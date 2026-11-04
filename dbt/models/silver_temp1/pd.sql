{#-
    PG_SILVER.PD — sheet 'Product', SCD TYPE 1.
    Danh mục mã sản phẩm hợp nhất (UNION DISTINCT) từ LOS_APP_PRODUCT.PRODUCT_CODE,
    FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE.SAN_PHAM_CHO_VAY_KHCN/KHDN và T24CORE_LD_LOANS_AND_DEPOSITS.PRODUCTGR_CODE.
    PD_NM lấy từ LOS_APP_PRODUCT; một PRODUCT_CODE có nhiều dòng (tên khác nhau) nên chọn dòng ID lớn nhất.
    Mã chỉ có ở FLEXBO / LD không có tên -> PD_NM NULL.
    Mỗi lần chạy chỉ MERGE các dòng mới / thay đổi / bị xóa ở nguồn:
      SYS_EFF_DT = ETL_DATE lần đầu xuất hiện (giữ nguyên khi cập nhật),
      SYS_EXP_DT = ETL_DATE khi mã biến mất khỏi nguồn (NULL lại nếu xuất hiện trở lại),
      SYS_UDT_DT = ETL_DATE lần thay đổi gần nhất.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='pd_id',
    on_schema_change='fail'
) }}

WITH los AS (
    SELECT
        TRIM(p.product_code) AS pd_code,
        TRIM(p.product_name) AS pd_nm,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(p.product_code)
            ORDER BY TRY_CAST(p.id AS BIGINT) DESC
        )                    AS rn
    FROM {{ source('pg_bronze', 'los_app_product') }} AS p
    WHERE p.etl_date = {{ etl_date() }}
),

pd_code AS (
    SELECT pd_code FROM los
    UNION
    SELECT TRIM(f.san_pham_cho_vay_khcn)
    FROM {{ source('pg_bronze', 'flexbo_pgb_los_contract_fields_tdate') }} AS f
    WHERE f.etl_date = {{ etl_date() }}
    UNION
    SELECT TRIM(f.san_pham_cho_vay_khdn)
    FROM {{ source('pg_bronze', 'flexbo_pgb_los_contract_fields_tdate') }} AS f
    WHERE f.etl_date = {{ etl_date() }}
    UNION
    SELECT TRIM(ld.productgr_code)
    FROM {{ source('pg_bronze', 't24core_ld_loans_and_deposits') }} AS ld
    WHERE ld.etl_date = {{ etl_date() }}
),

src AS (
    SELECT
        {{ fn_hash('T24_PRODUCT', 'c.pd_code') }} AS pd_id,
        c.pd_code,
        l.pd_nm
    FROM pd_code AS c
    LEFT JOIN los AS l ON l.pd_code = c.pd_code AND l.rn = 1
    WHERE NULLIF(c.pd_code, '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.pd_id, s.pd_code, s.pd_nm,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE)                       AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.pd_id = t.pd_id
    WHERE t.pd_id IS NULL
       OR t.sys_exp_dt IS NOT NULL
       OR s.pd_nm IS DISTINCT FROM t.pd_nm
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.pd_id, t.pd_code, t.pd_nm,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.pd_id = t.pd_id
    WHERE s.pd_id IS NULL
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
        pd_id, pd_code, pd_nm,
        {{ etl_date() }}   AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(pd_id AS VARCHAR)         AS pd_id,
    CAST(pd_code AS VARCHAR)       AS pd_code,
    CAST(pd_nm AS VARCHAR)         AS pd_nm,
    CAST('T24_PRODUCT' AS VARCHAR) AS src_stm_code,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}               AS sys_udt_dt,
    {{ etl_date() }}               AS etl_date
FROM final
