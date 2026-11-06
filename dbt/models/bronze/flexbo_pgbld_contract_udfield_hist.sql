{#- Nguồn Oracle PG_FLEXBO.PGBLD_CONTRACT_UDFIELD_HIST -> iceberg.pg_bronze.flexbo_pgbld_contract_udfield_hist (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`CONTRACT_REF_NO`,
    CAST(src.`CT_KHUYEN_MAI_CHO_VAY` AS STRING) AS `CT_KHUYEN_MAI_CHO_VAY`,
    src.`CTKM2`,
    src.`MOV_DATE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGBLD_CONTRACT_UDFIELD_HIST' AS SRC_STM_CODE
FROM {{ source('oracle_flexbo', 'PGBLD_CONTRACT_UDFIELD_HIST') }} AS src
