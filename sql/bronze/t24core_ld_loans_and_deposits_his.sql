-- Source: PG_T24CORE.LD_LOANS_AND_DEPOSITS_HIS
-- Target: iceberg.pg_bronze.t24core_ld_loans_and_deposits_his
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_ld_loans_and_deposits_his
SELECT
    src.`ACC_FCC`,
    src.`AMOUNT`,
    src.`APPROVE_AMOUNT`,
    src.`CATEGORY`,
    src.`COMMIT_ACTION`,
    src.`CO_CODE`,
    src.`CRA_LD`,
    src.`CURRENCY`,
    src.`CURR_NO`,
    src.`CUSTOMER_ID`,
    src.`DATE_TIME`,
    src.`DRAWDOWN_NET_AMT`,
    src.`EXCG_RATE`,
    src.`FIN_MAT_DATE`,
    src.`INTEREST_RATE`,
    src.`INTEREST_SPREAD`,
    src.`INT_LIQ_ACCT`,
    src.`INT_RATE_TYPE`,
    src.`INT_VALUE_DATE`,
    src.`LOC_TERM`,
    src.`MB_RM_BANCHEO`,
    src.`ORIG_VAL_DATE`,
    src.`PRIN_LIQ_ACCT`,
    src.`REAL_RATE`,
    src.`RECID`,
    src.`RECORD_STATUS`,
    src.`USE_OF_LOAN`,
    src.`USE_OF_LOAN_CHA`,
    src.`VALUE_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LD_LOANS_AND_DEPOSITS_HIS' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.LD_LOANS_AND_DEPOSITS_HIS AS src;
