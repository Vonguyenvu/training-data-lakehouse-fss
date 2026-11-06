{#- Nguồn Oracle PG_T24CORE.COMPANY -> iceberg.pg_bronze.t24core_company (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`COMPANY_NAME`,
    src.`RECID`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_COMPANY' AS SRC_STM_CODE
FROM {{ source('oracle_t24core', 'COMPANY') }} AS src
