"""Lệnh dbt cho BashOperator (dùng chung các DAG). dbt chạy trong /opt/dbt-venv, engine Spark Thrift Server."""
from __future__ import annotations

import re
from pathlib import Path

PROJECT = "/opt/airflow/dbt"
ETL_DATE = "{{ dag_run.conf.get('etl_date', ds) }}"
# Ngày nghiệp vụ (BOOKING_DATE / TXN_DATE / MOV_DATE) cho SNAPSHOT/TXN; mặc định = etl_date.
# Oracle hiện là dữ liệu mẫu 2025 nên phải truyền riêng, vd --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07"}'.
BIZ_DATE = "{{ dag_run.conf.get('biz_date') or dag_run.conf.get('etl_date', ds) }}"
# Chạy lại ngày cũ cho bảng SCD (dbt/macros/scd_backdate.sql): truyền "backdate": true cho MỌI ngày replay.
BACKDATE = "{{ dag_run.conf.get('backdate', false) | tojson }}"


def dbt(command: str, select: str | None, work: str) -> str:
    # Project mount read-only -> target/log ghi vào thư mục riêng của task để chạy song song không đè nhau.
    return (
        f"/opt/dbt-venv/bin/dbt {command} --project-dir {PROJECT} --profiles-dir {PROJECT} "
        f"--target-path /tmp/dbt/{work}/target --log-path /tmp/dbt/{work}/logs "
        + (f"--select {select} " if select else "")
        + f"--vars '{{\"etl_date\": \"{ETL_DATE}\", \"biz_date\": \"{BIZ_DATE}\", \"backdate\": {BACKDATE}}}'"
    )


def unless_skip_bronze(command: str, when_skipped: str) -> str:
    """conf "skip_bronze": true -> chạy when_skipped thay command (giữ partition Bronze đã có, không đọc lại Oracle)."""
    return f"{{% if dag_run.conf.get('skip_bronze') %}}{when_skipped}{{% else %}}{command}{{% endif %}}"


def models_with_refs(folder: str) -> dict[str, set[str]]:
    """{model: các model được ref()} trong dbt/models/<folder>, để dựng phụ thuộc task giữa các model."""
    return {
        f.stem: set(re.findall(r"ref\('(\w+)'\)", f.read_text(encoding="utf-8")))
        for f in sorted(Path(PROJECT, "models", folder).glob("*.sql"))
    }
