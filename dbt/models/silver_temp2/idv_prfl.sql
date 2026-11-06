{#-
    PG_SILVER.IDV_PRFL — sheet 'Individual Profile', SCD TYPE 2 (macro scd2, khuôn ip_elc_adr.sql).
    T24CORE_CUSTOMER, KHOI LIKE '%INDIV%'. Khóa tự nhiên CST_ID; đổi bất kỳ cột nào -> đóng dòng cũ, mở phiên bản mới.
    Bronze: ASSET_CLASS / CUS_IND_PARENT / MB_INDUSTRY dạng số Oracle '1.0000000000' -> t24_code.
    Lệch Oracle (2026-11-03): CUSTOMER chỉ có 10 cột -> đa số cột đích NULL.
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
        CAST({{ fn_hash('T24_CUSTOMER', 'c.recid') }} AS STRING)                  AS cst_id,
        CAST(TRIM(c.recid) AS STRING)                                             AS cst_code,
        CAST(TRIM(c.active_status) AS STRING)                                     AS cst_lcs_code,
        CAST(TRIM(c.aml_check) AS STRING)                                         AS aml_chk_f,
        CAST(TRIM(c.aml_result) AS STRING)                                        AS aml_rslt,
        CAST({{ t24_code('c.asset_class') }} AS STRING)                           AS cst_fnc_st_code,
        CAST(TRIM(c.co_code) AS STRING)                                           AS ou_code,
        CAST(TRIM(c.customer_status) AS STRING)                                   AS cst_st_code,
        CAST(TRIM(c.internet_banking_service) AS STRING)                          AS inn_bnkg_f,
        CAST(TRIM(c.kyc_channel) AS STRING)                                       AS kyc_cnl_code,
        CAST(TRIM(c.ma_bhxh) AS STRING)                                           AS vss_code,
        CAST(TRIM(c.mobile_banking_service) AS STRING)                            AS mbl_bnkg_f,
        CAST(TRIM(c.nationality) AS STRING)                                       AS cty_of_ctzn_code,
        CAST(TRIM(c.no_lien_doi) AS STRING)                                       AS jnt_lby_f,
        CAST(COALESCE(NULLIF(TRIM(c.tax_serial), ''), TRIM(c.vat_inv_serial)) AS STRING) AS tax_identn_nbr,
        CAST(TRIM(c.vip_customer) AS STRING)                                      AS vip_f,
        CAST(TRIM(c.vn_gender) AS STRING)                                         AS gnd,
        CAST({{ t24_code('c.cus_ind_parent') }} AS STRING)                        AS idy_lv1_cl_code,
        CAST({{ t24_code('c.mb_industry') }} AS STRING)                           AS idy_lv2_cl_code,
        COALESCE({{ t24_date('c.birth_incorp_date') }}, {{ t24_date('c.bdate_legal') }}) AS dob,
        CAST(TRIM(c.ffb_type) AS STRING)                                          AS vip_tp_code,
        {{ t24_date('c.cu_eff_date') }}                                           AS vip_eff_dt,
        {{ t24_date('c.vat_inv_date') }}                                          AS bsn_rgst_eff_dt,
        CAST(TRIM(c.mb_cr_stt) AS STRING)                                         AS mb_cr_st
    FROM {{ ref('t24core_customer') }} AS c
    WHERE c.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(c.recid), '') IS NOT NULL
      AND c.khoi LIKE '%INDIV%'
)
{{ scd2(['cst_id']) }}
