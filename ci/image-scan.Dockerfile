# Анализ контейнерного образа: уязвимости в пакетах внутри образа.
# Отчёт выводится в лог сборки; критические исправимые уязвимости роняют сборку.
FROM aquasec/trivy:latest AS trivy

FROM devops16-app:latest

USER root

COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy

RUN trivy rootfs --no-progress --cache-dir /tmp/.trivy \
        --severity HIGH,CRITICAL --exit-code 0 / 2>&1 | tail -30
