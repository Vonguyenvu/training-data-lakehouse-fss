-- Source: PG_T24CORE.PD_PAYMENT_DUE
-- Target: iceberg.pg_bronze.t24core_pd_payment_due
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_pd_payment_due
SELECT
    src.`AUTHORISER`,
    src.`CRA_LD`,
    src.`CREDIT_STATUS`,
    src.`CURR_NO`,
    src.`CUSTOMER`,
    src.`FLAG_STATUS`,
    src.`INPUTTER`,
    src.`LIMIT_REFERENCE`,
    src.`LOS_FAC_CODE`,
    src.`ORIGINAL_MAT`,
    src.`PAYMENT_DTE_DUE`,
    src.`PD_TYPE`,
    src.`PENALTY_RATE`,
    src.`PE_RATE`,
    src.`PS_RATE`,
    src.`RECID`,
    src.`REPAYMENT_ACCT`,
    src.`SNQH_CHUYENDOI`,
    src.`STATUS`,
    src.`USE_OF_LOAN`,
    src.`USE_OF_LOAN_CHA`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.PD_PAYMENT_DUE AS src;
