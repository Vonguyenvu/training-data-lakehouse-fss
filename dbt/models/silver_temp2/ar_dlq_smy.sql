{#-
    PG_SILVER.AR_DLQ_SMY — sheet 'Arrangement Delinquency Summary', SNAPSHOT theo ETL_DATE.
    T24CORE_PD_PAYMENT_DUE_HIS_MV: mỗi (RECID, PAY_TYPE) lấy dòng DATE_TIME lớn nhất VÀ CURR_NO lớn nhất
    (2 subquery MAX của Excel -> window, tính trên toàn bộ dòng trước khi lọc như Excel), lọc LIVE / PR,IN / ...,
    GROUP BY SUBSTR(RECID,1,14). LEFT JOIN PD_PAYMENT_DUE lấy MAX(SNQH_CHUYENDOI).
    Khác Excel: join b theo SUBSTR(a.RECID,1,14) = b.RECID — RECID HIS_MV có hậu tố ';n' ('PDPD2524402874;1')
    nên a.RECID = b.RECID không bao giờ khớp.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH his AS (
    SELECT
        SUBSTR(TRIM(a.recid), 1, 14) AS ar_code,
        TRIM(a.pay_type) AS pay_type,
        {{ t24_code('a.category') }} AS category,
        {{ t24_date('a.payment_dte_due') }} AS payment_dte_due,
        TRY_CAST(TRIM(a.pay_amt_outs) AS DECIMAL(25, 5)) AS pay_amt_outs,
        TRIM(a.flag_status) AS flag_status,
        NULLIF(TRIM(a.pd_type), '') AS pd_type,
        NULLIF(TRIM(a.record_status), '') AS record_status,
        {{ t24_datetime('a.date_time') }} AS date_time,
        TRY_CAST(TRIM(a.curr_no) AS INTEGER) AS curr_no,
        MAX({{ t24_datetime('a.date_time') }}) OVER w AS max_date_time,
        MAX(TRY_CAST(TRIM(a.curr_no) AS INTEGER)) OVER w AS max_curr_no
    FROM {{ ref('t24core_pd_payment_due_his_mv') }} AS a
    WHERE a.etl_date = {{ etl_date() }}
    WINDOW w AS (PARTITION BY TRIM(a.recid), TRIM(a.pay_type))
),

pd AS (
    SELECT TRIM(b.recid) AS recid, MAX(TRY_CAST(TRIM(b.snqh_chuyendoi) AS DECIMAL(22, 0))) AS snqh_chuyendoi
    FROM {{ ref('t24core_pd_payment_due') }} AS b
    WHERE b.etl_date = {{ etl_date() }}
    GROUP BY TRIM(b.recid)
),

agg AS (
    SELECT
        a.ar_code,
        MIN(CASE WHEN a.pay_type = 'PR' AND a.category <> '21069' THEN a.payment_dte_due END) AS pnp_past_due_dt,
        MIN(CASE
            WHEN a.pay_type = 'IN' OR (a.category = '21069' AND a.pay_type = 'PR')
                THEN a.payment_dte_due
        END) AS int_past_due_dt,
        SUM(CASE WHEN a.pay_type = 'PR' AND a.category <> '21069' THEN a.pay_amt_outs ELSE 0 END) AS pnp_ars,
        SUM(CASE
            WHEN a.pay_type = 'IN' OR (a.category = '21069' AND a.pay_type = 'PR')
                THEN a.pay_amt_outs
            ELSE 0
        END) AS int_ars,
        MAX(pd.snqh_chuyendoi) AS addition_dys_in_ars
    FROM his AS a
    LEFT JOIN pd ON pd.recid = a.ar_code
    WHERE
        a.flag_status = 'LIVE'
        AND a.pay_type IN ('PR', 'IN')
        AND COALESCE(a.pd_type, '0') <> '1'
        AND a.record_status IS NULL
        AND a.pay_amt_outs > 0
        AND a.date_time = a.max_date_time
        AND a.curr_no = a.max_curr_no
    GROUP BY a.ar_code
)

SELECT
    {{ etl_date() }} AS cdr_dt,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'ar_code') }} AS STRING) AS ar_id,
    CAST(ar_code AS STRING) AS ar_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS',
         "CASE WHEN ar_code LIKE 'PDLD%' THEN SUBSTR(ar_code, 3, 12) ELSE ar_code END") }} AS STRING) AS orig_ar_id,
    CAST(CASE WHEN ar_code LIKE 'PDLD%' THEN SUBSTR(ar_code, 3, 12) ELSE ar_code END AS STRING) AS orig_ar_code,
    CAST('T24_PD_PAYMENT_DUE_HIS_MV' AS STRING) AS src_stm_code,
    pnp_past_due_dt,
    int_past_due_dt,
    CAST(pnp_ars AS DECIMAL(25, 5)) AS pnp_ars,
    CAST(int_ars AS DECIMAL(25, 5)) AS int_ars,
    CAST(addition_dys_in_ars AS DECIMAL(22, 0)) AS addition_dys_in_ars,
    {{ etl_date() }} AS etl_date
FROM agg
