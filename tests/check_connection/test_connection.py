from __future__ import annotations

import os

import boto3
import pytest
import requests

from common.database.oracle_connection import OracleConnection
from common.database.trino_connection import TrinoConnection
from src.config.bronze_tables import BRONZE_TABLES, BronzeTable

NESSIE_URI = os.getenv("NESSIE_URI", "http://nessie:19120/api/v2")
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio:9000")


def test_oracle_connection(oracle: OracleConnection) -> None:
    assert oracle.health_check()


@pytest.mark.parametrize("tbl", BRONZE_TABLES, ids=lambda t: t.target_name)
def test_oracle_source_table_exists(oracle: OracleConnection, tbl: BronzeTable) -> None:
    with oracle.connect().cursor() as cursor:
        cursor.execute(
            "SELECT 1 FROM all_tables WHERE owner = :owner AND table_name = :table_name",
            owner=tbl.source_schema,
            table_name=tbl.source_table,
        )
        assert cursor.fetchone() is not None, (
            f"Không thấy bảng nguồn {tbl.source_schema}.{tbl.source_table} trên Oracle"
        )


def test_nessie_connection() -> None:
    response = requests.get(f"{NESSIE_URI}/config", timeout=10)
    assert response.status_code == 200, response.text
    assert response.json()["defaultBranch"] == "main"


@pytest.mark.parametrize("bucket", [os.getenv("MINIO_BUCKET", "warehouse")])
def test_minio_bucket(bucket: str) -> None:
    s3 = boto3.client(
        "s3",
        endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=os.environ["MINIO_ROOT_USER"],
        aws_secret_access_key=os.environ["MINIO_ROOT_PASSWORD"],
        region_name="us-east-1",
    )
    s3.head_bucket(Bucket=bucket)


def test_trino_connection(trino_conn: TrinoConnection) -> None:
    assert trino_conn.health_check()


def test_trino_iceberg_catalog(trino_conn: TrinoConnection) -> None:
    catalogs = {row[0] for row in trino_conn.query("SHOW CATALOGS")}
    assert "iceberg" in catalogs
