
PYTHON ?= python3

VENV := venv/bin/python

PY := $(VENV)

HOST ?= 0.0.0.0

PORT ?= 8000

REPORTS := reports

COMPOSE ?= docker compose

.PHONY: setup run test quality format migrate backup restore verify up down container-check reports clean

setup:
	$(PYTHON) -m venv venv
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -r requirements.txt
	@test -f .env || cp .env.example .env

run:
	$(PY) -m uvicorn app.main:app --reload --host $(HOST) --port $(PORT)

test: reports
	$(PY) -m pytest

quality: reports
	PY=$(PY) bash scripts/quality.sh

format:
	$(PY) -m ruff format .

migrate:
	$(PY) -m alembic upgrade head

backup:
	$(PY) scripts/backup.py

restore:
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=backups/backup_XXX.sql" && exit 1)
	$(PY) scripts/restore.py $(FILE)

reports:
	@mkdir -p $(REPORTS)

verify: quality test
	@echo "All local checks passed."

up:
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен. Установите docker.io и docker-compose-plugin." && exit 1)
	$(COMPOSE) up -d --build

down:
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен." && exit 1)
	$(COMPOSE) down

container-check:
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен." && exit 1)
	$(COMPOSE) run --rm app sh -c "ruff check . && ruff format --check . && bandit -r app/ -q && pytest"

clean:
	rm -rf $(REPORTS) .pytest_cache .ruff_cache
