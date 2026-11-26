# syntax=docker/dockerfile:1
#
# base    — рабочие зависимости (без инструментов проверки)
# test    — тесты и анализаторы; при падении сборка останавливается
# runtime — рабочий образ, код берётся из проверенной стадии

FROM python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir --no-compile -r requirements.txt

FROM base AS test

COPY requirements-dev.txt ./
RUN pip install --no-cache-dir --no-compile -r requirements-dev.txt

COPY . .

# Один RUN: проверки и подготовка каталога для рантайма.
# reports/ создаётся, потому что pytest.ini пишет туда отчёты, а .dockerignore
# этот каталог из контекста исключает.
RUN mkdir -p reports \
    && pytest -q \
    && ruff check . \
    && ruff format --check . \
    && bandit -r app/ -q \
    && mkdir -p /dist \
    && cp -r app static templates scripts alembic alembic.ini /dist/ \
    && find /dist -name __pycache__ -type d -prune -exec rm -rf {} +

CMD ["pytest"]

FROM base AS runtime

RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app --home-dir /app --shell /usr/sbin/nologin app

COPY --from=test --chown=1001:1001 /dist/ /app/

USER 1001:1001

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]

STOPSIGNAL SIGTERM

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*", "--timeout-graceful-shutdown", "5"]
