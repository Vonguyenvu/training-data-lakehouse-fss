{#-
    PG_SILVER.AR_BAL — sheet 'Arrangement Balance', SNAPSHOT theo ETL_DATE (khuôn exg_rate.sql).
    SOURCE_SAOKE_CRB, APP_CODE IN ('LD','PD'). Grain = 1 dòng sao kê CRB (hợp đồng × loại dư nợ × SBV_CODE).
    Bronze: TXN_DATE dạng 'yyyy-MM-dd HH:mm:ss.SSS'.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

SELECT
    TRY_CAST(TRIM(a.amount_cur) AS DECIMAL(25, 5)) AS rcvb_amt_lcy,
    TRY_CAST(TRIM(a.amount_lcy) AS DECIMAL(25, 5)) AS cls_bal_lcy,
    CAST(TRIM(a.app_code) AS STRING) AS mud_code,
    CAST(TRIM(a.app_id) AS STRING) AS ar_code,
    CAST({{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'a.app_id') }} AS STRING) AS ar_id,
    CAST(TRIM(a.asset_type) AS STRING) AS ast_tp_code,
    CAST(TRIM(a.categ_code) AS STRING) AS pd_cgy_code,
    CAST(TRIM(a.co_code) AS STRING) AS ou_code,
    CAST(TRIM(a.curr) AS STRING) AS ccy_code,
    CAST(TRIM(a.cus_id) AS STRING) AS cst_code,
    CAST({{ fn_hash('T24_CUSTOMER', 'a.cus_id') }} AS STRING) AS cst_id,
    CAST(TRIM(a.loc_term) AS STRING) AS ar_term_tp_code,
    CAST(TRIM(a.sbv_code) AS STRING) AS gl_itm_code,
    CAST({{ fn_hash('T24_GL_ITM', 'a.sbv_code') }} AS STRING) AS gl_itm_id,
    CAST(TRIM(a.sub_pro) AS STRING) AS sub_pd_code,
    TRY_CAST(SUBSTR(TRIM(a.txn_date), 1, 10) AS DATE) AS cdr_dt,
    {{ etl_date() }} AS etl_date
FROM {{ ref('source_saoke_crb') }} AS a
WHERE
    a.etl_date = {{ etl_date() }}
    AND TRIM(a.app_code) IN ('LD', 'PD')
