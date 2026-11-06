{#- Nguồn Oracle PG_FLEXBO.PGB_LDTB_CONTRACT_MASTER -> iceberg.pg_bronze.flexbo_pgb_ldtb_contract_master (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`BOOKING_DATE`,
    src.`CONTRACT_REF_NO`,
    CAST(src.`VERSION_NO` AS STRING) AS `VERSION_NO`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_LDTB_CONTRACT_MASTER' AS SRC_STM_CODE
FROM {{ source('oracle_flexbo', 'PGB_LDTB_CONTRACT_MASTER') }} AS src
