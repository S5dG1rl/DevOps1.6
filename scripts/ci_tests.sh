#!/bin/bash
# Тесты против отдельной тестовой БД PostgreSQL (не SQLite).
set -uo pipefail

NET=ci-net
docker network create "$NET" >/dev/null 2>&1 || true
docker rm -f pg-test >/dev/null 2>&1 || true

echo "== поднимаем тестовую БД =="
docker run -d --name pg-test --network "$NET" \
    -e POSTGRES_DB=mountains_test \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    postgres:17 >/dev/null

for _ in $(seq 1 60); do
    docker exec pg-test pg_isready -U test -d mountains_test >/dev/null 2>&1 && break
    sleep 1
done

echo "== прогоняем миграции и тесты =="
rc=0
docker rm -f tests-run >/dev/null 2>&1 || true
docker run --name tests-run --network "$NET" \
    -e DATABASE_URL=postgresql://test:test@pg-test:5432/mountains_test \
    devops16-test sh -c 'alembic upgrade head && pytest -q' || rc=$?

mkdir -p reports
docker cp tests-run:/app/reports/. reports/ >/dev/null 2>&1 || true
docker rm -f tests-run >/dev/null 2>&1 || true

echo "== код тестов: $rc =="
exit "$rc"
