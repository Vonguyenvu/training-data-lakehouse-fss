{#-
    PG_SILVER.IP_ALT_IDENTN — sheet 'Involved Party Alternative Iden', SCD TYPE 2 (khuôn: ip_elc_adr.sql).
    Nguồn T24CORE_CUSTOMER, lọc NATIONAL_ID NOT NULL. Khóa tự nhiên CST_ID (1 giấy tờ / khách hàng theo sheet).
    Lệch Oracle (2026-10-29): CUSTOMER không có NATIONAL_ID / NAT_ID_* (NULL ở Bronze) -> bảng hiện rỗng.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['cst_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH cus AS (
    SELECT c.*
    FROM {{ ref('t24core_customer') }} AS c
    WHERE c.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(c.recid), '') IS NOT NULL
),

src AS (
    SELECT
        {{ fn_hash('T24_CUSTOMER', 'c.recid') }} AS cst_id,
        TRIM(c.recid)                             AS cst_code,
        TRIM(c.nat_id_type)                       AS identn_tp_code,
        {{ t24_date('c.nat_id_iss_date') }}       AS identn_issu_dt,
        {{ t24_date('c.nat_id_exp_date') }}       AS identn_expiry_dt,
        TRIM(c.nat_id_iss_plc)                    AS issu_plc_code,
        TRIM(c.national_id)                       AS identn_nbr
    FROM cus AS c
    WHERE NULLIF(TRIM(c.national_id), '') IS NOT NULL
),

{% if is_incremental() %}
cur AS (
    SELECT * FROM {{ this }} WHERE sys_exp_dt IS NULL
),

new_ver AS (
    SELECT s.cst_id, s.cst_code, s.identn_tp_code, s.identn_issu_dt, s.identn_expiry_dt,
           s.issu_plc_code, s.identn_nbr,
           {{ etl_date() }}   AS sys_eff_dt,
           CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN cur AS c ON c.cst_id = s.cst_id
    WHERE c.cst_id IS NULL
       OR s.identn_tp_code IS DISTINCT FROM c.identn_tp_code
       OR s.identn_issu_dt IS DISTINCT FROM c.identn_issu_dt
       OR s.identn_expiry_dt IS DISTINCT FROM c.identn_expiry_dt
       OR s.issu_plc_code IS DISTINCT FROM c.issu_plc_code
       OR s.identn_nbr IS DISTINCT FROM c.identn_nbr
),

closed AS (
    SELECT c.cst_id, c.cst_code, c.identn_tp_code, c.identn_issu_dt, c.identn_expiry_dt,
           c.issu_plc_code, c.identn_nbr,
           c.sys_eff_dt,
           {{ etl_date() }} AS sys_exp_dt
    FROM cur AS c
    LEFT JOIN src AS s ON s.cst_id = c.cst_id
    WHERE c.sys_eff_dt < {{ etl_date() }}
      AND (
            (s.cst_id IS NULL AND EXISTS (SELECT 1 FROM cus))
         OR (s.cst_id IS NOT NULL AND (   -- chỉ so giá trị khi key còn ở nguồn (nguồn rỗng không đóng dòng)
                s.identn_tp_code IS DISTINCT FROM c.identn_tp_code
            OR  s.identn_issu_dt IS DISTINCT FROM c.identn_issu_dt
            OR  s.identn_expiry_dt IS DISTINCT FROM c.identn_expiry_dt
            OR  s.issu_plc_code IS DISTINCT FROM c.issu_plc_code
            OR  s.identn_nbr IS DISTINCT FROM c.identn_nbr
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
    SELECT src.*,
           {{ etl_date() }}   AS sys_eff_dt,
           CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(cst_id AS STRING)         AS cst_id,
    CAST(cst_code AS STRING)       AS cst_code,
    CAST(identn_tp_code AS STRING) AS identn_tp_code,
    CAST(identn_issu_dt AS DATE)    AS identn_issu_dt,
    CAST(identn_expiry_dt AS DATE)  AS identn_expiry_dt,
    CAST(issu_plc_code AS STRING)  AS issu_plc_code,
    CAST(identn_nbr AS STRING)     AS identn_nbr,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}                AS sys_udt_dt,
    {{ etl_date() }}                AS etl_date
FROM final
