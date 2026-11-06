{#-
    PG_SILVER.AR_X_IP_RLTNP — sheet 'Arrangement x Involved Party', SCD TYPE 2 (macro scd2).
    Khóa tự nhiên (AR_ID, CST_ID): hợp đồng đổi khách hàng -> cặp cũ đóng (biến mất), cặp mới mở.
    3 nhánh UNION ALL, chọn dòng như loan_ar.sql: LD sống / LD_HIS (CURR_NO max, không REVE, đã rời LD) / PD.
    d = LOS_CONTRACT_FIELDS_TDATE (MOV_DATE = ngày giá trị, 1 dòng / (hợp đồng, ngày)).
    Khác Excel: bỏ LEFT JOIN d1 (SELECT DISTINCT RECID FROM PD_PAYMENT_DUE_MV) của nhánh PD — không lấy cột nào, không đổi kết quả.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ar_id', 'cst_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH ld AS (
    SELECT l.*, TRIM(l.recid) AS ar_code,
           {{ t24_date("COALESCE(NULLIF(TRIM(l.orig_val_date), ''), l.value_date)") }} AS val_key_dt
    FROM {{ ref('t24core_ld_loans_and_deposits') }} AS l
    WHERE l.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(l.recid), '') IS NOT NULL
),

ldh AS (
    SELECT h.*, {{ t24_date("COALESCE(NULLIF(TRIM(h.orig_val_date), ''), h.value_date)") }} AS val_key_dt
    FROM (
        SELECT x.*, SPLIT_PART(TRIM(x.recid), ';', 1) AS ar_code,
               ROW_NUMBER() OVER (PARTITION BY SPLIT_PART(TRIM(x.recid), ';', 1)
                                  ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn,
               MAX(CASE WHEN TRIM(x.record_status) = 'REVE' THEN 1 ELSE 0 END)
                   OVER (PARTITION BY SPLIT_PART(TRIM(x.recid), ';', 1)) AS has_reve
        FROM {{ ref('t24core_ld_loans_and_deposits_his') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND NULLIF(SPLIT_PART(TRIM(x.recid), ';', 1), '') IS NOT NULL
    ) AS h
    WHERE h.rn = 1
      AND h.has_reve = 0
      AND NOT EXISTS (SELECT 1 FROM ld WHERE ld.ar_code = h.ar_code)
),

d AS (
    SELECT *
    FROM (
        SELECT TRIM(x.contract_ref_no) AS contract_ref_no,
               TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) AS mov_date,
               TRIM(x.can_bo_de_xuat_gn) AS can_bo_de_xuat_gn, TRIM(x.tt_pp_de_xuat_gn) AS tt_pp_de_xuat_gn,
               TRIM(x.cbtd_ql_khoan_vay) AS cbtd_ql_khoan_vay, TRIM(x.tp_pp_ql_khoan_vay) AS tp_pp_ql_khoan_vay,
               TRIM(x.cap_phe_duyet_gntl) AS cap_phe_duyet_gntl,
               ROW_NUMBER() OVER (PARTITION BY TRIM(x.contract_ref_no), SUBSTR(TRIM(x.mov_date), 1, 10)
                                  ORDER BY x.mov_date DESC) AS rn
        FROM {{ ref('flexbo_pgb_los_contract_fields_tdate') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

ld_ldh AS (
    SELECT 'T24_LD_LOANS_AND_DEPOSITS' AS src_stm_code, ar_code, TRIM(customer_id) AS customer_id,
           TRIM(inputter) AS inputter, TRIM(authoriser) AS authoriser, TRIM(mb_rm_bancheo) AS mb_rm_bancheo, val_key_dt
    FROM ld
    UNION ALL
    SELECT 'T24_LD_LOANS_AND_DEPOSITS_HIS', ar_code, TRIM(customer_id), NULL, NULL, TRIM(mb_rm_bancheo), val_key_dt
    FROM ldh
),

pd AS (
    SELECT d.*, SUBSTR(TRIM(d.recid), 1, 14) AS ar_code
    FROM (
        SELECT x.*, ROW_NUMBER() OVER (PARTITION BY TRIM(x.recid)
                                       ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC) AS rn
        FROM {{ ref('t24core_pd_payment_due') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND COALESCE(x.flag_status, '_') <> 'DELETE'
          AND NULLIF(TRIM(x.recid), '') IS NOT NULL
    ) AS d
    WHERE d.rn = 1
),

unioned AS (
    SELECT
        x.src_stm_code,
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'x.ar_code') }} AS ar_id,
        x.ar_code,
        {{ fn_hash('T24_CUSTOMER', 'x.customer_id') }}          AS cst_id,
        x.customer_id                                           AS cst_code,
        x.inputter                                              AS maker_ofcr,
        x.authoriser                                            AS chker_ofcr,
        x.mb_rm_bancheo                                         AS refrrer_ofcr,
        d.can_bo_de_xuat_gn                                     AS dsbr_prpsl_ofcr,
        d.tt_pp_de_xuat_gn                                      AS dsbr_prpsl_mgr,
        d.cbtd_ql_khoan_vay                                     AS mgt_ofcr,
        d.tp_pp_ql_khoan_vay                                    AS mgt_mgr,
        d.cap_phe_duyet_gntl                                    AS aprv_ahr
    FROM ld_ldh AS x
    LEFT JOIN d ON d.contract_ref_no = x.ar_code AND d.mov_date = x.val_key_dt

    UNION ALL

    SELECT
        'T24_PD_PAYMENT_DUE',
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'pd.ar_code') }},
        pd.ar_code,
        {{ fn_hash('T24_CUSTOMER', 'pd.customer') }},
        TRIM(pd.customer),
        TRIM(pd.inputter),
        TRIM(pd.authoriser),
        NULL, NULL, NULL, NULL, NULL, NULL
    FROM pd
),

src AS (
    SELECT
        CAST(src_stm_code AS STRING)    AS src_stm_code,
        CAST(ar_id AS STRING)           AS ar_id,
        CAST(ar_code AS STRING)         AS ar_code,
        CAST(cst_id AS STRING)          AS cst_id,
        CAST(cst_code AS STRING)        AS cst_code,
        CAST(maker_ofcr AS STRING)      AS maker_ofcr,
        CAST(chker_ofcr AS STRING)      AS chker_ofcr,
        CAST(refrrer_ofcr AS STRING)    AS refrrer_ofcr,
        CAST(dsbr_prpsl_ofcr AS STRING) AS dsbr_prpsl_ofcr,
        CAST(dsbr_prpsl_mgr AS STRING)  AS dsbr_prpsl_mgr,
        CAST(mgt_ofcr AS STRING)        AS mgt_ofcr,
        CAST(mgt_mgr AS STRING)         AS mgt_mgr,
        CAST(aprv_ahr AS STRING)        AS aprv_ahr
    FROM unioned
    -- quan hệ cần đủ 2 đầu; hợp đồng không có khách hàng không phải quan hệ AR x IP
    WHERE cst_id IS NOT NULL
)
{{ scd2(['ar_id', 'cst_id']) }}
