{#-
    PG_SILVER.IP_PST_ADR — sheet 'Involved Party Postal Address', SCD TYPE 2 (khuôn: ip_elc_adr.sql).
    2 nhánh UNION ALL từ T24CORE_CUSTOMER: 'CURRENT ADDRESS' (VN_STREET, VN_TOWN, COUNTRY)
    và 'PERMANENT ADDRESS' (STREET, RESID_PROVINCE, RESIDENCE). Khóa tự nhiên (CST_ID, PST_ADR_TP).
    Khác Excel (đã thống nhất):
      - Excel ghép bằng '||' (Oracle coi NULL là rỗng); Trino '||' trả NULL nếu 1 phần NULL
        -> dùng concat_ws bỏ phần rỗng.
      - Excel không lọc NOT NULL -> mỗi khách hàng sinh 2 dòng toàn NULL; ở đây bỏ dòng không có phần địa chỉ nào.
    Lệch Oracle (2026-10-29): CUSTOMER không có các cột địa chỉ (NULL ở Bronze) -> bảng hiện rỗng.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['cst_id', 'pst_adr_tp', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH cus AS (
    SELECT
        {{ fn_hash('T24_CUSTOMER', 'c.recid') }} AS cst_id,
        TRIM(c.recid)                             AS cst_code,
        NULLIF(TRIM(c.vn_street), '')             AS vn_street,
        NULLIF(TRIM(c.vn_town), '')               AS vn_town,
        NULLIF(TRIM(c.country), '')               AS country,
        NULLIF(TRIM(c.street), '')                AS street,
        NULLIF(TRIM(c.resid_province), '')        AS resid_province,
        NULLIF(TRIM(c.residence), '')             AS residence
    FROM {{ source('pg_bronze', 't24core_customer') }} AS c
    WHERE c.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(c.recid), '') IS NOT NULL
),

branches AS (
    SELECT cst_id, cst_code, 'CURRENT ADDRESS' AS pst_adr_tp,
           NULLIF(concat_ws(',', vn_street, vn_town, country), '') AS pst_adr_val,
           country AS cty_nm, vn_town AS prov_nm, vn_street AS str_nm
    FROM cus
    UNION ALL
    SELECT cst_id, cst_code, 'PERMANENT ADDRESS',
           NULLIF(concat_ws(',', resid_province, residence), ''),
           residence, resid_province, street
    FROM cus
),

src AS (
    SELECT * FROM branches
    WHERE COALESCE(pst_adr_val, str_nm) IS NOT NULL
),

{% if is_incremental() %}
cur AS (
    SELECT * FROM {{ this }} WHERE sys_exp_dt IS NULL
),

new_ver AS (
    SELECT s.cst_id, s.cst_code, s.pst_adr_tp, s.pst_adr_val, s.cty_nm, s.prov_nm, s.str_nm,
           {{ etl_date() }}   AS sys_eff_dt,
           CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN cur AS c ON c.cst_id = s.cst_id AND c.pst_adr_tp = s.pst_adr_tp
    WHERE c.cst_id IS NULL
       OR s.pst_adr_val IS DISTINCT FROM c.pst_adr_val
       OR s.cty_nm IS DISTINCT FROM c.cty_nm
       OR s.prov_nm IS DISTINCT FROM c.prov_nm
       OR s.str_nm IS DISTINCT FROM c.str_nm
),

closed AS (
    SELECT c.cst_id, c.cst_code, c.pst_adr_tp, c.pst_adr_val, c.cty_nm, c.prov_nm, c.str_nm,
           c.sys_eff_dt,
           {{ etl_date() }} AS sys_exp_dt
    FROM cur AS c
    LEFT JOIN src AS s ON s.cst_id = c.cst_id AND s.pst_adr_tp = c.pst_adr_tp
    WHERE c.sys_eff_dt < {{ etl_date() }}
      AND (
            (s.cst_id IS NULL AND EXISTS (SELECT 1 FROM cus))
         OR s.pst_adr_val IS DISTINCT FROM c.pst_adr_val
         OR s.cty_nm IS DISTINCT FROM c.cty_nm
         OR s.prov_nm IS DISTINCT FROM c.prov_nm
         OR s.str_nm IS DISTINCT FROM c.str_nm
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
    CAST(cst_id AS VARCHAR)      AS cst_id,
    CAST(cst_code AS VARCHAR)    AS cst_code,
    CAST(pst_adr_tp AS VARCHAR)  AS pst_adr_tp,
    CAST(pst_adr_val AS VARCHAR) AS pst_adr_val,
    CAST(cty_nm AS VARCHAR)      AS cty_nm,
    CAST(prov_nm AS VARCHAR)     AS prov_nm,
    CAST(str_nm AS VARCHAR)      AS str_nm,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}             AS sys_udt_dt,
    {{ etl_date() }}             AS etl_date
FROM final
