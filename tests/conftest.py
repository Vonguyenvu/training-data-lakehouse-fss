from __future__ import annotations

import sys
from collections.abc import Iterator
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from common.database.oracle_connection import OracleConnection  # noqa: E402
from common.database.trino_connection import TrinoConnection  # noqa: E402


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--etl-date",
        default=None,
        help="Partition ETL_DATE cần kiểm tra (YYYY-MM-DD). Mặc định: partition mới nhất của từng bảng.",
    )


@pytest.fixture(scope="session")
def etl_date(request: pytest.FixtureRequest) -> str | None:
    return request.config.getoption("--etl-date")


@pytest.fixture(scope="session")
def oracle() -> Iterator[OracleConnection]:
    connection = OracleConnection.from_environment()
    connection.connect()
    yield connection
    connection.close()


@pytest.fixture(scope="session")
def trino_conn() -> Iterator[TrinoConnection]:
    connection = TrinoConnection.from_environment()
    yield connection
    connection.close()
