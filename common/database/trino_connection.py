from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import trino
from dotenv import load_dotenv

from common.database.connection import Connection
from common.exception.connection_exception import (
    ConfigurationError,
    ConnectionFailedError,
)
from common.logging.logger import get_logger


@dataclass(frozen=True)
class TrinoConfig:
    host: str
    port: int
    user: str
    catalog: str

    @property
    def endpoint(self) -> str:
        return f"{self.host}:{self.port}"


class TrinoConnection(Connection):
    def __init__(self, config: TrinoConfig) -> None:
        self.config = config
        self._connection: Any = None
        self._log = get_logger(__name__)

    @classmethod
    def from_environment(cls) -> TrinoConnection:
        load_dotenv()
        host = os.getenv("TRINO_HOST", "trino")
        port = os.getenv("TRINO_INTERNAL_PORT", "8080")
        user = os.getenv("TRINO_USER", "lakehouse_test")
        catalog = os.getenv("TRINO_CATALOG", "iceberg")

        try:
            port_int = int(port)
        except ValueError as exc:
            raise ConfigurationError("TRINO_INTERNAL_PORT must be an integer") from exc

        return cls(TrinoConfig(host=host, port=port_int, user=user, catalog=catalog))

    def connect(self) -> Any:
        if self._connection is not None:
            self._log.debug(
                "Reusing existing Trino connection to %s", self.config.endpoint
            )
            return self._connection
        self._log.info("Connecting to Trino: %s", self.config.endpoint)
        try:
            self._connection = trino.dbapi.connect(
                host=self.config.host,
                port=self.config.port,
                user=self.config.user,
                catalog=self.config.catalog,
            )
            self._log.info("Trino connection established.")
            return self._connection
        except Exception as exc:
            self._log.error("Trino connection failed: %s", exc)
            raise ConnectionFailedError("Could not connect to Trino") from exc

    def query(self, sql: str) -> list[tuple[Any, ...]]:
        cursor = self.connect().cursor()
        try:
            cursor.execute(sql)
            return cursor.fetchall()
        finally:
            cursor.close()

    def health_check(self) -> bool:
        self._log.debug("Running Trino health check on %s", self.config.endpoint)
        try:
            self.query("SELECT 1")
            self._log.debug("Trino health check passed.")
            return True
        except Exception as exc:
            self._log.error("Trino health check failed: %s", exc)
            raise ConnectionFailedError("Trino health check failed") from exc

    def close(self) -> None:
        if self._connection is not None:
            self._log.info("Closing Trino connection to %s", self.config.endpoint)
            self._connection.close()
            self._connection = None

    def __enter__(self) -> TrinoConnection:
        self.connect()
        return self

    def __exit__(self, *args: object) -> None:
        self.close()
