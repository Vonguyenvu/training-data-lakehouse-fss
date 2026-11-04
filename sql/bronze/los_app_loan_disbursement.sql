-- Source: PG_LOS_APP.LOAN_DISBURSEMENT
-- Target: iceberg.pg_bronze.los_app_loan_disbursement
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.los_app_loan_disbursement
SELECT
    src.`EXT_REF_NO_1`,
    src.`AMND_STATE`,
    src.`STATUS`,
    CAST(src.`FACILITY_ID` AS STRING) AS `FACILITY_ID`,
    src.`BOOKING_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_LOAN_DISBURSEMENT' AS SRC_STM_CODE
FROM oracle.PG_LOS_APP.LOAN_DISBURSEMENT AS src;
