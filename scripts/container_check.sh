#!/bin/bash
# Автоматическая проверка контейнерного окружения (лабораторная работа №4).
#
# Проверяет запреты из задания и работоспособность окружения:
#   1. политики: нет latest, нет публикации порта БД, есть healthcheck и лимиты;
#   2. сборка образа;
#   3. приложение работает не от root;
#   4. секретов и .git в образе нет;
#   5. линтер, форматирование, SAST и тесты внутри контейнера;
#   6. окружение поднимается и отвечает на /health;
#   7. данные переживают пересоздание контейнеров;
#   8. приложение корректно завершается по SIGTERM.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

COMPOSE=${COMPOSE:-docker-compose}
APP_URL=${APP_URL:-http://127.0.0.1:8001}
TEST_IMAGE=devops16-test
FAILED=0

step() { printf '\n== %s ==\n' "$1"; }
ok()   { printf '  [ ok ] %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

# Ждём, пока сервис станет healthy (не дольше 60 секунд).
wait_healthy() {
    local name=$1 id state i
    id=$($COMPOSE ps -q "$name" 2>/dev/null)
    for i in $(seq 1 60); do
        state=$(docker inspect -f '{{.State.Health.Status}}' "$id" 2>/dev/null)
        [ "$state" = "healthy" ] && return 0
        sleep 1
    done
    return 1
}

step "1. Политики контейнерного окружения"

# Проверяем только строки инструкций, а не комментарии.
if grep -qiE '^FROM[[:space:]].*:latest' Dockerfile; then
    bad "в Dockerfile используется тег latest"
else
    ok "в Dockerfile нет тега latest"
fi

if grep -qE '^[[:space:]]*image:.*:latest' docker-compose.yml; then
    bad "в compose используется тег latest"
else
    ok "в compose нет тега latest"
fi

if grep -qE '^FROM[[:space:]]+[^@]+@sha256:' Dockerfile; then
    ok "базовый образ зафиксирован по digest"
else
    bad "базовый образ не зафиксирован по digest"
fi

if $COMPOSE config 2>/dev/null | grep -q 'published: "5432"'; then
    bad "порт базы данных публикуется наружу"
else
    ok "порт базы данных наружу не публикуется"
fi

if $COMPOSE config 2>/dev/null | grep -q 'healthcheck'; then
    ok "healthcheck задан"
else
    bad "healthcheck не задан"
fi

# compose нормализует память в байты, поэтому считаем заданные лимиты по сервисам.
limit_count=$($COMPOSE config 2>/dev/null | grep -c 'memory:')
if [ "$limit_count" -ge 2 ]; then
    ok "ограничения ресурсов заданы для обоих сервисов ($limit_count лимита)"
else
    bad "нет ограничений ресурсов хотя бы у одного сервиса"
fi

if [ -f .dockerignore ] && grep -qx '.env' .dockerignore; then
    ok ".dockerignore исключает .env"
else
    bad ".dockerignore отсутствует или не исключает .env"
fi

step "2. Сборка образа"
if $COMPOSE build --pull 2>&1 | tail -2; then
    ok "образ собран"
else
    bad "сборка образа не удалась"
fi

step "3. Пользователь процесса"
uid=$($COMPOSE run --rm --no-deps --entrypoint id app -u 2>/dev/null | tr -d '\r')
if [ -n "$uid" ] && [ "$uid" != "0" ]; then
    ok "приложение работает от непривилегированного пользователя (uid=$uid)"
else
    bad "приложение работает от root"
fi

step "4. Секреты в образе"
if $COMPOSE run --rm --no-deps --entrypoint sh app -c 'test -e /app/.env' >/dev/null 2>&1; then
    bad "файл .env попал в образ"
else
    ok "файла .env в образе нет"
fi

if $COMPOSE run --rm --no-deps --entrypoint sh app -c 'test -d /app/.git' >/dev/null 2>&1; then
    bad "каталог .git попал в образ"
else
    ok "каталога .git в образе нет"
fi

step "5. Проверки внутри контейнера"
if docker build --target test -t "$TEST_IMAGE" . >/dev/null 2>&1; then
    ok "образ для проверок собран"
    if docker run --rm "$TEST_IMAGE" sh -c 'mkdir -p reports && ruff check . && ruff format --check . && bandit -r app/ -q && pytest -q' 2>&1 | tail -6; then
        ok "линтер, форматирование, SAST и тесты пройдены"
    else
        bad "проверки внутри контейнера не пройдены"
    fi
else
    bad "не удалось собрать образ для проверок"
fi

step "6. Запуск окружения"
$COMPOSE up -d --build --remove-orphans >/dev/null 2>&1 || bad "не удалось поднять окружение"

if wait_healthy db && wait_healthy app; then
    ok "контейнеры перешли в состояние healthy"
else
    bad "контейнеры не стали healthy"
fi

health=$(curl -fsS -m 5 "$APP_URL/health" 2>/dev/null)
if [ -n "$health" ]; then
    ok "приложение отвечает: $health"
else
    bad "приложение не отвечает на $APP_URL/health"
fi

step "7. Сохранность данных"
$COMPOSE exec -T db psql -U app_db_user -d mountains_db -c \
    "INSERT INTO mountains (name, country, height_m) VALUES ('PERSIST_TEST', 'RU', 1000) ON CONFLICT (name) DO NOTHING;" >/dev/null 2>&1
$COMPOSE down >/dev/null 2>&1
$COMPOSE up -d >/dev/null 2>&1
wait_healthy db

rows=$($COMPOSE exec -T db psql -U app_db_user -d mountains_db -tAc \
    "SELECT count(*) FROM mountains WHERE name='PERSIST_TEST';" 2>/dev/null | tr -d '[:space:]')
if [ "$rows" = "1" ]; then
    ok "данные сохранились после пересоздания контейнеров"
else
    bad "данные потерялись после пересоздания контейнеров"
fi
$COMPOSE exec -T db psql -U app_db_user -d mountains_db -c \
    "DELETE FROM mountains WHERE name='PERSIST_TEST';" >/dev/null 2>&1

step "8. Корректное завершение"
$COMPOSE up -d >/dev/null 2>&1
wait_healthy app
start=$(date +%s)
$COMPOSE stop app >/dev/null 2>&1
stop_time=$(( $(date +%s) - start ))

if $COMPOSE logs app 2>/dev/null | grep -qiE 'shutting down|finished server process'; then
    ok "приложение завершилось корректно (uvicorn обработал SIGTERM) за ${stop_time}s"
else
    bad "в журнале нет корректного завершения"
fi

if [ "$stop_time" -le 10 ]; then
    ok "остановка уложилась в stop_grace_period (${stop_time}s ≤ 10s)"
else
    bad "остановка заняла ${stop_time}s — больше stop_grace_period"
fi

printf '\n'
if [ "$FAILED" -eq 0 ]; then
    echo "ИТОГ: контейнерное окружение соответствует требованиям."
else
    echo "ИТОГ: есть нарушения, окружение не принимается."
fi
exit "$FAILED"
