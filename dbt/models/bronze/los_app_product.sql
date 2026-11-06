{#- Nguồn Oracle PG_LOS_APP.PRODUCT -> iceberg.pg_bronze.los_app_product (mirror 1:1, mọi cột STRING). -#}
SELECT
    CAST(src.`ID` AS STRING) AS `ID`,
    src.`PRODUCT_CODE`,
    src.`PRODUCT_NAME`,
    CAST(NULL AS STRING) AS `RECID`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_PRODUCT' AS SRC_STM_CODE
FROM {{ source('oracle_los_app', 'PRODUCT') }} AS src
