{#-
    PG_SILVER.LOAN_AR_PRFL — sheet 'Loan Arrangement Profile', SCD TYPE 2 (macro scd2). Khóa tự nhiên AR_ID.
    3 nhánh UNION ALL, cùng cách chọn dòng như loan_ar.sql (LD sống / LD_HIS CURR_NO max, không REVE, đã rời LD / PD).
    Bảng phụ (left join, lấy 1 dòng / khóa join để không nhân dòng):
      b EBANKING_COL_UDF_VALUE (UDF NHANNO_BATBUOC; CONTRACT_INFOR theo ACC_FCC ưu tiên hơn LIMIT_INFOR theo FCC_LIMIT),
      c/c1 PGB_CONTRACT_UDF_MAP, d LOS_CONTRACT_FIELDS_TDATE (MOV_DATE = ngày giá trị),
      e PGBLD_CONTRACT_UDFIELD_HIST / g PGBLD_RT_CONTRACT_UDFIELD_HIST (MOV_DATE mới nhất — sheet ghi "tránh dup"),
      f MB_MG_SAVING_MULTI, h SAOKE_MVMT (SBV_CODE LIKE '39%', MIN SBV_CODE / TRANS_REF), i CUSTOMER.
    Khác Excel:
      - e, g, h có nhiều dòng / hợp đồng -> lấy 1 dòng (e, g: MOV_DATE lớn nhất; h: MIN(SBV_CODE)).
      - NGAY_HET_COVID19 trên Bronze dạng 'dd/MM/yyyy'; SO_LAN_CO_CAU dạng số Oracle '0E-10'.
      - Bronze 2026-11-03: e (CONTRACT_UDFIELD_HIST) rỗng -> PROM_PRGM chỉ đến từ f.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ar_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH ld AS (
    SELECT
        l.*, TRIM(l.recid) AS ar_code,
        {{ t24_date("COALESCE(NULLIF(TRIM(l.orig_val_date), ''), l.value_date)") }} AS val_key_dt
    FROM {{ ref('t24core_ld_loans_and_deposits') }} AS l
    WHERE
        l.etl_date = {{ etl_date() }}
        AND NULLIF(TRIM(l.recid), '') IS NOT NULL
),

ldh AS (
    SELECT h.*, {{ t24_date("COALESCE(NULLIF(TRIM(h.orig_val_date), ''), h.value_date)") }} AS val_key_dt
    FROM (
        SELECT
            x.*, SPLIT_PART(TRIM(x.recid), ';', 1) AS ar_code,
            ROW_NUMBER() OVER (
                PARTITION BY SPLIT_PART(TRIM(x.recid), ';', 1)
                ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC
            ) AS rn,
            MAX(CASE WHEN TRIM(x.record_status) = 'REVE' THEN 1 ELSE 0 END)
                OVER (PARTITION BY SPLIT_PART(TRIM(x.recid), ';', 1)) AS has_reve
        FROM {{ ref('t24core_ld_loans_and_deposits_his') }} AS x
        WHERE
            x.etl_date = {{ etl_date() }}
            AND NULLIF(SPLIT_PART(TRIM(x.recid), ';', 1), '') IS NOT NULL
    ) AS h
    WHERE
        h.rn = 1
        AND h.has_reve = 0
        AND NOT EXISTS (SELECT 1 FROM ld WHERE ld.ar_code = h.ar_code)
),

b AS (
    SELECT TRIM(x.col_ref) AS col_ref, TRIM(x.function_code) AS function_code, MAX(TRIM(x.udf_value)) AS udf_value
    FROM {{ ref('ebanking_col_udf_value') }} AS x
    WHERE
        x.etl_date = {{ etl_date() }}
        AND TRIM(x.udf_id) = 'NHANNO_BATBUOC'
        AND TRIM(x.function_code) IN ('CONTRACT_INFOR', 'LIMIT_INFOR')
    GROUP BY TRIM(x.col_ref), TRIM(x.function_code)
),

c AS (
    SELECT
        TRIM(x.contract_ref_no) AS contract_ref_no,
        MAX(CASE WHEN TRIM(x.field_name) = 'SO LAN CO CAU' THEN TRIM(x.field_val) END) AS so_lan_co_cau,
        MAX(CASE WHEN TRIM(x.field_name) = 'LOAI CHUNG KHOAN' THEN TRIM(x.field_val) END) AS loai_chung_khoan
    FROM {{ ref('flexbo_pgb_contract_udf_map') }} AS x
    WHERE
        x.etl_date = {{ etl_date() }}
        AND TRIM(x.field_name) IN ('SO LAN CO CAU', 'LOAI CHUNG KHOAN')
    GROUP BY TRIM(x.contract_ref_no)
),

d AS (
    SELECT *
    FROM (
        SELECT
            TRIM(x.contract_ref_no) AS contract_ref_no,
            TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) AS mov_date,
            TRIM(x.so_lan_co_cau) AS so_lan_co_cau, TRIM(x.car_application_code) AS car_application_code,
            TRIM(x.los_contract_code) AS los_contract_code, TRIM(x.los_contract_id) AS los_contract_id,
            TRIM(x.co_cau_no_mien_giam_lai) AS co_cau_no_mien_giam_lai, TRIM(x.mdvay_nkt) AS mdvay_nkt,
            TRIM(x.mdvay_sp) AS mdvay_sp, TRIM(x.can_bo_de_xuat_gn) AS can_bo_de_xuat_gn,
            TRIM(x.tt_pp_de_xuat_gn) AS tt_pp_de_xuat_gn, TRIM(x.cbtd_ql_khoan_vay) AS cbtd_ql_khoan_vay,
            TRIM(x.tp_pp_ql_khoan_vay) AS tp_pp_ql_khoan_vay, TRIM(x.cap_phe_duyet_gntl) AS cap_phe_duyet_gntl,
            TRIM(x.bds_tt11) AS bds_tt11,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(x.contract_ref_no), SUBSTR(TRIM(x.mov_date), 1, 10)
                ORDER BY x.mov_date DESC
            ) AS rn
        FROM {{ ref('flexbo_pgb_los_contract_fields_tdate') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

e AS (
    SELECT contract_ref_no, ct_khuyen_mai_cho_vay, ctkm2
    FROM (
        SELECT
            TRIM(x.contract_ref_no) AS contract_ref_no,
            NULLIF(TRIM(x.ct_khuyen_mai_cho_vay), '') AS ct_khuyen_mai_cho_vay,
            NULLIF(TRIM(x.ctkm2), '') AS ctkm2,
            ROW_NUMBER() OVER (PARTITION BY TRIM(x.contract_ref_no) ORDER BY x.mov_date DESC) AS rn
        FROM {{ ref('flexbo_pgbld_contract_udfield_hist') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

f AS (
    SELECT TRIM(x.ld_id) AS ld_id, MAX(NULLIF(TRIM(x.mb_ld_type), '')) AS mb_ld_type
    FROM {{ ref('t24core_mb_mg_saving_multi') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
    GROUP BY TRIM(x.ld_id)
),

g AS (
    SELECT contract_ref_no, co_cau_no, ngay_het_covid19
    FROM (
        SELECT
            TRIM(x.contract_ref_no) AS contract_ref_no,
            TRIM(x.co_cau_no) AS co_cau_no,
            CAST(try_to_timestamp(TRIM(x.ngay_het_covid19), 'dd/MM/yyyy') AS DATE) AS ngay_het_covid19,
            ROW_NUMBER() OVER (PARTITION BY TRIM(x.contract_ref_no) ORDER BY x.mov_date DESC) AS rn
        FROM {{ ref('flexbo_pgbld_rt_contract_udfield_hist') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

h AS (
    SELECT TRIM(x.trans_ref) AS trans_ref, MIN(TRIM(x.sbv_code)) AS sbv_code
    FROM {{ ref('source_saoke_mvmt') }} AS x
    WHERE
        x.etl_date = {{ etl_date() }}
        AND TRIM(x.sbv_code) LIKE '39%'
    GROUP BY TRIM(x.trans_ref)
),

i AS (
    SELECT TRIM(x.recid) AS recid, MAX(TRIM(x.khoi)) AS khoi
    FROM {{ ref('t24core_customer') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
    GROUP BY TRIM(x.recid)
),

ld_ldh AS (
    -- LD và LD_HIS cùng khuôn; cột sheet gán NULL ở nhánh LD_HIS -> NULL.
    SELECT
        'T24_LD_LOANS_AND_DEPOSITS' AS src_stm_code, ar_code, TRIM(acc_fcc) AS acc_fcc, TRIM(fcc_limit) AS fcc_limit,
        TRIM(int_liq_acct) AS int_liq_acct, TRIM(prin_liq_acct) AS prin_liq_acct, TRIM(status) AS status,
        TRIM(co_code) AS co_code, TRIM(authoriser) AS authoriser, TRIM(inputter) AS inputter,
        TRIM(mb_rm_bancheo) AS mb_rm_bancheo, TRIM(customer_id) AS customer_id, val_key_dt
    FROM ld
    UNION ALL
    SELECT
        'T24_LD_LOANS_AND_DEPOSITS_HIS', ar_code, TRIM(acc_fcc), NULL,
        TRIM(int_liq_acct), TRIM(prin_liq_acct), NULL,
        TRIM(co_code), NULL, NULL,
        TRIM(mb_rm_bancheo), TRIM(customer_id), val_key_dt
    FROM ldh
),

pd AS (
    SELECT d.*, SUBSTR(TRIM(d.recid), 1, 14) AS ar_code
    FROM (
        SELECT
            x.*, ROW_NUMBER() OVER (
                PARTITION BY TRIM(x.recid)
                ORDER BY TRY_CAST(TRIM(x.curr_no) AS INTEGER) DESC
            ) AS rn
        FROM {{ ref('t24core_pd_payment_due') }} AS x
        WHERE
            x.etl_date = {{ etl_date() }}
            AND COALESCE(x.flag_status, '_') <> 'DELETE'
            AND NULLIF(TRIM(x.recid), '') IS NOT NULL
    ) AS d
    WHERE d.rn = 1
),

pd_mv AS (
    SELECT TRIM(x.recid) AS recid, MAX(TRIM(x.co_code)) AS co_code, MAX(TRIM(x.repayment_acct)) AS repayment_acct
    FROM {{ ref('t24core_pd_payment_due_mv') }} AS x
    WHERE
        x.etl_date = {{ etl_date() }}
        AND COALESCE(x.flag_status, '_') <> 'DELETE'
    GROUP BY TRIM(x.recid)
),

unioned AS (
    SELECT
        x.src_stm_code,
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'x.ar_code') }} AS ar_id,
        x.ar_code,
        x.int_liq_acct AS int_lqd_ar_code,
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'x.int_liq_acct') }} AS int_lqd_ar_id,
        x.prin_liq_acct AS pnp_lqd_ar_code,
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'x.prin_liq_acct') }} AS pnp_lqd_ar_id,
        x.status AS ar_lcs_tp_code,
        x.co_code AS ou_code,
        COALESCE(CASE WHEN x.ar_code LIKE 'LD%' THEN b_ctr.udf_value END, b_lmt.udf_value) AS mand_repymt,
        COALESCE(
            TRY_CAST(d.so_lan_co_cau AS DECIMAL(30, 10)),
            TRY_CAST(c.so_lan_co_cau AS DECIMAL(30, 10))
        ) AS nbr_of_dbt_rstc,
        c.loai_chung_khoan AS scr_tp,
        d.car_application_code AS car_ap_code,
        d.los_contract_code AS los_ctr_code,
        d.los_contract_id AS los_ctr_id,
        d.co_cau_no_mien_giam_lai AS dbt_wvr_f,
        d.mdvay_nkt AS ar_pps_by_idy,
        d.mdvay_sp AS ar_pps_by_pd,
        d.can_bo_de_xuat_gn AS dsbr_prpsl_ofcr,
        d.tt_pp_de_xuat_gn AS dsbr_prpsl_mgr,
        d.cbtd_ql_khoan_vay AS mgt_ofcr,
        d.tp_pp_ql_khoan_vay AS mgt_mgr,
        d.cap_phe_duyet_gntl AS aprv_ahr,
        x.authoriser AS chker_ofcr,
        x.inputter AS maker_ofcr,
        x.mb_rm_bancheo AS refrrer_ofcr,
        CASE
            WHEN e.ct_khuyen_mai_cho_vay IS NULL AND i.khoi = 'INDIV' THEN f.mb_ld_type
            ELSE e.ct_khuyen_mai_cho_vay
        END AS prom_prgm,
        CASE
            WHEN e.ctkm2 IS NULL AND i.khoi <> 'INDIV' THEN f.mb_ld_type
            ELSE e.ctkm2
        END AS prom_prgm_2,
        g.co_cau_no AS dbt_rstc_tp_code,
        g.ngay_het_covid19 AS covid19_rstc_compl_dt,
        h.sbv_code AS gl_itm_code,
        {{ fn_hash('T24_GL_ITM', 'h.sbv_code') }} AS gl_itm_id,
        '1' AS fnc_st_code,
        d.bds_tt11
    FROM ld_ldh AS x
    LEFT JOIN b AS b_ctr ON b_ctr.col_ref = x.acc_fcc AND b_ctr.function_code = 'CONTRACT_INFOR'
    LEFT JOIN b AS b_lmt ON b_lmt.col_ref = x.fcc_limit AND b_lmt.function_code = 'LIMIT_INFOR'
    LEFT JOIN c ON c.contract_ref_no = x.acc_fcc
    LEFT JOIN d ON d.contract_ref_no = x.ar_code AND d.mov_date = x.val_key_dt
    LEFT JOIN e ON e.contract_ref_no = x.acc_fcc
    LEFT JOIN f ON f.ld_id = x.ar_code
    LEFT JOIN g ON g.contract_ref_no = x.acc_fcc
    LEFT JOIN h ON h.trans_ref = x.ar_code
    LEFT JOIN i ON i.recid = x.customer_id

    UNION ALL

    SELECT
        'T24_PD_PAYMENT_DUE',
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'pd.ar_code') }},
        pd.ar_code,
        COALESCE(NULLIF(TRIM(pd.repayment_acct), ''), d1.repayment_acct),
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', "COALESCE(NULLIF(TRIM(pd.repayment_acct), ''), d1.repayment_acct)") }},
        NULL, NULL,
        TRIM(pd.status),
        d1.co_code,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        TRIM(pd.authoriser),
        TRIM(pd.inputter),
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        COALESCE(NULLIF(TRIM(pd.credit_status), ''), '1'),
        NULL
    FROM pd
    LEFT JOIN pd_mv AS d1 ON d1.recid = TRIM(pd.recid)
),

src AS (
    SELECT
        CAST(src_stm_code AS STRING) AS src_stm_code,
        CAST(ar_id AS STRING) AS ar_id,
        CAST(ar_code AS STRING) AS ar_code,
        CAST(int_lqd_ar_code AS STRING) AS int_lqd_ar_code,
        CAST(int_lqd_ar_id AS STRING) AS int_lqd_ar_id,
        CAST(pnp_lqd_ar_code AS STRING) AS pnp_lqd_ar_code,
        CAST(pnp_lqd_ar_id AS STRING) AS pnp_lqd_ar_id,
        CAST(ar_lcs_tp_code AS STRING) AS ar_lcs_tp_code,
        CAST(ou_code AS STRING) AS ou_code,
        CAST(mand_repymt AS STRING) AS mand_repymt,
        CAST(nbr_of_dbt_rstc AS DECIMAL(22, 0)) AS nbr_of_dbt_rstc,
        CAST(scr_tp AS STRING) AS scr_tp,
        CAST(car_ap_code AS STRING) AS car_ap_code,
        CAST(los_ctr_code AS STRING) AS los_ctr_code,
        CAST(los_ctr_id AS STRING) AS los_ctr_id,
        CAST(dbt_wvr_f AS STRING) AS dbt_wvr_f,
        CAST(ar_pps_by_idy AS STRING) AS ar_pps_by_idy,
        CAST(ar_pps_by_pd AS STRING) AS ar_pps_by_pd,
        CAST(dsbr_prpsl_ofcr AS STRING) AS dsbr_prpsl_ofcr,
        CAST(dsbr_prpsl_mgr AS STRING) AS dsbr_prpsl_mgr,
        CAST(mgt_ofcr AS STRING) AS mgt_ofcr,
        CAST(mgt_mgr AS STRING) AS mgt_mgr,
        CAST(aprv_ahr AS STRING) AS aprv_ahr,
        CAST(chker_ofcr AS STRING) AS chker_ofcr,
        CAST(maker_ofcr AS STRING) AS maker_ofcr,
        CAST(refrrer_ofcr AS STRING) AS refrrer_ofcr,
        CAST(prom_prgm AS STRING) AS prom_prgm,
        CAST(prom_prgm_2 AS STRING) AS prom_prgm_2,
        CAST(dbt_rstc_tp_code AS STRING) AS dbt_rstc_tp_code,
        CAST(covid19_rstc_compl_dt AS DATE) AS covid19_rstc_compl_dt,
        CAST(gl_itm_code AS STRING) AS gl_itm_code,
        CAST(gl_itm_id AS STRING) AS gl_itm_id,
        CAST(fnc_st_code AS STRING) AS fnc_st_code,
        CAST(bds_tt11 AS STRING) AS bds_tt11
    FROM unioned
)
{{ scd2(['ar_id']) }}
