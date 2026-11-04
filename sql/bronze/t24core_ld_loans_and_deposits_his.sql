-- Source: PG_T24CORE.LD_LOANS_AND_DEPOSITS_HIS
-- Target: iceberg.pg_bronze.t24core_ld_loans_and_deposits_his
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_ld_loans_and_deposits_his
SELECT
    src.`RECID`,
    src.`CO_CODE`,
    src.`PRIN_LIQ_ACCT`,
    src.`INT_LIQ_ACCT`,
    src.`DRAWDOWN_NET_AMT`,
    src.`ORIG_VAL_DATE`,
    src.`VALUE_DATE`,
    src.`FIN_MAT_DATE`,
    src.`INT_RATE_TYPE`,
    src.`INTEREST_SPREAD`,
    src.`INTEREST_RATE`,
    src.`REAL_RATE`,
    src.`CATEGORY`,
    src.`APPROVE_AMOUNT`,
    src.`DATE_TIME`,
    src.`CURR_NO`,
    src.`ACC_FCC`,
    src.`CURRENCY`,
    src.`RECORD_STATUS`,
    src.`INT_VALUE_DATE`,
    src.`USE_OF_LOAN`,
    src.`USE_OF_LOAN_CHA`,
    src.`CRA_LD`,
    src.`EXCG_RATE`,
    src.`MB_RM_BANCHEO`,
    src.`LOC_TERM`,
    src.`CUSTOMER_ID`,
    src.`AMOUNT`,
    -- Cột có trong mapping Excel nhưng bảng nguồn Oracle không có: nạp NULL.
    CAST(NULL AS STRING) AS `COMMIT_ACTION`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LD_LOANS_AND_DEPOSITS_HIS' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.LD_LOANS_AND_DEPOSITS_HIS AS src;
