# DDD-EDS — see README for hybrid (Postgres in Docker + local Rails) vs full Docker stack.
.DEFAULT_GOAL := help
.PHONY: help start stop test reset clean \
	lint lint-ci brakeman bundler-audit importmap-audit check

COMPOSE := docker compose

help: ## Print available targets and short descriptions
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(firstword $(MAKEFILE_LIST)) | sort -u | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

start: ## Start Postgres + web in background (rebuild images when Dockerfile changes)
	$(COMPOSE) up -d --build postgres web

stop: ## Stop compose services (containers removed; named volumes kept)
	$(COMPOSE) down

test: ## Run full RSpec suite (DB must match config/database.yml, e.g. Postgres on 15432)
	bundle exec rspec

reset: ## db:reset — inside web container if it is running, else local bin/rails
	@if $(COMPOSE) ps -q web 2>/dev/null | grep -q .; then \
		$(COMPOSE) exec -T web bin/rails db:reset; \
	else \
		bin/rails db:reset; \
	fi

clean: ## docker compose down and remove orphan containers from old compose definitions
	$(COMPOSE) down --remove-orphans

lint: ## RuboCop (Omakase rules; default formatter)
	RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop

lint-ci: ## RuboCop with GitHub Actions formatter (used in CI)
	RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop -f github

brakeman: ## Brakeman Rails security scan (quiet, no pager; exit on warn/error — same as bin/ci)
	bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error

bundler-audit: ## Report known vulnerable gems from Gemfile.lock
	bin/bundler-audit

importmap-audit: ## Audit JavaScript dependencies pinned in importmap
	bin/importmap audit

check: ## Run lint, Brakeman, bundler-audit, importmap audit (static checks; mirrors CI)
	$(MAKE) lint
	$(MAKE) brakeman
	$(MAKE) bundler-audit
	$(MAKE) importmap-audit
