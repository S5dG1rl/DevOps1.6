#!/bin/bash
# Единый прогон проверок качества с отчётами в reports/.
# Используется из Makefile: make quality
set -eo pipefail

PY=${PY:-venv/bin/python}
REPORTS=${REPORTS:-reports}

mkdir -p "$REPORTS"

echo "== ruff check (линтер) =="
$PY -m ruff check . --output-format=concise | tee "$REPORTS/ruff.txt"

echo
echo "== ruff format --check (форматирование) =="
$PY -m ruff format --check . | tee "$REPORTS/ruff-format.txt"

echo
echo "== bandit (SAST) =="
set +e
$PY -m bandit -r app/ -q -f json -o "$REPORTS/bandit.json"
BANDIT_RC=$?
$PY -m bandit -r app/ -q -f txt -o "$REPORTS/bandit.txt"
set -e

# Если замечаний нет, bandit оставляет пустой файл — пишем это явно.
if [ ! -s "$REPORTS/bandit.txt" ]; then
    echo "Замечаний по безопасности не найдено (0 findings)." > "$REPORTS/bandit.txt"
fi

echo "Отчёты записаны в $REPORTS/: ruff.txt, ruff-format.txt, bandit.txt, bandit.json"
exit $BANDIT_RC
