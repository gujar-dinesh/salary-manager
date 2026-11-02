# AI Usage Log

This project was built with an AI pair (Claude) as a collaborator. This log records how it was used,
what was asked, and where its output was reviewed, corrected or rejected — so the reviewer can see
the human judgment behind the code.

## Working agreement
- I (the engineer) own the decisions: scope, data model, trade-offs. The AI proposes, drafts and speeds up.
- Tests are written first for each behaviour; AI-generated code must make a failing test pass.
- Every AI-generated change is read before commit. Notable corrections are logged below.

## Session log

### 1. Planning & requirements
**Prompt (summary):** "Here is the assessment brief and the job description. Plan how to approach it."
**Outcome:** Stack chosen from the JD (Rails, TDD, React + TypeScript). Agreed scope: directory, CRUD,
insights by country and by job title within a country, USD-normalized org overview, salary change audit.
**Decisions made by me:** store salaries in local currency with a static FX table (deterministic tests);
leave out auth and bulk import, with reasons recorded in `REQUIREMENTS.md`.

### 2. Environment setup
**Context:** The AI's sandboxes could not reach rubygems.org / npm at first, so dependency installs were blocked.
**Decision:** Keep my corporate Git identity global; this repo uses a repo-local personal identity
(`git config user.email gujar.dinesh@gmail.com`) and pushes through an SSH host alias
(`git@github-personal:gujar-dinesh/salary-manager.git`) so personal and work accounts never mix.

### 3. Building the backend (TDD)
**Prompt (summary):** "Build it step by step, tests first, keep the code plain and readable."
**Outcome:** Model with validations and salary history, employees API, insights, deterministic seeder. Each
step started with failing specs and was committed separately.
**Reviewed / corrected:**
- A request spec memoized `response.parsed_body` with `let`, so a second request in the same example asserted
  against the first response. Caught by a failing test, replaced with a method.
- Currency was planned as a form field; I decided to derive it from country to avoid inconsistent data.

### 4. Frontend
**Outcome:** Directory, detail page with salary history, insights tabs, shared form. Tests stub `fetch`.
**Reviewed / corrected:** Mantine dropdowns did not render in jsdom until the provider was set to `env="test"`;
tab panels stay mounted, so a few assertions were tightened.
Clicked through the real app (edit salary, check history, insights) before committing.

### 5. Optimization pass
**My direction:** "First make it work, then optimize: design patterns, query and memory efficiency."
**Approach:** measured with `EXPLAIN QUERY PLAN` and request timings before changing anything.
**Changes:** query objects moved to `app/queries`, serializer extracted, stats + median merged into one query,
indexes added for sorted pages.
**Found during manual testing:** sorting by salary across countries compared yen with dollars. Fixed to sort by
USD equivalent, with a regression spec.
**Rejected:** caching insights (millisecond queries, adds stale-data risk) and full-text search (not needed at
10,000 rows). Reasons in `ARCHITECTURE.md`.

### 6. Security pass
**My direction:** "Check frontend and backend for vulnerabilities, fix in a separate commit."
**Outcome:** Brakeman, bundler-audit and npm audit were clean. Manual review added input length limits, a
salary ceiling, a search length cap and rate limiting on writes; verified the limit live (60 x 200, then 429).
Authentication remains the main known gap and is called out in the docs.

### 7. End-to-end tests
**My direction:** "Write a few Playwright scripts so the major use cases are covered."
**Outcome:** 12 tests across directory, add/edit/delete and insights, running against their own seeded
database and ports. Ran repeatedly to check for flakiness.
**Found by the e2e tests:**
- A real bug: failed requests were retried three times, so a deleted employee's page showed "Loading..." for
  about 7 seconds. 4xx responses are no longer retried.
- A race in a test: the table keeps the previous page visible while the next loads, so the sort test now polls
  until the rows are actually sorted.

### 8. PostgreSQL and SOLID
**My direction:** "Use Postgres, and make sure the design follows SOLID."
**Postgres:** median now uses `PERCENTILE_CONT`, search moved to `ILIKE` (a spec for case-insensitive search was
added first, since Postgres `LIKE` is case-sensitive) with trigram indexes. Checked the query plans: at 10,000
rows Postgres still picks a sequential scan, which is documented rather than claimed as a speedup.
**SOLID review:** the AI's first pass listed candidate violations; I kept the ones that were real single
responsibility problems (country data inside `Employee`, pagination inside search, one insights class doing two
jobs, duplicated USD SQL) and dropped dependency injection for controllers as ceremony. Same treatment for the
frontend employees page (filters hook and table component).

### 9. Playbook for next time
**My direction:** "Be more careful with tokens; write a rule book so the next assessment doesn't repeat work
or miss deliverables."
**Outcome:** `docs/AI_PLAYBOOK.md` (also installed as a personal Claude Code skill) and a project `CLAUDE.md`.
**Lesson recorded:** most rework here came from decisions made mid-way (SQLite to PostgreSQL, a SOLID pass
after the code was written). The playbook asks those questions in the first prompt, lists the gotchas that cost
debugging time, and sets token rules (batch commands, narrow test runs, measure before optimizing).

### 10. Data model review and normalization
**My direction:** asked for a review from a data-structure angle, then "are the tables well normalized?" and
"did we apply associations, callbacks and validations?". Chose which items to do from the resulting list.
**Findings I acted on:** currency depended on country (third normal form violation); department and job title
were repeated strings; rules lived only in Rails although the seeder bypasses validations; `ExchangeRate` was
joined with raw SQL instead of an association; a stray `hstore` extension came from the local `template1`.
**Changes:** check constraints and an enum; append-only salary history with an index matching its sort order;
`countries`, `departments` and `job_titles` tables with migrations that backfill existing rows.
**Decided by me:** the API keeps using names so the frontend and e2e tests did not change and could prove the
refactor; job titles are shared across departments.
**Caught by tests:** Rails `belongs_to` does not validate a new associated record by default, so an over-long
job title passed validation; fixed with `validate: true`.
