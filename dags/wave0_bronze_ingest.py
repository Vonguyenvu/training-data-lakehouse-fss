from __future__ import annotations

import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

from dbt_command import BIZ_DATE, ETL_DATE, dbt
from src.config.bronze_tables import BRONZE_TABLES

with DAG(
    dag_id="wave0_bronze_ingest",
    default_args={"owner": "data_platform", "retries": 1},
    schedule_interval=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    max_active_tasks=2,
    tags=["wave0", "bronze"],
    doc_md="""
## Wave 0 — Oracle → Iceberg Bronze → kích hoạt Wave 1 Silver Temp 1

Mỗi bảng là 1 model dbt `dbt/models/bronze/<target_name>.sql`, thực thi trên Spark Thrift Server
(service `spark-thrift`, executor trên `spark-worker`). Chạy lại cùng `etl_date` chỉ ghi đè partition đó.
Xong 28 bảng -> `dbt test` tầng Bronze -> trigger `wave1_silver_temp1` cùng `etl_date`.
```bash
airflow dags trigger wave0_bronze_ingest --conf '{"etl_date": "2026-11-04"}'
# Bảng SNAPSHOT/TXN lọc theo ngày nghiệp vụ: thêm "biz_date": "2025-10-07" (Oracle là dữ liệu mẫu 2025)
```
    """,
) as dag:
    loads = [
        BashOperator(
            task_id=f"bronze_{tbl.task_id}",
            bash_command=dbt("run", tbl.target_name, tbl.target_name),
        )
        for tbl in BRONZE_TABLES
    ]
    test = BashOperator(
        task_id="test_bronze", bash_command=dbt("test", "bronze", "test_bronze")
    )
    trigger_silver = TriggerDagRunOperator(
        task_id="trigger_wave1_silver_temp1",
        trigger_dag_id="wave1_silver_temp1",
        conf={"etl_date": ETL_DATE, "biz_date": BIZ_DATE},
    )
    loads >> test >> trigger_silver
