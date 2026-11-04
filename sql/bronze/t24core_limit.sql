-- Source: PG_T24CORE.LIMIT
-- Target: iceberg.pg_bronze.t24core_limit
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_limit
SELECT
    src.`FCC_LIMIT`,
    src.`RECID`,
    -- Cột có trong mapping Excel nhưng bảng nguồn Oracle không có: nạp NULL.
    CAST(NULL AS STRING) AS `LIMIT_PRODUCT`,
    CAST(NULL AS STRING) AS `INTERNAL_AMOUNT`,
    CAST(NULL AS STRING) AS `MAXIMUM_TOTAL`,
    CAST(NULL AS STRING) AS `ONLINE_LIMIT_DATE`,
    CAST(NULL AS STRING) AS `EXPIRY_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LIMIT' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.LIMIT AS src;
