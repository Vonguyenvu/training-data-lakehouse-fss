FROM python:3.12-slim

# Engine: Spark Thrift Server (service spark-thrift). PyHive dùng pure-sasl, không cần build C.
RUN pip install --no-cache-dir "dbt-spark[PyHive]"

WORKDIR /usr/app
