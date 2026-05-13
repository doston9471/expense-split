# Expense Split

Rails **8.1** expense-sharing app: rooms, equal splits, balance projection, settlements, **tracked invitations**, and **Rails Event Store** for domain events. Business logic lives under `app/domains` (modular monolith / bounded contexts).

## Stack

| Layer | Choice |
|--------|--------|
| Runtime | Ruby **4.0.4** |
| Framework | Rails **8.1** |
| DB | PostgreSQL **16** |
| Auth | Devise |
| Authorization | Pundit |
| Events | Rails Event Store (ActiveRecord repository) |
| UI | Hotwire (Turbo + Stimulus), Tailwind CSS |

## Quick start (local Ruby + Docker Postgres only)

1. **PostgreSQL** (Docker):

   ```bash
   docker compose up -d postgres
   ```

2. **Ruby & gems** (rbenv / asdf with Ruby 4.0.4):

   ```bash
   bundle install
   cp .env.example .env   # recommended: dotenv-rails loads this for local Rails
   bin/rails db:prepare
   bin/dev                 # or: bin/rails server
   ```

   Local Rails uses host port **15432** by default (`config/database.yml` development/test + `docker-compose.yml`), so it does not collide with another PostgreSQL on **5432**. To use only a local Postgres on 5432 instead of Docker, set **`DATABASE_PORT=5432`** (and matching host) in **`.env`**. Optional sanity check:

   ```bash
   docker compose exec postgres psql -U ddd_eds -d postgres -c "select current_user"
   ```

3. Open **http://localhost:3000**, sign up, create a room, share the **room link** or a **tracked invitation**.

## Full stack in Docker (Rails + Postgres)

Runs the app inside Docker with code mounted from the host (good for trying the stack without local Ruby).

```bash
docker compose up --build
```

Then open **http://localhost:3000**.

Equivalent using the project **Makefile**: `make start` (see [Makefile commands](#makefile-commands)).

- **Web** service: `Dockerfile.dev`, entrypoint `bin/docker-entrypoint-web` (waits for Postgres, `bundle install` if needed, `db:prepare`, then `rails server`).
- **Postgres**: hostname from the web container is `postgres` (`DATABASE_HOST` is set in compose).
- **URL helpers** (invite links, mailers): set `APPLICATION_HOST` and optionally `APPLICATION_PORT` in `.env` (defaults: `localhost` / `3000`). See `config/initializers/url_options.rb`.

### Environment variables (reference)

| Variable | Purpose |
|----------|---------|
| `DATABASE_HOST` | DB host (`postgres` in compose, `127.0.0.1` locally) |
| `DATABASE_PORT` | DB port (`5432` inside the Docker network; **15432** on the host by default) |
| `POSTGRES_PORT` | Host port published for the Postgres container (default **15432**) |
| `DATABASE_USER` / `DATABASE_PASSWORD` | DB credentials |
| `APPLICATION_HOST` / `APPLICATION_PORT` | Host/port for `*_url` helpers |
| `WEB_PORT` | Host port mapped to the web container (default `3000`) |

Copy **`.env.example`** to **`.env`** and adjust.

## Makefile commands

From the repo root, **`make`** or **`make help`** lists targets. Summary:

| Command | What it does |
|---------|----------------|
| `make help` | Print targets and short descriptions (also the default when you run `make` with no arguments). |
| `make start` | `docker compose up -d --build postgres web` — full stack in the background. |
| `make stop` | `docker compose down` — stop and remove containers for this project; **Postgres data volume is kept**. |
| `make test` | `bundle exec rspec` — needs a reachable test database (same rules as [Tests](#tests)). |
| `make reset` | `bin/rails db:reset` — if the **`web`** compose service is running, runs inside that container; otherwise uses **local** `bin/rails` (hybrid Postgres-in-Docker + host Ruby). **Drops and recreates the development database.** |
| `make clean` | `docker compose down --remove-orphans` — like `make stop`, plus removal of **orphan** containers left over from older compose files. |
| `make lint` | **RuboCop** — Omakase rules; cache directory **`tmp/rubocop`** (ignored by git via `tmp/`). |
| `make lint-ci` | RuboCop with **GitHub** formatter (for Actions-style output). |
| `make brakeman` | **Brakeman** — same flags as **`bin/ci`**: `--quiet --no-pager --exit-on-warn --exit-on-error`. |
| `make bundler-audit` | **bundler-audit** — known vulnerable gems in `Gemfile.lock`. |
| `make importmap-audit` | **importmap** vulnerability audit for pinned JS. |
| `make check` | Runs **`lint`**, **`brakeman`**, **`bundler-audit`**, and **`importmap-audit`** in sequence (same static checks as CI, minus the DB-backed **test** job). |

Requires **Docker Compose V2** (`docker compose` on your `PATH`) for stack-related targets. Lint and security targets only need Ruby and `bundle install`.

For a full local gate similar to CI (including DB setup), use **`bin/ci`** (see `config/ci.rb`).

GitHub Actions (`.github/workflows/ci.yml`) runs **RuboCop**, **Brakeman**, **bundler-audit**, **importmap audit**, and **RSpec** (with PostgreSQL 16) on pushes and pull requests to `main`.

## Bounded contexts (`app/domains`)

| Context | Responsibility |
|---------|----------------|
| **Identity** | Users (Devise); thin AR in `app/models/user.rb` |
| **Rooms** | Room lifecycle, archive, room-level invite token |
| **Memberships** | Join/leave, roles (`owner` / `member`) |
| **Invitations** | Tracked invites: optional email lock, expiry, revoke, accept → membership + events |
| **Expenses** | Equal split (extensible to % / shares), commands + services |
| **Balances** | Read model rebuilt from expenses + settlements (idempotent subscriber) |
| **Settlements** | Record cash transfers between members |

Domain events are stored in Rails Event Store (PostgreSQL) and published to per-room streams `Room$<uuid>`.

## Invitations vs room link

- **Room link** (`/join/:token`): uses `Room#invite_token`. Any signed-in user can join while the room is active.
- **Tracked invitation** (`/invitations/:token`): stored row with **expiry** (14 days), **revoke**, optional **email** (accept only if the signed-in user’s email matches). Emits `InvitationCreated`, `InvitationAccepted`, `InvitationRevoked` plus `MemberJoined` on successful accept.

## Tests

Requires PostgreSQL and role/database matching `config/database.yml`. With Docker: `docker compose up -d postgres`, then `bin/rails db:test:prepare` (development and test default to host port **15432** unless you set **`DATABASE_PORT`**).

Layout:

- **`spec/models/`** — ActiveRecord models (validations, associations, helpers).
- **`spec/domains/`** — bounded contexts: services, repositories, policies, queries, subscribers (many examples use `type: :model` for transactional DB access).

```bash
bin/rails db:test:prepare
bundle exec rspec
# or: make test   (same as bundle exec rspec; ensure DB is up)
```

## API stub

- `GET /api/v1/status` — versioned JSON placeholder for a future mobile API.

## Production image

The default **`Dockerfile`** (from `rails new`) targets Kamal/production (Thruster, `RAILS_ENV=production`). Use **`Dockerfile.dev`** + **`docker-compose.yml`** for local full-stack Docker.

## Deploy to Heroku

This app is a standard **Rails 8 + PostgreSQL** stack. Heroku provides a single **`DATABASE_URL`**; `config/database.yml` uses it for **primary, Solid Cache, Solid Queue, and Solid Cable** (same physical database, separate migration paths).

### Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) logged in (`heroku login`).
- Git remote for the Heroku app (create app first, then `heroku git:remote -a your-app-name`).

### One-time setup

```bash
heroku create your-app-name
heroku stack:set heroku-24
heroku addons:create heroku-postgresql:essential-0
heroku buildpacks:set heroku/ruby
```

### Required config vars

| Variable | Purpose |
|----------|---------|
| `RAILS_MASTER_KEY` | Contents of `config/master.key` (or set `SECRET_KEY_BASE` instead if you do not use credentials). |
| `APPLICATION_HOST` | Public hostname for URL helpers and Devise (no scheme), e.g. `your-app-name.herokuapp.com`. On Heroku you can **omit** this if **`HEROKU_APP_NAME`** is set (the app derives `https://YOUR_APP.herokuapp.com`). Always set it for **custom domains**. |
| *(none for queue)* | **Recommended:** do **not** set `SOLID_QUEUE_IN_PUMA`. Use the **`worker`** process in the `Procfile` and scale it (see below). |
| `SOLID_QUEUE_IN_PUMA` | Optional `true` only if you insist on **one dyno**: runs Solid Queue inside Puma. Heroku often sets **`WEB_CONCURRENCY` > 0**; `config/puma.rb` then **forces `WEB_CONCURRENCY=0`** so the supervisor is not killed by clustered workers (avoids *"Solid Queue has gone away, stopping Puma"*). |

Optional: `RAILS_LOG_LEVEL`, `JOB_CONCURRENCY` (defaults in `config/queue.yml`).

```bash
heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)"
# Optional on Heroku if HEROKU_APP_NAME is set (URL helpers still work):
# heroku config:set APPLICATION_HOST=your-app-name.herokuapp.com
heroku ps:scale web=1 worker=1
```

Do **not** set `SOLID_QUEUE_IN_PUMA` when using a **worker** dyno (default above). Only set `SOLID_QUEUE_IN_PUMA=true` if you want a single dyno and accept one Puma process for both HTTP and jobs.

Heroku sets **`DATABASE_URL`**, **`HEROKU_APP_NAME`**, **`PORT`**, and **`RAILS_ENV=production`** automatically.

### Deploy

```bash
git push heroku main
```

The root **`Procfile`** runs **`rails db:migrate`** on release, **`puma`** for `web`, and **`rails solid_queue:start`** for `worker`. Scale the worker (`heroku ps:scale worker=1`) or jobs will stay queued.

### After first deploy

- Open `https://YOUR_HOST` and hit **`/up`** if you need a quick health check.
- If you use a **custom domain**, add it in Heroku, set **`APPLICATION_HOST`** to that hostname, and consider enabling **`config.hosts`** for it (already supported when `HEROKU_APP_NAME` is unset via **`APPLICATION_HOST`** in `config/environments/production.rb`).

### Notes

- **SSL**: `config/environments/production.rb` enables `force_ssl` and `assume_ssl` for reverse-proxy TLS (Heroku router).
- **Action Cable (Turbo Streams)**: Uses **Solid Cable** backed by Postgres (no Redis addon required).
- **Tailwind**: The Heroku Ruby buildpack runs **`rake assets:precompile`**; `tailwindcss-rails` hooks into that pipeline.
- **Non-Heroku production** (e.g. Kamal): leave **`DATABASE_URL`** unset and continue using **`DDD_EDS_DATABASE_PASSWORD`** and separate database names as before.

### Web dyno crashes: *"Detected Solid Queue has gone away, stopping Puma"*

Heroku’s Ruby buildpack often sets **`WEB_CONCURRENCY`** to a value **greater than 0** so Puma runs in **cluster** mode. Solid Queue’s **in-Puma** supervisor does not survive that; it exits and Puma shuts down (**H10**).

**Fix (pick one):**

1. **Recommended:** `heroku config:unset SOLID_QUEUE_IN_PUMA` and run a **`worker`** dyno (`heroku ps:scale worker=1`). The repo **`Procfile`** already defines `worker: bundle exec rails solid_queue:start`.
2. **Single dyno:** keep `SOLID_QUEUE_IN_PUMA=true`. Current **`config/puma.rb`** forces **`WEB_CONCURRENCY=0`** when both are set, so the supervisor stays in a single Puma process.

### Sign-up or forms return **403** / session issues

- **Blocked host:** Production enables host authorization. On Heroku we allow **any** `*.herokuapp.com` when **`DYNO`** is set, and your **`APPLICATION_HOST`** when set. Deploy the latest `config/environments/production.rb` if you still see `Blocked hosts` in logs.
- **URL defaults:** If you never set `APPLICATION_HOST`, `config/initializers/url_options.rb` now falls back to **`HEROKU_APP_NAME.herokuapp.com`** on Heroku so Devise and `*_url` helpers use HTTPS.
- **App crashed (H10):** Fix Solid Queue + Puma first (see section above); a crashed web dyno breaks every route including sign up.

## License

Private / your choice — add a `LICENSE` file if you open-source the project.
