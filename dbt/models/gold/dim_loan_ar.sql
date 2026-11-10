{#-
    PG_GOLD.DIM_LOAN_AR — sheet 'Dimension Loan Arrangement', SCD TYPE 2 (macro scd2).
    PG_SILVER.LOAN_AR a (SYS_EXP_DT IS NULL) LEFT JOIN LOAN_AR_PRFL b (AR_ID, SYS_EXP_DT IS NULL).
    DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || AR_ID.
    Khác Excel: ETL_CHANGE_DATE = ngày đổi mới nhất của a VÀ b (GREATEST), không chỉ của a — b đổi (vd AR_LCS_TP_CODE)
    sinh phiên bản DIM mới, nếu chỉ lấy ngày của a thì phiên bản mới trùng DIM_KEY với phiên bản cũ.
    SYS_EFF_DT / SYS_EXP_DT là ngày hiệu lực phiên bản DIM (macro scd2), không chép 1:1 từ LOAN_AR.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ar_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST(CONCAT(
            -- LEAST: replay backdate đọc Silver SCD1 không tua được, SYS_UDT_DT có thể là ngày sau ETL_DATE
            DATE_FORMAT(
                LEAST(COALESCE(
                    GREATEST(COALESCE(a.sys_udt_dt, a.sys_eff_dt), COALESCE(b.sys_udt_dt, b.sys_eff_dt)),
                    {{ etl_date() }}
                ), {{ etl_date() }}),
                'yyyyMMdd'
            ),
            a.ar_id
        ) AS STRING) AS dim_key,
        CAST(a.ar_id AS STRING) AS ar_id,
        CAST(a.ar_code AS STRING) AS ar_code,
        CAST(a.fcc_ar_code AS STRING) AS fcc_ar_code,
        CAST(a.ppr_ctr_nbr AS STRING) AS ppr_ctr_nbr,
        CAST(b.ar_lcs_tp_code AS STRING) AS ar_lcs_tp_code,
        CAST(a.ar_pps_grp_code AS STRING) AS ar_pps_grp_code,
        CAST(a.ar_pps_tp_code AS STRING) AS ar_pps_tp_code,
        CAST(a.orig_amt_fcy AS DECIMAL(25, 5)) AS orig_amt_fcy,
        CAST(a.pd_cgy_code AS STRING) AS pd_cgy_code,
        CAST(b.prom_prgm AS STRING) AS prom_code,
        CAST(b.prom_prgm_2 AS STRING) AS prom_code_2,
        CAST(a.term_code AS STRING) AS term_code,
        CAST(a.val_dt AS DATE) AS val_dt,
        CAST(a.eff_dt AS DATE) AS eff_dt,
        CAST(a.mat_dt AS DATE) AS mat_dt
    FROM {{ ref('loan_ar') }} AS a
    LEFT JOIN {{ ref('loan_ar_prfl') }} AS b
        ON
            a.ar_id = b.ar_id
            AND b.sys_exp_dt IS NULL
    WHERE
        a.sys_exp_dt IS NULL
)

{{ scd2(['ar_id'], compare_exclude=['dim_key']) }}
