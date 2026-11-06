{#- Nguồn Oracle PG_T24CORE.PD_PAYMENT_DUE_HIS -> iceberg.pg_bronze.t24core_pd_payment_due_his (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`RECID`,
    CAST(src.`CURR_NO` AS STRING) AS `CURR_NO`,
    CAST(src.`PD_TYPE` AS STRING) AS `PD_TYPE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_PD_PAYMENT_DUE_HIS' AS SRC_STM_CODE
FROM {{ source('oracle_t24core', 'PD_PAYMENT_DUE_HIS') }} AS src
