{#-
    PG_SILVER.LOAN_AR — sheet 'Loan Arrangement', SCD TYPE 2 (macro scd2). Khóa tự nhiên AR_ID.
    3 nhánh UNION ALL (mỗi nhánh 1 dòng / AR_ID, không trùng khóa giữa các nhánh):
      - LD     : T24CORE_LD_LOANS_AND_DEPOSITS (hợp đồng đang sống).
      - LD_HIS : phiên bản CURR_NO lớn nhất của hợp đồng không có bản REVE và đã rời LD.
      - PD     : T24CORE_PD_PAYMENT_DUE (FLAG_STATUS <> 'DELETE') + PD_PAYMENT_DUE_MV gom theo RECID.
                 AR_CODE = SUBSTR(RECID,1,14) ('PDLD...') -> khác khóa LD, đúng sheet.
    Bảng phụ LD/LD_HIS: m (CONTRACT_MASTER, VERSION_NO lớn nhất), td (LOS_CONTRACT_FIELDS_TDATE, MOV_DATE = ngày giá trị),
    ld_los -> los -> pd_los (LOS), i (CUSTOMER).
    Khác Excel:
      - Mọi bảng lọc ETL_DATE; subquery MAX -> ROW_NUMBER; bảng phụ lấy 1 dòng / khóa join (tránh nhân dòng).
      - FRST_OU_CODE: CO_CODE đầu tiên trên LD ∪ LD_HIS (theo ghi chú sheet), không chỉ trong LD.
      - PD có dòng trùng RECID -> lấy CURR_NO lớn nhất; PAYMENT_DTE_DUE đa giá trị '#' -> 8 ký tự đầu (theo sheet).
      - PD_MV: MAX(APPROVE_AMOUNT) tính trên số, không trên chuỗi.
    Định dạng Bronze: MOV_DATE / BOOKING_DATE (FLEXBO, LOS) 'yyyy-MM-dd HH:mm:ss.SSS'; ngày T24 yyyyMMdd.
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

ldh_all AS (
    SELECT
        h.*, SPLIT_PART(TRIM(h.recid), ';', 1) AS ar_code,
        ROW_NUMBER() OVER (
            PARTITION BY SPLIT_PART(TRIM(h.recid), ';', 1)
            ORDER BY TRY_CAST(TRIM(h.curr_no) AS INTEGER) DESC
        ) AS rn,
        MAX(CASE WHEN TRIM(h.record_status) = 'REVE' THEN 1 ELSE 0 END)
            OVER (PARTITION BY SPLIT_PART(TRIM(h.recid), ';', 1)) AS has_reve
    FROM {{ ref('t24core_ld_loans_and_deposits_his') }} AS h
    WHERE
        h.etl_date = {{ etl_date() }}
        AND NULLIF(SPLIT_PART(TRIM(h.recid), ';', 1), '') IS NOT NULL
),

ldh AS (
    SELECT h.*, {{ t24_date("COALESCE(NULLIF(TRIM(h.orig_val_date), ''), h.value_date)") }} AS val_key_dt
    FROM ldh_all AS h
    WHERE
        h.rn = 1
        AND h.has_reve = 0
        AND NOT EXISTS (SELECT 1 FROM ld WHERE ld.ar_code = h.ar_code)
),

frst AS (
    -- Chi nhánh mở đầu tiên của hợp đồng trên LD ∪ LD_HIS.
    SELECT ar_code, MIN_BY(co_code, ord) AS frst_ou_code
    FROM (
        SELECT
            ar_code, TRIM(co_code) AS co_code,
            STRUCT({{ t24_date('value_date') }} AS d, TRY_CAST(TRIM(curr_no) AS INTEGER) AS n) AS ord
        FROM ld
        UNION ALL
        SELECT ar_code, TRIM(co_code), STRUCT({{ t24_date('value_date') }}, TRY_CAST(TRIM(curr_no) AS INTEGER))
        FROM ldh_all
    )
    GROUP BY ar_code
),

m AS (
    SELECT contract_ref_no, booking_date
    FROM (
        SELECT
            TRIM(x.contract_ref_no) AS contract_ref_no,
            TRY_CAST(SUBSTR(TRIM(x.booking_date), 1, 10) AS DATE) AS booking_date,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(x.contract_ref_no)
                ORDER BY TRY_CAST(TRIM(x.version_no) AS INTEGER) DESC
            ) AS rn
        FROM {{ ref('flexbo_pgb_ldtb_contract_master') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

td AS (
    SELECT contract_ref_no, mov_date, san_pham_cho_vay_khcn, san_pham_cho_vay_khdn, mdvay_sp
    FROM (
        SELECT
            TRIM(x.contract_ref_no) AS contract_ref_no,
            TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) AS mov_date,
            TRIM(x.san_pham_cho_vay_khcn) AS san_pham_cho_vay_khcn,
            TRIM(x.san_pham_cho_vay_khdn) AS san_pham_cho_vay_khdn,
            TRIM(x.mdvay_sp) AS mdvay_sp,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(x.contract_ref_no), SUBSTR(TRIM(x.mov_date), 1, 10)
                ORDER BY x.mov_date DESC
            ) AS rn
        FROM {{ ref('flexbo_pgb_los_contract_fields_tdate') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

los_pd AS (
    -- ld_los -> los -> pd_los: 1 mã sản phẩm LOS / (hợp đồng, ngày giải ngân).
    SELECT ext_ref_no_1, booking_date, product_code
    FROM (
        SELECT
            TRIM(d.ext_ref_no_1) AS ext_ref_no_1,
            TRY_CAST(SUBSTR(TRIM(d.booking_date), 1, 10) AS DATE) AS booking_date,
            TRIM(p.product_code) AS product_code,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(d.ext_ref_no_1), SUBSTR(TRIM(d.booking_date), 1, 10)
                ORDER BY TRY_CAST(TRIM(p.id) AS BIGINT) DESC
            ) AS rn
        FROM {{ ref('los_app_loan_disbursement') }} AS d
        LEFT JOIN {{ ref('los_app_facility') }} AS f
            ON TRIM(f.id) = TRIM(d.facility_id) AND f.etl_date = {{ etl_date() }}
        LEFT JOIN {{ ref('los_app_product') }} AS p
            ON TRIM(p.id) = TRIM(f.product_id) AND p.etl_date = {{ etl_date() }}
        WHERE
            d.etl_date = {{ etl_date() }}
            AND TRIM(d.amnd_state) = 'F'
            AND TRIM(d.status) IN ('A', 'U')
    )
    WHERE rn = 1
),

cus AS (
    SELECT TRIM(c.recid) AS recid, MAX(TRIM(c.khoi)) AS khoi
    FROM {{ ref('t24core_customer') }} AS c
    WHERE c.etl_date = {{ etl_date() }}
    GROUP BY TRIM(c.recid)
),

ld_ldh AS (
    -- LD và LD_HIS cùng khuôn cột; cột LD_HIS không có -> NULL (theo sheet).
    SELECT
        'T24_LD_LOANS_AND_DEPOSITS' AS src_stm_code, ar_code, acc_fcc, approve_amount, authoriser, category, cra_ld,
        currency, customer_id, drawdown_net_amt, excg_rate, fcc_limit, fin_mat_date, inputter, limit_reference,
        loc_term, los_fac_code, mb_rm_bancheo, orig_val_date, productgr_code, use_of_loan, use_of_loan_cha,
        value_date, val_key_dt
    FROM ld
    UNION ALL
    SELECT
        'T24_LD_LOANS_AND_DEPOSITS_HIS', ar_code, acc_fcc, approve_amount, NULL, category, cra_ld,
        currency, customer_id, drawdown_net_amt, excg_rate, NULL, fin_mat_date, NULL, NULL,
        loc_term, NULL, mb_rm_bancheo, orig_val_date, NULL, use_of_loan, use_of_loan_cha,
        value_date, val_key_dt
    FROM ldh
),

x_branch AS (
    SELECT
        x.src_stm_code,
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'x.ar_code') }} AS ar_id,
        x.ar_code,
        TRIM(x.acc_fcc) AS fcc_ar_code,
        TRY_CAST(TRIM(x.approve_amount) AS DECIMAL(25, 5)) AS orig_amt_fcy,
        TRIM(x.authoriser) AS chker_ofcr_code,
        TRIM(x.category) AS pd_cgy_code,
        frst.frst_ou_code,
        TRIM(x.cra_ld) AS ppr_ctr_nbr,
        TRIM(x.currency) AS ccy_code,
        TRIM(x.customer_id) AS cst_code,
        {{ fn_hash('T24_CUSTOMER', 'x.customer_id') }} AS cst_id,
        TRY_CAST(TRIM(x.drawdown_net_amt) AS DECIMAL(25, 5)) AS dsbr_amt_fcy,
        TRY_CAST(TRIM(x.excg_rate) AS DECIMAL(25, 7)) AS exg_rate_to_lcl_ccy,
        TRIM(x.fcc_limit) AS fcc_lmt_code,
        {{ t24_date('x.fin_mat_date') }} AS mat_dt,
        TRIM(x.inputter) AS maker_ofcr_code,
        TRIM(x.limit_reference) AS lmt_code,
        {{ fn_hash('T24_LIMIT', 'x.limit_reference') }} AS lmt_id,
        TRIM(x.loc_term) AS term_code,
        TRIM(x.los_fac_code) AS los_ctr_nbr,
        TRIM(x.mb_rm_bancheo) AS refrrer_ofcr_code,
        {{ t24_date('x.orig_val_date') }} AS val_dt,
        CASE
            WHEN x.acc_fcc IS NOT NULL AND cus.khoi = 'INDIV' THEN td.san_pham_cho_vay_khcn
            WHEN x.acc_fcc IS NOT NULL AND cus.khoi <> 'INDIV' THEN td.san_pham_cho_vay_khdn
            ELSE COALESCE(los_pd.product_code, TRIM(x.productgr_code))
        END AS pd_code,
        COALESCE(td.mdvay_sp, TRIM(x.use_of_loan)) AS ar_pps_tp_code,
        TRIM(x.use_of_loan_cha) AS ar_pps_grp_code,
        {{ t24_date('x.value_date') }} AS eff_dt,
        m.booking_date AS fcc_val_dt
    FROM ld_ldh AS x
    LEFT JOIN frst ON frst.ar_code = x.ar_code
    LEFT JOIN m ON m.contract_ref_no = TRIM(x.acc_fcc)
    LEFT JOIN td ON td.contract_ref_no = x.ar_code AND td.mov_date = x.val_key_dt
    LEFT JOIN los_pd ON los_pd.ext_ref_no_1 = x.ar_code AND los_pd.booking_date = x.val_key_dt
    LEFT JOIN cus ON cus.recid = TRIM(x.customer_id)
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
    SELECT
        TRIM(x.recid) AS recid,
        MAX(TRIM(x.acc_fcc)) AS acc_fcc,
        MAX(TRY_CAST(TRIM(x.approve_amount) AS DECIMAL(25, 5))) AS approve_amount,
        MAX(TRIM(x.category)) AS category,
        MAX(TRIM(x.co_code)) AS co_code,
        MAX({{ t24_date('x.final_due_date') }}) AS final_due_date,
        MAX({{ t24_date('x.original_mat') }}) AS original_mat
    FROM {{ ref('t24core_pd_payment_due_mv') }} AS x
    WHERE
        x.etl_date = {{ etl_date() }}
        AND COALESCE(x.flag_status, '_') <> 'DELETE'
    GROUP BY TRIM(x.recid)
),

unioned AS (
    SELECT * FROM x_branch
    UNION ALL
    SELECT
        'T24_PD_PAYMENT_DUE',
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'pd.ar_code') }},
        pd.ar_code,
        d1.acc_fcc,
        d1.approve_amount,
        TRIM(pd.authoriser),
        d1.category,
        d1.co_code,
        TRIM(pd.cra_ld),
        NULL,
        TRIM(pd.customer),
        {{ fn_hash('T24_CUSTOMER', 'pd.customer') }},
        NULL,
        NULL,
        NULL,
        d1.final_due_date,
        TRIM(pd.inputter),
        TRIM(pd.limit_reference),
        {{ fn_hash('T24_LIMIT', 'pd.limit_reference') }},
        NULL,
        TRIM(pd.los_fac_code),
        NULL,
        COALESCE({{ t24_date('pd.original_mat') }}, d1.original_mat),
        NULL,
        TRIM(pd.use_of_loan),
        TRIM(pd.use_of_loan_cha),
        {{ t24_date('SUBSTR(TRIM(pd.payment_dte_due), 1, 8)') }},
        NULL
    FROM pd
    LEFT JOIN pd_mv AS d1 ON d1.recid = TRIM(pd.recid)
),

src AS (
    SELECT
        CAST(src_stm_code AS STRING) AS src_stm_code,
        CAST(ar_id AS STRING) AS ar_id,
        CAST(ar_code AS STRING) AS ar_code,
        CAST(fcc_ar_code AS STRING) AS fcc_ar_code,
        CAST(orig_amt_fcy AS DECIMAL(25, 5)) AS orig_amt_fcy,
        CAST(chker_ofcr_code AS STRING) AS chker_ofcr_code,
        CAST(pd_cgy_code AS STRING) AS pd_cgy_code,
        CAST(frst_ou_code AS STRING) AS frst_ou_code,
        CAST(ppr_ctr_nbr AS STRING) AS ppr_ctr_nbr,
        CAST(ccy_code AS STRING) AS ccy_code,
        CAST(cst_code AS STRING) AS cst_code,
        CAST(cst_id AS STRING) AS cst_id,
        CAST(dsbr_amt_fcy AS DECIMAL(25, 5)) AS dsbr_amt_fcy,
        CAST(exg_rate_to_lcl_ccy AS DECIMAL(25, 7)) AS exg_rate_to_lcl_ccy,
        CAST(fcc_lmt_code AS STRING) AS fcc_lmt_code,
        CAST(mat_dt AS DATE) AS mat_dt,
        CAST(maker_ofcr_code AS STRING) AS maker_ofcr_code,
        CAST(lmt_code AS STRING) AS lmt_code,
        CAST(lmt_id AS STRING) AS lmt_id,
        CAST(term_code AS STRING) AS term_code,
        CAST(los_ctr_nbr AS STRING) AS los_ctr_nbr,
        CAST(refrrer_ofcr_code AS STRING) AS refrrer_ofcr_code,
        CAST(val_dt AS DATE) AS val_dt,
        CAST(pd_code AS STRING) AS pd_code,
        CAST(ar_pps_tp_code AS STRING) AS ar_pps_tp_code,
        CAST(ar_pps_grp_code AS STRING) AS ar_pps_grp_code,
        CAST(eff_dt AS DATE) AS eff_dt,
        CAST(fcc_val_dt AS DATE) AS fcc_val_dt
    FROM unioned
)
{{ scd2(['ar_id']) }}
