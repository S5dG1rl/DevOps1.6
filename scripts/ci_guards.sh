#!/bin/bash
# Защита критических файлов приёмки.
# Не даёт незаметно удалить тесты, снизить порог покрытия или ослабить анализаторы.
set -uo pipefail

BASE=origin/main
FAILED=0
ok()  { echo "  [ ok ] $1"; }
bad() { echo "  [FAIL] $1"; FAILED=1; }

echo "== Защита критических файлов =="

git fetch --no-tags --depth=50 origin main:refs/remotes/origin/main >/dev/null 2>&1 || true

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    echo "  [skip] базовая ветка $BASE недоступна — сравнение пропущено"
    exit 0
fi

count_tests() {
    git grep -h -c "def test_" "$1" -- tests 2>/dev/null | awk '{s+=$1} END {print s+0}'
}

base_tests=$(count_tests "$BASE")
cur_tests=$(count_tests HEAD)

if [ "$cur_tests" -ge "$base_tests" ]; then
    ok "тестов не меньше, чем в $BASE: $cur_tests (было $base_tests)"
else
    bad "тестов стало меньше: $cur_tests, было $base_tests"
fi

cov_of() {
    git show "$1:pytest.ini" 2>/dev/null | grep -o 'cov-fail-under=[0-9]*' | cut -d= -f2 | head -1
}

base_cov=$(cov_of "$BASE")
cur_cov=$(cov_of HEAD)

if [ -z "$base_cov" ] || [ -z "$cur_cov" ]; then
    bad "не удалось прочитать порог покрытия в pytest.ini"
elif [ "$cur_cov" -lt "$base_cov" ]; then
    bad "порог покрытия снижен: $cur_cov, было $base_cov"
else
    ok "порог покрытия не снижен: $cur_cov (было $base_cov)"
fi

ignores_of() {
    git show "$1:ruff.toml" 2>/dev/null | grep -o '"[A-Z]\+[0-9]\+"' | sort | tr '\n' ' '
}

base_ign=$(ignores_of "$BASE")
cur_ign=$(ignores_of HEAD)

if [ "$base_ign" = "$cur_ign" ]; then
    ok "настройки анализатора не ослаблены: $cur_ign"
else
    bad "настройки анализатора изменены: было [$base_ign], стало [$cur_ign]"
fi

if git diff --name-only "$BASE"...HEAD 2>/dev/null | grep -qE '^(tests/|pytest\.ini|ruff\.toml|Makefile|\.github/)'; then
    echo "  [info] изменены критические файлы — требуется согласование CODEOWNERS"
    git diff --name-only "$BASE"...HEAD | grep -E '^(tests/|pytest\.ini|ruff\.toml|Makefile|\.github/)' | sed 's/^/         /'
else
    ok "критические файлы не менялись"
fi

if [ "$FAILED" -eq 0 ]; then
    echo "  ИТОГ: критическая часть приёмки не ослаблена"
else
    echo "  ИТОГ: попытка ослабить проверки отклонена"
fi
exit "$FAILED"
