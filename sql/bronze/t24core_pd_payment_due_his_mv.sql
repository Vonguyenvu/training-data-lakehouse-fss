-- Source: PG_T24CORE.PD_PAYMENT_DUE_HIS_MV
-- Target: iceberg.pg_bronze.t24core_pd_payment_due_his_mv
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_pd_payment_due_his_mv
SELECT
    src.`ACC_FCC`,
    src.`APPROVE_AMOUNT`,
    src.`CATEGORY`,
    src.`CO_CODE`,
    src.`CREDIT_STATUS`,
    src.`CURR_NO`,
    src.`CUSTOMER`,
    src.`DATE_TIME`,
    src.`FINAL_DUE_DATE`,
    src.`FLAG_STATUS`,
    src.`ORIGINAL_MAT`,
    src.`PAY_TYPE`,
    src.`PD_TYPE`,
    src.`PENALTY_RATE`,
    src.`PE_RATE`,
    src.`RECID`,
    src.`RECORD_STATUS`,
    src.`REPAYMENT_ACCT`,
    src.`PAYMENT_DTE_DUE`,
    src.`PAY_AMT_OUTS`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE_HIS_MV' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.PD_PAYMENT_DUE_HIS_MV AS src;
