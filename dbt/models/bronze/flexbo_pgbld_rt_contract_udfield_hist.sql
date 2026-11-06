{#- Nguồn Oracle PG_FLEXBO.PGBLD_RT_CONTRACT_UDFIELD_HIST -> iceberg.pg_bronze.flexbo_pgbld_rt_contract_udfield_hist (mirror 1:1, mọi cột STRING). -#}
SELECT
    CAST(src.`CO_CAU_NO` AS STRING) AS `CO_CAU_NO`,
    src.`CONTRACT_REF_NO`,
    src.`MOV_DATE`,
    src.`NGAY_HET_COVID19`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST' AS SRC_STM_CODE
FROM {{ source('oracle_flexbo', 'PGBLD_RT_CONTRACT_UDFIELD_HIST') }} AS src
