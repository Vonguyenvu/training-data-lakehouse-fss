-- Source: PG_T24CORE.DEPT_ACCT_OFFICER
-- Target: iceberg.pg_bronze.t24core_dept_acct_officer
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_dept_acct_officer
SELECT
    src.`NAME`,
    CAST(src.`RECID` AS STRING) AS `RECID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_DEPT_ACCT_OFFICER' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.DEPT_ACCT_OFFICER AS src;
