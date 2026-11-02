# Salary Manager

Rails 8.1 API (`backend/`, PostgreSQL) and React + TypeScript (`frontend/`, Vite, Mantine).
Requirements, design and trade-offs are in `docs/`.

## Rules
- Tests first for every behaviour change. Keep tests fast and deterministic (no network, fixed seeds).
- Plain code: no emoji, comments only where intent isn't obvious.
- One logical change per commit, conventional prefixes (feat, fix, refactor, perf, security, test, docs).
- No co-author trailers in commit messages.
- Aggregates are computed in SQL, never by loading rows into memory.
- Record each working session in `docs/AI_USAGE.md` (prompt, outcome, what was corrected or rejected).

## Commands
- Backend: `cd backend && bundle exec rspec && bin/rubocop && bin/brakeman -q`
- Frontend: `cd frontend && npm test && npm run build && npm run lint`
- E2E: `cd frontend && npm run e2e` (own database `salary_manager_e2e`, ports 3100/5180)
- Reset data: `cd backend && bin/rails db:seed`

## Structure
- `app/queries`: EmployeeSearch, Pagination, SalaryStatistics, PayrollReport
- `app/models/country.rb`: supported countries and currencies
- `app/serializers`: JSON shapes
- `frontend/src/hooks/useEmployeeFilters.ts`: filter state lives in the URL
