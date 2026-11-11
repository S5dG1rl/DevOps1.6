# DevOps1.6

Version: v0.1.2 (11.11.26)

Проект: учёт гор, альпинистов, групп, восхождений и отчётов.
FastAPI + PostgreSQL, JWT-аутентификация, шифрование персональных данных.

Быстрый старт: `make setup`, `make migrate`, `make run`.
Проверка работоспособности: `curl http://localhost:8000/health`.

## Команды

| Команда | Назначение |
|---|---|
| `make setup` | Первоначальная настройка: venv, зависимости, копия `.env` |
| `make run` | Локальный запуск с автоперезагрузкой |
| `make test` | Тесты с покрытием и отчётами в `reports/` |
| `make quality` | ruff (линтер + формат) и bandit (SAST) |
| `make format` | Автоматическое форматирование кода |
| `make migrate` | Применение миграций БД (`alembic upgrade head`) |
| `make backup` | Резервная копия БД в `backups/` |
| `make restore` | Восстановление: `make restore FILE=backups/backup_XXX.sql` |
| `make verify` | Полный обязательный набор локальных проверок (`quality` + `test`) |
| `make up` | Запуск контейнерного окружения (требуется Docker) |
| `make down` | Остановка контейнерного окружения |
| `make container-check` | Прогон проверок внутри контейнера |
| `make clean` | Удаление отчётов и кэшей |

> Команды `up`, `down`, `container-check` требуют установленного Docker
> и плагина Compose. На учебных серверах развёртывание выполняется без
> контейнеров — через systemd (см. `deploy.sh`).

## Окружение и секреты

- Все настройки читаются из `.env` (шаблон — `.env.example`).
- `.env` и `.env.test` в репозиторий **не попадают** (см. `.gitignore`).
- Строка подключения к БД задаётся переменной `DATABASE_URL` и читается
  и приложением, и Alembic — в `alembic.ini` учётных данных нет.
- Пароли, ключ шифрования и `JWT_SECRET_KEY` хранятся только в `.env`
  на сервере, права `600`.

## Логирование

Уровень задаётся переменной `LOG_LEVEL` (по умолчанию `INFO`).
Логи пишутся в stdout: под systemd они уходят в journald, в контейнере —
в лог Docker.

```bash
sudo journalctl -u devops-app -f
```

## Отчёты проверок

`make test` создаёт в `reports/`:

- `junit.xml` — результаты тестов;
- `coverage.xml` — покрытие в формате Cobertura;
- `htmlcov/index.html` — HTML-отчёт покрытия.

Порог покрытия — 40 %, задан в `pytest.ini` (`--cov-fail-under=40`).

## Миграции

```bash
make migrate                      # применить все миграции
alembic current                   # текущая версия схемы
alembic downgrade -1              # откатить одну миграцию
DATABASE_URL=... alembic upgrade head   # применить к другой БД
```

## Правила внесения изменений

1. Любое изменение начинается с задачи.
2. Запрещается отправлять изменения напрямую в `main`.
3. Каждая функция разрабатывается в отдельной ветке.
4. Перед запросом на слияние необходимо выполнить `make verify`.
5. Запрещено удалять тесты ради успешного прохождения проверок.
6. Запрещено отключать статический анализ и снижать пороги без согласования.
7. Секреты не должны попадать в репозиторий.
8. Файл `.env` хранится только локально.

## Пояснение к настройкам линтера (ruff.toml)

В проекте отключены правила `B008` и `DTZ011`. Это сделано не для ослабления CI, а по следующим причинам:
- `B008` (Depends в аргументах) конфликтует со стандартным и рекомендованным паттерном внедрения зависимостей в FastAPI.
- `DTZ011` (date.today) отключено, так как в предметной области (даты восхождений) не требуются часовые пояса, используются простые даты.

## API Endpoints

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/health` | Проверка работоспособности |
| GET | `/api/mountains` | Список гор |
| POST | `/api/mountains` | Создание горы |
| GET | `/api/climbers` | Список альпинистов |
| POST | `/api/climbers` | Создание альпиниста |
| GET | `/api/groups` | Список групп |
| POST | `/api/groups` | Создание группы |
| POST | `/api/groups/{id}/climbers` | Добавить альпиниста в группу |
| GET | `/api/ascents` | Список восхождений |
| POST | `/api/ascents` | Создание восхождения |
| POST | `/api/ascents/{id}/complete` | Завершить восхождение |
| POST | `/api/ascents/{id}/cancel` | Отменить восхождение |
| GET | `/api/reports` | Список отчётов |
| POST | `/api/reports` | Создание отчёта |

Интерактивная документация: `/docs` (OpenAPI).

## Схема данных

**Mountain** (Гора)
- id, name (unique), country, region, height_m, difficulty

**Climber** (Альпинист)
- id, full_name, email (unique), birth_date, experience_level, medical_clearance

**Group** (Группа)
- id, name (unique), description

**GroupClimber** (Участие в группе) — связь M:N
- group_id, climber_id, role

**Ascent** (Восхождение)
- id, mountain_id, group_id, route_name, status, start_date, end_date, notes

**Report** (Отчёт)
- id, ascent_id, report_type, title, summary

## Бизнес-правила

1. Высота горы должна быть больше 0
2. Дата окончания восхождения не может быть раньше даты начала
3. Нельзя завершить восхождение, если в группе нет участников
4. Отчёт можно создать только для завершённого восхождения
5. Уровень опыта альпиниста: beginner, intermediate, advanced, expert
6. Роль в группе: member, leader, instructor, medic
7. Тип отчёта: final, incident, medical
