{#-
    PG_SILVER.LMT — sheet 'Limit', SCD TYPE 1.
    Khóa T24 của bảng LIMIT là RECID. Oracle nguồn chưa có LIMIT_PRODUCT, INTERNAL_AMOUNT, MAXIMUM_TOTAL,
    ONLINE_LIMIT_DATE, EXPIRY_DATE nên Bronze nạp NULL; các cột này sẽ có giá trị khi nguồn bổ sung.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi RECID biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='lmt_id',
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        {{ fn_hash('T24_LIMIT', 'l.recid') }}                AS lmt_id,
        TRIM(l.recid)                                         AS lmt_code,
        TRIM(l.limit_product)                                 AS lmt_dsc,
        TRY_CAST(TRIM(l.internal_amount) AS DECIMAL(25, 5))   AS inr_lmt_amt,
        TRY_CAST(TRIM(l.maximum_total) AS DECIMAL(25, 5))     AS max_tot_lmt,
        {{ t24_date('l.online_limit_date') }}                 AS onl_lmt_dt,
        {{ t24_date('l.expiry_date') }}                       AS lmt_exp_dt
    FROM {{ source('pg_bronze', 't24core_limit') }} AS l
    WHERE l.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(l.recid), '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.lmt_id, s.lmt_code, s.lmt_dsc, s.inr_lmt_amt, s.max_tot_lmt, s.onl_lmt_dt, s.lmt_exp_dt,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.lmt_id = t.lmt_id
    WHERE t.lmt_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.lmt_dsc IS DISTINCT FROM t.lmt_dsc
       OR s.inr_lmt_amt IS DISTINCT FROM t.inr_lmt_amt
       OR s.max_tot_lmt IS DISTINCT FROM t.max_tot_lmt
       OR s.onl_lmt_dt IS DISTINCT FROM t.onl_lmt_dt
       OR s.lmt_exp_dt IS DISTINCT FROM t.lmt_exp_dt
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.lmt_id, t.lmt_code, t.lmt_dsc, t.inr_lmt_amt, t.max_tot_lmt, t.onl_lmt_dt, t.lmt_exp_dt,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.lmt_id = t.lmt_id
    WHERE s.lmt_id IS NULL
      AND t.sys_exp_dt IS NULL
      AND EXISTS (SELECT 1 FROM src)
),

final AS (
    SELECT * FROM changed
    UNION ALL
    SELECT * FROM deleted
)
{% else %}
final AS (
    SELECT
        lmt_id, lmt_code, lmt_dsc, inr_lmt_amt, max_tot_lmt, onl_lmt_dt, lmt_exp_dt,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(lmt_id AS VARCHAR)              AS lmt_id,
    CAST(lmt_code AS VARCHAR)            AS lmt_code,
    CAST(lmt_dsc AS VARCHAR)             AS lmt_dsc,
    CAST(inr_lmt_amt AS DECIMAL(25, 5))  AS inr_lmt_amt,
    CAST(max_tot_lmt AS DECIMAL(25, 5))  AS max_tot_lmt,
    CAST(onl_lmt_dt AS DATE)             AS onl_lmt_dt,
    CAST(lmt_exp_dt AS DATE)             AS lmt_exp_dt,
    CAST('T24_LIMIT' AS VARCHAR)         AS src_stm_code,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}                     AS sys_udt_dt,
    {{ etl_date() }}                     AS etl_date
FROM final
