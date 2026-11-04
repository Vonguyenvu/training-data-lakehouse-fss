-- Source: PG_FLEXBO.PGB_CONTRACT_UDF_MAP
-- Target: iceberg.pg_bronze.flexbo_pgb_contract_udf_map
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgb_contract_udf_map
SELECT
    src.`CONTRACT_REF_NO`,
    src.`FIELD_NAME`,
    src.`FIELD_VAL`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_CONTRACT_UDF_MAP' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGB_CONTRACT_UDF_MAP AS src;
