{#-
    PG_SILVER.SAOKE_GIAINGAN — sheet 'Saoke_GIAINGAN', SNAPSHOT theo ETL_DATE (sao kê giải ngân, giữ tên cột nguồn).
    SOURCE_SAOKE_CRB (APP_CODE LD/PD, TXN_DATE = ngày nghiệp vụ)
      LEFT JOIN SMY_STMT_DAILY (OUR_REFERENCE, TRANSACTION_CODE '402', BOOKING_DATE = ngày nghiệp vụ)
      LEFT JOIN SOURCE_SAOKE_MVMT (TRANS_REF, TXN_DATE = ngày nghiệp vụ)
      LEFT JOIN CUSTOMER (CUS_ID), COMPANY (CO_CODE); mọi bảng lọc ETL_DATE.
    Ngày nghiệp vụ = biz_date() (mặc định = etl_date; Bronze chỉ có TXN_DATE 2025-10-07).
    Khác Excel: SAOKE_MVMT lặp TRANS_REF (391 dòng / 38 mã) -> lấy 1 dòng / TRANS_REF (SBV_CODE nhỏ nhất) để không nhân dòng.
    Định dạng Bronze: ngày CRB/MVMT 'yyyy-MM-dd HH:mm:ss.SSS', SMY.TXN_DATE 'M/d/yyyy', DATE_TIME yyMMddHHmm.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH stmt AS (
    SELECT * FROM {{ ref('smy_stmt_daily') }}
    WHERE
        etl_date = {{ etl_date() }}
        AND TRIM(transaction_code) = '402'
        AND {{ t24_date('booking_date') }} = {{ biz_date() }}
),

mvmt AS (
    SELECT TRIM(m.trans_ref) AS trans_ref, MIN(TRIM(m.sbv_code)) AS sbv_code, MIN(m.txn_date) AS txn_date
    FROM {{ ref('source_saoke_mvmt') }} AS m
    WHERE
        m.etl_date = {{ etl_date() }}
        AND TRY_CAST(SUBSTR(TRIM(m.txn_date), 1, 10) AS DATE) = {{ biz_date() }}
    GROUP BY TRIM(m.trans_ref)
),

cus AS (
    SELECT *
    FROM {{ ref('t24core_customer') }}
    WHERE etl_date = {{ etl_date() }}
),

comp AS (
    SELECT *
    FROM {{ ref('t24core_company') }}
    WHERE etl_date = {{ etl_date() }}
)

SELECT
    CAST(TRIM(stmt.narrative) AS STRING) AS narrative,
    COALESCE(TRY_CAST(TRIM(stmt.orig_amount_lcy) AS DECIMAL(25, 5)), 0) AS orig_amount_lcy,
    CAST(TRIM(stmt.original_acct) AS STRING) AS original_acct,
    COALESCE(TRY_CAST(TRIM(stmt.original_amount) AS DECIMAL(25, 5)), 0) AS original_amount,
    CAST(TRIM(stmt.original_ccy) AS STRING) AS original_ccy,
    COALESCE(TRY_CAST(TRIM(stmt.original_exch_rate) AS DECIMAL(13, 7)), 0) AS original_exch_rate,
    CAST(TRIM(stmt.our_reference) AS STRING) AS our_reference,
    COALESCE(TRY_CAST(TRIM(stmt.outstanding_bal) AS DECIMAL(25, 5)), 0) AS outstanding_bal,
    CAST(TRIM(stmt.override) AS STRING) AS override,
    CAST(TRIM(stmt.process_forward) AS STRING) AS process_forward,
    {{ t24_date('stmt.processing_date') }} AS processing_date,
    CAST(TRIM(stmt.product_category) AS STRING) AS product_category,
    CAST(TRIM(stmt.recid) AS STRING) AS stmt_recid,
    CAST(TRIM(stmt.record_status) AS STRING) AS record_status,
    COALESCE(TRY_CAST(TRIM(stmt.repayment_amt) AS DECIMAL(25, 5)), 0) AS repayment_amt,
    {{ t24_date('stmt.repayment_date') }} AS repayment_date,
    CAST(TRIM(stmt.repayment_type) AS STRING) AS repayment_type,
    CAST(TRIM(stmt.stmt_entry_id) AS STRING) AS stmt_entry_id,
    CAST(TRIM(stmt.stmt_no) AS STRING) AS stmt_no,
    CAST(TRIM(stmt.suspense_category) AS STRING) AS suspense_category,
    {{ t24_date('stmt.suspnse_value_date') }} AS suspnse_value_date,
    CAST(TRIM(stmt.system_id) AS STRING) AS system_id,
    CAST(TRIM(stmt.their_reference) AS STRING) AS their_reference,
    CAST(TRIM(stmt.trans_reference) AS STRING) AS trans_reference,
    CAST(TRIM(stmt.transaction_code) AS STRING) AS transaction_code,
    CAST(try_to_timestamp(TRIM(stmt.txn_date), 'M/d/yyyy') AS DATE) AS stmt_txn_date,
    {{ t24_date('stmt.value_date') }} AS value_date,
    CAST(TRIM(crb.acc_fcc) AS STRING) AS acc_fcc,
    COALESCE(TRY_CAST(TRIM(crb.amount_cur) AS DECIMAL(25, 5)), 0) AS amount_cur,
    COALESCE(TRY_CAST(TRIM(crb.amount_lcy) AS DECIMAL(25, 5)), 0) AS amount_lcy,
    CAST(TRIM(crb.app_code) AS STRING) AS app_code,
    CAST(TRIM(crb.app_id) AS STRING) AS app_id,
    CAST(TRIM(cus.asset_class) AS STRING) AS asset_class,
    CAST(TRIM(crb.asset_type) AS STRING) AS asset_type,
    CAST(TRIM(crb.categ_code) AS STRING) AS categ_code,
    CAST(TRIM(crb.co_code) AS STRING) AS co_code,
    CAST(TRIM(crb.curr) AS STRING) AS curr,
    CAST(TRIM(crb.cus_id) AS STRING) AS cus_id,
    TRY_CAST(SUBSTR(TRIM(crb.`date`), 1, 10) AS DATE) AS `date`,
    CAST(TRIM(crb.loc_term) AS STRING) AS loc_term,
    TRY_CAST(SUBSTR(TRIM(crb.mat_date), 1, 10) AS DATE) AS mat_date,
    CAST(TRIM(crb.sbv_code) AS STRING) AS sbv_code,
    CAST(TRIM(crb.sub_pro) AS STRING) AS sub_pro,
    TRY_CAST(SUBSTR(TRIM(crb.txn_date), 1, 10) AS DATE) AS txn_date,
    TRY_CAST(SUBSTR(TRIM(crb.val_date), 1, 10) AS DATE) AS val_date,
    CAST(TRIM(mvmt.sbv_code) AS STRING) AS mvmt_sbv_code,
    CAST(TRIM(mvmt.trans_ref) AS STRING) AS trans_ref,
    TRY_CAST(SUBSTR(TRIM(mvmt.txn_date), 1, 10) AS DATE) AS mvmt_txn_date,
    CAST(TRIM(comp.company_name) AS STRING) AS company_name,
    CAST(TRIM(comp.recid) AS STRING) AS comp_recid,
    CAST(TRIM(cus.account_officer) AS STRING) AS account_officer,
    CAST(TRIM(cus.active_status) AS STRING) AS active_status,
    CAST(TRIM(cus.aml_check) AS STRING) AS aml_check,
    CAST(TRIM(cus.aml_result) AS STRING) AS aml_result,
    {{ t24_date('cus.bdate_legal') }} AS bdate_legal,
    {{ t24_date('cus.bday_director') }} AS bday_director,
    {{ t24_date('cus.birth_incorp_date') }} AS birth_incorp_date,
    CAST(TRIM(cus.co_code) AS STRING) AS cus_co_code,
    CAST(TRIM(cus.company_book) AS STRING) AS company_book,
    {{ t24_date('cus.contact_date') }} AS contact_date,
    CAST(TRIM(cus.contact_person) AS STRING) AS contact_person,
    CAST(TRIM(cus.country) AS STRING) AS country,
    {{ t24_date('cus.cu_eff_date') }} AS cu_eff_date,
    CAST(TRIM(cus.cus_ind_parent) AS STRING) AS cus_ind_parent,
    CAST(TRIM(cus.customer_status) AS STRING) AS customer_status,
    CAST({{ t24_datetime('cus.date_time') }} AS DATE) AS date_time,
    CAST(TRIM(cus.email_address) AS STRING) AS email_address,
    CAST(TRIM(cus.employment_status) AS STRING) AS employment_status,
    CAST(TRIM(cus.estab_lic_code) AS STRING) AS estab_lic_code,
    CAST(TRIM(cus.ffb_type) AS STRING) AS ffb_type,
    CAST(TRIM(cus.gen_dir_plc) AS STRING) AS gen_dir_plc,
    CAST(TRIM(cus.home_number) AS STRING) AS home_number,
    CAST(TRIM(cus.industry) AS STRING) AS industry,
    {{ etl_date() }} AS etl_date
FROM {{ ref('source_saoke_crb') }} AS crb
LEFT JOIN stmt ON TRIM(stmt.our_reference) = TRIM(crb.app_id)
LEFT JOIN mvmt ON mvmt.trans_ref = TRIM(crb.app_id)
LEFT JOIN cus ON TRIM(cus.recid) = TRIM(crb.cus_id)
LEFT JOIN comp ON TRIM(comp.recid) = TRIM(crb.co_code)
WHERE
    crb.etl_date = {{ etl_date() }}
    AND TRIM(crb.app_code) IN ('LD', 'PD')
    AND TRY_CAST(SUBSTR(TRIM(crb.txn_date), 1, 10) AS DATE) = {{ biz_date() }}
