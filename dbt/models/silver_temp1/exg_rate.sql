{#-
    PG_SILVER.EXG_RATE — sheet 'Exchange Rate', SNAPSHOT theo ETL_DATE.
    Theo 3 khối trong sheet: tỷ giá hiện hành (CURRENCY, curr_no = 999999) và lịch sử (CURRENCY_HIS)
    có DATE_TIME trước ngày batch; mỗi loại tiền lấy bản mới nhất, ưu tiên curr_no lớn nhất.
    Trên PG_BRONZE: ID = CURRENCY_CODE ('USD', lịch sử dạng 'USD;123'), MID_REVAL_RATE có thể đa giá trị '#'.
    Chạy lại cùng ngày sẽ thay thế partition ETL_DATE đó (insert_overwrite).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH cur AS (
    SELECT
        TRIM(cur.currency_code)                                                     AS frst_ccy_code,
        'VND'                                                                       AS scd_ccy_code,
        COALESCE(TRY_CAST({{ t24_multi_value('cur.mid_reval_rate') }} AS DECIMAL(13, 7)), 1) AS mid_reval_rate,
        {{ t24_datetime('cur.date_time') }}                                         AS date_time_value,
        999999                                                                      AS curr_no,
        RANK() OVER (
            PARTITION BY TRIM(cur.currency_code)
            ORDER BY {{ t24_datetime('cur.date_time') }} DESC
        )                                                                           AS rn
    FROM {{ ref('t24core_currency') }} AS cur
    WHERE cur.etl_date = {{ etl_date() }}
      AND {{ t24_datetime('cur.date_time') }} < {{ etl_date() }} + INTERVAL '1' DAY
),

cur_his AS (
    SELECT
        SPLIT_PART(ch.currency_code, ';', 1)                                        AS frst_ccy_code,
        'VND'                                                                       AS scd_ccy_code,
        COALESCE(TRY_CAST({{ t24_multi_value('ch.mid_reval_rate') }} AS DECIMAL(13, 7)), 1) AS mid_reval_rate,
        {{ t24_datetime('ch.date_time') }}                                          AS date_time_value,
        TRY_CAST(ch.curr_no AS INTEGER)                                             AS curr_no,
        RANK() OVER (
            PARTITION BY SPLIT_PART(ch.currency_code, ';', 1)
            ORDER BY {{ t24_datetime('ch.date_time') }} DESC
        )                                                                           AS rn
    FROM {{ ref('t24core_currency_his') }} AS ch
    WHERE ch.etl_date = {{ etl_date() }}
      AND {{ t24_datetime('ch.date_time') }} < {{ etl_date() }} + INTERVAL '1' DAY
),

cur_main AS (
    SELECT
        frst_ccy_code, scd_ccy_code, mid_reval_rate, date_time_value,
        RANK() OVER (PARTITION BY frst_ccy_code ORDER BY curr_no DESC) AS rnk
    FROM (
        SELECT * FROM cur WHERE rn = 1
        UNION ALL
        SELECT * FROM cur_his WHERE rn = 1
    )
)

SELECT
    {{ etl_date() }}                          AS snpst_dt,
    CAST('T24_CURRENCY' AS STRING)           AS src_stm_code,
    CAST(frst_ccy_code AS STRING)            AS frst_ccy_code,
    CAST(scd_ccy_code AS STRING)             AS scd_ccy_code,
    CAST(mid_reval_rate AS DECIMAL(25, 7))    AS mid_rate,
    {{ etl_date() }}                          AS etl_date
FROM cur_main
WHERE rnk = 1
