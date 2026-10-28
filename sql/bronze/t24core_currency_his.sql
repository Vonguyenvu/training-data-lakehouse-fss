-- Source: PG_T24CORE.CURRENCY_HIS
-- Target: iceberg.pg_bronze.t24core_currency_his
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_currency_his
SELECT
    src.`CURR_NO`,
    src.`DATE_TIME`,
    src.`ID`,
    src.`MID_REVAL_RATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_CURRENCY_HIS' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.CURRENCY_HIS AS src;
