# syntax=docker/dockerfile:1
#
# Воспроизводимая сборка:
#  - базовый образ зафиксирован по тегу И по digest (не latest);
#  - версии Python-зависимостей зафиксированы в requirements.txt;
#  - зависимости ставятся отдельным слоем до копирования кода.
#
# Стадии:
#   base    — рабочие зависимости приложения
#   test    — инструменты проверки + тесты; если проверки упали, сборка встаёт
#   runtime — рабочий образ; код берётся из уже проверенной стадии test

FROM python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Только рабочие зависимости: инструменты проверок сюда не попадают.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt


# ---------- стадия проверки ----------
# Тесты и статический анализ выполняются при сборке. Если что-то упало —
# стадия не собирается, и рабочий образ получить нельзя.
FROM base AS test

COPY requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt

COPY . .

RUN mkdir -p reports \
    && pytest -q \
    && ruff check . \
    && ruff format --check . \
    && bandit -r app/ -q

CMD ["pytest"]


# ---------- рабочий образ ----------
# Код копируется из стадии test, поэтому образ соберётся только после
# успешных проверок. Инструменты проверок в этот образ не переходят.
FROM base AS runtime

# Отдельный непривилегированный пользователь: приложение не работает от root.
RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app --home-dir /app --shell /usr/sbin/nologin app

COPY --from=test --chown=app:app /app/app ./app
COPY --from=test --chown=app:app /app/static ./static
COPY --from=test --chown=app:app /app/templates ./templates
COPY --from=test --chown=app:app /app/scripts ./scripts
COPY --from=test --chown=app:app /app/alembic ./alembic
COPY --from=test --chown=app:app /app/alembic.ini ./

USER app

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]

# SIGTERM обрабатывает uvicorn: он корректно завершает соединения.
STOPSIGNAL SIGTERM

# exec-форма: uvicorn становится PID 1 и первым получает сигнал остановки.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*", "--timeout-graceful-shutdown", "5"]
