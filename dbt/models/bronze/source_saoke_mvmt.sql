{#- Nguồn Oracle PG_SOURCE.SAOKE_MVMT -> iceberg.pg_bronze.source_saoke_mvmt (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`TRANS_REF`,
    CAST(src.`SBV_CODE` AS STRING) AS `SBV_CODE`,
    src.`TXN_DATE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'SOURCE_SAOKE_MVMT' AS SRC_STM_CODE
FROM {{ source('oracle_source', 'SAOKE_MVMT') }} AS src
