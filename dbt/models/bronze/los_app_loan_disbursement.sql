{#- Nguồn Oracle PG_LOS_APP.LOAN_DISBURSEMENT -> iceberg.pg_bronze.los_app_loan_disbursement (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`EXT_REF_NO_1`,
    src.`AMND_STATE`,
    src.`STATUS`,
    CAST(src.`FACILITY_ID` AS STRING) AS `FACILITY_ID`,
    src.`BOOKING_DATE`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'LOS_APP_LOAN_DISBURSEMENT' AS SRC_STM_CODE
FROM {{ source('oracle_los_app', 'LOAN_DISBURSEMENT') }} AS src
