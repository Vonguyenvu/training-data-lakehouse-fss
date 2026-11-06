{#- Nguồn Oracle PG_T24CORE.MB_MG_SAVING_MULTI -> iceberg.pg_bronze.t24core_mb_mg_saving_multi (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`LD_ID`,
    src.`MB_LD_TYPE`,
    src.`PRODUCTGR_CODE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_MB_MG_SAVING_MULTI' AS SRC_STM_CODE
FROM {{ source('oracle_t24core', 'MB_MG_SAVING_MULTI') }} AS src
