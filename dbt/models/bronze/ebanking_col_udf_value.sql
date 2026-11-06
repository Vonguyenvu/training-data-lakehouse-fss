{#- Nguồn Oracle PG_EBANKING.COL_UDF_VALUE -> iceberg.pg_bronze.ebanking_col_udf_value (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`COL_REF`,
    src.`FUNCTION_CODE`,
    src.`UDF_ID`,
    src.`UDF_VALUE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'EBANKING_COL_UDF_VALUE' AS SRC_STM_CODE
FROM {{ source('oracle_ebanking', 'COL_UDF_VALUE') }} AS src
