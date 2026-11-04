-- Source: PG_T24CORE.MB_MG_SAVING_MULTI
-- Target: iceberg.pg_bronze.t24core_mb_mg_saving_multi
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_mb_mg_saving_multi
SELECT
    src.`LD_ID`,
    src.`MB_LD_TYPE`,
    src.`PRODUCTGR_CODE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_MB_MG_SAVING_MULTI' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.MB_MG_SAVING_MULTI AS src;
