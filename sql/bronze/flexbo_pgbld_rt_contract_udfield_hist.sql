-- Source: PG_FLEXBO.PGBLD_RT_CONTRACT_UDFIELD_HIST
-- Target: iceberg.pg_bronze.flexbo_pgbld_rt_contract_udfield_hist
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgbld_rt_contract_udfield_hist
SELECT
    CAST(src.`CO_CAU_NO` AS STRING) AS `CO_CAU_NO`,
    src.`CONTRACT_REF_NO`,
    src.`MOV_DATE`,
    src.`NGAY_HET_COVID19`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGBLD_RT_CONTRACT_UDFIELD_HIST AS src;
