{#-
    PG_GOLD.DIM_RSTC_TP — sheet 'Dimension Loan Restructure Type', SCD TYPE 2 (macro scd2) từ PG_SILVER.CV (SCD TYPE 1).
    DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || cl_id, ETL_CHANGE_DATE = COALESCE(SYS_UDT_DT, SYS_EFF_DT, ETL_DATE) của Silver
    -> phiên bản mới chỉ khi cột của DIM đổi (scd2 compare_exclude dim_key); ngày đó Silver có SYS_UDT_DT mới nên DIM_KEY không trùng.
    Khác Excel: SYS_EFF_DT / SYS_EXP_DT là ngày hiệu lực của phiên bản DIM (macro scd2), không chép 1:1 từ Silver
    (Silver SCD1 chỉ có 1 dòng / ID nên SYS_EFF_DT của Silver là ngày xuất hiện đầu tiên, không phải ngày của phiên bản).
    Nguồn chỉ lấy dòng Silver còn hiệu lực (SYS_EXP_DT IS NULL): ID bị xóa ở Silver -> scd2 đóng phiên bản DIM.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['rstc_tp_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST(CONCAT(
            -- LEAST: replay backdate đọc Silver SCD1 không tua được, SYS_UDT_DT có thể là ngày sau ETL_DATE
            DATE_FORMAT(LEAST(COALESCE(cv.sys_udt_dt, cv.sys_eff_dt, {{ etl_date() }}), {{ etl_date() }}), 'yyyyMMdd'), cv.cl_id
        ) AS STRING) AS dim_key,
        CAST(cv.cl_id AS STRING) AS rstc_tp_id,
        CAST(cv.cl_code AS STRING) AS rstc_tp_code,
        CAST(cv.cl_dsc AS STRING) AS rstc_tp_dsc
    FROM {{ ref('cv') }} AS cv
    WHERE
        cv.sys_exp_dt IS NULL
        AND cv.cl_scm_code = 'LOAN_RSTC_TP'
)

{{ scd2(['rstc_tp_id'], compare_exclude=['dim_key']) }}
