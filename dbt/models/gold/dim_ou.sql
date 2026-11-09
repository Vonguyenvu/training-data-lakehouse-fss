{#-
    PG_GOLD.DIM_OU — sheet 'Dimension Organization Unit', SCD TYPE 2 (macro scd2) từ PG_SILVER.OU (SCD TYPE 1).
    DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || ou_id, ETL_CHANGE_DATE = COALESCE(SYS_UDT_DT, SYS_EFF_DT, ETL_DATE) của Silver
    -> phiên bản mới chỉ khi cột của DIM đổi (scd2 compare_exclude dim_key); ngày đó Silver có SYS_UDT_DT mới nên DIM_KEY không trùng.
    Khác Excel: SYS_EFF_DT / SYS_EXP_DT là ngày hiệu lực của phiên bản DIM (macro scd2), không chép 1:1 từ Silver
    (Silver SCD1 chỉ có 1 dòng / ID nên SYS_EFF_DT của Silver là ngày xuất hiện đầu tiên, không phải ngày của phiên bản).
    Nguồn chỉ lấy dòng Silver còn hiệu lực (SYS_EXP_DT IS NULL): ID bị xóa ở Silver -> scd2 đóng phiên bản DIM.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ou_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST(CONCAT(
            DATE_FORMAT(COALESCE(ou.sys_udt_dt, ou.sys_eff_dt, {{ etl_date() }}), 'yyyyMMdd'), ou.ou_id
        ) AS STRING) AS dim_key,
        CAST(ou.ou_id AS STRING) AS ou_id,
        CAST(ou.ou_code AS STRING) AS ou_code,
        CAST(ou.ou_nm AS STRING) AS ou_nm
    FROM {{ ref('ou') }} AS ou
    WHERE
        ou.sys_exp_dt IS NULL
)

{{ scd2(['ou_id'], compare_exclude=['dim_key']) }}
