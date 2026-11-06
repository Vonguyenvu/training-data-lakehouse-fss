from __future__ import annotations

import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from airflow import DAG
from airflow.operators.bash import BashOperator

from dbt_command import dbt, models_with_refs

with DAG(
    dag_id="wave2_silver_temp2",
    default_args={"owner": "data_platform", "retries": 1},
    schedule_interval=None,   # được wave1_silver_temp1 trigger sau khi Temp 1 xong
    start_date=datetime(2025, 1, 1),
    catchup=False,
    max_active_runs=1,        # SCD2 phải chạy ETL_DATE tăng dần, không chồng lần chạy
    max_active_tasks=2,
    tags=["wave2", "silver"],
    doc_md="""
## Wave 2 — Silver Temp 2

1 task / model trong `dbt/models/silver_temp2/` (tự đọc từ thư mục), phụ thuộc giữa các model lấy từ `ref()`.
Cuối cùng `dbt test` tầng silver_temp2. Chạy tay:
```bash
airflow dags trigger wave2_silver_temp2 --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07"}'
```
    """,
) as dag:
    graph = models_with_refs("silver_temp2")
    tasks = {m: BashOperator(task_id=m, bash_command=dbt("run", m, m)) for m in graph}
    test = BashOperator(task_id="test_silver_temp2", bash_command=dbt("test", "silver_temp2", "test_silver_temp2"))
    for model, refs in graph.items():
        for upstream in refs & tasks.keys():
            tasks[upstream] >> tasks[model]
        tasks[model] >> test
