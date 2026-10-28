-- Source: PG_T24CORE.SECTOR
-- Target: iceberg.pg_bronze.t24core_sector
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_sector
SELECT
    src.`CUSTOMER_TYPE`,
    src.`RECID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_SECTOR' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.SECTOR AS src;
