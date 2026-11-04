FROM apache/airflow:2.10.5

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

USER airflow
RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.12.txt" \
    apache-airflow-providers-apache-spark==5.0.0

# Phải khớp phiên bản Spark của cluster (docker/spark/Dockerfile: 3.5.9)
RUN pip install --no-cache-dir pyspark==3.5.9

# Bộ test tests/ (check_connection, check_bronze)
RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.12.txt" \
    pytest oracledb trino
