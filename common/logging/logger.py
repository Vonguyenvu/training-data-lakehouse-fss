from __future__ import annotations

import logging
import os

_FORMAT = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
_DATE_FMT = "%Y-%m-%d %H:%M:%S"


def get_logger(name: str) -> logging.Logger:
    """Return a named logger backed by a StreamHandler.

    Log level is controlled by the LOG_LEVEL environment variable (default INFO).
    Handlers are attached only once to prevent duplicate log lines on re-import.
    """
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(_FORMAT, datefmt=_DATE_FMT))
        logger.addHandler(handler)
        logger.propagate = False

    level_name = os.getenv("LOG_LEVEL", "INFO").upper()
    logger.setLevel(getattr(logging, level_name, logging.INFO))
    return logger
