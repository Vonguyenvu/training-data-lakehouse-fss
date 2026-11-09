{#-
    PG_GOLD.INTF_LOAN_DSBR — sheet 'Interface Loan Disbursement', SNAPSHOT theo ETL_DATE.
    PG_SILVER.LOAN_AR a (SYS_EXP_DT IS NULL) LEFT JOIN theo AR_CODE: LOAN_AR_PRFL b, AR_X_IP_RLTNP c, AR_RATE_HIST e;
    EMPE d theo COALESCE(c.REFRRER_OFCR, b.REFRRER_OFCR) = EMPE_CODE; PD f theo PD_CODE.
    Khác Excel: AR_X_IP_RLTNP có nhiều khách hàng / hợp đồng (unique_key AR_ID, CST_ID) -> lấy 1 dòng / AR_CODE
    (dòng có REFRRER_OFCR trước) để không nhân dòng. PD (SCD1) lọc thêm SYS_EXP_DT IS NULL (bỏ mã sản phẩm đã xóa).
    CDR_DT = ETL_DATE. Chạy lại cùng ngày thay thế partition ETL_DATE đó (insert_overwrite).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH a AS (
    SELECT *
    FROM {{ ref('loan_ar') }}
    WHERE sys_exp_dt IS NULL
),

b AS (
    SELECT *
    FROM {{ ref('loan_ar_prfl') }}
    WHERE sys_exp_dt IS NULL
),

c AS (
    SELECT *
    FROM (
        SELECT
            x.*,
            ROW_NUMBER() OVER (
                PARTITION BY x.ar_code ORDER BY CASE WHEN x.refrrer_ofcr IS NULL THEN 1 ELSE 0 END, x.cst_code
            ) AS rn
        FROM {{ ref('ar_x_ip_rltnp') }} AS x
        WHERE x.sys_exp_dt IS NULL
    )
    WHERE rn = 1
),

d AS (
    SELECT *
    FROM {{ ref('empe') }}
    WHERE sys_exp_dt IS NULL
),

e AS (
    SELECT *
    FROM {{ ref('ar_rate_hist') }}
    WHERE sys_exp_dt IS NULL
),

f AS (
    SELECT *
    FROM {{ ref('pd') }}
    WHERE sys_exp_dt IS NULL
)

SELECT
    CAST({{ etl_date() }} AS DATE) AS cdr_dt,
    CAST(a.ar_code AS STRING) AS ar_code,
    CAST(a.cst_code AS STRING) AS cst_code,
    CAST(b.ou_code AS STRING) AS ou_code,
    CAST(COALESCE(a.val_dt, a.eff_dt) AS DATE) AS val_dt,
    CAST(a.eff_dt AS DATE) AS eff_dt,
    CAST(a.mat_dt AS DATE) AS mat_dt,
    CAST(a.ccy_code AS STRING) AS ccy_code,
    CAST(a.ar_pps_tp_code AS STRING) AS ar_pps_tp_code,
    CAST(a.ppr_ctr_nbr AS STRING) AS ppr_ctr_nbr,
    CAST(a.pd_cgy_code AS STRING) AS pd_cgy_code,
    CAST(a.orig_amt_fcy AS DECIMAL(25, 5)) AS orig_amt_fcy,
    CAST(CASE WHEN a.ccy_code = 'VND' THEN 1 ELSE a.exg_rate_to_lcl_ccy END AS DECIMAL(25, 7)) AS exg_rate_to_lcl_ccy,
    CAST(
        a.orig_amt_fcy * CASE WHEN a.ccy_code = 'VND' THEN 1 ELSE a.exg_rate_to_lcl_ccy END AS DECIMAL(25, 5)
    ) AS orig_amt_lcy,
    CAST(d.empe_nm AS STRING) AS empe_nm,
    CAST(e.eff_rate_pct AS DECIMAL(25, 7)) AS eff_rate_pct,
    CAST(b.ar_pps_by_idy AS STRING) AS ar_pps_by_idy,
    CAST(b.los_ctr_code AS STRING) AS los_ctr_code,
    CAST(b.car_ap_code AS STRING) AS car_ap_code,
    CAST(b.dsbr_prpsl_ofcr AS STRING) AS dsbr_prpsl_ofcr,
    CAST(b.dsbr_prpsl_mgr AS STRING) AS dsbr_prpsl_mgr,
    CAST(a.pd_code AS STRING) AS pd_code,
    CAST(f.pd_nm AS STRING) AS pd_nm,
    CAST(a.term_code AS STRING) AS loc_term,
    {{ etl_date() }} AS etl_date
FROM a
LEFT JOIN b ON a.ar_code = b.ar_code
LEFT JOIN c ON a.ar_code = c.ar_code
LEFT JOIN d ON COALESCE(c.refrrer_ofcr, b.refrrer_ofcr) = d.empe_code
LEFT JOIN e ON a.ar_code = e.ar_code
LEFT JOIN f ON a.pd_code = f.pd_code
