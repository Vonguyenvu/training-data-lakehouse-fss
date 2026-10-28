-- Source: PG_T24CORE.LIMIT
-- Target: iceberg.pg_bronze.t24core_limit
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_limit
SELECT
    src.`EXPIRY_DATE`,
    src.`INTERNAL_AMOUNT`,
    src.`LIMIT_PRODUCT`,
    src.`MAXIMUM_TOTAL`,
    src.`ONLINE_LIMIT_DATE`,
    src.`RECID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LIMIT' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.LIMIT AS src;
