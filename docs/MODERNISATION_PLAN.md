# OpenManifest plan

Single source of truth for reviving, modernising, generalising and releasing OpenManifest and for the first features
built on it. It covers both repositories:

- **backend** = `OpenManifest/openmanifest-server` (this repo; Rails GraphQL API)
- **client** = `OpenManifest/openmanifest` (Expo / React Native app for iOS, Android and web)

Every task lives in this file, and the **Execution order** below is the one queue for all of them. Design documents
hold the reasoning and are linked from the tasks:

| Design | Covers | Tasks |
|---|---|---|
| [GENERALISATION](reference/GENERALISATION.md) | industry templates, modules, rename map, generic domain model | Phase 7 |
| [`client:docs/ui-modernisation-plan.md`](https://github.com/OpenManifest/openmanifest/blob/staging/docs/ui-modernisation-plan.md) | UI and UX redesign, design system, testing strategy | Phase U |
| [COMMERCE_FOUNDATION](features/COMMERCE_FOUNDATION.md) | money, ledger, Stripe, platform fee, orders, coupons | Phase C |
| [BOOKING_PLAN](features/BOOKING_PLAN.md) | bookable services, availability, guest booking | Phase B |
| [WEBSHOP_PLAN](features/WEBSHOP_PLAN.md) | products, stock, shop checkout, vouchers, reports | Phase S |

The client repo's `docs/MODERNISATION_PLAN.md` only points here. Reference material lives in [`docs/reference/`](reference/):
[README](reference/README.md) (system reference), [BUGS](reference/BUGS.md) (bug register), [diagrams](reference/diagrams.md),
[CLOUD_ENV](reference/CLOUD_ENV.md). Client-side reference:
<https://github.com/OpenManifest/openmanifest/blob/staging/docs/reference/README.md>.

Written in pass 1 on 2026-10-08 against backend `b8dc33a` and client `3112795` (both `staging`). Phases 7, U, C, B and
S were added on 2026-10-11 and merged into one queue the same day.

## Current state

OpenManifest is a skydiving dropzone manifest system: a Rails 7.0.4 / Ruby 3.1.3 GraphQL API (`graphql-ruby` 2.0,
`graphql_devise` token auth, `active_interaction` business logic, ActionCable subscriptions, PostgreSQL, Redis) and an
Expo SDK 47 / React Native 0.70 / React 18.1 client using Apollo Client 3.7 plus Redux Toolkit with redux-persist. Both
were last changed in October 2023. Both boot in the cloud VM with small local changes: the API on Ruby 3.1.6 with
`libpq-dev` installed, the client on Node 20 with `SENTRYCLI_SKIP_DOWNLOAD=1`. Login → dropzone → manifest board → load
screen works in a web export. The client's GraphQL documents match the server schema exactly, but the server has no
working tenant isolation, several manifesting and payment rules are broken (slots double-counted, wrong permission checks,
credit minting), and several mutations the client calls crash. The backend spec suite is red (64 of 187 failing); the
client has effectively no tests. Every runtime and framework is end-of-life or far behind: Ruby 3.1 (EOL 2025-03), Rails 7.0
(EOL), Expo SDK 47 (latest is 57). 133 backend and 715 client dependency advisories are open. There are 88 registered bugs
(7 critical, 29 high), and Android layout problems trace back to 9 shared root causes. Deploy workflows still point at 2023
infrastructure and fire on every push to `staging`/`main`.

## Top 5 risks

1. **Data exposure and abuse in any running deployment.** Any logged-in user can read every dropzone's members (email,
   phone), loads and audit logs, and can mint credits (BUG-001…BUG-008). If `stg.openmanifest.org` / `prod.openmanifest.org`
   are still running the 2023 code, the owner should take them offline or restrict access **now**. The security fixes are
   scheduled in Phase 6, after the safety nets and the upgrades; this plan does not make the old code safe to expose
   before then.
2. **Ten Expo SDK upgrades plus the New Architecture.** The path runs SDK 47 → 57, through React 19, the end of the legacy
   architecture (SDK 55) and the end of webpack web builds (SDK 50). Several libraries are abandoned (Rome, react-native-skeleton-content,
   react-native-animated-nav-tab-bar, expo-facebook), and 169 files use react-native-paper 4. All of this has to land with
   tests that only exist from Phase 1, and with no emulator in the VM.
3. **Device-only verification.** Android layout, keyboard, push and native-module behaviour can only be confirmed by the
   owner on real devices. That needs EAS/App Store/Play accounts (decision D2). Until then, owner checks rely on web builds
   on phone browsers.
4. **Production data integrity.** Counters are double-counted, money is stored as floats, membership uniqueness exists only
   in Ruby, and load numbers are duplicated. Migrations that add constraints must clean the data first. Decision D7
   (2026-10-11): there is no production database to carry forward, which also lets Phase 7 rename in place.
5. **Environment and external dependencies.** `cache.ruby-lang.org` and Expo's API are blocked in the VM. Ruby 4.0
   compatibility of older gems (`geokit-rails`, `search_cop`, `active_interaction-extras`) is unproven. Third-party keys
   (AppSignal, Google Maps, APF, Apple, Facebook, SMTP) may no longer be valid.

## Open Decisions

Tasks that depend on an owner decision are `blocked (awaiting decision Dn)` until the owner writes the decision into
this section ("Decision: …, date"); the executor then changes the blocked tasks back to `todo` in the next task's PR.

| ID | Decision | Options | Recommendation | Blocks |
|---|---|---|---|---|
| D1 | Hosting for the API, database and file storage (no Redis: Solid Queue, Solid Cache and Solid Cable run on PostgreSQL), and for the web app | (a) Fly.io (configs exist: `fly.toml`, `fly-production.toml`) with Fly Postgres and S3-compatible storage; (b) Render/Heroku-style PaaS; (c) a VPS with Kamal (Rails 8 default) | (a) Fly.io for the API with a Rails 8 Dockerfile, managed Postgres and an S3-compatible bucket. Web: keep GitHub Pages (existing `openmanifest-web` repos), which needs no new account | P8.4, P8.5, P8.6 |
| D2 | Store and Expo accounts and identifiers: Apple team, Play Console, EAS project `1d8fa34d-2ff8-4095-ab49-29a426117a8c`, bundle id `com.dangertechnologies.openmanifest`, domains `openmanifest.org` | (a) keep the existing identifiers if the owner still controls them; (b) new identifiers (a new app in the stores) | (a) if access exists (keeps users and EAS Update channels); otherwise (b) with a new EAS project | P3.21 (owner part), P8.2, P8.3, P8.6, owner device checks from Phase 3 |
| D3 | Dropzone eligibility defaults (BUG-033): the 2023 Settings release turned on `require_membership`, `require_rig_inspection`, `require_reserve_in_date`, `require_equipment`, `require_license`, `require_credits` for all existing dropzones | (a) keep strict defaults; (b) permissive defaults for new dropzones and backfill existing ones as permissive; (c) permissive for existing, strict for new | (b) new and existing dropzones default to `require_credits` = value of `is_credit_system_enabled`, everything else `false`; operators opt in | P6.14 |
| D4 | Facebook login (BUG-084) | (a) drop Facebook login on all platforms; (b) re-implement with `expo-auth-session` | **Decision: (a) drop Facebook login on all platforms (owner, 2026-10-11, approved as D-UI7 of the UI plan).** | none (P3.3 unblocked) |
| D5 | Generalisation go-ahead and naming strategy (GENERALISATION.md §0, §3) | (A) rename tables, models, API and client now; (B) keep internal names, add generic API aliases and profile labels, rename internals later; (C) labels only | **Decision: go ahead with (A), rename in place with no compatibility layer; keep `Load` as `Load` (owner, 2026-10-11).** | none (P7.1–P7.31 unblocked) |
| D6 | Generalisation scope: target industries (GENERALISATION.md §1) | — | **Decision: skydiving, scuba diving, snorkel trips, whale watching, fishing charters, parasailing, whitewater rafting, scenic flights, hot-air balloons, gliding clubs, tandem paragliding, safari drives and bus tours, each configured by an industry template chosen at operator creation (owner, 2026-10-11).** People only (no cargo); one destination per slot or an ordered list per load; boarding at the start only | none |
| D7 | Is there a 2023 production database to carry forward? | (a) yes: provide a dump for migration rehearsal; (b) no: start fresh | **Decision: (b), the project is not in production and there is no data to keep (owner, 2026-10-11).** | none (P8.8 uses the D7 (b) path) |
| D8 | Peer-to-peer credit transfers between members (BUG-008) | (a) remove (only staff with `createUserTransaction` move credits); (b) keep, limited to the same dropzone and the sender's available balance | (a) | P6.7 |
| D9 | Customer booking, timetables and bus-tour scope | — | **Decision: customer self-booking (including tandems for skydiving and paragliding, tours, flights) is built by Phase B (design in `docs/features/BOOKING_PLAN.md`). Phase 7 builds only the manifest-side seam (P7.17) and ships bus tours staff-manifested; bus tours become a full fit when booking lands (owner, 2026-10-11).** | none |
| D10 | Branding for non-skydiving operators | (a) keep "OpenManifest", replace airplane icons with vehicle-kind icons, skydiving illustrations only for the skydiving template; (b) per-template themes; (c) skydiving look everywhere | **Decision: (a) (owner, 2026-10-11).** | none (P7.22) |
| D11 | Online payments for customer bookings | — | **Decision: built by Phases C and B (designs in `docs/features/`); not in Phase 7 (owner, 2026-10-11).** | none |

Decisions recorded in the design documents (all decided by the owner on 2026-10-11): D-UI1–D-UI11 (UI plan; D-UI6's
vocabulary is replaced by D5 and GENERALISATION §3/§13), CD1–CD7 (COMMERCE_FOUNDATION §2), BD1–BD7 (BOOKING_PLAN §2),
SD1–SD4 (WEBSHOP_PLAN §2).

## Executor instructions

These are the standing rules for every executor session. Read this whole section, then the task you pick, then every
document the task links, before changing anything.

### Session setup

1. Both repositories must be attached to the session (backend `OpenManifest/openmanifest-server`, client
   `OpenManifest/openmanifest`). If one is missing, stop and report it.
2. Start services and boot the apps as described in [`reference/CLOUD_ENV.md` §4](reference/CLOUD_ENV.md#4-per-session-commands).
   If the setup script version required by the task (CLOUD_ENV §1) is not installed, set the task to
   `owner-check (install setup script version X)` and stop.
3. Work through the queue autonomously: after finishing a task (PR opened, status updated), pick the next task by the
   rules below and continue until no task qualifies or a stop condition is hit. Each task still gets its own branch,
   commits and PR, and the acceptance criteria are checked per task; never combine tasks.

### Picking the task

- Go through the **Execution order** table from top to bottom, and within a row in the order listed. Pick the first
  task whose `Status` is `todo` and whose `Depends on` tasks are all `done`. Skip tasks that are `blocked (…)`,
  `owner-check (…)` or `superseded (…)`.
- If no task qualifies, report that and stop. Do not start a task whose dependencies are `owner-check`; the owner sets
  them to `done` after checking. Phase verify tasks are owner gates for releases, not dependencies of later work.

### Git workflow

- **Base branch**: `staging` (the default branch of both repos).
- For each task, run `git fetch origin staging` in every repo the task touches, then
  `git checkout -B <branch> origin/staging`, where `<branch>` is the task's `Branch:` value exactly (`modernise/…` for
  Phases 0–8 and U, `feature/…` for Phases C, B and S).
- Make the changes, then run every "Acceptance criteria (cloud VM)" command and keep the output for the PR description.
- Commit using Conventional Commits with the task ID in the subject, for example
  `chore(deps): upgrade rails to 7.1 [P2.3]` or `fix(manifest): count slots once [P6.9]`. Several commits per task are fine.
- Push with `git push -u origin <branch>`. Open a PR into `staging` with `gh pr create --base staging --head <branch>`.
  If `gh` is not authenticated in the session, use the GitHub MCP `create_pull_request` tool. The PR body must contain:
  the task ID and title, a summary of the changes, the acceptance-criteria output, and any owner checks.
- **Stacked tasks.** A dependency counts as `done` once its PR sets it to `done`, even if the owner has not merged it
  yet. In that case branch from the dependency's task branch instead of `origin/staging`, still open the PR into
  `staging`, and start the PR body with `Stacked on <PR URL>; merge that first.` After the dependency merges, merge
  `origin/staging` into the stacked branch (never rebase a pushed branch). Do not merge PRs yourself.
- **Cross-repo tasks** (`Repo: both`): one branch with the same name in each repo, one PR per repo. Each PR body links the
  other PR. Merge order: backend first unless the task says otherwise.
- Never force-push. Never rewrite history on `staging` or `main`. Never commit secrets, `.env` files, local-only config
  (`/etc/hosts` edits, `vendor/bundle`, `.bundle/`, `node_modules`, `web-build/`, `dist/`), or files outside the task's scope.
- Pass-1 throwaway changes (Gemfile Ruby patch, scratch seeds) were never committed. Tasks recreate them properly.

### Status tracking

- In the same PR, update the task's `Status:` line in this file (the backend repo's copy is the only one; for client-only
  tasks, also open a one-line backend PR updating the status, or include the status change in the backend PR of a
  cross-repo task):
  - `done`: every cloud-VM acceptance criterion passed and the owner section says "none".
  - `owner-check (…)`: the code is done and the only remaining criteria need a real device or an account. List exactly
    what the owner must check.
  - `superseded (by …)`: the task's work was merged into the named tasks. It is never picked, and no task depends on it.
  - `blocked (…)`: one-line reason, for example `blocked (bundle install fails: geokit-rails needs Ruby < 4)`.
- Bugs found while working go into [`reference/BUGS.md`](reference/BUGS.md) with the next free ID. Do not fix them unless
  the task's `Fixes:` line covers them. When a task fixes a bug, prefix that bug's Description with `FIXED in P{x}.{y}:`.

### Stop conditions

Stop working on a task, set it to `blocked (<reason>)`, commit and push that status change (PR if needed), and report, when:

- an acceptance criterion cannot be met after following the steps;
- a step is wrong for the code as you find it (file missing, version unavailable, command fails for a reason the task
  does not anticipate);
- the work turns out larger than the task's `Size` (S ≈ < 1 hour, M ≈ half a session, L ≈ a full session);
- the only way forward is an architectural change the task does not describe.

Do not improvise a different design. Do not skip, disable or delete tests to get green. Exception: marking a test
`pending "BUG-xxx"` when the task explicitly says so.

### Conventions used in tasks

- Paths are relative to the repo named in `Repo:`. In `Repo: both` tasks, paths start with `backend:` or `client:`.
- "Backend env" means the variables in CLOUD_ENV §3/§4 (`PGHOST`, `PGUSER`, `PGPASSWORD`, `SECRET_KEY_BASE`,
  `BACKEND_URL`, `DISABLE_SPRING`).
- "Client checks" means, in the client repo: `yarn install --frozen-lockfile && yarn check:types && yarn check:linting &&
  yarn check:testing`.
- "Web export" means `EXPO_ENV=staging npx expo export:web` (SDK ≤ 49) or `EXPO_ENV=staging npx expo export --platform web`
  (SDK ≥ 50, from P3.7). It must exit 0.
- Versions named in tasks were verified on 2026-10-08. If an exact version no longer installs, use the newest patch of
  the same minor and note it in the PR.

### Client UI work

These rules apply to every task that changes the client, in every phase.

**Test tiers.** Slow UI suites run once per batch, not on every change. "Web smoke test" in any task means tier 2 once
U0.1 is `done` (before that, `node scripts/web-smoke.mjs` as in CLOUD_ENV §4).

| Tier | What | Command (client) | When |
|---|---|---|---|
| 1 | types, lint, Jest | client checks; while working, `yarn jest <paths>` for touched files | after each change, as often as you like |
| 2 | UI smoke: Playwright `smoke` project (390×844 and 1440×900, light, skydiving operator), layout invariants and axe on the routes the task touched | `yarn test:ui:smoke --grep @<tag>` (tags in each task), then once untagged before pushing | **once per task**, after the change is complete, before push; CI runs it on every PR |
| 3 | UI full: Playwright `full` project (360×640, 390×844, 820×1180, 1440×900 × light/dark × skydiving/generic operator, 200 % text, visual regression) and the Android emulator flows (Maestro, from U3.1) | `yarn test:ui:full` locally; `ui-full` and `android-ui` workflows by `workflow_dispatch` on the task branch | **only in checkpoint and verify tasks**, and weekly on `staging` |
| 4 | owner on real devices | `client:docs/SMOKE_TEST.md` sections named in the checkpoint | listed in checkpoint and verify PRs; required only before production |

- The Android half of tier 3 applies once U3.1 is `done`; if U3.1 is blocked, run tier 3 on web only and say so.
- Do not run tier 3 outside a checkpoint or verify task. If a tier 2 run shows a problem outside your task's area,
  write it in the PR body under "For the checkpoint" and leave it.
- Visual baselines (`toHaveScreenshot`) are created and updated only in checkpoint and verify tasks, only for routes the
  batch changed, with the diff images attached to the PR. Other tasks never pass `--update-snapshots`.
- If tier 3 fails in a checkpoint, fix the regressions in the checkpoint PR when each fix is small (< 30 lines);
  otherwise set the checkpoint `blocked (<failing flow>)` and add a fix task before it.
- A batch is the set of tasks between two checkpoints; stack its PRs ("Stacked tasks" above).

**Definition of done for a new or converted screen** (from U2.8 on, every new screen in any phase meets it): no
`react-native-paper` import; no hex/`rgb(`/named colour, numeric `fontSize` or numeric spacing outside
`app/ui/tokens`; no raw `Pressable`/`Touchable*` with `onPress` outside `app/ui`; every user-visible string through
`t()`; every interactive element has a role and a name (tests query with `getByRole`); the directory is added to the
lint allow-list in `client:eslint/ui-converted.js` so the rules become errors there.

**Conventions.** Import UI from `app/ui` (`import { Button, ListRow } from 'app/ui'`); styles through
`useStyles((t) => …)` from `app/ui/theme`; sizes from `t.space`, `t.type`, `t.radius`, `t.density`; breakpoints and pointer
from `useDevice()`; strings with `useTranslation(['common', 'terms'])` and the term keys of GENERALISATION §13; sentences
take terms as parameters (`t('common:newLoad', { load: t('terms:load') })`); dates, money and quantities through
`app/i18n/format.ts`; new navigation entries go in the destinations table (`app/navigation/destinations.ts`, U1.1) with
their permission and module. Commit scopes: `ui`, `nav`, `board`, `load`, `picker`, `today`, `people`, `setup`,
`i18n`, `test`, `ci`, plus the feature scopes of each phase.

### Names after the rename

From P7.6 on, code uses the names in GENERALISATION §3 (`Operator`, `Membership`, `Vehicle`, `Guest`, `ActivityType`,
`DailyLog`, `body_mass_kg`, …; `Load` and `Slot` keep their names). A few task Contexts written before the rename still
name old files or identifiers (`dropzone`, `plane`, `rig`, `passenger`, `screens/authenticated/dropzone/…`): map them
through `config/vocabulary.yml`. A path that moved under the vocabulary map is not a stop condition.

### Commerce, booking and webshop tasks (Phases C, B, S)

- **Rules for every task** at the start of each of these phases apply in addition to everything above.
- **External services**: `api.stripe.com`, `js.stripe.com` and `challenges.cloudflare.com` are not reachable from the
  VM. Specs stub HTTP with WebMock and recorded fixtures under `spec/fixtures/stripe/` and `spec/fixtures/turnstile/`.
  Never put real keys in fixtures. If the owner later allowlists Stripe (CLOUD_ENV §2) with test-mode keys, tasks may
  add an opt-in `STRIPE_LIVE_TESTS=1` spec group; CI never runs it. Real payments need a deployed API with a public
  HTTPS URL for webhooks (P8.4); until then cloud-VM acceptance uses the fake payment adapter (C2.1), and Stripe
  test-mode checks are owner checks on staging.
- **Secrets**: new server variables (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `TURNSTILE_SECRET_KEY`) go into the
  environment-variable table of [`reference/README.md`](reference/README.md) §8 by name only. Publishable keys
  (`EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY`, `EXPO_PUBLIC_TURNSTILE_SITE_KEY`) are not secrets and go into the client's
  per-environment config.
- **Permissions**: new permissions go into the list in `config/seed/access.yml`; default grants go into the base
  templates' role presets (`config/industries/_*/presets.yml`, P7.7), and a data migration grants them to the matching
  roles of existing operators.
- **Caches and rate limits** use `Rails.cache`, which is Solid Cache in production (no Redis).
- **Decisions** for these phases live in the design documents' decision tables; record new ones there
  ("Decision: …, date") and unblock dependent tasks in the next task's PR.

---

## Execution order

The one queue for every open task in this file (rule in "Picking the task"). Dependencies are hard constraints; the
order is the priority. Tasks with status `done`, `owner-check` or `superseded` are not listed.

| # | Stage | Tasks, in order | Why here |
|---|---|---|---|
| 3 | Phase 7 stage B: generic model | P7.17, UB.3 | Destinations, vehicles, crew, calls, units and currency, certifications, equipment, escorts, eligibility, booking seam. Old screens get the smallest change; new setup screens use `app/ui`. |
| 4 | Manifest UI | U3.1, U3.2, U3.3, U3.4, U3.5, U3.6, U3.7, U3.8, U3.9, U3.10 | Board, load and picker built once, for the generic model (replaces P7.19). Checkpoints U3.6, U3.10. |
| 5 | Member UI | U4.1, U4.2, U4.3, U4.4, U4.5 | Today, self-booking, Wallet, Inbox. Checkpoint U4.5. |
| 6 | People and setup | U5.1, U5.2, U5.3, U5.4, U5.5, U5.6, U5.7, U5.8, U5.9 | People, profile, Setup and Rules, permissions, conditions, reports. Checkpoints U5.4, U5.9. |
| 7 | Phase 7 stage C: module-aware UI and terminology | P7.22, P7.20, P7.21 | Isolate skydiving features, then enforce translated strings and the vocabulary check, then server copy. |
| 8 | UI hardening | U6.1, U6.2, U6.3, U6.4, U6.5 | Remove Paper, motion, performance, retire the old board; U6.5 is the UI owner gate. |
| 9 | Phase 7 stage D: onboarding and templates | P7.23, P7.24, P7.25, P7.26, P7.27, P7.28, P7.29, P7.30, P7.31 | Operator wizard on the new UI, then one template per task; P7.31 verifies. |
| 10 | Release | P8.1, P8.2, P8.3, P8.4, P8.5, P8.6, P8.7, P8.8, P8.9 | Versioning, deploy and stores; most tasks wait for D1 and D2, and the queue moves on while they do. |
| 11 | Commerce foundation | C1.1, C1.2, C1.3, C2.1, C2.2, C2.3, C2.4, C2.5, C2.6, C2.7, C2.8, C2.9, C2.10, C2.11 | Money, ledger, Stripe, platform fee, checkout, coupons. Shared by booking and the webshop. |
| 12 | Booking | B1.1, B1.2, B1.3, B1.4, B1.5, B1.6, B1.7, B1.8, B2.1, B2.2, B2.3, B2.4, B2.5, B3.1, B3.2, B3.3, B3.4 | Operators' highest-value sales; if a booking task is blocked, the queue continues with the webshop. |
| 13 | Webshop | S1.1, S1.2, S1.3, S1.4, S2.1, S2.2, S2.3, S3.1, S3.2, S3.3, S4.1, S4.2, S4.3, S4.4 | Catalogue, stock, checkout, virtual products, fulfilment, reports. |
| 14 | Waiting for decisions | P6.7, P6.14 | Picked when D8 and D3 are decided. |

What the merge of the plans changed (2026-10-11), so nothing is built twice:

- P7.18 (i18n wiring) is done by U0.6; P7.19 (manifest screens' strings) by U3.3–U3.9; P7.22's navigation step by
  U1.1. U0.6 uses GENERALISATION §13's term keys and the operator's terminology instead of bundled profiles.
- UB.3 (eligibility with reasons) became step 4 of P7.16 (`Membership.eligibility`); UB.4's call presets are P7.11's
  call schedule, and its remaining part is the new UB.3 (last slot and call time).
- Phase U's terminology phase (old U6.1–U6.5) is gone: API terms are in U0.6, units and currency in P7.12, route aliases
  are not needed (D5: rename in place, P7.4), enforcement is P7.20. UI hardening is now U6.1–U6.5.
- The operator currency moved from C1.1 to P7.12 (the wizard and the formatters need it before Phase C).
- Phase C, B and S tasks use the renamed code (Operator, Membership, Vehicle, Guest), build their screens on `app/ui`
  in the shell's destinations (Platform, Setup → Business, Bookings, Shop, Reports), and test with Playwright. B3.2 uses
  Phase 7's guests, escorts and prepaid slots; booking chooses the markdown renderer that the webshop reuses; online
  top-up lives in the Wallet.
- P7.1 and C1.1 no longer wait for the P6.27 device check (phase verify tasks are release gates, not dependencies).

## Phase 0 — Baseline

Goal of the phase: both apps install, boot, lint and test reproducibly in the VM and in GitHub Actions; deploys are off;
there is an offline seed dataset and a manual smoke checklist. No application behaviour changes.

### P0.1 — Disable push-triggered deploy workflows
Status: done
Repo: both
Depends on: none
Branch: modernise/p0-1-disable-deploys
Goal: Merging into `staging` or `main` no longer deploys anything; deploy workflows only run when started manually.
Context: Every push to `staging`/`main` triggers deploys to 2023 infrastructure (BUG-057). Backend workflows:
`.github/workflows/release-staging.yml`, `release-production.yml` (Fly), `release-dokku-staging.yml`,
`release-dokku-production.yml` (Dokku on dangertechnologies.com), `release-heroku-staging.yml`,
`release-heroku-production.yml` (Heroku). Client: `.github/workflows/publish.yml` (EAS Update + GitHub Pages; it also
commits "[ci skip]: Published x.y.z" version bumps back to the branch). See reference/README.md §8.
Steps:
  1. backend: in each of the six `release-*.yml` files, replace the whole `on:` block with
     ```yaml
     on:
       workflow_dispatch:
     ```
     Keep the jobs unchanged. In `release-production.yml` and `release-staging.yml` the existing `workflow_dispatch`
     has an invalid `branches:` key; remove it.
  2. client: in `.github/workflows/publish.yml`, delete the `push:` trigger (lines `push:` / `branches:` / `- main` /
     `- staging`) and keep `workflow_dispatch:` with its `inputs:`.
  3. Add one line at the top of each edited file: `# Disabled for automatic runs during modernisation (P0.1). Re-enabled in P8.6.`
Acceptance criteria (cloud VM):
  - backend: `ruby -ryaml -e 'Dir[".github/workflows/*.yml"].each { |f| y = YAML.load_file(f); on = y["on"] || y[true]; puts "#{f}: #{on.keys.inspect}" }'` lists only `["workflow_dispatch"]` for every `release-*.yml`.
  - client: the same command run in the client repo lists only `["workflow_dispatch"]` for `publish.yml`.
  - `grep -n "push:" backend:.github/workflows/release-*.yml client:.github/workflows/publish.yml` prints nothing.
Acceptance criteria (owner, real device):
  - none
Out of scope: the CI workflows (`specs.yml`, `test.yml`, `codeql-analysis.yml`), which are handled in P0.4 and P0.7; deleting
the deploy workflows.
Risk / rollback: none at runtime. Revert the commit to restore the triggers.
Size: S
Fixes: BUG-057

### P0.2 — Pin the backend to Ruby 3.1.6 and document local configuration
Status: done
Repo: backend
Depends on: P0.1
Branch: modernise/p0-2-ruby-316
Goal: `bundle install` and `bin/rails s` work in the VM with the preinstalled Ruby 3.1.6, without local patches.
Context: The repo pins Ruby 3.1.3 (`.ruby-version`, `Gemfile:6`, `Gemfile.lock` "RUBY VERSION"), which is not installed and
cannot be downloaded (cache.ruby-lang.org is blocked). 3.1.6 is the latest 3.1 patch release, so the change is a patch bump only.
`pg` needs `libpq-dev`, which the setup script installs. See reference/README.md §9 and CLOUD_ENV.md.
Steps:
  1. Set `.ruby-version` to `3.1.6`.
  2. In `Gemfile`, change `ruby "3.1.3"` to `ruby "3.1.6"`.
  3. Run `bundle _2.3.26_ update --ruby`, then `git diff Gemfile.lock`. Only the `RUBY VERSION` section may change
     (to `ruby 3.1.6p260`). If anything else changes, `git checkout Gemfile.lock` and edit just that line by hand.
  4. In `.github/workflows/specs.yml`, set `RUBY_VERSION: 3.1.6` (the file is replaced in P0.4).
  5. Add `.env` to `.gitignore` (dotenv-rails loads it in development/test).
  6. Create `.env.example` containing only variable names with safe local values:
     ```
     # Copy to .env for local development. Never commit .env.
     BACKEND_URL=http://local.openmanifest.org:5000/
     FRONTEND_URL=http://local.openmanifest.org:19006
     PGHOST=localhost
     PGUSER=root
     PGPASSWORD=root
     REDIS_URL=redis://localhost:6379/0
     # SECRET_KEY_BASE=<generate with: openssl rand -hex 64>
     # Production only: SMTP_SERVER SMTP_PORT SMTP_DOMAIN SMTP_USERNAME SMTP_PASSWORD GOOGLE_PROJECT GOOGLE_BUCKET
     # GOOGLE_BUCKET_CREDENTIALS GOOGLE_MAPS_KEY APPSIGNAL_PUSH_API_KEY RAILS_MASTER_KEY
     ```
Acceptance criteria (cloud VM):
  - `bundle install` exits 0 with `ruby -v` reporting 3.1.6 (no `RBENV_VERSION` override).
  - With the backend env set: `bin/rails runner 'puts DzSchema.to_definition.lines.count'` prints a number > 3000.
  - `bin/rails db:create db:schema:load db:seed` exits 0 on a fresh dev database. Then
    `bin/rails s -b 0.0.0.0 -p 5000` in the background, and `curl -s -o /dev/null -w "%{http_code}" http://local.openmanifest.org:5000/graphql` prints `200`.
Acceptance criteria (owner, real device):
  - none
Out of scope: upgrading any gem; `docker/Dockerfile` (rewritten in P8.4).
Risk / rollback: negligible (patch release). Revert the commit.
Size: S
Fixes: none

### P0.3 — Make the backend spec suite a green baseline
Status: done
Repo: backend
Depends on: P0.2
Branch: modernise/p0-3-green-specs
Goal: `bundle exec rspec` passes; every failure that comes from a known product bug is an explicit `pending "BUG-xxx"`.
Context: Pass 1 got 187 examples, 64 failures, 6 pending (reference/README.md §9). The causes:
(a) 55 failures say "membership has expired". Dropzone default settings require a membership, but the factories create
members without `expires_at` (BUG-033).
(b) 8 failures are `NoMethodError` on `created_by.can?` because slots are built without `created_by` (BUG-034).
(c) 2 failures are `undefined method 'receipts' for nil`, from finalising loads with slots that have no order (BUG-030).
(d) 1 failure is order-dependent: `spec/graphql/resolvers/users/dropzone_users_spec.rb` "Can see newly created ghost user" compares an ordered list.
`spec/rails_helper.rb` uses DatabaseCleaner transactions and `Setup::Global::Seeds` before the suite.
Steps:
  1. `RAILS_ENV=test bin/rails db:create db:schema:load`, then `bundle exec rspec 2>&1 | tee /tmp/rspec-before.log`.
  2. In `spec/factories/dropzone_users.rb`, add `expires_at { 1.year.from_now }` to the factory.
  3. Find every place a `Slot` is created without `created_by` (`grep -rn "Slot.create\|create(:slot\|build(:slot" spec`).
     Add `created_by` (the acting dropzone user, or the slot's `dropzone_user`) there and in `spec/factories/slots.rb`
     (`created_by { dropzone_user }`). Do not change `app/`.
  4. In `spec/graphql/resolvers/users/dropzone_users_spec.rb`, make the "Can see newly created ghost user" expectation
     order-independent: compare `json[:dropzoneUsers][:edges].map { |e| e[:node][:id] }` with `match_array`.
  5. Run the suite again. For each remaining failure:
     - if it is caused by a bug already in `docs/reference/BUGS.md`, add `pending "BUG-xxx: <short reason>"` as the
       first line of that example;
     - otherwise add a new bug to BUGS.md and mark the example pending with the new ID.
     Expected: the 2 finalize examples become `pending "BUG-030 …"`.
  6. Run with three different seeds to prove order-independence.
Acceptance criteria (cloud VM):
  - `bundle exec rspec` exits 0. `bundle exec rspec --seed 1` and `bundle exec rspec --seed 4242` exit 0.
  - `grep -rn 'pending "' spec | grep -v 'BUG-[0-9]\{3\}'` prints nothing.
  - `git diff --stat origin/staging -- app config db` prints nothing (no application code changed).
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing BUG-030/033/034 in application code (Phase 6); adding new specs (Phase 1).
Risk / rollback: test-only change. Revert the commit.
Size: M
Fixes: BUG-058

### P0.4 — Add backend CI on GitHub Actions
Status: done
Repo: backend
Depends on: P0.3
Branch: modernise/p0-4-backend-ci
Goal: Every push and PR runs Rubocop and RSpec, which must pass, plus a non-blocking dependency audit.
Context: `.github/workflows/specs.yml` runs RSpec with `continue-on-error: true` and contains a committed `SECRET_KEY_BASE`
(BUG-014). The test database name is `openmanifest_test_<TEST_ENV_NUMBER>` (`config/database.yml`). The test database
user and password come from `PGUSER`/`PGPASSWORD`.
Steps:
  1. Delete `.github/workflows/specs.yml`.
  2. Create `.github/workflows/ci.yml`:
     ```yaml
     name: CI
     on:
       push:
         branches: [staging, main]
       pull_request:
     concurrency:
       group: ci-${{ github.ref }}
       cancel-in-progress: true
     jobs:
       test:
         runs-on: ubuntu-24.04
         services:
           postgres:
             image: postgres:16
             env: { POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres }
             ports: ["5432:5432"]
             options: >-
               --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
           redis:
             image: redis:7
             ports: ["6379:6379"]
         env:
           RAILS_ENV: test
           PGHOST: 127.0.0.1
           PGUSER: postgres
           PGPASSWORD: postgres
           BACKEND_URL: http://localhost:5000/
           DISABLE_SPRING: "1"
         steps:
           - uses: actions/checkout@v4
           - run: sudo apt-get update -qq && sudo apt-get install -y -qq libpq-dev libvips42
           - uses: ruby/setup-ruby@v1
             with:
               ruby-version: .ruby-version
               bundler-cache: true
           - run: echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" >> "$GITHUB_ENV"
           - run: bin/rails db:create db:schema:load
           - run: bundle exec rubocop --parallel
           - run: bundle exec rspec
       audit:
         runs-on: ubuntu-24.04
         continue-on-error: true   # made blocking in P2.11
         steps:
           - uses: actions/checkout@v4
           - uses: ruby/setup-ruby@v1
             with: { ruby-version: .ruby-version }
           - run: gem install bundler-audit && bundle-audit check --update
     ```
  3. Update the README badges that point to `test.yml`/CircleCI to point to `ci.yml` (badge URL
     `https://github.com/OpenManifest/openmanifest-server/actions/workflows/ci.yml/badge.svg`).
Acceptance criteria (cloud VM):
  - `service docker start && docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest` reports no errors for `ci.yml`.
  - The PR's "CI / test" check is green on GitHub (check it with `gh pr checks` or the GitHub MCP tools).
Acceptance criteria (owner, real device):
  - none
Out of scope: deploy workflows; Brakeman (added in P6.24).
Risk / rollback: CI-only. Revert the commit.
Size: S
Fixes: BUG-058, BUG-014 (committed secret part)

### P0.5 — Add an offline development seed dataset
Status: done
Repo: backend
Depends on: P0.2
Branch: modernise/p0-5-dev-seed
Goal: `bin/rails db:seed:dev_baseline` creates a usable demo dropzone (staff, jumpers, aircraft, tickets, loads with slots) without network access.
Context: `db/seeds/demo.rb` needs randomuser.me and picsum.photos, which are blocked. `lib/tasks/seeds.rake` defines
`db:seed:<file>` for every `db/seeds/*.rb`. Pass 1 used an equivalent script to boot the app (reference/README.md §9).
Steps:
  1. Create `db/seeds/dev_baseline.rb` with exactly this content (idempotent):
     ```ruby
     # frozen_string_literal: true

     # Offline development dataset. Run: bin/rails db:seed db:seed:dev_baseline
     # Login: owner@example.com / Password1!  (all users share the password)
     raise "dev_baseline is for development/test only" if Rails.env.production?

     Setup::Global::Seeds.run!

     def dev_user(email, name, weight = 80)
       user = User.find_or_initialize_by(email: email)
       user.assign_attributes(name: name, phone: "0400000000", exit_weight: weight,
                              password: "Password1!", password_confirmation: "Password1!")
       user.skip_confirmation!
       user.save!
       user
     end

     owner = dev_user("owner@example.com", "Olive Owner")
     dropzone = Dropzone.find_by(name: "Demo Dropzone")
     unless dropzone
       dropzone = Setup::Dropzones::CreateDropzone.run!(
         name: "Demo Dropzone", owner: owner, federation: Federation.find_by(slug: "apf") || Federation.first,
         lat: nil, lng: nil, is_credit_system_enabled: true, primary_color: "#1D3557", secondary_color: "#E63946"
       )
     end
     dropzone.update!(state: "public", settings: { require_membership: false, require_rig_inspection: false,
                                                   require_reserve_in_date: false, require_equipment: false })

     plane = dropzone.planes.find_or_create_by!(name: "Caravan", registration: "VH-ABC", min_slots: 2, max_slots: 14)
     ticket = dropzone.ticket_types.find_or_create_by!(name: "Full altitude", cost: 40, altitude: 14_000,
                                                       allow_manifesting_self: true, currency: "AUD")
     dropzone.ticket_types.find_or_create_by!(name: "Tandem", cost: 0, altitude: 14_000, allow_manifesting_self: false,
                                              is_tandem: true, currency: "AUD")
     roles = dropzone.user_roles.index_by(&:name)
     license = (Federation.find_by(slug: "apf") || Federation.first).licenses.where.not(name: "No license").first
     members = {}
     [["pilot@example.com", "Pat Pilot", "pilot"], ["manifest@example.com", "Max Manifest", "manifest"],
      ["jumper1@example.com", "Jo Jumper", "fun_jumper"], ["jumper2@example.com", "Sam Skydiver", "fun_jumper"],
      ["student@example.com", "Stu Student", "student"]].each do |email, name, role|
       membership = dropzone.dropzone_users.find_or_initialize_by(user: dev_user(email, name))
       membership.assign_attributes(user_role: roles.fetch(role), credits: 400, license: license, expires_at: 1.year.from_now)
       membership.save!
       members[email] = membership
     end
     owner_membership = dropzone.dropzone_users.find_by!(user: owner)
     owner_membership.update!(credits: 1000, license: license, expires_at: 1.year.from_now)
     %w(actAsPilot actAsGCA actAsLoadMaster actAsDZSO actAsRigInspector).each { |p| owner_membership.grant!(p) }
     members["pilot@example.com"].grant!("actAsPilot")

     if Load.joins(:plane).where(planes: { dropzone_id: dropzone.id }).none?
       context = ApplicationInteraction::AccessContext.new(owner_membership)
       first = Manifest::CreateLoad.run!(access_context: context, plane: plane, pilot: members["pilot@example.com"],
                                         gca: owner_membership, load_master: owner_membership, name: "Load 1")
       Manifest::CreateLoad.run!(access_context: context, plane: plane, pilot: members["pilot@example.com"],
                                 gca: owner_membership, load_master: owner_membership, name: "Load 2")
       %w(jumper1@example.com jumper2@example.com).each do |email|
         Manifest::CreateSlot.run!(access_context: context, load: first, dropzone_user: members[email], ticket_type: ticket,
                                   jump_type: JumpType.find_by(slug: "fs") || JumpType.first, exit_weight: 80)
       end
     end
     puts "dev_baseline: dropzone #{dropzone.id}, #{dropzone.loads.count} loads. Login owner@example.com / Password1!"
     ```
  2. Add a "Development data" paragraph to `README.md` naming the command and the login.
Acceptance criteria (cloud VM):
  - On a dropped dev database: `bin/rails db:drop db:create db:schema:load db:seed db:seed:dev_baseline` exits 0. Running
    `bin/rails db:seed:dev_baseline` a second time exits 0 and does not create more loads
    (`bin/rails runner 'puts Load.count'` prints `2` both times).
  - With the server running, this prints a JSON body containing `accessToken`:
    `curl -s -X POST http://local.openmanifest.org:5000/graphql -H 'Content-Type: application/json' -d '{"query":"mutation { userLogin(email: \"owner@example.com\", password: \"Password1!\") { credentials { accessToken } } }"}'`
Acceptance criteria (owner, real device):
  - none
Out of scope: changing `db/seeds/demo.rb`; fixing the double-counted `slots_count` this dataset will show (BUG-019, P6.10).
Risk / rollback: development data only; the file refuses to run in production. Revert the commit.
Size: S
Fixes: none

### P0.6 — Make the client toolchain reproducible
Status: done
Repo: client
Depends on: P0.1
Branch: modernise/p0-6-client-toolchain
Goal: On Node 20, a clean install, type-check, lint, tests and the web export all succeed, and `yarn check:testing` actually runs Jest.
Context: In pass 1 these all worked on Node 20 (`/opt/node20`): `yarn install --frozen-lockfile` with `SENTRYCLI_SKIP_DOWNLOAD=1`,
`check:types` (tsc 4.9.4), `check:linting` (ESLint + Rome), Jest (1 suite, 8 tests), and `expo export:web` (webpack,
warnings only). But `package.json` has `"check:testing": "exit 0"`, so tests never ran (BUG-081). A 960 KB `yarn-error.log`
is committed. See client reference §8.
Steps:
  1. Create `.nvmrc` containing `20`.
  2. In `package.json`, set `"check:testing": "jest --ci"` and `"check:testing:ci": "jest --ci"`. Leave
     `testPathIgnorePatterns` alone; the ManifestScreen test is re-enabled in P1.10.
  3. `git rm yarn-error.log` (it is already in `.gitignore`).
  4. Create `.env.example`:
     ```
     # Copy to .env for local builds. Never commit .env.
     EXPO_ENV=local
     # Optional keys (leave empty for local work):
     GOOGLE_MAPS_ANDROID=
     GOOGLE_MAPS_IOS=
     GOOGLE_MAPS_WEB=
     APPSIGNAL_DEVELOPMENT_API_KEY=
     FACEBOOK_APP_ID=
     FACEBOOK_CLIENT_TOKEN=
     ```
     and add `.env` to `.gitignore`.
Acceptance criteria (cloud VM):
  - With `PATH=/opt/node20/bin:$PATH SENTRYCLI_SKIP_DOWNLOAD=1`, the client checks pass and `yarn check:testing`
    reports "Tests: 8 passed".
  - Web export (`EXPO_ENV=staging npx expo export:web`) exits 0 and `web-build/index.html` exists.
  - `git status --porcelain` is clean after these commands (no generated files tracked).
Acceptance criteria (owner, real device):
  - none
Out of scope: dependency upgrades; the excluded ManifestScreen test.
Risk / rollback: tooling only. Revert the commit.
Size: S
Fixes: none

### P0.7 — Add client CI on GitHub Actions
Status: done
Repo: client
Depends on: P0.6
Branch: modernise/p0-7-client-ci
Goal: Every push and PR runs the type-check, linting, tests and the web export, all of which must pass.
Context: `.github/workflows/test.yml` runs only on `pull_request`. It depends on a third-party variable-store action
(`UnlyEd/github-action-store-variable`) and on JUnit artefacts, and its test step is a no-op. CircleCI config
(`.circleci/config.yml`) is unused.
Steps:
  1. Delete `.github/workflows/test.yml` and `.circleci/config.yml`.
  2. Create `.github/workflows/ci.yml`:
     ```yaml
     name: CI
     on:
       push:
         branches: [staging, main]
       pull_request:
     concurrency:
       group: ci-${{ github.ref }}
       cancel-in-progress: true
     env:
       SENTRYCLI_SKIP_DOWNLOAD: "1"
       EXPO_NO_TELEMETRY: "1"
       CI: "1"
     jobs:
       checks:
         runs-on: ubuntu-24.04
         steps:
           - uses: actions/checkout@v4
           - uses: actions/setup-node@v4
             with: { node-version-file: .nvmrc, cache: yarn }
           - run: yarn install --frozen-lockfile
           - run: yarn check:types
           - run: yarn check:linting
           - run: yarn check:testing
       web-export:
         runs-on: ubuntu-24.04
         steps:
           - uses: actions/checkout@v4
           - uses: actions/setup-node@v4
             with: { node-version-file: .nvmrc, cache: yarn }
           - run: yarn install --frozen-lockfile
           - run: npx expo export:web
             env: { EXPO_ENV: staging, NODE_OPTIONS: --max_old_space_size=6144 }
     ```
  3. Replace the CircleCI badge in `README.md` with
     `https://github.com/OpenManifest/openmanifest/actions/workflows/ci.yml/badge.svg`.
Acceptance criteria (cloud VM):
  - `service docker start && docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest` reports no errors.
  - The PR's `CI / checks` and `CI / web-export` checks are green on GitHub.
Acceptance criteria (owner, real device):
  - none
Out of scope: `publish.yml`, `codeql-analysis.yml`.
Risk / rollback: CI-only. Revert the commit.
Size: S
Fixes: none

### P0.8 — Add a web smoke-test script for the client
Status: done
Repo: client
Depends on: P0.6, P0.5
Branch: modernise/p0-8-web-smoke
Goal: One command logs into a locally built web app backed by the local API, walks login → dropzone → manifest → load at 360×640 and 1280×800, and saves screenshots.
Context: The only runtime evidence for the UI in the VM is a web export viewed in headless Chromium. Playwright 1.56.1 is
installed globally at `/opt/node-tools/node_modules/playwright`, with browsers under `/opt/pw-browsers`. Chromium must
bypass the agent proxy for `local.openmanifest.org`, or the websocket gets 403. A web build with `EXPO_ENV=local`
calls `http://local.openmanifest.org:5000/graphql` (`build/constants.ts`). The API needs the P0.5 seed.
Steps:
  1. Create `scripts/serve-web-build.py`:
     ```python
     """Serve a static web export with index.html fallback (SPA). Usage: python3 scripts/serve-web-build.py <dir> <port>"""
     import http.server, os, sys
     ROOT, PORT = sys.argv[1], int(sys.argv[2])
     class Handler(http.server.SimpleHTTPRequestHandler):
         def __init__(self, *a, **k): super().__init__(*a, directory=ROOT, **k)
         def send_head(self):
             if not os.path.exists(self.translate_path(self.path)): self.path = "/index.html"
             return super().send_head()
     http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
     ```
  2. Create `scripts/web-smoke.mjs`. Arguments: `--base <url>` (default `http://localhost:19006`) and `--out <dir>`
     (default `./smoke-output`). Behaviour, for each viewport `{ desktop: 1280x800, phone360: 360x640 }`:
     - Load Playwright with `createRequire(import.meta.url)` from `process.env.PLAYWRIGHT_PATH ?? '/opt/node-tools/node_modules/playwright'`.
     - Launch Chromium with `args: ['--proxy-bypass-list=local.openmanifest.org,localhost']`.
     - Collect `pageerror` events.
     - Go to `<base>/login` and wait 3 s. Click `input` #0 (with `force: true`) and type `owner@example.com`. Click
       `input` #1 and type `Password1!`. Press Enter and wait 6 s.
     - Find `getByText('Dropzone', { exact: true })`, then `mouse.move` / `down` / `up` on its bounding box (a plain
       `click()` does not trigger react-native-gesture-handler touchables on web). Wait 8 s.
     - Assert the URL ends with `/dropzone/manifest` and save `<out>/<viewport>-manifest.png`.
     - Click `getByText(/Load #1\b/)` with `force: true` and wait 6 s. Assert the URL matches `/dropzone/load/\d+` and
       save `<out>/<viewport>-load.png`.
     Exit with code 1 if any assertion fails or any `pageerror` occurred, and print a one-line summary per viewport.
  3. Add `smoke-output/` to `.gitignore`.
  4. Add a "Web smoke test" section to `README.md` with the commands from CLOUD_ENV.md §4.
Acceptance criteria (cloud VM):
  - Backend dev server running with the dev_baseline seed. In the client: `EXPO_ENV=local npx expo export:web` exits 0;
    `python3 scripts/serve-web-build.py web-build 19006 &`; then `node scripts/web-smoke.mjs --out /tmp/smoke` exits 0 and
    `/tmp/smoke` contains 4 PNG files.
Acceptance criteria (owner, real device):
  - none
Out of scope: running the smoke test in GitHub Actions (needs a backend service; revisit in P8.7).
Risk / rollback: new scripts only. Revert the commit.
Size: M
Fixes: none

### P0.9 — Correct the READMEs and add the owner smoke checklist
Status: done
Repo: both
Depends on: P0.5, P0.8
Branch: modernise/p0-9-readmes
Goal: Both root READMEs describe how to set up and run the project today, and the owner has a device smoke-test checklist.
Context: The backend README says "ruby 2.7.3" and uses passworded `createuser` steps. The client README says
`yarn global add expo-cli` (the global CLI is deprecated; `npx expo` is used). Both READMEs have CircleCI badges.
Steps:
  1. backend `README.md`: replace "Requirements" and "Getting started" with: Ruby from `.ruby-version`, PostgreSQL 16,
     Redis 7, `libpq-dev`, `libvips`; the commands from CLOUD_ENV.md §4 (backend); the dev seed; links to
     `docs/reference/README.md` and `docs/MODERNISATION_PLAN.md`.
  2. client `README.md`: replace "Set up" with: Node from `.nvmrc`, `yarn install --frozen-lockfile`,
     `EXPO_ENV=local npx expo start` / `--web`, the `local.openmanifest.org` hosts entry, the web smoke test, and links to
     `docs/reference/README.md` and the backend plan.
  3. client: create `docs/SMOKE_TEST.md`, the owner checklist used by every phase-verification task. Use the content in
     "Owner smoke checklist" below.
Acceptance criteria (cloud VM):
  - Following the new backend README commands verbatim in a fresh session boots the API (`/graphql` 200).
  - Following the new client README commands verbatim produces a web export.
  - `client:docs/SMOKE_TEST.md` exists and contains the sections "Devices", "Web", "Login", "Manifest", "Layout".
Acceptance criteria (owner, real device):
  - none
Out of scope: the root `LICENSE.md` files.
Risk / rollback: docs only.
Size: S
Fixes: none

Owner smoke checklist (content for `client:docs/SMOKE_TEST.md`):

```markdown
# Owner smoke test checklist

Run on: (1) an iPhone, (2) a typical Android phone, (3) a small Android phone or emulator profile at 360×640 dp,
(4) any of them with system font size at maximum (Android: Settings → Display → Font size largest + Display size largest;
iOS: Larger Accessibility Sizes). Until EAS builds exist (Phase 3, decision D2), run the web build in the phone's browser
(`EXPO_ENV=local npx expo start --web` on your machine; open http://<your-ip>:19006 on the phone).

## Devices
- [ ] Record device model, OS version, screen size, font scale.
## Web
- [ ] Desktop browser at 1280×800: login, dropzone, manifest, load all render.
## Login
- [ ] Email login works; wrong password shows an error.
- [ ] "Sign up" and "Forgot your password?" are reachable without zooming; with the keyboard open the focused field stays visible.
- [ ] Log out, log in again without restarting the app: data loads.
## Manifest
- [ ] Select a dropzone; manifest board shows today's loads; pull to refresh updates the list.
- [ ] Create a load (staff); it appears on another device without refreshing.
- [ ] Manifest yourself; manifest a group; take someone off; slot counts are correct ("2/14" for two jumpers).
- [ ] Give a 10-minute call: push notification arrives on the jumper's device; countdown shows the right time.
- [ ] Mark as landed; cancel a load; credits are charged/refunded correctly.
## Layout
- [ ] No text, button or input is cut off horizontally on the 360 dp device in: sign-up, user setup wizard, dropzone setup wizard, weather screens.
- [ ] Floating buttons do not cover the tab bar, gesture bar or the last list item.
- [ ] Bottom sheets: every field stays visible above the keyboard; the submit button is reachable.
- [ ] At maximum font size, slot rows, tables and dialogs remain readable (no clipped text).
```

### P0.10 — Verify Phase 0
Status: owner-check (merge both Phase 0 stacks and confirm CI green on staging; run SMOKE_TEST Web/Login/Manifest on phones — see docs/verification/phase-0.md)
Repo: both
Depends on: P0.1, P0.2, P0.3, P0.4, P0.5, P0.6, P0.7, P0.8, P0.9
Branch: modernise/p0-10-verify
Goal: The baseline is proven end to end and recorded.
Context: The phase gate. The only change is a short report file.
Steps:
  1. In a fresh session, follow CLOUD_ENV.md §4: run the backend specs, Rubocop, the dev seed and the server, then the
     client checks, the web export and the web smoke test.
  2. Create `backend:docs/verification/phase-0.md` containing: date, backend and client commit SHAs, the rspec summary
     line, the jest summary line, web-smoke output, links to the green CI runs on `staging` for both repos.
Acceptance criteria (cloud VM):
  - All commands in step 1 exit 0. The CI workflow on `staging` is green in both repos (latest run).
Acceptance criteria (owner, real device):
  - Run `client:docs/SMOKE_TEST.md` sections Web, Login and Manifest in phone browsers (iPhone, Android, small Android at
    360 dp) against a locally running stack. Record results in `docs/verification/phase-0.md`; failures are expected and
    should match BUGS.md entries. The task's purpose is a recorded baseline.
Out of scope: fixing anything found.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 1 — Characterisation tests

Goal of the phase: every GraphQL operation the client sends has a backend request spec that uses the client's own
document, the API contract is checked automatically in both repos, and the critical client flows have headless tests.
Known bugs get specs marked `pending "BUG-xxx"`, which flip to passing when Phase 6 fixes them. No application behaviour
changes in this phase.

Client operations to cover (from `client:app/api/{queries,mutations,subscriptions}/*.gql`, 76 in total):

| Group (task) | Operations |
|---|---|
| Auth & session (P1.1) | `Login`, `UserSignUp`, `ConfirmUser`, `RecoverPassword`, `UpdateLostPassword`, `CurrentUser`, `LoginWithApple`, `LoginWithFacebook` |
| Dropzones & access (P1.2) | `Dropzones`, `Dropzone`, `DropzoneStatistics`, `DropzonesStatistics`, `CurrentUserPermissions`, `DropzonePermissions`, `Roles`, `CreateDropzone`, `UpdateDropzone`, `UpdateVisibility`, `UpdateRole`, `RigInspectionTemplate`, `UpdateRigInspectionTemplate` |
| Manifest (P1.3) | `Loads`, `Load`, `CreateLoad`, `UpdateLoad`, `FinalizeLoad`, `ManifestUser`, `ManifestGroup`, `MoveSlot`, `DeleteSlot`, `LoadCreated`, `LoadUpdated` |
| Users & permissions (P1.4) | `DropzoneUsers`, `DropzoneUsersDetailed`, `DropzoneUser`, `DropzoneUserDetailed`, `DropzoneUserProfile`, `UpdateUser`, `UpdateDropzoneUser`, `CreateGhost`, `ArchiveUser`, `GrantPermission`, `RevokePermission`, `JoinFederation`, `Notifications`, `UserUpdated` |
| Setup (P1.5) | `Planes`, `CreateAircraft`, `UpdateAircraft`, `ArchivePlane`, `TicketTypes`, `AllowedTicketTypes`, `CreateTicketType`, `UpdateTicketType`, `ArchiveTicketType`, `TicketTypeExtras`, `CreateTicketAddon`, `UpdateTicketAddon`, `DropzoneRigs`, `AvailableRigs`, `CreateRig`, `UpdateRig`, `ArchiveRig`, `CreateRigInspection`, `ReloadWeather`, `MasterLog`, `UpdateMasterLog` |
| Payments, activity, meta (P1.6) | `CreateOrder`, `DropzoneTransactions`, `Activity`, `ActivityDetails`, `Federations`, `Licenses`, `JumpTypes`, `AllowedJumpTypes`, `AddressToLocation` |

### P1.1 — Build the client-operation request-spec harness and cover auth operations
Status: done
Repo: backend
Depends on: P0.10
Branch: modernise/p1-1-operation-harness
Goal: Backend specs can execute any client GraphQL document by operation name, and the auth/session operations are covered.
Context: Existing GraphQL specs build their queries by hand (`spec/support/graphql/client.rb`, `spec/support/graphql_client.rb`),
so they do not prove the client's documents work. Client documents use `#import` comments and shared fragments
(`app/api/fragments/*.gql`). graphql-ruby rejects documents with unused fragments, so the harness must include only
the fragments an operation uses, transitively. Facebook/Apple logins call external APIs: stub `Login::Facebook.run!` /
`Login::Apple.run!` (WebMock is already enabled).
Steps:
  1. Create `bin/sync-client-operations` (Ruby, executable). It takes the client repo path as an argument (default
     `../openmanifest`). It copies `app/api/{queries,mutations,subscriptions,fragments}/*.gql` into
     `spec/fixtures/client_operations/<same subdir>/`, deleting stale files first, and writes the client's
     `git rev-parse HEAD` into `spec/fixtures/client_operations/SOURCE_COMMIT`. Run it and commit the copied files.
  2. Create `spec/support/client_operations.rb`:
     ```ruby
     # frozen_string_literal: true

     module ClientOperations
       ROOT = Rails.root.join("spec/fixtures/client_operations")

       def self.definitions
         @definitions ||= Dir[ROOT.join("**/*.gql")].flat_map { |f| GraphQL.parse(File.read(f)).definitions }
       end

       def self.operations = definitions.grep(GraphQL::Language::Nodes::OperationDefinition).index_by(&:name)
       def self.fragments  = definitions.grep(GraphQL::Language::Nodes::FragmentDefinition).index_by(&:name)

       # Returns the query string for the named client operation plus every fragment it uses (transitively).
       def self.document(name)
         op = operations.fetch(name) { raise KeyError, "No client operation named #{name}" }
         needed = []
         queue = [op]
         until queue.empty?
           node = queue.shift
           spreads = []
           collect = lambda do |n|
             spreads << n.name if n.is_a?(GraphQL::Language::Nodes::FragmentSpread)
             n.children.each { |c| collect.call(c) } if n.respond_to?(:children)
           end
           collect.call(node)
           spreads.uniq.each do |s|
             next if needed.include?(s)
             needed << s
             queue << fragments.fetch(s)
           end
         end
         ([op] + needed.map { |s| fragments.fetch(s) }).map(&:to_query_string).join("\n")
       end
     end
     ```
  3. Create `spec/support/client_operation_helper.rb`. It defines
     `client_operation(name, variables: {}, as: nil)`, which POSTs to `/graphql` with
     `params: { query: ClientOperations.document(name), variables: variables.to_json, operationName: name }`, adds
     `headers: as.create_new_auth_token` when `as` (a `User`) is given, and returns
     `JSON.parse(response.body).with_indifferent_access`. Include it in `type: :request` specs.
  4. Create `spec/requests/client_operations/auth_spec.rb` with one `describe` per operation (`Login`, `UserSignUp`,
     `ConfirmUser`, `RecoverPassword`, `UpdateLostPassword`, `CurrentUser`, `LoginWithApple`, `LoginWithFacebook`),
     covering at least: happy path (asserting the fields the client selects are present), invalid input, unauthenticated
     where relevant. Use `ActionMailer::Base.deliveries` for the recover/confirm flows.
  5. Add `spec/requests/client_operations/harness_spec.rb`. It asserts that `ClientOperations.operations.keys.size == 76`
     and that every operation parses together with its fragments without errors
     (`GraphQL::StaticValidation::Validator.new(schema: DzSchema).validate(GraphQL::Query.new(DzSchema, ClientOperations.document(name)))[:errors]` is empty for all 76).
Acceptance criteria (cloud VM):
  - `bundle exec rspec spec/requests/client_operations` exits 0. The harness spec validates all 76 operations with 0 errors.
  - `bundle exec rspec` exits 0. `bundle exec rubocop` exits 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: changing `app/`; deleting the existing hand-written GraphQL specs.
Risk / rollback: test-only. Revert the commit.
Size: M
Fixes: none

### P1.2 — Cover dropzone and access operations
Status: done
Repo: backend
Depends on: P1.1
Branch: modernise/p1-2-spec-dropzones
Goal: Every operation in the "Dropzones & access" group has request specs using the client document.
Context: Operations listed in the Phase 1 table. Behaviour to pin: `Dropzones` returns staff dropzones plus public ones
(`Dropzone.for`, `app/models/dropzone.rb:85-90`). `dropzone { currentUser }` creates a membership (BUG-005; pin it as
current behaviour with a comment). `UpdateDropzone` with `banner` raises (BUG-041). `UpdateVisibility` rules are in
`app/interactions/setup/dropzones/update_visibility.rb`.
Steps:
  1. Create `spec/requests/client_operations/dropzones_spec.rb` with a `describe` per operation. Use the factories in
     `spec/factories`. For each operation cover: permitted user → success fields; user without permission → `errors`
     or `AUTHENTICATION_ERROR` as the code currently returns; and the known-bug behaviours as `pending "BUG-xxx"`
     examples asserting the correct behaviour (BUG-041 banner upload; BUG-005 "reading a dropzone does not create a membership").
  2. Where the current behaviour is wrong but has no BUG entry yet, add one to BUGS.md and a pending example.
Acceptance criteria (cloud VM):
  - `bundle exec rspec spec/requests/client_operations/dropzones_spec.rb` exits 0 and contains at least one example per
    operation in the group (`grep -c "describe \"" spec/requests/client_operations/dropzones_spec.rb` ≥ 13).
  - `bundle exec rspec` and `bundle exec rubocop` exit 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing bugs.
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.3 — Cover manifest operations and subscription triggers
Status: done
Repo: backend
Depends on: P1.1
Branch: modernise/p1-3-spec-manifest
Goal: Load and slot operations, and the `loadCreated`/`loadUpdated` broadcasts, are pinned by specs.
Context: Manifesting rules and bugs: counters (BUG-019), max slots (BUG-025), group numbers (BUG-027), extras (BUG-028),
finalize with tandems (BUG-030), moveSlot (BUG-007, BUG-031), deleteSlot (BUG-032), students manifesting others (BUG-006),
landing counters (BUG-026), state rules (BUG-035). Subscriptions are triggered from `app/models/load.rb:115-136`. The
test environment uses the ActionCable `test` adapter (`config/cable.yml`), so use `have_broadcasted_to` /
`ActionCable.server.pubsub.broadcasts("graphql-event::loadCreated:dropzoneId:<id>")`.
Steps:
  1. Create `spec/requests/client_operations/manifest_spec.rb` covering `Loads` (date filter in the dropzone time zone),
     `Load`, `CreateLoad`, `UpdateLoad` (call: `dispatchAt` + `state`; cancel call; plane change), `FinalizeLoad` (landed,
     cancelled, refunds), `ManifestUser` (self, other by staff, tandem with passenger, insufficient credits, double
     manifest), `ManifestGroup`, `MoveSlot`, `DeleteSlot`.
  2. Add pending examples asserting correct behaviour for each bug listed in Context (one example per bug ID at least).
  3. Create `spec/requests/client_operations/subscriptions_spec.rb`. It asserts that `CreateLoad` broadcasts on
     `graphql-event::loadCreated:dropzoneId:<id>`, that `UpdateLoad` broadcasts `loadUpdated:loadId:<id>`, and that the
     `LoadCreated`/`LoadUpdated` subscription documents validate (via `ClientOperations.document`). Add a pending
     "broadcast exactly once" example (BUG-036).
Acceptance criteria (cloud VM):
  - Both spec files exist and pass. Every manifest operation has at least two examples. `grep -o 'pending "BUG-[0-9]*' spec/requests/client_operations/manifest_spec.rb | sort -u` includes BUG-006, BUG-007, BUG-019, BUG-025, BUG-026, BUG-027, BUG-028, BUG-030, BUG-031, BUG-032.
  - `bundle exec rspec` and `bundle exec rubocop` exit 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing bugs.
Risk / rollback: test-only.
Size: L
Fixes: none

### P1.4 — Cover user, permission, federation and notification operations
Status: done
Repo: backend
Depends on: P1.1
Branch: modernise/p1-4-spec-users
Goal: The "Users & permissions" operations are pinned by request specs.
Context: Known bugs: BUG-037 (`updateDropzoneUser` NameError after save), BUG-038 (`updateUser` for others), BUG-012
(ghost takeover), BUG-013 (PII fields), BUG-055 (`joinFederation` without memberships), BUG-056. `JoinFederation`
calls the APF API through `Federations::ApfSync`; stub it with the existing `spec/support/contexts/mock_apf_call.rb`.
`UserUpdated` is triggered in `app/models/dropzone_user.rb:219-228`.
Steps:
  1. Create `spec/requests/client_operations/users_spec.rb` covering every operation in the group, with pending
     examples for the bugs above.
  2. Cover role changes in `UpdateDropzoneUser` (role ids lower than the actor's only, `grantPermission` required).
Acceptance criteria (cloud VM):
  - The spec file passes and has at least one `describe` per operation (≥ 14). `bundle exec rspec` and `bundle exec rubocop` exit 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing bugs.
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.5 — Cover setup operations (aircraft, tickets, extras, rigs, inspections, weather, master log)
Status: done
Repo: backend
Depends on: P1.1
Branch: modernise/p1-5-spec-setup
Goal: The "Setup" operations are pinned by request specs.
Context: Known bugs: BUG-039 (`archiveTicketType`, `archiveRig` for others), BUG-040 (`reloadWeatherCondition` without
`dropzoneId`), BUG-041 (packing card upload), BUG-042 (inspection notifications), BUG-061 (extras link clobbering),
BUG-009/BUG-010 (cross-tenant edits), BUG-044 (`masterLog`). Weather creation calls `markschulze.net` in a model
callback: stub it with `WebMock.stub_request(:get, /markschulze\.net/).to_return(body: { speed: {}, direction: {}, temp: {} }.to_json)`.
Steps:
  1. Create `spec/requests/client_operations/setup_spec.rb` covering every operation in the group, with pending examples
     for each bug listed.
Acceptance criteria (cloud VM):
  - The spec file passes with ≥ 21 `describe` blocks. `bundle exec rspec` and `bundle exec rubocop` exit 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing bugs.
Risk / rollback: test-only.
Size: L
Fixes: none

### P1.6 — Cover payments, activity and meta operations; enforce full coverage
Status: done
Repo: backend
Depends on: P1.2, P1.3, P1.4, P1.5
Branch: modernise/p1-6-spec-payments-meta
Goal: All 76 client operations are exercised by at least one request spec, and a spec fails if a new client operation appears without one.
Context: Known bugs: BUG-008 (credit minting), BUG-048 (float money and refund truncation), BUG-003 (activity leak).
`AddressToLocation` calls Google Geocoding; stub `Geokit::Geocoders::GoogleGeocoder.geocode`.
Steps:
  1. Create `spec/requests/client_operations/payments_meta_spec.rb` for the operations in the P1.6 group, with pending
     examples for BUG-008, BUG-048 and BUG-003.
  2. Create `spec/requests/client_operations/coverage_spec.rb`. It reads all files in `spec/requests/client_operations/`,
     and for every name in `ClientOperations.operations.keys` it asserts that the string `client_operation("<Name>"` or
     `client_operation('<Name>'` appears in at least one of them.
Acceptance criteria (cloud VM):
  - `bundle exec rspec spec/requests/client_operations/coverage_spec.rb` exits 0. `bundle exec rspec` and `bundle exec rubocop` exit 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing bugs.
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.7 — Add tenant-isolation characterisation specs
Status: done
Repo: backend
Depends on: P1.6
Branch: modernise/p1-7-spec-tenancy
Goal: One spec file states, as pending examples, every cross-tenant access the API must refuse.
Context: Pass-1 audit findings BUG-001…BUG-011 and BUG-013. These examples become the acceptance tests of Phase 6
security tasks. Set-up: two dropzones A and B with their own staff, members, loads, planes, tickets, rigs, events and
a blob. The actor is a regular member of A, or the owner of A.
Steps:
  1. Create `spec/requests/tenant_isolation_spec.rb`. Add one example per row below, each marked
     `pending "BUG-xxx"` and asserting refusal (`data` field nil plus an error, or the record unchanged):
     `load(id: B's load)` (BUG-002), `loads(dropzone: B)` (BUG-002), `dropzoneUser(id: B member)` (BUG-002),
     `dropzoneUsers(dropzone: B)` (BUG-002), `planes`/`ticketTypes`/`extras`/`masterLog`/`availableRigs` for B (BUG-002),
     `activity` without filter returns no B events (BUG-003), `image(id: B blob)` (BUG-004), `updatePlane` on B's plane
     does not create a membership in B (BUG-005), `createSlot` for another member by a student (BUG-006), `moveSlot` B →
     A (BUG-007), `createOrder` paying a B member (BUG-008), `updateFormTemplate` on B's template with `dropzoneId: A`
     (BUG-009), `updateTicketType(dropzoneId: A)` on B's ticket (BUG-010), subscribing to `loadUpdated(loadId: B load)` is
     refused (BUG-011), `user { email phone pushToken }` of a B member is null (BUG-013).
  2. Add a non-pending example that documents the singleton (BUG-001):
     `expect(AccessContext::CurrentUser.for(u1)).to equal(AccessContext::CurrentUser.for(u2))`, with the comment
     `# BUG-001: flips to not_to equal in P6.1`.
Acceptance criteria (cloud VM):
  - The file passes with ≥ 16 examples, all pending except the BUG-001 one. `bundle exec rspec` exits 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing.
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.8 — Commit the server schema and fail CI when it drifts
Status: done
Repo: backend
Depends on: P1.1
Branch: modernise/p1-8-schema-dump
Goal: `schema.graphql` in the backend repo always equals the schema the server serves, so the client can check its documents offline.
Context: The client keeps its own copy (`client:schema.graphql`), refreshed in 2023 by curling a running server
(`client:package.json` `gql:schema:*`). `GraphqlController#index` prints the schema with
`GraphQL::Schema::Printer.print_schema(DzSchema)`.
Steps:
  1. Create `lib/tasks/graphql.rake` with task `graphql:schema:dump`, which writes
     `GraphQL::Schema::Printer.print_schema(DzSchema)` to `schema.graphql` at the repo root.
  2. Run it and commit `schema.graphql`.
  3. Create `spec/schema_dump_spec.rb`. It expects `File.read(Rails.root.join("schema.graphql"))` to equal
     `GraphQL::Schema::Printer.print_schema(DzSchema)`, with the failure message "Run bin/rails graphql:schema:dump and commit schema.graphql".
Acceptance criteria (cloud VM):
  - `bin/rails graphql:schema:dump && git diff --exit-code schema.graphql` exits 0 after the commit.
  - `diff <(grep -v '^\s*$' schema.graphql) <(grep -v '^\s*$' ../openmanifest/schema.graphql)` shows no type or field
    differences (the client copy was in sync in pass 1). Record any differences in the PR.
  - `bundle exec rspec` exits 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: changing the schema.
Risk / rollback: test-only.
Size: S
Fixes: none

### P1.9 — Replace the client's broken GraphQL check with an offline contract check
Status: done
Repo: client
Depends on: P1.8
Branch: modernise/p1-9-contract-check
Goal: `yarn check:graphql` validates every client document against the backend's committed schema without network access, and runs in CI.
Context: `build/scripts/schema-compatibility.ts` posts to `<api>/graphql/validate`, a route that does not exist (BUG-080).
Pass 1 validated all documents with graphql-js `validate()` against the live schema: 0 errors. The backend now commits
`schema.graphql` (P1.8).
Steps:
  1. Create `scripts/sync-schema.mjs`. It copies `<backend>/schema.graphql` (argument; default `../openmanifest-server/schema.graphql`)
     to `schema.graphql`.
  2. Create `scripts/validate-graphql.mjs`. It loads `graphql` from `node_modules`, builds the schema from `schema.graphql`,
     parses every `app/api/**/*.gql` file, concatenates the ASTs (`concatAST`), runs `validate(schema, doc)`, prints each
     error with its file, and exits 1 on any error.
  3. In `package.json`, set `"check:graphql": "node scripts/validate-graphql.mjs"` and add `"sync:schema": "node scripts/sync-schema.mjs"`.
     Delete `build/scripts/schema-compatibility.ts`.
  4. Add a `yarn check:graphql` step to the `checks` job in `.github/workflows/ci.yml`.
Acceptance criteria (cloud VM):
  - `yarn sync:schema && yarn check:graphql` exits 0 and prints the number of validated documents (76 operations).
  - Changing one field name in a copy of a `.gql` file makes `yarn check:graphql` exit 1 (verify, then revert).
  - Client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: regenerating TypeScript types (P3.19).
Risk / rollback: tooling only.
Size: S
Fixes: BUG-080

### P1.10 — Repair the client Jest harness and re-enable the manifest screen test
Status: done
Repo: client
Depends on: P0.10
Branch: modernise/p1-10-jest-harness
Goal: Screen-level tests render with the app's providers, and `app/__tests__/manifest/ManifestScreen.test.tsx` runs and passes.
Context: Pass 1 found two problems (BUG-081). First, `react-test-renderer` 17.0.1 with React 18.1.0 fails with "Cannot
read properties of undefined (reading 'current')". Second, after aligning the renderer to 18.1.0, the test fails with
"'BottomSheetModalInternalContext' cannot be null!": in `app/__mocks__/render.tsx` (lines 93-99),
`BottomSheetModalProvider` wraps only `children`, but `DropzoneContextProvider` renders bottom-sheet dialogs outside it.
`@gorhom/bottom-sheet` ships a Jest mock at `@gorhom/bottom-sheet/mock`.
Steps:
  1. `yarn add -D react-test-renderer@18.1.0 --ignore-scripts` (must equal the `react` version).
  2. In `app/__mocks__/render.tsx`, move `<BottomSheetModalProvider>` outside `<DropzoneContextProvider>` so it wraps the
     whole provider tree.
  3. In `jest.setup.ts`, add `jest.mock('@gorhom/bottom-sheet', () => require('@gorhom/bottom-sheet/mock'));`.
  4. In `package.json` `jest.testPathIgnorePatterns`, remove `"app/__tests__/manifest/ManifestScreen.test.tsx"`.
  5. Run `npx jest app/__tests__/manifest`. If a test fails because its mocks no longer match the queries
     (`app/__tests__/manifest/__mocks__/*.ts`), update the mocks to the current documents; do not change application code.
Acceptance criteria (cloud VM):
  - `yarn check:testing` passes and reports ≥ 2 test suites, including `ManifestScreen.test.tsx`, with 0 failures.
  - Client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: upgrading Jest or Testing Library (Phase 3).
Risk / rollback: test-only dependency change. Revert the commit.
Size: S
Fixes: BUG-081

### P1.11 — Add client tests for login, logout and dropzone selection
Status: done
Repo: client
Depends on: P1.10
Branch: modernise/p1-11-tests-auth
Goal: The authentication flows are covered by headless tests.
Context: Login form: `app/screens/unauthenticated/login/form/LoginForm.tsx`, `useForm.ts`. Credentials go to Redux
`global.setCredentials` (`app/state/global.ts`). Logout: `app/api/hooks/useLogout.ts` (BUG-063: it aborts a shared
`AbortController` in `app/api/client/links/http.ts`). Dropzone selection: `app/screens/limbo/dropzone_select/DropzoneCard.tsx`.
Use `MockedProvider` with the generated documents from `app/api/reflection.tsx` (e.g. `LoginDocument`).
Steps:
  1. `app/__tests__/auth/LoginScreen.test.tsx`: renders the email/password fields and the "Sign up" link; submitting
     valid credentials dispatches the credentials into the store (assert `store.getState().global.credentials.accessToken`);
     a GraphQL error shows the message.
  2. `app/__tests__/auth/logout.test.ts`: after `useLogout()()` the store's credentials are null and Apollo
     `clearStore` was called. Add `it.skip('BUG-063: requests still work after logout', …)` describing the expected behaviour.
  3. `app/__tests__/limbo/DropzoneSelect.test.tsx`: renders the dropzone list from a mocked `Dropzones` query; pressing a
     card stores the dropzone (`global.currentDropzoneId`).
Acceptance criteria (cloud VM):
  - The three test files pass; `yarn check:testing` passes. Client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing BUG-063 (P4.8).
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.12 — Add client tests for the manifest flows
Status: done
Repo: client
Depends on: P1.10
Branch: modernise/p1-12-tests-manifest
Goal: The manifest board, load screen, manifest-user dialog, create-load dialog and call actions are covered by headless tests that assert the GraphQL variables sent.
Context: `ManifestScreen.tsx`, `dropzone/load/LoadScreen.tsx`, `ActionButton.tsx`, `forms/manifest_user/*`,
`forms/load/*`, `api/crud/useManifest.tsx`, `useLoad.tsx`. Known client bugs to pin as skipped tests: BUG-065
(pull-to-refresh refreshes the wrong query), BUG-066 (group dialog from the board), BUG-067 (load creation requires the
staff member's own prerequisites), BUG-068 (device date).
Steps:
  1. `app/__tests__/manifest/LoadScreen.test.tsx`: renders N slot rows and `maxSlots − N` "Available" rows from a mocked
     `Load` query.
  2. `app/__tests__/manifest/ManifestUserDialog.test.tsx`: filling the form calls `ManifestUser` with
     `{ load, dropzoneUser, ticketType, jumpType, exitWeight }` (use a `MockedProvider` mock whose `variableMatcher` /
     exact variables assert the payload).
  3. `app/__tests__/manifest/LoadDialog.test.tsx`: submitting calls `CreateLoad` with `{ plane, pilot, gca, maxSlots, state: 'open' }`.
  4. `app/__tests__/manifest/ActionButton.test.tsx`: "10 minute call" calls `UpdateLoad` with `state: BOARDING_CALL` and a
     `dispatchAt` 10 minutes ahead (use `jest.useFakeTimers().setSystemTime(...)`).
  5. Add `it.skip('BUG-0xx …')` tests for BUG-065, BUG-066, BUG-067, BUG-068 describing the expected behaviour.
Acceptance criteria (cloud VM):
  - The four files pass; `yarn check:testing` passes; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing the bugs.
Risk / rollback: test-only.
Size: L
Fixes: none

### P1.13 — Add client tests for users, credits and setup forms
Status: done
Repo: client
Depends on: P1.10
Branch: modernise/p1-13-tests-users-setup
Goal: Profile, credits, aircraft, ticket type and create-user forms are covered by headless tests.
Context: `screens/authenticated/user/profile/ProfileScreen.tsx`, `forms/credits/*` (`createOrder` with buyer/seller
wallet ids: deposit → seller = member wallet, buyer = dropzone wallet), `forms/aircraft/*`, `forms/ticket_type/*`,
`forms/create_user/*` (GitHub issue client#126, BUG-086: "Create Ghost doesn't fire submit button").
Steps:
  1. `app/__tests__/users/ProfileScreen.test.tsx`: renders name, credits and the slots/transactions tabs from a mocked
     `DropzoneUserProfile` query.
  2. `app/__tests__/users/CreditsSheet.test.tsx`: a deposit of 50 calls `CreateOrder` with
     `{ amount: 50, seller: <member walletId>, buyer: <dropzone walletId>, dropzone }`.
  3. `app/__tests__/setup/AircraftForm.test.tsx` and `TicketTypeForm.test.tsx`: submitting calls `CreateAircraft` /
     `CreateTicketType` with the entered values.
  4. `app/__tests__/users/CreateGhost.test.tsx`: pressing the sheet's submit button calls `CreateGhost`. If it does not
     (BUG-086), write the test as `it.skip('BUG-086 …')` and update BUG-086 to `confirmed` with the observed reason.
Acceptance criteria (cloud VM):
  - All files pass (skips allowed only for BUG-referenced tests); client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixes.
Risk / rollback: test-only.
Size: M
Fixes: none

### P1.14 — Verify Phase 1
Status: done
Repo: both
Depends on: P1.1, P1.2, P1.3, P1.4, P1.5, P1.6, P1.7, P1.8, P1.9, P1.10, P1.11, P1.12, P1.13
Branch: modernise/p1-14-verify
Goal: The safety net is complete and recorded before any upgrade starts.
Context: Phase gate.
Steps:
  1. Re-sync the client operations (`bin/sync-client-operations ../openmanifest`) and the schema (`yarn sync:schema`).
     Both must produce no diff.
  2. Run the full backend suite, client checks, `yarn check:graphql`, web export and web smoke test.
  3. Write `backend:docs/verification/phase-1.md` (same structure as phase 0) including the counts of examples, pending
     examples (by BUG ID) and client tests.
Acceptance criteria (cloud VM):
  - Everything in step 2 exits 0. CI is green on `staging` in both repos.
Acceptance criteria (owner, real device):
  - Repeat the Phase 0 phone-browser smoke run; results must not differ from Phase 0 (no behaviour changed).
Out of scope: fixing anything.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 2 — Backend upgrade

Goal of the phase: the API runs on Ruby 4.0.7 and Rails 8.1.4 with current gems. It is stepped through each Rails minor
version per the official upgrade guide (<https://guides.rubyonrails.org/upgrading_ruby_on_rails.html>), with every step
green. The GraphQL contract must not change: after every task, `bin/rails graphql:schema:dump` must leave
`schema.graphql` unchanged. If it does change, the client check (`yarn sync:schema && yarn check:graphql` in the client)
must still pass, and the PR must list the diff.

The version ladder is forced by `graphql_devise` (verified on RubyGems 2026-10-08):

| Rails | graphql_devise | graphql (newest allowed) | rspec-rails | Ruby |
|---|---|---|---|---|
| 7.0.10 | 1.2.0 (current) | 2.0.32 | 5.1.2 | 3.1.6 |
| 7.1.6 | 1.5.0 | 2.3.23 | 6.1.5 | 3.1.6 |
| 7.2.4 | 2.0.0 | 2.4.18 | 7.1.1 | 3.1.6 → 3.4.11 (P2.5) |
| 8.0.5.1 | 2.1.0 | 2.5.26 | 8.0.4 | 3.4.11 |
| 8.1.4 | 2.4.0 | 2.6.11 | 8.0.4 | 3.4.11 → 4.0.7 (P2.9) |

Standard procedure for a Rails step (referred to as **"Rails step procedure"** below):

1. Set the versions in `Gemfile` as the task says, then run `bundle update <the gems the task lists>`. If Bundler
   reports a conflict naming another gem that constrains Rails or graphql, add that gem to the command, updating it to
   the newest version whose requirements allow the target. Check requirements with
   `curl -s https://rubygems.org/api/v2/rubygems/<gem>/versions/<version>.json`. Record every extra gem in the PR.
2. Run `yes n | bin/rails app:update`. This creates the `config/initializers/new_framework_defaults_X_Y.rb` file
   (and new files such as `bin/` scripts) without overwriting existing files. Review the new files and keep them.
3. Keep `config.load_defaults` at the previous version. In `new_framework_defaults_X_Y.rb`, uncomment the settings one at
   a time, running `bundle exec rspec` after each. If a setting breaks specs and the fix is not a one-line code change,
   leave it commented and list it in the PR. When all are uncommented, delete the file and set
   `config.load_defaults X.Y` in `config/application.rb`.
4. Run the suite and fix every `DEPRECATION WARNING` printed by `bundle exec rspec 2>&1 | grep -i deprecat | sort -u`.
5. Run `bin/rails graphql:schema:dump` and check `schema.graphql` as described above. Boot the dev server with the
   dev_baseline seed and run the client web smoke test (P0.8) against it.

### P2.1 — Remove dead code and unused gems from the backend
Status: done
Repo: backend
Depends on: P1.14
Branch: modernise/p2-1-backend-cleanup
Goal: The backend contains only what the API needs, which shrinks the upgrade surface.
Context: These are leftovers. Webpacker/JS: `package.json`, `yarn.lock`, `babel.config.js`, `postcss.config.js`,
`.browserslistrc`, `config/webpack/`, `config/webpacker.yml`, `app/javascript/`. A stale 2021 web build of the client:
`public/static/`, `app/views/web-build/`, plus the routes `/`, `/index.html`, `/confirm` → `application#index` (BUG-059).
Committed temporary uploads: `public/uploads/tmp/`. Unused development/test gems: `railroady`, `rails-erd` (and
`lib/tasks/auto_generate_diagram.rake`), `solargraph`, `yard` (pinned 0.9.24, with advisories), `fasterer`, `guard`,
`guard-rspec` (and `Guardfile`), `capybara`, `selenium-webdriver`, `webdrivers` (no system specs exist), `reek` (and
`.reek.yml`). The `/.well-known/apple-app-site-association` route and `public/apple-app-site-association.json` stay;
universal links use them.
Steps:
  1. Delete the files and directories listed above, except `public/apple-app-site-association.json`, `public/robots.txt`
     and `public/*.html` error pages.
  2. In `config/routes.rb`, delete the three `application#index` routes and the commented-out catch-all. Delete
     `ApplicationController#index`.
  3. In `Gemfile`, remove the gems listed above, then run `bundle install` (not `update`).
  4. Run `grep -rn "Webpacker\|javascript_pack_tag\|webpacker" app config` and remove any remaining references.
Acceptance criteria (cloud VM):
  - `bundle exec rspec` and `bundle exec rubocop` exit 0.
  - `git diff origin/staging -- Gemfile.lock | grep '^-    [a-z]' | wc -l` > 0 and `grep -c "^    rails (" Gemfile.lock` is unchanged (Rails not updated).
  - Dev server: `/graphql` returns 200, `/.well-known/apple-app-site-association` returns 200, and `/` returns 404.
  - `bin/rails graphql:schema:dump && git diff --exit-code schema.graphql`.
Acceptance criteria (owner, real device):
  - none
Out of scope: removing runtime gems; the `Admin` model.
Risk / rollback: anything that relied on the API serving the web app at `/` stops working. The web app is hosted
separately (GitHub Pages). Revert the commit.
Size: M
Fixes: BUG-059

### P2.2 — Update to Rails 7.0.10 and patch-level security releases
Status: done
Repo: backend
Depends on: P2.1
Branch: modernise/p2-2-rails-7-0-10
Goal: The app runs on the final Rails 7.0 release, with security patches that need no major upgrade.
Context: bundle-audit lists advisories for Rails 7.0.4 components, rack 2.2.5, nokogiri, puma 6.0, geokit-rails 2.3.2,
httparty 0.21, jwt 2.6, globalid, loofah and others (BUG-015). This task stays within current major versions.
Steps:
  1. `Gemfile`: `gem "rails", "~> 7.0.10"`.
  2. `bundle update --conservative rails rack nokogiri puma loofah rails-html-sanitizer globalid net-imap mail rexml
     websocket-driver concurrent-ruby crass addressable faraday msgpack bcrypt httparty geokit-rails jwt devise`
     (`--conservative` keeps the other gems put). If `jwt` 2.x → newest 2.x breaks Apple login specs, keep the newest 2.x that passes.
  3. Run `bundle-audit check --update` and record the remaining advisories in the PR.
Acceptance criteria (cloud VM):
  - `grep "^    rails (" Gemfile.lock` shows `rails (7.0.10)`.
  - `bundle exec rspec`, `bundle exec rubocop` exit 0; schema unchanged; web smoke test passes against the dev server.
  - The `bundle-audit` advisory count is lower than 133.
Acceptance criteria (owner, real device):
  - none
Out of scope: Rails 7.1; major versions of any gem.
Risk / rollback: low (patch releases). Revert `Gemfile`/`Gemfile.lock`.
Size: S
Fixes: none

### P2.3 — Upgrade Rails 7.0 → 7.1
Status: done
Repo: backend
Depends on: P2.2
Branch: modernise/p2-3-rails-7-1
Goal: The app runs on Rails 7.1.6 with `config.load_defaults 7.1`.
Context: Follow the Rails step procedure. Target versions (table above): rails 7.1.6, graphql_devise 1.5.0 (needs
rails < 7.2, graphql < 2.4), graphql 2.3.23, devise_token_auth 1.2.6, rspec-rails 6.1.5.
Known 7.1 changes that touch this app:
- `serialize` without a coder raises under 7.1 defaults. `users.tokens`/`admins.tokens` are serialised by devise_token_auth.
  If you see "Missing coder", set `config.active_record.default_column_serializer = YAML` in `config/application.rb`
  and note it in the PR.
- graphql ≥ 2.1 deprecates `use(GraphQL::Tracing::AppsignalTracing)`; replace it in `app/graphql/dz_schema.rb:18` with
  `trace_with(GraphQL::Tracing::AppsignalTrace)`.
- `state_machines-activerecord` 0.8.0 may not support Rails 7.1. If specs fail inside `state_machines`, update it to the
  newest version whose `activerecord` requirement allows 7.1.
Steps:
  1. `Gemfile`: `gem "rails", "~> 7.1.6"`, `gem "graphql", "~> 2.3.23"`, `gem "graphql_devise", "~> 1.5.0"`,
     `gem "rspec-rails", "~> 6.1.5"`. Then run `bundle update rails graphql graphql_devise devise_token_auth rspec-rails`.
  2. Apply the Rails step procedure (steps 2–5).
  3. Read the graphql-ruby changelog sections for 2.1–2.3
     (`https://raw.githubusercontent.com/rmosolgo/graphql-ruby/master/CHANGELOG.md`) and the graphql_devise changelog
     (`https://raw.githubusercontent.com/graphql-devise/graphql_devise/master/CHANGELOG.md`). Apply every item marked
     breaking that affects files in `app/graphql`.
Acceptance criteria (cloud VM):
  - `grep "^    rails (" Gemfile.lock` → `rails (7.1.6)`; `grep load_defaults config/application.rb` → `7.1`; no
    `new_framework_defaults_7_1.rb` remains (or the PR lists each setting left commented and why).
  - `bundle exec rspec` and `bundle exec rubocop` exit 0; `bundle exec rspec 2>&1 | grep -ci "deprecation"` prints 0.
  - Schema check per the phase intro; web smoke test passes against the dev server.
Acceptance criteria (owner, real device):
  - none
Out of scope: Rails 7.2; Ruby version.
Risk / rollback: auth tokens (devise_token_auth) and GraphQL behaviour. The request specs from Phase 1 cover login and
every client operation. Revert the merge commit.
Size: L
Fixes: none

### P2.4 — Upgrade Rails 7.1 → 7.2
Status: done
Repo: backend
Depends on: P2.3
Branch: modernise/p2-4-rails-7-2
Goal: The app runs on Rails 7.2.4 with `config.load_defaults 7.2` and no Rails 8 removals pending.
Context: Target versions: rails 7.2.4, graphql_devise 2.0.0, graphql 2.4.18, rspec-rails 7.1.1. Rails 7.2 deprecates
defining enums with keyword arguments; Rails 8 removes it. The app uses the old form in `app/models/activity/event.rb:10,12,14`,
`rig.rb:37`, `notification.rb:23`, `load.rb:55`, `user.rb:56`, `order.rb:30`, `transaction.rb:32,34`.
Steps:
  1. `Gemfile`: `gem "rails", "~> 7.2.4"`, `gem "graphql", "~> 2.4.18"`, `gem "graphql_devise", "~> 2.0.0"`,
     `gem "rspec-rails", "~> 7.1.1"`. Then run `bundle update rails graphql graphql_devise rspec-rails`.
  2. Convert every enum to the positional form, e.g. `enum :state, { open: 0, boarding_call: 1, in_flight: 2, landed: 3, cancelled: 4 }`.
     Keep the values identical.
  3. Apply the Rails step procedure (steps 2–5). Rails 7.2 sets `config.active_job.enqueue_after_transaction_commit`. Keep it at the
     7.2 default unless specs that assert notification jobs fail; then set it to `:never` and note it.
  4. Apply breaking items from the graphql 2.4 and graphql_devise 2.0 changelog entries.
Acceptance criteria (cloud VM):
  - `rails (7.2.4)` in `Gemfile.lock`; `load_defaults 7.2`; `grep -rn "enum [a-z_]*:" app/models` prints nothing.
  - `bundle exec rspec`, `bundle exec rubocop` exit 0; deprecation count 0; schema check; web smoke test passes.
Acceptance criteria (owner, real device):
  - none
Out of scope: Ruby upgrade (P2.5).
Risk / rollback: enum conversion. Specs cover every enum through the request specs. Revert the merge.
Size: L
Fixes: none

### P2.5 — Upgrade Ruby 3.1.6 → 3.4.11
Status: done
Repo: backend
Depends on: P2.4
Branch: modernise/p2-5-ruby-3-4
Goal: The app runs on Ruby 3.4.11 (Ruby 3.1 is EOL; Rails 8 needs Ruby ≥ 3.2).
Context: Requires setup script version B (CLOUD_ENV.md §1). If `rbenv versions` does not list 3.4.11, set this task to
`owner-check (install setup script version B and allowlist cache.ruby-lang.org)` and stop, or use the Docker fallback
in CLOUD_ENV.md §4 for every Ruby command. Ruby 3.4 warns about mutating string literals; files already have
`# frozen_string_literal: true` in most places.
Steps:
  1. `.ruby-version` → `3.4.11`; `Gemfile` `ruby "3.4.11"`; `bundle update --ruby`; `gem install bundler` (the Bundler
     shipped with or newest for Ruby 3.4), then `bundle update --bundler`.
  2. `bundle install`. For each native gem that fails to compile, update it to its newest version (record in the PR).
  3. Run the suite with `RUBYOPT="-W:deprecated"` and fix warnings in `app/`, `lib/`, `config/`, `spec/`.
  4. Update `.github/workflows/ci.yml` only if needed (it reads `.ruby-version`).
Acceptance criteria (cloud VM):
  - `ruby -v` → 3.4.11 inside the repo. `bundle exec rspec` and `bundle exec rubocop` exit 0. CI green on the PR.
  - Schema unchanged; web smoke test passes.
Acceptance criteria (owner, real device):
  - none
Out of scope: Rails 8.
Risk / rollback: native extensions. Revert `.ruby-version`, `Gemfile` and `Gemfile.lock`.
Size: M
Fixes: none

### P2.6 — Upgrade Rails 7.2 → 8.0
Status: done
Repo: backend
Depends on: P2.5
Branch: modernise/p2-6-rails-8-0
Goal: The app runs on Rails 8.0.5.1 with `config.load_defaults 8.0`.
Context: Target versions: rails 8.0.5.1, graphql_devise 2.1.0 (rails < 8.1, graphql < 2.6), graphql 2.5.26, rspec-rails 8.0.4.
Rails 8 no longer depends on `sprockets-rails`; `graphiql-rails` needs an asset pipeline in development.
Steps:
  1. `Gemfile`: `gem "rails", "~> 8.0.5"`, `gem "graphql", "~> 2.5.26"`, `gem "graphql_devise", "~> 2.1.0"`,
     `gem "rspec-rails", "~> 8.0.4"`, and add `gem "sprockets-rails"`. Then run
     `bundle update rails graphql graphql_devise rspec-rails sprockets-rails`.
  2. Apply the Rails step procedure. `app:update` in 8.0 proposes Solid Cache/Queue/Cable and Kamal files; answer `n`
     (adopting Solid Queue is P6.17).
  3. Verify graphiql: in development, `GET /graphiql` returns 200.
Acceptance criteria (cloud VM):
  - `rails (8.0.5.1)`; `load_defaults 8.0`; specs, rubocop, deprecation count 0, schema check, web smoke test all pass.
  - `curl -s -o /dev/null -w "%{http_code}" http://local.openmanifest.org:5000/graphiql` → 200.
Acceptance criteria (owner, real device):
  - none
Out of scope: Solid Queue/Cache/Cable, Kamal, Dockerfile.
Risk / rollback: as previous steps. Revert the merge.
Size: L
Fixes: none

### P2.7 — Upgrade Rails 8.0 → 8.1
Status: done
Repo: backend
Depends on: P2.6
Branch: modernise/p2-7-rails-8-1
Goal: The app runs on Rails 8.1.4 (security support until 2027-10-10) with `config.load_defaults 8.1`.
Context: Target versions: rails 8.1.4, graphql_devise 2.4.0, graphql 2.6.11, devise_token_auth 1.3.0 (rails < 8.3, devise < 6).
Steps:
  1. `Gemfile`: `gem "rails", "~> 8.1.4"`, `gem "graphql", "~> 2.6.11"`, `gem "graphql_devise", "~> 2.4.0"`. Then run
     `bundle update rails graphql graphql_devise devise_token_auth devise`.
  2. Apply the Rails step procedure.
Acceptance criteria (cloud VM):
  - `rails (8.1.4)`, `graphql (2.6.11)`, `graphql_devise (2.4.0)` in `Gemfile.lock`; `load_defaults 8.1`; specs,
    rubocop, deprecation count 0, schema check, web smoke test all pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: other gem majors (P2.8).
Risk / rollback: revert the merge.
Size: M
Fixes: none

### P2.8 — Upgrade the remaining runtime gems to current majors
Status: done
Repo: backend
Depends on: P2.7
Branch: modernise/p2-8-runtime-gems
Goal: Every runtime gem is on its current major version.
Context: Targets (RubyGems 2026-10-08): puma 8.0.2, pg 1.7.0, redis 6.0.0 (ActionCable's adapter allows `< 7`),
devise 5.0.4, appsignal 5.0.2, jwt 3.3.0 (used in `app/interactions/login/apple.rb`: `JWT::JWK.import`, `JWT.decode`),
discard 2.0.0, state_machines-activerecord 0.200.0 (requires activerecord ≥ 7.2), active_interaction 5.5.0, active_interaction-extras 1.1.0, active_storage_base64 3.0.1, image_processing 2.2.0,
rack-cors 3.0.0, dotenv-rails 3.2.0, activerecord-import 2.3.0, geokit-rails 2.5.0, httparty 0.24.3, search_cop 1.6.0,
google-cloud-storage 1.62.1, bootsnap 1.26.0, graphiql-rails 1.10.5, faker 3.8.0. `counter_culture` is deliberately
left at 3.3.0 (pinned in P2.2): 3.14.0 makes the double counting of BUG-019 fail three-tandem group manifests, so P6.10
fixes the counters and then moves the gem to 3.14.0.
Steps:
  1. Remove version constraints for these gems in `Gemfile` where a constraint blocks the target (e.g. `puma "~> 6.0"`,
     `redis "~> 4.0"`, `discard "~> 1.2"`). Upgrade in this order, running `bundle exec rspec` after each:
     (a) `bundle update puma pg redis bootsnap`; (b) `bundle update devise devise_token_auth`; (c) `bundle update jwt`
     (adapt `Login::Apple` to jwt 3: `JWT::JWK.import(key).verify_key` / `JWT.decode(token, nil, true, algorithms: [alg], jwks: …)`
     as the jwt 3 upgrade guide in the gem's `UPGRADING.md` describes); (d) `bundle update state_machines state_machines-activerecord discard`;
     (e) `bundle update active_interaction active_interaction-extras active_storage_base64 image_processing activerecord-import`;
     (f) `bundle update rack-cors dotenv-rails geokit-rails httparty search_cop google-cloud-storage graphiql-rails faker appsignal`.
  2. Update `config/puma.rb` for Puma 8 if it warns about removed options.
Acceptance criteria (cloud VM):
  - `bundle outdated --only-explicit --strict` lists only gems handled in P2.10 (development/test group) and `counter_culture` (P6.10).
  - Specs, rubocop, schema check and web smoke test pass. `bundle-audit check --update` lists no advisories, or the PR
    lists each remaining one with the reason.
Acceptance criteria (owner, real device):
  - none
Out of scope: dev/test gems; Ruby 4.
Risk / rollback: Apple login (jwt 3) is covered only by stubbed specs. The owner re-tests Apple login on a device in
Phase 3 verification. Revert per gem group.
Size: L
Fixes: BUG-097

### P2.9 — Upgrade Ruby 3.4.11 → 4.0.7
Status: done
Repo: backend
Depends on: P2.8
Branch: modernise/p2-9-ruby-4
Goal: The app runs on Ruby 4.0.7, the current stable Ruby.
Context: Requires setup script version C (or the Docker image `ruby:4.0.7-bookworm`, which exists). Some older gems
(`geokit-rails` last released 2023-01, `search_cop`, `active_interaction-extras`) have not declared Ruby 4 support.
Steps:
  1. `.ruby-version` → `4.0.7`; `Gemfile` `ruby "4.0.7"`; `bundle update --ruby`; update Bundler as in P2.5.
  2. `bundle install`; run the suite with `RUBYOPT="-W:deprecated"`; fix warnings in app code.
  3. If a gem fails on Ruby 4 and no fixed release exists: stop and set `blocked (gem <name> incompatible with Ruby 4.0.7; stay on 3.4.11)`.
     Do not vendor or patch gems.
Acceptance criteria (cloud VM):
  - `ruby -v` → 4.0.7; specs, rubocop, schema check, web smoke test pass; CI green.
Acceptance criteria (owner, real device):
  - none
Out of scope: replacing gems with alternatives (that would need an owner-approved task).
Risk / rollback: revert `.ruby-version`, `Gemfile` and `Gemfile.lock` (back to 3.4.11, which has security support).
Size: M
Fixes: none

### P2.10 — Upgrade development and test tooling
Status: done
Repo: backend
Depends on: P2.9
Branch: modernise/p2-10-dev-gems
Goal: Test and lint tooling is current and Rubocop's config matches it.
Context: Targets: rubocop 1.91.0 with plugins `rubocop-rails`, `rubocop-performance`, `rubocop-rspec`, `rubocop-graphql`
(newest), factory_bot_rails 6.5.1, webmock, database_cleaner, parallel_tests, rspec_junit_formatter, byebug → replace
with the `debug` gem (default since Rails 7), `web-console`, `listen`, `rack-mini-profiler`, `spring` (remove; Rails 8
does not use it), `annotate` (unmaintained → `annotaterb`), `brakeman` (newest). Rubocop config: `.rubocop.yml`,
`.rubocop_todo.yml`, `config/rubocop/`.
Steps:
  1. Update the `development`/`test` groups: replace `byebug` with `debug`, `annotate` with `annotaterb`; remove `spring`
     (and `config/spring.rb`, `bin/spring` if present); then `bundle update --group development test`.
  2. Use `plugins:` instead of `require:` in `.rubocop.yml` for the rubocop extensions. Run `bundle exec rubocop -A` only
     for cops added since 1.50 (`--only` with the list from `bundle exec rubocop --show-cops` that are `Enabled: pending`).
     Regenerate `.rubocop_todo.yml` with `bundle exec rubocop --auto-gen-config` if the auto-correct produced more than
     200 changed lines; otherwise commit the corrections.
Acceptance criteria (cloud VM):
  - `bundle outdated --only-explicit` lists nothing, or only gems with a reason in the PR.
  - `bundle exec rubocop` and `bundle exec rspec` exit 0; `bundle exec brakeman -q --no-pager` runs (the findings are
    recorded in the PR; fixing them is P6.24).
Acceptance criteria (owner, real device):
  - none
Out of scope: application code changes beyond auto-correctable style.
Risk / rollback: style-only. Revert.
Size: M
Fixes: none

### P2.11 — Verify Phase 2
Status: owner-check (merge the Phase 0, 1 and 2 stacks in order and confirm CI on staging in both repos; phone-browser smoke run as in docs/verification/phase-2.md)
Repo: both
Depends on: P2.1, P2.2, P2.3, P2.4, P2.5, P2.6, P2.7, P2.8, P2.9, P2.10
Branch: modernise/p2-11-verify
Goal: The upgraded backend is proven against the unchanged client, and dependency audits are now blocking in CI.
Context: Phase gate. BUG-015 (backend advisories) should be resolved by the upgrades.
Steps:
  1. backend: in `.github/workflows/ci.yml`, remove `continue-on-error: true` from the `audit` job.
  2. Run the full backend suite, `bundle-audit check --update`, the schema check, client checks, `yarn check:graphql`,
     web export and web smoke test.
  3. Write `backend:docs/verification/phase-2.md` with versions (`ruby -v`, `bin/rails -v`, key gems), results and audit output.
  4. Update the dependency inventory table in `backend:docs/reference/README.md` §10 with the new current versions.
Acceptance criteria (cloud VM):
  - All commands exit 0; `bundle-audit` reports "No vulnerabilities found"; CI green on `staging` in both repos.
Acceptance criteria (owner, real device):
  - Phone-browser smoke run (SMOKE_TEST.md sections Login and Manifest) against a locally running stack shows no
    regression versus `docs/verification/phase-1.md`.
Out of scope: fixing app bugs.
Risk / rollback: none.
Size: S
Fixes: BUG-015

---

## Phase 3 — Client upgrade

Goal of the phase: the client runs on Expo SDK 57 (React Native 0.86.3, React 19.2.3), stepped one SDK at a time as Expo
recommends ("upgrade SDK versions incrementally, one at a time": Expo upgrade walkthrough
<https://docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough/>). Abandoned libraries are replaced, web moves from
webpack to Metro, the New Architecture is enabled before SDK 55 drops the legacy one, and builds use EAS with config in
`app.config.ts`. VM verification uses type-check, lint, tests, `yarn check:graphql`, web export, the web smoke test and
`npx expo-doctor`. Device verification is collected in P3.22.

Versions Expo pins per SDK (from each `expo@<version>` tarball's `bundledNativeModules.json`, verified 2026-10-08):

| SDK (expo) | react-native | react | reanimated | gesture-handler | screens | safe-area-context | jest-expo |
|---|---|---|---|---|---|---|---|
| 47 (47.0.13, current) | 0.70.5 (repo has 0.70.8) | 18.1.0 | ~2.12.0 | ~2.8.0 | ~3.18.0 | 4.4.1 | ^47 |
| 48 (48.0.21) | 0.71.14 | 18.2.0 | ~2.14.4 | ~2.9.0 | ~3.20.0 | 4.5.0 | ^48 |
| 49 (49.0.23) | 0.72.10 | 18.2.0 | ~3.3.0 | ~2.12.0 | ~3.22.0 | 4.6.3 | ~49.0.0 |
| 50 (50.0.21) | 0.73.6 | 18.2.0 | ~3.6.2 | ~2.14.0 | ~3.29.0 | 4.8.2 | ~50.0.4 |
| 51 (51.0.39) | 0.74.5 | 18.2.0 | ~3.10.1 | ~2.16.1 | 3.31.1 | 4.10.5 | ~51.0.4 |
| 52 (52.0.49) | 0.76.9 | 18.3.1 | ~3.16.1 | ~2.20.2 | ~4.4.0 | 4.12.0 | ~52.0.6 |
| 53 (53.0.27) | 0.79.6 | 19.0.0 | ~3.17.4 | ~2.24.0 | ~4.11.1 | 5.4.0 | ~53.0.14 |
| 54 (54.0.37) | 0.81.5 | 19.1.0 | ~4.1.1 (+ react-native-worklets 0.5.1) | ~2.28.0 | ~4.16.0 | ~5.6.0 | ~54.0.18 |
| 55 (55.0.31) | 0.83.10 | 19.2.0 | 4.2.1 | ~2.30.0 | ~4.23.0 | ~5.6.2 | ~55.0.22 |
| 56 (56.0.23) | 0.85.3 | 19.2.3 | 4.3.1 | ~2.31.1 | ~4.26.0 | ~5.7.0 | ~56.0.5 |
| 57 (57.0.27, `latest`) | 0.86.3 | 19.2.3 | 4.5.1 (+ worklets 0.10.1) | ~2.32.0 | ~4.26.0 | ~5.7.0 | ~57.0.5 |

Facts from Expo's changelogs and blog (summarised via web search in pass 1; re-read the official page for each step):
SDK 50 deprecates webpack for web in favour of Metro. The New Architecture is the default from SDK 53. SDK 54 / RN 0.81
is the last release supporting the legacy architecture, and SDK 55 removes it (`newArchEnabled` is removed from app
config). SDK 56 requires iOS ≥ 16.4, makes `expo/fetch` the global fetch, and stops pulling `@expo/vector-icons` in
transitively. SDK 57 moves to RN 0.86 with no breaking changes intended; use `expo@57.0.17` or later (Hermes memory fix).

**SDK step procedure** (referred to by each SDK task):

1. Read `https://expo.dev/changelog/sdk-<N>` (use the WebFetch tool if available; the shell may not reach expo.dev). Apply
   every breaking change that touches this app; the task lists the ones known to matter.
2. `npx expo install expo@~<N>.0.0`, then `npx expo install --fix`. If `api.expo.dev` is blocked, prefix both with
   `EXPO_OFFLINE=1`. If `--fix` cannot resolve offline, align versions by hand: run
   `node -e "const b=require('expo/bundledNativeModules.json'),p=require('./package.json');for(const d of ['dependencies','devDependencies'])for(const [k,v] of Object.entries(p[d]||{}))if(b[k]&&b[k]!==v)console.log(k,v,'->',b[k])"`
   and `yarn add <pkg>@<version>` for each line.
3. Set `react-test-renderer` (dev) to exactly the new `react` version, `jest-expo` to the SDK's version, and
   `@types/react` to the matching major.
4. Remove `resolutions` entries in `package.json` that pin packages to older SDK versions (`react-native-reanimated`,
   `expo-linear-gradient`, `@babel/runtime`, `@jest/create-cache-key-function`) when they conflict.
5. Fix type errors (`yarn check:types`), lint, tests and the web export. Run `npx expo-doctor` (with `EXPO_OFFLINE=1` if
   needed). Every remaining doctor warning must be listed in the PR with the task that will fix it.
6. Update the version table in `client:docs/reference/README.md` §10.

### P3.1 — Remove unused client dependencies
Status: done
Repo: client
Depends on: P2.11
Branch: modernise/p3-1-remove-unused-deps
Goal: `package.json` lists only packages the app imports or needs as peers, which cuts the upgrade surface.
Context: Pass 1 found these packages are never imported from `app/`, `index.js` or `app.config.ts`:
`@fseehawer/react-circular-slider`, `@gorhom/animated-tabbar`, `@react-navigation/material-bottom-tabs`,
`@react-navigation/material-top-tabs`, `react-native-tab-view`, `@vitu.soares/react-native-skeleton-content`, `cosmiconfig`,
`expo-document-picker`, `graphql-ruby-client`, `react-native-dotenv`, `react-native-get-random-values`, `react-native-localize`,
`react-native-mmkv-storage`, `react-native-numeric-input`. In devDependencies: `enzyme`, `redux-mock-store`, `json`,
`@types/react-test-renderer` (re-added later if needed). Peers that look unused but must stay: `react-native-pager-view`
(peer of `react-native-paper-tabs`), `@emotion/react` and `@emotion/styled` (peers of `@mui/material`), `styled-components`
(peer of `react-native-animated-nav-tab-bar`, removed in P3.4).
Steps:
  1. Before removing each package, confirm with `grep -rn "<pkg>" app index.js app.config.ts babel.config.js metro.config.js jest.setup.ts package.json`
     that only `package.json` mentions it. Then run `yarn remove <pkg…>`.
  2. Run the client checks and the web export. If removing a package breaks something, re-add it at the same version
     and note it in the PR.
Acceptance criteria (cloud VM):
  - Client checks, `yarn check:graphql`, web export and the web smoke test (against the dev server) pass.
  - `node -e "const p=require('./package.json');console.log(Object.keys(p.dependencies).length)"` is at least 14 lower than before.
Acceptance criteria (owner, real device):
  - none
Out of scope: upgrading anything.
Risk / rollback: a hidden runtime import could break a native build. Native builds are verified in P3.22. Revert.
Size: S
Fixes: none

### P3.2 — Remove sentry-expo
Status: done
Repo: client
Depends on: P3.1
Branch: modernise/p3-2-remove-sentry
Goal: The unused Sentry SDK and its blocked binary download are gone. Error reporting stays with AppSignal.
Context: `sentry-expo` (~6.0.0) is in `package.json` but not imported anywhere (pass-1 grep). Its postinstall downloads a
binary from `downloads.sentry-cdn.com` (blocked). `.github/workflows/publish.yml` passes `SENTRY_DSN`/`SENTRY_API_KEY`.
AppSignal (`app/components/app_signal/*`) remains the error reporter.
Steps:
  1. `yarn remove sentry-expo`.
  2. Remove `SENTRY_DSN` and `SENTRY_API_KEY` from `.github/workflows/publish.yml`.
  3. Remove the "Sentry" mention in `app/components/app_signal/AppSignalLink.tsx:119` (comment only).
Acceptance criteria (cloud VM):
  - `yarn install --frozen-lockfile` succeeds **without** `SENTRYCLI_SKIP_DOWNLOAD`. Client checks and web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: AppSignal changes.
Risk / rollback: none (unused). Revert.
Size: S
Fixes: none

### P3.3 — Remove or replace Facebook login
Status: done
Repo: both
Depends on: P3.2
Branch: modernise/p3-3-facebook-login
Goal: No code depends on `expo-facebook`, and Facebook login either no longer exists (D4 option a) or works through `expo-auth-session` (option b).
Context: `expo-facebook` 12.2.0 is not part of Expo SDK 47 and cannot be built with current SDKs (BUG-084). Files:
client `app/screens/unauthenticated/login/form/FacebookButton.tsx`, `FacebookButton.web.tsx` (uses `react-facebook-login`),
`LoginForm.tsx:64`, `useForm.ts` (`loginWithFacebook`), `app.json` keys `facebookAppId`, `facebookDisplayName`,
`facebookAutoInitEnabled`, `facebookScheme`, `ios.infoPlist.fbAppId/fbAppName/fbAppUrl/facebookScheme`, `app.config.ts`
`plugins: ["expo-facebook", …]`, `extra.facebookAppId/facebookClientToken`, `app/api/mutations/LoginWithFacebook.gql`.
Backend: `app/graphql/mutations/users/login/facebook.rb`, `app/interactions/login/facebook.rb`, the `login_with_facebook`
field in `app/graphql/types/mutation_type.rb:15`.
Steps:
  Option a (recommended):
  1. client: delete both `FacebookButton` files and their use in `LoginForm.tsx`; remove `loginWithFacebook` from
     `login/form/useForm.ts`; delete `app/api/mutations/LoginWithFacebook.gql` and regenerate types (`yarn ts:graphql`
     after `yarn sync:schema`); remove the Facebook keys from `app.json` and `app.config.ts`; then
     `yarn remove expo-facebook react-facebook-login @types/react-facebook-login @types/facebook-js-sdk`.
  2. backend: mark the `loginWithFacebook` field with `deprecation_reason: "Facebook login removed (D4)"` (do not delete
     yet; older app builds may call it). Delete it in P8.7.
  3. Re-sync client operations in the backend (`bin/sync-client-operations`) and update the coverage spec's expected
     count (75).
  Option b: replace steps 1–2 with an `expo-auth-session` Facebook provider flow calling the existing
`loginWithFacebook(token:)` mutation. Owner supplies the Facebook app id/client token.
Acceptance criteria (cloud VM):
  - `grep -rn "expo-facebook\|react-facebook-login" client:package.json client:app client:app.config.ts client:app.json`
    prints nothing (option a). Client checks, `yarn check:graphql`, backend specs, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - Option b only: Facebook login works on iOS and Android dev builds.
Out of scope: Apple login.
Risk / rollback: users who signed up with Facebook can no longer log in with Facebook. They must use "Forgot your
password?" with the same email (option a). Revert both PRs.
Size: M
Fixes: BUG-084

### P3.4 — Replace libraries built on the Reanimated 1 API
Status: done
Repo: client
Depends on: P3.2
Branch: modernise/p3-4-replace-reanimated1-libs
Goal: No dependency relies on Reanimated 1 APIs, which Reanimated 3 (SDK 49) removes.
Context: `react-native-skeleton-content` 1.0.28 bundles its own `react-native-reanimated` 2.1.0 and uses v1
`interpolate`. It is used by `app/components/Skeleton.tsx`, `Skeleton.web.tsx` and their many callers.
`react-native-animated-nav-tab-bar` 3.1.8 (peer: React Navigation 5, styled-components 4) produces the web-export warning
"'default'.'interpolate' is not exported from 'react-native-reanimated'". It powers the bottom tab bar
(`app/screens/authenticated/TabBar.tsx`, `TabBar.web.tsx`, options in `screens/authenticated/routes.tsx:225-238`).
Steps:
  1. Rewrite `app/components/Skeleton.tsx` and `Skeleton.web.tsx` without the library. Keep the same props
     (`isLoading`, `layout` array of `{ key, width, height, borderRadius, marginX… }`, `children`), render grey `View`
     blocks with an opacity pulse using React Native `Animated.loop`, and render `children` when not loading.
  2. Replace both `TabBar.tsx` files with `export default createBottomTabNavigator<AuthenticatedRoutes>();` from
     `@react-navigation/bottom-tabs` (already a dependency). Remove the `appearance` and `tabBarOptions` props in
     `screens/authenticated/routes.tsx`; express the active colours with `screenOptions` (`tabBarActiveTintColor`,
     `tabBarActiveBackgroundColor` = `palette.primary.main` with white tint).
  3. `yarn remove react-native-skeleton-content react-native-animated-nav-tab-bar styled-components`.
  4. Add a render test `app/__tests__/components/Skeleton.test.tsx` (loading shows N blocks, loaded shows children).
Acceptance criteria (cloud VM):
  - Client checks pass; web smoke test passes and the screenshots show the tab bar. (The `interpolate' is not exported`
    line in the web export log does not come from these libraries: it comes from `@react-navigation/drawer`'s legacy
    overlay and goes away in P3.9, whose criteria now include it.)
Acceptance criteria (owner, real device):
  - none (checked in P3.22)
Out of scope: visual redesign.
Risk / rollback: tab bar looks different (standard bottom tabs). Revert.
Size: M
Fixes: none

### P3.5 — Upgrade to Expo SDK 48
Status: done
Repo: client
Depends on: P3.4
Branch: modernise/p3-5-expo-48
Goal: The client runs on Expo SDK 48 (RN 0.71.14, React 18.2.0).
Context: Apply the SDK step procedure with N = 48. App-specific items: `Constants.manifest` is deprecated in favour of
`Constants.expoConfig`. `app/constants/expo.ts` reads `Constants.manifest?.extra || Constants.manifest2?…`; change it to
`Constants.expoConfig?.extra`. `@types/react-native` is no longer needed from RN 0.71 (types ship with react-native).
Steps:
  1. SDK step procedure (N = 48), with `react-test-renderer@18.2.0`.
  2. Update `app/constants/expo.ts` as above.
  3. `yarn remove @types/react-native`; fix type errors.
Acceptance criteria (cloud VM):
  - `node -p "require('expo/package.json').version"` starts with `48.`; `react-native` 0.71.x installed.
  - Client checks, `yarn check:graphql`, web export (`expo export:web`) and web smoke test pass; `npx expo-doctor` (offline if needed) output in the PR.
Acceptance criteria (owner, real device):
  - none (checked in P3.22)
Out of scope: other library majors.
Risk / rollback: revert `package.json`/`yarn.lock`.
Size: M
Fixes: none

### P3.6 — Upgrade to Expo SDK 49
Status: done
Repo: client
Depends on: P3.5
Branch: modernise/p3-6-expo-49
Goal: The client runs on Expo SDK 49 (RN 0.72.10, Reanimated 3.3).
Context: SDK step procedure with N = 49. Reanimated 3 removes the v1 API (prepared in P3.4). `@gorhom/bottom-sheet` 4.4.5
supports Reanimated ≥ 2.2; upgrade it to the newest 4.x. `react-native-reanimated-carousel` 3.1.5 works with Reanimated 3;
upgrade to the newest 3.x.
Steps:
  1. SDK step procedure (N = 49).
  2. `yarn add @gorhom/bottom-sheet@^4 react-native-reanimated-carousel@^3` (newest 4.x / 3.x).
  3. Keep `react-native-reanimated/plugin` as the last Babel plugin in `babel.config.js`.
Acceptance criteria (cloud VM):
  - expo 49.x installed; client checks, `check:graphql`, web export and web smoke test pass; expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: expo-router (not adopted).
Risk / rollback: revert.
Size: M
Fixes: none

### P3.7 — Upgrade to Expo SDK 50 and move web builds to Metro
Status: done
Repo: client
Depends on: P3.6
Branch: modernise/p3-7-expo-50-metro-web
Goal: The client runs on Expo SDK 50 (RN 0.73.6), and the web app is bundled by Metro (`npx expo export --platform web` → `dist/`) instead of the deprecated webpack.
Context: SDK step procedure with N = 50. Webpack-specific files: `webpack.config.js`, `@expo/webpack-config`, `web/`
(custom `index.html`, `404.html`, `.well-known`). With Metro, only `EXPO_PUBLIC_*` environment variables are inlined into
app code. The app reads `process.env.EXPO_ENV` in `app/api/client/links/errors.ts:166,177,203,216`; it must read
`Constants.expoConfig?.extra?.environment` instead (`app.config.ts` already sets `extra.environment`). Web-only CSS import:
`app/screens/authenticated/overview/statistics/LoadsByDay.css` (Metro web supports CSS imports).
Steps:
  1. SDK step procedure (N = 50).
  2. In `app.json`, set `"web": { "favicon": "./assets/images/favicon.png", "bundler": "metro", "output": "single" }`.
     Install the web dependencies Expo prints (`npx expo install react-dom react-native-web @expo/metro-runtime`).
  3. Delete `webpack.config.js`; `yarn remove @expo/webpack-config`. Move the needed parts of `web/index.html` (meta tags,
     fonts) into `app/+html.tsx` only if expo-router is used; otherwise keep the default HTML and note the dropped
     customisations in the PR. Copy `web/.well-known` to `public/.well-known` (Metro copies `public/` to `dist/`).
  4. Replace `process.env.EXPO_ENV` in app code with a helper `app/constants/environment.ts` that exports
     `Constants.expoConfig?.extra?.environment ?? 'production'`.
  5. In `package.json`, change `eas:build:web` to `expo export --platform web --clear`. In `.github/workflows/ci.yml`, change
     the web job to `npx expo export --platform web`. In `scripts/web-smoke.mjs` usage docs, serve `dist`.
  6. Update `backend:docs/reference/CLOUD_ENV.md` §4/§5 if any command differs from what is written there (separate backend PR).
Acceptance criteria (cloud VM):
  - expo 50.x; `EXPO_ENV=local npx expo export --platform web` exits 0 and creates `dist/index.html`;
    `python3 scripts/serve-web-build.py dist 19006` plus the web smoke test pass against the dev server.
  - Client checks and `check:graphql` pass; `grep -rn "process.env.EXPO_ENV" app` prints nothing.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: expo-router; Node upgrade (P3.15).
Risk / rollback: web build differences (fonts, favicon, deep links). The smoke test covers the main flow. Revert.
Size: L
Fixes: none

### P3.8 — Upgrade to Expo SDK 51
Status: done
Repo: client
Depends on: P3.7
Branch: modernise/p3-8-expo-51
Goal: The client runs on Expo SDK 51 (RN 0.74.5).
Context: SDK step procedure with N = 51. `expo-notifications` 0.28 needs the EAS `projectId` passed to
`getExpoPushTokenAsync({ projectId })` (`app/entrypoint/providers/PushNotificationProvider.tsx:24`). Pass
`Constants.expoConfig?.extra?.eas?.projectId`.
Steps:
  1. SDK step procedure (N = 51).
  2. Pass `projectId` to `Notifications.getExpoPushTokenAsync`.
Acceptance criteria (cloud VM):
  - expo 51.x; client checks, `check:graphql`, web export and web smoke test pass; expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: navigation upgrade (P3.9).
Risk / rollback: revert.
Size: M
Fixes: none

### P3.9 — Upgrade React Navigation 6 → 7
Status: done
Repo: client
Depends on: P3.8
Branch: modernise/p3-9-react-navigation-7
Goal: Navigation uses React Navigation 7 (`@react-navigation/native` 7.5.0, `stack` 7.12.0, `bottom-tabs` 7.20.0, `drawer` 7.14.3).
Context: Navigators: `app/screens/routes.tsx` (root stack + linking config), `drawers/UserDrawer.tsx` (drawer),
`authenticated/routes.tsx` (tabs), `dropzone/routes.tsx`, `user/routes.tsx`, `notifications/routes.tsx`,
`overview/routes.tsx`, `configuration/routes.tsx`, `limbo/routes.tsx`, `unauthenticated/routes.tsx`, `wizards/routes.tsx`,
`components/navigation_wizard/Wizard.tsx`. Breaking changes are listed in the official guide
<https://reactnavigation.org/docs/upgrading-from-6.x> (fetch it with the WebFetch tool). Known items for this code:
`navigate` to a screen in another navigator must use nested params (already done); `unmountOnBlur` is replaced by
`popToTopOnBlur`/manual handling; drawer requires `react-native-reanimated` ≥ 3; `@react-navigation/core` imports should
come from `@react-navigation/native`.
Steps:
  1. `yarn add @react-navigation/native@7.5.0 @react-navigation/stack@7.12.0 @react-navigation/bottom-tabs@7.20.0 @react-navigation/drawer@7.14.3`
     and `yarn remove @react-navigation/core` (import from `@react-navigation/native`).
  2. Apply the guide's breaking changes; replace `unmountOnBlur: true` (Notifications and Users tabs) with
     `popToTopOnBlur: true`.
  3. Fix the linking config: remove entries for unregistered screens (`Manifest.DashboardScreen`,
     `Configuration.AircraftScreen`, `Unauthenticated.SignUpWizard`) or register them (BUG-083).
  4. Update `app/__mocks__/@react-navigation/core.js` (rename/move to `native.js` if imports changed).
Acceptance criteria (cloud VM):
  - The web export log does not contain `interpolate' is not exported` (left over from P3.4: `@react-navigation/drawer` legacy overlay).
  - Client checks and web smoke test pass. Deep links `/dropzone/manifest` and `/dropzone/load/1` open the right screens
    in the web build (smoke test visits both URLs directly).
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: expo-router.
Risk / rollback: navigation regressions (back behaviour, tab state). Revert.
Size: L
Fixes: BUG-083

### P3.10 — Upgrade to Expo SDK 52
Status: done
Repo: client
Depends on: P3.9
Branch: modernise/p3-10-expo-52
Goal: The client runs on Expo SDK 52 (RN 0.76.9, React 18.3.1).
Context: SDK step procedure with N = 52. `react-native-screens` moves to 4.x (React Navigation 7, installed in P3.9, declares it as a peer `>= 4.0.0`; until this task yarn prints three peer warnings and the native behaviour with screens 3.31 is untested). Keep the legacy architecture explicitly for
this step (`"newArchEnabled": false` in `app.json` under `expo`) so that the New Architecture switch happens alone in P3.14.
Steps:
  1. SDK step procedure (N = 52), with `react-test-renderer@18.3.1`.
  2. Set `"newArchEnabled": false` in `app.json`.
Acceptance criteria (cloud VM):
  - expo 52.x; client checks, `check:graphql`, web export and web smoke test pass; expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: New Architecture.
Risk / rollback: revert.
Size: M
Fixes: none

### P3.11 — Upgrade react-native-paper 4 → 5 (infrastructure and shared components)
Status: done
Repo: client
Depends on: P3.10
Branch: modernise/p3-11-paper-5-core
Goal: react-native-paper 5.15.3 is installed with an MD2 theme so visuals stay close to today, and every shared component under `app/components/` compiles and renders.
Context: 169 files import `react-native-paper`. Paper 5 defaults to Material Design 3; MD2 is available with `MD2LightTheme`,
`MD2DarkTheme` and `theme.version = 2` (migration guide <https://callstack.github.io/react-native-paper/docs/guides/migration-guide-to-5.0>).
Themes are built in `app/state/global.ts:115-147` (`CombinedDefaultTheme`/`CombinedDarkTheme` from Paper `DefaultTheme`/`DarkTheme`)
and provided in `app/entrypoint/providers/ThemeProvider*.tsx`. `react-native-paper-dates` and `react-native-paper-tabs`
must move to versions supporting Paper 5 (`react-native-paper-dates` 0.24.0; `react-native-paper-tabs` newest).
Steps:
  1. `yarn add react-native-paper@5.15.3 react-native-paper-dates@0.24.0 react-native-paper-tabs@latest`.
  2. Build the combined themes from `MD2LightTheme`/`MD2DarkTheme` (Paper) and the React Navigation themes; keep the font
     names; keep `primary`/`accent` colours.
  3. Delete `app/types/react-native-legacy-props.d.ts` (added in P3.10 to make Paper 4's typings compile against RN 0.76).
  4. Fix every type error under `app/components/`, `app/entrypoint/`, `app/providers/`, `app/forms/` caused by Paper 5
     (e.g. `Provider` → `PaperProvider`, `Button color` → `buttonColor`/`textColor`, `Colors` export removed, `IconButton color` → `iconColor`,
     `Appbar.Content` subtitle removal, `Chip` styles).
Acceptance criteria (cloud VM):
  - `yarn check:types 2>&1 | grep -c "app/\(components\|entrypoint\|providers\|forms\)/"` prints 0. Errors may remain only under
    `app/screens/` (P3.12); list their count in the PR.
  - `yarn check:testing` passes.
Acceptance criteria (owner, real device):
  - none
Out of scope: `app/screens/`; MD3 redesign.
Risk / rollback: visual changes. Revert.
Size: L
Fixes: none

### P3.12 — Upgrade react-native-paper 4 → 5 (screens)
Status: done
Repo: client
Depends on: P3.11
Branch: modernise/p3-12-paper-5-screens
Goal: The whole app compiles and runs with Paper 5.
Context: The remaining type errors from P3.11 are under `app/screens/` (28: 21× `theme.colors.text` → use `useAppTheme()`
from `app/hooks/useAppTheme`, 3× dialog-opener `onPress` signatures, 2× `Tabs` (wrap in `TabsProvider`; drop the `theme` prop),
1× `IconButton color` → `iconColor`, 1× `Appbar.Content title`). Paper 5's `ProgressBar` fills its parent's height on web;
P3.11 added `app/components/ProgressBar.tsx` (a 4 px wrapper) and used it outside `app/screens/`. Replace the Paper `ProgressBar`
imports in `app/screens/` (`grep -rln "ProgressBar" app/screens`) with it, otherwise the manifest board renders empty on web.
Steps:
  1. Fix all remaining Paper 5 type errors and runtime warnings under `app/screens/`.
  2. Run the web smoke test and compare its screenshots with the Phase 2 ones; fix any obviously broken layout (missing
     text, invisible buttons).
Acceptance criteria (cloud VM):
  - Client checks pass with 0 type errors; web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: redesign.
Risk / rollback: revert together with P3.11.
Size: L
Fixes: BUG-099

### P3.13 — Replace remaining unmaintained UI libraries
Status: done
Repo: client
Depends on: P3.12
Branch: modernise/p3-13-replace-unmaintained-libs
Goal: No dependency is abandoned or incompatible with the New Architecture.
Context: Pass-1 inventory. `react-native-color-picker` 0.6.0 (2022; uses the removed RN core `Slider`, hence the web
warnings) is used in `app/components/input/colorpicker/*`. `react-native-input-spinner` 1.8.0 is used once
(`grep -rn react-native-input-spinner app`). `react-native-swiper-flatlist` 3.0.18 (last release 2024) is used in
`app/components/wizard/Wizard.tsx` and one other file. `react-native-image-viewing` 0.2.2 (2021) is used in
`app/components/dialogs/ImageViewer/ImageViewer.tsx`. `react-native-countdown-circle-timer` / `react-countdown-circle-timer`
3.1.0 is used in `manifest/LoadCard/CountdownTimer*.ts`.
Steps:
  1. Color picker: replace `ColorPicker.tsx` with a grid of 16 preset colour swatches plus a hex `TextInput` validated by
     `/^#[0-9a-fA-F]{6}$/`. Keep the component's props.
  2. Input spinner: replace with a Paper `TextInput` (numeric keyboard) flanked by `IconButton` minus/plus with min/max props.
  3. Swiper: replace `SwiperFlatList` in `app/components/wizard/Wizard.tsx` with a horizontal `FlatList`
     (`pagingEnabled`, `scrollEnabled={false}`, `getItemLayout` with the window width from `useWindowDimensions`) and keep
     `WizardContext` (`setIndex` → `scrollToIndex`). Do the same in the second usage.
  4. Image viewer: keep `react-native-image-viewing` if it builds; otherwise replace with a Paper `Portal` + `Modal`
     showing an `Image` with `resizeMode="contain"`.
  5. Countdown: upgrade both countdown packages to their newest versions.
  6. `yarn remove` the replaced packages.
Acceptance criteria (cloud VM):
  - The web export log contains no "is not exported from" warnings. Client checks and web smoke test pass. New render
    tests exist for the colour picker and the numeric spinner.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: chart library (react-native-chart-kit is SVG-based and maintained).
Risk / rollback: UI differences in settings/wizards. Revert.
Size: L
Fixes: none

### P3.14 — Upgrade to Expo SDK 53, React 19 and the New Architecture
Status: done
Repo: client
Depends on: P3.13
Branch: modernise/p3-14-expo-53-new-arch
Goal: The client runs on Expo SDK 53 (RN 0.79.6, React 19.0.0) with the New Architecture enabled.
Context: SDK step procedure with N = 53. React 19 requires `react-test-renderer` 19 (deprecated upstream but still used by
React Native Testing Library), `@testing-library/react-native` 13.x and Jest 29 (from `jest-expo` 53). Remove
`@testing-library/jest-native` (deprecated; RNTL ≥ 12.4 has built-in matchers) and its `setupFilesAfterEnv` entry.
React 19 removes `defaultProps` on function components and string refs. Fix any warnings.
Steps:
  1. SDK step procedure (N = 53), with `react-test-renderer@19.0.0`.
  2. `yarn add -D @testing-library/react-native@^13 jest@^29` (the versions jest-expo 53 accepts); `yarn remove @testing-library/jest-native`;
     update `package.json` `jest.setupFilesAfterEnv`.
  3. Remove `"newArchEnabled": false` from `app.json` (New Architecture on).
  4. Run `npx expo-doctor` and `npx expo install --check`. For every library reported as not supporting the New
     Architecture, upgrade it to a version that does. If none exists, stop and record it as blocked.
Acceptance criteria (cloud VM):
  - expo 53.x, react 19.0.0; client checks (including all tests) pass; web export and web smoke test pass; expo-doctor
    reports no New Architecture incompatibilities.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: Reanimated 4 (P3.15).
Risk / rollback: native modules without New Architecture support crash at runtime on devices, which the VM cannot see.
P3.22 covers it on devices. Revert.
Size: L
Fixes: none

### P3.15 — Upgrade to Expo SDK 54, Reanimated 4 and Node 24
Status: done
Repo: client
Depends on: P3.14
Branch: modernise/p3-15-expo-54
Goal: The client runs on Expo SDK 54 (RN 0.81.5, React 19.1.0, Reanimated 4.1 with `react-native-worklets`), with tooling on Node 24 LTS.
Context: SDK step procedure with N = 54. Reanimated 4 needs `react-native-worklets` and the Babel plugin
`react-native-worklets/plugin` (it replaces `react-native-reanimated/plugin`). `@gorhom/bottom-sheet` 5.2.14 supports
Reanimated 4. Android is edge-to-edge from this SDK, so screens draw under the system bars. Phase 5 fixes the layout;
note new overlaps in the PR. `react-native-keyboard-controller` 1.18.5 is bundled from this SDK and is used in Phase 5.
Steps:
  1. SDK step procedure (N = 54), with `react-test-renderer@19.1.0`.
  2. `npx expo install react-native-worklets` (EXPO_OFFLINE fallback as usual); in `babel.config.js`, replace
     `'react-native-reanimated/plugin'` with `'react-native-worklets/plugin'` (still last).
  3. `yarn add @gorhom/bottom-sheet@5.2.14 react-native-reanimated-carousel@5.1.1`. Fix API changes (bottom sheet v5:
     `BottomSheetModal` props, `enableDynamicSizing` default true; set `enableDynamicSizing={false}` where `snapPoints`
     are passed).
  4. Node 24: set `.nvmrc` to `24`; use `/opt/node24/bin` in the VM; CI uses `.nvmrc`.
Acceptance criteria (cloud VM):
  - expo 54.x; `node -v` in CI logs shows v24; client checks, web export and web smoke test pass; expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: layout fixes for edge-to-edge (Phase 5).
Risk / rollback: animations and bottom sheets. Revert.
Size: L
Fixes: none

### P3.16 — Upgrade to Expo SDK 55
Status: done
Repo: client
Depends on: P3.15
Branch: modernise/p3-16-expo-55
Goal: The client runs on Expo SDK 55 (RN 0.83.10, React 19.2.0), on the New Architecture only.
Context: SDK step procedure with N = 55. The `newArchEnabled` app config key is removed. Expo package versions switch to
SDK-numbered versions (e.g. `expo-notifications` ~55.0.27).
Steps:
  1. SDK step procedure (N = 55), with `react-test-renderer@19.2.0`.
  2. Remove any `newArchEnabled` key left in `app.json`/`app.config.ts`.
Acceptance criteria (cloud VM):
  - expo 55.x; client checks, web export and web smoke test pass; expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: anything else.
Risk / rollback: revert.
Size: M
Fixes: none

### P3.17 — Upgrade to Expo SDK 56
Status: done
Repo: client
Depends on: P3.16
Branch: modernise/p3-17-expo-56
Goal: The client runs on Expo SDK 56 (RN 0.85.3, React 19.2.3).
Context: SDK step procedure with N = 56. Known changes: iOS minimum 16.4. `expo/fetch` becomes the global `fetch`;
Apollo's HTTP link uses `fetch`, so watch for request differences and set `EXPO_PUBLIC_USE_RN_FETCH=1` only if requests
break. `@expo/vector-icons` is no longer a transitive dependency of `expo`; the app imports it directly
(`MaterialCommunityIcons`), so add it to `dependencies` with `npx expo install @expo/vector-icons`.
Steps:
  1. SDK step procedure (N = 56), with `react-test-renderer@19.2.3`.
  2. `npx expo install @expo/vector-icons`.
Acceptance criteria (cloud VM):
  - expo 56.x; client checks, web export and web smoke test pass (the smoke test performs GraphQL requests, so it covers the fetch change on web); expo-doctor output in the PR.
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: anything else.
Risk / rollback: revert.
Size: M
Fixes: none

### P3.18 — Upgrade to Expo SDK 57
Status: done
Repo: client
Depends on: P3.17
Branch: modernise/p3-18-expo-57
Goal: The client runs on the current stable Expo SDK 57 (`expo` ≥ 57.0.17, RN 0.86.3, React 19.2.3).
Context: SDK step procedure with N = 57. Expo describes SDK 57 as a low-risk release; `expo@57.0.17`+ fixes a Hermes
memory regression with Reanimated. `npx expo prebuild` now clears native directories; the repo has no `ios/`/`android/`
directories, so there is no impact.
Steps:
  1. SDK step procedure (N = 57); ensure the installed `expo` is ≥ 57.0.17 (`npx expo install expo@^57.0.27`).
Acceptance criteria (cloud VM):
  - `node -p "require('expo/package.json').version"` ≥ 57.0.17; client checks, web export and web smoke test pass;
    `npx expo-doctor` reports no errors (warnings listed in the PR).
Acceptance criteria (owner, real device):
  - none (P3.22)
Out of scope: SDK 58 (in beta on 2026-10-08).
Risk / rollback: revert.
Size: S
Fixes: none

### P3.19 — Upgrade Apollo Client, graphql-js and code generation
Status: done
Repo: client
Depends on: P3.18
Branch: modernise/p3-19-apollo-codegen
Goal: Apollo Client is on the newest 3.x (3.14.1), graphql-js on 16.x, and the generated types are regenerated with current graphql-codegen.
Context: `@apollo/client` 3.7.11, `graphql` 15.8.0, `@graphql-codegen/*` 2.x/3.x (`codegen.yml`). Generated files:
`app/api/schema.d.ts`, `operations.ts`, `reflection.tsx`, `openmanifest.graphql`, `openmanifest.json`. Apollo Client 4
is a separate breaking upgrade and is deliberately not done here; it is reconsidered after Phase 4 (see the backlog note
in Phase 4).
Steps:
  1. `yarn add @apollo/client@3.14.1 graphql@^16`.
  2. `yarn add -D` the codegen packages. Done with `cli@^5.0.7 typescript@^4.1.6 typescript-operations@^4.6.1
     typescript-react-apollo@^4.4.2 import-types-preset@^3.0.1 add@^5.0.3 introspection@^4 schema-ast@^4` instead of `@latest`:
     cli 7 / operations 6 stop emitting `__typename?` and re-declare enums as string literals (100+ type errors in fixtures and
     production code). Migrating to cli 7 is a separate task (see the deferred note in Phase 4).
  3. `yarn sync:schema && yarn ts:graphql`. Fix type errors from the regenerated code without changing documents.
  4. Remove `zen-observable`/`zen-observable-ts` if unused after the upgrade (`grep -rn zen-observable app`).
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and web smoke test pass; regenerated files are committed;
    `yarn ts:graphql && git diff --exit-code app/api` passes after the commit.
Acceptance criteria (owner, real device):
  - none
Out of scope: Apollo Client 4.
Risk / rollback: cache behaviour changes (e.g. `relayStylePagination`). Revert.
Size: M
Fixes: none

### P3.20 — Upgrade TypeScript and linting; drop Rome
Status: done
Repo: client
Depends on: P3.19
Branch: modernise/p3-20-ts-eslint
Goal: TypeScript 5.9.3 and ESLint 9-style flat config (`eslint-config-expo` for SDK 57) replace the old toolchain; Rome (unmaintained, last release 2024) is removed in favour of Prettier.
Context: `typescript` is already 5.9.3 and `ts-node` 10.9.2 since P3.9 (React Navigation 7's types need TS 5), so step 1 only adds the ESLint/Prettier packages; `.eslintrc.js` (only react-hooks rules), `rome.json`, `.prettierrc`.
TypeScript 7.0 exists but is a new native compiler; use 5.9.3, the newest 5.x, for compatibility with Expo tooling.
Steps:
  1. `yarn add -D typescript@5.9.3 eslint@^9 eslint-config-expo@~57 prettier@latest eslint-config-prettier@latest`.
     Remove `rome`, `@react-native-community/eslint-config`, `eslint-config-airbnb-typescript*`, `eslint-config-universe`
     and `eslint-import-resolver-babel-module` if no longer referenced.
  2. Create `eslint.config.js` extending `eslint-config-expo/flat` and `eslint-config-prettier`, keeping
     `react-hooks/exhaustive-deps: error`; delete `.eslintrc.js`, `rome.json` and `tsconfig.eslint.json` if unused.
  3. Scripts: `check:linting` = `eslint app && prettier --check "app/**/*.{ts,tsx}"`; remove the rome scripts.
  4. Run `prettier --write app` in a separate commit titled `style: prettier format [P3.20]`.
Acceptance criteria (cloud VM):
  - Client checks pass; `npx tsc -v` → 5.9.3; `grep -c rome package.json` → 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing lint findings beyond auto-fix (list counts in the PR if rules are downgraded to `warn`).
Risk / rollback: formatting-only diffs. Revert.
Size: M
Fixes: none

### P3.21 — Modernise app configuration and EAS build profiles
Status: done
Repo: client
Depends on: P3.20
Branch: modernise/p3-21-eas-config
Goal: All app config lives in `app.config.ts` with one version source, EAS profiles match current EAS CLI, and a development-client profile exists for owner device testing.
Context: `app.json` and `app.config.ts` overlap (`version` 1.3.0 in `app.json` vs 1.1.60 in `package.json`, BUG-088). EAS:
`eas.json` (`cli.version >= 3.6.1`; current `eas-cli` is 24.12.0), `runtimeVersion.policy: sdkVersion`, `updates.url`
with project id `1d8fa34d-2ff8-4095-ab49-29a426117a8c`. Android permissions include `CAMERA_ROLL`,
`READ/WRITE_EXTERNAL_STORAGE`, which are obsolete on current Android. Owner accounts are decision D2.
Steps:
  1. Move everything from `app.json` into `app.config.ts` and delete `app.json`. Take `version` from `package.json`
     (`build/constants.ts` `APP_VERSION`). Remove `ios.buildNumber`/`android.versionCode`; use EAS remote versioning
     (`"cli": { "version": ">= 24.12.0", "appVersionSource": "remote" }` in `eas.json`) with `autoIncrement: true` in
     the store profiles.
  2. Set `runtimeVersion: { policy: 'appVersion' }`.
  3. Add `expo-dev-client` (`npx expo install expo-dev-client`) and set the `development` profile to
     `"developmentClient": true, "distribution": "internal"`.
  4. Android permissions: keep `CAMERA`, `ACCESS_COARSE_LOCATION`, `NOTIFICATIONS` (`POST_NOTIFICATIONS` is added by
     expo-notifications); remove `CAMERA_ROLL`, `MEDIA_LIBRARY`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
     (the image picker uses the system photo picker).
  5. Run `npx expo config --type public` and include the output in the PR.
  6. (Done in P3.10: the direct `@expo/config-plugins` and `@expo/metro-config` installs were removed because the old
     metro-config broke `expo export` on SDK 52; `metro.config.js` already uses `expo/metro-config` since P3.7.) Verify that
     `grep -n "@expo/config-plugins\|@expo/metro-config" package.json` still prints nothing.
Acceptance criteria (cloud VM):
  - `npx expo config --type public` exits 0; `test ! -f app.json`; client checks, web export and web smoke test pass;
    `npx expo-doctor` reports no config errors.
Acceptance criteria (owner, real device):
  - After D2: `eas build --profile development --platform all` succeeds on the owner's EAS account, and the dev client installs on an iPhone and an Android phone.
Out of scope: store submission (Phase 8).
Risk / rollback: config regressions show up only in native builds. Revert.
Size: M
Fixes: BUG-088

### P3.22 — Verify Phase 3
Status: owner-check (answer D4, merge the Phase 0–3 stacks in order and confirm CI on staging; device smoke run with EAS development builds — see docs/verification/phase-3.md)
Repo: both
Depends on: P3.1, P3.2, P3.4, P3.5, P3.6, P3.7, P3.8, P3.9, P3.10, P3.11, P3.12, P3.13, P3.14, P3.15, P3.16, P3.17, P3.18, P3.19, P3.20, P3.21
Branch: modernise/p3-22-verify
Goal: The upgraded client is proven in the VM and, by the owner, on real devices.
Context: Phase gate. P3.3 (Facebook login removal, D4 option a) is done; add it to the dependencies when the verification is run.
BUG-016 (client advisories) should be largely resolved.
Steps:
  1. Run client checks, `check:graphql`, web export, web smoke test, `npx expo-doctor`, and
     `yarn audit --groups dependencies --summary` (record the counts).
  2. Write `backend:docs/verification/phase-3.md` with versions (`expo`, `react-native`, `react`, Node), test counts,
     audit counts and doctor output.
  3. Update client reference §10 and backend reference §10 with current versions.
Acceptance criteria (cloud VM):
  - All commands exit 0; yarn audit shows no critical advisories in `dependencies`; CI green on `staging`.
Acceptance criteria (owner, real device):
  - With EAS development builds (needs D2): run all of `client:docs/SMOKE_TEST.md` on an iPhone (iOS ≥ 16.4), an Android
    phone, a small Android phone (360×640 dp) and with maximum font size. Also check push notifications (manifest a user,
    give a call), Apple login, the camera/photo picker on the profile avatar, and maps on the dropzone setup location
    step (BUG-085). Record results in `docs/verification/phase-3.md`; layout failures are expected and feed Phase 5.
Out of scope: fixing layout (Phase 5).
Risk / rollback: none.
Size: S
Fixes: BUG-016

---

## Phase 4 — Client state

Goal: Apollo is the only server-data cache; a small zustand store holds session and UI preferences; form state lives
in react-hook-form; Redux and redux-persist are removed. Credentials move to `expo-secure-store` on native.

Current shape (`client:app/state/store.ts`, `global.ts`, `app/screens/slice.ts`, `app/components/forms/slice.ts`):

| Slice | Contents | Target |
|---|---|---|
| `global` (persisted) | `credentials`, `authenticated`, `currentDropzoneId`, `expoPushToken`, `currentRouteName` | `useSession` zustand store (P4.1) |
| `global` (persisted) | `theme`, `palette`, `isDarkMode` | `useAppTheme` hook + `usePreferences` store (P4.2) |
| `global` (persisted) | `currentUser`, `currentDropzone`, `permissions` (deprecated snapshots) | removed; read from Apollo (P4.3) |
| `screens.*` | manifest, users, login, signup, dropzoneWizard UI state | component state / route params (P4.4) |
| `forms.*` | dropzone, dropzoneUser, rig, rigInspection, rigInspectionTemplate, user, weather, manifest, manifestGroup | react-hook-form + dialog context (P4.5–P4.7) |
| `imageViewer` | open image | component state (P4.4) |

Libraries: `zustand` 5.0.15 (`persist` middleware with `createJSONStorage`), `expo-secure-store` (version from
`npx expo install` for SDK 57), `@react-native-async-storage/async-storage` (already present). Apollo stays on 3.14.1;
P4.9 records Apollo 4 as backlog.

### P4.1 — Introduce the session store and move credentials to secure storage
Status: owner-check (install the previous dev build, log in, install this build over it on iOS and Android: still logged in; log out and in works)
Repo: client
Depends on: P3.22
Branch: modernise/p4-1-session-store
Goal: Session data (credentials, current dropzone, push token, current route) lives in a zustand store; credentials are
stored with `expo-secure-store` on native and `localStorage` on web; existing logged-in users stay logged in.
Context: `app/state/global.ts` (`setCredentials`, `logout`, `setDropzone`, `setPushToken`, `setRoute`); readers of
`credentials` (`app/api/client/links/authentication.ts`, `app/api/client/client.ts`, `app/screens/routes.tsx`, login/Apple/confirm screens), `currentDropzoneId` (21 files),
`expoPushToken` (`app/entrypoint/providers/PushNotificationProvider.tsx`), `currentRouteName` (2 files). Persist key
`open-manifest.0.9.1` (`persist:open-manifest.0.9.1` in storage). BUG-017.
Steps:
  1. `npx expo install expo-secure-store` and `yarn add zustand@5.0.15`.
  2. Create `app/state/session.ts` exporting `useSession` (zustand + `persist`) with state
     `{ credentials: { accessToken, client, uid, tokenType, expiry } | null, currentDropzoneId: string | null,
     expoPushToken: string | null, currentRouteName: string | null }` and actions `setCredentials`, `clearCredentials`,
     `setDropzone`, `setPushToken`, `setRoute`, plus `hydrated: boolean`.
     Storage adapter `app/state/storage.ts`: on native, `credentials` are written to `SecureStore` under
     `openmanifest.credentials` and the rest to AsyncStorage key `openmanifest.session.v1`; on web both go to
     `localStorage`. Use `partialize` so `credentials` are not written to AsyncStorage.
  3. One-time migration in `app/state/migrateFromReduxPersist.ts`: if `openmanifest.session.v1` is absent and
     `persist:open-manifest.0.9.1` exists, parse it (redux-persist stores each slice as a JSON string), copy
     `global.credentials`, `global.currentDropzoneId`, `global.expoPushToken` into the session store, then leave the old
     key in place (P4.8 deletes it). Call it before rendering in `app/entrypoint/` and gate rendering on `hydrated`.
  4. Delete those four fields from the `global` slice (state type, initial state, reducers). `yarn check:types` then lists
     every reader, including components that destructure `useAppSelector((root) => root.global)`. Replace each with
     `useSession` selectors/actions (non-React code such as Apollo links uses `useSession.getState()`). The migration in
     step 3 reads the raw storage key, not the slice.
  5. Add `app/state/__tests__/session.test.ts`: migration from a fixture redux-persist blob; credentials written via
     the SecureStore mock (`jest.mock('expo-secure-store')`) and not present in the AsyncStorage mock.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass.
  - The `global` slice state type no longer has `credentials`, `currentDropzoneId`, `expoPushToken`, `currentRouteName` (`yarn check:types` passes).
  - In the web smoke test, a session created by the pre-P4.1 build (run the smoke login against the `staging` web
    export, then serve this branch's export on the same origin) is still logged in after reload.
Acceptance criteria (owner, real device):
  - Install the previous dev build, log in, then install this build over it: still logged in on iOS and Android;
    logging out and in works.
Out of scope: theme (P4.2); removing Redux (P4.8).
Risk / rollback: a migration bug logs users out (they log in again). Revert restores the old key, which is untouched.
Size: L
Fixes: BUG-017

### P4.2 — Replace the Redux theme state with a theme hook
Status: owner-check (dark mode toggle in Settings → Appearance and system dark mode on one phone)
Repo: client
Depends on: P4.1
Branch: modernise/p4-2-theme-hook
Goal: Theme and palette come from `useAppTheme()` (Paper theme + dropzone colours) and a persisted `usePreferences`
store (`colorScheme: 'system' | 'light' | 'dark'`), not Redux.
Context: `root.global.theme` (19 files) and `palette` (18 files) are derived in `global.ts` reducers from the current
dropzone's `primaryColor`/`secondaryColor` and the device scheme (`app/hooks/useColorScheme*.ts`). Paper 5 MD2 theme
from P3.11.
Steps:
  1. Create `app/state/preferences.ts` (`usePreferences`, zustand + persist, AsyncStorage/localStorage key
     `openmanifest.preferences.v1`) with `colorScheme` and `setColorScheme`.
  2. Create `app/theme/useAppTheme.ts`: reads `usePreferences`, `useColorScheme()` and the current dropzone colours
     from the Apollo `DropzoneEssentials`/current dropzone query, returns `{ theme, palette, isDark }` built with the
     existing palette functions moved from `global.ts` to `app/theme/palette.ts`.
  3. Pass `useAppTheme().theme` to `PaperProvider` and `NavigationContainer`. Delete `theme`, `palette`, `isDarkMode` and
     their reducers from the `global` slice and fix every reader `yarn check:types` reports (many destructure
     `root.global`). Move the dark-mode toggle in settings to `usePreferences`.
  4. Unit-test `palette.ts` (light/dark, dropzone colours present/absent).
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; the `global` slice state type has no `theme`, `palette` or `isDarkMode`.
  - Web smoke screenshots of login and manifest board match the P4.1 screenshots (visual check in the PR).
Acceptance criteria (owner, real device):
  - Dark mode toggle and system dark mode work on one phone.
Out of scope: dark-mode bugs on specific screens (BUG-087, P5.6).
Risk / rollback: visual only. Revert.
Size: M
Fixes: none

### P4.3 — Remove deprecated user and dropzone snapshots from global state
Status: done
Repo: client
Depends on: P4.2
Branch: modernise/p4-3-remove-snapshots
Goal: `currentUser`, `currentDropzone` and `permissions` are read only from Apollo (the dropzone context provider and `app/api/crud/useDropzone.tsx`).
Context: The fields are marked deprecated in `global.ts`; reducers `setUser`, `setDropzone(object)`, `setPermissions`
are still dispatched from providers and the login form. `app/screens/routes.tsx` uses `currentDropzone` to choose
Limbo vs Authenticated; it must use `useSession().currentDropzoneId` instead.
Steps:
  1. Delete the fields, reducers and dispatches from the `global` slice; fix every reader `yarn check:types` reports using
     the existing Apollo-backed hooks (`app/api/crud/useDropzone.tsx` / the dropzone context provider in
     `app/entrypoint/providers/Dropzones.tsx`).
  2. Add `version` + `migrate` to the redux-persist config (still present until P4.8) that drops the removed keys.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; the `global` slice state type has no `currentUser`, `currentDropzone` or `permissions`.
Acceptance criteria (owner, real device):
  - none
Out of scope: anything else in Redux.
Risk / rollback: low. Revert.
Size: S
Fixes: none

### P4.4 — Move screen slices and the image viewer to local state
Status: done
Repo: client
Depends on: P4.3
Branch: modernise/p4-4-screen-state
Goal: `screens.*` and `imageViewer` slices are replaced by component state, route params or small React contexts.
Context: `app/screens/slice.ts` (manifest, users, login, signup, dropzoneWizard; 15 files read `screens.*`),
`app/components/dialogs/ImageViewer/slice.ts`. Manifest board filters (date, display mode) are shared between the board
and its header, so they go into the existing `app/providers/manifest/provider.tsx` context.
Steps:
  1. manifest → `ManifestContext` fields (`date`, `display`, `showCompletedLoads`); users → `UserListScreen` state +
     search param; login/signup → form state (RHF); dropzoneWizard → wizard component state; imageViewer →
     `ImageViewerProvider` context in `app/components/dialogs/ImageViewer/`.
  2. Delete `app/screens/slice.ts`, the image viewer slice and their store wiring.
  3. Update or add tests touched by P1.11–P1.13 so they no longer dispatch screen actions.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `test ! -f app/screens/slice.ts`; `grep -rn "screens\." app/state` prints nothing.
Acceptance criteria (owner, real device):
  - none
Out of scope: forms.
Risk / rollback: low. Revert.
Size: M
Fixes: none

### P4.5 — Move setup forms to react-hook-form (group 1)
Status: owner-check (edit dropzone settings, weather conditions and your own profile on one phone)
Repo: client
Depends on: P4.4
Branch: modernise/p4-5-forms-group-1
Goal: `forms.dropzone`, `forms.weather`, `forms.user` slices are replaced with react-hook-form + yup; dialogs receive
the record to edit as a prop or via an `open(record)` callback.
Context: `app/components/forms/dropzone`, `weather_conditions`, `user` and their screens/dialogs. `app/forms/*` already
uses RHF + yup (pattern to copy: `app/forms/aircraft`). Forms slice: `app/components/forms/slice.ts`.
Steps:
  1. For each form: create `app/forms/<name>/{schema.ts,useForm.tsx}` like `app/forms/aircraft`, move field
     components to `useController`, move submit logic from screens into `useForm`'s `onSubmit`.
  2. Replace `actions.forms.<name>.setOpen/setField/reset` with props/local state; delete the slice entries.
  3. Tests: one RHF test per form (validation error shown, submit calls the mutation mock with expected variables).
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -rnE "forms\.(dropzone|weather|user)\b" app` prints nothing.
Acceptance criteria (owner, real device):
  - Edit dropzone settings, weather conditions and own profile on one phone.
Out of scope: layout of these forms (Phase 5).
Risk / rollback: form regressions are covered by the new tests. Revert.
Size: L
Fixes: none

### P4.6 — Move equipment and membership forms to react-hook-form (group 2)
Status: owner-check (add a rig, inspect a rig, edit a member's role/expiry on one phone)
Repo: client
Depends on: P4.5
Branch: modernise/p4-6-forms-group-2
Goal: `forms.dropzoneUser`, `forms.rig`, `forms.rigInspection`, `forms.rigInspectionTemplate` are RHF forms.
Context: `app/components/forms/{dropzone_user,rig,rig_inspection,rig_inspection_template}`, `app/components/dialogs/{DropzoneUserDialog,Rig}.tsx`,
readers in `screens/authenticated/user/**` and `configuration/{rigs,rig_inspection_template}`.
Steps:
  1. As P4.5 step 1–2 for the four forms. Rig inspection keeps its dynamic template fields: the schema is built from the
     template definition with `yup.object(Object.fromEntries(...))`.
  2. Tests as P4.5 step 3.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -rnE "forms\.(dropzoneUser|rig|rigInspection|rigInspectionTemplate)\b" app` prints nothing.
Acceptance criteria (owner, real device):
  - Add a rig, inspect a rig, edit a member's role/expiry on one phone.
Out of scope: layout.
Risk / rollback: as P4.5.
Size: L
Fixes: none

### P4.7 — Move manifest forms into the manifest context
Status: owner-check (on a phone: manifest a group from the load screen's speed dial and from an "available" row; edit a slot by tapping it)
Repo: client
Depends on: P4.6
Branch: modernise/p4-7-manifest-dialogs
Goal: The manifest-user and manifest-group sheets are mounted once inside `ManifestProvider` and opened through
`useManifestContext().dialogs.{manifestUser,manifestGroup}.open(...)` from both the board and the load screen.
Context: BUG-066 (group sheet only mounted in `LoadScreen`, FIXMEs at `ManifestScreen.tsx:198` and `LoadScreen`),
BUG-079 (tapping an ungrouped slot dispatches `forms.manifest.setOpen`, which nothing reads; nested `if (canEditSelf)`
hides slots from staff with `updateUserSlot` only). `app/forms/manifest_user`, `app/components/dialogs/ManifestGroup`.
Steps:
  1. Add a `dialogs` object to `app/providers/manifest/provider.tsx` with state `{ open: boolean, load, slot?, users? }`
     per dialog and render `ManifestUserSheet` and `ManifestGroupSheet` once inside the provider.
  2. Board actions (`ManifestScreen.tsx` 194-207, `LoadCard/Large/Card.tsx` 140-150) and `LoadScreen` slot taps call the
     context; remove the FIXMEs. Fix the permission branch: open the slot editor when the user has `updateSlot` and the
     slot is their own, or `updateUserSlot` (the API checks `updateSlot` for your own slot and `updateUserSlot` for
     someone else's, `update_slot.rb:50`).
  3. Delete `forms.manifest` and `forms.manifestGroup` slices.
  4. Tests: from the board, "Manifest group" opens the group sheet; tapping a slot on the load screen opens the user
     sheet; a user with only `updateUserSlot` can open someone else's slot, one with only `updateSlot` cannot.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -rnE "forms\.(manifest|manifestGroup)\b" app` prints nothing.
  - Web smoke test extended: open the group sheet (from the load screen's speed dial: neither board display mode has a group action, see BUG-066).
Acceptance criteria (owner, real device):
  - On a phone: manifest a group from the board and from the load screen; edit a slot by tapping it.
Out of scope: group manifest server bugs (P6.13).
Risk / rollback: central flow, covered by tests from P1.12. Revert.
Size: L
Fixes: BUG-066, BUG-079

### P4.8 — Remove Redux and make logout reset everything
Status: owner-check (on a phone: log out and log in as a different user without killing the app; the second user must not receive the first user's push notifications, which also needs P6.18)
Repo: client
Depends on: P4.7
Branch: modernise/p4-8-remove-redux
Goal: Redux, react-redux, redux-persist and @reduxjs/toolkit are gone; one `resetSession()` performs logout and
dropzone switching consistently.
Context: BUG-063 (module-level `AbortController` in `app/api/client/links/http.ts` aborted by `useLogout`, every later
request fails), BUG-069 (logout resets only `global`; auth-error logout in `app/api/client/links/errors.ts:191-199`
does not clear Apollo; dropzone switch keeps form state), BUG-018 client part (push token not cleared server-side on
logout), BUG-064 (`useLoad().manifestUser` inverted guard, unused).
Steps:
  1. `app/state/resetSession.ts`: `async function resetSession({ reason })` → best-effort
     `updateUser(input: { pushToken: null })` mutation for the current user when online (BUG-018), then
     `apolloClient.clearStore()`, `useSession.getState().clearCredentials()`, `setDropzone(null)`, and
     `SecureStore.deleteItemAsync('openmanifest.credentials')`. `useLogout` and the error link both call it.
     Dropzone switching calls `apolloClient.resetStore()` after `setDropzone`.
  2. Remove the shared `AbortController`; `BatchHttpLink` gets no `signal`. If cancellation of in-flight requests on
     logout is needed, use `apolloClient.stop()` before `clearStore()`.
  3. Delete `app/state/store.ts`, `global.ts`, `app/components/forms/slice.ts`, `<Provider store>` and `PersistGate`;
     delete the legacy `persist:open-manifest.0.9.1` key in `migrateFromReduxPersist.ts` after migrating.
     `yarn remove redux react-redux redux-persist @reduxjs/toolkit`.
  4. Delete `manifestUser` from `app/api/crud/useLoad.tsx` (BUG-064, unused).
  5. Tests: log in → log out → log in as another user in one test: second login's requests succeed (BUG-063), Apollo
     cache has no data from the first user, the push-token mutation was called with null (BUG-069, BUG-018).
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass. `grep -E '"(redux|react-redux|redux-persist|@reduxjs/toolkit)"' package.json` prints nothing.
  - Web smoke test extended: login → logout → login without reload succeeds.
Acceptance criteria (owner, real device):
  - On a phone: log out and log in as a different user without killing the app; the second user does not receive the
    first user's push notifications (after P6.18 for the server side).
Out of scope: server-side push-token handling (P6.18).
Risk / rollback: auth flow changes. Covered by tests; revert restores Redux.
Size: L
Fixes: BUG-063, BUG-064, BUG-069

### P4.9 — Verify Phase 4
Status: owner-check (merge the Phase 0–4 stacks in order and confirm CI on staging; run SMOKE_TEST Login and Manifest on an iPhone and an Android phone, including logging in as a second user without restarting the app — see docs/verification/phase-4.md)
Repo: both
Depends on: P4.1, P4.2, P4.3, P4.4, P4.5, P4.6, P4.7, P4.8
Branch: modernise/p4-9-verify
Goal: Client state is simplified and proven.
Context: Phase gate.
Steps:
  1. Run client checks, web export, web smoke test and `check:graphql`; record test counts.
  2. Write `backend:docs/verification/phase-4.md`. Add a "Backlog" line: "Apollo Client 4 (`@apollo/client` 4.x) —
     reconsider after Phase 6; requires `useQuery` callback removal and new error types." Add a second Backlog line:
     "graphql-codegen 7 (cli 7, typescript-operations 6) — P3.19 stayed on cli 5 / plugins 4 because the 6.x operations plugin
     stops emitting `__typename?` and re-declares enums as string literals; migrate with `nonOptionalTypename` decisions for the
     fixtures and mocks."
  3. Update `client:docs/reference/README.md` §3 (store shape) and `client:docs/reference/diagrams.md` §2 to describe the
     zustand stores and remove the Redux diagram.
Acceptance criteria (cloud VM):
  - All commands exit 0; CI green on `staging`.
Acceptance criteria (owner, real device):
  - Run `client:docs/SMOKE_TEST.md` sections Login and Manifest on one iPhone and one Android phone, including
    logout/login as a second user without restarting the app.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 5 — Android and small-screen layout

Goal: every screen works on a 360×640 dp Android phone, with the keyboard open, at font scale 2.0, in edge-to-edge
mode, and on web at 360×640 and 1280×800. Fixes are organised by the root causes in
[BUGS.md "Android / mobile layout"](reference/BUGS.md#android--mobile-layout-shared-root-causes) (RC1–RC9), applied
screen group by screen group on top of four shared primitives.

Libraries (all installed with `npx expo install` for SDK 57): `react-native-safe-area-context` (already present),
`react-native-keyboard-controller` (`KeyboardProvider`, `KeyboardAwareScrollView`, `KeyboardStickyView`),
`@gorhom/bottom-sheet` 5.2.14 (`BottomSheetTextInput`, `keyboardBehavior="interactive"`,
`android_keyboardInputMode="adjustResize"`). `app.config.ts` must have `android.softwareKeyboardLayoutMode: "resize"`
and edge-to-edge (default from SDK 54).

Layout rules every Phase 5 task applies:

1. No fixed `width`/`minWidth` above 280 on containers; use `width: '100%'` with `maxWidth` (RC1).
2. Every screen root is `ScreenContainer` (safe-area aware); no hard-coded top/bottom offsets (RC2).
3. No `Dimensions.get('window')` for layout; use flex, or `useWindowDimensions()` only for breakpoints (RC3).
4. Forms use `FormColumn` (keyboard-aware scroll); no `KeyboardAvoidingView` (RC4).
5. One scroll container per axis: a screen with a list uses the list as the scroll container with
   `ListHeaderComponent`/`ListFooterComponent` (RC5).
6. FABs use `FloatingActionArea`, rendered outside scroll content (RC6).
7. Tall content is always scrollable (RC7).
8. Rows use `minHeight`, not `height`; titles use theme variants, not fixed 50–72 pt sizes (RC8).
9. `Platform.select` blocks have a `default` branch (RC9).

The web smoke test (P0.8) gains a layout check in P5.1 that every later task extends: for each listed route, at
360×640, `document.scrollingElement.scrollWidth <= 360` and every element matching `[data-testid$="-primary-action"]`
can be scrolled into view and clicked.

### P5.1 — Add layout primitives and the layout smoke check
Status: done
Repo: client
Depends on: P4.9
Branch: modernise/p5-1-layout-primitives
Goal: Four shared primitives exist with tests and a demo in the web smoke test; the smoke test checks horizontal overflow.
Context: Existing wrappers `app/components/layout/Screen*.tsx`, `ScrollableScreen`, `components/wizard/WizardScreen.tsx`.
`react-native-keyboard-controller` is bundled from SDK 54 (`npx expo install react-native-keyboard-controller`).
Steps:
  1. `npx expo install react-native-keyboard-controller`. Wrap the app in `KeyboardProvider` in `app/entrypoint/`
     (inside `SafeAreaProvider`). Set `android.softwareKeyboardLayoutMode: "resize"` in `app.config.ts`.
  2. Create in `app/components/layout/`:
     - `ScreenContainer.tsx`: `SafeAreaView` (`edges` prop, default `['top','bottom']` for headerless screens and
       `['bottom']` under a navigator header), theme background, `flex: 1`.
     - `FormColumn.tsx`: `KeyboardAwareScrollView` (`bottomOffset={16}`, `keyboardShouldPersistTaps="handled"`) with
       content `width: '100%'`, `maxWidth: 560`, `alignSelf: 'center'`, horizontal padding 16.
     - `FloatingActionArea.tsx`: absolutely positioned container anchored to the bottom-right with
       `useSafeAreaInsets().bottom + 16`, wrapped in `KeyboardStickyView` so it rises with the keyboard.
     - `useBreakpoint.ts`: `useWindowDimensions()` → `'compact' | 'medium' | 'expanded'` (< 600, < 1024, ≥ 1024).
  3. On web, `react-native-keyboard-controller` components fall back to plain `ScrollView`/`View`; verify the web
     export.
  4. Unit tests: `FormColumn` renders children inside a scroll view; `FloatingActionArea` applies the bottom inset
     (mock `useSafeAreaInsets`).
  5. Extend `scripts/web-smoke.mjs` with `checkLayout(route)` (rules above) and run it on `/login` only; mark the check
     for other routes as TODO comments with the owning task ID.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -c KeyboardProvider app/entrypoint -r` ≥ 1.
Acceptance criteria (owner, real device):
  - none
Out of scope: changing screens (P5.2–P5.8).
Risk / rollback: additive. Revert.
Size: M
Fixes: none

### P5.2 — Fix the wizards
Status: owner-check (small Android phone at font scale 2.0: complete sign-up and dropzone setup with the keyboard open on each field; close client#133 and client#134 if they no longer reproduce)
Repo: client
Depends on: P5.1
Branch: modernise/p5-2-wizards
Goal: Sign-up, user setup, dropzone setup and password wizards fit 360 dp, scroll with the keyboard open, and keep their
buttons reachable (GitHub issues client#133, client#134).
Context: RC1/RC3/RC4/RC8. `app/components/carousel_wizard/{Wizard,HookFormWizard,Step}.tsx` (fixed `minWidth`/`width`
300–400 at `Step.tsx:74,81`, `Wizard.tsx:147,165`; `KeyboardAvoidingView behavior={undefined}` at `Wizard.tsx:95-98`,
`HookFormWizard.tsx:76-79`); `app/components/wizard/WizardScreen.tsx`; wizard titles at 72 pt.
Steps:
  1. `Step.tsx`: replace fixed widths with `width: '100%', maxWidth: 400`; wrap step content in `FormColumn`; titles use
     `variant="headlineMedium"`.
  2. `Wizard.tsx`/`HookFormWizard.tsx`: remove `KeyboardAvoidingView`; page width from `onLayout` of the container, not
     `Dimensions`; the next/back buttons go in a `KeyboardStickyView` footer inside `ScreenContainer`.
  3. Add `testID`s `wizard-next-primary-action` and run `checkLayout` for `/signup` and `/setup` (the dropzone wizard; with
     the dev seed's admin user) in the web smoke test.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test (with the new routes) pass.
Acceptance criteria (owner, real device):
  - On a small Android phone (360×640 dp) and at font scale 2.0: complete sign-up and dropzone setup with the keyboard
    open on each field; every button is reachable. Close client#133 and client#134 if they no longer reproduce.
Out of scope: map step behaviour (BUG-085).
Risk / rollback: visual. Revert.
Size: L
Fixes: BUG-070, BUG-073 (wizards)

### P5.3 — Fix login, sign-up entry and dropzone selection
Status: owner-check (small Android phone and iPhone with notch: login with keyboard open, Apple button and "Sign up" reachable; dropzone list not under the status bar)
Repo: client
Depends on: P5.2
Branch: modernise/p5-3-login-limbo
Goal: Login and dropzone selection scroll, respect safe areas and fit 360×640.
Context: RC2/RC7. `screens/unauthenticated/login/LoginScreen.tsx:16-37,60-79` (non-scrolling centred `ImageBackground`,
300 px logo, negative margin), `login/form/LoginForm.tsx`, `limbo/dropzone_select/*`, `app_signal/ErrorScreen.tsx`.
Pass-1 web reproduction: "Sign up" at y=653.5 in a 640 px viewport, no scroll.
Steps:
  1. LoginScreen: `ImageBackground` as absolute fill behind `ScreenContainer` > `FormColumn`; logo
     `width: '60%', maxWidth: 300, aspectRatio: 1`; remove negative margins.
  2. Dropzone select and error screens: `ScreenContainer`; list as the only scroll container; FAB in `FloatingActionArea`.
  3. Web smoke: `checkLayout('/login')` now also asserts the "Sign up" button can be clicked at 360×640; add
     `checkLayout` for the dropzone selection route.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass, including the "Sign up" reachability assertion.
Acceptance criteria (owner, real device):
  - Small Android phone and iPhone with notch: login with keyboard open, Apple button and "Sign up" reachable; dropzone
    list not under the status bar.
Out of scope: auth logic.
Risk / rollback: visual. Revert.
Size: M
Fixes: BUG-076, BUG-071 (login, limbo, error screens)

### P5.4 — Fix bottom sheets and dialogs
Status: owner-check (small Android phone: in each sheet (manifest user, group, credits, aircraft, ticket type, rig) focus the last input; the input and the save button stay visible; say whether the save button needs a pinned footer)
Repo: client
Depends on: P5.3
Branch: modernise/p5-4-bottom-sheets
Goal: All bottom sheets handle the keyboard natively and respect the bottom inset.
Context: RC2/RC4. Sheets using a fixed 400 px bottom padding when the keyboard is visible and plain `TextInput`:
`app/components/dialogs/**`, `app/components/forms/**` sheets (manifest user, manifest group, credits, aircraft,
ticket type, rig). Bottom-sheet 5.2.14 (P3.15).
Steps:
  1. Create `app/components/layout/Sheet.tsx` wrapping `BottomSheetModal` with `keyboardBehavior="interactive"`,
     `keyboardBlurBehavior="restore"`, `android_keyboardInputMode="adjustResize"`, `bottomInset={insets.bottom}`,
     `enableDynamicSizing`, content in `BottomSheetScrollView`.
  2. Replace every direct `BottomSheetModal` use with `Sheet`; replace `TextInput` inside sheets with an input component
     that renders `BottomSheetTextInput` (Paper `TextInput` with `render` prop); delete keyboard padding hacks
     (`grep -rn "400" app/components | grep -i padding`).
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -rn "<BottomSheetModal[^P]" app | grep -v layout/Sheet.tsx` prints nothing (`[^P]` excludes `<BottomSheetModalProvider>`).
Acceptance criteria (owner, real device):
  - Small Android phone: in each sheet (manifest user, group, credits, aircraft, ticket type, rig) focus the last input;
    the input and the save button stay visible.
Out of scope: sheet content redesign.
Risk / rollback: visual. Revert.
Size: L
Fixes: BUG-073 (sheets)

### P5.5 — Fix the manifest board and load screen
Status: owner-check (small Android phone: board scrolls to the last load above the tab bar; load screen scrolls to the last jumper; FABs float above the gesture bar)
Repo: client
Depends on: P5.4
Branch: modernise/p5-5-manifest-layout
Goal: The manifest board and load screen use flex layout and a single scroll container.
Context: RC2/RC3/RC5. `ManifestScreen.tsx:253,277` (`height - 56 * 2`), `dropzone/load/views/CardView.tsx:86`,
`components/layout/ScrollableScreen` (`minHeight: height` + 200 padding), `LoadScreen.tsx:165` (FlatList inside
`Screen` = ScrollView on native), module-level `Dimensions.get`, manifest FAB group.
Steps:
  1. Board: the loads `FlatList` fills the screen with `flex: 1`; column count from `useBreakpoint`; FAB group in
     `FloatingActionArea`; delete window-height arithmetic.
  2. Load screen: render header/details as `ListHeaderComponent` of the slots `FlatList`; remove the outer ScrollView.
  3. `ScrollableScreen`: remove `minHeight: height` and the 200 px padding; use `contentContainerStyle={{ flexGrow: 1,
     paddingBottom: insets.bottom + 80 }}` when a FAB is present.
  4. Web smoke: `checkLayout` on the board and a load; assert the last slot row can be scrolled into view at 360×640
     with 10 jumpers (dev seed load with 10 slots).
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; React Native "VirtualizedLists should never be nested" does not
    appear in Jest output for the load screen test (`grep -c "VirtualizedLists" jest.log` → 0).
Acceptance criteria (owner, real device):
  - Small Android phone: board scrolls to the last load above the tab bar; load screen scrolls to the last jumper; FABs
    float above the gesture bar.
Out of scope: manifest logic.
Risk / rollback: central screen; visual regressions caught by screenshots. Revert.
Size: L
Fixes: BUG-072, BUG-074 (load screen), BUG-071 (FABs on manifest)

### P5.6 — Fix configuration screens
Status: owner-check (small Android phone, dark mode: each configuration screen's FAB floats and its last row is reachable)
Repo: client
Depends on: P5.5
Branch: modernise/p5-6-configuration-layout
Goal: Configuration screens (aircraft, ticket types, extras, rigs, rig inspection template, transactions, permissions,
master log, dropzones table) have floating FABs, single scroll containers and theme colours.
Context: RC5/RC6. FABs inside scroll content at `configuration/aircrafts/AircraftsScreen.tsx:104-111`,
`ticket_types/TicketTypesScreen.tsx`, `rigs/DropzoneRigsScreen.tsx`; hard-coded `backgroundColor: 'white'`
(BUG-087, `TicketTypesScreen.tsx:62`, `DropzoneRigsScreen.tsx`); nested dropzones table list.
Steps:
  1. Each screen: `ScreenContainer edges={['bottom']}` > list as the scroll container > `FloatingActionArea` outside it.
  2. Replace `'white'` and other literal colours with `theme.colors.surface`/`background`
     (`grep -rnE "'(white|#fff|#ffffff)'" app/screens/authenticated/configuration`).
  3. Web smoke: `checkLayout` on each configuration route; one dark-mode screenshot of ticket types.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; the grep in step 2 prints nothing.
Acceptance criteria (owner, real device):
  - Small Android phone, dark mode: each configuration screen's FAB floats and its last row is reachable.
Out of scope: configuration features.
Risk / rollback: visual. Revert.
Size: M
Fixes: BUG-075, BUG-087, BUG-074 (dropzones table)

### P5.7 — Fix the weather, wind and jump-run screens
Status: owner-check (small Android phone: edit temperature, winds and jump run with the keyboard open)
Repo: client
Depends on: P5.6
Branch: modernise/p5-7-weather-layout
Goal: Weather forms fit 360 dp, handle the keyboard, and grow inputs on Android.
Context: RC1/RC4/RC8/RC9. `components/forms/weather_conditions/WeatherConditionForm.tsx:158-166` (no Android branch),
`behavior="height"` KeyboardAvoidingView, jump-run text at 50–60 pt, fixed widths in wind/jump-run screens.
Steps:
  1. Replace the `Platform.select` with a shared style (`flexGrow: 1`) and a `default` branch.
  2. Form in `FormColumn`; remove `KeyboardAvoidingView`; large numerals use `variant="displaySmall"` with
     `adjustsFontSizeToFit` and `numberOfLines={1}`.
  3. Web smoke: `checkLayout` on the weather, wind and jump-run routes.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - Small Android phone: edit temperature, winds and jump run with the keyboard open.
Out of scope: weather backend (P6.19).
Risk / rollback: visual. Revert.
Size: M
Fixes: BUG-078, BUG-070 (weather), BUG-073 (weather)

### P5.8 — Support large font scales
Status: owner-check (Android at font scale 2.0 and iOS at the largest accessibility text size: board, load, profile, login are readable without clipped text in rows)
Repo: client
Depends on: P5.7
Branch: modernise/p5-8-font-scale
Goal: The app is usable at Android font scale 2.0 and iOS largest accessibility size.
Context: RC8. Fixed-height rows (`components/slots_table/UserRow.tsx:57,208` 46 px), headers (56 px), 60 px inputs,
aircraft rows, 50–72 pt titles.
Steps:
  1. `grep -rnE "height: (4[0-9]|5[0-9]|6[0-9])\b" app/components app/screens` and convert row/header/input heights to
     `minHeight` with vertical padding; remove `numberOfLines={1}` on names where it truncates essential data, or add
     `ellipsizeMode="tail"` plus an accessibility label with the full text.
  2. Set `maxFontSizeMultiplier={1.6}` on tab bar labels and FAB labels only (navigation chrome).
  3. Web smoke: run the board and a load with every font size doubled (react-native-web writes px, so `html { font-size: 200% }` changes nothing; the script scales each element's computed font size) and check `checkLayout`.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test (with the 200% run) pass.
Acceptance criteria (owner, real device):
  - Android at font scale 2.0 and iOS at the largest accessibility text size: board, load, profile, login are readable
    without clipped text in rows.
Out of scope: redesign.
Risk / rollback: visual. Revert.
Size: M
Fixes: BUG-077

### P5.9 — Add a lint guard against the layout root causes
Status: done
Repo: client
Depends on: P5.8
Branch: modernise/p5-9-layout-lint
Goal: ESLint prevents reintroducing RC2–RC4 patterns.
Context: Flat ESLint config from P3.20.
Steps:
  1. In `eslint.config.js` add for `app/**`:
     `no-restricted-imports` → `react-native` named imports `KeyboardAvoidingView` and `SafeAreaView` (message: use
     `FormColumn` / `ScreenContainer`); `no-restricted-syntax` → `CallExpression[callee.object.name='Dimensions'][callee.property.name='get']`.
     Exclude `app/components/layout/**`.
  2. Fix any remaining hits.
Acceptance criteria (cloud VM):
  - Client checks pass; adding `import { KeyboardAvoidingView } from 'react-native'` to any screen makes `yarn check:linting` fail (show this in the PR, then remove it).
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: lint only. Revert.
Size: S
Fixes: none

### P5.10 — Verify Phase 5
Status: owner-check (the "Layout" section of client:docs/SMOKE_TEST.md on a small Android phone, a large Android phone, an iPhone and an iPad, each at default and maximum font size, dark mode on one; merge the Phase 0–5 stacks and confirm CI on `staging`)
Repo: both
Depends on: P5.1, P5.2, P5.3, P5.4, P5.5, P5.6, P5.7, P5.8, P5.9
Branch: modernise/p5-10-verify
Goal: Layout fixes are proven on web and real devices.
Context: Phase gate.
Steps:
  1. Run client checks, web export and web smoke test (all layout checks). Save 360×640 and 1280×800 screenshots of
     login, board, load, profile, a wizard step and a configuration screen in the PR.
  2. Write `backend:docs/verification/phase-5.md`; mark BUG-070…BUG-078 as fixed or list what remains.
Acceptance criteria (cloud VM):
  - All commands exit 0; CI green on `staging`.
Acceptance criteria (owner, real device):
  - Run the "Layout" section of `client:docs/SMOKE_TEST.md` on a small Android phone (360×640 dp), a large Android phone,
    an iPhone and an iPad, each at default and maximum font size, with dark mode on one device.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 6 — Security and correctness fixes

Goal: every remaining confirmed or likely bug in BUGS.md is fixed with a regression spec. Order: request isolation and
tenant isolation first, then manifesting and payments, then data constraints and background work, then client UX.

Rules for every Phase 6 task:

- First write a failing spec that reproduces each bug in the task's `Fixes:` line (request spec through
  `OpenManifestSchema.execute` / `post "/graphql"` for API bugs, model/interaction spec otherwise). Commit it with the
  fix. Phase 1 characterisation specs that asserted buggy behaviour are updated in the same PR, with a one-line note in
  the PR body per changed expectation.
- Authorization helper used from P6.2 on: `Support::Authorization` (added in P6.2) with
  `authorize_dropzone!(dropzone, permission = nil)` and `authorize_record!(record, permission)` that resolve the
  dropzone from the record (`record.dropzone` / `record.load.dropzone` / `record.ticket_type.dropzone`), require a
  **kept existing** membership of the current user, and raise `GraphQL::ExecutionError` with code `FORBIDDEN`.
- Data migrations: reversible; clean or merge existing data before adding a constraint; print counts of changed rows.
- Mark each fixed bug in BUGS.md as `FIXED in P6.n:` (Executor instructions, status tracking).

### P6.1 — Make the access context per request
Status: done
Repo: backend
Depends on: P5.10
Branch: modernise/p6-1-request-access-context
Goal: Every GraphQL request and cable message gets its own access context; concurrent requests cannot see another
user's identity or dropzone membership.
Context: BUG-001. `app/graphql/access_context/current_user.rb` includes `Singleton`; `self.for(user)` mutates the
shared instance; `@dropzone_user` is memoised forever. Built in `app/controllers/graphql_controller.rb#context` and
`app/channels/graphql_channel.rb`; dropzone set in `app/graphql/support/dropzone_context.rb` (`at_dropzone`).
Steps:
  1. Remove `include Singleton`; `self.for(user)` returns `new(user)`; `initialize(user)` sets `@user`.
     `at_dropzone(dropzone)` sets `@dropzone` and resets `@dropzone_user = nil` when the dropzone changes.
  2. Update the controller and channel to use `AccessContext::CurrentUser.for(user)` (now a new instance) — no other
     call sites exist (`grep -rn "CurrentUser" app lib spec`).
  3. Spec `spec/graphql/access_context/current_user_spec.rb`: two contexts for different users are distinct objects;
     `at_dropzone(b)` after `at_dropzone(a)` returns B's membership. Request spec: user A at dropzone A followed by
     user B at dropzone B in the same process returns each user's own `currentUser` id
     (`query { dropzone(id:) { currentUser { id } } }`).
  4. Thread spec: 2 threads × 50 iterations, each alternately executing the query above as user A/B against the
     schema; assert no response contains the other user's id.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `bundle exec rubocop` clean; `grep -rn "Singleton" app/graphql` prints nothing.
Acceptance criteria (owner, real device):
  - none
Out of scope: authorization rules (P6.2+).
Risk / rollback: small change, high impact. Revert.
Size: S
Fixes: BUG-001

### P6.2 — Add tenant checks to dropzone, load and setup queries
Status: done
Repo: backend
Depends on: P6.1
Branch: modernise/p6-2-query-authz-1
Goal: Query resolvers only return data for dropzones the caller belongs to (or public data explicitly marked public).
Context: BUG-002 (resolvers `dropzone/load.rb:12`, `loads.rb:11-13`, `dropzone/aircrafts.rb`, `ticket_types.rb`,
`ticket_addons.rb`, `master_log.rb`, `available_rigs.rb:6-23`, `meta/jump_types.rb:6-7`), BUG-003 (`dropzone/activity.rb:27-35`
returns all dropzones' events), BUG-004 (`resolvers/image.rb` serves any blob; the client never calls `image`). The
P1.7 tenant-isolation specs currently assert the leak (marked `pending "BUG-002"` etc.).
Steps:
  1. Add `app/graphql/support/authorization.rb` (`Support::Authorization`, see phase rules) and include it in
     `Resolvers::Base` and `Mutations::Base`. Membership lookup: `DropzoneUser.kept.find_by(dropzone:, user:)` — never
     `DropzoneUser.for` (it creates memberships, BUG-005, P6.4).
  2. Apply it to the resolvers listed above: `load(id:)` → `authorize_record!(load)`; `loads(dropzone:)`,
     `aircrafts`, `ticketTypes`, `ticketAddons`, `masterLog`, `availableRigs` → `authorize_dropzone!(dropzone)`;
     `masterLog` additionally requires `readMasterLog` (permission names from `db/seeds/permissions`, check the exact
     name with `Permission.pluck(:name)`).
  3. `activity`: require a `dropzone` argument for non-moderators; check `viewSystemActivity` for moderators without a
     dropzone, `readActivity` (or the closest existing permission name) otherwise.
  4. Remove the `image` query field and resolver (BUG-004); the schema dump (P1.8) and contract check (P1.9) must stay
     green because the client does not use it.
  5. `Resolvers::Dropzones`: apply the `state` argument (`context[:access_context].dropzones.where(state: state)` when
     given) (BUG-090); un-pend its example in `spec/requests/client_operations/dropzones_spec.rb`.
  6. `Support::DropzoneContext`: return nil from the `prepare` lambda when `ctx[:access_context]` is nil so anonymous
     callers get `AUTHENTICATION_ERROR` instead of `NoMethodError` (BUG-095); un-pend its example in
     `spec/requests/client_operations/setup_spec.rb`.
  7. Un-pend the P1.7 specs for these resolvers; they must now pass.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `bundle exec rails graphql:schema:dump` diff only removes `image`;
    client `check:graphql` (P1.9) passes against the new schema.
Acceptance criteria (owner, real device):
  - none
Out of scope: user/member queries (P6.3).
Risk / rollback: over-restricting breaks screens; P1 client-operation specs catch it. Revert.
Size: L
Fixes: BUG-002 (dropzone/load/setup resolvers), BUG-003, BUG-004, BUG-090, BUG-095

### P6.3 — Add tenant checks to user queries and protect personal data
Status: done
Repo: backend
Depends on: P6.2
Branch: modernise/p6-3-query-authz-2
Goal: Member and user data is only visible to the member themselves and to staff of a shared dropzone with `readUser`;
`pushToken` is never exposed to others.
Context: BUG-002 (`resolvers/users/dropzone_user.rb:11-13`, `dropzone_users.rb:7-15`), BUG-013
(`types/users/user.rb:33-38` exposes `pushToken`, `email`, `phone`). Client reads its own `user.pushToken` in
`PushNotificationProvider` (via the current-user fragment).
Steps:
  1. `dropzoneUser(id:)` / `dropzoneUsers(dropzone:)` → `authorize_dropzone!` + `readUser` unless the record is the
     caller's own membership.
  2. `Types::Users::User`: field-level `authorized?` for `email`, `phone`, `pushToken`: `pushToken` only for
     `object == current_user`; `email`/`phone` for self or a user who has `readUser` at a dropzone where both are
     members (one query: `DropzoneUser.kept.where(user: object).where(dropzone_id: caller_staff_dropzone_ids)`).
     Return `nil` (not an error) when unauthorised so lists still render.
  3. `Resolvers::Users::DropzoneUsers` `permissions` filter: find the roles that grant the permission through
     `UserRolePermission` first, then members by `user_role_id` (BUG-093); un-pend its example in
     `spec/requests/client_operations/users_spec.rb`.
  4. Specs per field and per resolver; un-pend the P1.7 member specs.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; client web smoke test against this branch passes (profile and user list).
Acceptance criteria (owner, real device):
  - none
Out of scope: subscriptions (P6.9).
Risk / rollback: as P6.2.
Size: M
Fixes: BUG-002 (member resolvers), BUG-013, BUG-093

### P6.4 — Stop creating memberships during permission checks; add joinDropzone
Status: done
Repo: both
Depends on: P6.3
Branch: modernise/p6-4-explicit-membership
Goal: Permission checks never write; users join a dropzone explicitly with a `joinDropzone` mutation that the client
calls when a user selects a dropzone they are not a member of.
Context: BUG-005. `User#can?` → `User#at` → `DropzoneUser.for` (`find_or_initialize_by` + `save`) in
`backend:app/models/user.rb:80-86`, `dropzone_user.rb:150-155`; `Types::DropzoneType#current_user`
(`types/dropzone_type.rb:88-90`) also creates. Client: `client:app/screens/authenticated/limbo/dropzone_select/*`
selects a dropzone and then reads `dropzone { currentUser }`, relying on auto-join.
Steps:
  1. backend: `DropzoneUser.for` becomes `find_by` only (rename to `DropzoneUser.membership(dropzone, user)`);
     `User#can?` returns `false` without a membership. `DropzoneType#current_user` returns `nil` when not a member
     (make the field nullable; the schema dump changes).
  2. backend: add `Mutations::Users::JoinDropzone` (`joinDropzone(input: { dropzone: ID! }): JoinDropzonePayload { dropzoneUser, errors, fieldErrors }`)
     using an interaction `Users::JoinDropzone`: the dropzone must be `public` (state machine `public` state) or the
     caller a moderator; creates the membership with the dropzone's default role (`dropzone.user_roles.find_by(name: "fun_jumper")`
     — use whatever `DropzoneUser` currently assigns in `before_create`/defaults); idempotent.
  3. client: add `app/api/mutations/JoinDropzone.gql`, run codegen; in dropzone selection, when the selected dropzone's
     `currentUser` is null, call `joinDropzone` then refetch. Handle `currentUser: null` everywhere it is read
     (`yarn check:types` shows them).
  4. `Setup::Dropzones::UpdateVisibility`: decide moderator rights from `access_context.user` instead of the membership
     (BUG-089: today it raises `NoMethodError` for a moderator who is not a member, which this task makes reachable);
     un-pend that example in `spec/requests/client_operations/dropzones_spec.rb`.
  5. Specs: `can?` on a non-member creates no rows (`expect { … }.not_to change(DropzoneUser, :count)`); join is
     idempotent; joining a private dropzone fails. Client test: selecting an unjoined dropzone calls `joinDropzone`.
Acceptance criteria (cloud VM):
  - Backend: `bundle exec rspec` green; schema dump updated. Client: client checks, `check:graphql`, web export and web
    smoke test (new user signs up, selects a dropzone, reaches the board) pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: dropzone invitations.
Risk / rollback: changes onboarding flow. Merge backend first; client PR must merge before any deploy. Revert both.
Size: L
Fixes: BUG-005, BUG-089

### P6.5 — Enforce manifest permissions
Status: done
Repo: backend
Depends on: P6.4
Branch: modernise/p6-5-manifest-authz
Goal: Manifesting self vs others, moving slots and group manifesting check the right permissions and tenants.
Context: BUG-006 (`interactions/manifest/create_slot.rb:23,133-160` private `authorize` never called), BUG-007
(`move_slot.rb:12-19,119-124`, no permission, target load may be another dropzone's), BUG-062
(`mutations/manifest/create_slots.rb:25-71`: compares dropzone-user ids to user id, undefined `required_permission`).
Permissions: `createSlot`, `createUserSlot`, `createDoubleSlot`, `createUserSlotWithSelf`, `updateSlot`, `updateUserSlot`
(names from `Permission` seeds; verify with `Permission.pluck(:name)`).
Steps:
  1. `CreateSlot`: call `authorize` as a step; self-manifest requires `createSlot`, manifesting another member requires
     `createUserSlot`; the load and the member must belong to the same dropzone as the context.
  2. `MoveSlot`: require `updateUserSlot` (others) or `updateSlot` (own slot); source and target load must share the
     dropzone; target load must be open and have capacity for the slot (BUG-092: validations run only on create today;
     un-pend "keeps the slot when the target load is full" in `manifest_spec.rb`).
  3. `CreateSlots#authorized?`: rewrite using membership ids: all members == caller's membership → `createSlot`;
     includes others → `createUserSlot`; remove dead branches.
  4. Specs for each permission combination (student self, student other → forbidden; manifest staff other → ok;
     cross-dropzone move → forbidden). Un-pend matching P1.7 specs.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green.
Acceptance criteria (owner, real device):
  - none
Out of scope: crash fixes in the same interactions (P6.11).
Risk / rollback: staff with odd role setups lose abilities; seeds define default roles. Revert.
Size: M
Fixes: BUG-006, BUG-007, BUG-062, BUG-092

### P6.6 — Restrict createOrder to same-dropzone staff purchases
Status: done
Repo: backend
Depends on: P6.5
Branch: modernise/p6-6-create-order
Goal: `createOrder` can no longer mint credits: seller and buyer must belong to the context dropzone, peer-to-peer
orders between two members are rejected until D8 is decided, and staff credit adjustments keep working.
Context: BUG-008 (`mutations/payments/create_order.rb:22-42`, `types/input/order_input.rb:7-20` resolves members by
unsigned GlobalID across dropzones; `transactions/purchase.rb:70-73` no balance check). Client uses `createOrder` for
"buy credits"/"transfer" in `app/forms/credits` (check which buyer/seller combinations it sends: dropzone ↔ member).
Steps:
  1. Resolve buyer/seller GlobalIDs with `GlobalID::Locator.locate_signed` is not possible (client sends unsigned) —
     instead locate and then require: each party is either the context dropzone or a kept membership of it.
  2. Member ↔ dropzone orders require `createUserTransaction` (or the existing staff credit permission) unless the buyer
     is the caller's own membership buying from the dropzone with sufficient credits.
  3. Member ↔ member orders return error "Transfers between members are disabled" (D8 may re-enable in P6.7).
  4. Purchase interaction: buyer balance check (`credits >= amount` unless `allow_negative_credits`).
  5. Specs: cross-dropzone seller rejected; member→member rejected; staff top-up works; own purchase with insufficient
     credits rejected.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; client P1 credits tests pass against the branch schema.
Acceptance criteria (owner, real device):
  - none
Out of scope: money types (P6.23); concurrency (P6.10).
Risk / rollback: if the owner wants peer transfers, P6.7 re-enables them. Revert.
Size: M
Fixes: BUG-008 (minting, cross-tenant)

### P6.7 — Implement the peer-to-peer credit decision
Status: blocked (awaiting decision D8)
Repo: both
Depends on: P6.6
Branch: modernise/p6-7-peer-credits
Goal: Peer-to-peer transfers follow decision D8.
Context: BUG-008. D8 (a): remove the member↔member UI in `client:app/forms/credits` and keep the P6.6 server rejection.
D8 (b): allow member→member within the same dropzone, limited to the sender's balance, with an `Order` + two
`Transaction`s and a notification to the receiver.
Steps:
  1. (a) client: remove member↔member options from the credits form; backend: keep rejection, add a spec name
     referencing D8. (b) backend: implement in `Transactions::Purchase` with wallet locks from P6.10, specs for
     balance, same dropzone, notification; client: form shows sender balance.
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green; client checks, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: money types.
Risk / rollback: revert.
Size: M
Fixes: BUG-008 (peer-to-peer policy)

### P6.8 — Fix IDOR, tenant moves and broken setup mutations
Status: done
Repo: backend
Depends on: P6.6
Branch: modernise/p6-8-setup-mutations
Goal: Setup mutations authorise against the record's own dropzone, cannot move records between tenants, and no longer crash.
Context: BUG-009 (`update_form_template.rb`, `update_rig_inspection.rb`, `create_extra.rb(id:)`,
`create_weather_condition.rb:72-73` authorise a client-supplied dropzone but load by id), BUG-010 (`update_ticket_type.rb:15`,
`update_plane.rb:15`, `update_rig.rb:24`, `update_extra.rb:14` pass `dropzoneId`/`userId` to `update!`), BUG-039
(`delete_ticket_type.rb:48-50` uses `Dropzone.find(<ticket type id>)` and `context[:current_user]`; same in
`delete_dropzone.rb:50-52`, `delete_rig.rb:49-56`), BUG-061 (`update_ticket_type.rb:16-28`, `update_extra.rb:17-29`
`destroy_all` unscoped).
Steps:
  1. Each update/delete mutation: load the record, then `authorize_record!(record, <permission>)` using the record's
     dropzone; ignore any client `dropzoneId` for updates.
  2. Strip `dropzone_id`, `user_id`, `owner_id` from attributes passed to `update!` (`input.to_h.except(...)`).
  3. Replace `context[:current_user]` with `context[:current_resource]`/access context everywhere
     (`grep -rn "context\[:current_user\]" app` must print nothing).
  4. Extras links: scope the cleanup to the record (`record.ticket_type_extras.where.not(extra_id: ids).destroy_all`); the
     association assignment in `update!(extra_ids:)` already creates the links, so delete the dead `Array#-` block.
  5. Specs per mutation: other tenant's record → forbidden; `dropzoneId` change ignored; archive ticket type works;
     updating ticket type A leaves ticket type B's extras intact.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; grep in step 3 prints nothing.
Acceptance criteria (owner, real device):
  - none
Out of scope: uploads (P6.21).
Risk / rollback: revert.
Size: L
Fixes: BUG-009, BUG-010, BUG-039, BUG-061

### P6.9 — Authenticate the cable connection and authorise subscriptions
Status: owner-check (on a phone logged in with Apple, the manifest board updates live when a load is created on the web; client half in the P6.9 client PR)
Repo: both
Depends on: P6.8
Branch: modernise/p6-9-cable-auth
Goal: ActionCable connections are authenticated with the devise token headers; subscriptions check membership of the
subscribed dropzone/load/user.
Context: BUG-011 (`subscriptions/manifest/load_updated.rb`, `load_created.rb`, `users/user_updated.rb` only check
"logged in"; `channels/application_cable/connection.rb` no auth), BUG-060 (`graphql_channel.rb:42-50` looks users up by
`email: uid`, failing for Apple users), BUG-053 (`production.rb` `ws://`, `puts` in the channel). Client builds the
cable URL in `client:app/api/client/links/websockets.ts` and passes credentials in the subscription params.
Steps:
  1. backend `ApplicationCable::Connection#connect`: read `access-token`, `client`, `uid` from query params (browsers
     cannot set WebSocket headers); `user = User.find_by(uid:, provider:)` (provider from params, default `email`);
     `reject_unauthorized_connection` unless `user&.valid_token?(token, client)`; `identified_by :current_user`.
  2. `GraphqlChannel`: build the access context from `current_user`; drop the email lookup; `Rails.logger` instead of `puts`.
  3. Each subscription `authorized?`: membership of the dropzone (`loadCreated(dropzone:)`), of the load's dropzone
     (`loadUpdated(load:)`), or self/`readUser` (`userUpdated(dropzoneUser:)`).
  4. `production.rb`: `config.action_cable.url = "wss://#{ENV.fetch('HOST')}/subscriptions"` (or remove the setting if
     unused; the client builds its own URL).
  5. client: `websockets.ts` appends `access-token`, `client`, `uid` (URL-encoded) to the cable URL from `useSession`;
     reconnect on credential change.
  6. Specs: `spec/channels/connection_spec.rb` (valid/invalid token, Apple-style uid); subscription authorisation
     specs. Client test for the URL builder.
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green; client checks pass; web smoke test sees a `loadUpdated` event (create a load in
    one browser context, see it appear in another without reload).
Acceptance criteria (owner, real device):
  - On a phone logged in with Apple: the manifest board updates live when a load is created on the web.
Out of scope: Redis adapter changes.
Risk / rollback: live updates stop if token handling is wrong; the board still works with pull-to-refresh. Revert both.
Size: L
Fixes: BUG-011, BUG-060, BUG-053

### P6.10 — Count slots correctly and lock capacity and credits
Status: done
Repo: backend
Depends on: P6.9
Branch: modernise/p6-10-counters-locking
Goal: Slot counters are correct, existing counts are repaired, and concurrent manifests cannot overbook a load, double-
book a person, or overdraw credits.
Context: BUG-019 (`models/slot.rb:48-55` counter_culture without `column_name:`), BUG-020 (`slot.rb:121-123`,
`create_multiple_slots.rb:47-54` capacity read-then-insert), BUG-021 (no unique `slots(load_id, dropzone_user_id)`),
BUG-023 (`slot.rb:143-150`, `purchase.rb:70-73` credit check without lock). Pass-1 dev DB showed `slots_count=4` for 2 slots.
Steps:
  0. Remove the `counter_culture` pin from `Gemfile` (P2.2 pinned 3.3.0, see the comment there) and
     `bundle update counter_culture` (3.14.0) in the same commit as step 1; the tandem group-manifest example in
     `spec/graphql/mutations/manifest/create_slots_spec.rb` ("successfully with tandem") fails on 3.14.0 until the
     counters are fixed.
  1. `counter_culture :load` (plain `slots_count`) and a second
     `counter_culture :load, column_name: proc { |s| s.ready? ? "ready_slots_count" : nil }, column_names: { Slot.ready => :ready_slots_count }`.
  2. Data migration `FixLoadSlotCounters`: `Slot.counter_culture_fix_counts` (prints fixes).
  3. Migration: delete duplicate `(load_id, dropzone_user_id)` slots keeping the oldest (print count), then
     `add_index :slots, [:load_id, :dropzone_user_id], unique: true, where: "dropzone_user_id IS NOT NULL"`.
     Rescue `ActiveRecord::RecordNotUnique` in create-slot interactions → error "Already manifested on this load".
  4. In `CreateSlot`, `CreateMultipleSlots`, `MoveSlot`: wrap in a transaction, `load.lock!` before the capacity check,
     and lock the paying `dropzone_user` row (`lock!`) before the credit check; lock order: load, then memberships by id.
  5. Specs: counters after create/delete/ready; concurrent spec using two threads with
     `ActiveRecord::Base.connection_pool.with_connection` manifesting the last seat → exactly one succeeds; same for
     credits (balance never negative); duplicate person → one slot.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green (concurrency specs use `self.use_transactional_tests = false` and clean up);
    `bin/rails db:migrate` and `db:rollback STEP=2` on a dev DB seeded by P0.5.
Acceptance criteria (owner, real device):
  - none
Out of scope: optimistic locking for edits (P6.22).
Risk / rollback: the unique index migration deletes duplicates; production rehearsal in P8.8. Rollback drops the index;
deleted duplicates are logged (ids) in the migration output.
Size: L
Fixes: BUG-019, BUG-020, BUG-021, BUG-023

### P6.11 — Fix manifest interaction crashes
Status: done
Repo: backend
Depends on: P6.10
Branch: modernise/p6-11-manifest-crashes
Goal: Max-slot changes, finalising, moving, deleting and updating slots work for all slot kinds.
Context: BUG-025 (`update_load.rb:92-95` inverted), BUG-029 (`update_slot.rb:44-52` `slot.user_id`), BUG-030
(`finalize_load.rb:34-41` nil order for passenger slots; auto-finalize), BUG-031 (`move_slot.rb:58` `group_numner`,
nil credits, undefined `load`), BUG-032 (`delete_slot.rb:42-44,54-64` nil order, undefined `load`), BUG-034
(`slot.rb:129,139,147,156` `created_by.can?` on nil).
Steps:
  1. `check_max_slots`: error when `max_slots < load.slots.count`.
  2. `UpdateSlot#authorized?`: use `slot.dropzone_user.user_id`; keep the mutation (it is in the schema) with specs.
  3. Finalize: skip receipts for slots without an order; auto-finalize uses the same interaction.
  4. Move: fix typo, `credits.to_f`, use `slot.load` in messages. Delete: guard nil order (no refund), fix messages.
  5. Slot validations: `created_by&.can?(...)`.
  6. `Sources::Model#fetch` returns `ids.map { |id| record_cache[id] }` so nil and missing keys keep their position
     (BUG-091: with a nil `load_master`, `slots { dropzoneUser }` resolves to null); un-pend its example in
     `spec/requests/client_operations/manifest_spec.rb`.
  7. Specs for each bug; the pass-1 failing spec files for finalize and available rigs pass without `pending`.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `grep -rn "pending \"BUG-0\(25\|29\|30\|31\|32\|34\)" spec` prints nothing.
Acceptance criteria (owner, real device):
  - none
Out of scope: load state rules (P6.12).
Risk / rollback: revert.
Size: M
Fixes: BUG-025, BUG-029, BUG-030, BUG-031, BUG-032, BUG-034, BUG-091

### P6.12 — Enforce load state transitions and fix jump counts
Status: done
Repo: both
Depends on: P6.11
Branch: modernise/p6-12-load-states
Goal: Load state changes go through the state machine; landing updates jump counters once; broadcasts happen once; the
client shows errors from landing/cancelling.
Context: BUG-035 (`update_load.rb:19,107-118` sets `state` from input; `concerns/state_machines/load_state.rb:8-56`),
BUG-026 (`load.rb:45-47,61-73,146-176` `state_changed?` false in `after_save`), BUG-036 (`loadCreated` ×3, `loadUpdated` ×2),
BUG-082 (`client:app/api/crud/useLoad.tsx:197-210`, `load/ActionButton.tsx` ignore mutation results).
Steps:
  1. backend: `updateLoad` accepts `state` only as an event: map requested state to event (`boarding_call` →
     `call`, `in_flight` → `dispatch`, `landed` → `land`, `cancelled` → `cancel`), call `fire_state_event`; invalid
     transition → error. `land` requires finalised orders or runs `FinalizeLoad` first.
  2. Jump counters: move `update_counters!` to an `after_transition to: :landed` callback (runs once).
  3. Broadcast `loadCreated` once in `after_create_commit`, `loadUpdated` once in `after_update_commit`; remove the
     interaction-level and `after_save` triggers.
  4. client: `ActionButton` awaits the mutation, shows `errors`/`fieldErrors` in a snackbar, and catches rejections.
  5. Specs: state transition matrix; counters increment once on land; broadcast count with
     `expect { … }.to have_broadcasted_to(...).exactly(:once)`. Client test: landing error shows a snackbar.
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green; client checks, web export and smoke test (boarding call → land) pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: auto-finalize scheduling (P6.17).
Risk / rollback: staff used free-form state changes; the event mapping keeps the client UI working. Revert both.
Size: L
Fixes: BUG-035, BUG-026, BUG-036, BUG-082

### P6.13 — Fix group manifesting and store add-ons
Status: done
Repo: backend
Depends on: P6.12
Branch: modernise/p6-13-groups-extras
Goal: A group gets one group number; ticket add-ons are stored and charged.
Context: BUG-027 (`create_multiple_slots.rb:31-45` per-member group number), BUG-028 (`create_slot.rb:18-20,74-89`,
`create_multiple_slots.rb:60-65`, `slot.rb:82-86`: no `SlotExtra` rows; input key `extras` vs `extra_ids`).
Steps:
  1. Compute `group_number ||= load.next_group_number` once before the loop.
  2. Accept `extras` (IDs) in both paths; validate they belong to the ticket type's allowed extras; create `SlotExtra`
     rows; include extra costs in the order amount (`Slot#cost`).
  3. Specs: group of 3 → one number; slot with 2 extras → 2 `SlotExtra`, order amount = ticket + extras; refund includes extras.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; client P1 manifest tests pass against the branch schema.
Acceptance criteria (owner, real device):
  - none
Out of scope: money types.
Risk / rollback: revert.
Size: M
Fixes: BUG-027, BUG-028

### P6.14 — Apply the eligibility-default decision
Status: blocked (awaiting decision D3)
Repo: backend
Depends on: P6.13
Branch: modernise/p6-14-eligibility-defaults
Goal: Dropzone eligibility settings default and backfill as decided in D3.
Context: BUG-033 (`models/concerns/dropzones/configuration.rb:13-50` defaults all `require_*` to true and applies them
to existing dropzones; `slot.rb:125-131`).
Steps:
  1. Change defaults per D3 (recommendation (b): `require_credits` = `is_credit_system_enabled`, all others false).
  2. Data migration writing explicit settings for every existing dropzone per D3; print the count.
  3. Specs: new dropzone defaults; existing dropzone after migration; manifest succeeds for a member without
     rig inspection when the setting is off.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; migration up/down on the P0.5 dev seed.
Acceptance criteria (owner, real device):
  - none
Out of scope: settings UI.
Risk / rollback: rollback restores the previous settings from a JSON column snapshot written by the migration.
Size: S
Fixes: BUG-033

### P6.15 — Fix user mutations
Status: done
Repo: backend
Depends on: P6.13
Branch: modernise/p6-15-user-mutations
Goal: Staff can edit members, users can edit profiles, Apple login errors are clear, joining a federation and deleting
users no longer crash.
Context: BUG-037 (`update_dropzone_user.rb:13-25` undefined `model` after save), BUG-038 (`interactions/users/update_user.rb:22-35,58-80`
`can?` arity, assigns `user_role_id`/`expires_at` to `User`), BUG-054 (`login/apple.rb:11-19,29` wrong error class),
BUG-055 (`join_federation.rb:17-20` nil membership), BUG-056 (`delete_user.rb:22-28` undefined `invalid`).
Steps:
  1. Fix each as described in BUGS.md "Suggested fix"; `UpdateUser` only touches `User` attributes; role/expiry go
     through `updateDropzoneUser` (client already does this — verify in `client:app/api/mutations/UpdateUser.gql`).
  2. `Users::UpdateUser`: return a `fieldErrors` entry for an email that already belongs to another user instead of raising
     `RecordNotUnique` (BUG-094).
  3. `joinFederation` accepts optional `dropzone` (ID) and falls back to the first kept membership or none.
  4. Specs per mutation including staff editing another user's profile with `updateUser` permission.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; schema dump diff only adds the optional `dropzone` argument.
Acceptance criteria (owner, real device):
  - none
Out of scope: sign-up takeover (P6.24).
Risk / rollback: revert.
Size: M
Fixes: BUG-037, BUG-038, BUG-054, BUG-055, BUG-056, BUG-094

### P6.16 — Add database constraints, loads.dropzone_id and safe load numbers
Status: done
Repo: backend
Depends on: P6.15
Branch: modernise/p6-16-constraints
Goal: Uniqueness and foreign keys the code relies on are enforced in PostgreSQL; loads carry their dropzone directly;
load numbers are unique per dropzone and day.
Context: BUG-050 (missing unique `dropzone_users(user_id, dropzone_id)`, `orders(dropzone_id, order_number)`, missing
`loads.dropzone_id`, indexes on `events(dropzone_id, created_at)`, `notifications(received_by_id, is_seen)`), BUG-022
(`load.rb:52,140-144` `today.count + 1`). GENERALISATION.md step 2 (`loads.dropzone_id`). Loads currently reach their
dropzone via `plane`.
Steps:
  1. Migration A: merge duplicate memberships (keep the oldest; move slots, orders, transactions, permissions, rigs
     inspections to it; discard the rest; print counts), then unique index `dropzone_users(user_id, dropzone_id)`.
  2. Migration B: add `loads.dropzone_id` (FK, null: false after backfill from `planes.dropzone_id`), `loads.load_date`
     (date, backfilled from `created_at` in the dropzone's time zone), unique index `(dropzone_id, load_date, load_number)`
     after renumbering duplicates per dropzone/day by `created_at` (print changes). `Load belongs_to :dropzone`; set it in
     `CreateLoad`.
  3. Load number: in `CreateLoad`, `dropzone.lock!` then `max(load_number) + 1` over loads of that dropzone and
     `load_date`, including discarded loads.
  4. Migration C: unique `orders(dropzone_id, order_number)` after renumbering duplicates; indexes on
     `events(dropzone_id, created_at)` and `notifications(received_by_id, is_seen)`.
  5. Specs: archive-then-create keeps numbers unique; constraint violations raise; membership merge migration spec
     with fixtures.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `db:migrate`, `db:rollback STEP=3`, `db:migrate` on the P0.5 dev seed;
    `db/schema.rb` committed.
Acceptance criteria (owner, real device):
  - none
Out of scope: money columns (P6.23).
Risk / rollback: data-changing migrations; rehearse on production data in P8.8. Rollback removes constraints; merges
are logged but not reversed.
Size: L
Fixes: BUG-050, BUG-022

### P6.17 — Move jobs to Solid Queue and schedule recurring work
Status: done
Repo: backend
Depends on: P6.16
Branch: modernise/p6-17-solid-queue
Goal: Background jobs run on Solid Queue with retries; master logs and auto-finalize run on a schedule; master-log
generation works.
Context: BUG-052 (`:async` adapter, errors swallowed), BUG-044 (`interactions/master_log/generate.rb:14-21` missing
`date`; `master_log.rb:20,36-56`; rake tasks in `lib/tasks/dropzone.rake` never scheduled; `dropzone_type.rb:103-108`
builds logs with a `created_at` range). Rails 8.1 from P2.7; `solid_queue` (latest 1.x compatible with Rails 8.1;
check `gem list -r solid_queue`).
Steps:
  1. `bundle add solid_queue`; `bin/rails solid_queue:install`; use the single-database setup
     (`config/queue.yml`, `db/queue_schema.rb` loaded into the primary DB via a migration as documented in the
     solid_queue README "Single database configuration"). `config.active_job.queue_adapter = :solid_queue` in all
     environments except test (`:test`).
  2. `config/recurring.yml`: `master_logs` daily at 02:00 per dropzone time zone (job iterates dropzones and runs for
     dropzones whose local time is 02:00–02:59), `auto_finalize` every 15 minutes.
  3. Fix `MasterLog::Generate` (set `date`), `Dropzone#master_log(date:)` (query by `date` in the dropzone zone).
  4. Jobs: remove blanket `rescue`; use `retry_on Net::OpenTimeout, HTTParty::Error, wait: :polynomially_longer, attempts: 5`.
  5. `Procfile`/`bin/dev`: add `jobs: bin/jobs`. Puma plugin `plugin :solid_queue` when `SOLID_QUEUE_IN_PUMA=1`.
  6. Specs: generate master log for a date; recurring config loads (`SolidQueue::RecurringTask` from YAML);
     `NotifyJob` retries.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `bin/jobs` starts and processes a `NotifyJob` enqueued from `rails runner` (log line).
Acceptance criteria (owner, real device):
  - none
Out of scope: push delivery content (P6.18).
Risk / rollback: revert to `:async`.
Size: L
Fixes: BUG-052, BUG-044

### P6.18 — Fix notifications and push tokens
Status: owner-check (on a phone: request a rig inspection and receive the push; log out, then trigger a notification for that user and no push arrives on the device)
Repo: backend
Depends on: P6.17
Branch: modernise/p6-18-notifications
Goal: Rig inspection and credit notifications are created and delivered; invalid Expo tokens are cleaned; logout clears
the token server-side; gauges are correct.
Context: BUG-042 (`rig_inspection.rb:24-36` `type:` vs `notification_type`; `request_rig_inspection_job.rb` expects ids;
`dropzone_user.rb:208-216`; `session_type.rb:38-42`), BUG-043 (`transaction.rb:30,40-71` wrong statuses, undefined
`dropzone_user`), BUG-018 server part (`notification.rb:38-48`), BUG-051 (`dropzone.rb:108-110`). Client part of BUG-018
was done in P4.8 (sends `pushToken: null` on logout).
Steps:
  1. Fix attribute names and job arguments (pass ids, `find` in the job).
  2. `Transaction#notify!` based on `transaction_type` and the receiver; notify the member's user.
  3. `Notification#deliver`: send via Expo push API (`https://exp.host/--/api/v2/push/send`) in `NotifyJob`; on
     `DeviceNotRegistered` in the ticket response, set `users.push_token = nil`. Clear the same token from any other
     user when a user registers it (`User.where(push_token: token).where.not(id:).update_all(push_token: nil)`).
  4. Gauge uses `Dropzone.count`.
  5. Specs with WebMock: rig inspection request creates a notification and enqueues push; `DeviceNotRegistered`
     clears the token; token reuse clears the previous owner.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green.
Acceptance criteria (owner, real device):
  - On a phone: request a rig inspection and receive the push; log out, then trigger a notification for that user: no
    push arrives on the device.
Out of scope: notification UI.
Risk / rollback: revert.
Size: M
Fixes: BUG-042, BUG-043, BUG-018, BUG-051

### P6.19 — Fix weather and server-side time zones
Status: done
Repo: both
Depends on: P6.18
Branch: modernise/p6-19-weather-timezones
Goal: Weather reload works from the client, external weather calls run in a job with timeouts, distances are stored
precisely, and "today" means the dropzone's day everywhere on the server.
Context: BUG-040 (`reload_weather_condition.rb:9-14,49-50` needs `dropzoneId`; client `ReloadWeather.gql` sends `id`),
BUG-045 (`weather_condition.rb:20,70-118` synchronous HTTP to `markschulze.net` in a callback; `exit_spot_miles`,
`offset_miles` integer), BUG-046 (`dropzone.rb:98-102` UTC day), BUG-047 (`load.rb:52`, `slot.rb:138`,
`create_multiple_slots.rb:82` ambient zone).
Steps:
  1. backend: `reloadWeatherCondition(input: { id })` loads the weather condition and authorises its dropzone; keep
     `dropzoneId` optional for compatibility.
  2. backend: move the winds fetch into `FetchWindsJob` (HTTParty `timeout: 5`); the record is created without winds
     and the job fills them and broadcasts `loadUpdated`-style refresh (or the client refetches; keep it simple:
     client pull-to-refresh). Migration: `exit_spot_miles`, `offset_miles` → `decimal(6,2)`.
  3. backend: `Dropzone#today` = `Time.use_zone(time_zone) { Time.zone.today }`; `Load.today_at(dropzone)`; replace all
     `Load.today`/`DateTime.now.beginning_of_day` uses (`grep -rn "DateTime.now\|DateTime.current\|Date.today" app`).
     `weather_conditions.date` column (backfilled) keyed by the dropzone's local date.
  4. client: `ReloadWeather.gql` unchanged if step 1 keeps `id`; add a test that reload succeeds against the mock.
  5. Specs: Brisbane dropzone at 23:00 UTC (09:00 local next day) → today's loads/weather are the local day.
  6. BUG-098: `spec/rails_helper.rb` uses `config.around(:suite)`, which RSpec ignores; run the examples inside
     `Time.use_zone("Australia/Brisbane")` with `config.around(:each)` and fix whatever then fails.
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green; client checks and `check:graphql` pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: client time zone handling (P6.20).
Risk / rollback: revert both.
Size: L
Fixes: BUG-040, BUG-045, BUG-046, BUG-047, BUG-098

### P6.20 — Use the dropzone time zone in the client
Status: done
Repo: both
Depends on: P6.19
Branch: modernise/p6-20-client-timezone
Goal: The manifest board shows the dropzone's current day and updates past midnight; call times display in the
dropzone's zone.
Context: BUG-068 (`client:app/providers/manifest/provider.tsx:56` device date at mount; `load/ActionButton.tsx` "is
today" and call times use the device zone). Backend `Dropzone.timeZone` field exists (verify in the schema dump; add
`timeZone: String!` to `DropzoneType` if missing).
Steps:
  1. backend (if needed): expose `timeZone`.
  2. client: add `date-fns-tz` (latest 3.x) — or use `Intl.DateTimeFormat` with `timeZone` if the codebase uses `moment`
     (then `moment-timezone` latest); `useDropzoneToday()` returns the dropzone's date and re-evaluates every minute
     and on app foreground (`AppState`).
  3. Replace device-date uses listed in BUG-068.
  4. Tests with mocked system time (`jest.useFakeTimers().setSystemTime`) for a Brisbane dropzone and a UTC device.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; backend rspec green if changed.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: BUG-068

### P6.21 — Fix uploads
Status: owner-check (on a phone: set a dropzone banner and a packing card photo with the camera)
Repo: backend
Depends on: P6.20
Branch: modernise/p6-21-uploads
Goal: Dropzone banners and rig packing cards upload correctly; publication requests notify moderators.
Context: BUG-041 (`update_dropzone.rb:15-30` undefined `dropzone_user`/`image`, wrong notification recipient type;
`create_rig.rb:26-29`, `update_rig.rb:20-23`).
Steps:
  1. Banner: decode the base64 data URL the client sends into `ActiveStorage` (`dropzone.banner.attach(io:, filename:,
     content_type:)`), validate content type (`image/png`, `image/jpeg`, `image/webp`) and size (≤ 5 MB).
  2. Publication request: notify each moderator user's `DropzoneUser`-less notification correctly (recipient type
     per the `Notification` model; check `received_by` polymorphism).
  3. Packing card: same attach pattern.
  4. Specs with fixture images.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green.
Acceptance criteria (owner, real device):
  - On a phone: set a dropzone banner and a packing card photo with the camera.
Out of scope: direct uploads.
Risk / rollback: revert.
Size: M
Fixes: BUG-041

### P6.22 — Add optimistic locking to loads and slots
Status: done
Repo: both
Depends on: P6.21
Branch: modernise/p6-22-optimistic-locking
Goal: Concurrent edits of the same load or slot are detected; the losing client sees a conflict message and the fresh data.
Context: BUG-024 (`update_load.rb`; client `useLoad.tsx:60-77` optimistic responses).
Steps:
  1. backend: `lock_version` integer default 0 on `loads` and `slots`; expose `lockVersion: Int!`; `updateLoad`/
     `updateSlot` inputs accept `lockVersion`; rescue `ActiveRecord::StaleObjectError` → error code `CONFLICT`.
  2. client: fragments include `lockVersion`; mutations send it; on `CONFLICT`, refetch the load and show a snackbar
     "This load was changed by someone else".
  3. Specs: stale update rejected. Client test for the conflict path.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: slot-level optimistic UI redesign.
Risk / rollback: revert both (migration rollback drops the columns).
Size: M
Fixes: BUG-024

### P6.23 — Store money as integer cents
Status: done
Repo: both
Depends on: P6.22
Branch: modernise/p6-23-money-cents
Goal: All monetary amounts are integer cents in the database and API; refunds are exact.
Context: BUG-048 (`dropzones.credits integer`, `dropzone_users.credits float`, `orders.amount float`,
`ticket_types.cost float`, `extras.cost float`, `transactions.amount float`, `receipts.amount_cents integer`;
`refund.rb:69-72`, `purchase.rb:76-80` integer division).
Steps:
  1. backend migration: add `*_cents bigint` columns, backfill `(value * 100).round`, keep old columns until P8.8 has
     run (do not drop in this task); models read/write cents; `money-rails` is not added — use plain integers and a
     `Money` value object in `app/models/money.rb` with `to_s` formatting.
  2. API: keep existing `Float` fields as deprecated computed values (`cents / 100.0`) and add `*Cents: Int!` fields;
     inputs accept `costCents`/`amountCents` and still accept the old float for one release.
  3. client: switch fragments and forms to cents fields; format with `Intl.NumberFormat` using the dropzone currency
     (default `AUD` if none; check the schema for a currency field).
  4. Specs: refund of 12.50 → exact; wallet sums; migration backfill spec.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web smoke test pass; dev seed totals unchanged after migration
    (compare sums before/after in the PR).
Acceptance criteria (owner, real device):
  - none
Out of scope: dropping old columns (P8.8 follow-up after production data migration).
Risk / rollback: dual columns make rollback safe.
Size: L
Fixes: BUG-048

### P6.24 — Close the sign-up takeover and harden CORS and CI secrets
Status: done
Repo: backend
Depends on: P6.23
Branch: modernise/p6-24-signup-cors
Goal: Ghost accounts can only be claimed through email confirmation; CORS is restricted; Brakeman runs in CI.
Context: BUG-012 (`mutations/users/sign_up.rb:18-23` reuses ghosts and skips confirmation outside production). BUG-014
was partly fixed in P0.4 (secret removed from CI); CORS remains (`config/initializers/cors.rb:3-6`).
Steps:
  1. Sign-up for an email that matches a ghost: create no session; send the confirmation email; on confirmation, merge
     the ghost into the confirmed user (`Users::ClaimGhost` interaction). Never call `skip_confirmation!` for ghosts.
  2. CORS: origins from `ENV.fetch("CORS_ORIGINS", "http://localhost:19006,http://localhost:8081").split(",")`;
     document the variable in reference README §10 and CLOUD_ENV §3.
  3. Add `brakeman` (latest) to the development/test group and a `brakeman --no-pager --exit-on-warn` step to backend CI;
     fix or ignore (with a reason in `config/brakeman.ignore`) every warning.
  4. Specs: ghost claim flow; CORS preflight from an allowed and a disallowed origin.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; `bundle exec brakeman --no-pager --exit-on-warn` exits 0.
Acceptance criteria (owner, real device):
  - none
Out of scope: rate limiting.
Risk / rollback: revert.
Size: M
Fixes: BUG-012, BUG-014 (CORS)

### P6.25 — Remove N+1 queries on the manifest board
Status: done
Repo: backend
Depends on: P6.24
Branch: modernise/p6-25-n-plus-one
Goal: Loading the manifest board and member list runs a bounded number of queries.
Context: BUG-049 (`types/manifest/load.rb:20-23,36-40,55-57`; `types/users/dropzone_user.rb:65-112`;
`dropzone_user.rb:118-120,157-163`).
Steps:
  1. Use `GraphQL::Dataloader` sources (`Sources::AssociationLoader` with `ActiveRecord::Associations::Preloader`) for
     `slots`, `rigInspections`, notification counts; memoise permissions per membership in the request.
  2. Add `prosopite` (latest) in test; enable it in a request spec that loads the board with 5 loads × 10 slots and
     the member list with 30 members; fail on N+1.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green including the prosopite spec.
Acceptance criteria (owner, real device):
  - none
Out of scope: caching.
Risk / rollback: revert.
Size: M
Fixes: BUG-049

### P6.26 — Fix client manifest and user UX bugs
Status: done
Repo: client
Depends on: P6.25
Branch: modernise/p6-26-client-ux
Goal: Pull-to-refresh refreshes loads; manifest staff can create loads without their own jumper prerequisites; creating
a ghost user submits.
Context: BUG-065 (`ManifestScreen.tsx:289` calls the dropzone query's `fetchMore`), BUG-067 (`app/forms/load/useForm.tsx:77-108`
runs the staff member's own `canManifest()`; server base errors not shown), BUG-086 (client#126, `app/forms/create_user/*`
submit button does nothing; P1.13 found the cause: `RoleSelect` / `FederationSelect` drop the `error` prop), BUG-096 (aircraft and
ticket dialogs pass `undefined` for untouched fields, overriding the form defaults).
Steps:
  1. `onRefresh={loads.refetch}`, `refreshing={loads.networkStatus === NetworkStatus.refetch}`.
  2. Remove the `canManifest()` gate from load creation; show `errors` from the `createLoad` payload in the form.
  3. Create ghost: un-skip `app/__tests__/users/CreateGhost.test.tsx` from P1.13 (or write it if P1.13 found it passing); fix the cause (wiring of
     `handleSubmit` / button `onPress`; P1.13: forward `error` through `RoleSelect` and `FederationSelect`); close client#126 in the PR body.
  4. BUG-096: un-skip the tests in `app/__tests__/setup/{AircraftForm,TicketTypeForm}.test.tsx`; stop the aircraft and ticket
     dialogs from overriding form defaults with `undefined`.
  5. Tests for each.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test (create a ghost user, create a load as a staff user without
    membership) pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: BUG-065, BUG-067, BUG-086, BUG-096

### P6.27 — Verify Phase 6
Status: owner-check (run docs/SMOKE_TEST.md on one iPhone and one Android phone against a staging API; see docs/verification/phase-6.md)
Repo: both
Depends on: P6.1, P6.2, P6.3, P6.4, P6.5, P6.6, P6.8, P6.9, P6.10, P6.11, P6.12, P6.13, P6.15, P6.16, P6.17, P6.18, P6.19, P6.20, P6.21, P6.22, P6.23, P6.24, P6.25, P6.26
Branch: modernise/p6-27-verify
Goal: The system is secure and correct enough to deploy.
Context: Phase gate. P6.7 (D8) and P6.14 (D3) are excluded from dependencies; record their state.
Steps:
  1. Backend: rspec, rubocop, brakeman, bundle-audit; client: checks, `check:graphql`, web export, smoke test, yarn audit.
  2. Re-run the pass-1 audit scenarios (AUDIT-1…25 in BUGS.md evidence) as the P1.7 and Phase 6 specs: list each with
     its covering spec file in `docs/verification/phase-6.md`.
  3. BUGS.md: every bug fixed so far is prefixed `FIXED in`; list remaining open bugs with their planned task.
Acceptance criteria (cloud VM):
  - All commands exit 0; no `pending "BUG-` specs remain except for bugs blocked on D3/D8; CI green on `staging`.
Acceptance criteria (owner, real device):
  - Run the full `client:docs/SMOKE_TEST.md` on one iPhone and one Android phone against a staging API built from
    `staging` (after D1 hosting exists; otherwise on web via the cloud VM tunnel the executor documents in the PR).
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase U — UI and UX modernisation

Goal: the redesign in [`client:docs/ui-modernisation-plan.md`](https://github.com/OpenManifest/openmanifest/blob/staging/docs/ui-modernisation-plan.md)
is built: a workspace shell for staff on tablet and desktop, tokens and an in-house component layer (`client:app/ui`),
the manifest board, load and picker rebuilt for speed, a member "Today" screen, People and Setup regrouped, WCAG 2.2 AA,
client-side i18n fed by the operator's terminology, and layout tests that run in CI. Approved by the owner on
2026-10-11 (decisions D-UI1–D-UI11 in that document; D-UI11: no offline mode, but an operator can switch off
self-manifesting and run everything from the office, UB.1 and UB.2).

Read before any Phase U task, in this order: "Client UI work" in the executor instructions; this preamble; the design
plan sections the task names (§ numbers in Phase U refer to it); the mockups
(<https://claude.ai/artifact/Mdiri5pZsNQ8qEBRtR3jdZ>; if you cannot open it, the design plan's §2–§5 and the
screenshots in `client:docs/ui-audit/` are enough); `client:docs/reference/README.md`.

How Phase U fits with Phase 7 (see "Execution order"): the safety net (U0.1, U0.2) and the office tasks (UB.1, UB.2)
run first; the renames (P7.1–P7.6) and templates (P7.7) come next, so everything after them uses the final names and
the operator's terminology; then the UI foundations (U0.3–U2.8); then the generic domain model (P7.8–P7.17); then the
screens (U3–U5), built once for that model. Phase 7's own UI tasks were merged into Phase U where they overlapped:
P7.18 into U0.6, P7.19 into U3, P7.22's navigation part into U1.1. The design plan's D-UI6 vocabulary is replaced by
GENERALISATION §3 and §13 (owner decision D5): code uses `Operator`, `Membership`, `Vehicle`, `Load`, `Slot`; users
see the operator's terms.

**Feature flag.** The new board, load screen and picker (U3.2–U3.9) ship behind the `newBoard` preference (on for new
installs, off for existing ones until U6.4), so the old screens keep working while the batch is reviewed.

**Owner checks.** Checkpoints have no blocking owner criteria, so the queue can continue; each checkpoint PR lists the
device checks for that batch, and U6.5 collects them as the gate before production.

---

### UB.1 — Let a dropzone switch off self-manifesting
Status: done
Repo: both
Depends on: none
Branch: modernise/ub-1-self-manifest-setting
Goal: A dropzone setting `allowSelfManifest` (default `true`). When it is `false`, members can see the board but cannot
put themselves on, take themselves off, move or edit their own slots; staff with the `…User…` slot permissions can still
do everything, including manifesting themselves. Everything can be run from the office.
Context: Design plan D-UI11 (owner, 2026-10-11). Settings live in `backend:app/models/concerns/dropzones/configuration.rb`
(`default_settings`, JSON column `dropzones.settings`) and are exposed by `backend:app/graphql/types/dropzone/settings.rb`
and `Types::Input::Dropzone::SettingsInput`. Self versus others is already split by permission: `createSlot`/`createUserSlot`
(`backend:app/interactions/manifest/create_slot.rb:147-155`), `deleteSlot`/`deleteUserSlot` (`delete_slot.rb:83-90`),
`updateSlot`/`updateUserSlot` (`move_slot.rb:125-129`, `mutations/manifest/update_slot.rb:55-77`), `createSlots`
(`mutations/manifest/create_slots.rb:29-48`). Every check goes through `DropzoneUser#can?` (`backend:app/models/dropzone_user.rb:122`);
the client hides actions by the permissions it receives (`DropzoneUser.permissions`, `Session.permissions`), so filtering
permissions in one place covers both the API and the UI.
Steps:
  1. backend: add `allow_self_manifest: true` to `default_settings` (comment: "Members may manifest themselves; when
     false, only staff with the …User… slot permissions manifest"). Add the GraphQL field and input argument
     `allowSelfManifest`.
  2. backend: in `DropzoneUser`, a constant `SELF_SERVICE_PERMISSIONS = { createSlot: :createUserSlot,
     createDoubleSlot: :createUserDoubleSlot, updateSlot: :updateUserSlot, deleteSlot: :deleteUserSlot }`. A self-service
     permission counts only if `dropzone.allow_self_manifest?` is true or the member also holds its staff counterpart.
     Apply it in `can?`, `permission_names` and the session's `permissions` (`backend:app/graphql/types/access/session_type.rb:11`;
     use `permission_names`, not `all_permissions.pluck`). Keep the dataloader-friendly path in `permission_names`
     (no extra query per member: the dropzone is already loaded with the membership).
  3. backend: when a mutation is refused for this reason, the error reads "Manifesting is done by the manifest desk at
     this dropzone" (add a branch in each `required_permissions`/`authorized?` listed in Context that checks the setting
     first).
  4. backend specs: request specs in `spec/requests/manifest_authorization_spec.rb` for setting off: fun jumper
     `createSlot` self, `createSlots` self-group, `deleteSlot` own, `updateSlot` own, `moveSlot` own are refused with that
     message; manifest staff manifests a jumper, and manifests themselves; `permissions` for the fun jumper omit
     `createSlot`/`updateSlot`/`deleteSlot`; setting on: today's behaviour unchanged. N+1 spec still green.
  5. client: `yarn sync:schema && yarn ts:graphql`; add the toggle to `app/forms/dropzone/DropzoneForm.tsx` beside the
     other rules: "Members can book themselves on loads", helper "When off, only manifest staff can add, move or remove
     people". On the board and load screen, a member without `CreateSlot` sees a one-line note "Bookings are made at the
     manifest desk" instead of the add actions (verify the existing gates in `load/ActionButton.tsx`,
     `manifest/LoadCard/Large/Card.tsx`, `components/appbar/AppBar.tsx` already hide them; fix any that check a role
     instead of the permission). Jest test for the note.
  6. Run `bin/sync-client-operations` in the backend if client operations changed.
Acceptance criteria (cloud VM):
  - Backend: rspec, rubocop, brakeman green. Client: client checks, `check:graphql`, web export; tier 2 `@manifest`.
Acceptance criteria (owner, real device):
  - none
Out of scope: per-role overrides (the permissions screen already allows that); hiding the board from members.
Risk / rollback: default `true` keeps current behaviour; revert both PRs.
Size: M
Fixes: none

### UB.2 — Let staff manage a member's equipment from the office
Status: done
Repo: both
Depends on: none
Branch: modernise/ub-2-office-equipment
Goal: Staff with `updateUser` at a dropzone can create, update and archive the personal rigs of that dropzone's members;
with UB.1 this closes the last self-service action that has no office equivalent.
Context: Office parity audit (2026-10-11), every member action and its staff path: manifest, take off, move, group
(`createUserSlot`, `deleteUserSlot`, `updateUserSlot`, `createSlots`) ✓; walk-in member without an account (`createGhost`,
`client:app/forms/create_user/Dialog.tsx`) ✓; licence, federation number, exit weight (`updateUser`,
`backend:app/interactions/users/update_user.rb`) ✓; role and membership expiry (`updateDropzoneUser`) ✓; credit
(`createOrder` with `createUserTransaction`) ✓; rig inspection (staff) ✓; **personal rigs ✗**: `createRig` refuses
`user_id` of another user (`backend:app/graphql/mutations/setup/equipment/create_rig.rb:59-66`), `updateRig` refuses
another user's rig (`update_rig.rb:56-66`), and `archiveRig` likewise (check). Pack jobs have no mutations (n/a).
Steps:
  1. backend: allow the other-user branch when the caller `can?(:updateUser, dropzone_id:)` at a dropzone where the rig's
     owner is a member (a `dropzone` argument on `createRig` if the input has none; check `RigInput`). Same rule in
     `updateRig` and `archiveRig`. Members keep full control of their own rigs.
  2. backend specs: staff creates/updates/archives a member's rig; staff of another dropzone is refused; a fun jumper
     cannot touch another member's rig.
  3. client: on a member's profile (`app/screens/authenticated/user/profile/*`, equipment section and
     `user/equipment/*`), show add/edit for staff with `UpdateUser`; Jest test with a staff fixture.
Acceptance criteria (cloud VM):
  - Backend rspec, rubocop, brakeman green; client checks and `check:graphql`; tier 2 `@profile`.
Acceptance criteria (owner, real device):
  - none
Out of scope: dropzone rigs (already staff-managed).
Risk / rollback: revert both PRs.
Size: M
Fixes: none

### UB.3 — Expose the last slot and the call time
Status: todo
Repo: backend
Depends on: P7.17
Branch: modernise/ub-3-last-slot-call-time
Goal: The picker can pre-fill a returning member's choices and a load can show "called at 12:10".
Context: Design plan §11 items 2 and 4. Call presets moved to P7.11 (`callScheduleMinutes`) and eligibility reasons to
P7.16 (`Membership.eligibility`); this task keeps the rest of the former UB.4. P7.17 added `departed_at` and
`completed_at`.
Steps:
  1. `Membership.lastSlot: Slot` (most recent kept slot at this operator on a departed or completed load; ticket type,
     activity type, equipment, destination, body mass and extras reachable through existing fields), dataloader-backed;
     N+1 spec.
  2. Migration `loads.called_at` (datetime, null), set by the state machine when the load enters `boarding` and cleared
     when the call is cancelled; GraphQL `Load.calledAt`. Specs for both transitions.
Acceptance criteria (cloud VM):
  - Backend rspec, rubocop, brakeman green; schema dump diff additive only.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: additive; revert and drop the column.
Size: S
Fixes: none

### U0.1 — Replace the web smoke script with a Playwright Test suite
Status: done
Repo: client
Depends on: none
Branch: modernise/u0-1-playwright
Goal: `e2e/` holds a Playwright Test suite with `smoke` and `full` projects, role log-ins, layout invariants and axe, and
reproduces everything `scripts/web-smoke.mjs` checks today.
Context: `scripts/web-smoke.mjs` (Playwright loaded from `/opt/node-tools`, `pressAt` workaround for gesture-handler
touchables, `checkLayout`, `checkReachable`); serving: `python3 scripts/serve-web-build.py dist 19006`; backend dev seed
`backend:db/seeds/dev_baseline.rb` (owner, `manifest@example.com`, `pilot@`, `jumper1@`, `jumper2@`, `student@`; check
the seed for the password). Versions checked 2026-10-11: `@playwright/test` 1.64.x, `@axe-core/playwright` 4.13.x. The
VM has Chromium in `/opt/pw-browsers`; if the pinned Playwright wants another build, launch with
`executablePath: process.env.PW_CHROMIUM ?? undefined` and set `PW_CHROMIUM=/opt/pw-browsers/chromium` locally.
Steps:
  1. `yarn add -D @playwright/test@~1.64 @axe-core/playwright@~4.13`. `playwright.config.ts`: `baseURL` from
     `UI_BASE_URL` (default `http://localhost:19006`), `retries: 1` on CI, `workers` 2, `reporter` html + list,
     timezone `Australia/Brisbane`; projects `smoke` (390×844, 1440×900; light) and `full` (360×640, 390×844, 820×1180,
     1440×900 × light/dark via `colorScheme`; a `text200` variant that doubles root font size as P5.8 did; a
     `generic` variant that opens routes with `?industry=generic`, which U0.6 implements; until then skip it).
  2. `e2e/support/`: `login(page, role)` storing auth state per role in `e2e/.auth/` (git-ignored), `press(locator)`
     (ported `pressAt`), `expectLayout(page)` (no horizontal scroll, primary action in viewport, last row reachable:
     ported `checkLayout`/`checkReachable`), `expectAccessible(page, { baseline })` (axe, tags `wcag2a`, `wcag2aa`,
     `wcag21aa`, `wcag22aa`; violations compared against `e2e/axe-baseline.json`: new serious or critical ones fail,
     existing ones are listed).
  3. Specs with tags: `login.spec.ts` (`@login`), `board.spec.ts` (`@manifest`: board, open a load, deep links from the
     old script), `profile.spec.ts` (`@profile`), `settings.spec.ts` (`@setup`). Record the axe baseline.
  4. Scripts: `test:ui:smoke` (`playwright test --project=smoke`), `test:ui:full`, `test:ui:report`. Add `e2e/README.md`
     with the local run (backend boot, web export, serve, run). Delete `scripts/web-smoke.mjs` and update CLOUD_ENV §4
     and the client README.
Acceptance criteria (cloud VM):
  - Client checks; `yarn test:ui:smoke` passes against the dev backend; `yarn test:ui:full --grep @login` passes
    (one-off check that the full project works; not repeated in later non-checkpoint tasks).
Acceptance criteria (owner, real device):
  - none
Out of scope: CI (U0.2).
Risk / rollback: revert; the old script is in history.
Size: L
Fixes: none

### U0.2 — Run the UI smoke suite in CI and add the full-suite workflow
Status: done
Repo: client
Depends on: U0.1
Branch: modernise/u0-2-ui-ci
Goal: Every PR touching the app runs tier 2 against a backend booted in the job; the full suite runs on demand and
weekly.
Context: `client:.github/workflows/ci.yml` (`checks`, `web-export`); backend CI setup in `backend:.github/workflows/ci.yml`
(Postgres 16 service, `ruby/setup-ruby` with `.ruby-version`, `libpq-dev libvips42`). The local endpoint is
`http://local.openmanifest.org:5000/graphql` (`client:build/constants.ts`). P8.7 step 2 planned this job; it moves here.
Steps:
  1. A composite action `.github/actions/ui-env/action.yml`: check out `OpenManifest/openmanifest-server` at `staging`
     (input `backend-ref`, default `staging`) into `backend/`, Postgres service is declared by the calling job, install
     Ruby with bundler cache, `db:create db:schema:load`, run `db/seeds/dev_baseline.rb`, start Rails on 5000
     (`SECRET_KEY_BASE` random, `CORS_ORIGINS=http://localhost:19006`), add `127.0.0.1 local.openmanifest.org` to
     `/etc/hosts`, `EXPO_ENV=local npx expo export --platform web`, serve `dist` on 19006, wait for both.
  2. Job `web-ui-smoke` in `ci.yml` (needs `checks`): path filter `app/**`, `e2e/**`, `package.json`, `yarn.lock`,
     `playwright.config.ts`; runs `yarn test:ui:smoke`; uploads the HTML report and traces on failure.
  3. Workflow `ui-full.yml`: `workflow_dispatch` (inputs `backend-ref`, `grep`) and `schedule` weekly (Monday 03:00
     Australia/Brisbane); runs `yarn test:ui:full`, uploads report and screenshot diffs.
  4. Document in `e2e/README.md` how an executor triggers `ui-full` on a branch (GitHub MCP `actions_run_trigger` or
     `gh workflow run ui-full.yml --ref <branch>`) and reads the result.
Acceptance criteria (cloud VM):
  - The PR's `web-ui-smoke` job passes; one manual `ui-full` run on the branch passes (attach the run URL).
Acceptance criteria (owner, real device):
  - none
Out of scope: Android (U3.1).
Risk / rollback: revert the workflow files.
Size: M
Fixes: none

### U0.3 — Add design tokens and the contrast function
Status: done
Repo: client
Depends on: none
Branch: modernise/u0-3-tokens
Goal: `app/ui/tokens` defines colour (light and dark), type, space, radius, elevation, density and motion, and derives
accessible brand shades from any operator colour.
Context: Design plan §3.1–§3.2 and the mockups' "Design system" board. Values:
  - Light: app `#F4F5F7`, surface `#FFFFFF`, raised `#EEF0F3`, border `#DDE1E6`, text `#14181F`, textMuted `#5B6472`,
    brand default `#1D3557` (D-UI3), brandSoft `#E4EAF2`.
  - Dark: app `#0E1116`, surface `#171B22`, raised `#232A34`, border `#2A313C`, text `#E8EBF0`, textMuted `#A9B2BF`,
    brand (dark default) `#35C3CF` on `#04262A`, brandSoft `#13353A`.
  - Status pairs (background/foreground, light): open `#E1EEFB`/`#0A4F96`, boarding `#FFE6A8`/`#5C3B00`, departed
    `#EBE3FA`/`#43287A`, landed `#DDF2E3`/`#17592F`, cancelled `#ECEEF1`/`#4A5260`, warning `#FFE9D6`/`#7A3300`,
    blocked `#FDE3E5`/`#8E1119`. Dark: ok `#12351F`/`#8FE3AE`, warning `#4A2A0C`/`#FFC98A`, info `#10304F`/`#9CCBFF`,
    boarding `#4A3A12`/`#FFE08A`; derive the rest the same way and test them.
  - Type: countdown 56/700, title 20/600, body 15/400, bodyCompact 14/400, label 13/600, caption 12/400; tabular
    numerals. Space 4, 8, 12, 16, 24, 32, 48. Radius 4, 8, 12, pill. Density rows 40/48/56, touch target min 44 (iOS)
    / 48 (Android). Motion 120/200/300 ms; highlight 600 ms.
Steps:
  1. `app/ui/tokens/{colour,type,space,radius,elevation,density,motion}.ts` with typed objects; `index.ts` exports a
     `Tokens` type.
  2. `contrast.ts`: WCAG relative luminance and ratio; `deriveBrand(hex, scheme)` returns `brand`, `onBrand`,
     `brandText` (the operator colour adjusted in OKLCH lightness until text pairs reach 4.5:1 on surface and on brand),
     `brandSoft`, `onBrandSoft`.
  3. Tests (`app/ui/tokens/__tests__`): every listed pair ≥ 4.5:1 (3:1 for icons and large text); `deriveBrand` for 50
     colours (include `#FF1414`, `#FFFF00`, `#000000`, `#FFFFFF`, the demo navy, the mockup teal) meets the pairs in
     both schemes.
Acceptance criteria (cloud VM):
  - Client checks. (No UI changes yet; no tier 2.)
Acceptance criteria (owner, real device):
  - none
Out of scope: using the tokens (U0.4).
Risk / rollback: additive.
Size: M
Fixes: none

### U0.4 — Generate the app theme from tokens; default brand and system fonts
Status: done
Repo: client
Depends on: U0.3, U0.1
Branch: modernise/u0-4-theme
Goal: `app/ui/theme` provides `ThemeProvider`, `useTheme()`, `useStyles()` and `useDevice()`; Paper's MD2 theme and the
Navigation theme are generated from tokens with the same exports as today; the default brand is navy and fonts are the
system fonts. The app looks the same apart from colours, fonts and dark surfaces.
Context: `app/theme/palette.ts` (MD2 light/dark + Roboto names), `app/theme/overrides.ts` (operator colours, live
preview), `app/constants/Colors.ts` (`#FF1414`), fonts loaded in `app/entrypoint/hooks/useCachedResources.ts:13` and
`app/entrypoint/providers/AppUpdate.tsx:19`, literal `fontFamily: 'Roboto_…'` in `components/orders/OrderCard.tsx:38` and
`components/appbar/AppBar.tsx:50`; `app/components/layout/useBreakpoint.ts`. Design plan D-UI3, D-UI8, §3.2 Density, §4
pointer signal.
Steps:
  1. `app/ui/theme/`: `ThemeProvider` (scheme from the preferences store, brand from the current operator via
     `deriveBrand`), `useTheme()`, `useStyles(factory)` (memoised on theme, breakpoint and density; ~60 lines),
     `useDevice()` → `{ breakpoint, pointer: 'coarse' | 'fine', density }` (`matchMedia('(pointer: coarse)')` on web,
     `coarse` on native; density from breakpoint and pointer, overridable later in Account).
  2. Rewrite `app/theme/palette.ts` internals to build `MD2LightTheme`/`MD2DarkTheme` and the Navigation theme from
     tokens; keep its exports. `Colors.ts` default brand `#1D3557`.
  3. Remove the Roboto font packages and loading; replace literal `fontFamily` uses with the system font (omit
     `fontFamily`, keep weights); verify Paper's `fonts` config uses the platform default.
  4. Record the web bundle size and Jest/Playwright timings in the PR (baseline for U6.3).
Acceptance criteria (cloud VM):
  - Client checks, web export; tier 2 (all tags). Before/after screenshots of board, load and profile at 390 and 1440 in
    light and dark in the PR.
Acceptance criteria (owner, real device):
  - none (fonts on devices are checked at Checkpoint U0.10's owner list)
Out of scope: changing components.
Risk / rollback: visual change only; revert.
Size: L
Fixes: none

### U0.5 — Add the UI lint guardrails and the debt counter
Status: done
Repo: client
Depends on: U0.4
Branch: modernise/u0-5-ui-lint
Goal: The rules in design plan §3.5 exist as errors for converted directories and as a counted debt elsewhere.
Context: `client:eslint.config.js` (flat config; P5.9 added `no-restricted-syntax`/`no-restricted-imports` guards).
`eslint-plugin-react-native-a11y` is not usable (ESLint ≤ 8).
Steps:
  1. `eslint/ui-converted.js` exports the list of converted globs (start: `app/ui/**`). Rules applied as `error` to
     those globs: no colour literals (hex, `rgb(`, `rgba(`, `'white'`, `'black'`), no numeric `fontSize`, no numeric
     `margin*`/`padding*`/`gap` (allow 0), no `react-native-paper` imports, no `Pressable`/`TouchableOpacity`/
     `TouchableWithoutFeedback`/`TouchableHighlight` JSX with `onPress`, `Image` without `accessibilityLabel` or
     `accessible={false}`.
  2. `scripts/ui-debt.mjs`: counts Paper imports, colour literals, raw touchables, numeric font sizes and literal JSX
     strings per directory; prints a table and writes `ui-debt.json`. CI prints it in the `checks` job (never fails).
  3. Add the current numbers to `e2e/README.md`'s "UI debt" table; each later task updates them in its PR body.
Acceptance criteria (cloud VM):
  - Client checks; `node scripts/ui-debt.mjs` prints the table.
Acceptance criteria (owner, real device):
  - none
Out of scope: fixing the debt.
Risk / rollback: revert.
Size: S
Fixes: none

### U0.6 — Add i18n with the operator's terminology
Status: done
Repo: client
Depends on: P7.7
Branch: modernise/u0-6-i18n
Goal: `app/i18n` provides i18next with `common` and `terms` namespaces; `terms` come from the current operator's
`terminology` (P7.7) with bundled fallbacks; formatters exist for money, dates, quantities, destinations and calls.
Context: GENERALISATION §13 (term keys `operator, member, vehicle, load, slot, ticket, extra, destination, activity,
crew.<key>, escort, guest, certification_body, certification, equipment, inspection, daily_log, call, load_count,
state.<state>`); this task replaces P7.18 (superseded). Design plan §6. Versions checked 2026-10-11: `i18next` 26.4.x,
`react-i18next` 17.0.x, `eslint-plugin-i18next` 6.1.x; `expo-localization` via `npx expo install`. Money formatting
today: `app/utils/money.ts`; operator clock: `app/utils/dropzoneTime.ts` or its renamed successor (luxon).
Steps:
  1. Install the libraries. `app/i18n/index.ts`: init with `lng` from `expo-localization` (default `en-AU`, fallback
     `en`), namespaces `common` and `terms`, `returnNull: false`.
  2. `app/i18n/locales/en/common.json` (start with tab and header labels) and `terms.generic.json` (the `generic`
     template's words, the fallback). `scripts/sync-terminology.mjs` copies each backend template's
     `config/industries/<slug>/locales/en.yml` into `app/i18n/fixtures/<slug>.json` (same mechanism as
     `scripts/sync-schema.mjs`) for tests, the gallery and Playwright.
  3. `useOperatorTerms()`: on operator change, `i18n.addResourceBundle(lng, 'terms', operator.terminology, true, true)`.
     On web dev/CI builds, `?industry=<slug>` replaces the operator's terms with that fixture (used by the `full`
     Playwright project and the gallery); tests pass a fixture through `renderWithProviders`.
  4. `app/i18n/format.ts`: `formatMoney` (wraps `utils/money.ts`; currency from `operator.currency` once P7.12 adds it,
     `AUD` until then), `formatDate`/`formatTime`/`formatRelative` with luxon in the operator's time zone,
     unambiguous dates ("8 Oct 2027"), `formatCall` (minutes → the template's call wording), `formatDestination` and
     `formatQuantity` as thin stubs that P7.8 and P7.12 complete.
  5. Install `eslint-plugin-i18next`; enable `i18next/no-literal-string` (`mode: 'jsx-text-only'`) for the converted
     globs from U0.5 (only `app/ui/**` for now). Convert the tab labels (proof of wiring).
  6. Tests: plural terms, switching between a skydiving and a generic operator, each formatter (time zone, 12/24 h).
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`; web export; tier 2 `@nav`.
Acceptance criteria (owner, real device):
  - none
Out of scope: converting screens (done as each screen is rebuilt).
Risk / rollback: revert.
Size: M
Fixes: none

### U0.7 — Upgrade Testing Library and add shared test utilities
Status: done
Repo: client
Depends on: U0.4, U0.6
Branch: modernise/u0-7-testing-library
Goal: `@testing-library/react-native` 14.1.x with a `renderWithProviders` that wraps theme, terms, Apollo mocks and
navigation, so tests query by role.
Context: 45 test files on RNTL 13 (`app/__tests__`, `app/**/__tests__`); RNTL 14.1.0 needs RN ≥ 0.78 and React ≥ 19
(met).
Steps:
  1. Upgrade; follow the v14 migration guide. If more than 20 test files need non-mechanical changes, stop and set
     `blocked (RNTL 14 migration larger than expected)`.
  2. `app/test-utils/render.tsx`: `renderWithProviders(ui, { role, profile, scheme, breakpoint, mocks })` with role
     fixtures (owner, manifest, fun jumper, student) built from the skydiving template's role presets
     (`backend:config/industries/skydiving/presets.yml`, P7.7).
  3. Convert three existing tests to `getByRole` as examples.
Acceptance criteria (cloud VM):
  - Client checks.
Acceptance criteria (owner, real device):
  - none
Out of scope: converting all tests.
Risk / rollback: revert.
Size: M
Fixes: none

### U0.8 — Spike headless primitives for overlays on web
Status: done
Repo: client
Depends on: U0.4, U0.1
Branch: modernise/u0-8-primitives-spike
Goal: A written go/no-go for `@rn-primitives` (dialog, select, tabs, popover, tooltip, portal) based on web keyboard and
screen-reader semantics.
Context: Design plan §3.3 (1.5.x, peers `*`, includes react-native-web). Fallback: our own semantics on
`app/components/input/select/Select.web.tsx`, `Menu.web.tsx`, `layout/DialogOrSheet.web.tsx`.
Steps:
  1. Install the packages; a dev-only route `/__spike` with a dialog, select, tabs, popover and tooltip.
  2. Playwright test (tag `@spike`): dialog traps focus and Esc closes it, returns focus to the trigger; select opens with
     Enter/Space, arrows move, Enter selects, roles `listbox`/`option`; tabs use arrows and `tab`/`tabpanel`; axe
     clean.
  3. Write `client:docs/ui/spike-rn-primitives.md`: results, bundle size added, decision. If no-go, remove the packages
     and note the fallback for U2.3.
Acceptance criteria (cloud VM):
  - Client checks; `yarn test:ui:smoke --grep @spike`.
Acceptance criteria (owner, real device):
  - none (TalkBack/VoiceOver on the overlays is in Checkpoint U2.8's owner list)
Out of scope: building components.
Risk / rollback: spike route is dev-only; revert.
Size: M
Fixes: none

### U0.9 — Apply the logged quick fixes
Status: done
Repo: both
Depends on: none
Branch: modernise/u0-9-quick-fixes
Goal: The behaviour-free fixes in design plan §1.11 are done, plus the one backend bug found by the audit.
Context: Design plan §1.11.
Steps:
  1. client: rename `app/providers/load/context .tsx` (space) and fix imports; delete `components/UserAvatar.web.old.tsx`,
     `components/input/LocationPicker.oldios.tsx`; remove the 88 `console.log/debug` calls (keep error reporting through
     AppSignal); fix the stale "Master Log … Temporarily disabled" copy and the check-mark icons on non-check rows in
     `SettingsMenuScreen.tsx`; correct `client:docs/reference/README.md` §6 (`TabBar.web.tsx` is not a top bar).
  2. backend: `app/graphql/types/equipment/rig.rb:38` reads an undefined `rig`; use `object`. Add BUG-1xx (next free ID)
     to `BUGS.md` with `FIXED in U0.9:` and a spec.
Acceptance criteria (cloud VM):
  - Client checks, web export; backend rspec and rubocop.
Acceptance criteria (owner, real device):
  - none
Notes (done): `components/UserAvatar.web.old.tsx` was not dead (an MUI avatar imported by `popover/Menu.web.tsx` and
`autocomplete/MembershipAutocomplete.web.tsx`), so it stays; `LocationPicker.oldios.tsx` was deleted. 88 `console.log/debug`
calls removed with the debug-only code behind them (`api/crud/factory.tsx`); the bug is BUG-102.
Out of scope: the visual quick fixes (WeatherBoard artwork, chart hatch, profile empty state, dark tab tint): they are
rebuilt in U1–U5.
Risk / rollback: revert.
Size: S
Fixes: the new BUG ID

### U0.10 — Checkpoint U0
Status: done
Repo: client
Depends on: U0.1, U0.2, U0.3, U0.4, U0.5, U0.6, U0.7, U0.8, U0.9
Branch: modernise/u0-10-checkpoint
Goal: Tier 3 passes on the foundations; baselines exist.
Context: Client UI work (test tiers).
Steps:
  1. Merge the batch's stack into the checkpoint branch as needed; run `yarn test:ui:full` locally and trigger
     `ui-full` on the branch.
  2. Create the first visual baselines for login, board, load, profile and settings (all `full` variants); commit them.
  3. Write `client:docs/verification/ui-u0.md` (results, axe baseline counts, UI debt table) and list the owner checks:
     system fonts and navy brand on an iPhone and an Android phone, light and dark.
Acceptance criteria (cloud VM):
  - Tier 3 web passes (Android starts at U3.1).
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: fixes beyond 30 lines (new task).
Risk / rollback: none.
Size: S
Fixes: none

---

### U1.1 — Compute navigation destinations from permissions and modules before render
Status: done
Repo: client
Depends on: U0.10
Branch: modernise/u1-1-destinations
Goal: One table of destinations decides tabs, rail and sidebar per role and per the operator's modules; tabs are
registered unconditionally and each screen shows a no-access or not-available state, so cold loads of deep links work.
Context: Design plan §5.1; GENERALISATION §14 (module-aware navigation, formerly P7.22 step 1); `operator.modules`
(P7.7); `app/screens/authenticated/routes.tsx` (tabs registered after permissions load, BUG-100); the drawer
component (renamed in P7.4 if it contained an old term).
Steps:
  1. `app/navigation/destinations.ts`: `{ key, route, icon, labelKey, permission?, module?, setting?, platformRole?,
     group: 'primary' | 'more' | 'account' }` for Today, Board, People, Inbox, Wallet, Money, Reports, Setup, Platform,
     Account. Later phases add Bookings and Shop here.
  2. `useDestinations()` returns the ordered list for the current session (§5.1 table) filtered by permissions and
     `operator.modules`; it waits for the session's permissions (splash until known).
  3. `NoAccess` and `NotAvailable` ("not available for this operator") screen states (plain `Text` until U2.4); register
     every tab always, guard each screen.
  4. Jest: destinations for the four role fixtures and for a skydiving and a generic operator; BUG-100 cold-load test
     (Playwright `@nav`: open the people route directly as owner).
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@nav`.
Acceptance criteria (owner, real device):
  - none
Out of scope: visual shell (U1.2).
Risk / rollback: revert.
Size: M
Fixes: BUG-100

### U1.2 — Build the responsive shell: tabs, rail and sidebar
Status: done
Repo: client
Depends on: U1.1
Branch: modernise/u1-2-shell
Goal: Bottom tabs on compact, a labelled rail on medium and a sidebar with operator switcher and account menu on
expanded, all from the destinations table; tablets can rotate.
Context: Design plan §4–§5, mockup "Desktop: manifest board"; React Navigation 7 `bottom-tabs` supports
`tabBarPosition: 'left'` (checked in the installed types); `authenticated/TabBar.tsx`, `TabBar.web.tsx` (identical);
`app.config.ts` `orientation: 'portrait'`.
Steps:
  1. `app/navigation/AppNavigation.tsx`: a custom `tabBar` rendering `BottomTabs` (compact), `Rail` (medium, 80 dp,
     icons and labels) or `Sidebar` (expanded, 240 dp: operator switcher at top, destinations, account menu at the
     bottom); `tabBarPosition` `bottom`/`left` by breakpoint. Active state uses `brandSoft`/`onBrandSoft` (contrast-safe,
     fixes the 1.7:1 dark tab icons); labels always visible; `maxFontSizeMultiplier` from `layout/fontScale.ts`.
  2. Keyboard and semantics on web: `nav` landmark, `aria-current`, focus ring from tokens, skip-to-content link.
  3. Delete `TabBar.web.tsx`. Set `orientation: 'default'` in `app.config.ts`; lock phones to portrait at runtime
     (`expo-screen-orientation`, `OrientationLock.PORTRAIT_UP` when the device is a phone) so only tablets rotate.
  4. All labels through `t()`; convert `app/navigation/**` (definition of done).
Acceptance criteria (cloud VM):
  - Client checks, web export; tier 2 `@nav` with new tests: tab bar at 390, sidebar at 1440, per role fixture, keyboard
    reaches every item.
Acceptance criteria (owner, real device):
  - none
Out of scope: Account screen (U1.3), headers (U1.4).
Risk / rollback: revert.
Size: L
Fixes: none

### U1.3 — Replace the drawer with Account and More
Status: done
Repo: client
Depends on: U1.2
Branch: modernise/u1-3-account
Goal: No drawer. Account (profile, equipment, appearance, density, switch operator, log out) is reachable from the
sidebar's account menu and from More on phones; staff get More (Setup, Money, Reports, Account) on compact.
Context: Design plan §5.2; `components/drawer/*`, `screens/drawers/UserDrawer.tsx`, Settings → Appearance today in
`configuration/settings_menu`.
Steps:
  1. `screens/authenticated/account/AccountScreen.tsx` and `MoreScreen.tsx` (list of `more` destinations).
  2. Move Appearance (System/Light/Dark) and a Density override (Auto/Compact/Comfortable/Touch, stored in preferences)
     into Account.
  3. Remove the drawer navigator, `Drawer.tsx`, `UserDrawer.tsx` and their tests; update links that opened the drawer.
  4. Convert the new screens (definition of done).
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@nav @account` (log out and switch operator from Account at 390 and 1440).
Acceptance criteria (owner, real device):
  - none
Out of scope: Setup regrouping (U5.3).
Risk / rollback: revert.
Size: M
Fixes: none

### U1.4 — Replace the app bar with a screen header
Status: done
Repo: client
Depends on: U1.2
Branch: modernise/u1-4-header
Goal: Every screen has `ScreenHeader` (title, back on detail screens, actions); the credits chip leaves the header;
document titles on web match.
Context: `components/appbar/AppBar.tsx` (hamburger, title, credits chip that shows the dropzone balance to owners);
load screen titled "Load" without a back button (design plan §1.8 item 2).
Steps:
  1. `app/navigation/ScreenHeader.tsx` used through `screenOptions.header`; back button with `accessibilityLabel`
     "Back to …" (previous screen's title); actions as `IconButton`s (until U2.1, use a minimal local button and
     replace it there).
  2. Titles from `t()`; the load screen reads "Load #n" (term-based: `t('common:loadNumber', { load: t('terms:load'), number })`); web
     `document.title` "<screen> · <operator>".
  3. Delete `components/appbar/*` and the credits chip.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@nav @manifest` (back from load to board at 390 and 1440).
Acceptance criteria (owner, real device):
  - none
Out of scope: balance display (Wallet U4.3, profile U5.2).
Risk / rollback: revert.
Size: M
Fixes: none

### U1.5 — Register the User stack once and redirect old paths
Status: done
Repo: client
Depends on: U1.2
Branch: modernise/u1-5-user-stack
Goal: A member's profile has one URL; the three other paths redirect.
Context: Design plan §1.2 (User stack registered under Manifest, Users, Notifications and Wizards; paths
`/dropzone/manifest/users/…`, `/user/…`, `/modal/user/…`).
Steps:
  1. One `User` stack under People (`/people/:userId/…` keeps `/user/:userId` as the canonical path if that is what
     push payloads use; check `api/crud/subscriptions` and notification data first and keep their path).
  2. Linking config redirects the other paths; update `navigate` calls.
  3. Playwright `@nav`: each old path lands on the profile.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@nav @profile`.
Acceptance criteria (owner, real device):
  - none
Out of scope: profile redesign (U5.2).
Risk / rollback: revert.
Size: M
Fixes: none

### U1.6 — Checkpoint U1
Status: done
Repo: client
Depends on: U1.1, U1.2, U1.3, U1.4, U1.5
Branch: modernise/u1-6-checkpoint
Goal: Tier 3 passes for the shell; baselines updated for changed routes.
Context: Client UI work (test tiers).
Steps:
  1. Tier 3 web (local and `ui-full` on the branch); update baselines for the shell routes.
  2. `client:docs/verification/ui-u1.md`; owner list: navigation per role on a phone and a tablet (both orientations),
     keyboard on a desktop browser, VoiceOver/TalkBack reach every tab.
Acceptance criteria (cloud VM):
  - Tier 3 web passes.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

### U2.1 — Build the base components
Status: done
Repo: client
Depends on: U0.10
Branch: modernise/u2-1-base-components
Goal: `Text`, `Button`, `IconButton`, `ListRow`, `Card`, `Divider`, `Stack`/`Row` layout helpers in `app/ui/components`
with tests.
Context: Design plan §3.4; tokens and `useStyles` from U0.3/U0.4.
Steps:
  1. `Text` variants = type tokens, `tabular` prop, colour by semantic token only.
  2. `Button` (primary, secondary, tertiary, destructive; `loading`, `disabled`; height by density, minimum target
     44/48), `IconButton` (`accessibilityLabel` required by its type; 44/48 target with `hitSlop` when the icon is
     smaller), `ListRow` (leading, title, supporting text, trailing; role `button` when pressable; selected state),
     `Card` (flat, raised), `Divider`. Pressed, hover (web) and focus-visible states.
  3. Tests per component: role, name, state, density sizes, both schemes.
Acceptance criteria (cloud VM):
  - Client checks.
Acceptance criteria (owner, real device):
  - none
Out of scope: gallery (U2.5).
Risk / rollback: additive.
Size: M
Fixes: none

### U2.2 — Build the form components
Status: done
Repo: client
Depends on: U2.1
Branch: modernise/u2-2-form-components
Goal: `TextField`, `NumberField` (units suffix, min/max, step), `Select`, `Segmented`, `Switch`, `Chip` (filter and
input) with labels, helper and error text wired for screen readers and react-hook-form.
Context: Existing `components/input/text/TextField`, `number_input`, `select`, `chip_select`, `dropdown_select`;
react-hook-form + yup (`app/forms/*`).
Steps:
  1. Components with a `control`-friendly API (`value`, `onChange`, `onBlur`, `error`) and `Controller` helpers
     (`FormTextField` etc.).
  2. `Select` uses `@rn-primitives/select` if U0.8 said go; otherwise our own listbox semantics.
  3. Tests: label association, error announcement (`accessibilityLiveRegion`/`aria-live`), keyboard on web (jsdom-level),
     density sizes.
Acceptance criteria (cloud VM):
  - Client checks.
Acceptance criteria (owner, real device):
  - none
Out of scope: converting forms (U2.6–U2.7).
Risk / rollback: additive.
Size: L
Fixes: none

### U2.3 — Build the overlay components
Status: done
Repo: client
Depends on: U2.1, U0.8
Branch: modernise/u2-3-overlays
Goal: One `Sheet`/`Dialog` API (bottom sheet on compact native, dialog or side panel elsewhere), `Menu`, `Popover`,
`Tooltip`, `Banner`, `Toast` (replacing the notifications provider's snackbar visuals).
Context: `layout/DialogOrSheet*.tsx` (P5.4), `@gorhom/bottom-sheet` 5.2.x, `providers/notifications`; U0.8 decision:
**go** for `@rn-primitives` on the web (installed; the spike route `/__spike`, `app/screens/dev/SpikeScreen.tsx`, `e2e/spike.spec.ts` and the
package entries stay until this task removes the route; rules for the select in `client:docs/ui/spike-rn-primitives.md`).
Steps:
  1. `Overlay` API: `presentation: 'auto' | 'sheet' | 'dialog' | 'panel'`, title, footer slot (pinned), focus trap and
     Esc on web, returns focus on close.
  2. `Menu`, `Popover`, `Tooltip` (primitives or fallback), `Banner` (info/warning/blocked with action), `Toast`.
  3. Tests; Playwright `@overlay` on a dev route with each overlay at 390 and 1440.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@overlay`.
Acceptance criteria (owner, real device):
  - none
Out of scope: replacing `DialogOrSheet` users (U2.6).
Risk / rollback: additive.
Size: L
Fixes: none

### U2.4 — Build the display components
Status: done
Repo: client
Depends on: U2.1
Branch: modernise/u2-4-display
Goal: `StatusBadge` (colour + icon + word), `Avatar` (initials fallback, label required), `EmptyState` (message and
next-step action), `Countdown` (tabular, announces every minute, not every second), `Tabs`, `Skeleton`, `ProgressMeter`.
Context: Design plan §2 principles 6 and 9; `components/Skeleton`, `ProgressBar`, `UserAvatar`, `LoadCard/Countdown.tsx`.
Steps:
  1. Components and tests (Countdown with fake timers and the dropzone time zone).
  2. Replace `NoAccess` from U1.1 with `EmptyState`.
Acceptance criteria (cloud VM):
  - Client checks.
Acceptance criteria (owner, real device):
  - none
Out of scope: domain components (U3).
Risk / rollback: additive.
Size: M
Fixes: none

### U2.5 — Add the component gallery
Status: done
Repo: client
Depends on: U2.2, U2.3, U2.4
Branch: modernise/u2-5-gallery
Goal: `/__gallery` (dev and CI builds only) renders every `app/ui` component in every state; Playwright screenshots it
in the `full` project.
Context: Design plan §8 "Gallery".
Steps:
  1. Route registered only when `environment` is `local`/`development` or `EXPO_PUBLIC_GALLERY=1` (set in the CI web
     export); sections per component; query params `?scheme=`, `?density=`, `?industry=`.
  2. `e2e/gallery.spec.ts` (`@gallery`): axe and layout per section; screenshots only in the `full` project.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@gallery` (no screenshots in tier 2).
Acceptance criteria (owner, real device):
  - none
Out of scope: baselines (Checkpoint U2.8).
Risk / rollback: dev-only route.
Size: M
Fixes: none

### U2.6 — Re-base inputs and layout wrappers on app/ui
Status: done
Repo: client
Depends on: U2.2, U2.3
Branch: modernise/u2-6-inputs
Goal: `app/components/input/*` and `layout/DialogOrSheet*` become thin adapters over `app/ui` (call sites unchanged);
`Themed.tsx`, `layout/Screen.tsx`, `layout/ScrollableScreen.tsx` are deleted.
Context: Design plan §1.5 (25 importers of `TextField`, 12 of `DialogOrSheet`, 10 of `ScrollableScreen`).
Steps:
  1. Re-implement the input components on `app/ui` keeping their props; delete the `.web.tsx` variants that become
     redundant.
  2. Move the 10 `ScrollableScreen` users to `ScreenContainer`/`FormColumn`; delete the legacy files.
  3. Add `app/components/input/**` and `app/components/layout/**` to the converted list.
Acceptance criteria (cloud VM):
  - Client checks, web export; tier 2 (all tags).
Acceptance criteria (owner, real device):
  - none
Out of scope: screen redesigns.
Risk / rollback: revert.
Size: L
Fixes: none

### U2.7 — Convert the forms
Status: done
Repo: client
Depends on: U2.6, U0.6
Branch: modernise/u2-7-forms
Goal: `app/forms/**` meets the definition of done (no Paper, tokens only, strings through `t()`), except the manifest
forms that U3.7 rebuilds.
Context: `app/forms/*` (about 40 files; `forms/manifest_user` and `forms/manifest_group` are excluded).
Steps:
  1. Convert form by form; pinned save button in the `Overlay` footer (answers the P5.4 owner question).
  2. Strings into `common.json` under `forms.<form>.*`.
  3. Add `app/forms/**` (minus the two manifest forms) to the converted list.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@setup @profile`.
Acceptance criteria (owner, real device):
  - none
Out of scope: manifest forms.
Risk / rollback: revert.
Size: L
Fixes: none

### U2.8 — Checkpoint U2
Status: done
Repo: client
Depends on: U2.1, U2.2, U2.3, U2.4, U2.5, U2.6, U2.7
Branch: modernise/u2-8-checkpoint
Goal: Tier 3 passes; gallery baselines exist for all variants.
Context: Client UI work (test tiers).
Steps:
  1. Tier 3 web; create gallery baselines (4 widths × 2 schemes × skydiving and generic × 200 % text where relevant).
  2. `client:docs/verification/ui-u2.md`; owner list: each form on a small Android phone with the keyboard open; overlays
     with TalkBack and VoiceOver.
Acceptance criteria (cloud VM):
  - Tier 3 web passes.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

### U3.1 — Add Android emulator flows with Maestro
Status: todo
Repo: client
Depends on: U2.8
Branch: modernise/u3-1-android-ui
Goal: A workflow builds an Android release APK against a backend in the same job, boots an emulator and runs Maestro
flows at font scale 1.0 and 2.0, on demand and weekly.
Context: Design plan §8, D-UI10 as amended (checkpoints and weekly only). No emulator in the cloud VM: flows are written
here and run in GitHub Actions. The emulator reaches the host at `10.0.2.2`; release builds block cleartext HTTP.
Steps:
  1. Add an `android-ci` environment: endpoint `http://10.0.2.2:5000/graphql` in `build/constants.ts`, and for that
     environment only `expo-build-properties` `android.usesCleartextTraffic: true`.
  2. Workflow `android-ui.yml` (`workflow_dispatch`, weekly): backend via the `ui-env` action (without the web export),
     `EXPO_ENV=android-ci npx expo prebuild --platform android --clean`, `./gradlew assembleRelease` (debug keystore),
     `reactivecircus/android-emulator-runner` (API 35, `pixel_7` and a 360×640 dp custom profile), install Maestro
     (pin the current CLI version; record it in the workflow), run `e2e/maestro/*.yaml` twice (font scale via
     `adb shell settings put system font_scale 2.0`), upload screenshots and JUnit.
  3. Flows: `login.yaml`, `board.yaml` (board renders, open a load, back), using `testID`s or accessibility labels.
  4. Document in `e2e/README.md`.
Acceptance criteria (cloud VM):
  - Client checks; one `android-ui` run on the branch passes (attach the run URL). If the build exceeds 60 minutes or the
    emulator cannot boot on the hosted runner, set `blocked (Android CI: <reason>)` and continue the batch without it.
Acceptance criteria (owner, real device):
  - none
Out of scope: iOS (owner device checks only).
Risk / rollback: separate workflow; revert.
Size: L
Fixes: none

### U3.2 — Add the board data layer and the newBoard flag
Status: todo
Repo: client
Depends on: U1.6, U2.8, P7.17, UB.3
Branch: modernise/u3-2-board-data
Goal: `useBoard(date)` gives the loads of a day in a stable order with live updates and change highlights; the
`newBoard` preference switches between the old and new board, load and picker screens.
Context: Design plan §2 principle 8, §12 (drag versus live updates); load subscriptions in `app/api/crud/subscriptions/*`;
`loads(from:, to:)` and future dates (P7.17); `Load.vehicles` (P7.9), `Load.crew` (P7.10), `Load.destinations` (P7.8),
`calledAt` (UB.3).
Steps:
  1. `app/features/board/useBoard.ts`: loads for the chosen date (today by default, operator time zone), ordered by
     state (open → boarding → departed → completed/cancelled) then load number; changed rows flagged for 600 ms;
     `freeze()`/`unfreeze()` to hold order while the user drags or edits.
  2. `newBoard` in the preferences store: default `true` when no previous preferences exist (new install), `false`
     otherwise; toggle in Account. Route switch in the manifest stack.
  3. Tests with a mocked subscription push (order stable, highlight set, frozen order honoured) and a future date.
Acceptance criteria (cloud VM):
  - Client checks.
Acceptance criteria (owner, real device):
  - none
Out of scope: UI (U3.3).
Risk / rollback: flag off restores the old board.
Size: M
Fixes: none

### U3.3 — Build the load card and the board layouts
Status: todo
Repo: client
Depends on: U3.2
Branch: modernise/u3-3-board
Goal: The new board: one column on compact, list plus selected load on medium, load columns with a completed strip on
expanded; a date switcher; each `LoadCard` shows state, the call countdown as its largest numeral, its vehicles, places
meter, crew chips per crew role and the next action; a read-only conditions strip when the operator has the
winds-aloft module.
Context: Mockups "Desktop: manifest board", "Phone: load"; design plan §2 principles 1–2, §4 table; GENERALISATION §7
and §14 (`VehicleIcon`, `CrewChip` per crew role); the old board screen, load cards and weather board (paths after
P7.4/P7.6). Replaces P7.19 for these screens.
Steps:
  1. Domain components in `app/features/board/`: `LoadCard`, `VehicleIcon` (kind → glyph per GENERALISATION §14),
     `CrewChip` (one per crew role, per vehicle for vehicle-scoped roles), `PlacesMeter` (capacity from carrying
     vehicles minus seat-occupying crew), `DestinationLabel` (`formatDestination`), `ConditionsStrip` (module
     `winds_aloft`; wind at altitude, jump-run heading, ground temperature, "Update" opens the existing weather screen
     until U5.7).
  2. `BoardScreen` with the three layouts and the date switcher (today by default; future dates per P7.17); content
     max width 1600, horizontal scroll past three columns; empty state with "Create load" for `createLoad`.
  3. All strings through `t()` with the operator's terms; convert `app/features/board/**`.
  4. Playwright `@board`: layout at 390 and 1440, create a load, countdown visible, a generic operator's board shows no
     skydiving words; Jest per component.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: actions (U3.4), load screen (U3.5).
Risk / rollback: behind `newBoard`.
Size: L
Fixes: none

### U3.4 — Make the next load action one tap
Status: todo
Repo: client
Depends on: U3.3
Branch: modernise/u3-4-load-actions
Goal: Call (from the operator's call schedule, plus custom), cancel call, depart, complete and cancel load are a
primary button on the card and on the load screen, chosen by state; the speed dial is gone from the new screens.
Context: Load states `open, boarding, departed, completed, cancelled` (P7.5) with the template's state terms;
`operator.callScheduleMinutes` (P7.11; empty means depart directly); the old action button (P7.11 made it generate
calls from the schedule); `updateLoad`/`finalizeLoad` (or their renamed successors).
Steps:
  1. `useLoadActions(load)`: state machine and permitted actions; destructive ones (cancel load, complete with
     unconfirmed places) confirm in a dialog; errors as `Toast`; required crew missing blocks departure with the
     reason (P7.10 validation message).
  2. Primary action button plus a `Menu` for the rest on card and load header; calls show the schedule as a
     `Segmented` choice and "Custom…" (`NumberField`, minutes).
  3. Tests per transition; Playwright `@board`: call → cancel call → call → depart → complete, each transition ≤ 2
     interactions; an operator with an empty call schedule departs directly.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: haptics (U6.2).
Risk / rollback: behind `newBoard`.
Size: M
Fixes: none

### U3.5 — Build the new load screen
Status: todo
Repo: client
Depends on: U3.4
Branch: modernise/u3-5-load-screen
Goal: Load screen with the call card (countdown largest, "called at", destinations), crew by role, places grouped by
vehicle when the load has several, guests shown under their escort, groups bracketed, eligibility and prepaid badges,
free places collapsed into one row, sticky actions on compact.
Context: Mockup "Phone: load"; GENERALISATION §7 (vehicles, crew), §10 (escorts), §17 item 3 (prepaid); P7.9
(`Load.vehicles`, `Slot.loadVehicle`), P7.15 (`escort_slot_id`), P7.16 (`Membership.eligibility`), P7.17 (`Slot.prepaid`);
the old load screen, header, info grid, slots table and slot cards (design plan §1.5; paths after P7.4/P7.6).
Steps:
  1. `LoadHeader`, `PlaceRow` (avatar, name, certification and activity type, `EligibilityBadge`, prepaid badge, group
     colour border, destination when per slot), `VehicleSection` (when the `multi_vehicle` module is on), `EscortGroup`,
     `FreePlaces` ("N free places", opens the picker in U3.7); crew editing per crew role in a `Menu`.
  2. Swipe-to-delete stays on native as a shortcut; every place also has a menu ("Edit", "Move to…", "Take off").
  3. Strings through `t()`; convert `app/features/load/**`.
  4. Playwright `@load`: a full load at 390 shows the call card and first places without scrolling; a two-vehicle load
     for a generic operator; layout invariants; axe.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@load @board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: picker (U3.7), move (U3.9).
Risk / rollback: behind `newBoard`.
Size: L
Fixes: none

### U3.6 — Checkpoint U3a (board and load)
Status: todo
Repo: client
Depends on: U3.3, U3.4, U3.5
Branch: modernise/u3-6-checkpoint
Goal: Tier 3 (web and Android) passes for the new board and load screen.
Context: Client UI work (test tiers).
Steps:
  1. Tier 3 web; if U3.1 is `done`, add the flows `board-actions.yaml` (call, depart, land) and `load.yaml` and run
     `android-ui`; update baselines for board and load.
  2. `client:docs/verification/ui-u3a.md`; owner list: run a real load with the new board on a tablet at the desk and on
     a phone (flag on).
Acceptance criteria (cloud VM):
  - Tier 3 passes (web; Android when U3.1 is done).
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: M
Fixes: none

### U3.7 — Build the member picker with one-tap defaults
Status: todo
Repo: client
Depends on: U3.5
Branch: modernise/u3-7-picker
Goal: Adding a returning member to a load takes at most 3 interactions: search, pick (pre-filled from their last
slot), confirm; eligibility and its reason show before the tap, with a "Fix" action.
Context: Mockup "Phone: add a jumper"; design plan §2 principles 3–4, §4 ("Adding a person"); P7.16
`Membership.eligibility(loadId)` (list-safe) and `slotEligibility` (full check for the chosen combination); UB.3
`lastSlot`; P7.8 destinations (per-slot scope), P7.14 equipment per required kind; the old member autocomplete and
manifest form (paths after P7.4/P7.6); `createSlot`.
Steps:
  1. `MemberPicker`: search field (focus on open; `/` focuses on web), filters (Everyone, Ready, Here today, Group),
     `MemberPickerRow` (avatar, name, certification/load count/credit line or the blocking reason, `EligibilityBadge`,
     "Fix" opens the member's profile section). Presentation: full screen on compact, side panel on medium, roster panel
     on expanded (stays open beside the columns).
  2. Selected member expands to the defaults card (ticket, activity type, destination when per slot, one equipment item
     per required kind with its inspection or service date, body mass, price) from `lastSlot`; `slotEligibility`
     checks the combination; "Change…" opens the full manifest form rebuilt on `app/ui` (replaces the old manifest
     form).
  3. Footer: "Add <name> to <load>" and the credit sentence built with `formatMoney` and terms.
  4. Copy for each eligibility code in `common.json`.
  5. Playwright `@picker`: add a member to a load in ≤ 3 interactions at 390 and 1440 (count `press`/`fill` calls); a
     blocked member shows the reason and cannot be added unless `allowManifestBypass` and staff.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@picker @load`.
Acceptance criteria (owner, real device):
  - none
Out of scope: groups and escorts (U3.8).
Risk / rollback: behind `newBoard`.
Size: L
Fixes: none

### U3.8 — Add groups and escorted guests to the picker
Status: todo
Repo: client
Depends on: U3.7
Branch: modernise/u3-8-groups
Goal: The picker has a group mode (select several, one group number, `createSlots`) and books guests with an escort
for tickets that require one (tandem, try dive, child with adult: n guests per escort up to `escort_capacity`); groups
and escorts show on the load.
Context: P7.15 (`requires_escort`, `escort_capacity`, guest fields), GENERALISATION §10; the old group dialog and form
(BUG-066), design plan §13 questions 4–5 (no persistent group concept).
Steps:
  1. "Group" toggle in the picker: multi-select rows, shared defaults with per-person overrides, one confirm.
  2. Escort tickets: the defaults card asks for the guests (name, body mass, date of birth when limits apply) and the
     escort (members holding the ticket's escort crew role or qualification).
  3. Move the old group and manifest-form code under `app/legacy/` while the old board still needs it (removed in U6.4).
  4. Playwright `@picker`: group of 4 in ≤ 6 interactions; a tandem (1 guest, 1 escort); a try dive (3 guests, 1 escort).
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@picker`.
Acceptance criteria (owner, real device):
  - none
Out of scope: persistent groups.
Risk / rollback: behind `newBoard`.
Size: M
Fixes: BUG-066 (on the new screens)

### U3.9 — Move people between loads and vehicles, and drag on the web
Status: todo
Repo: client
Depends on: U3.7
Branch: modernise/u3-9-move
Goal: "Move to…" on every place (all platforms; loads and, on multi-vehicle loads, vehicles) and, on web at expanded
width, drag between load columns and from the roster panel onto a load, with a keyboard alternative; live updates
never move a row under the pointer.
Context: the old drag-and-drop web files (`@dnd-kit/core` 6.3.1), `moveSlot` (between vehicles since P7.9);
`useBoard().freeze()` from U3.2; design plan §12 risk 3.
Steps:
  1. `MoveToSheet`: open loads (and their vehicles) with free places; disabled targets say why.
  2. Web: `@dnd-kit/core` `DndContext` around the board; draggable places and roster rows, droppable load columns; on
     drag start `freeze()`, on drop or cancel `unfreeze()`; keyboard sensor (Space to pick up, arrows, Space to drop)
     with live-region announcements.
  3. Playwright `@move`: drag a place between columns at 1440; move via sheet at 390; a scripted subscription push
     during a drag does not reorder the dragged column.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@move`.
Acceptance criteria (owner, real device):
  - none
Out of scope: drag on native.
Risk / rollback: behind `newBoard`.
Size: L
Fixes: none

### U3.10 — Checkpoint U3b (picker and move)
Status: todo
Repo: client
Depends on: U3.6, U3.7, U3.8, U3.9
Branch: modernise/u3-10-checkpoint
Goal: Tier 3 passes for the whole manifest flow; the exit criterion of design plan Phase 3 is shown by a test.
Context: Client UI work (test tiers); design plan §10 Phase 3 exit criterion.
Steps:
  1. Tier 3 web; `android-ui` with `picker.yaml`, `group.yaml`, `move.yaml`; baselines for picker and roster.
  2. `client:docs/verification/ui-u3b.md`; owner list: one staffed day on the new board (flag on) at a dropzone or a
     realistic rehearsal: record time to manifest returning jumpers and any blocking issue.
Acceptance criteria (cloud VM):
  - Tier 3 web and Android pass.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: M
Fixes: none

---

### U4.1 — Build the Today screen
Status: todo
Repo: client
Depends on: U3.10
Branch: modernise/u4-1-today
Goal: Members land on Today: next load card (state, countdown, load summary, take-me-off when permitted), a "Ready"
checklist with fixes, credit, today's loads; crew members also see their assignments for the day.
Context: Mockup "Phone: my day"; design plan §2 principle 7, §5.1; UB.1 (members without `deleteSlot` see "Ask the
manifest desk to change your booking"); P7.16 `Membership.eligibility` (codes for membership, certification,
qualification, equipment inspection and service, credits, limits); P7.10 crew assignments.
Steps:
  1. `app/features/today/`: `NextLoadCard`, `ReadyChecklist` (one row per eligibility check with a fix action),
     `CreditCard`, `TodayLoads`, `DutiesCard` (the member's crew assignments today).
  2. Today is the first destination for roles without `createUserSlot`.
  3. Playwright `@today`: as a fun jumper, find my load and take myself off (self-manifest on); with it off the action is
     replaced by the desk note.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@today`.
Acceptance criteria (owner, real device):
  - none
Out of scope: booking (U4.2).
Risk / rollback: revert.
Size: L
Fixes: none

### U4.2 — Let members book themselves from Today and the board
Status: todo
Repo: client
Depends on: U4.1
Branch: modernise/u4-2-self-booking
Goal: "Book a jump" on Today and on open loads uses the picker in self mode (defaults from the member's last slot, UB.3);
hidden when the dropzone switched off self-manifesting.
Context: U3.7 picker; UB.1 permissions; `createSlot`.
Steps:
  1. Picker `mode: 'self'` (no search, the member's defaults, confirm); entry points on Today and the load card.
  2. Playwright `@today`: book in ≤ 3 interactions; setting off → no entry points.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@today @board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: booking ahead (D6).
Risk / rollback: revert.
Size: M
Fixes: none

### U4.3 — Build the Wallet
Status: todo
Repo: client
Depends on: U4.1
Branch: modernise/u4-3-wallet
Goal: Members see balance, money held for booked jumps, history and top-up in one place; staff keep the Money area.
Context: `screens/authenticated/user/orders`, `order_receipt`, `transactions`, `forms/credits/*`, `createOrder`; the
credits chip removed in U1.4.
Steps:
  1. `app/features/wallet/`: balance card, held amount (sum of the member's slots on open loads; compute client-side
     from existing fields unless the API has it), history list with receipts, top-up (existing order flow if the
     dropzone allows it; otherwise "Top up at the manifest desk").
  2. Replace the member's routes; staff routes stay for Money.
  3. Playwright `@wallet`.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@wallet`.
Acceptance criteria (owner, real device):
  - none
Out of scope: online card top-up (C2.5 adds it to this screen).
Risk / rollback: revert.
Size: M
Fixes: none

### U4.4 — Turn notifications into the Inbox and route pushes
Status: todo
Repo: client
Depends on: U4.1
Branch: modernise/u4-4-inbox
Goal: Inbox lists notifications with read state and actions (rig-inspection request → inspection screen; call → load);
tapping a push opens the right screen (Today for calls and manifest changes).
Context: `screens/authenticated/notifications/*`, notification types in `backend:app/models/notification.rb:23-26`
(after P7.5: `boarding`, `user_manifested`, `credits_updated`, the equipment inspection request, …), push data
`{ notificationId, type }`.
Steps:
  1. `app/features/inbox/` with `ListRow`s, unread badge on the tab, mark read.
  2. Push response handler maps `type` to a route; tests per type.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@inbox`.
Acceptance criteria (owner, real device):
  - none
Out of scope: new notification types.
Risk / rollback: revert.
Size: M
Fixes: none

### U4.5 — Checkpoint U4
Status: todo
Repo: client
Depends on: U4.1, U4.2, U4.3, U4.4
Branch: modernise/u4-5-checkpoint
Goal: Tier 3 passes for the member experience.
Context: Client UI work (test tiers).
Steps:
  1. Tier 3 web; `android-ui` with `today.yaml` (find my load, take myself off, book) at font scale 2.0; baselines.
  2. `client:docs/verification/ui-u4.md`; owner list: VoiceOver and TalkBack pass over Today, booking and Wallet; a push
     for a call opens Today.
Acceptance criteria (cloud VM):
  - Tier 3 web and Android pass.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

### U5.1 — Build People
Status: todo
Repo: client
Depends on: U4.5
Branch: modernise/u5-1-people
Goal: A searchable, filterable people list (table on expanded; rows elsewhere) with role, licence, eligibility summary,
credit and last jump; staff can add a walk-in member and act on a row (manifest on…, add credit).
Context: `screens/authenticated/users/*` (UserListScreen), `forms/create_user/Dialog.tsx` (`createGhost`); UB.3.
Steps:
  1. `app/features/people/`: list with search (`/` on web), filters (role, Ready/Expiring/Blocked), sort; row actions in
     a `Menu`.
  2. "Add member" opens the ghost form (converted).
  3. Playwright `@people`.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@people`.
Acceptance criteria (owner, real device):
  - none
Out of scope: bulk actions.
Risk / rollback: revert.
Size: L
Fixes: none

### U5.2 — Redesign the member profile
Status: todo
Repo: client
Depends on: U5.1, UB.2
Branch: modernise/u5-2-profile
Goal: Profile = summary and eligibility with fixes, then Loads (with empty state), Funds, Certifications and
qualifications (P7.13), Equipment (P7.14; staff can add and edit, UB.2), Membership (role and expiry with unambiguous dates); one scroll on phones, two columns on expanded.
Context: `screens/authenticated/user/profile/*`, `user/equipment/*`, `user/rig_inspection`; design plan §1.8 item 5.
Steps:
  1. Rebuild the screens on `app/ui`; staff actions gated by permission.
  2. Playwright `@profile`: own profile and a member's profile as staff.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@profile`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### U5.3 — Regroup Setup and add the Rules page
Status: todo
Repo: client
Depends on: U5.1
Branch: modernise/u5-3-setup
Goal: Setup has three groups (Operations, People and access, Business) per design plan §5.2; Rules holds the
eligibility settings, "Members can book themselves on loads" (UB.1), the call schedule (P7.11), units and
currency (P7.12) and the template's optional modules (P7.7).
Context: `configuration/settings_menu/SettingsMenuScreen.tsx`, `forms/dropzone/DropzoneForm.tsx`.
Steps:
  1. `SetupScreen` with grouped `ListRow`s; side-by-side list and detail on expanded.
  2. `RulesScreen`: switches with helper text; call schedule editor (chips, descending, at most 6, may be empty);
     Modules (switches for optional modules; locked ones shown disabled).
  3. Playwright `@setup`: switch off self-manifesting, then as `jumper1` the board shows the desk note.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@setup @today`.
Acceptance criteria (owner, real device):
  - none
Out of scope: the setup lists (U5.5).
Risk / rollback: revert.
Size: M
Fixes: none

### U5.4 — Checkpoint U5a (people and setup)
Status: todo
Repo: client
Depends on: U5.1, U5.2, U5.3
Branch: modernise/u5-4-checkpoint
Goal: Tier 3 passes for People, profile and Setup.
Context: Client UI work (test tiers).
Steps:
  1. Tier 3 web; `android-ui` `profile.yaml`; baselines.
  2. `client:docs/verification/ui-u5a.md`; owner list: run a day from the office with self-manifesting off (add a
     walk-in, record their rig, credit, manifest, move, land).
Acceptance criteria (cloud VM):
  - Tier 3 web and Android pass.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

### U5.5 — Put the setup lists on one pattern
Status: todo
Repo: client
Depends on: U5.4
Branch: modernise/u5-5-setup-lists
Goal: Vehicles, tickets (with `DestinationSelect`), extras, destinations, crew roles, equipment kinds, operator equipment,
inspection forms and accepted certification bodies use `ResourceList` + `ResourceForm`
(side panel on expanded, sheet on compact).
Context: `configuration/aircrafts`, `ticket_types`, `extras`, `dropzone_rigs`, `rig_inspection_template`.
Steps:
  1. `app/ui/patterns/ResourceList.tsx`, `ResourceForm.tsx`; convert the five screens.
  2. Playwright `@setup`: create and edit one of each.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@setup`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### U5.6 — Rebuild permissions as a matrix
Status: todo
Repo: client
Depends on: U5.4
Branch: modernise/u5-6-permissions
Goal: Roles × permissions matrix on expanded (grouped by `access.yml` groups, sticky headers), per-role list on compact;
per-user acting permissions on the member profile.
Context: `configuration/permissions/PermissionsScreen.tsx` (440 lines), `grantPermission`/`revokePermission`/`updateRole`.
Steps:
  1. Matrix with `Switch` cells (role `switch`, names "<role>: <permission>"), optimistic update with rollback on error.
  2. Playwright `@permissions`: grant and revoke.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@permissions`.
Acceptance criteria (owner, real device):
  - none
Out of scope: new permissions.
Risk / rollback: revert.
Size: L
Fixes: none

### U5.7 — Move conditions editing into a panel
Status: todo
Repo: client
Depends on: U5.4
Branch: modernise/u5-7-conditions
Goal: For operators with the `winds_aloft` module, "Update" on the conditions strip opens a panel or sheet with temperature, winds aloft table and a numeric jump-run
heading (0–359°); the navy wizard and the jump-run dial are removed.
Context: D-UI7; `dropzone/weather_conditions/*`, `components/input/jump_run_select/*` (~700 lines),
`components/forms/weather_conditions/*`.
Steps:
  1. `ConditionsPanel` with `NumberField`s (units via `formatQuantity`), wind rows add/remove.
  2. Move the winds-aloft screens and components into `app/features/skydiving/` (GENERALISATION §14).
     Delete the wizard screens and `jump_run_select/*`; redirect their routes to the board with the panel open.
  3. Playwright `@conditions`.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@conditions @board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: winds-aloft feed changes.
Risk / rollback: revert.
Size: M
Fixes: none

### U5.8 — Convert the remaining screens
Status: todo
Repo: client
Depends on: U5.4
Branch: modernise/u5-8-remaining
Goal: Reports (Overview charts fixed or replaced), Platform (the cross-operator overview for administrators),
Money (staff transactions), daily log, login, sign-up, recovery,
dropzone select and the wizards meet the definition of done.
Context: `overview/*` (`statistics/LoadsByDay.web.tsx` hatch), `configuration/transactions`, `master_log`,
`screens/unauthenticated/*`, `screens/wizards/*`.
Steps:
  1. Convert each; charts: keep the library if it renders on web after a fix, otherwise simple bar lists built from
     tokens.
  2. If this exceeds a session, split at the unauthenticated screens and add U5.8b before the checkpoint.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@login @reports @setup`.
Acceptance criteria (owner, real device):
  - none
Out of scope: new reports.
Risk / rollback: revert.
Size: L
Fixes: none

### U5.9 — Checkpoint U5b
Status: todo
Repo: client
Depends on: U5.5, U5.6, U5.7, U5.8
Branch: modernise/u5-9-checkpoint
Goal: Tier 3 passes for the whole app; axe has no serious or critical violations left (the baseline file is empty).
Context: Client UI work (test tiers); design plan §7.
Steps:
  1. Tier 3 web and Android; baselines; empty `e2e/axe-baseline.json` (fix what remains or add a task).
  2. `client:docs/verification/ui-u5b.md` with the UI debt table (Paper imports should be near zero).
Acceptance criteria (cloud VM):
  - Tier 3 passes; axe baseline empty.
Acceptance criteria (owner, real device):
  - none (listed for U6.5)
Out of scope: none.
Risk / rollback: none.
Size: M
Fixes: none

---

### U6.1 — Remove react-native-paper
Status: todo
Repo: client
Depends on: P7.20
Branch: modernise/u6-1-remove-paper
Goal: No Paper or `react-native-paper-dates`; date and time pickers built on tokens; the Paper theme adapter deleted.
Context: UI debt table; design plan §3.3.
Steps:
  1. Replace remaining Paper uses (except under `app/legacy/`, removed in U6.4); `DateField`/`TimeField` (native:
     `@react-native-community/datetimepicker` via `npx expo install` if not present, or `@expo/ui` pickers if their
     web story is adequate by then; web: `<input type="date|time">`).
  2. `yarn remove react-native-paper react-native-paper-dates`; delete the adapter in `app/theme/palette.ts`.
Acceptance criteria (cloud VM):
  - Client checks, web export; tier 2 (all tags).
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### U6.2 — Add motion, haptics and reduced motion
Status: todo
Repo: client
Depends on: P7.20
Branch: modernise/u6-2-motion
Goal: Motion tokens applied (sheet, panel, highlight), haptics on call, depart and land (native), reduced motion honoured.
Context: Design plan §3.2 Motion; Reanimated `ReduceMotion`, `expo-haptics`.
Steps:
  1. Apply; tests that reduced motion disables animations (mock).
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@board`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### U6.3 — Measure and tune performance and bundle size
Status: todo
Repo: client
Depends on: U6.1
Branch: modernise/u6-3-performance
Goal: Bundle and startup are no worse than the U0.4 baseline; the board with 6 loads × 14 seats and live updates keeps
60 fps on web and re-renders only changed cards.
Context: U0.4 baseline; date-fns still in some files.
Steps:
  1. Remove date-fns (luxon only); FlashList for People if the seed scaled to 500 members is slow; memoise board rows.
  2. Record numbers in `client:docs/verification/ui-u7.md`.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 `@board @people`; numbers recorded.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### U6.4 — Retire the old board
Status: todo
Repo: client
Depends on: U6.1
Branch: modernise/u6-4-retire-old-board
Goal: The `newBoard` flag and `app/legacy/` are removed.
Context: Do this only after the owner's U3.10 staffed-day check is recorded as passed in `client:docs/verification/ui-u3b.md`;
otherwise set `owner-check (staffed day on the new board, U3.10)`.
Steps:
  1. Remove the flag, the old screens and their tests.
Acceptance criteria (cloud VM):
  - Client checks; tier 2 (all tags).
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: S
Fixes: none

### U6.5 — Verify the UI modernisation
Status: todo
Repo: client
Depends on: U6.2, U6.3, U6.4
Branch: modernise/u6-5-verify
Goal: Tier 3 passes on the final app, and the owner has run the collected device checks.
Context: Phase gate; owner lists in `client:docs/verification/ui-u0.md` … `ui-u5b.md`.
Steps:
  1. Tier 3 web and Android; final baselines.
  2. Merge the owner lists into a "UI" section of `client:docs/SMOKE_TEST.md`; write `client:docs/verification/ui-final.md`.
Acceptance criteria (cloud VM):
  - Tier 3 passes; CI green on `staging`.
Acceptance criteria (owner, real device):
  - The "UI" section of `client:docs/SMOKE_TEST.md` on an iPhone, an Android phone, a small Android phone at font scale
    2.0, an iPad in both orientations and a desktop browser, light and dark.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 7 — Generalisation

Goal: OpenManifest serves any operator that manifests people onto loads (skydiving, scuba, snorkel, whale watching,
fishing charters, parasailing, whitewater rafting, scenic flights, hot-air balloons, gliding, tandem paragliding,
safari, bus tours). Operators pick an industry template at creation; the template switches on modules and seeds
editable presets; code and API use industry-neutral names; users see their industry's words. Design, diagrams and the
rename map: [GENERALISATION.md](reference/GENERALISATION.md) (§n below refers to it).

Rules for every Phase 7 task (from D5, D7, D9 and D11):

- **Rename, do not alias.** There is no production data and no released client. Change tables, columns, models, GraphQL
  types, fields, arguments and client code in place. No deprecated mirrors, no backfills, no dual columns. Migrations
  are still reversible (`rename_table`, `rename_column`, `change_table`). **`Load` keeps its name** (owner, D5): `loads`,
  `load_number`, `load_date`, `createLoad`, `loadCreated` and the client's load screens stay.
- **Rebuild the dev seed instead of migrating data.** Every task that changes the schema updates `db/seeds/dev_baseline.rb`
  and the factories so `bin/rails db:reset` works; the P0.5 smoke data must still log in and show a manifest board.
- **Backend and client renames merge in pairs.** A backend rename task (P7.3, P7.5) changes the API; the client keeps
  passing its checks against its own schema copy (`app/api/openmanifest.graphql`) until the paired client task syncs
  it. The owner merges each pair together, backend first.
- **No industry branches.** Behaviour depends on `operator.module?(…)` and operator settings, never on the industry slug.
  From P7.7, `bin/check-industry-branches` (backend) and `yarn check:industry-branches` (client) fail on
  `industry ==`, `industry?(`, `skydiving?`, `isSkydiving` and similar outside `config/industries/**`.
- **Mechanical renames use a codemod.** Rename tasks run the replacements listed in `config/vocabulary.yml` with the
  script added in P7.1 (`bin/rename-vocabulary --group <name>`), then fix what the script cannot (grammar in comments,
  file moves, ambiguous words). Review the diff for false positives before committing.
- **No customer booking or online payment here.** Those belong to Phases B and C (designs in `docs/features/`, D9,
  D11). Phase 7 only builds the manifest-side seam they use (P7.17, GENERALISATION §17).
- **Order with Phase U** (see Execution order): stage A (P7.1–P7.6) and P7.7 run before the UI foundations; P7.8–P7.17
  run after them and before the screens are rebuilt; P7.22, P7.20 and P7.21 run after Phase U's screens. P7.18 and
  P7.19 are superseded by U0.6 and U3; P7.22 lost its navigation step to U1.1.
- **Screens Phase U rebuilds get the smallest change.** In P7.8–P7.17, client steps that touch the board, load screen,
  load and manifest forms, slots table, profile or the setup lists make the smallest change that keeps those screens
  working and tested; U3–U5 rebuild them for the generic model. New screens (destinations, crew roles, equipment
  kinds, accepted certification bodies) are built on `app/ui` per "Client UI work".

### P7.1 — Add the vocabulary map, the old-terms check and the rename codemod
Status: done
Repo: both
Depends on: U0.2
Branch: modernise/p7-1-vocabulary
Goal: The rename map exists in machine-readable form; both repos can count old terms and apply renames per group.
Context: GENERALISATION §3 (table). The check runs in report mode until P7.20 makes it enforcing.
Steps:
  1. backend: `config/vocabulary.yml` with one entry per row of §3 that changes a name: `group` (`tenant`, `vehicle`,
     `certifications`, `equipment`, `settings`, `permissions`), `old` and `new` in every case form used (snake, camel,
     Pascal, kebab, plural), and `allow` globs (`config/industries/skydiving/**`, `app/**/skydiving/**`,
     `app/features/skydiving/**`, `db/migrate/**`, `docs/**`, `CHANGELOG.md`). `Load` is not in the map. Client copy at
     `config/vocabulary.yml`, synced by `scripts/sync-vocabulary.mjs` from the backend checkout (same mechanism as
     `scripts/sync-schema.mjs`).
  2. `bin/check-vocabulary` (backend, Ruby, uses `git grep -n -w`) and `scripts/check-vocabulary.mjs` (client,
     `yarn check:vocabulary`): print a count per old term and per directory; `--enforce` exits 1 on any hit outside
     `allow`. CI runs it without `--enforce` and writes the table to the job summary.
  3. `bin/rename-vocabulary --group <group> [--dry-run]` (backend) and `scripts/rename-vocabulary.mjs` (client): apply the
     group's word-boundary replacements to file contents and `git mv` files and directories whose names contain an old
     term. Skips `allow` paths. Specs/tests for the replacement function (case forms, word boundaries, unrelated words
     containing an old term are untouched).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass; `bin/check-vocabulary` and `yarn check:vocabulary` exit 0 and the baseline
    counts are in the PR body; `bin/rename-vocabulary --group tenant --dry-run` lists files without changing them.
Acceptance criteria (owner, real device):
  - none
Out of scope: applying renames (P7.3 onwards).
Risk / rollback: tooling only; revert.
Size: M
Fixes: none

### P7.2 — Drop legacy columns and deprecated API fields
Status: done
Repo: both
Depends on: P7.1
Branch: modernise/p7-2-drop-legacy
Goal: Nothing kept only for data migration or old clients remains.
Context: D7 = (b). P6.23 kept the float money columns (`dropzones.credits`, `dropzone_users.credits`, `orders.amount`,
`ticket_types.cost`, `extras.cost`, `transactions.amount`) and deprecated GraphQL fields (`grep -rn deprecation_reason
app/graphql`: `Slot.cost`, `DropzoneUser.credits`, `SellableItem.cost`, `TicketType.cost`, `Extra.cost`, `Order.amount`,
`Transaction.amount`) and still accepts float inputs. `planes.is_deleted`, `ticket_types.is_deleted`, `extras.is_deleted`
are superseded by `discarded_at`.
Steps:
  1. backend: migration dropping those columns (reversible with types); remove the deprecated fields and float inputs;
     remove the `is_deleted` reads (verify with `git grep is_deleted` that nothing else uses them).
  2. client: remove the deprecated fields from documents and fragments (`check:graphql` must pass against the new
     schema after `scripts/sync-schema.mjs`); regenerate code.
Acceptance criteria (cloud VM):
  - Backend rspec green; `grep -rn deprecation_reason app/graphql` prints nothing; client checks, `check:graphql`, web
    export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: renames.
Risk / rollback: revert both; the down migration restores empty columns.
Size: M
Fixes: none

### P7.3 — Rename the tenant in the backend: Dropzone → Operator, DropzoneUser → Membership
Status: done
Repo: backend
Depends on: P7.2
Branch: modernise/p7-3-operator-backend
Goal: The backend says `Operator` and `Membership` everywhere; behaviour is unchanged.
Context: GENERALISATION §3 rows "Dropzone" and "DropzoneUser". Affects tables `dropzones`, `dropzone_users`, every
`dropzone_id`/`dropzone_user_id` column and foreign key, `Dropzones::Configuration`, `StateMachines::DropzoneState`,
interactions `Setup::Dropzones::*`, `Users::JoinDropzone`, GraphQL types `Dropzone*`, `DropzoneUser*`, root fields
`dropzone`, `dropzones`, `dropzoneUser`, `dropzoneUsers`, mutations `createDropzone`, `updateDropzone`, `deleteDropzone`,
`joinDropzone`, `updateDropzoneUser`, arguments `dropzone`/`dropzoneId`, `users.dropzone_count`, counter caches,
`master_log_entry/dropzone*.rb`, specs, factories, seeds.
Steps:
  1. Migration: `rename_table :dropzones, :operators`, `rename_table :dropzone_users, :memberships`, rename every
     `dropzone_id` → `operator_id`, `dropzone_user_id` → `membership_id`, `users.dropzone_count` → `operator_count`;
     rename indexes and foreign keys so their names match.
  2. `bin/rename-vocabulary --group tenant`, then fix the remainder by hand; rename files and constants (Zeitwerk must
     load: `bin/rails zeitwerk:check`).
  3. Regenerate `schema.graphql` (P1.8 drift check) and the annotate comments.
  4. Rename the request specs and client-operation fixtures from Phase 1 to the new operation names; they must pass
     with only name changes in their expectations.
Acceptance criteria (cloud VM):
  - `bin/rails zeitwerk:check`, rspec and rubocop green; `bin/rails db:reset` works; `bin/check-vocabulary` shows 0
    `tenant` hits outside allowed paths.
Acceptance criteria (owner, real device):
  - none
Out of scope: client (P7.4); user-visible words (they come from terminology in P7.18–P7.20).
Risk / rollback: revert; the down migration renames back. The client is broken against this API until P7.4 merges, so
the owner merges P7.3 and P7.4 together.
Size: L
Fixes: none

### P7.4 — Rename the tenant in the client
Status: done
Repo: client
Depends on: P7.3
Branch: modernise/p7-4-operator-client
Goal: The client uses the renamed API and says `operator`/`membership` in code; routes are neutral.
Context: GENERALISATION §3; `app/providers/dropzone/*`, `screens/limbo/dropzone_select/*`, `screens/wizards/dropzone_wizard/*`,
`useSession` (`currentDropzoneId`), `app/screens/routes.tsx` paths `/dropzone/...`, `forms/dropzone*`, all `.gql`
documents.
Steps:
  1. `scripts/sync-schema.mjs` against the P7.3 branch; `scripts/rename-vocabulary.mjs --group tenant`; fix the rest;
     regenerate code.
  2. Routes drop the `dropzone` prefix: `/dropzone/manifest` → `/manifest`, `/dropzone/load/:loadId` → `/loads/:loadId`,
     dropzone selection → `/operators/select`; directory `screens/authenticated/dropzone/` →
     `screens/authenticated/manifest/`. Update the Playwright suite's paths (`e2e/`, U0.1).
  3. The persisted session key `currentDropzoneId` becomes `currentOperatorId` (no migration needed: no released app).
  4. Visible copy stays as it is ("Dropzone"); it moves to terms in P7.19/P7.20.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and web smoke test (against the P7.3 backend) pass; the remaining `tenant`
    hits in `yarn check:vocabulary` are visible copy only (listed in the PR).
Acceptance criteria (owner, real device):
  - none
Out of scope: vehicle and participant names (P7.6).
Risk / rollback: revert together with P7.3.
Size: L
Fixes: none

### P7.5 — Rename vehicles, guests, activity types and the daily log in the backend
Status: done
Repo: backend
Depends on: P7.4
Branch: modernise/p7-5-vehicle-backend
Goal: `Plane` → `Vehicle`, `Passenger` → `Guest`, `JumpType` → `ActivityType`, `MasterLog` → `DailyLog`, `exit_weight` →
`body_mass_kg`, `jump_count` → `load_count`; aviation-only load states and setup permissions renamed; behaviour
unchanged. `Load` is not renamed.
Context: GENERALISATION §3 and §7 (state names). Tables `planes`, `passengers`, `jump_types`, `master_logs`; columns
`loads.plane_id` → `loads.vehicle_id` (replaced by `load_vehicles` in P7.9), `slots.jump_type_id`, `slots.passenger_id`,
`planes.max_slots`/`min_slots` → `vehicles.capacity`/`min_capacity`, `master_logs.dzso_id` → `duty_officer_id`,
`exit_weight` on `users`, `slots`, `passengers` → `body_mass_kg`, `users.jump_count`, `memberships.jump_count` →
`load_count`, `users.plane_count` (drop if unused); `StateMachines::LoadState` states (`boarding_call` → `boarding`,
`in_flight` → `departed`, `landed` → `completed`) and events (`dispatch` → `call`, `take_off` → `depart`,
`mark_as_landed` → `complete`), notification types; permissions in `config/seed/access.yml` (`createPlane` →
`createVehicle`, `actAsDZSO` → `actAsDutyOfficer`, `actAsRigInspector` → `actAsEquipmentInspector`, …);
`MasterLogEntry::*`; the `Aircraft` GraphQL class names; mutations `createPlane`/`updatePlane`/`deletePlane`; query
`planes`, `jumpTypes`.
Steps:
  1. Migration with `rename_table`/`rename_column`; `vehicles.kind` string not null default `"aircraft"` (the default is
     dropped in P7.7 when templates set it); enum values keep their integers.
  2. `bin/rename-vocabulary --group vehicle` and `--group permissions`; fix the remainder; Zeitwerk check.
  3. Regenerate `schema.graphql`; rename Phase 1 specs/fixtures.
Acceptance criteria (cloud VM):
  - Zeitwerk check, rspec and rubocop green; `bin/rails db:reset` works; vocabulary check shows 0 `vehicle`/`permissions`
    hits outside allowed paths.
Acceptance criteria (owner, real device):
  - none
Out of scope: crew columns (`pilot_id`, `gca_id`, `load_master_id` stay until P7.10); `ticket_types.altitude` (P7.8);
rigs and federations (P7.13, P7.14); weather (stays, owned by the winds-aloft module).
Risk / rollback: revert; merge with P7.6.
Size: L
Fixes: none

### P7.6 — Rename vehicles, guests, activity types and the daily log in the client
Status: done
Repo: client
Depends on: P7.5
Branch: modernise/p7-6-vehicle-client
Goal: The client uses the P7.5 API; code names follow §3.
Context: `configuration/aircrafts/*`, `forms/aircraft/*`, `components/chips/PlaneChip.tsx`, `JumpTypeChipSelect.tsx`,
`JumpTypeSelect.tsx`, master log screens, passenger fields in the manifest forms, `calculateWingLoading.ts` (reads
`bodyMassKg`), load state enums in `ActionButton.tsx` and `Countdown.tsx`, user wizard `Wingloading.tsx`.
Steps:
  1. Sync schema; `scripts/rename-vocabulary.mjs --group vehicle --group permissions`; fix the rest; regenerate code.
  2. Directory names: `configuration/aircrafts/` → `configuration/vehicles/`, `configuration/master_log/` →
     `configuration/daily_log/`, `forms/aircraft/` → `forms/vehicle/`.
  3. Update the Playwright suite (`e2e/`) and the client tests.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and web smoke test pass; the remaining `vehicle` hits in the vocabulary
    check are visible copy only (listed in the PR).
Acceptance criteria (owner, real device):
  - none
Out of scope: visible copy.
Risk / rollback: revert together with P7.5.
Size: L
Fixes: none

### P7.7 — Add industry templates with inheritance, modules and the presets engine
Status: done
Repo: backend
Depends on: P7.6
Branch: modernise/p7-7-industry-templates
Goal: Every operator has an immutable `industry` and a `modules` set; `createOperator` requires an industry and seeds
the operator from the template's presets; templates can extend abstract bases; skydiving behaviour is unchanged; a
`generic` template exists.
Context: GENERALISATION §2, §5 (file layout, inheritance diagram, YAML), §6 (sequence). Today
`Setup::Dropzones::Access::CreateDefaults` (now `Setup::Operators::…`) seeds roles from `config/seed/access.yml`,
`global.yml` seeds jump types and APF licences, the configuration concern holds default settings,
`UserRole::DEFAULT`/`DEFAULT_LICENSED` hard-code `student`/`fun_jumper`, the rig-inspection template default is in
`rig_inspection.rb:38-106`, and `Setup::Demo::DataGenerator` builds skydiving demo data.
UB.1's `allow_self_manifest` setting moves into the template defaults with the other settings.
Steps:
  1. Migration: `operators.industry` string not null (no default), `operators.modules` jsonb not null default `{}`;
     drop the `vehicles.kind` default; `time_zone` not null without default.
  2. `config/industries/schema.json`; abstract bases `_aviation`, `_water`, `_ground` (crew role names, units, daily-log
     template, call schedule per §5 matrix); `skydiving` (extends `_aviation`) and `generic`, each with `template.yml`,
     `presets.yml`, `catalogue.yml`, `locales/en.yml`. Skydiving content moves from `access.yml` (roles), `global.yml`,
     the settings defaults, the role defaults and the default inspection form. `access.yml` keeps only the permission list.
  3. `Industry` registry (`app/models/industry.rb`): loads templates at boot, resolves `extends` (maps deep-merge, lists
     replace, one level of `extends` per file, cycles rejected), validates against the schema; `Industry.selectable`
     excludes names starting with `_`; `Industry.fetch(slug)`, `#modules`, `#terminology(locale)`, `#units`, `#presets`,
     `#booking` (validated, consumed by the booking plan). `Operator#module?(name)`, `#terminology`, `#units`,
     `#call_schedule_minutes` merge template defaults with `operators.modules`/`settings`.
  4. `Presets::Apply` interaction: roles and permissions (with `default`/`default_certified` flags replacing the
     constants), ticket types, extras, vehicle kinds, enabled activity types, inspection form templates. Each later
     Phase 7 task extends it for its own records. `Setup::Operators::Create` takes `industry` and composes
     `Presets::Apply` inside its transaction.
  5. GraphQL: `industries` query (`slug`, `name`, `description`, `icon`, `base`, `modules`, `presetSummary`),
     `Industry` enum (selectable only), `Operator.industry`, `.modules`, `.terminology` (JSON), `.units`;
     `createOperator(industry: Industry!)`; `updateOperator(modules:)` for optional modules (a module the template marks
     `locked` cannot be turned off).
  6. Seeds: catalogues are loaded from each template's `catalogue.yml`; the dev seed creates its operator with
     `industry: "skydiving"`; the demo generator takes the industry (skydiving and generic data for now).
  7. `bin/check-industry-branches` added to CI.
  8. Specs: every selectable template resolves and validates; a child template overrides a base key and inherits the
     rest; presets apply idempotently; a skydiving operator created through `createOperator` has exactly the roles,
     permissions and settings it had before this task (compare with a fixture captured on the parent commit); a
     `generic` operator can create a vehicle, a load and a slot.
Acceptance criteria (cloud VM):
  - Rspec and rubocop green; `bin/check-industry-branches` exits 0; `bin/rails db:reset` works.
Acceptance criteria (owner, real device):
  - none
Notes (done): `createOperator` now requires `industry` and `time_zone` (and `federation` only for industries with the
certifications module), so the client's create-operator wizard fails against this API until P7.23 adds the industry step.
`Operator.timezone` and the Brisbane fallback are gone; `slots.activity_type` is required only when the operator has
the `activities` module. `UserRole.default_licensed` keeps its name until the certification rename in stage B.
Out of scope: client wizard (P7.23); other templates (P7.24–P7.30).
Risk / rollback: revert.
Size: L
Fixes: none

### P7.8 — Add destinations
Status: done
Repo: both
Depends on: P7.7
Branch: modernise/p7-8-destinations
Goal: Altitude becomes one kind of destination; loads and slots reference destinations according to the template's
destination scope.
Context: GENERALISATION §4 (ER, scope note) and §12. `ticket_types.altitude` (int feet); client
`components/input/dropdown_select/AltitudeSelect.tsx` (hard-coded 4000/14000), `slots_table/UserRow.tsx` ("14k"),
`configuration/ticket_types/*`, daily log altitude.
Steps:
  1. backend: `destinations` (`operator_id`, `kind` string `altitude|site|route|section`, `name`, `altitude_m`
     decimal(10,2), `location` jsonb, `stops` jsonb array, `min_certification_rank` int null, `discarded_at`);
     `load_destinations` (`load_id`, `destination_id`, `position`, unique per load/position); `slots.destination_id`;
     `ticket_types.default_destination_id`; drop `ticket_types.altitude`. Validation: kind allowed by the operator's
     `destinations.kinds`; per-slot scope requires `slots.destination_id` (defaulted from the ticket type), per-load scope
     requires ≥ 1 load destination when the load is called.
  2. Presets: skydiving destinations "Hop n Pop" 1219.2 m and "Full altitude" 4267.2 m; ticket types point at them.
  3. GraphQL: `Destination` type, `operator.destinations`, `createDestination`/`updateDestination`/`archiveDestination`
     (`updateOperator` permission), `Load.destinations`, `Slot.destination`, `TicketType.defaultDestination`; load
     create/update accept `destinationIds`.
  4. client: destinations configuration screen; `DestinationSelect` replaces `AltitudeSelect`; the ticket type form uses
     it; the load form shows ordered destinations when the scope is per load; altitude display converts metres to feet
     with the "14k" format until units land (P7.12 replaces the formatter).
  5. Specs/tests for both scopes.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: boarding at intermediate stops (GENERALISATION §16).
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.9 — Allow several vehicles on one load
Status: done
Repo: both
Depends on: P7.8
Branch: modernise/p7-9-multi-vehicle
Goal: A load uses one or more vehicles, each carrying participants or supporting (tug, chase vehicle, shuttle);
capacity is the sum of the carrying vehicles; slots can be assigned to a carrying vehicle.
Context: GENERALISATION §1 (rafting, safari, bus tours, gliding, balloons), §7 "Vehicles". `loads.vehicle_id` (from
P7.5), slot counting and capacity locks from P6.10, client load card, load form vehicle picker.
Steps:
  1. backend: `load_vehicles` (`load_id`, `vehicle_id`, `role` `carrying|support`, `position`; unique per load/vehicle;
     at least one carrying); `slots.load_vehicle_id` null; drop `loads.vehicle_id`. Capacity = sum of carrying
     capacities; a slot with a vehicle counts against that vehicle as well (same locked counter pattern as P6.10). A
     vehicle cannot be on two overlapping open loads (`dispatch_at` within an operator setting, default 0 = only one
     open load per vehicle at a time).
  2. `multi_vehicle` module: off → API and UI accept exactly one carrying vehicle and no support vehicles (today's
     behaviour); on → any number. Skydiving template: off. `generic` and `_ground`: on.
  3. GraphQL: `Load.vehicles: [LoadVehicle!]!`, `Slot.loadVehicle`; load inputs take `vehicles: [{vehicleId, role}]`;
     `moveSlot` can move between vehicles of a load.
  4. client: single-vehicle picker unchanged when the module is off; with it on, a vehicle list in the load form and
     slots grouped by vehicle on the load screen.
  5. Specs/tests: capacity sum; per-vehicle capacity; concurrent last-seat specs from P6.10 still pass.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: automatic distribution of participants across vehicles.
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.10 — Generalise load crew
Status: done
Repo: both
Depends on: P7.9
Branch: modernise/p7-10-crew-roles
Goal: Pilot, GCA and load master become crew roles defined per operator, assigned per load or per vehicle; required
roles are validated from data.
Context: GENERALISATION §7. `loads.pilot_id`, `gca_id`, `load_master_id`; `validates :gca`, `:pilot` in the load model;
permissions `actAsPilot`, `actAsGCA`, `actAsLoadMaster`; client `PilotChip`, `GcaChip`, `LoadMasterChip`, load form.
Steps:
  1. backend: `crew_roles` (`operator_id`, `key`, `name`, `scope` `load|vehicle`, `required`, `occupies_slot`,
     `permission`, `position`), `load_crew_assignments` (`load_id`, `load_vehicle_id` null, `crew_role_id`,
     `membership_id`; unique per load/vehicle/role); drop the three columns. Validation: every required load-scoped role
     assigned once per load, every required vehicle-scoped role once per vehicle the role applies to (carrying, or the
     kinds listed on the role), each by a member holding the role's permission; capacity counts crew with
     `occupies_slot`. Presets seed skydiving `pilot` (vehicle, required), `gca` (load, required), `load_master` (load).
  2. GraphQL: `CrewRole`, `operator.crewRoles`, `Load.crew: [LoadCrewAssignment!]!`, load inputs take
     `crew: [{crewRoleId, membershipId, loadVehicleId}]`; CRUD for crew roles (`updateOperator` permission).
  3. client: one `CrewChip` per crew role, per vehicle for vehicle-scoped roles (replaces the three chips); the load form
     is generated from `crewRoles`.
  4. Specs/tests (required role missing, wrong permission, a guide per raft on a three-raft load, capacity with
     seat-occupying crew).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: duty officer on the daily log (stays a single column).
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.11 — Make the call schedule configurable
Status: done
Repo: both
Depends on: P7.10
Branch: modernise/p7-11-call-schedule
Goal: Call buttons and countdowns come from `operator.callScheduleMinutes` (template default, editable).
Context: client `screens/authenticated/manifest/load/ActionButton.tsx` (hard-coded 20/15/10), `Countdown.tsx`;
notification copy.
Steps:
  1. backend: `settings.call_schedule_minutes` (array of positive integers, descending, max 6, may be empty) with the
     template default; GraphQL `Operator.callScheduleMinutes: [Int!]!`; `updateOperator` accepts it.
  2. client: ActionButton generates call actions from it (none when empty: depart directly); operator settings screen
     edits it.
  3. Specs/tests.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert both.
Size: S
Fixes: none

### P7.12 — Store SI units and display the operator's units
Status: done
Repo: both
Depends on: P7.11
Branch: modernise/p7-12-units
Goal: Quantities are SI in the database and API and shown in the operator's unit system; each operator has a
currency.
Context: GENERALISATION §12. The operator currency moved here from COMMERCE C1.1 so the wizard (P7.23) and the
client formatters (U0.6) have it before Phase C. Remaining non-SI storage after P7.5/P7.8: weather `exit_spot_miles`, `offset_miles`, winds
JSON speeds (knots), `temperature`; canopy size (ft², moves into equipment attributes in P7.14).
Steps:
  1. backend: `Units` module (`to_si`, `from_si`, supported units per quantity); rename/convert weather columns to
     `exit_spot_m`, `offset_m`, winds speeds to m/s (`*_mps`), `temperature_c`; `settings.units` merged with the template's
     `units`; GraphQL `Operator.units` (`{altitude, depth, distance, mass, speed, temperature}`) and SI fields only;
     `operators.currency` (ISO 4217, not null; `AUD` for existing rows and the dev seed; set at creation from P7.23),
     GraphQL `Operator.currency`, `updateOperator` accepts it until the operator has payments (guard added in C1.1).
  2. client: complete `formatQuantity` and add `parseQuantity` and `compactAltitude` in `app/i18n/format.ts` (U0.6);
     every display/input of mass, altitude, depth, distance, speed and temperature goes through them; `formatMoney`
     uses `operator.currency`; the operator settings screen picks units and currency.
  3. Unit tests for every conversion pair; backend spec for the weather calculations in SI.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass; a skydiving operator still
    sees "14k" and kg.
Acceptance criteria (owner, real device):
  - none
Out of scope: per-user unit preferences.
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.13 — Generalise certifications
Status: done
Repo: both
Depends on: P7.12
Branch: modernise/p7-13-certifications
Goal: Federations, licences and qualifications become certification bodies, levels and qualifications with comparable
ranks and optional expiry; operators accept several bodies; requirements are minimum ranks or qualifications.
Context: GENERALISATION §8. Tables `federations`, `licenses`, `licensed_jump_types`, `user_federations`,
`qualifications`, `user_federation_qualifications`; `operators.federation_id`, `users.license_id`,
`memberships.license_id`, `users.apf_number`; `Federations::ApfSync`, `Federations::AssignUser`; mutation
`joinFederation`; client `forms/user_wizard/steps/Federation*.tsx`, `License.tsx`, `FederationCardSelect.tsx`,
`LicenseCardSelect.tsx`, operator wizard `Federation` step.
Steps:
  1. backend: rename to `certification_bodies` (+ `industry`, `verification_provider`), `certification_levels`
     (+ `rank` int not null, `equivalence_key`), `permitted_activities`, `user_certifications` (`number` replaces
     `license_number`; + `verified_at`, `verified_by_id`), `user_qualifications` (+ `number`; `expires_at` exists);
     a body may have no levels (qualifications only); new `operator_certification_bodies`; drop
     `operators.federation_id`, `users.license_id`, `users.apf_number`; `memberships.license_id` →
     `memberships.certification_level_id` only if still used, else drop. `bin/rename-vocabulary --group certifications`.
  2. `ticket_types.min_certification_rank`, `ticket_types.required_qualification_id`, `extras.required_qualification_id`;
     activity-type gating keeps using permitted activities. APF sync becomes `Certifications::Providers::Apf`, chosen by
     `verification_provider`.
  3. Catalogue: skydiving `catalogue.yml` gets ranks (No licence 0, Student 10, A 20 … E 60) and `equivalence_key`s.
  4. GraphQL: `CertificationBody`, `CertificationLevel`, `UserCertification`, `Qualification`, `UserQualification`;
     `operator.certificationBodies` (accepted), `certificationBodies(industry:)`; `joinCertificationBody` replaces
     `joinFederation`; `addUserQualification`.
  5. client: wizard steps list only the operator's accepted bodies; a qualification step (number, expiry) when the
     operator's tickets or extras require qualifications; operator settings edit accepted bodies; renames.
  6. Specs: rank comparison across two bodies; expired qualification fails; APF provider unchanged behaviour.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: catalogues for other industries (template tasks); automated verification for non-APF bodies.
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.14 — Generalise equipment
Status: done
Repo: both
Depends on: P7.13
Branch: modernise/p7-14-equipment
Goal: Rigs become equipment items of operator-defined kinds with validated attributes, service dates and inspections
with a validity; a slot can use several items; skydiving specifics live in the skydiving namespace.
Context: GENERALISATION §9. `rigs` (`rig_type`, `canopy_size`, `repack_expires_at`, `maintained_at`, `pack_value`,
`packing_card`, `make`, `model`, `serial`, `is_public`), `rig_inspections`, `operators.rig_inspection_template_id`,
`slots.rig_id`, `packs`, `Slot#wing_loading`, `operator.student_rigs`/`tandem_rigs`; settings `require_equipment`,
`require_rig_inspection`, `require_reserve_in_date`; client `screens/authenticated/user/equipment/*`,
`configuration/rigs/*`, `forms/rig*`, `user_wizard/steps/Rig.tsx`, `ReserveRepack.tsx`, `AskForRig.tsx`,
`calculateWingLoading.ts`. UB.2 lets staff with `updateUser` manage members' personal rigs; keep that rule on the
renamed equipment mutations.
Steps:
  1. backend: `equipment_kinds` (`operator_id`, `key`, `name`, `attribute_schema` jsonb, `service_interval_days`,
     `inspection_form_template_id`, `inspection_valid_days` null = until changed, `required_by` jsonb of ticket type and
     activity ids); `equipment` (renamed `rigs`: `kind_id`, `ownership` enum personal/operator, `user_id`, `operator_id`,
     `name`, `make`, `model`, `serial`, `attributes` jsonb validated by the kind schema, `service_due_at`);
     `equipment_inspections`; `slot_equipment` replaces `slots.rig_id`; settings renamed
     (`require_equipment_inspection`, `require_equipment_in_service`). Skydiving `rig` kind schema: `rig_type`,
     `canopy_size_m2` (shown ft²), `pack_value`; `repack_expires_at` → `service_due_at`.
  2. `app/models/skydiving/` (or `app/services/skydiving/`): wing loading, packing jobs (`packs`), student/tandem rig
     scopes; reachable only with the `equipment` module and a `rig` kind.
  3. GraphQL: `EquipmentKind`, `Equipment`, `EquipmentInspection`, `Slot.equipment`; mutations renamed
     (`createEquipment`, …); `availableEquipment(kind:)` replaces `availableRigs`.
  4. client: generic equipment screens driven by the kind's attribute schema (string/integer/decimal/enum/date fields);
     skydiving components (`WingLoading`, rig wizard steps) move to `app/features/skydiving/`; the manifest form picks
     one item per required kind.
  5. Specs/tests: attribute validation, service date expiry, inspection validity of one day, two items on one slot.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: kinds for other industries (template tasks).
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.15 — Generalise escorts and guests
Status: done
Repo: both
Depends on: P7.14
Branch: modernise/p7-15-escorts
Goal: Tandem becomes "requires escort" with a configurable number of guests per escort; guests carry the same
personal fields as booking participants.
Context: GENERALISATION §10, §17 items 2 and 7. `ticket_types.is_tandem`, `slots.passenger_slot_id` (escort → guest,
1:1), `Manifest::CreateSlot` tandem branch, `guests` (renamed from `passengers` in P7.5); client manifest form passenger
fields, "Tandem Passenger:" row.
Steps:
  1. backend: `ticket_types.requires_escort` (replaces `is_tandem`), `escort_capacity` int default 1,
     `escort_crew_role_id` / `escort_qualification_id` null; `slots.escort_slot_id` on the guest slot (replaces
     `passenger_slot_id` on the escort slot); `guests` gets `email`, `phone`, `date_of_birth`, `emergency_contact`.
     Validation: escort slot on the same load (and same vehicle when assigned), escort qualified, guests per escort ≤
     capacity. A child-with-adult ticket is an escort ticket whose escort needs no qualification.
  2. GraphQL and client: the manifest form books n guests with one escort; the slots table groups guests under their
     escort.
  3. Specs/tests: 1:1 tandem unchanged; 1:4 try dive; capacity exceeded; child with adult.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.16 — Add participant limits and move eligibility into module rules
Status: done
Repo: both
Depends on: P7.15
Branch: modernise/p7-16-eligibility
Goal: Manifest eligibility is computed once on the server from core and module rules, including age and body-mass
limits; the client shows the server's result instead of re-implementing it.
Context: GENERALISATION §11, §17 item 6. Server: `Manifest::CreateSlot`, `Slot` validations,
`Operators::Configuration`. Client: `app/hooks/useManifestValidator.ts`. The booking plan's `participant_rules` use
`min_age` and `max_body_mass_kg`.
Steps:
  1. backend: `users.date_of_birth`; `ticket_types.participant_limits` jsonb (`min_age`, `max_age`,
     `min_body_mass_kg`, `max_body_mass_kg`); `activity_types.participant_limits` (same keys); `vehicles.max_payload_kg`;
     `group_limits` on ticket types (`max_group_body_mass_kg`, `max_group_size`) for flight groups (`slots.group_number`).
  2. `Eligibility::Rule` interface (`applies?(operator)`, `check(context) → Result(code, ok, message_key)`), core rules
     (capacity, membership, credits unless prepaid, double manifesting) and module rules (certification rank /
     qualification, equipment present / inspected / in service, limits: age, body mass, group mass and size, load mass ≤
     sum of carrying vehicles' payload; escort); `Eligibility.check(…)` used by slot creation, moves and edits; bypass
     handling unchanged.
  3. GraphQL `slotEligibility(loadId, membershipId | guest, ticketTypeId, extraIds, equipmentIds, loadVehicleId,
     groupNumber): [EligibilityResult!]!`.
  4. `Membership.eligibility(loadId: ID): Eligibility!`, a list-safe summary for pickers and the Today checklist
     (formerly UB.3): `ready` plus one entry per applicable rule (`code`, `ok`, `status` `PASS`/`EXPIRING`/`FAIL`/
     `NOT_REQUIRED`, `expiresAt`, `amountCents`), `EXPIRING` within 14 days; dataloader-backed, with an N+1 spec for a
     members list selecting it.
  5. client: `useManifestValidator` calls `slotEligibility` (debounced) and renders results; local rule code removed;
     date of birth in the profile wizard when the limits module is on.
  6. Specs: one per rule; module off → rule absent; missing date of birth with an age limit fails with its own code;
     `eligibility.ready` agrees with slot creation for every rule.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: recency and waiver rules (GENERALISATION §16).
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.17 — Add the manifest-side booking seam
Status: todo
Repo: both
Depends on: P7.16
Branch: modernise/p7-17-booking-seam
Goal: Loads can be scheduled on future dates and carry actual times; slots can be prepaid; templates declare how
bookings reach the manifest. Nothing booking-specific is built.
Context: GENERALISATION §7 "Dates", §17 (contract items 1–7). Phase B (design `docs/features/BOOKING_PLAN.md`): B3.2 check-in to manifest and BD7 (b) session ↔ load. Today loads are listed per
operator-local day and the board shows today only; tandem slots skip the wallet through
`Transactions::Purchase#refund_if_tandem`.
Steps:
  1. backend: `loads.departed_at`, `loads.completed_at` set by the state machine; `load_date` may be in the future
     (validation: not in the past when created); `loads(from:, to:)` query by date range; load numbers per
     `load_date` as today.
  2. `slots.prepaid` boolean default false: no wallet charge on creation or completion; replaces the tandem special
     case with a prepaid flag set for escort tickets that were charged to the guest's order (behaviour for tandems
     unchanged, proven by the existing payment specs); GraphQL `Slot.prepaid`, `CreateSlotInput.prepaid` (permission
     `createPrepaidSlot`, granted to the roles that hold `createUserSlot` today).
  3. Templates: `booking.manifest_link` (`checkin` | `load`) validated by the schema; skydiving `checkin`, generic
     `load`; exposed as `Industry.booking { manifestLink }`.
  4. client (smallest change, Phase 7 rules; U3.3 builds the real one): date picker on the manifest board (today by default, operator time zone from P6.20); creating a load for
     another date; prepaid badge on slots.
  5. Specs/tests: future load listing; prepaid slot not charged on completion; reopening a completed load clears
     `completed_at`.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: booking tables, sessions, availability and payments (booking and commerce plans).
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.18 — Add i18n to the client with operator terminology
Status: superseded (by U0.6)
Repo: client
Depends on: P7.17
Branch: modernise/p7-18-i18n
Goal: The client has i18next with `common` and `terms` namespaces; `terms` come from the current operator.
Context: GENERALISATION §13. Libraries: `i18next`, `react-i18next`, `expo-localization` (`npx expo install`),
`eslint-plugin-i18next` (latest versions at the time of the task).
Steps:
  1. `app/i18n/index.ts`: init with the device language, fallback `en`, `en/common.json`, `en/terms.json` (generic
     template words as fallback).
  2. `useOperatorTerms()`: on operator change, `i18n.addResourceBundle(lng, 'terms', operator.terminology, true, true)`.
  3. Convert the tab labels, drawer and settings menu (proof of wiring); tests switching between a skydiving and a
     generic operator.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: converting all strings (P7.19, P7.20).
Risk / rollback: revert.
Size: M
Fixes: none

### P7.19 — Convert manifest and load screens to translated terms
Status: superseded (by U3.3–U3.9)
Repo: client
Depends on: P7.18
Branch: modernise/p7-19-i18n-manifest
Goal: All user-visible strings under `app/screens/authenticated/manifest/**` and the load, slot and manifest components
use `t()`; `i18next/no-literal-string` is on for those directories.
Context: GENERALISATION §13.
Steps:
  1. Replace literals with keys in `common.json`; industry words via `terms:` keys, including load state names
     (`terms:state.departed` → "In flight" for aviation templates).
  2. Enable `i18next/no-literal-string` (mode `jsx-text-only`) for the converted directories in `eslint.config.js`.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; smoke screenshots for the skydiving operator show the same English
    copy as before.
Acceptance criteria (owner, real device):
  - none
Out of scope: other directories (P7.20).
Risk / rollback: revert.
Size: L
Fixes: none

### P7.20 — Convert the remaining screens and enforce the vocabulary check
Status: todo
Repo: both
Depends on: P7.22
Branch: modernise/p7-20-i18n-rest
Goal: Every client screen uses `t()`; the lint rule covers `app/**`; the vocabulary check is enforcing in both repos.
Context: Phase U converted every screen it rebuilt (U0.6, U2.7, U3–U5) and P7.22 isolated the skydiving features;
this task converts what is left and enforces. P7.1 check.
Steps:
  1. client: as P7.19 for every remaining directory; rule on `app/**` (excluding tests and `app/api/**`).
  2. both: CI runs the vocabulary check with `--enforce`; fix or allow-list every remaining hit (allow-list entries need
     a one-line reason in `config/vocabulary.yml`).
  3. client: Playwright `@terms` (full project only): as a generic operator, render the main routes and fail on any
     word from the skydiving vocabulary (jumper, aircraft, altitude, dropzone, rig, …).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export and web smoke test pass; both vocabulary checks pass with `--enforce`.
Acceptance criteria (owner, real device):
  - none
Out of scope: translations into other languages.
Risk / rollback: revert.
Size: L
Fixes: none

### P7.21 — Use operator terminology in server-generated copy
Status: todo
Repo: backend
Depends on: P7.20
Branch: modernise/p7-21-server-copy
Goal: Notifications, push messages, activity events and emails use Rails I18n with the operator's terms.
Context: GENERALISATION §13. Literal copy in the load state machine (`"Load ##{n} take off at …"`), `Load` model
notifications, `Activity::CreateEvent` messages in interactions, mailer views.
Steps:
  1. `config/locales/en.yml` keys with interpolation; `Operator#term(key, count:)`; replace literals ("take off" becomes
     the template's `call` wording).
  2. Spec: a skydiving operator and an operator with the terminology override `load: Trip` produce "Load #3 …" and
     "Trip #3 …".
Acceptance criteria (cloud VM):
  - Rspec green; `git grep -nE '"(Dropzone|Jumper|Plane|Aircraft)'` in `app/` prints nothing outside skydiving paths.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### P7.22 — Make navigation module-aware, replace airplane icons and isolate skydiving features
Status: todo
Repo: client
Depends on: U5.9
Branch: modernise/p7-22-module-aware-ui
Goal: Screens, tabs and menu entries show only what the operator's modules provide; skydiving-only UI lives in
`app/features/skydiving/`; vehicle icons follow the vehicle kind (D10).
Context: GENERALISATION §14 (icon mapping verified against `@expo/vector-icons` 15.0.2); D10 = (a).
Steps:
  1. Navigation already filters on modules (U1.1); add `module` to the remaining entry points (Setup groups, Account and
     profile sections) and use the `NotAvailable` state for their deep links.
  2. Move winds/jump-run screens, wing loading, packing jobs and remaining skydiving components into
     `app/features/skydiving/`.
  3. `VehicleIcon` (`kind` → icon per §14) replaces every hard-coded airplane icon (manifest tab, load cards, vehicle
     lists); the operator's template icon is used in the operator selector. Skydiving illustrations and Lottie
     animations render only when the operator's template is skydiving-based (read from `operator.industry`'s
     `illustrations` key in the template, not from the slug); others use neutral illustrations shipped in `assets/`.
  4. The user profile wizard asks only for what the modules need.
  5. Tests: a generic operator sees no equipment, certification, weather or daily-log entries and no airplane icon.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass, including a run as a generic operator with no skydiving words or
    airplane icons on screen; `git grep -n "name=\"airplane\"\|'airplane'" app/` hits only `VehicleIcon` and
    `app/features/skydiving/`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### P7.23 — Add the operator wizard with an industry picker
Status: todo
Repo: both
Depends on: P7.21
Branch: modernise/p7-23-operator-wizard
Goal: Creating an operator starts with choosing an industry; the rest of the wizard is pre-filled from the template and
the owner reviews the seeded presets.
Context: GENERALISATION §6 (sequence and steps); client `screens/wizards/operator_wizard/` (was `dropzone_wizard`).
Steps:
  1. backend: `industries` query returns a `presetSummary` (crew roles, ticket types, destinations, roles);
     `createOperator` accepts `currency`, `units`, `certificationBodyIds`.
  2. client: steps Industry (cards grouped air / water / land / other) → Name → Location and time zone → Currency and
     units → Certification bodies (if module on) → Branding → Review presets (prices, first vehicle) → Done; time zone
     and currency pre-filled from `expo-localization`.
  3. Optional modules are edited in Setup → Rules (U5.3); the wizard's review step links there. The wizard is built on
     `app/ui` (Client UI work) and replaces the old wizard frame.
  4. Web smoke test creates a `generic` operator through the wizard.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - Owner runs the wizard on a phone for skydiving and generic and confirms the steps read well.
Out of scope: further templates.
Risk / rollback: revert both.
Size: M
Fixes: none

Template tasks P7.24–P7.30 share these steps; each task lists only what differs.

- backend: `config/industries/<slug>/{template.yml,presets.yml,catalogue.yml,locales/en.yml}` extending the base named
  in GENERALISATION §5 and following its module matrix row; certification bodies, levels, qualifications and activity
  types in `catalogue.yml`; presets for roles, crew roles, vehicle kinds, ticket types (with participant limits and
  escorts), extras, destinations, equipment kinds; `booking.manifest_link` per §17. Names of certification levels,
  limits and crew roles are checked against public sources (agency course lists, operator safety pages, regulators),
  cited in the PR; preset numbers are marked as defaults to review.
- backend: the demo generator and the dev seed get one demo operator per template with staff, a vehicle (or vehicles),
  destinations and participants.
- client: anything the task names; otherwise templates are data only.
- Web smoke test: the scenario in the task, run in addition to every earlier template's scenario.
- Acceptance criteria (cloud VM) for every template task: backend rspec green; client checks, `check:graphql`, web
  export and the web smoke test (all templates so far) pass.
- Acceptance criteria (owner, real device): the owner reviews the template's screens and wording on a phone, ideally
  with an operator from that industry.
- Risk / rollback: revert both.

### P7.24 — Add the scuba and snorkel templates
Status: todo
Repo: both
Depends on: P7.23
Branch: modernise/p7-24-scuba-snorkel
Goal: A dive centre can run a two-site boat trip with certified divers, rental gear, nitrox and a try-dive guest; a
snorkel operator runs the same boat without certifications.
Context: GENERALISATION §1, §5 (scuba YAML), §8. `snorkel` extends `scuba`.
Steps:
  1. scuba catalogue: PADI, SSI, NAUI, CMAS, RAID, SDI/TDI, BSAC recreational levels with ranks and `equivalence_key`s;
     a nitrox qualification per body; dive types (fun, night, deep, wreck, drift, training). Equipment kinds BCD,
     regulator, wetsuit, cylinder. Sites with `max_depth_m` and `min_certification_rank`.
  2. snorkel: certifications off; equipment kinds mask, fins, stinger suit; children-with-adult ticket.
  3. Web smoke: create a scuba operator in the wizard; add a boat and two sites; manifest an Advanced diver, an Open
     Water diver (blocked from a 30 m site), a nitrox extra (blocked without the qualification) and a try-dive guest
     with an instructor; call, depart, complete. Create a snorkel operator and complete a load with a child and an adult.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: marine conditions, dive logs (GENERALISATION §16).
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.25 — Add the whale-watching and fishing-charter templates
Status: todo
Repo: both
Depends on: P7.24
Branch: modernise/p7-25-whale-fishing
Goal: Boat operators without certifications run route and grounds trips with a passenger list; fishing charters
check fishing licences and rent rods.
Context: GENERALISATION §1, §5. Both extend `_water`.
Steps:
  1. whale_watching: route destinations, crew skipper (required), deckhand, naturalist; adult/child/family tickets.
  2. fishing_charter: grounds destinations; a qualification-only certification body per supported jurisdiction
     ("Recreational fishing licence", with expiry) required by the adult ticket and waivable per ticket (some
     jurisdictions cover charter passengers under the operator's licence: a ticket setting, not a hard rule); rod and
     tackle equipment kinds.
  3. Daily log template `passenger_list`: names, contact, emergency contact per load, exportable as CSV.
  4. Web smoke: a whale-watching load with adults and a child, completed, passenger list exported; a fishing load where
     a passenger without a licence is blocked and then allowed on a licence-included ticket.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: catch logging.
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.26 — Add the scenic-flight and hot-air-balloon templates
Status: todo
Repo: both
Depends on: P7.25
Branch: modernise/p7-26-scenic-balloon
Goal: Scenic flight operators fly routes with weight limits; balloon operators fly from launch sites with a chase
vehicle and crew; both log flight times.
Context: GENERALISATION §1, §5, §7 (support vehicles, actual times), §11 (limits). Both extend `_aviation`.
Steps:
  1. scenic_flights: vehicle kinds helicopter and aeroplane with `max_payload_kg`; route destinations; pilot crew
     (vehicle, required); per-person `max_body_mass_kg` on tickets; flight log daily template (`departed_at`,
     `completed_at`, pilot, vehicle, passengers).
  2. hot_air_balloon: vehicle kinds balloon (carrying) and chase vehicle (support); pilot (vehicle, required on the
     balloon), chase crew (vehicle, on the chase vehicle); launch-site destinations; `min_age` and body-mass limits.
  3. Web smoke: a scenic flight where adding a passenger over the payload is blocked; a balloon load with a chase
     vehicle and crew, departed and completed, with flight times in the log.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: seat assignment by weight (GENERALISATION §16).
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.27 — Add the tandem-paragliding and parasailing templates
Status: todo
Repo: both
Depends on: P7.26
Branch: modernise/p7-27-paragliding-parasailing
Goal: Paragliding operators shuttle tandem passengers to a launch, one pilot per passenger; parasailing operators fly
solo, tandem and triple flights from a boat within per-person and per-flight limits.
Context: GENERALISATION §1, §5, §10 (escorts), §11 (group limits). `tandem_paragliding` extends `_aviation`,
`parasailing` extends `_water`.
Steps:
  1. tandem_paragliding: vehicle kind van; launch-site destinations; tandem ticket `requires_escort` 1:1 with escort
     qualification "Tandem pilot rating" (qualification of a national body or operator-issued); driver crew; equipment
     kinds wing and harness with inspections; body-mass min/max and `min_age` on the ticket; `booking.manifest_link:
     checkin`.
  2. parasailing: vehicle kind boat; crew captain and winch operator (both required); solo/tandem/triple tickets as
     flight groups (`group_number`) with `max_group_size` and `max_group_body_mass_kg`, per-person min body mass;
     harness equipment kind.
  3. Web smoke: three paragliding passengers with three pilots on one van load, a fourth blocked for lack of a pilot; a
     parasailing load where a triple flight over the group limit is blocked and accepted as a tandem plus a solo.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: flying-weather module.
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.28 — Add the gliding-club template with flight times and duration charges
Status: todo
Repo: both
Depends on: P7.27
Branch: modernise/p7-28-gliding
Goal: A gliding club runs a flying day: each load is one launch of a glider (aerotow or winch), members are charged
for the launch and for glider time by the minute, and the flying log records take-off and landing times.
Context: GENERALISATION §1, §5, §7 ("Duration charges"). Extends `_aviation`. Club model like skydiving (memberships,
wallet credits).
Steps:
  1. backend: `flight_times` module: `ticket_types.price_per_minute_cents`; on completion the slot's charge is
     `cost_cents + ceil(minutes(departed_at → completed_at)) × price_per_minute_cents` through the existing finalise
     step (wallet transaction text names both parts); a staff correction of `departed_at`/`completed_at` on a completed
     load re-computes the charge (refund or extra charge through the existing wallet transactions).
  2. Template: vehicle kinds glider (carrying, capacity 1–2), tug (support), winch (support); crew instructor (vehicle,
     glider), tug pilot (vehicle, tug, required with aerotow), winch driver (vehicle, winch), launch point controller
     (load); per-slot altitude destinations for aerotow release heights priced by ticket type; instructional flight
     ticket = escort 1:1 with instructor qualification; catalogue of national gliding bodies with licences/ratings
     (the executor picks the bodies for the owner's markets, starting with Australia's GFA, the UK's BGA and the US's
     SSA, and cites sources); glider equipment kind with daily inspection (`inspection_valid_days: 1`); call schedule
     empty; flying log daily template with launches, times and durations.
  3. client: the load card shows elapsed time while departed; staff can correct times on a completed load.
  4. Web smoke: two aerotow launches and a winch launch on one day, one instructional; durations charged; flying log
     lists all three.
Acceptance criteria (cloud VM):
  - As stated above for template tasks; plus a spec for rounding and for time corrections.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: OLC/IGC flight-log import, glider maintenance hours tracking beyond `service_due_at`.
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.29 — Add the whitewater-rafting and safari templates
Status: todo
Repo: both
Depends on: P7.28
Branch: modernise/p7-29-rafting-safari
Goal: Rafting operators send several rafts with a guide each plus a shuttle down a river section; safari operators
send several 4×4s with a ranger and tracker each.
Context: GENERALISATION §1, §5, §7 (multi-vehicle, vehicle-scoped crew). `whitewater_rafting` extends `_water`,
`safari` extends `_ground`; both use `multi_vehicle`.
Steps:
  1. whitewater_rafting: vehicle kinds raft (carrying), shuttle bus and safety kayak (support); crew raft guide
     (vehicle, raft, required), safety kayaker (vehicle, kayak), driver (vehicle, shuttle); river-section destinations
     with `grade`; `min_age` per section ticket; equipment kinds PFD, helmet, wetsuit; guide-rating qualifications for
     staff.
  2. safari: vehicle kind 4×4 (carrying); ranger (vehicle, required), tracker (vehicle); drive-sector / route
     destinations; children-with-adult and `min_age` per drive ticket.
  3. Web smoke: a rafting load with three rafts, a shuttle and a kayak, each raft with a guide, participants assigned
     to rafts, one too young for the section blocked; a safari load with two 4×4s.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: automatic assignment of participants to rafts or vehicles.
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.30 — Add the bus-tour template
Status: todo
Repo: both
Depends on: P7.29
Branch: modernise/p7-30-bus-tours
Goal: A tour operator runs routes with one or more buses, a driver per bus and a guide, manifesting passengers at the
desk; the template is ready for customer bookings once the booking plan lands.
Context: GENERALISATION §1, §5, §16, §17; D9: customer booking, timetables and payments come from the booking and
commerce plans, so in Phase 7 bus tours are staff-manifested. Extends `_ground`.
Steps:
  1. Template: vehicle kind bus (carrying); driver (vehicle, required), guide (load); route destinations with ordered
     stops; adult/child/concession tickets, children with an adult; `booking.manifest_link: load`; passenger-list daily
     log.
  2. client: route destination editor (ordered stops with names and optional times).
  3. Web smoke: tomorrow's departure created today with two buses, passengers manifested onto each, called, departed,
     completed the next day; passenger list exported.
Acceptance criteria (cloud VM):
  - As stated above for template tasks.
Acceptance criteria (owner, real device):
  - As stated above for template tasks.
Out of scope: customer booking, timetables, pickups and stop-level boarding (booking plan and GENERALISATION §16).
Risk / rollback: revert both.
Size: M
Fixes: none

### P7.31 — Verify Phase 7
Status: todo
Repo: both
Depends on: P7.1, P7.2, P7.3, P7.4, P7.5, P7.6, P7.7, P7.8, P7.9, P7.10, P7.11, P7.12, P7.13, P7.14, P7.15, P7.16, P7.17, P7.20, P7.21, P7.22, P7.23, P7.24, P7.25, P7.26, P7.27, P7.28, P7.29, P7.30, U0.6, U3.10
Branch: modernise/p7-31-verify
Goal: Generalisation is proven for every shipped template.
Context: Phase gate.
Steps:
  1. Run all backend and client checks, web export and the web smoke test for every template.
  2. Write `docs/verification/phase-7.md`; update GENERALISATION.md (what was built, what remains), the backend and client
     reference READMEs and both `diagrams.md` files to the new names.
Acceptance criteria (cloud VM):
  - All commands exit 0; CI green on `staging`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: none.
Size: M
Fixes: none

---

## Phase 8 — Release

Goal: versioned, deployable, store-ready builds of both apps on the infrastructure chosen in D1 and accounts confirmed
in D2, with production data migrated per D7.

### P8.1 — Add versioning and changelogs
Status: todo
Repo: both
Depends on: P7.31, U6.5
Branch: modernise/p8-1-versioning
Goal: Both repos use semantic versions with a changelog; the API reports its version.
Context: Client version in `package.json` (1.1.60) is the single source since P3.21; backend has no version.
Steps:
  1. backend: `config/initializers/version.rb` reads `VERSION` file (`2.0.0`); GraphQL `meta { apiVersion }` field;
     `CHANGELOG.md` (Keep a Changelog format) summarising Phases 0–7 with links to PRs.
  2. client: `package.json` version `2.0.0`; `CHANGELOG.md` likewise; settings screen shows app and API versions.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: automated release tooling.
Risk / rollback: revert.
Size: S
Fixes: none

### P8.2 — Configure EAS build and submit profiles
Status: blocked (awaiting decision D2)
Repo: client
Depends on: P8.1
Branch: modernise/p8-2-eas-profiles
Goal: `eas.json` has `development`, `preview` and `production` build profiles and `production` submit profiles for the
accounts confirmed in D2; update channels match.
Context: P3.21 config; EAS project id `1d8fa34d-2ff8-4095-ab49-29a426117a8c` (D2 may change it).
Steps:
  1. Profiles: `preview` (internal distribution, channel `preview`, `EXPO_ENV=staging`), `production` (store, channel
     `production`, `EXPO_ENV=production`, `autoIncrement: true`).
  2. Submit: iOS `ascAppId` and Apple team from D2; Android `track: internal`, service-account key path from EAS secrets
     (never committed).
  3. `npx eas-cli@latest config --profile production --platform all` output in the PR (needs network to expo.dev; if
     blocked in the VM, mark owner-check).
Acceptance criteria (cloud VM):
  - Client checks pass; `node -e "JSON.parse(require('fs').readFileSync('eas.json'))"` exits 0.
Acceptance criteria (owner, real device):
  - `eas build --profile preview --platform all` succeeds on the owner's account; preview builds install on an iPhone and an Android phone.
Out of scope: submission (P8.8).
Risk / rollback: config only.
Size: S
Fixes: none

### P8.3 — Set up owner accounts and credentials
Status: blocked (awaiting decision D2)
Repo: both
Depends on: P8.2
Branch: modernise/p8-3-accounts
Goal: A written, owner-verified record of every account and credential the release needs, stored outside the repos, with
the repos documenting only names and locations.
Context: Accounts: Apple Developer, Play Console, Expo/EAS, AppSignal (or replacement), Google Maps keys
(`GOOGLE_MAPS_*`), SMTP, APF API, Apple Sign In service id. Env var names in backend reference README §10.
Steps:
  1. Add `docs/RELEASE_ACCOUNTS.md` (backend) listing each account, the env var/EAS secret names it feeds, and who owns it — no values.
  2. Client README: EAS secrets list (names only).
Acceptance criteria (cloud VM):
  - Files exist; `git grep -nE "(sk_live|AIza[0-9A-Za-z_-]{35}|-----BEGIN)"` prints nothing in either repo.
Acceptance criteria (owner, real device):
  - Owner confirms each account exists and the listed secrets are set in EAS and in the hosting provider (D1).
Out of scope: creating accounts (owner).
Risk / rollback: docs only.
Size: S
Fixes: none

### P8.4 — Containerise and deploy the API
Status: blocked (awaiting decision D1)
Repo: backend
Depends on: P8.3
Branch: modernise/p8-4-deploy-api
Goal: The API builds into a production Docker image and deploys to the D1 host with Postgres (which also holds Solid Cable's
messages and Solid Cache's entries), object storage and the Solid Queue worker (`bin/jobs`).
Context: Rails 8.1 generates a production `Dockerfile` (`bin/rails app:update` from P2.7 may already have it); existing
`fly.toml`, `fly-production.toml` target 2023 apps. D1 recommendation: Fly.io.
Steps:
  1. `Dockerfile` from the Rails 8.1 template (Ruby 4.0.7 base `ruby:4.0.7-slim`), `bin/docker-entrypoint` runs
     `db:prepare`; `.dockerignore`.
  2. For Fly (D1 a): new `fly.toml` with `[processes] web = "bin/rails server"`, `worker = "bin/jobs"`; release command
     `bin/rails db:migrate`; health check `GET /up`. For other D1 options, the equivalent config named in D1.
  3. ActiveStorage service `amazon` (S3-compatible) in `config/storage.yml` from env vars; `config.active_storage.service`
     from `ACTIVE_STORAGE_SERVICE`.
  4. `docker build .` must succeed in the VM (Docker fallback in CLOUD_ENV §6).
Acceptance criteria (cloud VM):
  - `docker build -t openmanifest-api .` exits 0; `docker run --rm openmanifest-api bin/rails about` prints Rails 8.1 (with `SECRET_KEY_BASE_DUMMY=1`).
Acceptance criteria (owner, real device):
  - Owner deploys to staging on the D1 host; `https://<staging host>/up` returns 200; the web app logs in against it.
Out of scope: production cut-over (P8.8).
Risk / rollback: new infrastructure only.
Size: L
Fixes: none

### P8.5 — Deploy the web app
Status: blocked (awaiting decision D1)
Repo: client
Depends on: P8.4
Branch: modernise/p8-5-deploy-web
Goal: The web build deploys to the D1 web host (recommendation: GitHub Pages) for staging and production.
Context: Metro web export (`npx expo export --platform web`, output `dist/`) since P3.7; existing `openmanifest-web`
Pages repos; SPA fallback needs `404.html` = `index.html`.
Steps:
  1. Workflow `.github/workflows/web-deploy.yml`: `workflow_dispatch` with input `environment` (`staging`|`production`);
     builds with `EXPO_ENV`, copies `index.html` to `404.html`, deploys with `actions/deploy-pages@v4` (or pushes to the
     Pages repo using a deploy key secret named in RELEASE_ACCOUNTS.md).
Acceptance criteria (cloud VM):
  - Workflow YAML passes `actionlint` (latest); web export passes.
Acceptance criteria (owner, real device):
  - Owner runs the workflow for staging; the site loads on a phone browser and logs in to the staging API.
Out of scope: custom domains DNS (owner).
Risk / rollback: manual trigger only.
Size: S
Fixes: none

### P8.6 — Re-enable automated deploy workflows
Status: blocked (awaiting decisions D1, D2)
Repo: both
Depends on: P8.5
Branch: modernise/p8-6-deploy-workflows
Goal: Merges to `staging` deploy the API and web to staging and publish an EAS Update to the `preview` channel; `main`
deploys production only on a tag.
Context: P0.1 disabled push triggers (BUG-057, fixed there). This task re-enables them against the new targets.
Steps:
  1. backend: `deploy.yml` on push to `staging` (after CI success, `workflow_run`) → staging deploy; on tag `v*` → production.
  2. client: `web-deploy.yml` gets the same triggers; `eas-update.yml` publishes `eas update --channel preview` on
     `staging` and `--channel production` on tags.
  3. Delete the 2023 workflows disabled in P0.1.
Acceptance criteria (cloud VM):
  - `actionlint` passes for all workflows in both repos.
Acceptance criteria (owner, real device):
  - After merging this PR, the staging deploy runs green; a preview build picks up the EAS update.
Out of scope: none.
Risk / rollback: disable the workflows via the GitHub UI.
Size: M
Fixes: none

### P8.7 — Remove deprecated API fields and add release smoke tests to CI
Status: todo
Repo: both
Depends on: P8.1
Branch: modernise/p8-7-deprecations-smoke
Goal: Deprecated fields that no supported client uses are removed; the web smoke test runs in client CI against a backend
started in the same job.
Context: P7.2 removed the Phase 6 deprecations and Phase 7 renamed without deprecating (D5), so step 1 should find
nothing except `loginWithFacebook` if D4 removed Facebook. Only remove fields that the client at the version released in P8.8 no longer queries
(`check:graphql` proves it).
Steps:
  1. backend: list deprecated fields (`grep -rn deprecation_reason app/graphql`); remove those not used by
     `client:app/api/**/*.gql`; remove `loginWithFacebook` if D4 = (a).
  2. client CI: done by U0.2 (`web-ui-smoke` on every PR, `ui-full` on demand and weekly). Here, run `ui-full`
     against the release commit and attach the run.
Acceptance criteria (cloud VM):
  - Backend rspec green; client `check:graphql` green against the new schema; the new CI job passes on the PR.
Acceptance criteria (owner, real device):
  - none
Out of scope: dropping old database columns (P8.8).
Risk / rollback: revert.
Size: M
Fixes: none

### P8.8 — Migrate production data and submit to the stores
Status: todo
Repo: both
Depends on: P8.6, P8.7
Branch: modernise/p8-8-production-release
Goal: The production database is migrated (or created fresh per D7), and version 2.0.0 is submitted to the App Store and
Play Store.
Context: D7 = (b): there is no production data, so only the fresh-setup path applies (old money columns were dropped in
P7.2). The D7 (a) wording below is kept for reference only.
Steps:
  1. D7 (a): restore the owner-provided dump into a local throwaway database in the VM; run `bin/rails db:migrate`;
     record row counts and the output of every data migration in `docs/verification/production-migration.md`
     (no personal data in the file). D7 (b): document fresh setup with `db:seed`.
  2. Write the cut-over runbook in the same file: maintenance window, backup, migrate, smoke test, rollback (restore backup).
  3. client: `eas build --profile production` and `eas submit` instructions in the runbook (owner runs them).
Acceptance criteria (cloud VM):
  - D7 (a): migrations complete on the restored dump with no errors and counts recorded; D7 (b): `bin/rails db:setup` on an empty database.
Acceptance criteria (owner, real device):
  - Owner runs the cut-over; production `/up` 200; full `client:docs/SMOKE_TEST.md` on production builds on an iPhone
    and an Android phone; store submissions accepted for review.
Out of scope: marketing.
Risk / rollback: database backup restore per the runbook.
Size: L
Fixes: none

### P8.9 — Verify the release
Status: todo
Repo: both
Depends on: P8.1, P8.2, P8.3, P8.4, P8.5, P8.6, P8.7, P8.8
Branch: modernise/p8-9-verify
Goal: The modernisation is complete and documented.
Context: Final gate.
Steps:
  1. Run every check in both repos; record versions, test counts, audit counts in `docs/verification/release.md`.
  2. Update both reference READMEs to the released state; mark this plan as complete at the top, with links to the
     verification files; list deferred and open bugs.
Acceptance criteria (cloud VM):
  - All commands exit 0; CI green on `staging` and `main`.
Acceptance criteria (owner, real device):
  - Owner confirms the store releases are live.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase C — Commerce foundation

Goal: operators connect their own Stripe account; members top up credits online by card, Apple Pay or Google Pay; every
money movement is posted to a per-operator double-entry ledger; the platform fee (configurable per operator, free
plans supported) applies to online and offline sales; customers, sales orders, checkout, refunds, disputes and coupons
exist for Phases B and S. Design and decisions CD1–CD7: [COMMERCE_FOUNDATION](features/COMMERCE_FOUNDATION.md) (§n in
Phase C refers to it; read it through the vocabulary map, its prose predates the rename).

Rules for every Phase C task: money is integer cents in the database and API (`*Cents: Int!` fields plus the operator
`currency`); every interaction that moves money records a ledger entry with `Ledger.record!` in the same database
transaction; every new mutation has a tenant-isolation spec (P1.7 style) and an authorization spec; webhook handlers
are idempotent and have a duplicate-delivery spec; client screens follow "Client UI work".

### C1.1 — Replace the app's Money class with the money gem; tax settings
Status: todo
Repo: both
Depends on: P7.12, U5.9
Branch: feature/c1-1-money-tax
Goal: `::Money` is the money gem everywhere and the app's own class is gone; the operator currency (P7.12) becomes
immutable once used; each operator has tax settings, shown and applied correctly in the client.
Context: COMMERCE §3.1, CD5. `app/models/money.rb` (app value object, collides with the gem), `MoneyAttributes`, call sites
(`grep -rn "Money\." app lib spec`), `Transaction#notification_message`. `operators.currency` and `formatMoney` with the
operator currency exist since P7.12.
Steps:
  1. backend: add `gem "money", "~> 7.1"`; `config/initializers/money.rb` (`rounding_mode` half-up, `locale_backend
     :currency`, no default currency); delete `app/models/money.rb` and its spec (port the behaviour assertions to
     the new helpers); move `cents_of` to `MoneyAttributes.cents_of`; add `<name>_money` readers to `MoneyAttributes`
     that return `Money.new(cents, currency)` with the operator's currency; replace `to_s` call sites with `format`.
  2. Migration: `operators.tax_rate_bps` integer not null default 0, `prices_include_tax` boolean default true,
     `tax_label`, `tax_registration_number`, `legal_name`. Validation: the currency cannot change once the operator has
     payments or ledger entries (guard written now, checked against tables added later).
  3. GraphQL: `Operator.taxSettings`; `updateOperator` accepts them (permission `updateOperator`).
  4. client: tax fields in Setup → Business → Rules (U5.3 group).
  5. Specs: formatting parity with the old class for AUD (`"$12.50"`, `"-$3.00"`), currency immutability, tax maths
     table (inclusive/exclusive, rounding).
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green, rubocop clean; `test ! -e app/models/money.rb`; client checks, `check:graphql`,
    web export pass; tier 2 `@setup`.
Acceptance criteria (owner, real device):
  - none
Out of scope: ledger.
Risk / rollback: revert; the migration is additive.
Size: M
Fixes: none

### C1.2 — Ledger: double_entry, chart of accounts, journal outbox
Status: todo
Repo: backend
Depends on: C1.1
Branch: feature/c1-2-ledger
Goal: `Ledger.record!`, posting, `reverse!`, `balance` and `trial_balance` work per operator on `double_entry`, with
append-only entries.
Context: §3.2 (all of it, including the limits table).
Steps:
  1. `gem "double_entry", "~> 2.0"`; `bin/rails generate double_entry:install` (json metadata); migration for
     `ledger_entries`; DB triggers rejecting `UPDATE`/`DELETE` on `double_entry_lines` and on `ledger_entries` (except
     setting `posted_at` once).
  2. `Ledger::ChartOfAccounts` and `Ledger::PostingRules` (the two tables in §3.2) drive
     `config/initializers/double_entry.rb`: accounts per key × `SUPPORTED_CURRENCIES`, scoped by operator; transfer
     codes per posting rule.
  3. `app/models/ledger.rb`: `record!` (validation), `PostLedgerEntryJob` (lock, idempotent split into transfers),
     sweep every minute in `config/recurring.yml`, `reverse!`, `balance`, `trial_balance`, `profit_and_loss(from, to)`.
  4. Specs: valid and invalid entries (unbalanced, foreign currency, unknown account, zero line), posting splits multi-line
     entries correctly, double posting is a no-op, an undeclared transfer raises, reversal, trial balance zero, triggers
     block edits, entry recorded inside a rolled-back transaction leaves nothing behind.
Acceptance criteria (cloud VM):
  - Backend rspec green; rubocop clean.
Acceptance criteria (owner, real device):
  - none
Out of scope: posting existing flows (C1.3).
Risk / rollback: new tables only.
Size: L
Fixes: none

### C1.3 — Record the wallet flows in the ledger and reconcile daily
Status: todo
Repo: both
Depends on: C1.2
Branch: feature/c1-3-wallet-ledger
Goal: Every existing credit movement records a balanced entry; existing balances get opening entries; desk top-ups
accrue the offline fee; a daily job proves the ledger and the wallets agree.
Context: §3.2 posting rules (wallet and desk rows), §3.4 (offline fee). `app/interactions/transactions/{purchase,
confirm,refund,create_order}.rb`; staff top-ups go through `createOrder` (client `app/forms/credits`).
Steps:
  1. Record entries in `Purchase` (reserve), `Confirm` (recognise revenue and tax), `Refund` (reverse), staff top-up
     and withdrawal. Staff top-ups gain `paymentMethod` (`cash` default, `card_terminal`, `bank_transfer`,
     `complimentary`); complimentary posts to `promotional_expense` and carries no fee. client: payment-method select
     in the credits form.
  2. No offline fee yet: plans arrive in C2.2, which accrues fees from then on (desk top-ups recorded before C2.2 are
     not charged retroactively).
  3. Rake task `ledger:opening_balances` (idempotent, prints counts): per operator, wallets and reserved transactions
     against `opening_balance_equity`; also run from a data migration so every environment is consistent.
  4. `LedgerReconciliationJob` daily in `config/recurring.yml` (invariants in §3.2); mismatches create error-level
     activity events and report to AppSignal.
  5. Specs: each flow records the expected lines; opening balances on the P0.5 seed make reconciliation pass; a forced
     mismatch is reported.
Acceptance criteria (cloud VM):
  - Backend rspec green; on the dev seed, `bin/rails ledger:opening_balances` then the reconciliation job report no
    mismatch; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: online payments.
Risk / rollback: recording is additive; the opening-balance task is idempotent by `document`.
Size: L
Fixes: none

### C2.1 — Stripe Connect onboarding and webhooks
Status: todo
Repo: both
Depends on: C1.3
Branch: feature/c2-1-stripe-connect
Goal: An operator with `managePayments` connects a Stripe account from the app; account status stays current from
webhooks; the fake provider covers development and tests.
Context: §3.3, CD1. Stripe API is not reachable from the VM (README "External services").
Steps:
  1. backend: `gem "stripe"` (latest stable 20.x); `PaymentProviders::Base`, `::Stripe`, `::Fake`; provider chosen by
     `PAYMENT_PROVIDER` (default `fake` outside production).
  2. `payment_accounts`, `provider_events` tables; mutation `startPaymentOnboarding(operatorId)` returns an account-link
     URL; `Operator.paymentAccount { chargesEnabled payoutsEnabled requirementsDue }`.
  3. `Webhooks::StripeController#create` (`POST /webhooks/stripe`, CSRF-free, signature verified with
     `STRIPE_WEBHOOK_SECRET`), stores the event, enqueues `ProcessProviderEventJob`; handler registry; `account.updated`.
     On first `charges_enabled`, register the web app's domain for Apple Pay on the connected account.
  4. Permissions from §3.8 with the role backfill.
  5. client: Setup → Business → Payments screen (U5.3 group; status, "Connect Stripe" opening the link with `expo-web-browser`, refresh on
     return).
  6. Specs with WebMock and fixtures: onboarding authz and tenancy, bad signature → 400, duplicate event handled once,
     `account.updated` updates flags.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - Owner, on staging with test-mode keys: connect a test operator account and see "charges enabled".
Out of scope: charges (C2.4).
Risk / rollback: new tables and endpoint. Revert both.
Size: L
Fixes: none

### C2.2 — Configurable fee plans, per-operator assignment, free operators
Status: todo
Repo: both
Depends on: C2.1
Branch: feature/c2-2-platform-fee
Goal: Platform administrators configure fee plans and assign them to operators (including free, permanently or until a
date); online and offline fees are computed from the plan in force, snapshotted and recorded on both sets of books;
zero fees and missing plans charge nothing.
Context: §3.4, CD3.
Steps:
  1. backend: `platform_fee_plans`, `platform_fee_assignments`, `platform_fees` (`kind` online/offline, owed and
     collected amounts); seed "Standard AUD" (default) and "Free" per §3.4.
  2. `PlatformFees::PlanResolver` (assignment covering the time → currency default → none) and
     `PlatformFees::Calculator` (formulas in §3.4; 0 when no plan or a zero plan).
  3. Administrator-only mutations: `createPlatformFeePlan`, `updatePlatformFeePlan` (new version when in use),
     `archivePlatformFeePlan`, `setDefaultPlatformFeePlan`, `assignPlatformFeePlan(operatorId, planId, startsAt,
     endsAt, reason)`, `endPlatformFeeAssignment`; queries `platformFeePlans`, `operator.platformFeePlan` (operator
     `managePayments` can read the plan in force and its end date). Activity event and operator notification on
     assignment changes.
  4. Ledger entries for fees charged and refunded; offline accrual on desk top-ups and `recordDeskPayment`.
  5. client: Platform destination (U1.1, U5.8) for administrators: plans list and form,
     operator search with the plan in force, assign/end with dates and reason; operator Payments screen shows the plan
     in force.
  6. Specs: rounding table (amounts 0, 1, 33, 34, 100, 12 345, below the minimum, at a maximum when set), offline
     formula; resolver precedence and date boundaries (assignment ends → default applies); free plan and no plan →
     no fee row, no ledger entry, no offline accrual; editing a plan in use versions it and leaves past fees unchanged;
     non-administrators rejected.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: carry-forward and invoices (C2.10), statements (C2.9).
Risk / rollback: additive.
Size: L
Fixes: none

### C2.3 — Customers, sales orders and the wallet top-up sellable
Status: todo
Repo: backend
Depends on: C2.2
Branch: feature/c2-3-sales-orders
Goal: The order model, totals, the `Sellable` contract and `WalletTopUp` exist; `createCheckout` creates an order with a
pending payment through the fake provider; staff can settle orders at the desk.
Context: §3.5.
Steps:
  1. Tables `customers`, `sales_orders`, `sales_order_lines`, `payments`; models, state machines (`state_machines`
     already in the Gemfile), `Sellable` concern, `Commerce::Totals` (tax per §3.1).
  2. `WalletTopUp` sellable: amount chosen by the member within operator limits (`settings.top_up_min_cents`,
     `top_up_max_cents`); `on_paid!` credits the wallet through the existing wallet code and records the entry.
  3. `Commerce::Checkout` and mutation `createCheckout(input: {operatorId, lines, idempotencyKey})` (logged-in
     members); query `salesOrder(id)` (buyer or `readOrders`); subscription `salesOrderUpdated(salesOrderId)`;
     `recordDeskPayment` (`recordDeskPayments`) with offline fee accrual.
  4. `ExpireSalesOrdersJob` every minute (`config/recurring.yml`).
  5. Specs: totals, idempotency (same key twice → same order; parallel requests → one order), expiry releases lines,
     desk payment accrues 1 %, tenant isolation.
Acceptance criteria (cloud VM):
  - Backend rspec green; schema dump diff additive.
Acceptance criteria (owner, real device):
  - none
Out of scope: Stripe charges (C2.4), coupons (C2.7).
Risk / rollback: additive.
Size: L
Fixes: none

### C2.4 — Charge through Stripe and confirm from webhooks
Status: todo
Repo: backend
Depends on: C2.3
Branch: feature/c2-4-payment-intents
Goal: Checkout creates a PaymentIntent on the operator's account with the platform fee; orders become paid only from
webhooks; late and lost webhooks are handled.
Context: §3.3, §3.5 (late payment rule).
Steps:
  1. `Payments::CreateIntent` (outside the checkout DB transaction, idempotency key `payment-<id>`; the fee from the plan
     in force, and no `application_fee_amount` at all when it is 0); `createCheckout`
     returns `clientSecret`, `stripeAccountId`, `publishableKey`; checkout fails clearly when the operator's account
     cannot take charges.
  2. Handlers: `payment_intent.succeeded` (mark paid, `on_paid!`, ledger, fee record, staff/customer notification),
     `payment_failed` (record message), `canceled`; late success on an expired order → re-reserve or full refund.
  3. `Payments::RecordProcessingFeeJob` reads the balance transaction and records the Stripe fee.
  4. `ReconcileStuckPaymentsJob` (every 15 minutes) re-fetches intents in `processing`.
  5. Development-only `simulatePayment(paymentId, outcome)` for the fake provider.
  6. Specs with fixtures: happy path, duplicate webhook, failure then retry, late success both ways, processing-fee
     entry, stuck-payment recovery.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none (end-to-end in C2.11)
Out of scope: client UI, carry-forward (C2.10).
Risk / rollback: revert; no data migration.
Size: L
Fixes: none

### C2.5 — Client payments and online credit top-up
Status: todo
Repo: both
Depends on: C2.4
Branch: feature/c2-5-client-payments
Goal: Members top up credits from the app and the web with card, Apple Pay or Google Pay; the payment components are
reusable by the other plans.
Context: §3.3 (client), CD6. Client platform-file convention (`*.web.tsx`), Apollo hooks via codegen.
Steps:
  1. client: `npx expo install @stripe/stripe-react-native`; config plugin in `app.config.ts` (`merchantIdentifier`
     per environment, `enableGooglePay: true`); `@stripe/stripe-js` and `@stripe/react-stripe-js` for web.
  2. `app/features/payments/` (on `app/ui`): `PaymentProvider(.web).tsx` (keyed by `stripeAccountId`), `PayButton(.web).tsx`
     (PaymentSheet natively; Express Checkout Element + Payment Element on web), `OrderStatus` (waits for
     `salesOrderUpdated`, falls back to polling).
  3. Online top-up in the Wallet (U4.3) and, for staff, on a member's Funds section (U5.2); remote switch `topUpsInIosApp` (backend: a
     platform setting exposed on `currentUser` or app config; default on) per CD6.
  4. With the fake provider, a development "Simulate payment" button replaces the Stripe UI so Playwright (`@payments`)
     can complete a top-up.
  5. Tests: top-up form validation, status transitions with mocked subscription, iOS switch hides the entry; extend
     `docs/SMOKE_TEST.md` with "top up credits".
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export, smoke test with the fake provider pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: top up with a test card on web, with Apple Pay on an iPhone (development build), with
    Google Pay on Android; balances and the ledger agree.
Out of scope: credit packages with bonuses (WEBSHOP S3.1).
Risk / rollback: revert; feature hidden when the operator has no connected account.
Size: L
Fixes: none

### C2.6 — Refunds and disputes
Status: todo
Repo: both
Depends on: C2.5
Branch: feature/c2-6-refunds
Goal: Staff refund orders fully or partly; fees (online and offline), ledger and wallet follow; disputes are tracked
and recorded.
Context: §3.6, CD4.
Steps:
  1. `refunds` table; `refundSalesOrder(input: {salesOrderId, lines: [{lineId, quantity}], amountCents?, reason,
     restock})` with `refundOrders`; provider refund with `refund_application_fee: true`; wallet refunds; desk refunds
     reduce the offline fee accrual; ledger reversal; `on_refunded!`.
  2. Handlers `charge.refunded` (refunds made in the Stripe Dashboard are mirrored), `charge.dispute.created|closed`
     (lost: chargeback entry and application-fee refund).
  3. client: refund action in the Money area (U5.8) for top-ups (shop and booking screens reuse it later).
  4. Specs: partial and full refund maths, fee refund proportional (online and offline), Dashboard-initiated refund
     mirrored once, lost dispute records a chargeback and refunds the fee, carried-forward fees untouched by the
     carrying payment's refund.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: refund a test top-up half, then fully; check the Stripe Dashboard shows the fee refunds.
Out of scope: return shipping (WEBSHOP S4.1).
Risk / rollback: revert.
Size: M
Fixes: none

### C2.7 — Coupons (backend)
Status: todo
Repo: backend
Depends on: C2.6
Branch: feature/c2-7-coupons
Goal: Coupons can be created, validated and redeemed in checkout with exact allocation and safe limits.
Context: §3.7.
Steps:
  1. Tables `coupons`, `coupon_targets`, `coupon_redemptions`; CRUD mutations (`manageCoupons`); `previewCoupon(code,
     lines)` for the client; `createCheckout` accepts `couponCode`.
  2. Conditional-update redemption reservation; release on expiry/cancel.
  3. Stored-value sellables (`stored_value? == true`) never discounted.
  4. Specs: each kind, date window, per-customer and total limits under 20 parallel checkouts (no over-redemption),
     allocation remainder, zero-total order paid without provider (and no fee), ledger `discounts` line.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: UI (C2.8).
Risk / rollback: additive.
Size: M
Fixes: none

### C2.8 — Coupons (client)
Status: todo
Repo: client
Depends on: C2.7
Branch: feature/c2-8-coupons-client
Goal: Staff manage coupons; checkout accepts a code and shows the discount.
Context: Setup list-and-form pattern (`ResourceList`/`ResourceForm`, U5.5).
Steps:
  1. Setup → Business → Coupons list and form (kind, value, window, limits, targets).
  2. Coupon field in the shared checkout summary component (`previewCoupon`).
  3. Tests: form validation; discount display.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### C2.9 — Platform fee statements and platform reporting
Status: todo
Repo: both
Depends on: C2.8
Branch: feature/c2-9-fee-statements
Goal: Operators see what they paid and owe OpenManifest; platform administrators see fee revenue, payment volume and
outstanding offline fees.
Context: §3.4 reporting, CD5 (tax line).
Steps:
  1. Queries: `operator.platformFeeStatement(month)` (`managePayments`): plan(s) in force that month, online fees,
     offline fees accrued, collected, owed, refunded, complimentary credits, tax line; CSV download.
     `platformRevenue(from, to)` (administrators): per operator and currency: plan in force, online and offline volume,
     fees, outstanding, refunds, disputes; operators on a free plan and operators with no plan listed separately, with
     the fees they would have paid under the default plan (so free arrangements have a visible cost).
  2. client: statement screen under Setup → Business → Payments; administrator screen in the Platform destination.
  3. Specs: statement totals equal the platform-side ledger accounts for the month (operator time zone boundaries).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: collection (C2.10).
Risk / rollback: read-only.
Size: M
Fixes: none

### C2.10 — Collect offline fees: carry-forward and monthly invoices
Status: todo
Repo: both
Depends on: C2.9
Branch: feature/c2-10-offline-fee-collection
Goal: Offline fees owed by an operator are collected automatically from its next online payments, and any remainder is
invoiced monthly through Stripe Billing.
Context: §3.4 (collection), CD7.
Steps:
  1. `platform_fee_collections`; in `Payments::CreateIntent`, add owed offline fees (oldest first) to
     `application_fee_amount` up to `carry_forward_cap_bps` of the payment, reserving them so two concurrent payments
     cannot collect the same fee; settle on `payment_intent.succeeded`, release on failure/expiry.
  2. Billing customer per operator on the platform account (`billing_customer_id`, billing email collected on the
     Payments screen); `MonthlyPlatformInvoicesJob` daily, invoicing each operator once its month has ended in its own
     time zone (the same month boundaries as the C2.9 statement), itemised by month; handlers `invoice.paid` (settle, ledger) and `invoice.payment_failed` (notify
     `managePayments` holders, show on the Payments screen).
  3. client: "Owed to OpenManifest" and invoices on the Payments screen.
  4. Specs: cap arithmetic, oldest-first allocation, concurrent payments, failed payment releases the reservation,
     invoice amounts equal owed fees, paid invoice settles, nothing invoiced when nothing is owed.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: record a desk top-up, make an online top-up and see the larger application fee in the
    Stripe Dashboard; run the invoice job for an operator with no online payments and pay the test invoice.
Out of scope: dunning beyond Stripe Billing's own retries; suspending operators that do not pay (owner policy, later).
Risk / rollback: revert; owed fees stay recorded and can be invoiced manually.
Size: L
Fixes: none

### C2.11 — Verify the commerce foundation
Status: todo
Repo: both
Depends on: C2.10
Branch: feature/c2-11-verify
Goal: The foundation works end to end and is documented.
Context: all of this plan.
Steps:
  1. Run every check in both repos; record results in `docs/verification/commerce-foundation.md`.
  2. Update `docs/reference/README.md` (payments row, domain model, env vars, jobs) and `diagrams.md` (ER for §3.9,
     sequence for checkout → webhook → ledger outbox).
Acceptance criteria (cloud VM):
  - All checks exit 0.
Acceptance criteria (owner, real device):
  - Owner on staging (needs P8.4 or an equivalent public URL for webhooks): test-mode top-ups on web, iPhone and
    Android; a desk top-up collected by carry-forward; a refund; a fee statement matching the Stripe Dashboard; App
    Review's answer on in-app top-ups (CD6) recorded here.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase B — Booking

Goal: operators publish bookable services, set up when they run and how many people fit, and customers book and pay
online with or without an account, never double-booked; booked participants reach the manifest as prepaid guest slots.
Design and decisions BD1–BD7: [BOOKING_PLAN](features/BOOKING_PLAN.md) (§n in Phase B refers to it). Builds on Phase C.

Rules for every Phase B task: concurrency claims are proven by specs that run real parallel threads against PostgreSQL
(the P6.10 lock specs are the pattern); every public (`authenticate: false`) field has a spec that it exposes nothing
from unpublished services or other operators; times are tested in a non-UTC operator time zone with a DST change;
client screens follow "Client UI work".

### B1.1 — Operator booking profile and the public API surface
Status: todo
Repo: backend
Depends on: C2.9
Branch: feature/b1-1-public-profile
Goal: Operators have a slug and booking settings; anonymous clients can read a published operator's public profile;
the rate-limit extension exists.
Context: §3.5. graphql_devise `authenticate: false`. `Operator` has no slug today.
Steps:
  1. Migration: `operators.slug` (unique, generated from the name, editable, never one of the client's reserved first
     path segments listed in `config/reserved_slugs.yml`: `manifest`, `loads`, `operators`, `people`, `bookings`, …), settings `booking_enabled` (false),
     `booking_horizon_days` (120), `hold_minutes` (15), `booking_contact_email`, `booking_terms_md`.
  2. Query `publicOperator(slug)` (`authenticate: false`): name, slug, banner, colours, time zone, currency, terms,
     contact; null unless `booking_enabled`.
  3. `Extensions::RateLimited` field extension (limit, period, key by IP or argument) using `Rails.cache`.
  4. Specs: public field shape, disabled operator returns null, rate limit returns `RATE_LIMITED` error code.
Acceptance criteria (cloud VM):
  - Backend rspec green; schema dump diff additive.
Acceptance criteria (owner, real device):
  - none
Out of scope: services.
Risk / rollback: additive.
Size: M
Fixes: none

### B1.2 — Services, resources and permissions
Status: todo
Repo: backend
Depends on: B1.1
Branch: feature/b1-2-services
Goal: Staff create services and resources through the API; published services are publicly readable.
Context: §3.1, §3.9.
Steps:
  1. Tables `services`, `resources`, `service_resource_requirements`; models with validations (payment mode and deposit
     consistent, participant rules ranges, `description_md` ≤ 20 000 characters).
  2. Mutations `createService`, `updateService`, `archiveService`, `createResource`, `updateResource`,
     `archiveResource` (`manageServices`); queries `services(operatorId)` (staff), `publicServices(operatorSlug)`,
     `publicService(operatorSlug, slug)`.
  3. Permissions in `access.yml` with role backfill.
  4. Specs: authz, tenancy, public visibility of draft/archived, validation.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: availability (B1.3).
Risk / rollback: additive.
Size: M
Fixes: none

### B1.3 — Availability rules and session generation
Status: todo
Repo: backend
Depends on: B1.2
Branch: feature/b1-3-availability
Goal: Rules and exceptions produce sessions for the booking horizon; public availability answers "what can I book".
Context: §3.2.
Steps:
  1. Tables `availability_rules`, `availability_exceptions`, `booking_sessions` (with the capacity check constraint).
  2. `BookingSessions::Generate` (idempotent per service and date range, local-time generation, never touches booked
     sessions); `GenerateBookingSessionsJob` nightly in `config/recurring.yml` and after rule changes.
  3. Mutations for rules, exceptions, one-off sessions, session capacity and closing (`manageServices`).
  4. Query `availability(serviceId, from, to, participants)` (public for published services): sessions with remaining
     places, accounting for resource units (allocation table arrives in B1.4; until then capacity only).
  5. Specs: weekly pattern, exceptions, DST week in `Australia/Sydney` and `Europe/Oslo`, regeneration with bookings
     present (stub booked count), capacity floor.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: holds.
Risk / rollback: additive.
Size: L
Fixes: none

### B1.4 — Holds, capacity and resource allocation
Status: todo
Repo: backend
Depends on: B1.3
Branch: feature/b1-4-holds
Goal: Places and resource units are reserved atomically with database-enforced guarantees; holds expire.
Context: §3.3 (all three guarantees and the race table), §3.4.
Steps:
  1. Tables `bookings`, `booking_participants`, `resource_allocations` (`btree_gist`, exclusion constraint with
     `released_at IS NULL`).
  2. `Bookings::Reserve` (conditional update, allocation with `SKIP LOCKED` and retry on exclusion violation, inline
     expiry of stale holds on that session), `Bookings::Release`, `Bookings::Reschedule`.
  3. Mutation `createBookingHold` for logged-in users and staff (guests in B1.5); `ExpireBookingHoldsJob` every minute;
     nightly counter check.
  4. Resource blocks: `blockResource(resourceId, from, to, reason)`.
  5. Availability (B1.3 step 4) includes free resource units.
  6. Specs: every row of the race table in §3.3 with real threads.
Acceptance criteria (cloud VM):
  - Backend rspec green; the concurrency specs pass 20 consecutive runs (`for i in $(seq 20); do bundle exec rspec spec/concurrency/bookings; done`).
Acceptance criteria (owner, real device):
  - none
Out of scope: payment.
Risk / rollback: additive; constraint migrations are reversible.
Size: L
Fixes: none

### B1.5 — Guest customers: Turnstile, email codes, manage links
Status: todo
Repo: backend
Depends on: B1.4
Branch: feature/b1-5-guest-verification
Goal: Guests can hold a booking after a captcha, prove their email with a code, and manage the booking from a link.
Context: §3.5. Turnstile is not reachable from the VM (stub with fixtures).
Steps:
  1. `Captcha::Turnstile.verify(token, ip)` (5-second timeout; `TURNSTILE_SECRET_KEY`; always-pass test keys in
     development per Cloudflare's documented test site/secret keys).
  2. `customer_verifications` (code HMAC, expiry, attempts); mutations `createBookingHold` (guest variant),
     `resendVerificationCode`, `verifyCustomerEmail`; mailer.
  3. `Booking.generates_token_for(:manage)`; query `managedBooking(token)`.
  4. Rate limits from §3.5; `AnonymiseGuestCustomersJob` monthly.
  5. Specs: captcha failure, code expiry/attempts/resend timing, token expiry, limits, anonymisation keeps ledger rows.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: UI (B2.1).
Risk / rollback: additive.
Size: M
Fixes: none

### B1.6 — Booking checkout and confirmation
Status: todo
Repo: backend
Depends on: B1.5
Branch: feature/b1-6-booking-checkout
Goal: Bookings are paid (deposit or full) through COMMERCE checkout, with coupons, and confirmed by webhook; free
bookings confirm without payment.
Context: §3.6; COMMERCE §3.5 (Sellable, late payment), C2.7 (coupons).
Steps:
  1. `Booking` implements `Sellable`; `startBookingCheckout(bookingId | manageToken, couponCode, idempotencyKey)` for
     guests (verified) and users; hold extended once.
  2. On paid: `confirmed`, balance due stored, ledger to `customer_deposits`, staff push, confirmation email (B1.8 adds
     the template; here a plain one).
  3. Zero-amount path (payment mode `none` or 100 % coupon) requires a verified customer.
  4. Specs: deposit maths with coupons and tax, late payment both ways, unverified guest rejected, free path.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: cancellations.
Risk / rollback: additive.
Size: L
Fixes: none

### B1.7 — Cancellation, rescheduling, operator cancellations and desk payments
Status: todo
Repo: backend
Depends on: B1.6
Branch: feature/b1-7-cancellations
Goal: Customers and staff cancel or reschedule within policy; operators cancel whole sessions; balances paid at the
desk are recorded.
Context: §3.4, §3.6, §3.7; COMMERCE C2.6 refunds.
Steps:
  1. Policy snapshot on the booking; `cancelBooking` (manage token or user; staff variant overrides policy with a
     reason), `rescheduleBooking`, `cancelBookingSession(sessionId, reason)` (each booking: notice + reschedule/refund
     choice per BD6).
  2. Desk balances through COMMERCE `recordDeskPayment` (offline fee accrued); revenue recognition at check-in or
     session end (`RecogniseBookingRevenueJob` hourly).
  3. Optional "pay balance online" checkout for the remaining amount (BD4 a).
  4. Specs: each policy tier at the boundary hours (operator time zone), forfeited deposit posting, session
     cancellation with mixed paid/unpaid bookings, reschedule keeps payments.
Acceptance criteria (cloud VM):
  - Backend rspec green; ledger reconciliation passes after the spec scenarios.
Acceptance criteria (owner, real device):
  - none
Out of scope: automatic balance charges (BD4 b).
Risk / rollback: additive.
Size: L
Fixes: none

### B1.8 — Booking emails and reminders
Status: todo
Repo: backend
Depends on: B1.7
Branch: feature/b1-8-booking-emails
Goal: Customers receive clear confirmation, reminder and change emails with calendar files and the manage link.
Context: §3.8. Only `app/mailers/application_mailer.rb` exists (devise mails come from devise); there are no mailer
previews yet, so this task adds `spec/mailers/previews/` and sets `config.action_mailer.preview_paths` in development.
Steps:
  1. Mailers and templates (HTML + text, operator branding colours and logo): code, confirmation (with `.ics`),
     reminder 24 h before (`BookingRemindersJob` hourly), cancellation, reschedule, operator cancellation.
  2. Push/in-app notifications for logged-in customers (new `notification_type` values).
  3. Specs: content, `.ics` validity (start/end in UTC with `TZID`), reminder sent once.
Acceptance criteria (cloud VM):
  - Backend rspec green; mailer previews render.
Acceptance criteria (owner, real device):
  - Owner receives the confirmation and reminder emails on staging (SMTP) and adds the `.ics` to a phone calendar.
Out of scope: SMS.
Risk / rollback: additive.
Size: M
Fixes: none

### B2.1 — Public booking pages on the web
Status: todo
Repo: both
Depends on: B1.8
Branch: feature/b2-1-public-booking
Goal: A guest can go from the operator's booking link to a confirmed, paid booking on a phone browser.
Context: §3.10. Unauthenticated routes live in `client:app/screens/unauthenticated/`; linking config in
`client:app/screens/routes.tsx`; payment components from C2.5.
Steps:
  1. client (Client UI work rules; public routes in the destinations-free unauthenticated stack): routes `/:operatorSlug/book`, `/:operatorSlug/book/:serviceSlug` available signed in or out; screens:
     service list, service detail (markdown description: choose the renderer here per WEBSHOP_PLAN §3.1, record the choice in the PR, and add
     `MarkdownView`/`MarkdownEditor` to `app/ui`; S1.1 reuses them), date picker with availability, session picker, participants form (rules), customer details,
     Turnstile widget (`.web.tsx` only), code entry, coupon, payment, confirmation.
  2. Hold countdown; clear "sold out, pick another time" recovery.
  3. backend: embed snippet documented in `docs/reference/README.md` (iframe of the booking URL).
  4. Tests: flow with mocked API; extend `docs/SMOKE_TEST.md` and the Playwright suite (`e2e/booking.spec.ts`, `@booking`) with a guest booking using the
     fake payment provider and Turnstile test keys.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and the smoke test (including the new booking step) pass.
Acceptance criteria (owner, real device):
  - Owner books as a guest on an iPhone (Safari, Apple Pay) and an Android phone (Chrome, Google Pay) on staging test
    mode; the layout passes the 360 dp checks from Phase 5.
Out of scope: native guest booking (BD1 b).
Risk / rollback: revert; operators enable booking explicitly.
Size: L
Fixes: none

### B2.2 — Manage-booking page
Status: todo
Repo: client
Depends on: B2.1
Branch: feature/b2-2-manage-booking
Goal: From the emailed link, a customer views, completes participant details for, cancels or reschedules a booking, and
pays a balance.
Context: §3.5 manage link; B1.7 mutations.
Steps:
  1. Route `/bookings/manage/:token`; booking summary, participant details form, cancel with the refund the policy
     gives (shown before confirming), reschedule picker, pay-balance button.
  2. Tests for each action and for an expired token.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### B2.3 — Staff configuration: services, resources and availability
Status: todo
Repo: client
Depends on: B2.2
Branch: feature/b2-3-booking-config
Goal: Staff with `manageServices` set up everything a booking needs from the app.
Context: Setup list-and-form pattern (`ResourceList`/`ResourceForm`, U5.5).
Steps:
  1. Setup → Booking group: operator booking settings (enable, slug, hold minutes, terms), Services (form with
     payment mode, policy tiers, participant rules, resource requirements, markdown description with preview), Resources
     (units, blocks), Availability (weekly rules editor, exceptions, preview of generated sessions).
  2. Tests for each form's validation and the rule preview.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner sets up a tandem service with weekend sessions on a small Android phone.
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### B2.4 — Staff bookings calendar, manual bookings and check-in
Status: todo
Repo: both
Depends on: B2.3
Branch: feature/b2-4-booking-desk
Goal: Staff see and run the day's bookings: calendar, list, booking detail, manual booking, move, cancel, check-in,
no-show, desk payment.
Context: §3.7.
Steps:
  1. backend: `bookings(operatorId, from, to, state, serviceId)` and `bookingSessions(...)` for staff
     (`readBookings`), subscription `bookingUpdated(operatorId)`; `checkInBooking`, `markNoShow`.
  2. client: Bookings destination (U1.1 table; shown with `booking_enabled` and `readBookings`) (day/week calendar with fill bars, list, detail sheet with actions; manual booking reusing the
     B2.1 flow with "pay at desk" and "no payment").
  3. Tests: actions, live update via mocked subscription.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner checks in a booking and records a desk payment on a phone.
Out of scope: manifest link (B3.2).
Risk / rollback: revert.
Size: L
Fixes: none

### B2.5 — Booking in the app for signed-in users
Status: todo
Repo: client
Depends on: B2.4
Branch: feature/b2-5-app-booking
Goal: Signed-in users book from the native app and see their bookings.
Context: B2.1 screens are reused in the authenticated stack; native payments through C2.5 (PaymentSheet).
Steps:
  1. "Book" entry on Today (U4.1); reuse the booking screens without Turnstile and code steps.
  2. Today and Account → My bookings (upcoming, past, manage actions).
  3. Tests.
Acceptance criteria (cloud VM):
  - Client checks, web export pass.
Acceptance criteria (owner, real device):
  - Owner books with Apple Pay on an iPhone development build and with Google Pay on Android.
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### B3.1 — Participant details and waiver forms
Status: todo
Repo: both
Depends on: B2.5
Branch: feature/b3-1-participant-forms
Goal: Services can require per-participant answers (medical declaration, weight, emergency contact, waiver
acknowledgement) built with the existing form templates.
Context: `FormTemplate` (JSON definition, used for rig inspections), `services.participant_form_template_id`.
Steps:
  1. backend: answers stored on `booking_participants.form_answers` with the template version; validation against the
     template; "details incomplete" flag on the booking.
  2. client: form renderer reused from the equipment inspection screen (P7.14) in booking flow, manage page and staff detail;
     template editor reused from configuration.
  3. Tests.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: legally binding e-signatures (needs owner legal advice; record the acknowledgement and timestamp only).
Risk / rollback: revert.
Size: M
Fixes: none

### B3.2 — Check-in to manifest
Status: todo
Repo: both
Depends on: B3.1
Branch: feature/b3-2-checkin-manifest
Goal: On check-in, staff put the booking's participants on a load in one step, as prepaid guest slots with their
escorts, without charging anyone's wallet.
Context: BD7 (a); GENERALISATION §17 (mode (a) check-in; mode (b) session ↔ load is later work); P7.15 (guests,
escorts), P7.16 (limits checked at slot creation), P7.17 (`prepaid` slots, dated loads).
Steps:
  1. backend: `manifestBooking(bookingId, loadId, escortMembershipIds?)` creates a `Guest` per participant (name, email,
     phone, date of birth, `body_mass_kg`, emergency contact) and prepaid slots with the service's `ticket_type_id`
     through `Manifest::CreateSlot` (escort slots for escort tickets); participant ↔ slot link; limit failures return
     the same eligibility codes staff see.
  2. client: "Manifest" action on a checked-in booking with a load picker (open loads of that day) and escort choice.
  3. Specs: tandem booking of 2 → 2 guest slots + 2 escort slots, nothing charged, revenue recognised once; a
     participant over the body-mass limit fails with its code.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass; tier 2 `@booking`.
Acceptance criteria (owner, real device):
  - Owner manifests a booked tandem on a phone.
Out of scope: mode (b) (session ↔ load), BD7 (b).
Risk / rollback: revert.
Size: M
Fixes: none

### B3.3 — Booking statistics
Status: todo
Repo: both
Depends on: B3.2
Branch: feature/b3-3-booking-stats
Goal: Operators see utilisation, revenue and no-shows per service and period.
Context: the Reports destination (U5.8);
WEBSHOP S4.3 later consolidates reports.
Steps:
  1. backend: `bookingStatistics(operatorId, from, to)` (`readReports`): sessions, capacity, places sold, utilisation %,
     revenue recognised, deposits outstanding, cancellations and refunds, no-show rate, coupon usage, lead time.
  2. client: Booking section on the overview screen; CSV export.
  3. Specs: numbers on a fixed scenario, operator-time-zone day boundaries.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: read-only.
Size: M
Fixes: none

### B3.4 — Verify booking
Status: todo
Repo: both
Depends on: B3.3
Branch: feature/b3-4-verify
Goal: Booking works end to end and is documented.
Context: all of this plan.
Steps:
  1. Run all checks; `docs/verification/booking.md` with results and the race-table spec output.
  2. Update `docs/reference/README.md` (feature inventory, domain model, jobs, public API) and `diagrams.md` (booking
     state and sequence diagrams from §3.4 and §3.10).
Acceptance criteria (cloud VM):
  - All checks exit 0.
Acceptance criteria (owner, real device):
  - Owner runs a full day on staging: guest bookings on two phones, a weather cancellation of one session, check-in
    and manifest of the rest; the ledger reconciliation reports no mismatch.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase S — Webshop

Goal: operators sell physical goods and virtual products (credit packages, gift vouchers, memberships) to signed-in
members on the web and in the app, manage stock and fulfilment, and see sales reports. Design and decisions SD1–SD4:
[WEBSHOP_PLAN](features/WEBSHOP_PLAN.md) (§n in Phase S refers to it). Builds on Phase C; gift vouchers and reports
also use Phase B.

Rules for every Phase S task: as Phase C (cents, ledger in the same transaction, tenant-isolation and authz specs);
stock claims are proven with parallel-thread specs like B1.4; client screens follow "Client UI work".

### S1.1 — Catalogue: products, variants, categories, markdown
Status: todo
Repo: both
Depends on: C2.9
Branch: feature/s1-1-catalogue
Goal: Staff create products with variants, categories, visibility and a markdown description; the public and members
can read what they are allowed to see.
Context: §3.1, §3.8, SD3.
Steps:
  1. backend: tables `product_categories`, `products`, `product_options`, `product_variants` (stock columns created
     here, used in S1.3); validations; mutations (`manageProducts`); queries `products(operatorId, filter)` (staff),
     `shopProducts(operatorSlug, categorySlug, search)` and `shopProduct(operatorSlug, slug)` (`authenticate: false`,
     filtered by visibility: `public` for everyone, `members` for members of that operator, `staff` for staff).
  2. client: reuse `MarkdownView` and `MarkdownEditor` from B2.1 (`app/ui`).
  3. Permissions with role backfill.
  4. Specs: visibility matrix (anonymous, other operator's member, member, staff) × (draft, active, archived, window),
     SKU uniqueness, markdown length.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql` pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: media (S1.2), staff screens (S1.4).
Risk / rollback: additive.
Size: M
Fixes: none

### S1.2 — Media: direct uploads for images and video
Status: todo
Repo: both
Depends on: S1.1
Branch: feature/s1-2-media
Goal: Staff attach ordered images and videos to products and services from a phone or the web, uploading straight to
storage.
Context: §3.2, SD1. `config/storage.yml`; P6.21 upload fixes; `expo-image-picker` is installed.
Steps:
  1. backend: `product_media` (polymorphic owner: product or service); `createDirectUpload`; `attachMedia`,
     `reorderMedia`, `updateMedia` (alt text), `removeMedia`; content-type and size validation on the blob; ffmpeg
     poster generation (skip with a warning when ffmpeg is missing); `PurgeUnattachedBlobsJob` daily.
  2. Document bucket CORS and ffmpeg in `docs/reference/README.md` §8 (for P8.4).
  3. client: `MediaManager` component (pick from library/camera, upload progress, reorder by drag on web and
     move buttons on native, alt text), `MediaGallery` (swipe, video playback with `expo-video` if bundled with SDK 57,
     otherwise the SDK's video module).
  4. Specs: direct upload round trip on the Disk service, rejected types and sizes, ordering, tenant isolation.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - Owner uploads 3 photos and a 1-minute phone video to a product on an iPhone and on Android; both play on web.
Out of scope: transcoding (SD1 b).
Risk / rollback: additive.
Size: L
Fixes: none

### S1.3 — Stock movements and reservations
Status: todo
Repo: backend
Depends on: S1.2
Branch: feature/s1-3-stock
Goal: Stock changes are recorded as movements; checkout reserves stock atomically; overselling is impossible unless
backorders are allowed.
Context: §3.3.
Steps:
  1. `stock_movements`; `Inventory::Move` (receive, adjust with reason, damage); check constraint on variants.
  2. `ProductVariant` implements `Sellable` (`reserve!`, `release!`, `on_paid!` decrements, `on_refunded!` with optional
     restock).
  3. Low-stock crossing notification.
  4. Specs: 20 threads buying the last 3 units → 3 succeed; backorder variant never blocks; expiry releases; counters
     equal movement sums after the scenarios.
Acceptance criteria (cloud VM):
  - Backend rspec green; the stock concurrency spec passes 20 consecutive runs.
Acceptance criteria (owner, real device):
  - none
Out of scope: valuation.
Risk / rollback: additive.
Size: M
Fixes: none

### S1.4 — Staff catalogue and stock screens
Status: todo
Repo: client
Depends on: S1.3
Branch: feature/s1-4-catalogue-screens
Goal: Staff manage the whole catalogue and stock from the app.
Context: Setup list-and-form pattern (U5.5); S1.1–S1.3 API.
Steps:
  1. Shop destination (U1.1 table; shown with `manageProducts` or `readOrders`) → Products: list with status/visibility/stock badges and search; product form (details, markdown editor,
     options and variants grid, prices, visibility and dates, media manager); categories screen.
  2. Stock: per-variant movement history, receive/adjust dialog with reason.
  3. Tests for forms and the variants grid.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner creates a T-shirt with sizes and colours, photos and stock on a small Android phone.
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### S2.1 — Storefront and cart
Status: todo
Repo: both
Depends on: S1.4
Branch: feature/s2-1-storefront
Goal: Anyone can browse an operator's shop; signed-in users keep a cart across web and app.
Context: §3.4. Public routes like B2.1 (`/:operatorSlug/shop`, `/:operatorSlug/shop/:productSlug`).
Steps:
  1. backend: `carts`, `cart_items`; mutations `addToCart`, `updateCartItem`, `removeCartItem`; query `cart(operatorId)`
     with current prices and availability flags.
  2. client: shop home (categories, featured), product list, product detail (gallery, variant picker, stock state,
     markdown), cart screen; "sign in to buy" for anonymous visitors, returning to the product after login.
  3. Tests; smoke test step "browse shop, add to cart".
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export, smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: checkout (S2.2).
Risk / rollback: revert.
Size: L
Fixes: none

### S2.2 — Checkout with shipping and pickup
Status: todo
Repo: both
Depends on: S2.1
Branch: feature/s2-2-shop-checkout
Goal: Signed-in users buy physical goods with card, Apple Pay or Google Pay, choosing delivery or pickup.
Context: §3.4; COMMERCE checkout (C2.3–C2.5) and coupons (C2.7–C2.8).
Steps:
  1. backend: `shipping_zones`, `shipping_rates`, pickup setting; `shippingOptions(cartId, address)`; checkout from a
     cart (lines from cart items, address and rate snapshot); shipping in totals, tax and ledger; staff configuration
     mutations (`manageProducts`).
  2. client: address form (saved addresses per user), shipping option list, order summary with coupon, payment with
     the C2.5 components, order confirmation; shipping configuration screen for staff.
  3. Specs: rate selection by zone/postcode/weight, free-over threshold after discounts, tax on shipping, stock
     reserved and released, order emails (receipt with tax details from COMMERCE C1.1).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export, smoke test (checkout with the fake provider) pass.
Acceptance criteria (owner, real device):
  - Owner buys with Apple Pay on an iPhone and Google Pay on Android (staging test mode); the order, stock, ledger and
    fee agree.
Out of scope: carrier rates (SD2 b).
Risk / rollback: revert.
Size: L
Fixes: none

### S2.3 — Pay with wallet credits
Status: todo
Repo: both
Depends on: S2.2
Branch: feature/s2-3-wallet-tender
Goal: Members pay shop orders with credits when the operator uses the credit system.
Context: SD4; wallet code (`add_cents!`, P6.10 locks), `allow_negative_credits` setting.
Steps:
  1. backend: `payments.provider = wallet`; balance check under the wallet lock; ledger `customer_wallets` →
     revenue; refunds back to the wallet; no platform fee.
  2. client: "Pay with credits (balance A$…)" option in checkout.
  3. Specs: insufficient balance, concurrent wallet spend (manifest + shop at once) never overdraws, refund.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: split tender.
Risk / rollback: revert.
Size: M
Fixes: none

### S3.1 — Credit packages
Status: todo
Repo: both
Depends on: S2.3
Branch: feature/s3-1-credit-packages
Goal: Operators sell fixed credit packages with optional bonus credits, in the shop and on the top-up screen.
Context: §3.5; COMMERCE C2.3 `WalletTopUp`, C2.5 top-up screen, CD6 (iOS flag).
Steps:
  1. backend: product kind `credit_package` with `credits_cents`, `bonus_cents`; `Sellable` posting per §3.5; never
     discountable.
  2. client: packages shown on the top-up screen above the free-amount option; product form fields.
  3. Specs: bonus posting, coupon rejected, refund removes credits (refusing if the member already spent them, unless
     staff force it into a negative balance with a reason).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### S3.2 — Gift vouchers
Status: todo
Repo: both
Depends on: S3.1, B1.6
Branch: feature/s3-2-gift-vouchers
Goal: Customers buy gift vouchers for someone else; vouchers pay for shop orders and bookings.
Context: §3.5. Booking checkout (B1.6) accepts the voucher as a tender too.
Steps:
  1. backend: `gift_vouchers` (code, initial and remaining balance, expiry, purchaser, recipient, message, state),
     `gift_voucher_redemptions`; product kind `gift_voucher` (fixed amounts or a custom amount in a range); voucher
     email with code; `redeemGiftVoucher` in shop and booking checkout (partial redemption, the rest by card);
     staff `convertVoucherToCredits`; expiry job posting breakage per the accountant's advice (CD5).
  2. client: voucher product page (recipient fields), voucher field in checkout and booking payment, staff voucher
     lookup.
  3. Specs: concurrent redemption of one voucher never exceeds its balance, partial use, expiry, refund of a voucher
     purchase only while unused.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export pass.
Acceptance criteria (owner, real device):
  - Owner buys a voucher on the web and redeems half of it on a tandem booking.
Out of scope: printed vouchers (PDF) — add if operators ask.
Risk / rollback: revert.
Size: L
Fixes: none

### S3.3 — Membership products
Status: todo
Repo: both
Depends on: S3.2
Branch: feature/s3-3-memberships
Goal: Members renew their operator membership online.
Context: §3.5; `memberships.expires_at`, the `membership` eligibility check (P7.16).
Steps:
  1. backend: product kind `membership` with `duration_months`; `on_paid!` extends expiry; notification; ledger.
  2. client: "Renew membership" as the fix action of the membership check on Today (U4.1) and in the picker (U3.7).
  3. Specs: extension from today vs from a future expiry; refund does not shorten (staff adjust manually).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: recurring subscriptions.
Risk / rollback: revert.
Size: M
Fixes: none

### S4.1 — Fulfilment, pickup and order emails
Status: todo
Repo: both
Depends on: S3.3
Branch: feature/s4-1-fulfilment
Goal: Staff ship or hand over orders, partially or fully, and customers are told at each step.
Context: §3.4 fulfilment.
Steps:
  1. backend: `shipments`; `createShipment(salesOrderId, lines, carrier, trackingNumber, trackingUrl)`,
     `markShipmentDelivered`, `markReadyForPickup`, `markPickedUp` (`updateOrders`); order `fulfilment_state`; emails
     and push; customer "My orders" query with shipments.
  2. client: fulfilment actions in the order detail; customer order history and tracking link.
  3. Specs: partial shipment states, refund of an unshipped line, notification sent once.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: labels and live carrier tracking (SD2 b), return authorisations.
Risk / rollback: revert.
Size: M
Fixes: none

### S4.2 — Orders dashboard
Status: todo
Repo: both
Depends on: S4.1
Branch: feature/s4-2-dashboard
Goal: Staff see at a glance what needs doing in the shop and act on it.
Context: §3.7 dashboard.
Steps:
  1. backend: `shopDashboard(operatorId)` (counts and first items per panel), `salesOrders(operatorId, filter)` with
     search by number, customer, product; subscription `salesOrderUpdated(operatorId)`; push on paid orders with a
     per-user opt-out setting.
  2. client: Shop dashboard (panels from §3.7), orders list with filters, order detail (lines, payments, refunds,
     shipments, notes, actions), staff landing card with counts.
  3. Tests: panels with mocked data, live update.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner places an order on one phone and sees it arrive on another phone's dashboard without refreshing.
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### S4.3 — Reports and statistics
Status: todo
Repo: both
Depends on: S4.2, B3.3
Branch: feature/s4-3-reports
Goal: Operators get the sales, stored-value and accounting reports in §3.7, with CSV export.
Context: §3.7 reports; ledger balances and `profit_and_loss` (COMMERCE C1.2); booking statistics (B3.3); `react-native-chart-kit` is
already a client dependency.
Steps:
  1. backend: report queries (`readReports`), each returning rows plus totals, in the operator's time zone; CSV
     endpoint per report (signed, short-lived URL); trial balance and P&L from the ledger.
  2. client: in the Reports destination (U5.8), date range, tabs (Sales, Products, Coupons, Stored value, Bookings, Accounting),
     charts for time series, CSV download.
  3. Specs: a fixed scenario (sales, discounts, refunds, vouchers, wallet spend, bookings) whose report totals equal
     the ledger; month boundary in a non-UTC zone.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: accounting-software integrations.
Risk / rollback: read-only.
Size: L
Fixes: none

### S4.4 — Verify the webshop
Status: todo
Repo: both
Depends on: S4.3
Branch: feature/s4-4-verify
Goal: The webshop works end to end and is documented.
Context: all of this plan.
Steps:
  1. Run all checks; `docs/verification/webshop.md`.
  2. Update `docs/reference/README.md` (feature inventory, domain model, jobs, permissions) and `diagrams.md` (shop ER and
     order state diagram).
Acceptance criteria (cloud VM):
  - All checks exit 0.
Acceptance criteria (owner, real device):
  - Owner, on staging: buys a physical product (ship) and a voucher on web, a credit package on iPhone, pays with
    credits on Android; ships, refunds one line; reports and the fee statement match the Stripe Dashboard.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Deferred bugs

Bugs not in any task's `Fixes:` line, with the reason.

| Bug | Reason | Where it is handled |
|---|---|---|
| BUG-085 | Suspected only (client#127, maps not loading on web/Android); cannot be confirmed without valid `GOOGLE_MAPS_*` keys, which the VM does not have. | Owner checks maps in P3.22. If confirmed, the executor adds a task after P5.10 (replace `react-native-maps` web shim / configure keys via EAS secrets) with `Fixes: BUG-085`. |
| BUG-100 | Cold loads of permission-gated tab URLs (`/users`, `/user/<id>`) end on `/`. The fix needs a decision: always register the tabs and show a no-access state, or hold the navigator until permissions are loaded. | The executor adds a task after P4.8 (when the session store makes permissions available before navigation mounts); until then the smoke test only deep-links ungated routes. |
