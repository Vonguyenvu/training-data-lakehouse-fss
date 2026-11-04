-- Source: PG_FLEXBO.PGBLD_CONTRACT_UDFIELD_HIST
-- Target: iceberg.pg_bronze.flexbo_pgbld_contract_udfield_hist
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgbld_contract_udfield_hist
SELECT
    src.`CONTRACT_REF_NO`,
    CAST(src.`CT_KHUYEN_MAI_CHO_VAY` AS STRING) AS `CT_KHUYEN_MAI_CHO_VAY`,
    src.`CTKM2`,
    src.`MOV_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGBLD_CONTRACT_UDFIELD_HIST' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGBLD_CONTRACT_UDFIELD_HIST AS src;
