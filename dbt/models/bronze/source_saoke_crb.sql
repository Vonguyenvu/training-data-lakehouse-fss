{#- Nguồn Oracle PG_SOURCE.SAOKE_CRB -> iceberg.pg_bronze.source_saoke_crb (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`APP_ID`,
    src.`ASSET_TYPE`,
    src.`SBV_CODE`,
    src.`ACC_FCC`,
    src.`AMOUNT_CUR`,
    src.`AMOUNT_LCY`,
    src.`APP_CODE`,
    src.`CATEG_CODE`,
    src.`CUS_ID`,
    src.`VAL_DATE`,
    src.`MAT_DATE`,
    src.`CO_CODE`,
    src.`SUB_PRO`,
    src.`CURR`,
    src.`LOC_TERM`,
    src.`TXN_DATE`,
    CAST(NULL AS STRING) AS `DATE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'SOURCE_SAOKE_CRB' AS SRC_STM_CODE
FROM {{ source('oracle_source', 'SAOKE_CRB') }} AS src
