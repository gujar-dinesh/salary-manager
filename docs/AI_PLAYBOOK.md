
# Take-home assessment playbook

Distilled from the salary-manager assessment (Incubyte, Nov 2026). Goal: finish with every deliverable covered,
a commit history that tells the story, and no rework from late decisions.

## 1. Before writing code (one round of questions, not many)

Read the brief and JD fully, then build a deliverables checklist from them. Typical items:
requirements doc, backend, UI, seed data, tests, incremental commits, artifacts (design notes, prompts, trade-offs,
performance), deployment, demo video.

Ask the user every decision in ONE message, with a recommended default for each:
- Stack (match the JD), database (default PostgreSQL; do not start on SQLite and migrate later)
- Expected design bar: SOLID review, design patterns, optimization pass, security scan, e2e tests (default: all yes)
- Deployment target and whether a demo video is needed
- Commit message style and attribution (check global CLAUDE.md: no co-author trailers if it says so)
- Code style: plain, few comments, no emoji

If the brief asks for AI usage to be shown (most do now), keep an honest `docs/AI_USAGE.md`. Never hide AI use.

## 2. Environment check (single command)

Versions of language runtime, framework, node; DB running (`pg_isready`); git identity and remote.
In the desktop app, the preview server tool cannot access `~/Documents` (macOS privacy): start servers with
background Bash instead of `preview_start`.

## 3. Build order and commits

One commit per step, conventional prefixes (`chore`, `feat`, `fix`, `refactor`, `perf`, `security`, `test`, `docs`):

1. docs: requirements (one page: goal, persona, scope, out of scope with reasons, NFRs)
2. chore: scaffold backend with test framework, `.gitignore` (scaffold may skip git: check `master.key`, DBs, logs)
3. feat: model + validations (spec first)
4. feat: CRUD API with search/filter/sort/pagination (request specs first)
5. feat: aggregates/insights (computed in SQL, never in Ruby/JS memory)
6. feat: deterministic seed (`insert_all` in batches, fixed random seed)
7. feat: frontend with component tests
8. test: e2e (Playwright) on an isolated DB and ports
9. perf: measure first (`EXPLAIN`), then index / merge queries
10. security: scanners + manual input bounds, rate limiting
11. refactor: SOLID review (backend and frontend)
12. docs: README, ARCHITECTURE, AI usage log

Design from the start, so step 11 is a check rather than a rewrite:
query objects (`app/queries`), serializers, reference data in its own module, pagination as its own class,
one class per reporting concern, whitelists for sortable/groupable columns, a single scope for currency conversion.

## 4. Checks before every commit

Backend: `bundle exec rspec`, `bin/rubocop -A`, `bin/brakeman -q` (security commits also `bin/bundler-audit check --update`).
Frontend: `npm test`, `npm run build` (typechecks), `npm run lint`; e2e before refactor and perf commits.

## 5. Known gotchas (save the debugging tokens)

Rails / RSpec
- Request specs need `type: :request` (type inference is off by default).
- Don't memoize `response.parsed_body` with `let`: use `def json = response.parsed_body`.
- New `app/*` directories need a dev server restart.
- `git rm` of the last file deletes the directory; `mkdir -p` before writing new files there.
- Postgres `LIKE` is case-sensitive: use `ILIKE`; median via `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x)`.
- Sorting money across currencies must convert to one currency first.
- Rails 8 `rate_limit` needs a real cache store; verify live, not in specs (test uses null store).

React / Mantine / TanStack Query
- Tests: `<MantineProvider env="test">` (no portals or transitions); Select inputs have role `combobox`.
- Inactive Tabs panels stay mounted: scope queries to the panel.
- Don't retry 4xx in TanStack Query (default retries make 404 pages hang ~7 s).
- Keep vitest to `src/**/*.test.{ts,tsx}` so Playwright specs are not picked up.

Playwright
- Isolated `webServer` entries: own DB name, own ports, own pid file (`-P tmp/pids/e2e.pid`).
- With `keepPreviousData` the URL changes before rows do: use `expect.poll` on the data.
- Closing modals animate: `await expect(dialog).toBeHidden()` before the next click.
- Run `--repeat-each=3` once to catch flakiness.

## 6. Token discipline

- Batch independent commands in one call; write files with heredocs; don't re-read files just written.
- Run the narrowest failing test while fixing, the full suite only before commit.
- Prefer `get_page_text` / `find` over screenshots; one screenshot per page to confirm layout.
- Measure before optimizing; skip optimizations that don't change measured results, and say so in the docs.
- Keep progress updates to one line; findings go in docs, not chat.

## 7. AI usage log

Update `docs/AI_USAGE.md` at the end of each stage: the prompt (summary), the outcome, what was reviewed,
corrected or rejected, and why. Corrections are the point of the log: they show judgment. Keep them.
