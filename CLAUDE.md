# CLAUDE.md — OpenManifest API

Rails GraphQL API for OpenManifest (skydiving dropzone manifest). The Expo client is the companion repo
`OpenManifest/openmanifest`.

**Source of truth:** [`docs/MODERNISATION_PLAN.md`](docs/MODERNISATION_PLAN.md) in this repo. It covers both repos; the
client repo's copy is only a pointer.

Before doing any work:

1. Read the plan's **Executor instructions** section first and follow it exactly (one task per session, branch naming,
   PRs, status updates in this file's plan, stop conditions).
2. Then read the task you picked and every document it links.

Reference: [`docs/reference/README.md`](docs/reference/README.md) (system reference),
[`BUGS.md`](docs/reference/BUGS.md) (bug register for both repos), [`diagrams.md`](docs/reference/diagrams.md),
[`GENERALISATION.md`](docs/reference/GENERALISATION.md), [`CLOUD_ENV.md`](docs/reference/CLOUD_ENV.md) (cloud VM
setup script, allowlist, env vars, per-session commands).

Quick commands (see CLOUD_ENV §4 for the environment variables): `service postgresql start && service redis-server start`,
`bundle exec rspec`, `bundle exec rubocop`, `bin/rails s -p 5000`.
Never commit secrets, `.env` files, `vendor/bundle` or `.bundle/`.
