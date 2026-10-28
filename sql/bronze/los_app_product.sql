-- Source: PG_LOS_APP.PRODUCT
-- Target: iceberg.pg_bronze.los_app_product
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.los_app_product
SELECT
    src.`ID`,
    src.`PRODUCT_CODE`,
    src.`PRODUCT_NAME`,
    src.`RECID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_PRODUCT' AS SRC_STM_CODE
FROM oracle.PG_LOS_APP.PRODUCT AS src;
