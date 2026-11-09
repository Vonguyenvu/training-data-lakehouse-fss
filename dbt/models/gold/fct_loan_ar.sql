{#-
    PG_GOLD.FCT_LOAN_AR — sheet 'Fact Loan Arrangement', SNAPSHOT theo ETL_DATE: 1 dòng / hợp đồng vay đang hiệu lực
    có số dư trong ngày, kèm DIM_KEY của 9 chiều (DIM lấy phiên bản đang mở SYS_EXP_DT IS NULL).
    PG_SILVER.LOAN_AR a (SYS_EXP_DT IS NULL) INNER JOIN AR_BAL b (ngày) / DIM_LOAN_AR / DIM_CST;
    LEFT JOIN LOAN_AR_PRFL c, AR_RATE_HIST d, IDV_PRFL l, ORG_PRFL m (SYS_EXP_DT IS NULL), EXG_RATE g (ngày),
    AR_DLQ_SMY e / AST_AR_INT_SMY h / AR_TVR_SMY k (ngày, gom theo ORIG_AR_ID), các DIM còn lại.
    Khác Excel:
      - b: Excel SELECT DISTINCT (AR_ID, CDR_DT, MUD_CODE); vẫn có thể >1 dòng / AR_ID nếu 1 hợp đồng có >1 MUD_CODE
        -> gom 1 dòng / AR_ID (MAX(MUD_CODE)) để giữ grain 1 dòng / hợp đồng.
      - Số ngày quá hạn = DATEDIFF(biz_date, ngày quá hạn) + 1 (ngày nghiệp vụ, mặc định = etl_date).
      - Lọc ngày các bảng SNAPSHOT bằng partition ETL_DATE (= CDR_DT / SNPST_DT = ${ETL_DATE} của sheet).
    Chạy lại cùng ngày thay thế partition ETL_DATE đó (insert_overwrite).
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
    SELECT
        ar_id,
        MAX(mud_code) AS mud_code
    FROM {{ ref('ar_bal') }}
    WHERE etl_date = {{ etl_date() }}
    GROUP BY ar_id
),

c AS (
    SELECT *
    FROM {{ ref('loan_ar_prfl') }}
    WHERE sys_exp_dt IS NULL
),

d AS (
    SELECT *
    FROM {{ ref('ar_rate_hist') }}
    WHERE sys_exp_dt IS NULL
),

e AS (
    SELECT
        orig_ar_id,
        MAX(DATEDIFF({{ biz_date() }}, pnp_past_due_dt)) + 1 AS so_ngay_qh_goc,
        MAX(DATEDIFF({{ biz_date() }}, int_past_due_dt)) + 1 AS so_ngay_qh_lai,
        GREATEST(
            COALESCE(MAX(DATEDIFF({{ biz_date() }}, pnp_past_due_dt)) + 1, 0),
            COALESCE(MAX(DATEDIFF({{ biz_date() }}, int_past_due_dt)) + 1, 0)
        ) AS songay_qhan_caonhat,
        MAX(COALESCE(addition_dys_in_ars, 0)) AS snqh_chuyendoi
    FROM {{ ref('ar_dlq_smy') }}
    WHERE etl_date = {{ etl_date() }}
    GROUP BY orig_ar_id
),

g AS (
    SELECT *
    FROM {{ ref('exg_rate') }}
    WHERE etl_date = {{ etl_date() }}
),

h AS (
    SELECT
        orig_ar_id,
        SUM(tot_int_paid_amt_fcy) AS tot_int_paid_amt_fcy,
        SUM(tot_int_due_amt_fcy) AS tot_int_due_amt_fcy,
        SUM(tot_int_odue_amt_fcy) AS tot_int_odue_amt_fcy
    FROM {{ ref('ast_ar_int_smy') }}
    WHERE etl_date = {{ etl_date() }}
    GROUP BY orig_ar_id
),

k AS (
    SELECT
        orig_ar_id,
        SUM(cls_bal_lcy) AS cls_bal_lcy
    FROM {{ ref('ar_tvr_smy') }}
    WHERE etl_date = {{ etl_date() }}
    GROUP BY orig_ar_id
),

l AS (
    SELECT *
    FROM {{ ref('idv_prfl') }}
    WHERE sys_exp_dt IS NULL
),

m AS (
    SELECT *
    FROM {{ ref('org_prfl') }}
    WHERE sys_exp_dt IS NULL
),

-- ref() viết tường minh (không lặp Jinja): dags/dbt_command.py đọc phụ thuộc bằng regex ref('...').
dim_ar AS (
    SELECT *
    FROM {{ ref('dim_loan_ar') }}
    WHERE sys_exp_dt IS NULL
),

dim_cst AS (
    SELECT *
    FROM {{ ref('dim_cst') }}
    WHERE sys_exp_dt IS NULL
),

dim_pd AS (
    SELECT *
    FROM {{ ref('dim_pd') }}
    WHERE sys_exp_dt IS NULL
),

dim_ou AS (
    SELECT *
    FROM {{ ref('dim_ou') }}
    WHERE sys_exp_dt IS NULL
),

dim_ccy AS (
    SELECT *
    FROM {{ ref('dim_ccy') }}
    WHERE sys_exp_dt IS NULL
),

dim_lmt AS (
    SELECT *
    FROM {{ ref('dim_lmt') }}
    WHERE sys_exp_dt IS NULL
),

dim_rstc AS (
    SELECT *
    FROM {{ ref('dim_rstc_tp') }}
    WHERE sys_exp_dt IS NULL
),

dim_fnc AS (
    SELECT *
    FROM {{ ref('dim_fnc_st') }}
    WHERE sys_exp_dt IS NULL
)

SELECT
    CAST({{ etl_date() }} AS DATE) AS cdr_dt_dim_key,
    CAST(dim_ar.dim_key AS STRING) AS loan_ar_dim_key,
    CAST(dim_cst.dim_key AS STRING) AS cst_dim_key,
    CAST(dim_pd.dim_key AS STRING) AS pd_dim_key,
    CAST(dim_ou.dim_key AS STRING) AS ou_dim_key,
    CAST(dim_ccy.dim_key AS STRING) AS ccy_dim_key,
    CAST(dim_lmt.dim_key AS STRING) AS lmt_dim_key,
    CAST(dim_rstc.dim_key AS STRING) AS loan_rstc_tp_dim_key,
    CAST(dim_fnc_1.dim_key AS STRING) AS loan_ar_fnc_st_dim_key,
    CAST(dim_fnc_2.dim_key AS STRING) AS cst_fnc_st_dim_key,
    CAST(b.mud_code AS STRING) AS mud_code,
    CAST(d.pny_rate AS DECIMAL(25, 7)) AS pny_rate,
    CAST(d.odue_int_rate AS DECIMAL(25, 7)) AS odue_int_rate,
    CAST(COALESCE(h.tot_int_due_amt_fcy, 0) + COALESCE(h.tot_int_odue_amt_fcy, 0) AS DECIMAL(32, 5)) AS tot_int_ars_fcy,
    CAST(COALESCE(h.tot_int_paid_amt_fcy, 0) AS DECIMAL(32, 5)) AS tot_int_paid_amt_fcy,
    CAST(COALESCE(e.so_ngay_qh_goc, 0) AS DECIMAL(32, 0)) AS dys_in_pnp_ars,
    CAST(COALESCE(e.so_ngay_qh_lai, 0) AS DECIMAL(32, 0)) AS dys_in_int_ars,
    CAST(COALESCE(e.songay_qhan_caonhat, 0) + COALESCE(e.snqh_chuyendoi, 0) AS DECIMAL(32, 0)) AS mx_dys_in_ars,
    CAST(COALESCE(e.snqh_chuyendoi, 0) AS DECIMAL(32, 0)) AS addition_dys_in_ars,
    CAST(COALESCE(k.cls_bal_lcy, 0) AS DECIMAL(32, 5)) AS otsnd_amt_lcy,
    CAST(g.mid_rate AS DECIMAL(25, 7)) AS exg_rate_to_lcl_ccy,
    CAST(c.nbr_of_dbt_rstc AS DECIMAL(22, 0)) AS nbr_of_dbt_rstc,
    {{ etl_date() }} AS etl_date
FROM a
INNER JOIN b ON a.ar_id = b.ar_id
INNER JOIN dim_ar ON a.ar_id = dim_ar.ar_id
INNER JOIN dim_cst ON a.cst_id = dim_cst.cst_id
LEFT JOIN c ON a.ar_id = c.ar_id
LEFT JOIN d ON a.ar_id = d.ar_id
LEFT JOIN e ON a.ar_id = e.orig_ar_id
LEFT JOIN g ON a.ccy_code = g.frst_ccy_code
LEFT JOIN h ON a.ar_id = h.orig_ar_id
LEFT JOIN k ON a.ar_id = k.orig_ar_id
LEFT JOIN l ON a.cst_id = l.cst_id
LEFT JOIN m ON a.cst_id = m.cst_id
LEFT JOIN dim_pd ON a.pd_code = dim_pd.pd_code
LEFT JOIN dim_ou ON c.ou_code = dim_ou.ou_code
LEFT JOIN dim_ccy ON a.ccy_code = dim_ccy.ccy_code
LEFT JOIN dim_lmt ON a.lmt_id = dim_lmt.lmt_id
LEFT JOIN dim_rstc ON c.dbt_rstc_tp_code = dim_rstc.rstc_tp_code
LEFT JOIN dim_fnc AS dim_fnc_1 ON c.fnc_st_code = dim_fnc_1.fnc_st_code
LEFT JOIN dim_fnc AS dim_fnc_2 ON COALESCE(l.cst_fnc_st_code, m.cst_fnc_st_code) = dim_fnc_2.fnc_st_code
