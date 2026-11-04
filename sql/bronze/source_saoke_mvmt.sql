-- Source: PG_SOURCE.SAOKE_MVMT
-- Target: iceberg.pg_bronze.source_saoke_mvmt
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.source_saoke_mvmt
SELECT
    src.`TRANS_REF`,
    CAST(src.`SBV_CODE` AS STRING) AS `SBV_CODE`,
    src.`TXN_DATE`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'SOURCE_SAOKE_MVMT' AS SRC_STM_CODE
FROM oracle.PG_SOURCE.SAOKE_MVMT AS src;
