{#-
    PG_SILVER.AST_AR_INT_SMY — sheet 'Asset Arrangement Interest Summ', SNAPSHOT theo ETL_DATE.
    SOURCE_SAOKE_CRB (APP_CODE LD/PD, TXN_DATE = ngày nghiệp vụ) GROUP BY APP_ID
    LEFT JOIN tổng lãi đã trả từ T24CORE_STMT_ENTRY (BOOKING_DATE <= ngày nghiệp vụ) theo OUR_REFERENCE.
    Ngày nghiệp vụ = biz_date() (mặc định = etl_date; Bronze chỉ có TXN_DATE 2025-10-07).
    COMMIT_ACTION <> 'D' -> COALESCE (NULL ở ~20% dòng, Excel sẽ loại hết).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH paid AS (
    SELECT
        TRIM(b.our_reference) AS recid,
        SUM(CASE WHEN b.our_reference LIKE 'PDPD%' AND TRIM(b.transaction_code) IN ('751', '434')
                 THEN CASE WHEN TRIM(b.currency) = 'VND' THEN ABS(TRY_CAST(TRIM(b.amount_lcy) AS DECIMAL(32, 5)))
                           ELSE ABS(TRY_CAST(TRIM(b.amount_fcy) AS DECIMAL(32, 5))) END
                 ELSE 0 END)
      + SUM(CASE WHEN (b.our_reference LIKE 'PDLD%' OR b.our_reference LIKE 'LD%')
                  AND TRIM(b.crf_prod_cat) = '21069' AND TRIM(b.transaction_code) IN ('750', '420')
                 THEN CASE WHEN TRIM(b.currency) = 'VND' THEN ABS(TRY_CAST(TRIM(b.amount_lcy) AS DECIMAL(32, 5)))
                           ELSE ABS(TRY_CAST(TRIM(b.amount_fcy) AS DECIMAL(32, 5))) END
                 ELSE 0 END) AS sum_repaid_amt
    FROM {{ ref('t24core_stmt_entry') }} AS b
    WHERE b.etl_date = {{ etl_date() }}
      AND b.recid NOT LIKE 'F%'
      AND COALESCE(b.commit_action, '') <> 'D'
      AND {{ t24_date('b.booking_date') }} <= {{ biz_date() }}
      AND (b.our_reference LIKE 'LD%' OR b.our_reference LIKE 'PD%')
    GROUP BY TRIM(b.our_reference)
),

crb AS (
    SELECT
        TRIM(a.app_id) AS app_id,
        SUM(CASE WHEN a.sbv_code LIKE '394%' OR a.sbv_code LIKE '94%'
                 THEN ABS(COALESCE(TRY_CAST(TRIM(a.amount_cur) AS DECIMAL(32, 5)), 0)) ELSE 0 END) AS tot_acr_int_amt_fcy,
        SUM(CASE WHEN a.sbv_code LIKE '394%'
                 THEN ABS(COALESCE(TRY_CAST(TRIM(a.amount_cur) AS DECIMAL(32, 5)), 0)) ELSE 0 END) AS tot_int_due_amt_fcy,
        SUM(CASE WHEN a.sbv_code LIKE '94%'
                 THEN ABS(COALESCE(TRY_CAST(TRIM(a.amount_cur) AS DECIMAL(32, 5)), 0)) ELSE 0 END) AS tot_int_odue_amt_fcy
    FROM {{ ref('source_saoke_crb') }} AS a
    WHERE a.etl_date = {{ etl_date() }}
      AND TRIM(a.app_code) IN ('LD', 'PD')
      AND TRY_CAST(SUBSTR(TRIM(a.txn_date), 1, 10) AS DATE) = {{ biz_date() }}
      AND NULLIF(TRIM(a.app_id), '') IS NOT NULL
    GROUP BY TRIM(a.app_id)
)

SELECT
    {{ etl_date() }}                                                              AS cdr_dt,
    CAST('SAOKE_CRB' AS STRING)                                                   AS src_stm_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'crb.app_id') }} AS STRING)      AS ar_id,
    CAST(crb.app_id AS STRING)                                                    AS ar_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS',
         "CASE WHEN crb.app_id LIKE 'PDLD%' THEN SUBSTR(crb.app_id, 3, 12) ELSE crb.app_id END") }} AS STRING) AS orig_ar_id,
    CAST(CASE WHEN crb.app_id LIKE 'PDLD%' THEN SUBSTR(crb.app_id, 3, 12) ELSE crb.app_id END AS STRING) AS orig_ar_code,
    CAST(crb.tot_acr_int_amt_fcy AS DECIMAL(32, 5))                               AS tot_acr_int_amt_fcy,
    CAST(COALESCE(paid.sum_repaid_amt, 0) AS DECIMAL(32, 5))                      AS tot_int_paid_amt_fcy,
    CAST(crb.tot_int_due_amt_fcy AS DECIMAL(32, 5))                               AS tot_int_due_amt_fcy,
    CAST(crb.tot_int_odue_amt_fcy AS DECIMAL(32, 5))                              AS tot_int_odue_amt_fcy,
    {{ etl_date() }}                                                              AS etl_date
FROM crb
LEFT JOIN paid ON paid.recid = crb.app_id
