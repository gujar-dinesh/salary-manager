# Salary Manager

A web app for ACME's HR manager to maintain salary data for 10,000 employees across countries and answer
questions about how the organisation pays people.

- Requirements: [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)
- Architecture and trade-offs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- How AI was used: [docs/AI_USAGE.md](docs/AI_USAGE.md)

## Features

- Employee directory with search, filters (country, department, job title), sorting and pagination
- Add, edit and delete employees with validation on both client and server
- Salary history recorded automatically on every salary change
- Insights: min / median / average / max salary by country, and by job title within a country
- Org overview: headcount and payroll by country and department in USD

## Stack

- Backend: Ruby 3.3, Rails 8.1 (API mode), SQLite, RSpec
- Frontend: React 19, TypeScript, Vite, Mantine, TanStack Query, Vitest, Testing Library

## Running locally

Requirements: Ruby 3.3 and Node 22.

```bash
cd backend
bundle install
bin/rails db:setup   # creates the database and seeds 10,000 employees
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

Static checks:

```bash
cd backend && bin/rubocop && bin/brakeman && bin/bundler-audit
cd frontend && npm run lint && npm audit
```

## Project layout

```
backend/
  app/models/          Employee, SalaryChange, ExchangeRate
  app/queries/         EmployeeSearch (list filters/sort/paging), SalaryInsights (aggregates)
  app/serializers/     EmployeeSerializer
  app/controllers/api/ employees and insights endpoints
  lib/employee_seeder.rb
frontend/
  src/api.ts           typed API client
  src/pages/           Employees, EmployeeDetail, Insights
  src/components/      EmployeeForm
docs/
```
