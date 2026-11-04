{#-
    PG_SILVER.CV — sheet 'Classification Value', SCD TYPE 1 (LOOKUP MASTER).
    Hai nhóm phân loại, mỗi nhóm SELECT DISTINCT mã để không nhân bản CL_ID:
      LOAN_RSTC_TP: FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST.CO_CAU_NO, mô tả theo DECODE trong sheet.
      FNC_ST      : T24CORE_CUSTOMER.ASSET_CLASS, mô tả 'Nhom no ' || mã.
    ASSET_CLASS trên PG_BRONZE dạng '1.0000000000' nên chuẩn hóa về số nguyên '1'..'5' cho khớp bảng mã chuẩn.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi mã biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='cl_id',
    on_schema_change='fail'
) }}

WITH loan_rstc_tp AS (
    SELECT DISTINCT TRIM(ud.co_cau_no) AS cl_code
    FROM {{ source('pg_bronze', 'flexbo_pgbld_rt_contract_udfield_hist') }} AS ud
    WHERE ud.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(ud.co_cau_no), '') IS NOT NULL
),

fnc_st AS (
    SELECT DISTINCT CAST(CAST(TRY_CAST(TRIM(cust.asset_class) AS DECIMAL(20, 10)) AS INTEGER) AS VARCHAR) AS cl_code
    FROM {{ source('pg_bronze', 't24core_customer') }} AS cust
    WHERE cust.etl_date = {{ etl_date() }}
      AND TRY_CAST(TRIM(cust.asset_class) AS DECIMAL(20, 10)) IS NOT NULL
),

src AS (
    SELECT
        {{ fn_hash('T24_CL_LOAN_RSTC_TP', 'cl_code') }} AS cl_id,
        cl_code,
        CASE cl_code
            WHEN '1' THEN '1.Co cau theo thong tu 09'
            WHEN '2' THEN '2.Co cau theo quyet dinh 780'
            WHEN '3' THEN '3.Co cau khac (theo thong tu 02 hien hanh)'
            WHEN '4' THEN '4.Khong'
            WHEN '5' THEN '5.Co cau no do Covid-19'
            WHEN '6' THEN '6.Mien giam lai do Covid-19'
            WHEN '7' THEN '7.Co cau va mien giam lai do Covid-19'
        END                                              AS cl_dsc,
        'LOAN_RSTC_TP'                                   AS cl_scm_code,
        'T24_CL_LOAN_RSTC_TP'                            AS src_stm_code
    FROM loan_rstc_tp
    UNION ALL
    SELECT
        {{ fn_hash('T24_CL_FNC_ST', 'cl_code') }} AS cl_id,
        cl_code,
        'Nhom no ' || cl_code                      AS cl_dsc,
        'FNC_ST'                                   AS cl_scm_code,
        'T24_CL_FNC_ST'                            AS src_stm_code
    FROM fnc_st
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.cl_id, s.cl_code, s.cl_dsc, s.cl_scm_code, s.src_stm_code,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.cl_id = t.cl_id
    WHERE t.cl_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.cl_dsc IS DISTINCT FROM t.cl_dsc
),

deleted AS (
    -- Chỉ đánh dấu xóa khi nguồn của đúng nhóm phân loại đó có dữ liệu,
    -- tránh expire cả nhóm khi một trong hai bảng Bronze chưa nạp.
    SELECT
        t.cl_id, t.cl_code, t.cl_dsc, t.cl_scm_code, t.src_stm_code,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.cl_id = t.cl_id
    WHERE s.cl_id IS NULL
      AND t.sys_exp_dt IS NULL
      AND EXISTS (SELECT 1 FROM src WHERE src.cl_scm_code = t.cl_scm_code)
),

final AS (
    SELECT * FROM changed
    UNION ALL
    SELECT * FROM deleted
)
{% else %}
final AS (
    SELECT
        cl_id, cl_code, cl_dsc, cl_scm_code, src_stm_code,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(cl_id AS VARCHAR)        AS cl_id,
    CAST(cl_code AS VARCHAR)      AS cl_code,
    CAST(cl_dsc AS VARCHAR)       AS cl_dsc,
    CAST(cl_scm_code AS VARCHAR)  AS cl_scm_code,
    CAST(src_stm_code AS VARCHAR) AS src_stm_code,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}              AS sys_udt_dt,
    {{ etl_date() }}              AS etl_date
FROM final
