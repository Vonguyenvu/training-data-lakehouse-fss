-- Source: PG_T24CORE.COMPANY
-- Target: iceberg.pg_bronze.t24core_company
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_company
SELECT
    src.`COMPANY_NAME`,
    src.`RECID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_COMPANY' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.COMPANY AS src;
