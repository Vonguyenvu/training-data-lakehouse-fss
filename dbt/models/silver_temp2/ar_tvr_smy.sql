{#-
    PG_SILVER.AR_TVR_SMY — sheet 'Arrangement Turnover Summary', Fact Snapshot theo ETL_DATE.
    Grain: 1 dòng / APP_ID của SOURCE_SAOKE_CRB (APP_CODE LD, PD; TXN_DATE = ngày nghiệp vụ).
    stmt = PST_ENTR gom theo AR_CODE (ngày / tháng / năm đến biz_date), dlq = AR_DLQ_SMY (CDR_DT = ETL_DATE) gom theo ORIG_AR_CODE,
    la = LOAN_AR phiên bản đang mở.
    Khác Excel:
      - Sheet bị lệch dòng: Transform của TOT_ODUE_PNP_AMT_FCY .. NBR_OF_DB_IN_YR trượt 1 dòng so với Cột đích
        (vd DSBR_AMT_LTD_FCY ghi NBR_OF_DB_IN_DAY). Map theo tên/diễn giải cột đích:
        TOT_ODUE_PNP_AMT_FCY = dlq.PNP_ARS, DSBR_AMT_LTD_FCY = COALESCE(la.DSBR_AMT_FCY, la.ORIG_AMT_FCY), các cột còn lại = stmt.<cùng tên>.
      - Gom CRB theo APP_ID trước rồi mới join (thay cho GROUP BY a.APP_ID, dlq.*, la.*, stmt.*).
      - PST_ENTR.ACG_CR_DB_F = 'DEBIT'/'CREDIT' -> so ký tự đầu với 'D'/'C'.
      - TXN_DATE / PST_DT so với biz_date (dữ liệu mẫu 2025); PST_ENTR đọc mọi partition, 1 dòng / PST_ENTR_ID (partition mới nhất).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH a AS (
    SELECT
        TRIM(x.app_id)                                                        AS ar_code,
        CASE WHEN TRIM(x.app_id) LIKE 'PDLD%' THEN SUBSTR(TRIM(x.app_id), 3, 12) ELSE TRIM(x.app_id) END AS orig_ar_code,
        SUM(CASE WHEN TRIM(x.sbv_code) LIKE '2%' AND TRY_CAST(TRIM(x.amount_cur) AS DECIMAL(32, 5)) < 0
                 THEN ABS(TRY_CAST(TRIM(x.amount_cur) AS DECIMAL(32, 5))) ELSE 0 END) AS cls_bal_fcy,
        SUM(CASE WHEN TRIM(x.sbv_code) LIKE '2%' AND TRY_CAST(TRIM(x.amount_lcy) AS DECIMAL(32, 5)) < 0
                 THEN ABS(TRY_CAST(TRIM(x.amount_lcy) AS DECIMAL(32, 5))) ELSE 0 END) AS cls_bal_lcy,
        SUM(CASE WHEN TRIM(x.sbv_code) LIKE '2%'
                  AND TRY_CAST(SUBSTR(TRIM(x.mat_date), 1, 10) AS DATE) = {{ biz_date() }}
                  AND TRY_CAST(TRIM(x.amount_cur) AS DECIMAL(32, 5)) < 0
                 THEN ABS(TRY_CAST(TRIM(x.amount_cur) AS DECIMAL(32, 5))) ELSE 0 END) AS tot_due_pnp_amt_fcy
    FROM {{ ref('source_saoke_crb') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND TRIM(x.app_code) IN ('LD', 'PD')
      AND TRY_CAST(SUBSTR(TRIM(x.txn_date), 1, 10) AS DATE) = {{ biz_date() }}
      AND NULLIF(TRIM(x.app_id), '') IS NOT NULL
    GROUP BY TRIM(x.app_id)
),

pst AS (
    -- PST_ENTR.ACG_CR_DB_F thực tế là 'DEBIT'/'CREDIT' (CRF_TYPE), sheet so 'D'/'C' -> lấy ký tự đầu
    SELECT ar_code, UPPER(SUBSTR(TRIM(acg_cr_db_f), 1, 1)) AS acg_cr_db_f, pst_dt, ABS(COALESCE(pst_entr_amt_fcy, 0)) AS amt, pst_entr_id
    FROM (
        SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.pst_entr_id ORDER BY p.etl_date DESC) AS rn
        FROM {{ ref('pst_entr') }} AS p
        WHERE p.etl_date <= {{ etl_date() }}
          AND p.pst_dt BETWEEN TRUNC({{ biz_date() }}, 'YEAR') AND {{ biz_date() }}
    )
    WHERE rn = 1
),

stmt AS (
    {%- set periods = {'day': 'pst_dt = ' ~ biz_date(), 'mo': "pst_dt >= TRUNC(" ~ biz_date() ~ ", 'MM')", 'yr': 'TRUE'} %}
    SELECT ar_code
    {%- for p, cond in periods.items() %}
        {%- for f, lbl in [('D', 'db'), ('C', 'cr')] %}
        , SUM(CASE WHEN acg_cr_db_f = '{{ f }}' AND {{ cond }} THEN amt ELSE 0 END)           AS {{ lbl }}_amt_in_{{ p }}_fcy
        , COUNT(CASE WHEN acg_cr_db_f = '{{ f }}' AND {{ cond }} THEN pst_entr_id END)        AS nbr_of_{{ lbl }}_in_{{ p }}
        {%- endfor %}
    {%- endfor %}
    FROM pst
    GROUP BY ar_code
),

dlq AS (
    SELECT TRIM(orig_ar_code) AS orig_ar_code, SUM(pnp_ars) AS pnp_ars
    FROM {{ ref('ar_dlq_smy') }}
    WHERE etl_date = {{ etl_date() }}
      AND cdr_dt = {{ etl_date() }}
    GROUP BY TRIM(orig_ar_code)
),

la AS (
    SELECT ar_code, dsbr_amt_fcy, orig_amt_fcy
    FROM {{ ref('loan_ar') }}
    WHERE sys_exp_dt IS NULL
)

SELECT
    CAST({{ etl_date() }} AS DATE)                                                       AS cdr_dt,
    CAST('SAOKE_CRB' AS STRING)                                                          AS src_stm_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'a.ar_code') }} AS STRING)              AS ar_id,
    CAST(a.ar_code AS STRING)                                                            AS ar_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'a.orig_ar_code') }} AS STRING)         AS orig_ar_id,
    CAST(a.orig_ar_code AS STRING)                                                       AS orig_ar_code,
    CAST(a.cls_bal_fcy AS DECIMAL(32, 5))                                                AS cls_bal_fcy,
    CAST(a.cls_bal_lcy AS DECIMAL(32, 5))                                                AS cls_bal_lcy,
    CAST(GREATEST(a.cls_bal_fcy - COALESCE(dlq.pnp_ars, 0), 0) AS DECIMAL(32, 5))        AS tot_recbl_pnp_amt_fcy,
    CAST(a.tot_due_pnp_amt_fcy AS DECIMAL(32, 5))                                        AS tot_due_pnp_amt_fcy,
    CAST(COALESCE(dlq.pnp_ars, 0) AS DECIMAL(32, 5))                                     AS tot_odue_pnp_amt_fcy,
    CAST(COALESCE(la.dsbr_amt_fcy, la.orig_amt_fcy) AS DECIMAL(32, 5))                   AS dsbr_amt_ltd_fcy,
    {%- for p in ['day', 'mo', 'yr'] %}
    {%- for lbl in ['db', 'cr'] %}
    CAST(COALESCE(stmt.{{ lbl }}_amt_in_{{ p }}_fcy, 0) AS DECIMAL(32, 5))                AS {{ lbl }}_amt_in_{{ p }}_fcy,
    CAST(COALESCE(stmt.nbr_of_{{ lbl }}_in_{{ p }}, 0) AS DECIMAL(32, 5))                 AS nbr_of_{{ lbl }}_in_{{ p }},
    {%- endfor %}
    {%- endfor %}
    {{ etl_date() }}                                                                     AS etl_date
FROM a
LEFT JOIN stmt ON stmt.ar_code = a.orig_ar_code
LEFT JOIN dlq  ON dlq.orig_ar_code = a.orig_ar_code
LEFT JOIN la   ON la.ar_code = a.ar_code
