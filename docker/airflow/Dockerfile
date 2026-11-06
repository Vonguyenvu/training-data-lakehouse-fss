FROM apache/airflow:2.10.5

# dbt cài trong venv riêng: tránh xung đột với constraint của Airflow.
# DAG gọi /opt/dbt-venv/bin/dbt; thực thi trên Spark Thrift Server (service spark-thrift).
USER root
RUN python -m venv /opt/dbt-venv \
    && /opt/dbt-venv/bin/pip install --no-cache-dir "dbt-core~=1.10.0" "dbt-spark[PyHive]~=1.9.0"

USER airflow
# Bộ test tests/ (check_connection, check_bronze)
RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.12.txt" \
    pytest oracledb trino
