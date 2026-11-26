#!/bin/bash
# Миграции на чистой БД: схема должна собраться с нуля и совпасть с моделями.
set -uo pipefail

NET=ci-net
docker network create "$NET" >/dev/null 2>&1 || true
docker rm -f pg-migr >/dev/null 2>&1 || true

echo "== чистая БД =="
docker run -d --name pg-migr --network "$NET" \
    -e POSTGRES_DB=migrations_test \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    postgres:17 >/dev/null

for _ in $(seq 1 60); do
    docker exec pg-migr pg_isready -U test -d migrations_test >/dev/null 2>&1 && break
    sleep 1
done

URL=postgresql://test:test@pg-migr:5432/migrations_test
rc=0

echo "== alembic upgrade head =="
docker run --rm --network "$NET" -e DATABASE_URL="$URL" \
    devops16-test sh -c 'alembic upgrade head' || rc=$?

if [ "$rc" -eq 0 ]; then
    echo "== alembic check (схема совпадает с моделями) =="
    docker run --rm --network "$NET" -e DATABASE_URL="$URL" \
        devops16-test sh -c 'alembic check' || rc=$?
fi

echo "== таблицы =="
docker exec pg-migr psql -U test -d migrations_test -c '\dt' || true

docker rm -f pg-migr >/dev/null 2>&1 || true
echo "== код миграций: $rc =="
exit "$rc"
