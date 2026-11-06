{#- Nguồn Oracle PG_T24CORE.DEPT_ACCT_OFFICER -> iceberg.pg_bronze.t24core_dept_acct_officer (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`NAME`,
    CAST(src.`RECID` AS STRING) AS `RECID`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'T24CORE_DEPT_ACCT_OFFICER' AS SRC_STM_CODE
FROM {{ source('oracle_t24core', 'DEPT_ACCT_OFFICER') }} AS src
