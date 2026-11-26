# Проверка зависимостей на известные уязвимости (SCA).
#
# --ignore-vuln для двух записей: исправленных версий у них нет,
# они зафиксированы как известное принятое исключение:
#   PYSEC-2026-1325 (ecdsa)       — транзитивная зависимость python-jose
#   PYSEC-2026-4298 (python-jose) — библиотека без активной поддержки
FROM devops16-test:latest

RUN pip install --no-cache-dir pip-audit \
    && pip-audit -r requirements.txt \
        --ignore-vuln PYSEC-2026-1325 \
        --ignore-vuln PYSEC-2026-4298 \
    && echo "уязвимых зависимостей не найдено (кроме принятых исключений)"
