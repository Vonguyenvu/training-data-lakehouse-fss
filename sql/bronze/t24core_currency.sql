-- Source: PG_T24CORE.CURRENCY
-- Target: iceberg.pg_bronze.t24core_currency
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_currency
SELECT
    src.`CCY_NAME`,
    src.`CURR_NO`,
    src.`DATE_TIME`,
    src.`ID`,
    src.`MID_REVAL_RATE`,
    src.`NUMERIC_CCY_CODE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_CURRENCY' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.CURRENCY AS src;
