PYTHON ?= python3

VENV := venv/bin/python

PY := $(VENV)

HOST ?= 0.0.0.0

PORT ?= 8000

REPORTS := reports

COMPOSE ?= docker compose

.DEFAULT_GOAL := help

.PHONY: help setup run test quality format migrate backup restore verify up down container-check reports clean

help: ## Показать этот список команд
	@echo
	@echo "Команды проекта DevOps1.6:"
	@echo
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-16s %s\n", $$1, $$2}'
	@echo

setup: ## Создать venv, поставить зависимости, скопировать .env
	$(PYTHON) -m venv venv
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -r requirements.txt
	@test -f .env || cp .env.example .env

run: ## Запустить приложение локально с автоперезагрузкой
	$(PY) -m uvicorn app.main:app --reload --host $(HOST) --port $(PORT)

test: reports ## Прогнать тесты с покрытием и отчётами
	$(PY) -m pytest

quality: reports ## Линтер, форматирование и SAST с отчётами
	PY=$(PY) bash scripts/quality.sh

format: ## Отформатировать код
	$(PY) -m ruff format .

migrate: ## Применить миграции БД (alembic upgrade head)
	$(PY) -m alembic upgrade head

backup: ## Сделать резервную копию БД в backups/
	$(PY) scripts/backup.py

restore: ## Восстановить БД: make restore FILE=backups/backup_XXX.sql
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=backups/backup_XXX.sql" && exit 1)
	$(PY) scripts/restore.py $(FILE)

verify: quality test ## Полный обязательный набор проверок
	@echo "All local checks passed."

up: ## Запустить контейнерное окружение (нужен Docker)
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен. Установите docker.io и docker-compose-plugin." && exit 1)
	$(COMPOSE) up -d --build

down: ## Остановить контейнерное окружение
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен." && exit 1)
	$(COMPOSE) down

container-check: ## Прогнать проверки внутри контейнера
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен." && exit 1)
	$(COMPOSE) run --rm app sh -c "ruff check . && ruff format --check . && bandit -r app/ -q && pytest"

reports: ## Создать каталог reports/
	@mkdir -p $(REPORTS)

clean: ## Удалить отчёты и кэши
	rm -rf $(REPORTS) .pytest_cache .ruff_cache
