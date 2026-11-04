{#-
    PG_SILVER.OU — sheet 'Organization Unit', SCD TYPE 1.
    Khóa T24 của bảng COMPANY là RECID.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi RECID biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='ou_id',
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        {{ fn_hash('T24_COMPANY', 'ou.recid') }} AS ou_id,
        TRIM(ou.recid)                            AS ou_code,
        TRIM(ou.company_name)                     AS ou_nm
    FROM {{ source('pg_bronze', 't24core_company') }} AS ou
    WHERE ou.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(ou.recid), '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.ou_id, s.ou_code, s.ou_nm,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.ou_id = t.ou_id
    WHERE t.ou_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.ou_nm IS DISTINCT FROM t.ou_nm
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.ou_id, t.ou_code, t.ou_nm,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.ou_id = t.ou_id
    WHERE s.ou_id IS NULL
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
        ou_id, ou_code, ou_nm,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(ou_id AS VARCHAR)   AS ou_id,
    CAST(ou_code AS VARCHAR) AS ou_code,
    CAST(ou_nm AS VARCHAR)   AS ou_nm,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}         AS sys_udt_dt,
    {{ etl_date() }}         AS etl_date
FROM final
