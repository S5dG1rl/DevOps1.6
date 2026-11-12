PYTHON ?= python3

VENV := venv/bin/python

PY := $(VENV)

HOST ?= 0.0.0.0

PORT ?= 8000

REPORTS := reports

COMPOSE ?= docker-compose

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

up: ## Запустить контейнерное окружение
	@command -v $(firstword $(COMPOSE)) >/dev/null 2>&1 || (echo "Docker не установлен. Нужны docker.io и docker-compose." && exit 1)
	$(COMPOSE) up -d --build

down: ## Остановить контейнерное окружение
	$(COMPOSE) down

container-check: ## Полная автоматическая проверка контейнерного окружения
	@command -v docker >/dev/null 2>&1 || (echo "Docker не установлен." && exit 1)
	bash scripts/container_check.sh

container-migrate: ## Применить миграции в контейнере
	$(COMPOSE) run --rm app alembic upgrade head

container-backup: ## Резервная копия БД из контейнера в backups/
	@mkdir -p backups
	$(COMPOSE) exec -T db sh -c 'pg_dump -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -F p' > backups/container_backup_$$(date +%Y%m%d_%H%M%S).sql
	@ls -1t backups/container_backup_*.sql | head -1

container-restore: ## Восстановить БД в контейнере: make container-restore FILE=backups/...sql
	@test -n "$(FILE)" || (echo "Usage: make container-restore FILE=backups/container_backup_XXX.sql" && exit 1)
	$(COMPOSE) exec -T db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"'
	$(COMPOSE) exec -T db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < $(FILE)

container-reset: ## Удалить контейнеры и volume БД (данные теряются)
	$(COMPOSE) down -v

reports: ## Создать каталог reports/
	@mkdir -p $(REPORTS)

clean: ## Удалить отчёты и кэши
	rm -rf $(REPORTS) .pytest_cache .ruff_cache
