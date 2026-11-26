#!/bin/bash
# Резервное копирование и восстановление в контейнерной среде.
set -uo pipefail

NET=ci-net
mkdir -p artifacts
docker network create "$NET" >/dev/null 2>&1 || true
docker rm -f pg-backup >/dev/null 2>&1 || true

echo "== БД с данными =="
docker run -d --name pg-backup --network "$NET" \
    -e POSTGRES_DB=backup_test \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    postgres:17 >/dev/null

for _ in $(seq 1 60); do
    docker exec pg-backup pg_isready -U test -d backup_test >/dev/null 2>&1 && break
    sleep 1
done

URL=postgresql://test:test@pg-backup:5432/backup_test
rc=0

docker run --rm --network "$NET" -e DATABASE_URL="$URL" \
    devops16-test sh -c 'alembic upgrade head' || rc=$?

docker exec pg-backup psql -U test -d backup_test -c \
    "INSERT INTO mountains (name,country,height_m) VALUES ('BACKUP_TEST','RU',1000);" >/dev/null

echo "== pg_dump =="
docker exec pg-backup pg_dump -U test -d backup_test > artifacts/ci_backup.sql
ls -l artifacts/ci_backup.sql

echo "== портим данные =="
docker exec pg-backup psql -U test -d backup_test -c "DELETE FROM mountains;" >/dev/null

echo "== восстанавливаем =="
docker exec -i pg-backup psql -U test -d backup_test < artifacts/ci_backup.sql >/dev/null 2>&1 || rc=$?

rows=$(docker exec pg-backup psql -U test -d backup_test -tAc \
    "SELECT count(*) FROM mountains WHERE name='BACKUP_TEST';" | tr -d '[:space:]')

if [ "$rows" = "1" ]; then
    echo "== восстановление успешно: строка на месте =="
else
    echo "== восстановление не удалось =="
    rc=1
fi

docker rm -f pg-backup >/dev/null 2>&1 || true
exit "$rc"
