# Phase 0 verification

Date: 2026-10-08. Run in the Claude Code cloud VM on the top of the stacked Phase 0 branches (not yet merged into
`staging`):

| Repo | Branch | Commit |
|---|---|---|
| backend | `modernise/p0-10-verify` (stack #125 → #126 → #127 → #128 → #129 → #130 → #131) | `6857eda` + this report |
| client | `modernise/p0-9-readmes` (stack #167 → #168 → #169 → #170 → #171) | `c30e241` |

## Backend (CLOUD_ENV §4)

```
bundle exec rspec              → 181 examples, 0 failures, 2 pending   (pending: BUG-033 double-manifest bypass)
bundle exec rubocop --parallel → 494 files inspected, no offenses detected
bin/rails db:seed:dev_baseline → dev_baseline: dropzone 1, 2 loads. Login owner@example.com / Password1!
bin/rails server -p 5000       → GET /graphql 200
```

## Client

```
yarn check:types    → exit 0
yarn check:linting  → exit 0
yarn check:testing  → Tests: 8 passed, 8 total
EXPO_ENV=local npx expo export:web → exit 0
node scripts/web-smoke.mjs --out /tmp/smoke
desktop 1280x800: ok
phone360 360x640: ok
```

## CI on GitHub

| Repo | Run | Result |
|---|---|---|
| backend | [CI on #128 (P0.4)](https://github.com/OpenManifest/openmanifest-server/actions/runs/37725282924) | `test` success; `audit` failure (expected: 133 advisories, non-blocking until P2.11) |
| backend | [CI on #129 (P0.5)](https://github.com/OpenManifest/openmanifest-server/actions/runs/37725437101) | `test` success; `audit` failure (expected) |
| client | [CI on #169 (P0.7)](https://github.com/OpenManifest/openmanifest/actions/runs/37751401297) | `checks` success; `web-export` success |

CI on `staging` itself runs once the stacks are merged (owner check below).

## Observations

- The load screen shows "4/14" slots for two jumpers (BUG-019, fixed in P6.10).
- The VM's Docker daemon would not start after the container restarted (`ulimit: Operation not permitted`). actionlint was
  built with `go install github.com/rhysd/actionlint/cmd/actionlint@latest` instead.

## Owner checks (pending)

1. Merge the backend stack (#125 … #131, then this PR) and the client stack (#167 … #171) in order; confirm the latest
   `CI` run on `staging` is green in both repos.
2. Run `client:docs/SMOKE_TEST.md` sections Web, Login and Manifest in phone browsers (iPhone, Android, small Android at
   360 dp) against a locally running stack and record the results here.
