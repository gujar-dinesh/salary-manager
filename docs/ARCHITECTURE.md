# Architecture

## Overview

```
React SPA (Vite)  --/api-->  Rails API  -->  PostgreSQL
  Mantine UI                  controllers -> query objects -> ActiveRecord
  TanStack Query cache        serializers
```

In development the Vite dev server proxies `/api` to Rails, so there is no CORS setup. In production the
built frontend can be served by Rails or any static host in front of it.

## Data model

| Table | Columns | Notes |
|-------|---------|-------|
| employees | full_name, email (unique), job_title, department, country, currency, salary (decimal 12,2), employment_type, hire_date | currency is derived from country |
| salary_changes | employee_id, old_salary, new_salary, currency, created_at | append-only audit trail, deleted with the employee |
| exchange_rates | currency (unique), usd_rate | static rates used for USD comparisons |

Decisions:

- **Currency follows country.** The requirements listed currency as an editable field. While building the form
  it was clear that letting HR pick "Germany + INR" only creates bad data, so currency is set from the country
  on save. A supported-countries list lives in `Employee::CURRENCY_BY_COUNTRY`.
- **Salary history via a model callback.** `after_update` records a change whenever salary changes. A service
  object was considered, but a callback guarantees the audit row is written no matter which code path updates
  the employee (API, console, future import job).
- **Decimal, not float**, for money. Values are converted to numbers only at the JSON boundary.

## Backend structure

Each class has one reason to change:

| Class | Responsibility |
|-------|----------------|
| `Employee` | validation, normalisation, recording salary changes |
| `Country` | supported countries and their currencies (reference data) |
| `EmployeeSearch` | filtering, text search and sorting of the directory |
| `Pagination` | page and page-size rules, limit/offset, meta block; not tied to employees |
| `SalaryStatistics` | salary distribution (min, median, average, max) in local currency |
| `PayrollReport` | headcount and payroll converted to USD |
| `EmployeeSerializer` | JSON shape of an employee |
| controllers | parse params, call one of the above, render |

Notes on SOLID:

- **Single responsibility** drove the splits above. Earlier versions had the country table inside `Employee`
  (used from five places), pagination inside `EmployeeSearch`, and one `SalaryInsights` class doing both local
  statistics and USD reporting.
- **Open/closed:** adding a sortable column or a new breakdown is a one-line change to a whitelist
  (`EmployeeSearch::SORTABLE`, `SalaryStatistics::GROUPABLE`). The USD conversion lives in one scope,
  `Employee.with_usd_salary`, used by both the directory sort and the payroll report.
- Liskov and interface segregation have little to act on here: there are no inheritance hierarchies beyond
  ActiveRecord. Injecting query objects into controllers (dependency inversion) was considered and left out;
  in Rails it adds wiring without making anything easier to test, since each query object is already tested on
  its own.

Frontend follows the same idea: `useEmployeeFilters` owns URL filter state, `EmployeeTable` only renders,
and the page composes them with data fetching.

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | /api/employees | list; params: q, country, department, job_title, sort, direction, page, per_page |
| GET | /api/employees/:id | employee with salary history |
| POST / PATCH / DELETE | /api/employees(/:id) | create, update, delete |
| GET | /api/employees/options | values for filters and form dropdowns |
| GET | /api/insights/countries | stats per country, local currency |
| GET | /api/insights/job_titles?country= | stats per job title within a country |
| GET | /api/insights/overview | headcount and payroll in USD by country and department |

Validation errors return `422` with `{ errors: { field: [messages] } }`, which the form maps onto its fields.

## Database

The project started on SQLite to keep setup trivial, then moved to PostgreSQL: it is what a real deployment of
salary data would use, and it brings a native median (`PERCENTILE_CONT`), case-insensitive `ILIKE` and trigram
indexes. Migrations stayed portable; only the search and median SQL changed. Dev, test and e2e each use their
own database.

## Performance

Measured on the seeded 10,000 employees (development mode, laptop):

| Endpoint | Time |
|----------|------|
| employees list, sorted by salary | ~6 ms |
| employees list, search | ~7 ms |
| insights by country | ~15 ms |
| org overview | ~11 ms |

What was done, based on `EXPLAIN QUERY PLAN`:

- **Everything is aggregated in SQL**, never by loading rows into Ruby. Memory use per request is one page of
  employees or one row per group.
- **Median in the same query** as min, max and average, using `PERCENTILE_CONT(0.5)`. (On SQLite this needed
  a `ROW_NUMBER()` window workaround; the first version used two queries per table.)
- **Indexes for sorting.** Sorting by salary or hire date originally scanned the table and built a temporary
  sort tree for every page. Indexes on `salary`, `hire_date` and `(country, salary)` let the database walk the index
  instead. `(country, job_title)` serves country filters and the job title breakdown.
- **Seeding uses `insert_all` in batches of 1,000**, so 10,000 rows take under a second and memory stays flat.
- **Frontend** uses server-side pagination, debounced search (300 ms) and keeps the previous page on screen
  while the next one loads. Filters live in the URL, so they survive navigation and can be shared.

Considered and left out:

- **Caching insights.** The queries take milliseconds; a cache would add invalidation logic and a risk of stale
  numbers for no visible gain at this size. Worth revisiting at 10x the data.
- **Full-text search.** Search uses `ILIKE '%term%'` backed by `pg_trgm` GIN indexes on name and email. At
  10,000 rows Postgres still prefers a sequential scan (about 10 ms either way); the indexes are there so search
  keeps working as the table grows. Postgres full-text search would only be needed for word-level matching.
- **Keyset pagination.** Offset pagination is simple and fine for ~400 pages.

## Correctness note: sorting across currencies

Sorting by salary without a country filter used to compare raw numbers, so a ¥21,000,000 salary ranked above
$237,000. Across countries the list now sorts by the USD equivalent (join on `exchange_rates`); within a
single country it sorts by the local amount and uses the `(country, salary)` index.

## Security

- Brakeman, bundler-audit and npm audit report no issues.
- Strong parameters (`params.expect`) whitelist writable fields; currency cannot be set directly.
- All SQL uses bound parameters; the few interpolated fragments come from fixed whitelists.
- Input bounds: text fields up to 100 characters (email 254), salary below the column's precision, search terms
  truncated to 100 characters, page size capped at 100.
- Write endpoints are rate limited (60 requests per minute per client).
- Production config forces SSL. React escapes all rendered values; no raw HTML is used.
- **Known gap: no authentication.** It was left out of scope deliberately (see requirements), and it is the
  first thing to add before real use: salary data is sensitive.

## Testing

- Backend (RSpec): model validations and salary history, query objects (including median edge cases and USD
  conversion), request specs for every endpoint, the seeder (deterministic, valid, idempotent).
- Frontend (Vitest + Testing Library): form validation and server error mapping, directory search and sorting,
  detail page history, insights tabs. `fetch` is stubbed, so tests are fast and need no backend.
