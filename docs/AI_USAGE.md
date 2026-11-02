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

### 11. Concurrency, database rules and load
**My direction:** "Did you try concurrent requests?", "the system should behave exactly right even under
extreme load", and "did you enforce constraints at the database level?"
**What testing showed:** parallel reads were fine; parallel writes had three bugs (a stale form silently reverted
another user's raise, and two kinds of unique conflicts returned 500). Several rules existed only in Rails.
**Changes:** optimistic locking with a 409 and a clear message; lookups created inside the employee transaction
so the unique index settles races; one retry for email conflicts; remaining rules moved into the database.
**Approach I insisted on:** prove it rather than claim it. Races are reproduced deterministically in specs, each
database rule is tested with raw inserts, and a load test checks invariants (no lost raises, an unbroken
history chain, one row per job title) at 40 and 100 parallel clients.
**Caught along the way:** the first race spec showed there were two race windows for lookups, not one, which
changed the fix from "retry the save" to "let the index decide when resolving the name".

### 12. Containerization
**My direction:** "Containerize the application, run it the Docker way and test it."
**Outcome:** multi-stage image (Node build, Ruby runtime, non-root), compose with Postgres and health checks,
Rails serving the built frontend. The same e2e suite and load test ran against the containers and passed.
**Caught before shipping:** Rails' public file server sends a one-year cache header; applied to `index.html`
it would keep users on an old release after a deploy, so `index.html` is served separately with `no-cache`.
`force_ssl` was hard-coded and would redirect plain-HTTP local runs, so it became an environment flag that
stays on by default.
**Playbook updated** with the gotchas from the last three rounds so the next project starts with them.

### 13. Full code review and fixes
**My direction:** "Do a thorough code review", then "fix all 15".
**Review:** run at the highest effort over every commit since the requirements doc. Three crash cases were
confirmed live before reporting (huge page number, array parameters).
**Most important findings:** salary history labelled the old amount with the new currency when an employee
moved country (an audit trail error); `db:seed` would wipe production data; the hire-date check used UTC and
rejected "today" for users in India, Japan or Australia for part of each day.
**Fixed test-first, one commit per theme:** history stores both currencies; seeding never replaces production
data unless forced; hire date compared with the latest date on Earth; list params accept only scalars and the
page is clamped; filters and email uniqueness match names ignoring case (the uniqueness check now uses the
`LOWER(email)` index); the last migration is reversible (verified by a rollback/migrate round trip); search no
longer floods browser history and follows Back; every write refreshes lists, options and insights; server
errors for fields not on the form are shown; the load test refuses too few clients; an early commit's co-author
trailer was removed from its message (history rewritten before the first push, tree unchanged).
**Verified** locally and against a rebuilt container that migrated its existing data: all specs, e2e tests and
the load test pass.

### 14. Second review, CI and the brief
**My direction:** "Review again and check the assignment doc so everything is in place", then "fix and add CI".
**Review findings fixed:** a blank `lock_version` caused a 500; two data-moving migrations could not be rolled
back although the docs said they could (now reversible, verified with a data checksum over every employee);
country names were still case-sensitive in two places (one shared `CaseInsensitiveName` concern now serves
countries, departments, job titles and the search); an invalid rate-limit setting silently blocked all writes
(now fails at boot). One finding (a refetch after delete) did not reproduce in a test, so the code was left
as is and the test kept as a guard.
**CI:** a GitHub Actions workflow with backend, frontend, e2e and Docker jobs, plus the missing spec step in
`bin/ci`. Running each job locally first caught two real problems: a test-helper type error that broke the
typechecked build (and the Docker image), and deep links returning 404 to clients that send `Accept: */*`.
**Brief check:** everything in the brief is in place except the items that need me: pushing the repository,
deploying, and recording the demo video.

### 15. Demo video
**My direction:** "Can a script generate a voice-over video?", then "make the video".
**Outcome:** `frontend/demo/make-video.sh` records a Playwright walkthrough of the main flows against a freshly
seeded Docker stack, generates narration with macOS `say` from an editable script, and merges both with ffmpeg.
Each scene waits for its narration, so the voice stays in sync after edits.
**Checked rather than assumed:** stills pulled from the video for every scene; speech onsets measured with
ffmpeg matched the scene timeline within 0.1 s. A one-second white flash from a full page reload was found this
way and replaced with in-app navigation; the script now reports any content-free frames automatically. `say`
hung once without a terminal, so each clip now has a time limit and retries.
