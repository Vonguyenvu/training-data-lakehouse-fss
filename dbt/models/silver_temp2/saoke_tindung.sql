{#-
    PG_SILVER.SAOKE_TINDUNG — sheet 'SAOKE_TINDUNG', SNAPSHOT theo ETL_DATE (sao kê tín dụng, giữ tên cột nguồn).
    T24CORE_LD_LOANS_AND_DEPOSITS (RECORD_STATUS <> 'REVE') LEFT JOIN CUSTOMER (CUSTOMER_ID) và
    DEPT_ACCT_OFFICER (MB_RM_BANCHEO), mọi bảng lọc ETL_DATE. Grain = 1 hợp đồng LD.
    Khác Excel: DATE_TIME ghi TO_DATE(...,'YYYYMMDD') nhưng Bronze là yyMMddHHmm -> t24_datetime.
    Lệch Oracle: CUSTOMER chỉ có 10 cột, LD thiếu cột ID -> ID lấy RECID (mã hợp đồng LD).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH cus AS (
    SELECT * FROM {{ ref('t24core_customer') }} WHERE etl_date = {{ etl_date() }}
),

dao AS (
    SELECT * FROM {{ ref('t24core_dept_acct_officer') }} WHERE etl_date = {{ etl_date() }}
)

SELECT
    CAST(TRIM(cus.internet_banking_service) AS STRING)                               AS internet_banking_service,
    CAST(TRIM(cus.khoi) AS STRING)                                                   AS khoi,
    CAST(TRIM(cus.kyc_channel) AS STRING)                                            AS kyc_channel,
    CAST(TRIM(cus.ma_bhxh) AS STRING)                                                AS ma_bhxh,
    CAST(TRIM(cus.mau_hd) AS STRING)                                                 AS mau_hd,
    CAST(TRIM(cus.mb_cr_stt) AS STRING)                                              AS mb_cr_stt,
    CAST(TRIM(cus.mb_industry) AS STRING)                                            AS mb_industry,
    CAST(TRIM(cus.mb_rm_bancheo) AS STRING)                                          AS mb_rm_bancheo,
    CAST(TRIM(cus.mobile_banking_service) AS STRING)                                 AS mobile_banking_service,
    CAST(TRIM(cus.mobile_number) AS STRING)                                          AS mobile_number,
    {{ t24_date('cus.nat_id_exp_date') }}                                            AS nat_id_exp_date,
    {{ t24_date('cus.nat_id_iss_date') }}                                            AS nat_id_iss_date,
    CAST(TRIM(cus.nat_id_iss_plc) AS STRING)                                         AS nat_id_iss_plc,
    CAST(TRIM(cus.nat_id_type) AS STRING)                                            AS nat_id_type,
    CAST(TRIM(cus.national_id) AS STRING)                                            AS national_id,
    CAST(TRIM(cus.nationality) AS STRING)                                            AS nationality,
    COALESCE(TRY_CAST(TRIM(cus.net_monthly_in) AS DECIMAL(25, 5)), 0)                AS net_monthly_in,
    CAST(TRIM(cus.no_lien_doi) AS STRING)                                            AS no_lien_doi,
    CAST(TRIM(cus.occupation) AS STRING)                                             AS occupation,
    CAST(TRIM(cus.open_company) AS STRING)                                           AS open_company,
    CAST(TRIM(cus.phone_cont_per) AS STRING)                                         AS phone_cont_per,
    CAST(TRIM(cus.recid) AS STRING)                                                  AS cus_recid,
    CAST(TRIM(cus.referred_by) AS STRING)                                            AS referred_by,
    CAST(TRIM(cus.resid_province) AS STRING)                                         AS resid_province,
    CAST(TRIM(cus.residence) AS STRING)                                              AS residence,
    CAST(TRIM(cus.second_officer) AS STRING)                                         AS second_officer,
    CAST(TRIM(cus.sector) AS STRING)                                                 AS sector,
    CAST(TRIM(cus.short_name) AS STRING)                                             AS short_name,
    CAST(TRIM(cus.street) AS STRING)                                                 AS street,
    CAST(TRIM(cus.target) AS STRING)                                                 AS target,
    CAST(TRIM(cus.tax_serial) AS STRING)                                             AS tax_serial,
    {{ t24_date('cus.txn_date') }}                                                   AS txn_date,
    {{ t24_date('cus.vat_inv_date') }}                                               AS vat_inv_date,
    CAST(TRIM(cus.vat_inv_serial) AS STRING)                                         AS vat_inv_serial,
    CAST(TRIM(cus.vip_customer) AS STRING)                                           AS vip_customer,
    CAST(TRIM(cus.vn_full_name) AS STRING)                                           AS vn_full_name,
    CAST(TRIM(cus.vn_gender) AS STRING)                                              AS vn_gender,
    CAST(TRIM(cus.vn_street) AS STRING)                                              AS vn_street,
    CAST(TRIM(cus.vn_town) AS STRING)                                                AS vn_town,
    CAST(TRIM(dao.name) AS STRING)                                                   AS name,
    CAST(TRIM(dao.recid) AS STRING)                                                  AS dao_recid,
    CAST(TRIM(ld.acc_fcc) AS STRING)                                                 AS acc_fcc,
    COALESCE(TRY_CAST(TRIM(ld.amount) AS DECIMAL(25, 5)), 0)                         AS amount,
    COALESCE(TRY_CAST(TRIM(ld.approve_amount) AS DECIMAL(25, 5)), 0)                 AS approve_amount,
    CAST(TRIM(ld.authoriser) AS STRING)                                              AS authoriser,
    CAST(TRIM(ld.category) AS STRING)                                                AS category,
    CAST(TRIM(ld.co_code) AS STRING)                                                 AS co_code,
    CAST(TRIM(ld.commit_action) AS STRING)                                           AS commit_action,
    CAST(TRIM(ld.cra_ld) AS STRING)                                                  AS cra_ld,
    COALESCE(TRY_CAST(TRIM(ld.curr_no) AS DECIMAL(10, 0)), 0)                        AS curr_no,
    CAST(TRIM(ld.currency) AS STRING)                                                AS currency,
    CAST(TRIM(ld.customer_id) AS STRING)                                             AS customer_id,
    CAST({{ t24_datetime('ld.date_time') }} AS DATE)                                 AS date_time,
    COALESCE(TRY_CAST(TRIM(ld.drawdown_net_amt) AS DECIMAL(25, 5)), 0)               AS drawdown_net_amt,
    COALESCE(TRY_CAST(TRIM(ld.excg_rate) AS DECIMAL(13, 7)), 0)                      AS excg_rate,
    CAST(TRIM(ld.fcc_limit) AS STRING)                                               AS fcc_limit,
    {{ t24_date('ld.fin_mat_date') }}                                                AS fin_mat_date,
    CAST(TRIM(COALESCE(ld.id, ld.recid)) AS STRING)                                                 AS id,
    CAST(TRIM(ld.inputter) AS STRING)                                                AS inputter,
    CAST(TRIM(ld.int_liq_acct) AS STRING)                                            AS int_liq_acct,
    CAST(TRIM(ld.int_rate_type) AS STRING)                                           AS int_rate_type,
    {{ t24_date('ld.int_value_date') }}                                              AS int_value_date,
    COALESCE(TRY_CAST(TRIM(ld.interest_rate) AS DECIMAL(13, 7)), 0)                  AS interest_rate,
    COALESCE(TRY_CAST(TRIM(ld.interest_spread) AS DECIMAL(13, 7)), 0)                AS interest_spread,
    CAST(TRIM(ld.limit_reference) AS STRING)                                         AS limit_reference,
    CAST(TRIM(ld.loc_term) AS STRING)                                                AS loc_term,
    CAST(TRIM(ld.los_fac_code) AS STRING)                                            AS los_fac_code,
    {{ etl_date() }}                                                                 AS etl_date
FROM {{ ref('t24core_ld_loans_and_deposits') }} AS ld
LEFT JOIN cus ON TRIM(cus.recid) = TRIM(ld.customer_id)
LEFT JOIN dao ON TRIM(dao.recid) = TRIM(ld.mb_rm_bancheo)
WHERE ld.etl_date = {{ etl_date() }}
  AND COALESCE(ld.record_status, '_') <> 'REVE'
