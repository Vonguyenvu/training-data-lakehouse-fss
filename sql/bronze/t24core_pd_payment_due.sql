-- Source: PG_T24CORE.PD_PAYMENT_DUE
-- Target: iceberg.pg_bronze.t24core_pd_payment_due
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.t24core_pd_payment_due
SELECT
    src.`AUTHORISER`,
    CAST(src.`CREDIT_STATUS` AS STRING) AS `CREDIT_STATUS`,
    src.`INPUTTER`,
    src.`LOS_FAC_CODE`,
    CAST(src.`ORIGINAL_MAT` AS STRING) AS `ORIGINAL_MAT`,
    src.`PAYMENT_DTE_DUE`,
    CAST(src.`PE_RATE` AS STRING) AS `PE_RATE`,
    CAST(src.`PENALTY_RATE` AS STRING) AS `PENALTY_RATE`,
    src.`RECID`,
    CAST(src.`SNQH_CHUYENDOI` AS STRING) AS `SNQH_CHUYENDOI`,
    CAST(src.`USE_OF_LOAN` AS STRING) AS `USE_OF_LOAN`,
    CAST(src.`CURR_NO` AS STRING) AS `CURR_NO`,
    CAST(src.`PD_TYPE` AS STRING) AS `PD_TYPE`,
    CAST(src.`CUSTOMER` AS STRING) AS `CUSTOMER`,
    CAST(src.`USE_OF_LOAN_CHA` AS STRING) AS `USE_OF_LOAN_CHA`,
    src.`CRA_LD`,
    src.`STATUS`,
    CAST(src.`LIMIT_REFERENCE` AS STRING) AS `LIMIT_REFERENCE`,
    src.`REPAYMENT_ACCT`,
    CAST(src.`PS_RATE` AS STRING) AS `PS_RATE`,
    CAST(src.`NGAY_AN_HAN` AS STRING) AS `NGAY_AN_HAN`,
    -- Cột có trong mapping Excel nhưng bảng nguồn Oracle không có: nạp NULL.
    CAST(NULL AS STRING) AS `FLAG_STATUS`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE' AS SRC_STM_CODE
FROM oracle.PG_T24CORE.PD_PAYMENT_DUE AS src;
