from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

import oracledb
from dotenv import load_dotenv

from common.database.connection import Connection
from common.exception.connection_exception import (
    ConfigurationError,
    ConnectionFailedError,
)
from common.logging.logger import get_logger


@dataclass(frozen=True)
class OracleConfig:
    host: str
    port: int
    database: str
    username: str
    password: str

    @property
    def dsn(self) -> str:
        return f"{self.host}:{self.port}/{self.database}"


class OracleConnection(Connection):
    def __init__(self, config: OracleConfig) -> None:
        self.config = config
        self._connection: Any = None
        self._log = get_logger(__name__)

    @classmethod
    def from_environment(cls) -> OracleConnection:
        load_dotenv()
        host = os.getenv("ORACLE_HOST")
        port = os.getenv("ORACLE_PORT")
        database = os.getenv("ORACLE_DATABASE")
        username = os.getenv("ORACLE_USERNAME")
        password = os.getenv("ORACLE_PASSWORD")

        if not all([host, port, database, username, password]):
            raise ConfigurationError(
                "ORACLE_HOST, ORACLE_PORT, ORACLE_DATABASE, ORACLE_USERNAME "
                "and ORACLE_PASSWORD are required"
            )

        try:
            port_int = int(port)  # type: ignore[arg-type]
        except ValueError as exc:
            raise ConfigurationError("ORACLE_PORT must be an integer") from exc

        return cls(
            OracleConfig(
                host=host,  # type: ignore[arg-type]
                port=port_int,
                database=database,  # type: ignore[arg-type]
                username=username,  # type: ignore[arg-type]
                password=password,  # type: ignore[arg-type]
            )
        )

    def connect(self) -> Any:
        if self._connection is not None:
            self._log.debug("Reusing existing Oracle connection to %s", self.config.dsn)
            return self._connection
        self._log.info("Connecting to Oracle: %s", self.config.dsn)
        try:
            self._connection = oracledb.connect(
                user=self.config.username,
                password=self.config.password,
                dsn=self.config.dsn,
            )
            self._log.info("Oracle connection established.")
            return self._connection
        except Exception as exc:
            self._log.error("Oracle connection failed: %s", exc)
            raise ConnectionFailedError("Could not connect to Oracle") from exc

    def health_check(self) -> bool:
        self._log.debug("Running Oracle health check on %s", self.config.dsn)
        conn = self.connect()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1 FROM dual")
                cursor.fetchone()
            self._log.debug("Oracle health check passed.")
            return True
        except Exception as exc:
            self._log.error("Oracle health check failed: %s", exc)
            raise ConnectionFailedError("Oracle health check failed") from exc

    def close(self) -> None:
        if self._connection is not None:
            self._log.info("Closing Oracle connection to %s", self.config.dsn)
            self._connection.close()
            self._connection = None

    def __enter__(self) -> OracleConnection:
        self.connect()
        return self

    def __exit__(self, *args: object) -> None:
        self.close()
