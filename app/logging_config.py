"""Единая настройка логирования приложения."""

from __future__ import annotations

import logging
import os
import sys

LOG_FORMAT = "%(asctime)s %(levelname)-7s [%(name)s] %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
DEFAULT_LEVEL = "INFO"


def configure_logging() -> None:
    """Настраивает корневой логгер: уровень из LOG_LEVEL, вывод в stdout.

    stdout выбран осознанно: под systemd сообщения попадают в journald,
    а в контейнере — в поток логов Docker.
    """
    level_name = os.getenv("LOG_LEVEL", DEFAULT_LEVEL).upper()
    level = getattr(logging, level_name, logging.INFO)

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(LOG_FORMAT, DATE_FORMAT))

    root = logging.getLogger()
    for existing in list(root.handlers):
        root.removeHandler(existing)
    root.addHandler(handler)
    root.setLevel(level)
