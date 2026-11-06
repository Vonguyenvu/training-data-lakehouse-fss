{#-
    PG_SILVER.AR_AVY_SHD_ITM — sheet 'Arrangement Activity Schedule I', SCD TYPE 2 (macro scd2).
    T24CORE_STMT_ENTRY bút toán kế hoạch (RECID LIKE 'F%', COMMIT_ACTION <> 'D', BOOKING_DATE = ngày nghiệp vụ)
      LEFT JOIN LD (RECID = contract_id, DATE_TIME <= ngày nghiệp vụ)
      LEFT JOIN pdp = PD_PAYMENT_DUE_MV có PAYMENT_DTE_DUE = MAX(PREV_SCHED_DATE <= ngày nghiệp vụ) của LD_SCHEDULE_DEFINE_MV.
    Khóa tự nhiên AR_AVY_SHD_ID = fn_hash('T24_LD_LOANS_AND_DEPOSITS', stmt.RECID) (theo sheet).
    Khác Excel:
      - Nguồn chỉ là bút toán của 1 ngày -> close_missing=false: bút toán ngày trước không bị đóng vì vắng mặt.
      - pdp lấy 1 dòng / CONTRACT_ID (PD_MV không có khóa duy nhất); subquery MAX -> ROW_NUMBER.
      - COMMIT_ACTION <> 'D' -> COALESCE; CATEGORY so sánh sau t24_code.
    Ngày nghiệp vụ = biz_date() (mặc định = etl_date). Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ar_avy_shd_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH stmt AS (
    SELECT
        s.*,
        CASE WHEN s.our_reference LIKE 'LD%' THEN TRIM(s.our_reference)
             WHEN s.our_reference LIKE 'PD%' THEN SUBSTR(TRIM(s.our_reference), 3) END AS contract_id
    FROM {{ ref('t24core_stmt_entry') }} AS s
    WHERE s.etl_date = {{ etl_date() }}
      AND s.recid LIKE 'F%'
      AND COALESCE(s.commit_action, '') <> 'D'
      AND {{ t24_date('s.booking_date') }} = {{ biz_date() }}
),

ld AS (
    SELECT TRIM(l.recid) AS recid, {{ t24_code('l.category') }} AS category
    FROM {{ ref('t24core_ld_loans_and_deposits') }} AS l
    WHERE l.etl_date = {{ etl_date() }}
      AND CAST({{ t24_datetime('l.date_time') }} AS DATE) <= {{ biz_date() }}
),

sch AS (
    SELECT TRIM(d.contract_id) AS contract_id, MAX({{ t24_date('d.prev_sched_date') }}) AS last_sched_dt
    FROM {{ ref('t24core_ld_schedule_define_mv') }} AS d
    WHERE d.etl_date = {{ etl_date() }}
      AND {{ t24_date('d.prev_sched_date') }} <= {{ biz_date() }}
    GROUP BY TRIM(d.contract_id)
),

pdp AS (
    SELECT contract_id, payment_dte_due, category
    FROM (
        SELECT SUBSTR(TRIM(p.recid), 3)              AS contract_id,
               {{ t24_date('p.payment_dte_due') }}    AS payment_dte_due,
               {{ t24_code('p.category') }}           AS category,
               ROW_NUMBER() OVER (PARTITION BY SUBSTR(TRIM(p.recid), 3) ORDER BY {{ t24_datetime('p.date_time') }} DESC) AS rn
        FROM {{ ref('t24core_pd_payment_due_mv') }} AS p
        JOIN sch ON sch.contract_id = SUBSTR(TRIM(p.recid), 3)
                AND sch.last_sched_dt = {{ t24_date('p.payment_dte_due') }}
        WHERE p.etl_date = {{ etl_date() }}
          AND COALESCE(p.flag_status, '') <> 'DELETE'
    )
    WHERE rn = 1
),

src AS (
    SELECT
        CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'stmt.recid') }} AS STRING)             AS ar_avy_shd_id,
        CAST(TRIM(stmt.recid) AS STRING)                                                     AS ar_avy_shd_code,
        CAST('LOAN_PD_SHD' AS STRING)                                                        AS ar_avy_shd_tp,
        CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'stmt.contract_id') }} AS STRING)       AS ar_id,
        CAST(stmt.contract_id AS STRING)                                                     AS ar_code,
        CAST(CASE
            WHEN stmt.transaction_code = '402' THEN 'LD_GN'
            WHEN stmt.transaction_code IN ('420', '423')
                 AND COALESCE(ld.category, pdp.category, {{ t24_code('stmt.crf_prod_cat') }}, '_') <> '21069' THEN 'LD_PR'
            WHEN stmt.transaction_code IN ('434', '424')
                 OR (stmt.transaction_code IN ('420', '423')
                     AND COALESCE(ld.category, pdp.category, {{ t24_code('stmt.crf_prod_cat') }}) = '21069') THEN 'LD_IN'
            WHEN stmt.transaction_code = '750' THEN 'PD_PR'
            WHEN stmt.transaction_code = '751' THEN 'PD_IN'
            WHEN stmt.transaction_code = '752' THEN 'PD_PE'
            WHEN stmt.transaction_code = '753' THEN 'PD_PS'
        END AS STRING)                                                                       AS pbl_amt_tp,
        CAST(ABS(COALESCE(TRY_CAST(TRIM(stmt.amount_lcy) AS DECIMAL(25, 5)), 0)) AS DECIMAL(25, 5)) AS pbl_amt_lcy,
        CAST(ABS(COALESCE(TRY_CAST(TRIM(stmt.amount_fcy) AS DECIMAL(25, 5)), 0)) AS DECIMAL(25, 5)) AS pbl_amt_fcy,
        TRY_CAST(TRIM(stmt.exchange_rate) AS DECIMAL(25, 7))                                 AS exg_rate,
        CAST(TRIM(stmt.currency) AS STRING)                                                  AS ccy_code,
        {{ t24_date('stmt.value_date') }}                                                    AS eff_mat_dt,
        CAST(CASE WHEN pdp.contract_id IS NOT NULL THEN 1 ELSE 0 END AS DECIMAL(1, 0))       AS f_last_od_dt,
        pdp.payment_dte_due                                                                  AS last_od_dt,
        CAST('T24CORE_STMT_ENTRY' AS STRING)                                                 AS src_stm_code,
        CAST({{ fn_hash('T24_CUSTOMER', 'stmt.customer_id') }} AS STRING)                    AS cst_id,
        CAST(TRIM(stmt.customer_id) AS STRING)                                               AS cst_code
    FROM stmt
    LEFT JOIN ld  ON ld.recid = stmt.contract_id
    LEFT JOIN pdp ON pdp.contract_id = stmt.contract_id
)
{{ scd2(['ar_avy_shd_id'], close_missing=false) }}
