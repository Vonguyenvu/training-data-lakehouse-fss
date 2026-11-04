"""Kiểm tra tầng PG_BRONZE cho từng bảng (Oracle -> iceberg.pg_bronze qua Trino).

Mỗi bảng chạy 6 kiểm tra; lọc một bảng bằng `-k <tên_bảng>`.
"""
from __future__ import annotations

import re
from functools import cache

import pytest

from common.database.oracle_connection import OracleConnection
from common.database.trino_connection import TrinoConnection
from src.config.bronze_tables import BRONZE_TABLES, BronzeTable
from tests.conftest import PROJECT_ROOT

AUDIT_COLUMNS = ["ETL_DATE", "INGEST_TMS", "SRC_STM_CODE"]
# Kiểu Spark trong schema/bronze.sql -> kiểu Trino hiển thị cho bảng Iceberg.
TRINO_TYPES = {
    "STRING": "varchar",
    "DATE": "date",
    "TIMESTAMP": "timestamp(6) with time zone",
}

by_table = pytest.mark.parametrize("tbl", BRONZE_TABLES, ids=lambda t: t.target_name)


@cache
def ddl_columns() -> dict[str, list[tuple[str, str]]]:
    text = (PROJECT_ROOT / "schema" / "bronze.sql").read_text(encoding="utf-8-sig")
    pattern = r"CREATE TABLE IF NOT EXISTS iceberg\.pg_bronze\.(\w+) \((.*?)\n\)"
    return {
        name: re.findall(r"`(\w+)`\s+(\w+)", body)
        for name, body in re.findall(pattern, text, re.S)
    }


def sql_file(tbl: BronzeTable) -> str:
    return (PROJECT_ROOT / "sql" / "bronze" / f"{tbl.target_name}.sql").read_text(encoding="utf-8-sig")


def oracle_columns(oracle: OracleConnection, tbl: BronzeTable) -> list[str]:
    with oracle.connect().cursor() as cursor:
        cursor.execute(
            """
            SELECT column_name FROM all_tab_columns
            WHERE owner = :owner AND table_name = :table_name
            ORDER BY column_id
            """,
            owner=tbl.source_schema,
            table_name=tbl.source_table,
        )
        return [row[0] for row in cursor.fetchall()]


def oracle_count(oracle: OracleConnection, tbl: BronzeTable) -> int:
    with oracle.connect().cursor() as cursor:
        cursor.execute(f'SELECT COUNT(*) FROM "{tbl.source_schema}"."{tbl.source_table}"')
        return cursor.fetchone()[0]


def bronze_columns(trino_conn: TrinoConnection, tbl: BronzeTable) -> list[tuple[str, str]]:
    rows = trino_conn.query(
        f"""
        SELECT column_name, data_type FROM iceberg.information_schema.columns
        WHERE table_schema = 'pg_bronze' AND table_name = '{tbl.target_name}'
        ORDER BY ordinal_position
        """
    )
    return [(name.upper(), data_type) for name, data_type in rows]


def partition_filter(trino_conn: TrinoConnection, tbl: BronzeTable, etl_date: str | None) -> str | None:
    """Điều kiện WHERE cho partition cần kiểm tra; None nếu bảng chưa có partition nào."""
    if etl_date is None:
        latest = trino_conn.query(f"SELECT MAX(ETL_DATE) FROM {tbl.target_table}")[0][0]
        if latest is None:
            return None
        etl_date = latest.isoformat()
    return f"ETL_DATE = DATE '{etl_date}'"


@by_table
def test_table_exists(trino_conn: TrinoConnection, tbl: BronzeTable) -> None:
    rows = trino_conn.query(
        f"""
        SELECT 1 FROM iceberg.information_schema.tables
        WHERE table_schema = 'pg_bronze' AND table_name = '{tbl.target_name}'
        """
    )
    assert rows, f"Chưa có bảng {tbl.target_table}"


@by_table
def test_schema_matches_ddl(trino_conn: TrinoConnection, tbl: BronzeTable) -> None:
    expected = [(name.upper(), TRINO_TYPES[spark_type]) for name, spark_type in ddl_columns()[tbl.target_name]]
    assert bronze_columns(trino_conn, tbl) == expected


@by_table
def test_all_source_columns_loaded(oracle: OracleConnection, trino_conn: TrinoConnection, tbl: BronzeTable) -> None:
    bronze = {name for name, _ in bronze_columns(trino_conn, tbl)}
    missing = [col for col in oracle_columns(oracle, tbl) if col not in bronze]
    assert not missing, f"Cột Oracle chưa có trên Bronze: {missing}"


@by_table
def test_row_count_matches_oracle(
    oracle: OracleConnection, trino_conn: TrinoConnection, tbl: BronzeTable, etl_date: str | None
) -> None:
    source_count = oracle_count(oracle, tbl)
    where = partition_filter(trino_conn, tbl, etl_date)
    bronze_count = 0 if where is None else trino_conn.query(
        f"SELECT COUNT(*) FROM {tbl.target_table} WHERE {where}"
    )[0][0]
    assert bronze_count == source_count, (
        f"Oracle {source_count} dòng, Bronze {bronze_count} dòng (chênh {source_count - bronze_count})"
    )


@by_table
def test_audit_columns(trino_conn: TrinoConnection, tbl: BronzeTable, etl_date: str | None) -> None:
    where = partition_filter(trino_conn, tbl, etl_date)
    if where is None:
        pytest.skip("Bảng chưa có dữ liệu")
    expected_code = re.search(r"'(\w+)' AS SRC_STM_CODE", sql_file(tbl)).group(1)
    null_tms, codes = trino_conn.query(
        f"""
        SELECT COUNT_IF(INGEST_TMS IS NULL), ARRAY_AGG(DISTINCT SRC_STM_CODE)
        FROM {tbl.target_table} WHERE {where}
        """
    )[0]
    assert null_tms == 0, f"{null_tms} dòng có INGEST_TMS NULL"
    assert codes == [expected_code], f"SRC_STM_CODE = {codes}, mong đợi {expected_code}"


@by_table
def test_excel_only_columns_are_null(trino_conn: TrinoConnection, tbl: BronzeTable, etl_date: str | None) -> None:
    null_columns = re.findall(r"CAST\(NULL AS STRING\) AS `(\w+)`", sql_file(tbl))
    if not null_columns:
        pytest.skip("Không có cột chỉ có trong Excel")
    where = partition_filter(trino_conn, tbl, etl_date)
    if where is None:
        pytest.skip("Bảng chưa có dữ liệu")
    counts = trino_conn.query(
        f"SELECT {', '.join(f'COUNT({col})' for col in null_columns)} FROM {tbl.target_table} WHERE {where}"
    )[0]
    not_null = {col: n for col, n in zip(null_columns, counts) if n}
    assert not not_null, f"Cột lẽ ra NULL nhưng có dữ liệu: {not_null}"
