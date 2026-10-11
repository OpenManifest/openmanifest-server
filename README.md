![Heroku](https://img.shields.io/badge/heroku-%23430098.svg?style=for-the-badge&logo=heroku&logoColor=white)
![GraphQL](https://img.shields.io/badge/-GraphQL-E10098?style=for-the-badge&logo=graphql)
![Rails](https://img.shields.io/badge/rails-%23CC0000.svg?style=for-the-badge&logo=ruby-on-rails&logoColor=white)

# OpenManifest API
![CI](https://github.com/OpenManifest/openmanifest-server/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/openmanifest/openmanifest-server/actions/workflows/release.yml/badge.svg)
![Production](https://github.com/openmanifest/openmanifest-server/actions/workflows/release-production.yml/badge.svg)



This is the backend server for OpenManifest, written with Rails using GraphQL and authenticated with `devise_graphql`. If you want to contribute to the OpenManifest backend, fork this repository and follow the setup instructions below

## Requirements

- Ruby from `.ruby-version` (3.1.6) with Bundler 2.3.26
- PostgreSQL 16 and Redis 7
- System packages: `libpq-dev`, `libvips` (Debian/Ubuntu: `apt-get install -y libpq-dev libvips42`)

## Getting started

Configuration comes from environment variables; `.env.example` lists them (copy it to `.env` for local work, never
commit `.env`). The database user is taken from `PGUSER`/`PGPASSWORD`.

```
$ service postgresql start && service redis-server start
$ export PGHOST=localhost PGUSER=root PGPASSWORD=root SECRET_KEY_BASE=$(openssl rand -hex 64) \
         BACKEND_URL=http://local.openmanifest.org:5000/ DISABLE_SPRING=1
$ gem install bundler -v 2.3.26
$ bundle install
$ bin/rails db:create db:schema:load db:seed
```

The client's `local` environment calls `http://local.openmanifest.org:5000`, so add `127.0.0.1 local.openmanifest.org`
to `/etc/hosts`.

### Tests and linting

```
$ RAILS_ENV=test bin/rails db:create db:schema:load
$ bundle exec rspec
$ bundle exec rubocop --parallel
```

## Development data

`bin/rails db:seed db:seed:dev_baseline` creates an offline demo dropzone ("Demo Dropzone") with staff, jumpers, an
aircraft, ticket types and two loads. It needs no network access and can be run repeatedly. Log in as
`owner@example.com` / `Password1!` (all seeded users share this password).

## Start the server locally

```
$ bin/rails db:seed:dev_baseline
$ bin/rails server -b 0.0.0.0 -p 5000
$ curl -s -o /dev/null -w "%{http_code}\n" http://local.openmanifest.org:5000/graphql   # 200
```

## Documentation

- [`docs/reference/README.md`](docs/reference/README.md): system reference (domain, architecture, multi-tenancy, API).
- [`docs/MODERNISATION_PLAN.md`](docs/MODERNISATION_PLAN.md): the plan for reviving and modernising both repos.
- [`docs/reference/CLOUD_ENV.md`](docs/reference/CLOUD_ENV.md): setting up a Claude Code cloud environment.
