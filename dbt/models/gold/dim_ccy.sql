{#-
    PG_GOLD.DIM_CCY — sheet 'Dimension Currency', SCD TYPE 2 (macro scd2) từ PG_SILVER.CCY (SCD TYPE 1).
    DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || ccy_id, ETL_CHANGE_DATE = COALESCE(SYS_UDT_DT, SYS_EFF_DT, ETL_DATE) của Silver
    -> phiên bản mới chỉ khi cột của DIM đổi (scd2 compare_exclude dim_key); ngày đó Silver có SYS_UDT_DT mới nên DIM_KEY không trùng.
    Khác Excel: SYS_EFF_DT / SYS_EXP_DT là ngày hiệu lực của phiên bản DIM (macro scd2), không chép 1:1 từ Silver
    (Silver SCD1 chỉ có 1 dòng / ID nên SYS_EFF_DT của Silver là ngày xuất hiện đầu tiên, không phải ngày của phiên bản).
    Nguồn chỉ lấy dòng Silver còn hiệu lực (SYS_EXP_DT IS NULL): ID bị xóa ở Silver -> scd2 đóng phiên bản DIM.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ccy_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST(CONCAT(
            -- LEAST: replay backdate đọc Silver SCD1 không tua được, SYS_UDT_DT có thể là ngày sau ETL_DATE
            DATE_FORMAT(LEAST(COALESCE(cur.sys_udt_dt, cur.sys_eff_dt, {{ etl_date() }}), {{ etl_date() }}), 'yyyyMMdd'), cur.ccy_id
        ) AS STRING) AS dim_key,
        CAST(cur.ccy_id AS STRING) AS ccy_id,
        CAST(cur.ccy_code AS STRING) AS ccy_code,
        CAST(cur.ccy_nm AS STRING) AS ccy_nm,
        CAST(cur.numeric_ccy_code AS STRING) AS numeric_ccy_code
    FROM {{ ref('ccy') }} AS cur
    WHERE
        cur.sys_exp_dt IS NULL
)

{{ scd2(['ccy_id'], compare_exclude=['dim_key']) }}
