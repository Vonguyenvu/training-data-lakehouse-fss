-- Source: PG_SOURCE.SAOKE_CRB
-- Target: iceberg.pg_bronze.source_saoke_crb
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.source_saoke_crb
SELECT
    src.`APP_ID`,
    src.`ASSET_TYPE`,
    src.`SBV_CODE`,
    src.`ACC_FCC`,
    src.`AMOUNT_CUR`,
    src.`AMOUNT_LCY`,
    src.`APP_CODE`,
    src.`CATEG_CODE`,
    src.`CUS_ID`,
    src.`VAL_DATE`,
    src.`MAT_DATE`,
    src.`CO_CODE`,
    src.`SUB_PRO`,
    src.`CURR`,
    src.`LOC_TERM`,
    src.`TXN_DATE`,
    -- Cột có trong mapping Excel nhưng bảng nguồn Oracle không có: nạp NULL.
    CAST(NULL AS STRING) AS `DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'SOURCE_SAOKE_CRB' AS SRC_STM_CODE
FROM oracle.PG_SOURCE.SAOKE_CRB AS src;
