-- Source: PG_FLEXBO.PGB_LDTB_CONTRACT_MASTER
-- Target: iceberg.pg_bronze.flexbo_pgb_ldtb_contract_master
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgb_ldtb_contract_master
SELECT
    src.`BOOKING_DATE`,
    src.`CONTRACT_REF_NO`,
    src.`VERSION_NO`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_LDTB_CONTRACT_MASTER' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGB_LDTB_CONTRACT_MASTER AS src;
