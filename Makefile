
PYTHON ?= python3

VENV := venv/bin/python

PY := $(VENV)

HOST ?= 0.0.0.0

PORT ?= 8000



.PHONY: setup run test quality format migrate backup restore verify



setup:

	$(PYTHON) -m venv venv

	$(PY) -m pip install --upgrade pip

	$(PY) -m pip install -r requirements.txt

	@test -f .env || cp .env.example .env



run:

	$(PY) -m uvicorn app.main:app --reload --host $(HOST) --port $(PORT)



test:

	$(PY) -m pytest



quality:

	$(PY) -m ruff check .

	$(PY) -m ruff format --check .

	$(PY) -m bandit -r app/ -q



format:

	$(PY) -m ruff format .



migrate:

	$(PY) -m alembic upgrade head



backup:

	$(PY) scripts/backup.py



restore:

	@test -n "$(FILE)" || (echo "Usage: make restore FILE=backups/backup_XXX.sql" && exit 1)

	$(PY) scripts/restore.py $(FILE)



verify: quality test

	@echo "All local checks passed."

