-- Source: PG_EBANKING.COL_UDF_VALUE
-- Target: iceberg.pg_bronze.ebanking_col_udf_value
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.ebanking_col_udf_value
SELECT
    src.`COL_REF`,
    src.`FUNCTION_CODE`,
    src.`UDF_ID`,
    src.`UDF_VALUE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'EBANKING_COL_UDF_VALUE' AS SRC_STM_CODE
FROM oracle.PG_EBANKING.COL_UDF_VALUE AS src;
