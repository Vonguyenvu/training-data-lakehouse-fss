{#-
    PG_SILVER.IDV_EMP_ST — sheet 'Individual Employment Status', SCD TYPE 2 (macro scd2).
    T24CORE_CUSTOMER, KHOI LIKE '%INDIV%'. Khóa tự nhiên CST_ID.
    Lệch Oracle (2026-11-03): EMPLOYMENT_STATUS / NET_MONTHLY_IN / OCCUPATION không có trên Oracle -> NULL.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['cst_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST({{ fn_hash('T24_CUSTOMER', 'c.recid') }} AS STRING) AS cst_id,
        CAST(TRIM(c.recid) AS STRING) AS cst_code,
        CAST(TRIM(c.employment_status) AS STRING) AS idv_emp_st_code,
        TRY_CAST(TRIM(c.net_monthly_in) AS DECIMAL(25, 5)) AS anul_incm,
        CAST(TRIM(c.occupation) AS STRING) AS ocp_code
    FROM {{ ref('t24core_customer') }} AS c
    WHERE
        c.etl_date = {{ etl_date() }}
        AND NULLIF(TRIM(c.recid), '') IS NOT NULL
        AND c.khoi LIKE '%INDIV%'
)
{{ scd2(['cst_id']) }}
