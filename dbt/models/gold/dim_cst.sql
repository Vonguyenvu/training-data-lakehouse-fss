{#-
    PG_GOLD.DIM_CST — sheet 'Dimension Customer', SCD TYPE 2 (macro scd2).
    PG_SILVER.CST cst (SYS_EXP_DT IS NULL) LEFT JOIN IDV_PRFL idv / ORG_PRFL org (CST_ID, SYS_EXP_DT IS NULL).
    DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || CST_ID.
    Khác Excel: ETL_CHANGE_DATE = ngày đổi mới nhất của cst, idv, org (GREATEST) để phiên bản mới do idv/org đổi
    không trùng DIM_KEY. SYS_EFF_DT / SYS_EXP_DT là ngày hiệu lực phiên bản DIM (macro scd2).
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['cst_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH src AS (
    SELECT
        CAST(CONCAT(
            -- LEAST: replay backdate đọc Silver SCD1 không tua được, SYS_UDT_DT có thể là ngày sau ETL_DATE
            DATE_FORMAT(
                LEAST(COALESCE(
                    GREATEST(
                        COALESCE(cst.sys_udt_dt, cst.sys_eff_dt),
                        COALESCE(idv.sys_udt_dt, idv.sys_eff_dt),
                        COALESCE(org.sys_udt_dt, org.sys_eff_dt)
                    ),
                    {{ etl_date() }}
                ), {{ etl_date() }}),
                'yyyyMMdd'
            ),
            cst.cst_id
        ) AS STRING) AS dim_key,
        CAST(cst.cst_id AS STRING) AS cst_id,
        CAST(cst.cst_code AS STRING) AS cst_code,
        CAST(cst.cst_nm AS STRING) AS cst_nm,
        CAST(cst.sctr_code AS STRING) AS sctr_code,
        CAST(COALESCE(idv.idy_lv1_cl_code, org.idy_lv1_cl_code) AS STRING) AS idy_lv1_cl_code,
        CAST(COALESCE(idv.idy_lv2_cl_code, org.idy_lv2_cl_code) AS STRING) AS idy_lv2_cl_code
    FROM {{ ref('cst') }} AS cst
    LEFT JOIN {{ ref('idv_prfl') }} AS idv
        ON
            cst.cst_id = idv.cst_id
            AND idv.sys_exp_dt IS NULL
    LEFT JOIN {{ ref('org_prfl') }} AS org
        ON
            cst.cst_id = org.cst_id
            AND org.sys_exp_dt IS NULL
    WHERE
        cst.sys_exp_dt IS NULL
)

{{ scd2(['cst_id'], compare_exclude=['dim_key']) }}
