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
| `APPLICATION_HOST` | Public hostname for URL helpers and Devise (no scheme), e.g. `your-app-name.herokuapp.com` or your custom domain. |
| `SOLID_QUEUE_IN_PUMA` | Set to `true` to run Solid Queue inside the web **Puma** process on a single web dyno (recommended to start). |

Optional: `RAILS_LOG_LEVEL`, `JOB_CONCURRENCY` (defaults in `config/queue.yml`).

```bash
heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)"
heroku config:set APPLICATION_HOST=your-app-name.herokuapp.com
heroku config:set SOLID_QUEUE_IN_PUMA=true
```

Heroku sets **`DATABASE_URL`**, **`HEROKU_APP_NAME`**, **`PORT`**, and **`RAILS_ENV=production`** automatically.

### Deploy

```bash
git push heroku main
```

The root **`Procfile`** runs **`rails db:migrate`** on each release and **`puma`** for the web process.

### After first deploy

- Open `https://YOUR_HOST` and hit **`/up`** if you need a quick health check.
- If you use a **custom domain**, add it in Heroku, set **`APPLICATION_HOST`** to that hostname, and consider enabling **`config.hosts`** for it (already supported when `HEROKU_APP_NAME` is unset via **`APPLICATION_HOST`** in `config/environments/production.rb`).

### Notes

- **SSL**: `config/environments/production.rb` enables `force_ssl` and `assume_ssl` for reverse-proxy TLS (Heroku router).
- **Action Cable (Turbo Streams)**: Uses **Solid Cable** backed by Postgres (no Redis addon required).
- **Tailwind**: The Heroku Ruby buildpack runs **`rake assets:precompile`**; `tailwindcss-rails` hooks into that pipeline.
- **Non-Heroku production** (e.g. Kamal): leave **`DATABASE_URL`** unset and continue using **`DDD_EDS_DATABASE_PASSWORD`** and separate database names as before.

## License

Private / your choice — add a `LICENSE` file if you open-source the project.
