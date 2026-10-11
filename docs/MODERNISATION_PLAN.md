# OpenManifest modernisation plan

Single source of truth for reviving, modernising and releasing OpenManifest. It covers both repositories:

- **backend** = `OpenManifest/openmanifest-server` (this repo; Rails GraphQL API)
- **client** = `OpenManifest/openmanifest` (Expo / React Native app for iOS, Android and web)

The client repo's `docs/MODERNISATION_PLAN.md` only points here. Reference material lives in [`docs/reference/`](reference/):
[README](reference/README.md) (system reference), [BUGS](reference/BUGS.md) (bug register), [diagrams](reference/diagrams.md),
[GENERALISATION](reference/GENERALISATION.md), [CLOUD_ENV](reference/CLOUD_ENV.md). Client-side reference:
<https://github.com/OpenManifest/openmanifest/blob/staging/docs/reference/README.md>.

Written in pass 1 on 2026-10-08 against backend `b8dc33a` and client `3112795` (both `staging`).

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
   in Ruby, and load numbers are duplicated. Migrations that add constraints must clean the data first, and whether a
   production database still exists is unknown (decision D7).
5. **Environment and external dependencies.** `cache.ruby-lang.org` and Expo's API are blocked in the VM. Ruby 4.0
   compatibility of older gems (`geokit-rails`, `search_cop`, `active_interaction-extras`) is unproven. Third-party keys
   (AppSignal, Google Maps, APF, Apple, Facebook, SMTP) may no longer be valid.

## Open Decisions

Tasks that depend on an owner decision are `blocked (awaiting decision Dn)` until the owner writes the decision into
this section ("Decision: …, date"); the executor then changes the blocked tasks back to `todo` in the next task's PR.

| ID | Decision | Options | Recommendation | Blocks |
|---|---|---|---|---|
| D1 | Hosting for the API, database, Redis and file storage, and for the web app | (a) Fly.io (configs exist: `fly.toml`, `fly-production.toml`) with Fly Postgres and S3-compatible storage; (b) Render/Heroku-style PaaS; (c) a VPS with Kamal (Rails 8 default) | (a) Fly.io for the API with a Rails 8 Dockerfile, managed Postgres and an S3-compatible bucket. Web: keep GitHub Pages (existing `openmanifest-web` repos), which needs no new account | P8.4, P8.5, P8.6 |
| D2 | Store and Expo accounts and identifiers: Apple team, Play Console, EAS project `1d8fa34d-2ff8-4095-ab49-29a426117a8c`, bundle id `com.dangertechnologies.openmanifest`, domains `openmanifest.org` | (a) keep the existing identifiers if the owner still controls them; (b) new identifiers (a new app in the stores) | (a) if access exists (keeps users and EAS Update channels); otherwise (b) with a new EAS project | P3.21 (owner part), P8.2, P8.3, P8.6, owner device checks from Phase 3 |
| D3 | Dropzone eligibility defaults (BUG-033): the 2023 Settings release turned on `require_membership`, `require_rig_inspection`, `require_reserve_in_date`, `require_equipment`, `require_license`, `require_credits` for all existing dropzones | (a) keep strict defaults; (b) permissive defaults for new dropzones and backfill existing ones as permissive; (c) permissive for existing, strict for new | (b) new and existing dropzones default to `require_credits` = value of `is_credit_system_enabled`, everything else `false`; operators opt in | P6.14 |
| D4 | Facebook login (BUG-084) | (a) drop Facebook login on all platforms; (b) re-implement with `expo-auth-session` | (a) drop. Native `expo-facebook` was removed from Expo, Facebook needs app review, and email + Apple sign-in remain | P3.3 |
| D5 | Generalisation go-ahead and naming strategy (GENERALISATION.md §6) | (A) rename tables/models now; (B) keep internal names, add generic API aliases and profile labels, rename internals later; (C) labels only | (B) | P7.1–P7.9 |
| D6 | Generalisation scope (GENERALISATION.md §7): target industries, cargo, recurring trips, multi-leg routes, booking ahead, payments | — | Start with skydiving + one second profile (dive boats), people only, single destination, same-day trips | P7.4, P7.9 |
| D7 | Is there a 2023 production database to carry forward? | (a) yes: provide a dump for migration rehearsal; (b) no: start fresh | (a) if it exists; all migrations in this plan preserve data either way | P8.8 |
| D8 | Peer-to-peer credit transfers between members (BUG-008) | (a) remove (only staff with `createUserTransaction` move credits); (b) keep, limited to the same dropzone and the sender's available balance | (a) | P6.7 |

## Executor instructions

These are the standing rules for every executor session. Read this whole section, then the task you pick, then every
document the task links, before changing anything.

### Session setup

1. Both repositories must be attached to the session (backend `OpenManifest/openmanifest-server`, client
   `OpenManifest/openmanifest`). If one is missing, stop and report it.
2. Start services and boot the apps as described in [`reference/CLOUD_ENV.md` §4](reference/CLOUD_ENV.md#4-per-session-commands).
   If the setup script version required by the task (CLOUD_ENV §1) is not installed, set the task to
   `owner-check (install setup script version X)` and stop.
3. Work on **exactly one task per session**.

### Picking the task

- Read the tasks in document order. Pick the first task whose `Status` is `todo` and whose `Depends on` tasks are all
  `done`. Skip tasks that are `blocked (…)` or `owner-check (…)`.
- If no task qualifies, report that and stop. Do not start a task whose dependencies are `owner-check`; the owner sets
  them to `done` after checking.

### Git workflow

- **Base branch**: `staging` (the default branch of both repos).
- For each task, run `git fetch origin staging` in every repo the task touches, then
  `git checkout -B modernise/p{phase}-{n}-{short-slug} origin/staging`. Use the `Branch:` value from the task exactly.
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

---

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
Status: blocked (awaiting decision D4)
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
Status: todo
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
Status: todo
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
Status: todo
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
  2. `yarn add -D @graphql-codegen/cli@latest @graphql-codegen/typescript@latest @graphql-codegen/typescript-operations@latest
     @graphql-codegen/typescript-react-apollo@latest @graphql-codegen/import-types-preset@latest @graphql-codegen/add@latest
     @graphql-codegen/introspection@latest @graphql-codegen/schema-ast@latest`.
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
Status: todo
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
Status: todo
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
Status: todo
Repo: both
Depends on: P3.1, P3.2, P3.4, P3.5, P3.6, P3.7, P3.8, P3.9, P3.10, P3.11, P3.12, P3.13, P3.14, P3.15, P3.16, P3.17, P3.18, P3.19, P3.20, P3.21
Branch: modernise/p3-22-verify
Goal: The upgraded client is proven in the VM and, by the owner, on real devices.
Context: Phase gate. P3.3 is excluded from the dependencies because it waits on D4. If D4 is still open, record it.
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
     context; remove the FIXMEs. Fix the permission branch: open the slot editor when the user has `updateSlot`, or
     `updateUserSlot` and the slot is their own.
  3. Delete `forms.manifest` and `forms.manifestGroup` slices.
  4. Tests: from the board, "Manifest group" opens the group sheet; tapping a slot on the load screen opens the user
     sheet; a user with only `updateUserSlot` can open their own slot but not others.
Acceptance criteria (cloud VM):
  - Client checks, web export and web smoke test pass; `grep -rnE "forms\.(manifest|manifestGroup)\b" app` prints nothing.
  - Web smoke test extended: open the group sheet from the board.
Acceptance criteria (owner, real device):
  - On a phone: manifest a group from the board and from the load screen; edit a slot by tapping it.
Out of scope: group manifest server bugs (P6.13).
Risk / rollback: central flow, covered by tests from P1.12. Revert.
Size: L
Fixes: BUG-066, BUG-079

### P4.8 — Remove Redux and make logout reset everything
Status: todo
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
Status: todo
Repo: both
Depends on: P4.1, P4.2, P4.3, P4.4, P4.5, P4.6, P4.7, P4.8
Branch: modernise/p4-9-verify
Goal: Client state is simplified and proven.
Context: Phase gate.
Steps:
  1. Run client checks, web export, web smoke test and `check:graphql`; record test counts.
  2. Write `backend:docs/verification/phase-4.md`. Add a "Backlog" line: "Apollo Client 4 (`@apollo/client` 4.x) —
     reconsider after Phase 6; requires `useQuery` callback removal and new error types."
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
Status: todo
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
Status: todo
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
  3. Add `testID`s `wizard-next-primary-action` and run `checkLayout` for `/signup` and `/wizards/dropzone` (with
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
Status: todo
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
Status: todo
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
  - Client checks, web export and web smoke test pass; `grep -rn "<BottomSheetModal" app | grep -v layout/Sheet.tsx` prints nothing.
Acceptance criteria (owner, real device):
  - Small Android phone: in each sheet (manifest user, group, credits, aircraft, ticket type, rig) focus the last input;
    the input and the save button stay visible.
Out of scope: sheet content redesign.
Risk / rollback: visual. Revert.
Size: L
Fixes: BUG-073 (sheets)

### P5.5 — Fix the manifest board and load screen
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
  3. Web smoke: run the board and a load at `html { font-size: 200% }` and check `checkLayout`.
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
  2. `MoveSlot`: require `updateSlot` (others) or `updateUserSlot` (own slot); source and target load must share the
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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
Status: todo
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

## Phase 7 — Generalisation

Goal: OpenManifest can serve operators other than skydiving dropzones through industry profiles, without renaming
tables or breaking released clients. Design: [GENERALISATION.md](reference/GENERALISATION.md), option B (generic API
aliases + profile labels; internal names unchanged). Steps 2 (`loads.dropzone_id`) and 6 (money in cents) of
GENERALISATION §6 are already done in P6.16 and P6.23.

All Phase 7 tasks are additive: old GraphQL fields stay, with `deprecation_reason`, until P8.7. Every phase-7 task
except P7.10 is blocked until D5 is decided; P7.4 and P7.9 also need D6.

### P7.1 — Add industry profiles
Status: blocked (awaiting decision D5)
Repo: backend
Depends on: P6.27
Branch: modernise/p7-1-industry-profiles
Goal: Dropzones have an `industry_profile` (default `skydiving`) and `profile_overrides`; the API exposes the merged
profile.
Context: GENERALISATION §3 (YAML example), §6 step 1.
Steps:
  1. Migration: `dropzones.industry_profile` string not null default `"skydiving"`, `profile_overrides` jsonb not null
     default `{}`.
  2. `config/industry_profiles/skydiving.yml` exactly as GENERALISATION §3; `IndustryProfile` PORO
     (`app/models/industry_profile.rb`) loaded with `Rails.application.config_for`-style YAML at boot, `deep_merge` with
     overrides, JSON-schema-like validation in a spec (required keys present).
  3. GraphQL `IndustryProfileType` (`slug`, `terminology` as JSON scalar, `destinationTypes`, `defaultCallScheduleMinutes`,
     `tripCrewRoles`, `units`) and `Dropzone.industryProfile`.
  4. Specs: default profile, override merge, GraphQL field.
Acceptance criteria (cloud VM):
  - Backend env: `bundle exec rspec` green; schema dump diff is additive only.
Acceptance criteria (owner, real device):
  - none
Out of scope: a second profile (P7.9).
Risk / rollback: additive; rollback drops columns.
Size: M
Fixes: none

### P7.2 — Add i18n to the client with profile terminology
Status: blocked (awaiting decision D5)
Repo: client
Depends on: P7.1
Branch: modernise/p7-2-i18n
Goal: The client has i18next with `common` and `terms` namespaces; `terms` come from the current dropzone's profile.
Context: GENERALISATION §5. Libraries: `i18next` (latest 25.x), `react-i18next` (latest 15.x), `expo-localization`
(`npx expo install`), `eslint-plugin-i18next` (latest).
Steps:
  1. `app/i18n/index.ts`: init with `lng` from `expo-localization`, fallback `en`, resources `en/common.json`,
     `en/terms.json` (skydiving defaults as fallback).
  2. `useProfileTerms()` hook: on current dropzone change, `i18n.addResourceBundle(lng, 'terms', terminology, true, true)`.
  3. Convert the tab labels and drawer items only (proof of wiring); tests for term switching.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export and web smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: converting all strings (P7.7, P7.8).
Risk / rollback: revert.
Size: M
Fixes: none

### P7.3 — Add unit conversion
Status: blocked (awaiting decision D5)
Repo: both
Depends on: P7.2
Branch: modernise/p7-3-units
Goal: Quantities are stored in SI and displayed in the operator's units.
Context: GENERALISATION §4 table. Altitude (feet in `ticket_types.altitude`), distances (miles in weather), mass
(`exit_weight` kg), speed (knots in winds JSON).
Steps:
  1. backend: `Units` module (`to_si`, `from_si`); SI columns added alongside existing ones for weather distances and
     mass (`exit_spot_m`, `offset_m`, `body_mass_kg`), backfilled; GraphQL SI fields added, old fields deprecated.
     Altitude moves with destinations in P7.4.
  2. client: `app/i18n/units.ts` (`formatQuantity`, `parseQuantity`, `compactAltitude`); unit system from
     `industryProfile.units` merged with dropzone settings; replace display/input of the affected fields.
  3. Unit tests for every conversion pair in the table; backend backfill spec.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: canopy area (stays ft² in the skydiving module).
Risk / rollback: old columns kept; revert both.
Size: L
Fixes: none

### P7.4 — Add destinations
Status: blocked (awaiting decisions D5, D6)
Repo: both
Depends on: P7.3
Branch: modernise/p7-4-destinations
Goal: Ticket types and slots reference a `Destination`; altitude becomes a destination kind.
Context: GENERALISATION §6 step 3; D6 scope decides whether `named_location`/`route` kinds are built now (recommendation:
`altitude` and `named_location` only).
Steps:
  1. backend: `destinations` table as GENERALISATION §6 step 3 (kinds per D6); backfill one altitude destination per
     distinct `(dropzone_id, altitude)`; `ticket_types.destination_id`, `slots.destination_id`; `TicketType.altitude`
     deprecated and computed. CRUD mutations `createDestination`/`updateDestination`/`archiveDestination` with
     `updateDropzone` permission.
  2. client: destinations configuration screen; `AltitudeSelect` replaced with `DestinationSelect`; ticket type form
     uses it.
  3. Specs and tests; backfill rehearsal on the P0.5 seed.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: multi-leg routes unless D6 includes them.
Risk / rollback: old column kept. Revert both.
Size: L
Fixes: none

### P7.5 — Make the call schedule configurable
Status: blocked (awaiting decision D5)
Repo: both
Depends on: P7.4
Branch: modernise/p7-5-call-schedule
Goal: Load call buttons (20/15/10 minutes) come from `dropzone.settings.callScheduleMinutes` (profile default).
Context: GENERALISATION §6 step 4; client `load/ActionButton.tsx` hard-codes calls.
Steps:
  1. backend: setting with default from profile; GraphQL `Settings.callScheduleMinutes: [Int!]!`; `updateDropzone` accepts it.
  2. client: ActionButton generates call actions from the setting; settings screen edits it.
  3. Specs/tests.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert both.
Size: S
Fixes: none

### P7.6 — Generalise trip crew roles
Status: blocked (awaiting decision D5)
Repo: both
Depends on: P7.5
Branch: modernise/p7-6-crew-roles
Goal: Pilot, GCA and load master become crew assignments driven by the profile's `trip_crew_roles`.
Context: GENERALISATION §6 step 5; `loads.pilot_id`, `gca_id`, `load_master_id`; `validates :gca, :pilot`.
Steps:
  1. backend: `trip_crew_assignments` table, backfill, model validation from the profile's required roles; old fields
     become deprecated mirrors kept in sync by a callback for one release.
  2. client: crew chips generated per role.
  3. Specs/tests.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: mirrors keep old clients working. Revert both.
Size: L
Fixes: none

### P7.7 — Convert manifest and load screens to translated terms
Status: blocked (awaiting decision D5)
Repo: client
Depends on: P7.6
Branch: modernise/p7-7-i18n-manifest
Goal: All user-visible strings under `app/screens/authenticated/dropzone/**` and `app/components/{load_card,slots_table}/**`
use `t()`; the `i18next/no-literal-string` rule is enabled for those directories.
Context: GENERALISATION §5.
Steps:
  1. Replace literals with keys in `common.json`; skydiving terms via `terms:` keys.
  2. Enable `i18next/no-literal-string` (mode `jsx-text-only`) for the converted directories in `eslint.config.js`.
Acceptance criteria (cloud VM):
  - Client checks, web export and smoke test pass; web smoke screenshots show identical English copy.
Acceptance criteria (owner, real device):
  - none
Out of scope: other directories (P7.8).
Risk / rollback: revert.
Size: L
Fixes: none

### P7.8 — Convert the remaining screens to translated terms
Status: blocked (awaiting decision D5)
Repo: client
Depends on: P7.7
Branch: modernise/p7-8-i18n-rest
Goal: All remaining screens and components use `t()`; the lint rule covers `app/**`.
Context: As P7.7.
Steps:
  1. As P7.7 for every remaining directory; enable the rule for `app/**` (exclude tests and `app/api/**`).
Acceptance criteria (cloud VM):
  - Client checks, web export and smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: translations into other languages.
Risk / rollback: revert.
Size: L
Fixes: none

### P7.9 — Add the second industry profile
Status: blocked (awaiting decisions D5, D6)
Repo: both
Depends on: P7.8
Branch: modernise/p7-9-second-profile
Goal: A second profile (D6; recommendation: `diving`) works end to end in the web smoke test.
Context: GENERALISATION §3 and §7.
Steps:
  1. backend: `config/industry_profiles/<slug>.yml`; seeds for a demo operator in `db/seeds/dev_baseline.rb`.
  2. client: hide equipment/licence/winds screens when the profile disables them; conditions module switch.
  3. Web smoke test: log in as the demo operator's admin, create a trip, manifest two participants; terms show the
     profile's words.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export and smoke test (both profiles) pass.
Acceptance criteria (owner, real device):
  - Owner reviews the second profile's screens on a phone and confirms the terminology.
Out of scope: further profiles.
Risk / rollback: revert both.
Size: L
Fixes: none

### P7.10 — Verify Phase 7
Status: todo
Repo: both
Depends on: P7.1, P7.2, P7.3, P7.4, P7.5, P7.6, P7.7, P7.8, P7.9
Branch: modernise/p7-10-verify
Goal: Generalisation is proven for both profiles.
Context: Phase gate. If D5 is decided as "no generalisation", the owner sets P7.1–P7.9 to `done (skipped by D5)` and
this task only records that.
Steps:
  1. Run all backend and client checks, web export and smoke test for both profiles.
  2. Write `docs/verification/phase-7.md`; update GENERALISATION.md with what was built and what remains.
Acceptance criteria (cloud VM):
  - All commands exit 0; CI green on `staging`.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none

---

## Phase 8 — Release

Goal: versioned, deployable, store-ready builds of both apps on the infrastructure chosen in D1 and accounts confirmed
in D2, with production data migrated per D7.

### P8.1 — Add versioning and changelogs
Status: todo
Repo: both
Depends on: P7.10
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
Goal: The API builds into a production Docker image and deploys to the D1 host with Postgres, Redis (ActionCable),
object storage and the Solid Queue worker.
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
Context: Deprecated in Phases 6–7 (float money fields, `ticketType.altitude`, crew mirrors), and `loginWithFacebook`
if D4 removed Facebook. Only remove fields that the client at the version released in P8.8 no longer queries
(`check:graphql` proves it).
Steps:
  1. backend: list deprecated fields (`grep -rn deprecation_reason app/graphql`); remove those not used by
     `client:app/api/**/*.gql`; remove `loginWithFacebook` if D4 = (a).
  2. client CI: job `web-smoke` that checks out the backend `staging` branch, starts Postgres/Redis services, loads the
     dev seed, boots Rails, builds the web export with `EXPO_ENV=local`, and runs `scripts/web-smoke.mjs`.
Acceptance criteria (cloud VM):
  - Backend rspec green; client `check:graphql` green against the new schema; the new CI job passes on the PR.
Acceptance criteria (owner, real device):
  - none
Out of scope: dropping old database columns (P8.8).
Risk / rollback: revert.
Size: M
Fixes: none

### P8.8 — Migrate production data and submit to the stores
Status: blocked (awaiting decision D7)
Repo: both
Depends on: P8.6, P8.7
Branch: modernise/p8-8-production-release
Goal: The production database is migrated (or created fresh per D7), and version 2.0.0 is submitted to the App Store and
Play Store.
Context: Data-changing migrations from P6.10, P6.16, P6.23, P7.x. Old money/unit columns are dropped after this release
in a follow-up.
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

## Deferred bugs

Bugs not in any task's `Fixes:` line, with the reason.

| Bug | Reason | Where it is handled |
|---|---|---|
| BUG-085 | Suspected only (client#127, maps not loading on web/Android); cannot be confirmed without valid `GOOGLE_MAPS_*` keys, which the VM does not have. | Owner checks maps in P3.22. If confirmed, the executor adds a task after P5.10 (replace `react-native-maps` web shim / configure keys via EAS secrets) with `Fixes: BUG-085`. |
| BUG-100 | Cold loads of permission-gated tab URLs (`/users`, `/user/<id>`) end on `/`. The fix needs a decision: always register the tabs and show a no-access state, or hold the navigator until permissions are loaded. | The executor adds a task after P4.8 (when the session store makes permissions available before navigation mounts); until then the smoke test only deep-links ungated routes. |
