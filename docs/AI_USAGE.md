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
