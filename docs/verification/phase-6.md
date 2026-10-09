# Phase 6 verification

Date: 2026-10-09. Run in the Claude Code cloud VM on the top of the stacked Phase 6 branches (the Phase 0–5 stacks are still not
merged into `staging`, so Phase 6 is stacked on Phase 5, which is stacked on Phase 4 …):

| Repo | Head | Notes |
|---|---|---|
| backend | `modernise/p6-27-verify` on top of `modernise/p6-26-client-ux` (stack [#198](https://github.com/OpenManifest/openmanifest-server/pull/198) → … → [#221](https://github.com/OpenManifest/openmanifest-server/pull/221), then this PR) | Ruby 4.0.7, Rails 8.1.4 |
| client | `modernise/p6-26-client-ux` (stack [#217](https://github.com/OpenManifest/openmanifest/pull/217), [#218](https://github.com/OpenManifest/openmanifest/pull/218), [#219](https://github.com/OpenManifest/openmanifest/pull/219), [#220](https://github.com/OpenManifest/openmanifest/pull/220), [#221](https://github.com/OpenManifest/openmanifest/pull/221), [#222](https://github.com/OpenManifest/openmanifest/pull/222), [#223](https://github.com/OpenManifest/openmanifest/pull/223), [#224](https://github.com/OpenManifest/openmanifest/pull/224)) | Node 20 (Node 24 comes with P3.15); no client change in this task |

Not part of the gate (blocked on owner decisions): **P6.7** (D8, peer-to-peer transfers) and **P6.14** (D3, eligibility
defaults). Both stay `blocked` in the plan.

## Backend commands

```
ruby -v / bin/rails -v                    → ruby 4.0.7 / Rails 8.1.4
bundle exec rspec                          → 980 examples, 0 failures, 2 pending
bundle exec rubocop                        → 555 files inspected, no offenses detected
bundle exec brakeman --no-pager --exit-on-warn → exit 0, 0 security warnings
bundler-audit check                        → No vulnerabilities found (ruby-advisory-db b6604fa, 2026-10-07)
bin/rails graphql:schema:dump              → no diff in schema.graphql
```

The two pending examples are one: `Manifest::CreateSlot` "user is double manifested but allowed to" (`pending "BUG-033"`), which waits
for decision D3 (P6.14). There is no other `pending "BUG-` spec. (`bundler-audit check --update` could not fetch the advisory database
inside the container: git there does not trust the VM proxy's CA. The database was cloned on the host and copied in.)

## Client commands

```
yarn check:types    → exit 0
yarn check:linting  → exit 0: ESLint "0 errors, 230 warnings" (unchanged), Prettier clean
yarn check:graphql  → OK: 90 files, 77 operations, 50 fragments checked against schema.graphql
yarn check:testing  → Test Suites: 45 passed, 45 total; Tests: 158 passed, 158 total (no skipped test left)
yarn ts:graphql && git status → clean
EXPO_ENV=staging npx expo export --platform web → exit 0;  EXPO_ENV=local → exit 0
TZ=Australia/Brisbane node scripts/web-smoke.mjs (P6.26 head, local backend on the P6.23 code with the dev seed)
desktop 1280x800: ok
phone360 360x640: ok
yarn audit --groups dependencies --summary → 42 vulnerabilities (23 High, 19 Moderate, 0 Critical); unchanged since Phase 4
```

CI (GitHub Actions) on the stack: `test`, `audit` and `brakeman` are green on [openmanifest-server#220]
(https://github.com/OpenManifest/openmanifest-server/pull/220); `checks` and `web-export` are green on
[openmanifest#223](https://github.com/OpenManifest/openmanifest/pull/223). DeepSource's check fails on the client PRs (it has no
configuration here; open item for the owner). CI on `staging` itself cannot be checked until the stacks are merged.

## Pass-1 audit scenarios

BUGS.md keeps eight of the 25 pass-1 throwaway audit scenarios by number (the others were not recorded with an id). Each one now has
a committed spec that fails without the fix:

| Scenario | What it did | Bug | Covering specs |
|---|---|---|---|
| AUDIT-2 | another dropzone member's email and phone are returned | BUG-013 (P6.3) | `spec/requests/member_authorization_spec.rb`, `spec/requests/tenant_isolation_spec.rb` |
| AUDIT-6 | creating a notification raises `UnknownAttributeError` (`type`) | BUG-042 (P6.18) | `spec/models/notifications_spec.rb` |
| AUDIT-7 | `updateSlot` raises `NoMethodError` in `authorized?` | BUG-029 (P6.11) | `spec/requests/update_slot_spec.rb` |
| AUDIT-12 | `reloadWeatherCondition` fails on the client's input (`dropzone_users` of nil) | BUG-040 (P6.19) | `spec/requests/client_operations/setup_spec.rb` (ReloadWeather), `client:app/__tests__/setup/ReloadWeather.test.tsx` |
| AUDIT-13 | `updateDropzoneUser` raises `NameError` (`model`) | BUG-037 (P6.15) | `spec/requests/client_operations/users_spec.rb` (UpdateDropzoneUser) |
| AUDIT-14 | deleting a ticket type, dropzone or rig raises `RecordNotFound` in the authorization check | BUG-039 (P6.8) | `spec/requests/client_operations/setup_spec.rb`, `spec/requests/setup_authorization_spec.rb` |
| AUDIT-21 | the scheduled master log raises (`iso8601` of nil) | BUG-044 (P6.17) | `spec/jobs/jobs_spec.rb` |
| AUDIT-22 | `updateUser` for another user raises `ArgumentError` | BUG-038 (P6.15) | `spec/requests/client_operations/users_spec.rb` |

Every bug of the register that has a committed example carries its `BUG-nnn` id in the spec; the Phase 1 characterisation examples
(`spec/requests/client_operations/*`, `tenant_isolation_spec.rb`) were turned into the acceptance tests of the Phase 6 tasks as each
task landed, with a one-line note per changed expectation in its PR.

## Bug register after Phase 6

101 bugs: **96 fixed** (every one is prefixed `FIXED in P{x}.{y}:` in BUGS.md) and 5 open.

Fixed, by task:

| Task | Bugs |
|---|---|
| P0.1 | BUG-057 |
| P0.3 | BUG-058 |
| P1.9 | BUG-080 |
| P1.10 | BUG-081 |
| P2.1 | BUG-059 |
| P2.8 | BUG-097 |
| P2.11 | BUG-015 |
| P3.9 | BUG-083 |
| P3.12 | BUG-099 |
| P3.21 | BUG-088 |
| P3.22 | BUG-016 |
| P4.1 | BUG-017 |
| P4.7 | BUG-066, BUG-079 |
| P4.8 | BUG-063, BUG-064, BUG-069 |
| P5.2 | BUG-070, BUG-071, BUG-073 |
| P5.3 | BUG-076 |
| P5.5 | BUG-072, BUG-074 |
| P5.6 | BUG-075, BUG-087 |
| P5.7 | BUG-078 |
| P5.8 | BUG-077 |
| P6.1 | BUG-001 |
| P6.2 | BUG-002, BUG-003, BUG-004, BUG-090, BUG-095 |
| P6.3 | BUG-013, BUG-093 |
| P6.4 | BUG-005, BUG-089 |
| P6.5 | BUG-006, BUG-007, BUG-062, BUG-092 |
| P6.6 | BUG-008 |
| P6.8 | BUG-009, BUG-010, BUG-039, BUG-061 |
| P6.9 | BUG-011, BUG-053, BUG-060 |
| P6.10 | BUG-019, BUG-020, BUG-021, BUG-023 |
| P6.11 | BUG-025, BUG-029, BUG-030, BUG-031, BUG-032, BUG-034, BUG-091 |
| P6.12 | BUG-026, BUG-035, BUG-036, BUG-082 |
| P6.13 | BUG-027, BUG-028 |
| P6.15 | BUG-037, BUG-038, BUG-054, BUG-055, BUG-056, BUG-094 |
| P6.16 | BUG-022, BUG-050 |
| P6.17 | BUG-044, BUG-052 |
| P6.18 | BUG-018, BUG-042, BUG-043, BUG-051 |
| P6.19 | BUG-040, BUG-045, BUG-046, BUG-047, BUG-098 |
| P6.20 | BUG-068 |
| P6.21 | BUG-041 |
| P6.22 | BUG-024 |
| P6.23 | BUG-048 |
| P6.24 | BUG-012, BUG-014 |
| P6.25 | BUG-049 |
| P6.26 | BUG-065, BUG-067, BUG-086, BUG-096 |

Open:

| Bug | Severity | Repo | What | Planned |
|---|---|---|---|---|
| BUG-033 | high | backend | Strict eligibility defaults applied to existing dropzones | P6.14, blocked on decision D3; its example is the only `pending "BUG-` spec (`spec/interactions/manifest/create_slot_spec.rb`) |
| BUG-084 | high | client | Native builds (Expo / React Native upgrade follow-ups) | P3.3, blocked on decision D4 |
| BUG-085 | medium | client | Google Maps not loading on web and Android (client#127), suspected | Deferred: owner checks with real `GOOGLE_MAPS_*` keys (P3.22) |
| BUG-100 | medium | client | A cold load of `/users` or `/user/<id>` ends on `/` | Deferred: needs a navigation decision (see the plan's Deferred bugs table) |
| BUG-101 | medium | backend | Editing a slot through `createSlot` charges the member again | Not planned yet: needs `updateSlot` to refund/charge the difference and a client change (found in P6.10) |

BUG-008 is `FIXED in P6.6` for the security part (cross-tenant and unaffordable transfers); the peer-to-peer policy of member to member
transfers waits for decision D8 (P6.7): today transfers between two members are refused (`Transfers between members are disabled`).

## Owner checks (not done here)

- Run the full `client:docs/SMOKE_TEST.md` on one iPhone and one Android phone against a staging API built from `staging` (needs D1 hosting,
  or web through a tunnel).
- Device checks listed in the Phase 6 PRs: Apple login live updates (P6.9), push delivery (P6.18), camera uploads of banners, packing cards
  and profile pictures (P6.21).
- Deploy notes: set `CORS_ORIGINS` on deployments whose web client is not served from `FRONTEND_URL` (P6.24); the P6.9 client must ship
  with or before the backend; run the P6.23 migration before the new client ships (older clients keep working through the deprecated
  Float fields).
