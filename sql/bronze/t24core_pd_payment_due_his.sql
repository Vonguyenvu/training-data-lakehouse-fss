-- Source: PG_T24CORE.PD_PAYMENT_DUE_HIS
-- Target: iceberg.pg_bronze.t24core_pd_payment_due_his
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_pd_payment_due_his
SELECT
    src.`RECID`,
    CAST(src.`CURR_NO` AS STRING) AS `CURR_NO`,
    CAST(src.`PD_TYPE` AS STRING) AS `PD_TYPE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE_HIS' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.PD_PAYMENT_DUE_HIS AS src;
