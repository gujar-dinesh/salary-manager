# Salary Manager — Requirements (one page)

## Goal
Give ACME's HR Manager one web tool to **maintain salary data for ~10,000 employees across countries**
and **answer "how do we pay people?" questions** in seconds — replacing a set of Excel files.

**Success looks like:** the HR Manager can find any employee in under 5 seconds, correct a salary in a
few clicks with a record of the change, and answer "what do we pay a Software Engineer in India vs
Germany?" without building a pivot table.

## Persona
**HR Manager** — comfortable with spreadsheets, not technical. Works in salary reviews, offer
benchmarking and leadership reporting. Needs accuracy and trust in the numbers more than visual flair.

## In scope

| # | Feature | Why it matters |
|---|---------|----------------|
| 1 | **Employee directory** — paginated table, search by name/email, filter by country, department, job title; sort by name, salary, hire date | Replaces scrolling an Excel sheet; must stay fast at 10k rows (server-side pagination) |
| 2 | **Add / edit / delete employee** — full name, email, job title, department, country, salary, employment type, hire date (currency follows the country, decided during the build: see ARCHITECTURE.md); validated on server and client | The core "manage" job; validation stops the data-quality problems Excel allows |
| 3 | **Salary insights by country** — headcount, min / max / average / median salary | The most common HR question; median is included because averages are skewed by outliers |
| 4 | **Salary insights by job title within a country** — same stats | Needed for offers and pay-equity checks ("is this offer in range?") |
| 5 | **Org overview** — headcount & payroll by country and department, normalized to USD | Leadership-level view; comparing across countries needs a common currency |
| 6 | **Salary change history** — every salary change records old value, new value and timestamp | HR needs an audit trail; Excel loses it |
| 7 | **Seed script** — 10,000 realistic, deterministic employees | Required; deterministic so demos and tests are repeatable |

### Key product decisions
- **Salaries stored in local currency, compared in USD.** Employees are paid in local currency, so that is
  the source of truth. Cross-country views convert using a **static FX table** kept in the database, which
  keeps the numbers deterministic and testable. Within-country insights show local currency only, so they
  are never distorted by FX.
- **Annual gross base salary only.** One clear, comparable number; bonus and equity add complexity
  without changing the core questions.
- **Statistics computed in the database** (SQL aggregates), never by loading 10k rows into memory.

## Deliberately out of scope

| Left out | Reasoning |
|----------|-----------|
| Authentication & roles | Single persona, internal tool; adding it would be the first follow-up before real use, but it does not demonstrate the core problem |
| Payroll processing, tax, payslips | A different product with legal/regulatory weight; HR asked to *manage and understand* pay, not run it |
| Live FX rates | External dependency that makes results non-deterministic; static rates are honest for an internal reporting tool and easy to update |
| Bulk Excel/CSV import | Very relevant to the migration story, but large (mapping, error reporting, partial failures). First item on the roadmap |
| Bonus, equity, benefits, pay bands | Expand the data model significantly; base salary answers the stated questions |
| Approval workflows, notifications, multi-tenancy | No stated need; would add complexity without value for one HR Manager |

## Non-functional requirements
- List and insights endpoints respond in **< 300 ms** with 10k employees (indexes on country, job title, department).
- **Tests first** (TDD): model validations, insight calculations (incl. median edge cases), API contracts, key UI flows. Fast and deterministic — no network, fixed seeds.
- Works in current desktop browsers; usable on a laptop screen.

## Tech choices (summary — details in `docs/ARCHITECTURE.md`)
Ruby on Rails (API mode) · PostgreSQL (started on SQLite, see `ARCHITECTURE.md`) · RSpec · React + TypeScript (Vite) · Mantine UI · TanStack Query · Vitest + Testing Library.
Chosen to match the role (Rails, TDD, React/TypeScript) and keep the stack simple to run and deploy.
