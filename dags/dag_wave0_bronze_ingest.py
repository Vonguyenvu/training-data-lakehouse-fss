from __future__ import annotations

import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator

from src.config.bronze_tables import BRONZE_TABLES

_RUN_SQL = "/opt/airflow/src/jobs/run_sql.py"
_ETL_DATE = "{{ dag_run.conf.get('etl_date', ds) }}"
_ENV = {"SPARK_CONF_DIR": "/opt/airflow/spark-conf"}

with DAG(
    dag_id="dag_wave0_bronze_ingest",
    default_args={"owner": "data_platform", "retries": 1},
    schedule_interval=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    max_active_tasks=2,
    tags=["wave0", "bronze"],
    doc_md="""
## Wave 0 — Oracle → Iceberg Bronze (one-time full load)

`create_tables` chạy `schema/bronze.sql`, sau đó 28 task chạy `sql/bronze/*.sql` song song.
Trigger thủ công:
```bash
airflow dags trigger dag_wave0_bronze_ingest --conf '{"etl_date": "2025-01-01"}'
```
    """,
) as dag:
    create_tables = SparkSubmitOperator(
        task_id="create_tables",
        application=_RUN_SQL,
        conn_id="spark_default",
        application_args=["--sql-file", "/opt/airflow/schema/bronze.sql", "--etl-date", _ETL_DATE],
        env_vars=_ENV,
    )

    for tbl in BRONZE_TABLES:
        load = SparkSubmitOperator(
            task_id=f"bronze_{tbl.task_id}",
            application=_RUN_SQL,
            conn_id="spark_default",
            application_args=[
                "--sql-file", f"/opt/airflow/sql/bronze/{tbl.target_name}.sql",
                "--etl-date", _ETL_DATE,
            ],
            env_vars=_ENV,
        )
        create_tables >> load
