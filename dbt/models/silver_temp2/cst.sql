{#-
    PG_SILVER.CST — sheet 'Customer', SCD TYPE 1 (khuôn: silver_temp1/ccy.sql).
    T24CORE_CUSTOMER LEFT JOIN T24CORE_SECTOR (c.SECTOR = s.RECID), cả hai lọc ETL_DATE.
    Bronze: SECTOR dạng '1602.0000000000', SECTOR.RECID là '1602' -> chuẩn hóa bằng t24_code.
    Lệch Oracle (2026-11-03): CUSTOMER chỉ có 10 cột -> đa số cột đích NULL (docs/thuc_te_vs_thiet_ke.md mục 2).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='cst_id',
    on_schema_change='fail'
) }}

WITH sec AS (
    SELECT TRIM(s.recid) AS recid, MAX(TRIM(s.customer_type)) AS customer_type
    FROM {{ ref('t24core_sector') }} AS s
    WHERE s.etl_date = {{ etl_date() }}
    GROUP BY TRIM(s.recid)
),

src AS (
    SELECT
        CAST({{ fn_hash('T24_CUSTOMER', 'c.recid') }} AS STRING) AS cst_id,
        CAST(TRIM(c.recid) AS STRING) AS cst_code,
        CAST(TRIM(c.khoi) AS STRING) AS cst_grp_code,
        CAST(TRIM(c.open_company) AS STRING) AS frst_ou_code,
        CAST(TRIM(c.company_book) AS STRING) AS ou_code,
        CAST(TRIM(c.account_officer) AS STRING) AS maker_ofcr_code,
        CAST(TRIM(c.second_officer) AS STRING) AS chker_ofcr_code,
        CAST(TRIM(c.referred_by) AS STRING) AS refr_code,
        CAST({{ t24_code('c.sector') }} AS STRING) AS sctr_code,
        CAST(TRIM(c.short_name) AS STRING) AS shrt_nm,
        CAST(TRIM(c.vn_full_name) AS STRING) AS cst_nm,
        {{ t24_date('c.contact_date') }} AS opn_dt,
        CAST(TRIM(c.account_officer) AS STRING) AS empe_code,
        CAST(TRIM(c.street) AS STRING) AS str_addr,
        CAST(TRIM(c.target) AS STRING) AS trgt_code,
        COALESCE(CAST({{ t24_datetime('c.date_time') }} AS DATE), {{ t24_date('c.txn_date') }}) AS src_dt_tm,
        CAST(TRIM(c.mau_hd) AS STRING) AS ctr_tmpl_code,
        CAST(TRIM(c.mb_rm_bancheo) AS STRING) AS crs_sell_rm_code,
        CAST(sec.customer_type AS STRING) AS cst_tp_code
    FROM {{ ref('t24core_customer') }} AS c
    LEFT JOIN sec ON sec.recid = {{ t24_code('c.sector') }}
    WHERE
        c.etl_date = {{ etl_date() }}
        AND NULLIF(TRIM(c.recid), '') IS NOT NULL
),

{% if is_incremental() %}
tgt AS (
    SELECT * FROM {{ this }}
),

changed AS (
    SELECT
        s.*,
        COALESCE(t.sys_eff_dt, {{ etl_date() }}) AS sys_eff_dt,
        CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN tgt AS t ON s.cst_id = t.cst_id
    WHERE
        t.cst_id IS NULL
        OR t.sys_exp_dt IS NOT NULL
        OR NOT (
            s.cst_grp_code <=> t.cst_grp_code AND s.frst_ou_code <=> t.frst_ou_code
            AND s.ou_code <=> t.ou_code AND s.maker_ofcr_code <=> t.maker_ofcr_code
            AND s.chker_ofcr_code <=> t.chker_ofcr_code AND s.refr_code <=> t.refr_code
            AND s.sctr_code <=> t.sctr_code AND s.shrt_nm <=> t.shrt_nm AND s.cst_nm <=> t.cst_nm
            AND s.opn_dt <=> t.opn_dt AND s.empe_code <=> t.empe_code AND s.str_addr <=> t.str_addr
            AND s.trgt_code <=> t.trgt_code AND s.src_dt_tm <=> t.src_dt_tm
            AND s.ctr_tmpl_code <=> t.ctr_tmpl_code AND s.crs_sell_rm_code <=> t.crs_sell_rm_code
            AND s.cst_tp_code <=> t.cst_tp_code
        )
),

deleted AS (
    -- Chỉ đánh dấu xóa khi partition nguồn có dữ liệu, tránh expire toàn bộ khi Bronze chưa nạp.
    SELECT
        t.cst_id, t.cst_code, t.cst_grp_code, t.frst_ou_code, t.ou_code, t.maker_ofcr_code,
        t.chker_ofcr_code, t.refr_code, t.sctr_code, t.shrt_nm, t.cst_nm, t.opn_dt, t.empe_code,
        t.str_addr, t.trgt_code, t.src_dt_tm, t.ctr_tmpl_code, t.crs_sell_rm_code, t.cst_tp_code,
        t.sys_eff_dt,
        {{ etl_date() }} AS sys_exp_dt
    FROM tgt AS t
    LEFT JOIN src AS s ON s.cst_id = t.cst_id
    WHERE
        s.cst_id IS NULL
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
    SELECT src.*, {{ etl_date() }} AS sys_eff_dt, CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    final.*,
    {{ etl_date() }} AS sys_udt_dt,
    {{ etl_date() }} AS etl_date
FROM final
