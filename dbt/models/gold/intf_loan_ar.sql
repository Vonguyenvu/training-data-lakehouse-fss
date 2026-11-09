{#-
    PG_GOLD.INTF_LOAN_AR — sheet 'Interface Loan Arrangement', SNAPSHOT theo ETL_DATE.
    Grain = PG_SILVER.AR_BAL của ngày (AR_ID x GL_ITM_CODE): dòng gốc (2%) và dòng lãi dự thu (394%) là 2 dòng;
    báo cáo cấp hợp đồng phải lọc GL_ITM_CODE LIKE '2%' để không cộng trùng (ghi chú của sheet).
    JOIN: LOAN_AR b (INNER), LOAN_AR_PRFL c, AR_RATE_HIST d, OU i (SCD -> SYS_EXP_DT IS NULL);
          EXG_RATE f, INF_CST cst (partition ETL_DATE của ngày); AR_AVY_SHD_ITM shd (lịch trả nợ còn lại, gom theo AR_ID).
    Khóa hợp đồng gốc ld_key: PDLD... -> fn_hash('T24_LD_LOANS_AND_DEPOSITS', SUBSTR(AR_CODE, 3, 12)), ngược lại AR_ID;
    e1 (AR_DLQ_SMY) và k (AST_AR_INT_SMY) gom theo ORIG_AR_ID rồi join theo ld_key.
    Khác Excel:
      - e chỉ join cho hợp đồng PDLD% (1:1 theo AR_ID). Excel join e bằng CASE nên hợp đồng LD khớp mọi dòng PD con
        (nhân dòng); hợp đồng LD lấy PNP_ARS từ e1 (đã gom) -> NVL(e.PNP_ARS, e1.PNP_ARS) cho kết quả như ý đồ của sheet.
      - d (AR_RATE_HIST) là SCD2 -> lọc SYS_EXP_DT IS NULL (sheet ghi nhầm alias e / CDR_DT).
      - Số ngày quá hạn = DATEDIFF(biz_date, ngày quá hạn) + 1 và lịch trả nợ EFF_MAT_DT >= biz_date: đây là ngày
        nghiệp vụ (macro biz_date, mặc định = etl_date), Excel ghi ${ETL_DATE}.
      - INF_CST lấy 1 dòng / CST_CODE (phòng khách hàng có cả hồ sơ cá nhân lẫn tổ chức).
    CDR_DT = ETL_DATE. Chạy lại cùng ngày thay thế partition ETL_DATE đó (insert_overwrite).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH a AS (
    SELECT
        x.*,
        CASE
            WHEN x.ar_code LIKE 'PDLD%' THEN {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'SUBSTR(x.ar_code, 3, 12)') }}
            ELSE x.ar_id
        END AS ld_key
    FROM {{ ref('ar_bal') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

b AS (
    SELECT *
    FROM {{ ref('loan_ar') }}
    WHERE sys_exp_dt IS NULL
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

dlq AS (
    SELECT *
    FROM {{ ref('ar_dlq_smy') }}
    WHERE etl_date = {{ etl_date() }}
),

e AS (
    SELECT *
    FROM (
        SELECT
            x.*,
            ROW_NUMBER() OVER (PARTITION BY x.ar_id ORDER BY x.pnp_past_due_dt) AS rn
        FROM dlq AS x
    )
    WHERE rn = 1
),

e1 AS (
    SELECT
        orig_ar_id,
        SUM(COALESCE(pnp_ars, 0)) AS pnp_ars,
        MAX(DATEDIFF({{ biz_date() }}, pnp_past_due_dt)) + 1 AS so_ngay_qh_goc,
        MAX(DATEDIFF({{ biz_date() }}, int_past_due_dt)) + 1 AS so_ngay_qh_lai,
        GREATEST(
            COALESCE(MAX(DATEDIFF({{ biz_date() }}, pnp_past_due_dt)) + 1, 0),
            COALESCE(MAX(DATEDIFF({{ biz_date() }}, int_past_due_dt)) + 1, 0)
        ) AS songay_qhan_caonhat,
        MAX(COALESCE(addition_dys_in_ars, 0)) AS snqh_chuyendoi
    FROM dlq
    GROUP BY orig_ar_id
),

f AS (
    SELECT *
    FROM {{ ref('exg_rate') }}
    WHERE etl_date = {{ etl_date() }}
),

i AS (
    SELECT *
    FROM {{ ref('ou') }}
    WHERE sys_exp_dt IS NULL
),

k AS (
    SELECT
        orig_ar_id,
        SUM(tot_acr_int_amt_fcy) AS tot_acr_int_amt_fcy,
        SUM(tot_int_paid_amt_fcy) AS tot_int_paid_amt_fcy,
        SUM(tot_int_due_amt_fcy) AS tot_int_due_amt_fcy,
        SUM(tot_int_odue_amt_fcy) AS tot_int_odue_amt_fcy
    FROM {{ ref('ast_ar_int_smy') }}
    WHERE etl_date = {{ etl_date() }}
    GROUP BY orig_ar_id
),

cst AS (
    SELECT *
    FROM (
        SELECT
            x.*,
            ROW_NUMBER() OVER (PARTITION BY x.cst_code ORDER BY x.cst_grp_code) AS rn
        FROM {{ ref('inf_cst') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

shd AS (
    SELECT
        ar_id,
        MIN(CASE WHEN pbl_amt_tp IN ('LD_PR', 'PD_PR') THEN eff_mat_dt END) AS ngay_thanh_toan_goc_tieptheo,
        SUM(CASE WHEN pbl_amt_tp IN ('LD_PR', 'PD_PR') THEN COALESCE(pbl_amt_fcy, 0) ELSE 0 END) AS so_tien_thuno_goc,
        MIN(CASE WHEN pbl_amt_tp IN ('LD_IN', 'PD_IN') THEN eff_mat_dt END) AS ngay_thanh_toan_lai
    FROM {{ ref('ar_avy_shd_itm') }}
    WHERE
        sys_exp_dt IS NULL
        AND eff_mat_dt >= {{ biz_date() }}
    GROUP BY ar_id
)

SELECT
    CAST({{ etl_date() }} AS DATE) AS cdr_dt,
    CAST(a.ar_code AS STRING) AS ar_code,
    CAST(b.eff_dt AS DATE) AS eff_dt,
    CAST(a.pd_cgy_code AS STRING) AS pd_cgy_code,
    CAST(b.ppr_ctr_nbr AS STRING) AS ppr_ctr_nbr,
    CAST(c.ou_code AS STRING) AS ou_code,
    CAST(a.sub_pd_code AS STRING) AS sub_pd_code,
    CAST(a.cst_code AS STRING) AS cst_code,
    CAST(c.ar_lcs_tp_code AS STRING) AS ar_lcs_tp_code,
    CAST(a.mud_code AS STRING) AS mud_code,
    CAST(c.fnc_st_code AS STRING) AS fnc_st_code,
    CAST(b.ccy_code AS STRING) AS ccy_code,
    CAST(b.mat_dt AS DATE) AS mat_dt,
    CAST(COALESCE(b.orig_amt_fcy, 0) AS DECIMAL(25, 5)) AS approve_amount,
    CAST(COALESCE(b.val_dt, b.fcc_val_dt, b.eff_dt) AS DATE) AS val_dt,
    CAST(c.pnp_lqd_ar_code AS STRING) AS drawdown_account,
    CAST(a.ar_term_tp_code AS STRING) AS ar_term_tp_code,
    CAST(b.lmt_code AS STRING) AS lmt_code,
    CAST(NULL AS DECIMAL(22, 0)) AS int_key,
    CAST(d.sprd_rate_pct AS DECIMAL(25, 7)) AS int_sprd,
    CAST(c.int_lqd_ar_code AS STRING) AS int_lqd_ar_code,
    CAST(b.fcc_ar_code AS STRING) AS fcc_ar_code,
    CAST(d.pny_rate AS DECIMAL(25, 7)) AS pny_rate,
    CAST(d.odue_int_rate AS DECIMAL(25, 7)) AS odue_int_rate,
    CAST(CASE WHEN a.gl_itm_code LIKE '2%' AND a.rcvb_amt_lcy < 0 THEN ABS(a.rcvb_amt_lcy) ELSE 0 END AS DECIMAL(25, 5)) AS amount_cur,
    CAST(d.int_rate_variablity_tp_code AS STRING) AS int_tp,
    CAST(NULL AS STRING) AS int_bss,
    CAST(CASE WHEN d.int_rate_variablity_tp_code IN ('1', 'FIX', 'FIXED') THEN 'Y' WHEN d.int_rate_variablity_tp_code IS NOT NULL THEN 'N' END AS STRING) AS int_fix,
    CAST(d.eff_rate_pct AS DECIMAL(25, 7)) AS rate,
    CAST(a.cdr_dt AS DATE) AS txn_dt,
    CAST(COALESCE(e.pnp_ars, e1.pnp_ars, 0) AS DECIMAL(25, 5)) AS odue_pr_amt,
    CAST(COALESCE(k.tot_int_odue_amt_fcy, 0) AS DECIMAL(32, 5)) AS odue_in_amt,
    CAST(0 AS DECIMAL(25, 5)) AS odue_pe_amt,
    CAST(0 AS DECIMAL(25, 5)) AS odue_ps_amt,
    CAST(d.mrgn_rate AS DECIMAL(25, 7)) AS mrgn_rate,
    CAST(b.pd_code AS STRING) AS pd_code,
    CAST(CASE WHEN cst.cst_grp_code LIKE '%INDIV%' THEN b.pd_code END AS STRING) AS khcn_pd_code,
    CAST(c.dsbr_prpsl_ofcr AS STRING) AS dsbr_prpsl_ofcr,
    CAST(c.dsbr_prpsl_mgr AS STRING) AS dsbr_prpsl_mgr,
    CAST(c.mgt_ofcr AS STRING) AS mgt_ofcr,
    CAST(c.mgt_mgr AS STRING) AS mgt_mgr,
    CAST(c.aprv_ahr AS STRING) AS aprv_ahr,
    CAST(c.dbt_wvr_f AS STRING) AS dbt_wvr_f,
    CAST(c.nbr_of_dbt_rstc AS DECIMAL(22, 0)) AS nbr_of_dbt_rstc,
    CAST(c.ar_pps_by_pd AS STRING) AS ar_pps_by_pd,
    CAST(COALESCE(e1.so_ngay_qh_goc, 0) AS DECIMAL(22, 0)) AS dys_in_pnp_ars,
    CAST(COALESCE(e1.so_ngay_qh_lai, 0) AS DECIMAL(22, 0)) AS dys_in_int_ars,
    CAST(COALESCE(k.tot_int_due_amt_fcy, 0) + COALESCE(k.tot_int_odue_amt_fcy, 0) AS DECIMAL(32, 5)) AS tot_int_ars,
    CAST(a.cst_id AS STRING) AS cst_id,
    CAST(cst.cst_fnc_st_code AS STRING) AS cst_fnc_st_code,
    CAST(f.mid_rate AS DECIMAL(25, 7)) AS mid_rate,
    CAST(CASE WHEN a.gl_itm_code LIKE '2%' AND a.cls_bal_lcy < 0 THEN ABS(a.cls_bal_lcy) ELSE 0 END AS DECIMAL(25, 5)) AS amt_lcy,
    CAST(COALESCE(b.orig_amt_fcy, 0) * CASE WHEN b.ccy_code = 'VND' THEN 1 ELSE COALESCE(f.mid_rate, b.exg_rate_to_lcl_ccy) END AS DECIMAL(25, 5)) AS aprv_amt_lcy,
    CAST(COALESCE(e1.songay_qhan_caonhat, 0) + COALESCE(e1.snqh_chuyendoi, 0) AS DECIMAL(22, 0)) AS mx_dys_in_ars,
    CAST(COALESCE(k.tot_int_paid_amt_fcy, 0) AS DECIMAL(32, 5)) AS tot_int_paid_amt_fcy,
    CAST(c.fnc_st_code AS STRING) AS ar_fnc_st_code,
    CAST(cst.jnt_lby_f AS STRING) AS jnt_lby_f,
    CAST(b.fcc_lmt_code AS STRING) AS fcc_lmt_code,
    CAST(c.maker_ofcr AS STRING) AS maker_ofcr_code,
    CAST(c.chker_ofcr AS STRING) AS chker_ofcr_code,
    CAST(cst.cst_grp_code AS STRING) AS cst_grp_code,
    CAST(CASE WHEN b.fcc_ar_code IS NOT NULL THEN SUBSTR(c.ar_pps_by_idy, 2) ELSE b.ar_pps_tp_code END AS STRING) AS ar_pps_tp_code,
    CAST(b.ar_pps_grp_code AS STRING) AS ar_pps_grp_code,
    CAST(c.los_ctr_code AS STRING) AS los_ctr_code,
    CAST(c.los_ctr_id AS STRING) AS los_ctr_id,
    CAST(c.dbt_rstc_tp_code AS STRING) AS dbt_rstc_tp_code,
    CAST(c.car_ap_code AS STRING) AS car_ap_code,
    CAST(c.scr_tp AS STRING) AS scr_tp,
    CAST(c.mand_repymt AS STRING) AS mand_repymt,
    CAST(b.los_ctr_nbr AS STRING) AS los_ctr_nbr,
    CAST(c.prom_prgm AS STRING) AS prom_prgm,
    CAST(c.prom_prgm_2 AS STRING) AS prom_prgm_2,
    CAST(cst.sctr_code AS STRING) AS sctr_code,
    CAST(c.covid19_rstc_compl_dt AS DATE) AS covid19_rstc_compl_dt,
    CAST(shd.ngay_thanh_toan_goc_tieptheo AS DATE) AS ngay_thanh_toan_goc_tieptheo,
    CAST(COALESCE(shd.so_tien_thuno_goc, 0) AS DECIMAL(25, 5)) AS so_tien_thuno_goc,
    CAST(shd.ngay_thanh_toan_lai AS DATE) AS ngay_thanh_toan_lai,
    CAST(cst.idy_lv1_cl_code AS STRING) AS idy_lv1_cl_code,
    CAST(cst.idy_lv2_cl_code AS STRING) AS idy_lv2_cl_code,
    CAST(CASE WHEN a.mud_code = 'LD' AND a.gl_itm_code LIKE '394%' THEN ABS(a.rcvb_amt_lcy) ELSE 0 END AS DECIMAL(25, 5)) AS tot_acr_int_due_amt,
    CAST(CASE WHEN a.mud_code = 'LD' AND a.gl_itm_code LIKE '394%' THEN ABS(a.rcvb_amt_lcy) ELSE 0 END AS DECIMAL(25, 5)) AS nxt_acr_int_amt,
    CAST(GREATEST(COALESCE(k.tot_acr_int_amt_fcy, 0) - COALESCE(k.tot_int_paid_amt_fcy, 0), 0) AS DECIMAL(25, 5)) AS dthu_conlai_dukien_kygannhat,
    CAST(i.ou_nm AS STRING) AS ou_nm,
    CAST(COALESCE(e1.snqh_chuyendoi, 0) AS DECIMAL(22, 0)) AS addition_dys_in_ars,
    CAST(c.bds_tt11 AS STRING) AS bds_tt11,
    CAST(a.gl_itm_code AS STRING) AS gl_itm_code,
    CAST(CASE WHEN cst.cst_grp_code LIKE '%INDIV%' THEN 'INDIV' ELSE 'CORP' END AS STRING) AS cst_tp_code,
    CAST(cst.cst_nm AS STRING) AS cst_nm,
    {{ etl_date() }} AS etl_date
FROM a
INNER JOIN b ON a.ar_id = b.ar_id
LEFT JOIN c ON a.ar_id = c.ar_id
LEFT JOIN d ON a.ar_id = d.ar_id
LEFT JOIN e
    ON
        a.ar_id = e.ar_id
        AND a.ar_code LIKE 'PDLD%'
LEFT JOIN e1 ON a.ld_key = e1.orig_ar_id
LEFT JOIN f ON b.ccy_code = f.frst_ccy_code
LEFT JOIN i ON c.ou_code = i.ou_code
LEFT JOIN k ON a.ld_key = k.orig_ar_id
LEFT JOIN cst ON a.cst_code = cst.cst_code
LEFT JOIN shd ON a.ar_id = shd.ar_id
