{#- Nguồn Oracle PG_T24CORE.LD_SCHEDULE_DEFINE_MV -> iceberg.pg_bronze.t24core_ld_schedule_define_mv (mirror 1:1, mọi cột STRING). -#}
SELECT
    CAST(src.`PREV_SCHED_DATE` AS STRING) AS `PREV_SCHED_DATE`,
    src.`CONTRACT_ID`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_LD_SCHEDULE_DEFINE_MV' AS SRC_STM_CODE
FROM {{ source('oracle_t24core', 'LD_SCHEDULE_DEFINE_MV') }} AS src
