{#- Nguồn Oracle PG_LOS_APP.FACILITY -> iceberg.pg_bronze.los_app_facility (mirror 1:1, mọi cột STRING). -#}
SELECT
    CAST(src.`ID` AS STRING) AS `ID`,
    CAST(src.`PRODUCT_ID` AS STRING) AS `PRODUCT_ID`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_FACILITY' AS SRC_STM_CODE
FROM {{ source('oracle_los_app', 'FACILITY') }} AS src
