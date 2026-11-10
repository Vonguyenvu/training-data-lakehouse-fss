#!/bin/bash
# Spark Thrift Server: engine thực thi của dbt (dbt-spark, method thrift). Driver ở container này,
# executor chạy local trong cùng JVM (local[1], không có cụm standalone để tiết kiệm RAM).
set -euo pipefail

COMMON=(--conf spark.sql.legacy.timeParserPolicy=CORRECTED)

# Thrift mở mỗi phiên bằng `USE default` -> namespace iceberg.default phải tồn tại (môi trường mới chưa có).
/opt/spark/bin/spark-sql --master 'local[1]' "${COMMON[@]}" -e "
  CREATE NAMESPACE IF NOT EXISTS iceberg.default;
  CREATE NAMESPACE IF NOT EXISTS iceberg.pg_bronze;
  CREATE NAMESPACE IF NOT EXISTS iceberg.pg_silver;
  CREATE NAMESPACE IF NOT EXISTS iceberg.pg_gold"

export SPARK_NO_DAEMONIZE=true
exec /opt/spark/sbin/start-thriftserver.sh \
  --master 'local[1]' \
  --driver-memory 1536m \
  --conf spark.driver.host=spark-thrift \
  --conf spark.driver.bindAddress=0.0.0.0 \
  --conf spark.sql.defaultCatalog=iceberg \
  `# Executor crash SIGSEGV (bộ nhớ native hỏng) khi đọc Iceberg bằng Parquet vectorized (Arrow) -> tắt.` \
  --conf spark.sql.iceberg.vectorization.enabled=false \
  "${COMMON[@]}" \
  --hiveconf hive.server2.thrift.port=10000 \
  --hiveconf hive.server2.thrift.bind.host=0.0.0.0
