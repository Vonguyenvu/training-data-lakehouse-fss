-- Source: PG_T24CORE.SECTOR
-- Target: iceberg.pg_bronze.t24core_sector
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_sector
SELECT
    CAST(src.`RECID` AS STRING) AS `RECID`,
    src.`KHOI`,
    src.`AUDIT_DATE_TIME`,
    src.`CUSTOMER_TYPE`,
    src.`RESERVED_4`,
    src.`SHORT_NAME`,
    src.`CO_CODE`,
    src.`RESERVED_3`,
    src.`RISK_EXPO_TYPE`,
    src.`DESCRIPTION`,
    CAST(src.`SECTOR` AS STRING) AS `SECTOR`,
    src.`RESERVED_1`,
    CAST(src.`CURR_NO` AS STRING) AS `CURR_NO`,
    src.`AUTHORISER`,
    src.`RECORD_STATUS`,
    src.`LOCAL_REF`,
    src.`INPUTTER`,
    src.`AUDITOR_CODE`,
    src.`SECTOR_CODE`,
    CAST(src.`DEPT_CODE` AS STRING) AS `DEPT_CODE`,
    src.`DATE_TIME`,
    src.`COMMIT_SCN`,
    src.`COMMIT_ACTION`,
    src.`COMMIT_TS`,
    src.`REPLICAT_TS`,
    src.`STREAM_TS`,
    src.`TIME_UPDATE`,
    src.`ID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_SECTOR' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.SECTOR AS src;
