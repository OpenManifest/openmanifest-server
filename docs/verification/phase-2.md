# Phase 2 verification

Date: 2026-10-08. Run in the Claude Code cloud VM on the top of the stacked Phase 2 branches (not yet merged into
`staging`; Phase 0 and Phase 1 are not merged either, the whole stack was built on the owner's explicit "stacked PRs"
instruction):

| Repo | Branch | Commit |
|---|---|---|
| backend | `modernise/p2-11-verify` (stack #147 → #148 → … → #156, then this PR) | `9490951` + this report |
| client | `modernise/p1-13-tests-users-setup` (unchanged since Phase 1; stack #172 … #176) | `b73942f` |

Ruby commands ran in the `ruby:4.0.7-bookworm` Docker image (P2.5 and P2.9 fell back to Docker because
`cache.ruby-lang.org` is blocked; commands in `docs/reference/CLOUD_ENV.md` §4). CI runs on native Rubies.

## Versions

```
ruby -v        → ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [x86_64-linux]
bin/rails -v   → Rails 8.1.4
bundle -v      → 4.0.22
rails 8.1.4, graphql 2.6.11, graphql_devise 2.4.0, devise 5.0.4, devise_token_auth 1.3.0, puma 8.0.2, pg 1.7.0,
redis 6.0.0, rspec-rails 8.0.4, rubocop 1.91.0, brakeman 8.1.0, jwt 3.3.0, appsignal 5.0.3, nokogiri 1.19.4, rack 3.2.7,
state_machines-activerecord 0.200.0, counter_culture 3.3.0 (held until P6.10)
```

## Backend (CLOUD_ENV §4, Docker)

```
bundle exec rspec                          → 575 examples, 0 failures, 67 pending (same 67 pending BUG examples as Phase 1; +2 new examples)
bundle exec rubocop --parallel             → 508 files inspected, no offenses detected
bundle-audit check --update                → No vulnerabilities found   (ruby-advisory-db 1261 advisories, 2026-10-07)
bundle exec brakeman -q --no-pager         → 0 security warnings
bin/rails graphql:schema:dump && git diff  → schema.graphql identical to the P2.10 commit; versus the Phase 1 schema the only diff
                                             is `@specifiedBy(url: "https://tools.ietf.org/html/rfc3339")` on the two ISO8601
                                             scalars (graphql 2.3 prints it; introduced in P2.3, client check unaffected)
dev server (Ruby 4.0.7, Rails 8.1.4, Puma 8.0.2) → GET /graphql 200
```
`bundle-audit` went 133 advisories (pass 1) → 128 (after P2.1) → 43 (P2.2) → 30 (P2.2, nokogiri/sanitizer) → 0 (P2.8).

## Client against the upgraded backend (client code unchanged)

```
yarn check:types    → exit 0
yarn check:linting  → exit 0
yarn check:graphql  → OK: 89 files, 76 operations, 50 fragments checked against schema.graphql  (client's committed copy)
yarn check:testing  → Test Suites: 15 passed; Tests: 33 passed, 7 skipped, 1 todo
EXPO_ENV=local npx expo export:web → exit 0
TZ=Australia/Brisbane node scripts/web-smoke.mjs   (against the dev server above)
desktop 1280x800: ok
phone360 360x640: ok
```
The client's own copy of `schema.graphql` still lacks the two `@specifiedBy` lines; `yarn sync:schema && yarn check:graphql`
also passes with the new schema (checked in P2.3), so no client change is needed. Syncing it is a one-line client diff for
whenever the next client PR is open.

## CI on GitHub

| PR | Task | `test` | `audit` |
|---|---|---|---|
| [#150](https://github.com/OpenManifest/openmanifest-server/actions/runs/37798390207) | P2.4 Rails 7.2 | success | failure (expected until P2.8; advisories) |
| [#151](https://github.com/OpenManifest/openmanifest-server/actions/runs/37799890664) | P2.5 Ruby 3.4.11 | success | failure (expected) |
| [#154](https://github.com/OpenManifest/openmanifest-server/actions/runs/37805345805) | P2.8 runtime gems | success | **success** |
| [#155](https://github.com/OpenManifest/openmanifest-server/actions/runs/37806477985) | P2.9 Ruby 4.0.7 | success | success |

This PR removes `continue-on-error` from the `audit` job, so from here on the audit blocks CI. CI on `staging` itself runs
once the stacks are merged (owner check below).

## Things learned during the phase (each is recorded in the plan, the register or the PR that hit it)

- Conservative `bundle update` still moved gems outside the listed set. `counter_culture` 3.14.0 makes the double counting of
  BUG-019 refuse three-tandem group manifests, so it stays pinned at 3.3.0 until P6.10 (P2.2).
- `graphql_devise` 1.5.0 calls the deprecated `Schema.tracer`; the one remaining deprecation line in P2.3 disappeared with 2.0.0 in
  P2.4 (P2.3 therefore did not meet its "deprecation count 0" criterion on its own; noted in its PR).
- appsignal 5 removed `Appsignal::Utils::HashSanitizer`; the code using it is skipped in the test environment, so it only broke the
  dev server. A spec now runs it (P2.8).
- state_machines-activerecord 0.200 needs the `enum` declared before the state machine (`Load`) (P2.8).
- BUG-097 (duplicate JSON keys in dropzone settings) found and fixed; BUG-098 (`around(:suite)` ignored by RSpec) registered, queued
  in P6.19.
- A development server left running from before an upgrade silently answers on :5000; kill it before starting the next one
  (`ss` prints nothing in this VM; `ps aux | grep puma`). Two early smoke runs (P2.1, P2.2) were affected; P2.2 was re-run.
- The smoke test only passes with `TZ=Australia/Brisbane` (BUG-068).

## Owner checks (pending)

1. Merge the stacks in order (Phase 0 → Phase 1 → Phase 2; backend #147 … #156 and this PR) and confirm the latest `CI` run on
   `staging` is green in both repos, `audit` included.
2. Phone-browser smoke run (`client:docs/SMOKE_TEST.md`, sections Login and Manifest) against a locally running stack; no regression
   versus `docs/verification/phase-1.md`. Apple login (jwt 3) has only stubbed specs: if you can, sign in with Apple once on a device.
3. `cache.ruby-lang.org` allowlist or setup script versions B/C are optional now (the Docker fallback works); decide whether future
   sessions should use a native Ruby 4.0.7.
