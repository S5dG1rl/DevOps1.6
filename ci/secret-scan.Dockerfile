# Поиск секретов в исходниках. Сборка падает, если найден секрет.
FROM zricethezav/gitleaks:latest

COPY . /src

RUN gitleaks detect --no-git --source /src --redact --exit-code 1 --verbose
