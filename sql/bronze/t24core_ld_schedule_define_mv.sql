-- Source: PG_T24CORE.LD_SCHEDULE_DEFINE_MV
-- Target: iceberg.pg_bronze.t24core_ld_schedule_define_mv
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_ld_schedule_define_mv
SELECT
    CAST(src.`PREV_SCHED_DATE` AS STRING) AS `PREV_SCHED_DATE`,
    src.`CONTRACT_ID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LD_SCHEDULE_DEFINE_MV' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.LD_SCHEDULE_DEFINE_MV AS src;
