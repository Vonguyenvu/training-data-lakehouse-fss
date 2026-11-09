from __future__ import annotations

import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

from dbt_command import dbt, models_with_refs, unless_skip_bronze
from src.config.bronze_tables import BRONZE_TABLES

with DAG(
    dag_id="full_luong",
    default_args={"owner": "data_platform", "retries": 1},
    schedule_interval=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    max_active_runs=1,  # SCD2 phải chạy ETL_DATE tăng dần, không chồng lần chạy
    max_active_tasks=2,  # Spark chỉ 1 core
    tags=["bronze", "silver", "gold"],
    doc_md="""
## Bronze → Silver Temp 1 → Silver Temp 2 → Gold (1 ngày batch)

Mỗi tầng là 1 TaskGroup: 1 task / bảng (model dbt, chạy trên Spark Thrift Server), phụ thuộc giữa model lấy từ `ref()`,
cuối tầng `dbt test`; test pass mới sang tầng sau.
```bash
airflow dags trigger full_luong --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07"}'
# biz_date: ngày nghiệp vụ cho SNAPSHOT/TXN (Oracle là dữ liệu mẫu 2025), mặc định = etl_date
```

### Chạy lại ngày cũ (backdate)
Oracle chỉ có trạng thái hiện tại -> chạy lại Bronze ngày cũ sẽ ghi đè bản chụp cũ bằng dữ liệu hôm nay.
Vì vậy backdate dùng `"skip_bronze": true` (Silver/Gold đọc partition Bronze đã có; Bronze chỉ kiểm tra
partition tồn tại) và `"backdate": true` cho **mọi** ngày replay, tăng dần, đợi run trước xong mới trigger ngày sau:
```bash
airflow dags trigger full_luong --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07", "backdate": true, "skip_bronze": true}'
airflow dags trigger full_luong --conf '{"etl_date": "2026-11-04", "biz_date": "2025-10-08", "backdate": true, "skip_bronze": true}'
# ... tới ngày mới nhất
```
    """,
) as dag:
    with TaskGroup("bronze") as bronze:
        loads = [
            BashOperator(
                task_id=tbl.task_id,
                bash_command=unless_skip_bronze(
                    dbt("run", tbl.target_name, tbl.target_name),
                    "echo 'skip_bronze: giữ partition Bronze đã có'",
                ),
            )
            for tbl in BRONZE_TABLES
        ]
        loads >> BashOperator(
            task_id="test",
            bash_command=unless_skip_bronze(
                dbt("test", "bronze", "test_bronze"),
                dbt("run-operation assert_bronze_partition", None, "test_bronze"),
            ),
        )

    layers = [bronze]
    for folder in ("silver_temp1", "silver_temp2", "gold"):
        with TaskGroup(folder) as group:
            graph = models_with_refs(folder)
            tasks = {
                m: BashOperator(task_id=m, bash_command=dbt("run", m, m)) for m in graph
            }
            test = BashOperator(
                task_id="test", bash_command=dbt("test", folder, f"test_{folder}")
            )
            for model, refs in graph.items():
                for upstream in refs & tasks.keys():
                    tasks[upstream] >> tasks[model]
                tasks[model] >> test
        layers[-1] >> group
        layers.append(group)
