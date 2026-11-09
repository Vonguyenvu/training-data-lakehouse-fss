{#-
    PG_SILVER.IP_ELC_ADR — sheet 'Involved Party Electronic Addre', SCD TYPE 2.
    3 nhánh UNION ALL từ T24CORE_CUSTOMER: EMAIL_ADDRESS / HOME_NUMBER / MOBILE_NUMBER (mỗi nhánh lọc NOT NULL).
    Khóa tự nhiên (CST_ID, ELC_ADR_TP); thay đổi ELC_ADR_VAL -> đóng dòng cũ, mở phiên bản mới.
    Lệch Oracle (2026-10-29): CUSTOMER chỉ có MOBILE_NUMBER, EMAIL_ADDRESS/HOME_NUMBER là NULL ở Bronze
    -> hiện chỉ nhánh MOBILE_NUMBER có dữ liệu.

    SCD2 trên dbt merge: unique_key = khóa tự nhiên + sys_eff_dt, nên MERGE
      - UPDATE dòng đang mở cần đóng (khớp sys_eff_dt cũ) -> sys_exp_dt = ETL_DATE,
      - INSERT phiên bản mới (sys_eff_dt = ETL_DATE chưa tồn tại).
    Dòng không đổi không có trong final -> không bị đụng. Key xuất hiện lại sau khi bị đóng -> mở dòng mới.
    Phải chạy ETL_DATE tăng dần; backfill ngày cũ sau ngày mới làm sai lịch sử.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['cst_id', 'elc_adr_tp', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH cus AS (
    SELECT c.*
    FROM {{ ref('t24core_customer') }} AS c
    WHERE
        c.etl_date = {{ etl_date() }}
        AND NULLIF(TRIM(c.recid), '') IS NOT NULL
),

src AS (
    SELECT
        {{ fn_hash('T24_CUSTOMER', 'recid') }} AS cst_id, TRIM(recid) AS cst_code,
        'EMAIL' AS elc_adr_tp, TRIM(email_address) AS elc_adr_val
    FROM cus
    WHERE NULLIF(TRIM(email_address), '') IS NOT NULL
    UNION ALL
    SELECT
        {{ fn_hash('T24_CUSTOMER', 'recid') }}, TRIM(recid),
        'HOME_NUMBER', TRIM(home_number)
    FROM cus
    WHERE NULLIF(TRIM(home_number), '') IS NOT NULL
    UNION ALL
    SELECT
        {{ fn_hash('T24_CUSTOMER', 'recid') }}, TRIM(recid),
        'MOBILE_NUMBER', TRIM(mobile_number)
    FROM cus
    WHERE NULLIF(TRIM(mobile_number), '') IS NOT NULL
),

{% if is_incremental() %}
cur AS (
    SELECT *
    FROM {{ this }}
    WHERE sys_exp_dt IS NULL
),

new_ver AS (
    -- Key mới, key xuất hiện lại (không còn dòng mở) hoặc giá trị đổi.
    SELECT
        s.cst_id, s.cst_code, s.elc_adr_tp, s.elc_adr_val,
        {{ etl_date() }} AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN cur AS c ON c.cst_id = s.cst_id AND c.elc_adr_tp = s.elc_adr_tp
    WHERE
        c.cst_id IS NULL
        OR s.elc_adr_val IS DISTINCT FROM c.elc_adr_val
),

closed AS (
    -- Đóng dòng đang mở khi giá trị đổi, hoặc key biến mất (chỉ khi partition nguồn có dữ liệu).
    -- sys_eff_dt = ETL_DATE (chạy lại cùng ngày) không đóng: new_ver ghi đè chính dòng đó.
    SELECT
        c.cst_id, c.cst_code, c.elc_adr_tp, c.elc_adr_val,
        c.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM cur AS c
    LEFT JOIN src AS s ON s.cst_id = c.cst_id AND s.elc_adr_tp = c.elc_adr_tp
    WHERE
        c.sys_eff_dt < {{ etl_date() }}
        AND (
            (s.cst_id IS NULL AND EXISTS (SELECT 1 FROM cus))
            OR (s.cst_id IS NOT NULL AND (   -- chỉ so giá trị khi key còn ở nguồn (nguồn rỗng không đóng dòng)
                s.elc_adr_val IS DISTINCT FROM c.elc_adr_val
            ))
        )
),

final AS (
    SELECT * FROM new_ver
    UNION ALL
    SELECT * FROM closed
)
{% else %}
final AS (
    SELECT
        src.*,
        {{ etl_date() }} AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(cst_id AS STRING) AS cst_id,
    CAST(cst_code AS STRING) AS cst_code,
    CAST(elc_adr_tp AS STRING) AS elc_adr_tp,
    CAST(elc_adr_val AS STRING) AS elc_adr_val,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }} AS sys_udt_dt,
    {{ etl_date() }} AS etl_date
FROM final
