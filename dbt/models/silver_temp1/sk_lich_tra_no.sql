{#-
    PG_SILVER.SK_LICH_TRA_NO — sheet 'sk_lich_tra_no', SNAPSHOT theo ETL_DATE (khuôn: exg_rate.sql).
    Bảng chính T24CORE_PD_PAYMENT_DUE_MV (FLAG_STATUS <> 'DELETE'), LEFT JOIN 10 bảng LD / PD / STMT / SECTOR.
    Grain (đã thống nhất, Excel không ghi): 1 dòng / dòng pdmv x bút toán STMT_ENTRY cùng hợp đồng trong ngày.
    Bảng phụ nhiều dòng / khóa được gom về 1 dòng trước khi join (Excel join thẳng -> nhân dòng):
      pd, pdh, ldh: CURR_NO lớn nhất; pdhmv: CURR_NO lớn nhất / (RECID, PAY_TYPE);
      sch: PREV_SCHED_DATE mới nhất <= ngày nghiệp vụ; mg: 1 dòng / LD_ID.
    Mọi bảng nguồn lọc ETL_DATE (Excel thiếu ở pdhmv, sch). Ngày nghiệp vụ (PREV_SCHED_DATE, BOOKING_DATE)
    = macro biz_date(), mặc định = etl_date; Bronze hiện có BOOKING_DATE / PREV_SCHED_DATE = 2025-10-07.
    Định dạng: DATE_TIME là yyMMddHHmm (Excel ghi YYYYMMDD) -> t24_datetime rồi lấy ngày; số dùng TRY_CAST.
    Lệch Oracle: PD_PAYMENT_DUE_HIS.RECID toàn NULL -> nhánh pdh không khớp; PD_PAYMENT_DUE.FLAG_STATUS NULL.
    Dữ liệu hiện tại (2026-11-03) không có dòng khớp cho pdhmv, mg -> các cột đó NULL/0.
    Chạy lại cùng ngày thay thế partition ETL_DATE đó (delete+insert).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='etl_date',
    properties={"partitioning": "ARRAY['etl_date']"},
    on_schema_change='fail'
) }}

WITH pdmv AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 't24core_pd_payment_due_mv') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND x.flag_status <> 'DELETE'
),

pd AS (
    SELECT * FROM (
        SELECT x.*, ROW_NUMBER() OVER (
                   PARTITION BY x.recid ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn
        FROM {{ source('pg_bronze', 't24core_pd_payment_due') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    ) WHERE rn = 1
),

pdhmv AS (
    SELECT * FROM (
        SELECT x.*, ROW_NUMBER() OVER (
                   PARTITION BY x.recid, x.pay_type ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn
        FROM {{ source('pg_bronze', 't24core_pd_payment_due_his_mv') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND x.flag_status = 'LIVE'
          AND TRY_CAST(TRIM(x.pay_amt_outs) AS DECIMAL(25, 5)) > 0
    ) WHERE rn = 1
),

pdh AS (
    SELECT * FROM (
        SELECT x.*, ROW_NUMBER() OVER (
                   PARTITION BY x.recid ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn
        FROM {{ source('pg_bronze', 't24core_pd_payment_due_his') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    ) WHERE rn = 1
),

sch AS (
    SELECT * FROM (
        SELECT x.*, ROW_NUMBER() OVER (
                   PARTITION BY x.contract_id ORDER BY {{ t24_date('x.prev_sched_date') }} DESC) AS rn
        FROM {{ source('pg_bronze', 't24core_ld_schedule_define_mv') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND {{ t24_date('x.prev_sched_date') }} <= {{ biz_date() }}
    ) WHERE rn = 1
),

ld AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 't24core_ld_loans_and_deposits') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

ldh AS (
    SELECT * FROM (
        SELECT x.*, SPLIT_PART(x.recid, ';', 1) AS contract_code,
               ROW_NUMBER() OVER (
                   PARTITION BY SPLIT_PART(x.recid, ';', 1) ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn
        FROM {{ source('pg_bronze', 't24core_ld_loans_and_deposits_his') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    ) WHERE rn = 1
),

mg AS (
    SELECT * FROM (
        SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.ld_id ORDER BY x.productgr_code) AS rn
        FROM {{ source('pg_bronze', 't24core_mb_mg_saving_multi') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    ) WHERE rn = 1
),

cus AS (
    -- Bronze: SECTOR là số Oracle dạng '1602.0000000000', SECTOR.RECID là '1602'.
    SELECT x.recid, CAST(TRY_CAST(TRIM(x.sector) AS DECIMAL(20, 0)) AS VARCHAR) AS sector
    FROM {{ source('pg_bronze', 't24core_customer') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

sec AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 't24core_sector') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

stmt AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 't24core_stmt_entry') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND {{ t24_date('x.booking_date') }} = {{ biz_date() }}
      AND COALESCE(x.commit_action, '') <> 'D'   -- Bronze: COMMIT_ACTION NULL ở nhiều dòng, không phải bản xóa
)

SELECT
    CAST(TRIM(ld.mb_rm_bancheo) AS VARCHAR)                          AS ld_mb_rm_bancheo,
    {{ t24_date('ld.orig_val_date') }}                               AS ld_orig_val_date,
    COALESCE(TRY_CAST(TRIM(ld.pe_rate) AS DECIMAL(13, 7)), 0)        AS ld_pe_rate,
    CAST(TRIM(ld.prin_liq_acct) AS VARCHAR)                          AS ld_prin_liq_acct,
    CAST(TRIM(ld.productgr_code) AS VARCHAR)                         AS ld_productgr_code,
    COALESCE(TRY_CAST(TRIM(ld.ps_rate) AS DECIMAL(13, 7)), 0)        AS ps_rate,
    COALESCE(TRY_CAST(TRIM(ld.real_rate) AS DECIMAL(13, 7)), 0)      AS ld_real_rate,
    CAST(TRIM(ld.recid) AS VARCHAR)                                  AS ld_recid,
    CAST(TRIM(ld.record_status) AS VARCHAR)                          AS ld_record_status,
    CAST(TRIM(ld.status) AS VARCHAR)                                 AS status,
    CAST(TRIM(ld.use_of_loan) AS VARCHAR)                            AS ld_use_of_loan,
    CAST(TRIM(ld.use_of_loan_cha) AS VARCHAR)                        AS ld_use_of_loan_cha,
    {{ t24_date('ld.value_date') }}                                  AS ld_value_date,
    CAST(TRIM(ldh.acc_fcc) AS VARCHAR)                               AS ldh_acc_fcc,
    COALESCE(TRY_CAST(TRIM(ldh.amount) AS DECIMAL(25, 5)), 0)        AS amount,
    COALESCE(TRY_CAST(TRIM(ldh.approve_amount) AS DECIMAL(25, 5)), 0) AS ldh_approve_amount,
    CAST(TRIM(ldh.category) AS VARCHAR)                              AS ldh_category,
    CAST(TRIM(ldh.co_code) AS VARCHAR)                               AS ldh_co_code,
    CAST(TRIM(ldh.commit_action) AS VARCHAR)                         AS ldh_commit_action,
    CAST(TRIM(ldh.cra_ld) AS VARCHAR)                                AS cra_ld,
    COALESCE(TRY_CAST(TRIM(ldh.curr_no) AS DECIMAL(10, 0)), 0)       AS ldh_curr_no,
    CAST(TRIM(ldh.currency) AS VARCHAR)                              AS ldh_currency,
    CAST(TRIM(ldh.customer_id) AS VARCHAR)                           AS customer_id,
    CAST({{ t24_datetime('ldh.date_time') }} AS DATE)                AS ldh_date_time,
    COALESCE(TRY_CAST(TRIM(ldh.drawdown_net_amt) AS DECIMAL(25, 5)), 0) AS drawdown_net_amt,
    COALESCE(TRY_CAST(TRIM(ldh.excg_rate) AS DECIMAL(13, 7)), 0)     AS excg_rate,
    {{ t24_date('ldh.fin_mat_date') }}                               AS fin_mat_date,
    CAST(TRIM(ldh.int_liq_acct) AS VARCHAR)                          AS int_liq_acct,
    CAST(TRIM(ldh.int_rate_type) AS VARCHAR)                         AS int_rate_type,
    {{ t24_date('ldh.int_value_date') }}                             AS int_value_date,
    COALESCE(TRY_CAST(TRIM(ldh.interest_rate) AS DECIMAL(13, 7)), 0) AS interest_rate,
    COALESCE(TRY_CAST(TRIM(ldh.interest_spread) AS DECIMAL(13, 7)), 0) AS interest_spread,
    CAST(TRIM(ldh.loc_term) AS VARCHAR)                              AS loc_term,
    CAST(TRIM(ldh.mb_rm_bancheo) AS VARCHAR)                         AS ldh_mb_rm_bancheo,
    {{ t24_date('ldh.orig_val_date') }}                              AS ldh_orig_val_date,
    CAST(TRIM(ldh.prin_liq_acct) AS VARCHAR)                         AS ldh_prin_liq_acct,
    COALESCE(TRY_CAST(TRIM(ldh.real_rate) AS DECIMAL(13, 7)), 0)     AS ldh_real_rate,
    CAST(TRIM(ldh.recid) AS VARCHAR)                                 AS ldh_recid,
    CAST(TRIM(ldh.record_status) AS VARCHAR)                         AS ldh_record_status,
    CAST(TRIM(ldh.use_of_loan) AS VARCHAR)                           AS ldh_use_of_loan,
    CAST(TRIM(ldh.use_of_loan_cha) AS VARCHAR)                       AS ldh_use_of_loan_cha,
    {{ t24_date('ldh.value_date') }}                                 AS ldh_value_date,
    CAST(TRIM(sch.contract_id) AS VARCHAR)                           AS contract_id,
    {{ t24_date('sch.prev_sched_date') }}                            AS prev_sched_date,
    CAST(TRIM(mg.ld_id) AS VARCHAR)                                  AS ld_id,
    CAST(TRIM(mg.productgr_code) AS VARCHAR)                         AS mg_productgr_code,
    CAST(TRIM(pd.authoriser) AS VARCHAR)                             AS authoriser,
    CAST(TRIM(pd.credit_status) AS VARCHAR)                          AS pd_credit_status,
    COALESCE(TRY_CAST(TRIM(pd.curr_no) AS DECIMAL(10, 0)), 0)        AS pd_curr_no,
    CAST(TRIM(pd.customer) AS VARCHAR)                               AS pd_customer,
    CAST(TRIM(pd.flag_status) AS VARCHAR)                            AS pd_flag_status,
    CAST(TRIM(pd.inputter) AS VARCHAR)                               AS inputter,
    CAST(TRIM(pd.los_fac_code) AS VARCHAR)                           AS los_fac_code,
    {{ t24_date('pd.original_mat') }}                                AS pd_original_mat,
    CAST(TRIM(pd.pd_type) AS VARCHAR)                                AS pd_pd_type,
    COALESCE(TRY_CAST(TRIM(pd.pe_rate) AS DECIMAL(13, 7)), 0)        AS pd_pe_rate,
    COALESCE(TRY_CAST(TRIM(pd.penalty_rate) AS DECIMAL(13, 7)), 0)   AS pd_penalty_rate,
    CAST(TRIM(pd.recid) AS VARCHAR)                                  AS pd_recid,
    COALESCE(TRY_CAST(TRIM(pd.snqh_chuyendoi) AS DECIMAL(10, 0)), 0) AS snqh_chuyendoi,
    CAST(TRIM(pd.use_of_loan) AS VARCHAR)                            AS pd_use_of_loan,
    CAST(TRIM(pd.use_of_loan_cha) AS VARCHAR)                        AS pd_use_of_loan_cha,
    COALESCE(TRY_CAST(TRIM(pdh.curr_no) AS DECIMAL(10, 0)), 0)       AS pdh_curr_no,
    CAST(TRIM(pdh.pd_type) AS VARCHAR)                               AS pdh_pd_type,
    CAST(TRIM(pdh.recid) AS VARCHAR)                                 AS pdh_recid,
    CAST(TRIM(pdhmv.acc_fcc) AS VARCHAR)                             AS pdhmv_acc_fcc,
    COALESCE(TRY_CAST(TRIM(pdhmv.approve_amount) AS DECIMAL(25, 5)), 0) AS pdhmv_approve_amount,
    CAST(TRIM(pdhmv.category) AS VARCHAR)                            AS pdhmv_category,
    CAST(TRIM(pdhmv.co_code) AS VARCHAR)                             AS pdhmv_co_code,
    CAST(TRIM(pdhmv.credit_status) AS VARCHAR)                       AS pdhmv_credit_status,
    COALESCE(TRY_CAST(TRIM(pdhmv.curr_no) AS DECIMAL(10, 0)), 0)     AS pdhmv_curr_no,
    CAST(TRIM(pdhmv.customer) AS VARCHAR)                            AS pdhmv_customer,
    CAST({{ t24_datetime('pdhmv.date_time') }} AS DATE)              AS pdhmv_date_time,
    {{ t24_date('pdhmv.final_due_date') }}                           AS pdhmv_final_due_date,
    CAST(TRIM(pdhmv.flag_status) AS VARCHAR)                         AS pdhmv_flag_status,
    {{ t24_date('pdhmv.original_mat') }}                             AS pdhmv_original_mat,
    CAST(TRIM(pdhmv.pay_type) AS VARCHAR)                            AS pdhmv_pay_type,
    CAST(TRIM(pdhmv.pd_type) AS VARCHAR)                             AS pdhmv_pd_type,
    COALESCE(TRY_CAST(TRIM(pdhmv.pe_rate) AS DECIMAL(13, 7)), 0)     AS pdhmv_pe_rate,
    COALESCE(TRY_CAST(TRIM(pdhmv.penalty_rate) AS DECIMAL(13, 7)), 0) AS pdhmv_penalty_rate,
    CAST(TRIM(pdhmv.recid) AS VARCHAR)                               AS pdhmv_recid,
    CAST(TRIM(pdhmv.record_status) AS VARCHAR)                       AS pdhmv_record_status,
    CAST(TRIM(pdhmv.repayment_acct) AS VARCHAR)                      AS pdhmv_repayment_acct,
    CAST(TRIM(pdmv.acc_fcc) AS VARCHAR)                              AS acc_fcc,
    COALESCE(TRY_CAST(TRIM(pdmv.approve_amount) AS DECIMAL(25, 5)), 0) AS approve_amount,
    CAST(TRIM(pdmv.category) AS VARCHAR)                             AS category,
    CAST(TRIM(pdmv.co_code) AS VARCHAR)                              AS co_code,
    CAST(TRIM(pdmv.commit_action) AS VARCHAR)                        AS commit_action,
    CAST(TRIM(pdmv.credit_status) AS VARCHAR)                        AS credit_status,
    COALESCE(TRY_CAST(TRIM(pdmv.curr_no) AS DECIMAL(10, 0)), 0)      AS curr_no,
    CAST(TRIM(pdmv.customer) AS VARCHAR)                             AS customer,
    CAST({{ t24_datetime('pdmv.date_time') }} AS DATE)               AS date_time,
    {{ t24_date('pdmv.final_due_date') }}                            AS final_due_date,
    CAST(TRIM(pdmv.flag_status) AS VARCHAR)                          AS flag_status,
    CAST(TRIM(pdmv.id) AS VARCHAR)                                   AS id,
    {{ t24_date('pdmv.original_mat') }}                              AS original_mat,
    COALESCE(TRY_CAST(TRIM(pdmv.pay_amt_outs) AS DECIMAL(25, 5)), 0) AS pay_amt_outs,
    CAST(TRIM(pdmv.pay_type) AS VARCHAR)                             AS pay_type,
    {{ t24_date('pdmv.payment_dte_due') }}                           AS payment_dte_due,
    CAST(TRIM(pdmv.pd_type) AS VARCHAR)                              AS pd_type,
    COALESCE(TRY_CAST(TRIM(pdmv.pe_rate) AS DECIMAL(13, 7)), 0)      AS pe_rate,
    COALESCE(TRY_CAST(TRIM(pdmv.penalty_rate) AS DECIMAL(13, 7)), 0) AS penalty_rate,
    CAST(TRIM(pdmv.recid) AS VARCHAR)                                AS recid,
    CAST(TRIM(pdmv.record_status) AS VARCHAR)                        AS record_status,
    COALESCE(TRY_CAST(TRIM(pdmv.repaid_amt) AS DECIMAL(25, 5)), 0)   AS repaid_amt,
    CAST(TRIM(pdmv.repayment_acct) AS VARCHAR)                       AS repayment_acct,
    CAST(TRIM(sec.customer_type) AS VARCHAR)                         AS customer_type,
    CAST(TRIM(sec.recid) AS VARCHAR)                                 AS sec_recid,
    COALESCE(TRY_CAST(TRIM(stmt.amount_fcy) AS DECIMAL(25, 5)), 0)   AS amount_fcy,
    COALESCE(TRY_CAST(TRIM(stmt.amount_lcy) AS DECIMAL(25, 5)), 0)   AS amount_lcy,
    {{ t24_date('stmt.booking_date') }}                              AS booking_date,
    CAST(TRIM(stmt.currency) AS VARCHAR)                             AS stmt_currency,
    CAST(TRIM(stmt.our_reference) AS VARCHAR)                        AS our_reference,
    CAST(TRIM(stmt.recid) AS VARCHAR)                                AS stmt_recid,
    CAST(TRIM(stmt.transaction_code) AS VARCHAR)                     AS transaction_code,
    {{ t24_date('stmt.value_date') }}                                AS stmt_value_date,
    {{ t24_date('pdhmv.payment_dte_due') }}                          AS pdhmv_payment_dte_due,
    COALESCE(TRY_CAST(TRIM(pdhmv.pay_amt_outs) AS DECIMAL(25, 5)), 0) AS pdhmv_pay_amt_outs,
    {{ etl_date() }}                                                 AS etl_date
FROM pdmv
LEFT JOIN pd    ON pd.recid = pdmv.recid
LEFT JOIN pdhmv ON pdhmv.recid = pdmv.recid AND pdhmv.pay_type = pdmv.pay_type
LEFT JOIN pdh   ON pdh.recid = pdmv.recid
LEFT JOIN sch   ON sch.contract_id = SUBSTR(pdmv.recid, 3)
LEFT JOIN ld    ON ld.recid = SUBSTR(pdmv.recid, 3, 12)
LEFT JOIN ldh   ON ldh.contract_code = SUBSTR(pdmv.recid, 3, 12)
LEFT JOIN mg    ON mg.ld_id = ld.recid
LEFT JOIN cus   ON cus.recid = COALESCE(pdmv.customer, pd.customer, ld.customer_id)
LEFT JOIN sec   ON sec.recid = cus.sector
LEFT JOIN stmt  ON SUBSTR(stmt.our_reference, 3) = SUBSTR(pdmv.recid, 3)
