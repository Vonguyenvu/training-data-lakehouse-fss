-- Source: PG_T24CORE.PD_PAYMENT_DUE_HIS_MV
-- Target: iceberg.pg_bronze.t24core_pd_payment_due_his_mv
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_pd_payment_due_his_mv
SELECT
    src.`RECID`,
    src.`PAY_TYPE`,
    src.`ACC_FCC`,
    src.`CATEGORY`,
    src.`CREDIT_STATUS`,
    src.`CURR_NO`,
    src.`DATE_TIME`,
    src.`FLAG_STATUS`,
    src.`PAY_AMT_OUTS`,
    src.`PAYMENT_DTE_DUE`,
    src.`PD_TYPE`,
    src.`RECORD_STATUS`,
    src.`REPAID_AMT`,
    src.`CUSTOMER`,
    src.`CO_CODE`,
    src.`REPAYMENT_ACCT`,
    src.`FINAL_DUE_DATE`,
    src.`ORIGINAL_MAT`,
    src.`APPROVE_AMOUNT`,
    src.`PENALTY_RATE`,
    src.`PE_RATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE_HIS_MV' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.PD_PAYMENT_DUE_HIS_MV AS src;
