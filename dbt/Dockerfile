FROM python:3.12-slim

# Engine: Spark Thrift Server (service spark-thrift). PyHive dùng pure-sasl, không cần build C.
RUN pip install --no-cache-dir "dbt-core~=1.10.0" "dbt-spark[PyHive]~=1.9.0"

WORKDIR /usr/app
