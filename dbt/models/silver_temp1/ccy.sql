{#-
    PG_SILVER.CCY — sheet 'Currency', SCD TYPE 1 (khuôn chuẩn cho SCD1).
    Khóa T24 của bảng CURRENCY là CURRENCY_CODE.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi ID biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='ccy_id',
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        {{ fn_hash('T24_CURRENCY', 'cur.currency_code') }} AS ccy_id,
        TRIM(cur.currency_code)                            AS ccy_code,
        TRIM(cur.ccy_name)                                 AS ccy_nm,
        TRIM(cur.numeric_ccy_code)                         AS numeric_ccy_code
    FROM {{ ref('t24core_currency') }} AS cur
    WHERE cur.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(cur.currency_code), '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.ccy_id, s.ccy_code, s.ccy_nm, s.numeric_ccy_code,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.ccy_id = t.ccy_id
    WHERE t.ccy_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.ccy_nm IS DISTINCT FROM t.ccy_nm
       OR s.numeric_ccy_code IS DISTINCT FROM t.numeric_ccy_code
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.ccy_id, t.ccy_code, t.ccy_nm, t.numeric_ccy_code,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.ccy_id = t.ccy_id
    WHERE s.ccy_id IS NULL
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
        ccy_id, ccy_code, ccy_nm, numeric_ccy_code,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(ccy_id AS STRING)           AS ccy_id,
    CAST(ccy_code AS STRING)         AS ccy_code,
    CAST(ccy_nm AS STRING)           AS ccy_nm,
    CAST(numeric_ccy_code AS STRING) AS numeric_ccy_code,
    CAST('T24_CURRENCY' AS STRING)   AS src_stm_code,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}                  AS sys_udt_dt,
    {{ etl_date() }}                  AS etl_date
FROM final
