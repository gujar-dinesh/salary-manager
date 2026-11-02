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
