# syntax=docker/dockerfile:1
#
# Воспроизводимая сборка:
#  - базовый образ зафиксирован по тегу И по digest (не latest);
#  - версии Python-зависимостей зафиксированы в requirements.txt;
#  - зависимости ставятся отдельным слоем до копирования кода.
#
# Стадии:
#   base    — общие шаги установки зависимостей
#   runtime — рабочий образ приложения (непривилегированный пользователь)
#   test    — образ с инструментами проверки для make container-check

FROM python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt


# ---------- рабочий образ ----------
FROM base AS runtime

# Отдельный непривилегированный пользователь: приложение не работает от root.
RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app --home-dir /app --shell /usr/sbin/nologin app

COPY --chown=app:app app ./app
COPY --chown=app:app static ./static
COPY --chown=app:app templates ./templates
COPY --chown=app:app scripts ./scripts
COPY --chown=app:app alembic ./alembic
COPY --chown=app:app alembic.ini ./

USER app

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]

# SIGTERM обрабатывает uvicorn: он корректно завершает соединения.
STOPSIGNAL SIGTERM

# exec-форма: uvicorn становится PID 1 и первым получает сигнал остановки.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*", "--timeout-graceful-shutdown", "5"]


# ---------- образ для проверок ----------
FROM base AS test

COPY requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt

COPY . .

CMD ["pytest"]
