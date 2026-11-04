-- Source: PG_LOS_APP.FACILITY
-- Target: iceberg.pg_bronze.los_app_facility
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.los_app_facility
SELECT
    CAST(src.`ID` AS STRING) AS `ID`,
    CAST(src.`PRODUCT_ID` AS STRING) AS `PRODUCT_ID`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_FACILITY' AS SRC_STM_CODE
FROM oracle.PG_LOS_APP.FACILITY AS src;
