# Claude Code cloud environment for OpenManifest

Everything an executor session needs to run both apps in a Claude Code cloud session (Ubuntu 24.04, 4 vCPU, 16 GB,
restricted network). Measured in pass 1 (2026-10-08).

What the base image already has: Ruby 3.1.6 / 3.2.6 / 3.3.6 under rbenv (`RBENV_ROOT=/opt/rbenv`, shims on `PATH`),
Node 20/21/22 (`/opt/node20` … ; Node 22 on `PATH`), PostgreSQL 16 and Redis 7 (not running), Docker (daemon not
running; `service docker start` works), Chromium for Playwright at `/opt/pw-browsers`, a global `playwright` package at
`/opt/node-tools/node_modules/playwright`.

What it lacks (installed by the script): `libpq-dev` (the `pg` gem fails without it), `libvips` (image_processing),
Bundler 2.3.26, Node 24, the `local.openmanifest.org` host entry.

## 1. Setup script (paste into the environment's "Setup script" field)

Version **A** — use from Phase 0 until task P2.5 (the first task that needs Ruby 3.4). Runs in ~15 s on a warm image,
well under 5 minutes. Always exits 0.

```bash
#!/usr/bin/env bash
# OpenManifest — Claude Code cloud environment setup script (version A: Phases 0, 1 and 2 up to P2.5)
# Idempotent. Non-critical steps never fail the script. Target runtime: < 5 minutes.
set -u
log() { echo "[openmanifest-setup] $*"; }
START=$(date +%s)
export DEBIAN_FRONTEND=noninteractive

# 1. System packages: libpq-dev for the pg gem, libvips for image_processing, build tools.
log "apt packages"
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq --no-install-recommends libpq-dev libvips42 imagemagick libyaml-dev build-essential pkg-config >/dev/null 2>&1 \
  || apt-get install -y -qq libpq-dev >/dev/null 2>&1 || log "WARN: apt install failed"

# 2. Ruby: the preinstalled rbenv Ruby 3.1.6 + the Bundler version in Gemfile.lock.
export RBENV_ROOT=/opt/rbenv
export PATH="/opt/rbenv/shims:/opt/rbenv/bin:$PATH"
log "bundler 2.3.26 for Ruby 3.1.6"
RBENV_VERSION=3.1.6 gem install bundler -v 2.3.26 --no-document >/dev/null 2>&1 || log "WARN: bundler install failed"
RBENV_VERSION=3.1.6 gem install bundler-audit --no-document >/dev/null 2>&1 || true

# 3. Node 24 LTS (used from Phase 3); Node 20 (preinstalled at /opt/node20) is used for Phases 0-2.
NODE24=v24.21.0
if [ ! -x /opt/node24/bin/node ]; then
  log "node $NODE24"
  (curl -fsSL "https://nodejs.org/dist/$NODE24/node-$NODE24-linux-x64.tar.xz" -o /tmp/node24.tar.xz \
    && mkdir -p /opt/node24 && tar -xJf /tmp/node24.tar.xz -C /opt/node24 --strip-components=1 && rm -f /tmp/node24.tar.xz) \
    || log "WARN: node 24 download failed"
fi
for n in /opt/node20 /opt/node24; do
  [ -x "$n/bin/corepack" ] && "$n/bin/corepack" enable --install-directory "$n/bin" >/dev/null 2>&1 || true
done
/opt/node20/bin/npm install -g yarn@1.22.22 >/dev/null 2>&1 || true

# 4. Host name used by the client's "local" environment (build/constants.ts).
grep -q "local.openmanifest.org" /etc/hosts || echo "127.0.0.1 local.openmanifest.org" >> /etc/hosts || true

# 5. Postgres role used by the docs/commands (password auth over TCP).
(service postgresql start >/dev/null 2>&1 && sleep 2 \
  && su postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='root'\" | grep -q 1 || psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'root';\"" >/dev/null 2>&1 \
  && service postgresql stop >/dev/null 2>&1) || log "WARN: postgres role setup failed"

# 6. Docker images used as a fallback for newer Rubies when cache.ruby-lang.org is not allowlisted (see CLOUD_ENV.md).
# Disabled in version A; enable in version B:
# (service docker start >/dev/null 2>&1; docker pull -q ruby:3.4.11-bookworm >/dev/null 2>&1; service docker stop >/dev/null 2>&1) || true

log "done in $(( $(date +%s) - START ))s"
exit 0
```

### Script versions by phase

The executor cannot edit the environment; the owner swaps the script when the plan reaches the listed task (the task is
marked `owner-check` until then).

| Version | Use from | Change to version A |
|---|---|---|
| A | P0.1 | (as above) |
| B | P2.5 (Ruby 3.4.11) | Add after step 2: `RUBY_CONFIGURE_OPTS=--disable-install-doc MAKE_OPTS=-j4 rbenv install -s 3.4.11 >/dev/null 2>&1 || log "WARN: ruby 3.4.11 build failed"` and `RBENV_VERSION=3.4.11 gem install bundler --no-document >/dev/null 2>&1 || true`. Requires `cache.ruby-lang.org` on the allowlist (§2). Compiling adds ~4 minutes once; the cached image keeps it. |
| C | P2.9 (Ruby 4.0.7) | Same as B with `4.0.7` instead of `3.4.11`; remove the 3.4.11 line once P2.9 is `done`. Remove the `RBENV_VERSION=3.1.6` lines (no longer needed). |
| D | P3.15 (client on Node 24) | No script change (Node 24 is installed by version A); the per-session commands switch from `/opt/node20` to `/opt/node24`. |

If `cache.ruby-lang.org` cannot be allowlisted, versions B/C instead uncomment step 6 (pull `ruby:3.4.11-bookworm` /
`ruby:4.0.7-bookworm`) and the executor runs Ruby commands in that image — see §4 "Docker fallback for Ruby".

## 2. Network allowlist additions

Hosts that pass 1 found **blocked** and that the work needs:

| Host | Needed for | Needed from | Without it |
|---|---|---|---|
| `cache.ruby-lang.org` | `rbenv install` (ruby-build downloads Ruby source tarballs) | P2.5 | Use the Docker fallback for Ruby (§4) |
| `api.expo.dev` | `npx expo install --fix` and `npx expo-doctor` fetch SDK version data | P3.5 | Run with `EXPO_OFFLINE=1` (versions come from the installed `expo/bundledNativeModules.json`); `expo-doctor` checks that need the network are skipped |
| `exp.host` | Expo push API (manual push testing only) | optional | Push sending fails silently in dev (it already swallows errors) |
| `downloads.sentry-cdn.com` | `@sentry/cli` postinstall binary (pulled in by `sentry-expo`) | until P3.2 removes `sentry-expo` | Set `SENTRYCLI_SKIP_DOWNLOAD=1` (already in §3) |
| `appsignal-agent-releases.global.ssl.fastly.net`, `d135dj0rjqvssy.cloudfront.net` | AppSignal native agent during `bundle install` | optional | Harmless warning `LoadError: cannot load such file -- appsignal_extension`; app runs |

Reachable already (verified): `github.com`, `raw.githubusercontent.com`, `rubygems.org`, `registry.npmjs.org`,
`nodejs.org`, `www.ruby-lang.org`, Docker Hub (`registry-1.docker.io`), `ghcr.io`.

## 3. Environment variables (environment settings, no secrets)

| Variable | Value | Why |
|---|---|---|
| `BASH_DEFAULT_TIMEOUT_MS` | `300000` | yarn installs, web exports and spec runs exceed the 2-minute default |
| `BASH_MAX_TIMEOUT_MS` | `600000` | allow 10-minute foreground commands |
| `SENTRYCLI_SKIP_DOWNLOAD` | `1` | only needed until P3.2 removed `sentry-expo` (its postinstall downloaded a binary from a blocked host); harmless afterwards |
| `DISABLE_SPRING` | `1` | Spring forks a background server that confuses repeated runs |
| `PGHOST` / `PGUSER` / `PGPASSWORD` | `localhost` / `root` / `root` | local throwaway Postgres role created by the setup script (not a secret) |
| `BACKEND_URL` | `http://local.openmanifest.org:5000/` | Rails boot requires it (`config/environments/development.rb`, routes); `bundle exec rspec` needs it too (the master-log specs build blob URLs and fail with "Missing host to link to" without it; CI sets `http://localhost:5000/`) |
| `WEB_CONCURRENCY` | `0` | single-process Puma in the VM |
| `EXPO_NO_TELEMETRY` | `1` | avoid blocked telemetry calls |
| `CI` | `1` | non-interactive Expo/Jest |

`SECRET_KEY_BASE` must not be stored in the environment; generate it per session (§4).

## 4. Per-session commands

Repos are checked out side by side (e.g. `/home/user/openmanifest-server` and `/home/user/openmanifest`); adjust
`cd` paths if the session uses different roots. Run long commands in the background and poll their log files.

### Services

```bash
service postgresql start
service redis-server start
export SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### Backend

```bash
cd /home/user/openmanifest-server
export PATH=/opt/rbenv/shims:$PATH              # /usr/local/bin/ruby is 3.3.6; the rbenv shims honour .ruby-version
# Since P0.2 .ruby-version (3.1.6) selects the Ruby automatically. On older branches that pin 3.1.3:
#   export RBENV_VERSION=3.1.6 and run Bundler from a scratch copy whose Gemfile says ruby "3.1.6".
bundle install --jobs 4                         # ~3 min the first time in a session; gems go to the rbenv Ruby, not vendor/
RAILS_ENV=test bin/rails db:create db:schema:load
bundle exec rspec                                # ~45 s
bundle exec rubocop --parallel
bundle-audit check --update || true

# Development server with seed data (P0.5 adds db/seeds/dev_baseline.rb)
bin/rails db:create db:schema:load db:seed
bin/rails db:seed:dev_baseline                   # after P0.5
nohup bin/rails s -b 0.0.0.0 -p 5000 > /tmp/rails.log 2>&1 &
curl -s -o /dev/null -w "%{http_code}\n" http://local.openmanifest.org:5000/graphql   # expect 200
```

Login for seeded data (after P0.5): `owner@example.com` / `Password1!`.

### Client

```bash
cd /home/user/openmanifest
export PATH=/opt/node20/bin:$PATH              # Phases 0-2. From P3.15: /opt/node24/bin
yarn install --frozen-lockfile                 # ~1 min
yarn check:types && yarn check:linting
npx jest --ci                                  # after P0.6: yarn check:testing
EXPO_ENV=local npx expo export --platform web  # Metro (since P3.7) -> dist/ ; ~1 min. Before P3.7 (SDK 47-49): `npx expo export:web` -> web-build/ (webpack, ~5 min)
```

Serving the web build and running the smoke script (both added by P0.8):

```bash
python3 scripts/serve-web-build.py dist 19006 &           # SPA server with index.html fallback (web-build before P3.7)
TZ=Australia/Brisbane node scripts/web-smoke.mjs --base http://localhost:19006 --out /tmp/smoke   # logs in as owner@example.com, screenshots 360x640 and 1280x800
```

Run the smoke test with `TZ=Australia/Brisbane`: the board asks for loads for the *device's* date (BUG-068) while the
seeded dropzone lives in Brisbane, so a browser in UTC sees "No loads so far today" for several hours of every day and
the smoke test fails at the load step.

Headless Chromium must bypass the agent proxy for the API host, otherwise the websocket gets 403:
`--proxy-bypass-list=local.openmanifest.org,localhost` (the smoke script passes it).

### Docker fallback for Ruby (only if `cache.ruby-lang.org` is not allowlisted)

```bash
service docker start
docker run --rm --network host -v "$PWD":/app -w /app \
  -e PGHOST -e PGUSER -e PGPASSWORD -e SECRET_KEY_BASE -e BACKEND_URL -e RAILS_ENV=test \
  ruby:3.4.11-bookworm bash -lc "apt-get update -qq && apt-get install -y -qq libpq-dev libvips42 >/dev/null && bundle install --jobs 4 && bundle exec rspec"
```

Verified in the P2.5 session (cloud VM without `cache.ruby-lang.org`): `service docker start` fails (`ulimit: error
setting limit`), but the daemon runs when started by hand, and Docker Hub is reachable:

```bash
(nohup dockerd --iptables=false --bridge=none --storage-driver=vfs > /tmp/dockerd.log 2>&1 &); sleep 12
docker pull ruby:3.4.11-bookworm            # ~50 s; `ruby:4.0.7-bookworm` for P2.9
docker rm -f rb34 2>/dev/null
docker run -d --name rb34 --network host -v "$PWD":/app -w /app -v rb34-gems:/usr/local/bundle \
  -e PGHOST=localhost -e PGUSER=root -e PGPASSWORD=root -e BACKEND_URL=http://local.openmanifest.org:5000/ \
  -e DISABLE_SPRING=1 -e WEB_CONCURRENCY=0 ruby:3.4.11-bookworm sleep infinity
docker exec rb34 bash -lc 'cd /app && bundle install --jobs 4'
docker exec -e SECRET_KEY_BASE=$(openssl rand -hex 64) rb34 bash -lc 'cd /app && bundle exec rspec'
# dev server for the web smoke test (host networking, so the host's Playwright reaches it on :5000)
docker exec -d -e SECRET_KEY_BASE=$(openssl rand -hex 64) rb34 bash -lc 'cd /app && bin/rails s -b 0.0.0.0 -p 5000 > /tmp/rails.log 2>&1'
```

Notes: Postgres and Redis keep running on the host (`--network host`). `apt-get` inside the container does not work
(`deb.debian.org` is blocked), so only what the image ships is available: the full (not `-slim`) image has `libpq-dev`,
but **no libvips**; Rails boots and the whole suite passes without it (image variants are therefore not verified in
this fallback). A stale Puma on the host also keeps :5000 busy: `ps aux | grep puma` and kill it before starting the container's
server (`ss` prints nothing in this VM).

## 5. What changes as the phases progress

| From task | Change |
|---|---|
| P0.2 | Drop `RBENV_VERSION=3.1.6` and the scratch-copy workaround; `.ruby-version` is `3.1.6` |
| P0.5 | `bin/rails db:seed:dev_baseline` exists |
| P0.8 | `scripts/serve-web-build.py`, `scripts/web-smoke.mjs` exist in the client repo |
| P2.5 | Setup script version B; Ruby 3.4.11 (`.ruby-version`) |
| P2.9 | Setup script version C; Ruby 4.0.7 |
| P3.5 | `api.expo.dev` should be allowlisted for `npx expo-doctor` (otherwise `EXPO_OFFLINE=1`) |
| P3.7 | done: web export command is `npx expo export --platform web` (output `dist/`); serve `dist` instead of `web-build` |
| P3.15 | Client uses `/opt/node24/bin` |
| P6.17 (Solid Queue) | Start the job worker in a second process: `bin/jobs` |
