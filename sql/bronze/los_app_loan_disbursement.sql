-- Source: PG_LOS_APP.LOAN_DISBURSEMENT
-- Target: iceberg.pg_bronze.los_app_loan_disbursement
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.los_app_loan_disbursement
SELECT
    src.`AMND_STATE`,
    src.`BOOKING_DATE`,
    src.`EXT_REF_NO_1`,
    src.`FACILITY_ID`,
    src.`STATUS`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_LOAN_DISBURSEMENT' AS SRC_STM_CODE
FROM oracle.PG_LOS_APP.LOAN_DISBURSEMENT AS src;
