#!/bin/bash
# Повторяемое развёртывание приложения на сервере (без контейнеров).
set -euo pipefail

APP_DIR=/home/appuser/DevOps1.6
cd "$APP_DIR"

echo "[deploy] 1/5 обновление кода из main"
git pull --ff-only origin main

echo "[deploy] 2/5 зависимости"
./venv/bin/pip install -r requirements.txt

echo "[deploy] 3/5 настройки и миграции"
set -a && source .env && set +a
./venv/bin/python -m alembic upgrade head

echo "[deploy] 4/5 перезапуск службы"
sudo systemctl restart devops-app

echo "[deploy] 5/5 проверка работоспособности"
for _ in 1 2 3 4 5; do
    if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
        curl -fsS http://127.0.0.1:8000/health
        echo
        echo "[deploy] готово"
        exit 0
    fi
    sleep 2
done

echo "[deploy] ОШИБКА: приложение не отвечает на /health" >&2
exit 1
