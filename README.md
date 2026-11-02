# Salary Manager

A web app for ACME's HR manager to maintain salary data for 10,000 employees across countries and answer
questions about how the organisation pays people.

- Requirements: [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)
- Architecture and trade-offs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- How AI was used: [docs/AI_USAGE.md](docs/AI_USAGE.md), rules for AI agents: [CLAUDE.md](CLAUDE.md), reusable playbook: [docs/AI_PLAYBOOK.md](docs/AI_PLAYBOOK.md)

## Features

- Employee directory with search, filters (country, department, job title), sorting and pagination
- Add, edit and delete employees with validation on both client and server
- Salary history recorded automatically on every salary change
- Insights: min / median / average / max salary by country, and by job title within a country
- Org overview: headcount and payroll by country and department in USD

## Stack

- Backend: Ruby 3.3, Rails 8.1 (API mode), PostgreSQL 16, RSpec
- Frontend: React 19, TypeScript, Vite, Mantine, TanStack Query, Vitest, Testing Library

## Running locally

Requirements: Ruby 3.3, Node 22 and a running PostgreSQL (16 or newer). Connection settings can be
overridden with `DATABASE_HOST`, `DATABASE_USER` and `DATABASE_PASSWORD`; production reads `DATABASE_URL`.

```bash
cd backend
bundle install
bin/rails db:setup   # creates the databases and seeds 10,000 employees
bin/rails server     # http://localhost:3000
```

```bash
cd frontend
npm install
npm run dev          # http://localhost:5173, proxies /api to the Rails server
```

To reset the data at any time: `bin/rails db:seed`. The seed is deterministic, so every run produces the
same employees.

## Tests

```bash
cd backend && bundle exec rspec
cd frontend && npm test
```

End-to-end tests (Playwright) start their own Rails server on port 3100 with a separate, freshly seeded
database (`salary_manager_e2e`), and a Vite server on port 5180, so they do not touch development data:

```bash
cd frontend
npx playwright install chromium   # first time only
npm run e2e
```

They cover browsing, search, filters, sorting and pagination, adding an employee (with validation and duplicate
email), editing a salary and seeing it in the history, deleting an employee, and the insights pages.

Load test with correctness checks (use a disposable database; it creates employees):

```bash
cd backend
DATABASE_NAME=salary_manager_load bin/rails db:prepare db:seed
DATABASE_NAME=salary_manager_load WRITE_RATE_LIMIT=100000 WEB_CONCURRENCY=4 bin/rails server -p 3200
ruby script/load_test.rb http://localhost:3200 100   # in another terminal
```

Static checks:

```bash
cd backend && bin/rubocop && bin/brakeman && bin/bundler-audit
cd frontend && npm run lint && npm audit
```

## Project layout

```
backend/
  app/models/          Employee, SalaryChange, ExchangeRate, Country, Department, JobTitle
  app/queries/         EmployeeSearch, Pagination, SalaryStatistics, PayrollReport
  app/serializers/     EmployeeSerializer
  app/controllers/api/ employees and insights endpoints
  lib/employee_seeder.rb
frontend/
  src/api.ts           typed API client
  src/pages/           Employees, EmployeeDetail, Insights
  src/components/      EmployeeForm, EmployeeTable
  src/hooks/           useEmployeeFilters (filter state in the URL)
  e2e/                 Playwright tests
docs/
```
