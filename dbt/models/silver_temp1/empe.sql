{#-
    PG_SILVER.EMPE — sheet 'Employee', SCD TYPE 1.
    Khóa T24 của bảng DEPT_ACCT_OFFICER là RECID.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi RECID biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='empe_id',
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        {{ fn_hash('T24_EMPLOYEE', 'empe.recid') }} AS empe_id,
        TRIM(empe.recid)                             AS empe_code,
        TRIM(empe.name)                              AS empe_nm
    FROM {{ ref('t24core_dept_acct_officer') }} AS empe
    WHERE empe.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(empe.recid), '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.empe_id, s.empe_code, s.empe_nm,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.empe_id = t.empe_id
    WHERE t.empe_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.empe_nm IS DISTINCT FROM t.empe_nm
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.empe_id, t.empe_code, t.empe_nm,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.empe_id = t.empe_id
    WHERE s.empe_id IS NULL
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
        empe_id, empe_code, empe_nm,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(empe_id AS STRING)   AS empe_id,
    CAST(empe_code AS STRING) AS empe_code,
    CAST(empe_nm AS STRING)   AS empe_nm,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}           AS sys_udt_dt,
    {{ etl_date() }}           AS etl_date
FROM final
