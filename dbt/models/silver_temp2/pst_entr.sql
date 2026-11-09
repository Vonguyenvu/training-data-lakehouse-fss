{#-
    PG_SILVER.PST_ENTR — sheet 'Posting Entry', TXN: load như SNAPSHOT, ghi đè partition ETL_DATE.
    T24CORE_STMT_ENTRY (RECID NOT LIKE 'F%', COMMIT_ACTION <> 'D', BOOKING_DATE = ngày nghiệp vụ)
      LEFT JOIN LD (RECID = contract_id, DATE_TIME <= ngày nghiệp vụ)
      LEFT JOIN PD_PAYMENT_DUE_MV (SUBSTR(RECID,3) = contract_id, FLAG_STATUS <> 'DELETE', DATE_TIME <= ngày nghiệp vụ).
    contract_id = OUR_REFERENCE nếu 'LD%', SUBSTR(OUR_REFERENCE, 3) nếu 'PD%'. Grain = 1 bút toán.
    Ngày nghiệp vụ = biz_date() (mặc định = etl_date).
    Khác Excel:
      - PD_PAYMENT_DUE_MV không có khóa duy nhất -> lấy 1 dòng / contract_id (DATE_TIME mới nhất) để không nhân bút toán.
      - COMMIT_ACTION <> 'D' -> COALESCE (NULL ở ~20% dòng). CATEGORY so sánh sau t24_code.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH stmt AS (
    SELECT
        s.*,
        CASE
            WHEN s.our_reference LIKE 'LD%' THEN TRIM(s.our_reference)
            WHEN s.our_reference LIKE 'PD%' THEN SUBSTR(TRIM(s.our_reference), 3)
        END AS contract_id
    FROM {{ ref('t24core_stmt_entry') }} AS s
    WHERE
        s.etl_date = {{ etl_date() }}
        AND s.recid NOT LIKE 'F%'
        AND COALESCE(s.commit_action, '') <> 'D'
        AND {{ t24_date('s.booking_date') }} = {{ biz_date() }}
),

ld AS (
    SELECT TRIM(l.recid) AS recid, {{ t24_code('l.category') }} AS category, TRIM(l.co_code) AS co_code
    FROM {{ ref('t24core_ld_loans_and_deposits') }} AS l
    WHERE
        l.etl_date = {{ etl_date() }}
        AND CAST({{ t24_datetime('l.date_time') }} AS DATE) <= {{ biz_date() }}
),

pd AS (
    SELECT contract_id, category, co_code
    FROM (
        SELECT
            SUBSTR(TRIM(p.recid), 3) AS contract_id, {{ t24_code('p.category') }} AS category, TRIM(p.co_code) AS co_code,
            ROW_NUMBER() OVER (
                PARTITION BY SUBSTR(TRIM(p.recid), 3)
                ORDER BY {{ t24_datetime('p.date_time') }} DESC
            ) AS rn
        FROM {{ ref('t24core_pd_payment_due_mv') }} AS p
        WHERE
            p.etl_date = {{ etl_date() }}
            AND COALESCE(p.flag_status, '') <> 'DELETE'
            AND CAST({{ t24_datetime('p.date_time') }} AS DATE) <= {{ biz_date() }}
    )
    WHERE rn = 1
)

SELECT
    CAST({{ fn_hash('T24_STMT_ENTRY', 'stmt.recid') }} AS STRING) AS pst_entr_id,
    CAST('T24_STMT_ENTRY' AS STRING) AS src_stm_code,
    CAST(TRIM(stmt.recid) AS STRING) AS pst_entr_nbr,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'stmt.our_reference') }} AS STRING) AS txn_id,
    CAST(TRIM(stmt.our_reference) AS STRING) AS txn_nbr,
    CAST(TRIM(stmt.crf_type) AS STRING) AS acg_cr_db_f,
    CAST(TRIM(stmt.transaction_code) AS STRING) AS txn_code,
    {{ t24_date('stmt.booking_date') }} AS pst_dt,
    CAST(COALESCE(TRY_CAST(TRIM(stmt.amount_fcy) AS DECIMAL(25, 5)), 0) AS DECIMAL(25, 5)) AS pst_entr_amt_fcy,
    CAST(COALESCE(TRY_CAST(TRIM(stmt.amount_lcy) AS DECIMAL(25, 5)), 0) AS DECIMAL(25, 5)) AS pst_entr_amt_lcy,
    CAST(TRIM(stmt.currency) AS STRING) AS ccy_code,
    {{ t24_date('stmt.value_date') }} AS val_dt,
    TRY_CAST(TRIM(stmt.exchange_rate) AS DECIMAL(25, 7)) AS exg_rate,
    CAST(COALESCE(ld.co_code, pd.co_code, TRIM(stmt.company_code)) AS STRING) AS ou_code,
    CAST(TRIM(stmt.account_number) AS STRING) AS ac_nbr,
    CAST(stmt.contract_id AS STRING) AS ar_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'stmt.contract_id') }} AS STRING) AS ar_id,
    CAST({{ fn_hash('T24_CUSTOMER', 'stmt.customer_id') }} AS STRING) AS cst_id,
    CAST(TRIM(stmt.customer_id) AS STRING) AS cst_nbr,
    CAST(TRIM(stmt.product_category) AS STRING) AS acg_pd_cgy,
    CAST(TRIM(stmt.narrative) AS STRING) AS pst_entr_dsc,
    CAST(TRIM(stmt.consol_key) AS STRING) AS consol_key,
    CAST(TRIM(stmt.system_id) AS STRING) AS mod_code,
    CAST(CASE
        WHEN stmt.transaction_code = '402' THEN 'LD_GN'
        WHEN
            stmt.transaction_code IN ('420', '423')
            AND COALESCE(ld.category, pd.category, {{ t24_code('stmt.crf_prod_cat') }}, '_') <> '21069' THEN 'LD_PR'
        WHEN
            stmt.transaction_code IN ('434', '424')
            OR (
                stmt.transaction_code IN ('420', '423')
                AND COALESCE(ld.category, pd.category, {{ t24_code('stmt.crf_prod_cat') }}) = '21069'
            ) THEN 'LD_IN'
        WHEN stmt.transaction_code = '750' THEN 'PD_PR'
        WHEN stmt.transaction_code = '751' THEN 'PD_IN'
        WHEN stmt.transaction_code = '752' THEN 'PD_PE'
        WHEN stmt.transaction_code = '753' THEN 'PD_PS'
    END AS STRING) AS pst_entr_cmpt,
    {{ t24_date('stmt.accounting_date') }} AS acg_dt,
    CAST({{ fn_hash('T24_ACCOUNT', 'stmt.acct_id') }} AS STRING) AS ac_id,
    CAST(TRIM(stmt.balance_type) AS STRING) AS bal_tp,
    CAST(TRIM(stmt.card_number) AS STRING) AS card_nbr,
    CAST(TRIM(stmt.commit_action) AS STRING) AS cmmt_actn,
    try_to_timestamp(NULLIF(TRIM(stmt.commit_ts), ''), 'dd-MMM-yy hh.mm.ss.SSSSSS a') AS cmmt_tms,
    CAST(TRIM(stmt.crf_prod_cat) AS STRING) AS cgy_pd_code,
    TRY_CAST(TRIM(stmt.curr_no) AS DECIMAL(22, 0)) AS crn_nbr,
    {{ t24_date('stmt.cycle_forward') }} AS cyc_fwd,
    CAST({{ t24_datetime('stmt.date_time') }} AS DATE) AS dt_tm,
    CAST(TRIM(stmt.department_code) AS STRING) AS dept_code,
    CAST(TRIM(stmt.drawn_account) AS STRING) AS drn_ac,
    CAST(TRIM(stmt.internal_category) AS STRING) AS inr_cgy,
    CAST(TRIM(stmt.local_ref) AS STRING) AS lcl_refr,
    TRY_CAST(TRIM(stmt.orig_amount_lcy) AS DECIMAL(25, 5)) AS orig_amt_lcy,
    CAST(TRIM(stmt.original_acct) AS STRING) AS orig_ac,
    TRY_CAST(TRIM(stmt.original_amount) AS DECIMAL(25, 5)) AS orig_amt,
    CAST(TRIM(stmt.original_ccy) AS STRING) AS orig_ccy,
    TRY_CAST(TRIM(stmt.original_exch_rate) AS DECIMAL(25, 7)) AS orig_exg_rate,
    TRY_CAST(TRIM(stmt.outstanding_bal) AS DECIMAL(25, 5)) AS otsnd_bal,
    CAST(TRIM(stmt.override) AS STRING) AS ovrd,
    CAST(TRIM(stmt.process_forward) AS STRING) AS pcs_fwd,
    CAST(TRIM(stmt.record_status) AS STRING) AS rcrd_st,
    TRY_CAST(TRIM(stmt.repayment_amt) AS DECIMAL(25, 5)) AS repymt_amt,
    {{ t24_date('stmt.repayment_date') }} AS repymt_dt,
    CAST(TRIM(stmt.repayment_type) AS STRING) AS repymt_tp,
    CAST(TRIM(stmt.suspense_category) AS STRING) AS susp_cgy,
    {{ t24_date('stmt.suspnse_value_date') }} AS susp_val_dt,
    {{ etl_date() }} AS etl_date
FROM stmt
LEFT JOIN ld ON ld.recid = stmt.contract_id
LEFT JOIN pd ON pd.contract_id = stmt.contract_id
