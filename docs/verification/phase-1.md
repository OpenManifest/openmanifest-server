# Phase 1 verification

Date: 2026-10-08. Run in the Claude Code cloud VM on the top of the stacked Phase 1 branches (not yet merged into
`staging`; the Phase 0 stacks are not merged either, Phase 1 was started on the owner's explicit "stacked PRs"
instruction):

| Repo | Branch | Commit |
|---|---|---|
| backend | `modernise/p1-14-verify` (code stack P1.1 … P1.8, then status PRs for P1.9 … P1.13) | `5839947` + this report |
| client | `modernise/p1-13-tests-users-setup` (stack #172 → #173 → #174 → #175 → #176 on top of the Phase 0 stack #167 … #171) | `b73942f` |

## Step 1: re-sync (no drift)

```
bin/sync-client-operations ../openmanifest → Copied 89 documents from /home/user/openmanifest @ b73942f
  git status: only spec/fixtures/client_operations/SOURCE_COMMIT changed (it records the client commit); no .gql changed
yarn sync:schema (client)                  → Copied ../openmanifest-server/schema.graphql; git diff: empty
```

## Step 2: backend (CLOUD_ENV §4)

```
bundle exec rspec              → 568 examples, 0 failures, 67 pending
bundle exec rubocop --parallel → 508 files inspected, no offenses detected
bin/rails db:schema:load db:seed db:seed:dev_baseline → dev_baseline: dropzone 1, 2 loads
bin/rails server -p 5000       → GET /graphql 200
```

`BACKEND_URL` must be set for `rspec` (the master-log specs fail with "Missing host to link to" otherwise); CI sets it.
CLOUD_ENV §3 now says so.

Examples by area (`it` counts in the source): client-operation request specs 217, other request specs 20 (tenant isolation
and friends), GraphQL 74, interactions 96, models 16.

Pending examples, by bug (every one fails for the stated reason; an unexpectedly passing one fails the suite):

| Bug | Pending | Bug | Pending | Bug | Pending | Bug | Pending |
|---|---|---|---|---|---|---|---|
| BUG-002 | 12 | BUG-013 | 2 | BUG-036 | 2 | BUG-061 | 1 |
| BUG-003 | 2 | BUG-019 | 1 | BUG-037 | 1 | BUG-089 | 1 |
| BUG-004 | 1 | BUG-025 | 1 | BUG-038 | 1 | BUG-090 | 1 |
| BUG-005 | 2 | BUG-026 | 1 | BUG-039 | 3 | BUG-091 | 1 |
| BUG-006 | 2 | BUG-027 | 1 | BUG-040 | 1 | BUG-092 | 1 |
| BUG-007 | 2 | BUG-028 | 1 | BUG-041 | 2 | BUG-093 | 1 |
| BUG-008 | 3 | BUG-030 | 1 | BUG-042 | 1 | BUG-094 | 1 |
| BUG-009 | 1 | BUG-031 | 1 | BUG-048 | 2 | BUG-095 | 1 |
| BUG-010 | 4 | BUG-032 | 1 | BUG-054 | 1 | | |
| BUG-011 | 1 | BUG-033 | 2 | BUG-055 | 1 | | |
| BUG-012 | 1 | BUG-035 | 1 | | | **total** | **67** |

## Step 2: client

```
yarn check:types    → exit 0
yarn check:linting  → exit 0
yarn check:graphql  → OK: 89 files, 76 operations, 50 fragments checked against schema.graphql
yarn check:testing  → Test Suites: 15 passed, 15 total; Tests: 33 passed, 7 skipped, 1 todo, 41 total
EXPO_ENV=local npx expo export:web → exit 0
python3 scripts/serve-web-build.py web-build 19006 &
TZ=Australia/Brisbane node scripts/web-smoke.mjs --out /tmp/smoke2
desktop 1280x800: ok
phone360 360x640: ok
```

Client tests by area: manifest 6 files (ManifestScreen, LoadScreen, ManifestUserDialog, LoadDialog, ActionButton,
KnownBugs), auth 2 (LoginScreen, logout), limbo 1 (DropzoneSelect), users 3 (ProfileScreen, CreditsSheet, CreateGhost),
setup 2 (AircraftForm, TicketTypeForm), utils 1.

Skipped client tests, by bug (each verified failing for the stated reason before being skipped): BUG-063 (logout leaves a
dead `AbortController`), BUG-065 (pull-to-refresh refetches the wrong query), BUG-066 (group sheet not mounted on the
board), BUG-067 (load creation gated on the staff member's own prerequisites), BUG-086 (no error shown without an access
level), BUG-096 (aircraft and ticket dialogs override form defaults; two tests). BUG-068 is an `it.todo`.

## CI on GitHub

| Repo | Run | Result |
|---|---|---|
| backend | [CI on #140 (P1.8)](https://github.com/OpenManifest/openmanifest-server/actions/runs/37765837949) | `test` success; `audit` failure (expected, non-blocking until P2.11) |
| client | [CI on #175 (P1.12)](https://github.com/OpenManifest/openmanifest/actions/runs/37788460114) | `checks` success; `web-export` success; DeepSource failure (see below) |

CI on `staging` itself runs once the stacks are merged (owner check below).

## Observations

- **BUG-068 seen live.** The first smoke run failed at the load step: it ran at 14:25 UTC, when it is already the next
  day in Brisbane, so the board (which asks for the *device's* date) showed "No loads so far today" for loads the
  dropzone dates tomorrow. The smoke test is deterministic with `TZ=Australia/Brisbane`; CLOUD_ENV documents it.
- **DeepSource** still flags `scripts/**` on every client PR from #170 on (unreachable details page; see the comments on
  #170 and #171). It does not block CI jobs, but the owner must either supply the flagged line or exclude `scripts/**`
  in `.deepsource.toml`.
- New bugs found in Phase 1: BUG-089 … BUG-096 (BUG-096 in P1.13). BUG-064, BUG-066, BUG-068 and BUG-086 were corrected
  in the register (see the P1.12 and P1.13 status PRs).
- Test-infrastructure findings worth knowing before editing the client mocks: the Apollo cache normalises by `__typename`
  + `id`, so fixtures that reuse an id with different fields overwrite each other (fixed in the Load, AllowedTicketTypes
  and CurrentUserPermissions mocks); `ManifestContextProvider` and `DropzoneContextProvider` mount (closed) copies of the
  manifest, load, credits, aircraft, ticket and create-user dialogs, so tests scope queries with `within()` or press every
  matching button.

## Owner checks (pending)

1. Merge the Phase 0 stacks (backend #125 … #132, client #167 … #171), then the Phase 1 stacks in order (backend
   #133 … #145 plus this PR; client #172 … #176), and confirm the latest `CI` run on `staging` is green in both repos.
2. Repeat the Phase 0 phone-browser smoke run (`client:docs/SMOKE_TEST.md`, sections Web, Login and Manifest, in iPhone,
   Android and a 360 dp Android browser). No behaviour changed in Phase 1, so the results must match Phase 0.
3. Decide the DeepSource question above.
