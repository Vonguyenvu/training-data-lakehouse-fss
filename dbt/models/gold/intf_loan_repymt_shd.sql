{#-
    PG_GOLD.INTF_LOAN_REPYMT_SHD — sheet 'Interface Loan Repayment Schedu', SNAPSHOT theo ETL_DATE.
    PG_SILVER.AR_AVY_SHD_ITM arr_shd (AR_AVY_SHD_TP = 'LOAN_PD_SHD', kỳ chưa đến hạn EFF_MAT_DT >= ngày nghiệp vụ,
    SYS_EXP_DT IS NULL) LEFT JOIN LOAN_AR, LOAN_AR_PRFL (AR_ID), CST, IDV_PRFL, ORG_PRFL (CST_ID); mọi bảng SYS_EXP_DT IS NULL.
    Khác Excel: so EFF_MAT_DT với biz_date (ngày nghiệp vụ, mặc định = etl_date) thay vì ${ETL_DATE}.
    CIC_LOAN_GRP: TRY_CAST nhóm nợ khách hàng (mặc định '1') sang DECIMAL(1,0).
    CDR_DT = ETL_DATE. Chạy lại cùng ngày thay thế partition ETL_DATE đó (insert_overwrite).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH arr_shd AS (
    SELECT *
    FROM {{ ref('ar_avy_shd_itm') }}
    WHERE
        ar_avy_shd_tp = 'LOAN_PD_SHD'
        AND eff_mat_dt >= {{ biz_date() }}
        AND sys_exp_dt IS NULL
),

arr_loan AS (
    SELECT *
    FROM {{ ref('loan_ar') }}
    WHERE sys_exp_dt IS NULL
),

arr_prfl AS (
    SELECT *
    FROM {{ ref('loan_ar_prfl') }}
    WHERE sys_exp_dt IS NULL
),

cst AS (
    SELECT *
    FROM {{ ref('cst') }}
    WHERE sys_exp_dt IS NULL
),

cst_idv AS (
    SELECT *
    FROM {{ ref('idv_prfl') }}
    WHERE sys_exp_dt IS NULL
),

cst_org AS (
    SELECT *
    FROM {{ ref('org_prfl') }}
    WHERE sys_exp_dt IS NULL
)

SELECT
    CAST({{ etl_date() }} AS DATE) AS cdr_dt,
    CAST(arr_shd.cst_id AS STRING) AS cst_id,
    CAST(arr_shd.cst_code AS STRING) AS cst_code,
    CAST(arr_shd.ar_avy_shd_code AS STRING) AS ar_avy_shd_code,
    CAST(arr_shd.ar_code AS STRING) AS ar_code,
    CAST(arr_prfl.ou_code AS STRING) AS ou_code,
    CAST(arr_shd.eff_mat_dt AS DATE) AS eff_mat_dt,
    CAST(arr_shd.ccy_code AS STRING) AS ccy_code,
    CAST(arr_shd.pbl_amt_tp AS STRING) AS pbl_amt_tp,
    CAST(arr_shd.pbl_amt_lcy AS DECIMAL(25, 5)) AS pbl_amt_lcy,
    CAST(arr_shd.pbl_amt_fcy AS DECIMAL(25, 5)) AS pbl_amt_fcy,
    CAST(arr_shd.exg_rate AS DECIMAL(25, 7)) AS exg_rate,
    CAST('DUE' AS STRING) AS lnd_repymt_tp,
    CAST(arr_shd.f_last_od_dt AS DECIMAL(1, 0)) AS f_last_od_dt,
    CAST(arr_shd.last_od_dt AS DATE) AS last_od_dt,
    CAST(arr_loan.fcc_val_dt AS DATE) AS fcc_val_dt,
    CAST(arr_loan.mat_dt AS DATE) AS mat_dt,
    CAST(arr_prfl.gl_itm_code AS STRING) AS gl_itm_code,
    TRY_CAST(COALESCE(cst_org.cst_fnc_st_code, cst_idv.cst_fnc_st_code, '1') AS DECIMAL(1, 0)) AS cic_loan_grp,
    CAST(cst.cst_nm AS STRING) AS cst_full_nm,
    {{ etl_date() }} AS etl_date
FROM arr_shd
LEFT JOIN arr_loan ON arr_shd.ar_id = arr_loan.ar_id
LEFT JOIN arr_prfl ON arr_shd.ar_id = arr_prfl.ar_id
LEFT JOIN cst ON arr_shd.cst_id = cst.cst_id
LEFT JOIN cst_idv ON arr_shd.cst_id = cst_idv.cst_id
LEFT JOIN cst_org ON arr_shd.cst_id = cst_org.cst_id
