-- Source: PG_SOURCE.SAOKE_CRB
-- Target: iceberg.pg_bronze.source_saoke_crb
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.source_saoke_crb
SELECT
    src.`ACC_FCC`,
    src.`AMOUNT_CUR`,
    src.`AMOUNT_LCY`,
    src.`APP_CODE`,
    src.`APP_ID`,
    src.`ASSET_TYPE`,
    src.`CATEG_CODE`,
    src.`CO_CODE`,
    src.`CURR`,
    src.`CUS_ID`,
    src.`DATE`,
    src.`LOC_TERM`,
    src.`MAT_DATE`,
    src.`SBV_CODE`,
    src.`SUB_PRO`,
    src.`TXN_DATE`,
    src.`VAL_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'SOURCE_SAOKE_CRB' AS SRC_STM_CODE
FROM oracle.PG_SOURCE.SAOKE_CRB AS src;
