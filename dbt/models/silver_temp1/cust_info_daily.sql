{#-
    PG_SILVER.CUST_INFO_DAILY — sheet 'CUST_INFO_DAILY', SNAPSHOT theo ETL_DATE (khuôn: exg_rate.sql).
    Bảng chính SMY_STMT_DAILY (bút toán ngày BOOKING_DATE = ngày batch), LEFT JOIN 9 bảng FLEXBO / EBANKING / LOS.
    Chạy lại cùng ngày thay thế partition ETL_DATE đó (delete+insert).
    Khác Excel (đã thống nhất / theo dữ liệu Bronze thực tế):
      - Mọi bảng nguồn lọc ETL_DATE (Bronze giữ nhiều partition; Excel thiếu ở m, col_udf, ld_los).
      - m: lấy VERSION_NO lớn nhất bằng ROW_NUMBER thay subquery tương quan.
      - udf_h, rt_h là bảng lịch sử: lấy bản MOV_DATE mới nhất <= ngày nghiệp vụ / hợp đồng (Excel join toàn bộ
        lịch sử -> nhân dòng). udf (CONTRACT_UDF_MAP) dạng EAV giữ nguyên: 1 dòng / FIELD_NAME như đặc tả.
      - Định dạng ngày Bronze khác 'YYYYMMDD' của Excel: MOV_DATE / BOOKING_DATE (FLEXBO, LOS) là
        'yyyy-MM-dd HH:mm:ss.SSS', NGAY_HET_COVID19 'dd/MM/yyyy', DATE_TIME 'yyMMddHHmm',
        COMMIT_TS 'dd-MON-yy hh.mi.ss.ffffff AM'.
      - Ngày nghiệp vụ = macro biz_date() (mặc định = etl_date); dữ liệu Bronze hiện chỉ có BOOKING_DATE
        2025-09..2025-10 nên test bằng --vars '{etl_date: ..., biz_date: 2025-09-26}'.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='etl_date',
    properties={"partitioning": "ARRAY['etl_date']"},
    on_schema_change='fail'
) }}

WITH stmt AS (
    SELECT s.*
    FROM {{ source('pg_bronze', 'smy_stmt_daily') }} AS s
    WHERE s.etl_date = {{ etl_date() }}
      AND {{ t24_date('s.booking_date') }} = {{ biz_date() }}
),

m AS (
    SELECT *
    FROM (
        SELECT x.*,
               ROW_NUMBER() OVER (
                   PARTITION BY TRIM(x.contract_ref_no)
                   ORDER BY TRY_CAST(TRIM(x.version_no) AS DECIMAL(10)) DESC
               ) AS rn
        FROM {{ source('pg_bronze', 'flexbo_pgb_ldtb_contract_master') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
    )
    WHERE rn = 1
),

td AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'flexbo_pgb_los_contract_fields_tdate') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) = {{ biz_date() }}
),

udf AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'flexbo_pgb_contract_udf_map') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

udf_h AS (
    SELECT *
    FROM (
        SELECT x.*,
               ROW_NUMBER() OVER (
                   PARTITION BY TRIM(x.contract_ref_no)
                   ORDER BY TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) DESC
               ) AS rn
        FROM {{ source('pg_bronze', 'flexbo_pgbld_contract_udfield_hist') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) <= {{ biz_date() }}
    )
    WHERE rn = 1
),

rt_h AS (
    SELECT *
    FROM (
        SELECT x.*,
               ROW_NUMBER() OVER (
                   PARTITION BY TRIM(x.contract_ref_no)
                   ORDER BY TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) DESC
               ) AS rn
        FROM {{ source('pg_bronze', 'flexbo_pgbld_rt_contract_udfield_hist') }} AS x
        WHERE x.etl_date = {{ etl_date() }}
          AND TRY_CAST(SUBSTR(TRIM(x.mov_date), 1, 10) AS DATE) <= {{ biz_date() }}
    )
    WHERE rn = 1
),

col_udf AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'ebanking_col_udf_value') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND TRIM(x.udf_id) = 'NHANNO_BATBUOC'
),

ld_los AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'los_app_loan_disbursement') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
      AND TRIM(x.amnd_state) = 'F'
      AND TRIM(x.status) IN ('A', 'U')
),

fac AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'los_app_facility') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
),

pd_los AS (
    SELECT x.*
    FROM {{ source('pg_bronze', 'los_app_product') }} AS x
    WHERE x.etl_date = {{ etl_date() }}
)

SELECT
    CAST(TRIM(col_udf.col_ref) AS VARCHAR)                                   AS col_ref,
    CAST(TRIM(col_udf.function_code) AS VARCHAR)                             AS function_code,
    CAST(TRIM(col_udf.udf_value) AS VARCHAR)                                 AS udf_value,
    CAST(TRIM(udf.contract_ref_no) AS VARCHAR)                               AS udf_map_contract_ref_no,
    CAST(TRIM(udf.field_name) AS VARCHAR)                                    AS field_name,
    CAST(TRIM(udf.field_val) AS VARCHAR)                                     AS field_val,
    TRY_CAST(SUBSTR(TRIM(m.booking_date), 1, 10) AS DATE)                    AS fcc_booking_date,
    CAST(TRIM(m.contract_ref_no) AS VARCHAR)                                 AS fcc_contract_ref_no,
    COALESCE(TRY_CAST(TRIM(m.version_no) AS DECIMAL(10, 0)), 0)              AS version_no,
    CAST(TRIM(td.can_bo_de_xuat_gn) AS VARCHAR)                              AS can_bo_de_xuat_gn,
    CAST(TRIM(td.car_application_code) AS VARCHAR)                           AS car_application_code,
    CAST(TRIM(td.contract_ref_no) AS VARCHAR)                                AS los_td_contract_ref_no,
    CAST(TRIM(td.los_contract_code) AS VARCHAR)                              AS los_contract_code,
    CAST(TRIM(td.mdvay_nkt) AS VARCHAR)                                      AS mdvay_nkt,
    CAST(TRIM(td.mdvay_sp) AS VARCHAR)                                       AS mdvay_sp,
    TRY_CAST(SUBSTR(TRIM(td.mov_date), 1, 10) AS DATE)                       AS los_td_mov_date,
    CAST(TRIM(td.tt_pp_de_xuat_gn) AS VARCHAR)                               AS tt_pp_de_xuat_gn,
    CAST(TRIM(udf_h.contract_ref_no) AS VARCHAR)                             AS udfh_contract_ref_no,
    CAST(TRIM(udf_h.ct_khuyen_mai_cho_vay) AS VARCHAR)                       AS ct_khuyen_mai_cho_vay,
    CAST(TRIM(udf_h.ctkm2) AS VARCHAR)                                       AS ctkm2,
    TRY_CAST(SUBSTR(TRIM(udf_h.mov_date), 1, 10) AS DATE)                    AS udfh_mov_date,
    CAST(TRIM(rt_h.co_cau_no) AS VARCHAR)                                    AS co_cau_no,
    CAST(TRIM(rt_h.contract_ref_no) AS VARCHAR)                              AS rth_contract_ref_no,
    CAST(TRY(DATE_PARSE(NULLIF(TRIM(rt_h.ngay_het_covid19), ''), '%d/%m/%Y')) AS DATE) AS ngay_het_covid19,
    CAST(TRIM(fac.id) AS VARCHAR)                                            AS fac_id,
    CAST(TRIM(fac.product_id) AS VARCHAR)                                    AS product_id,
    CAST(TRIM(ld_los.amnd_state) AS VARCHAR)                                 AS amnd_state,
    TRY_CAST(SUBSTR(TRIM(ld_los.booking_date), 1, 10) AS DATE)               AS los_dsbr_booking_date,
    CAST(TRIM(ld_los.ext_ref_no_1) AS VARCHAR)                               AS ext_ref_no_1,
    CAST(TRIM(ld_los.facility_id) AS VARCHAR)                                AS facility_id,
    CAST(TRIM(ld_los.status) AS VARCHAR)                                     AS status,
    CAST(TRIM(pd_los.id) AS VARCHAR)                                         AS prod_id,
    CAST(TRIM(pd_los.product_code) AS VARCHAR)                               AS product_code,
    CAST(TRIM(pd_los.product_name) AS VARCHAR)                               AS product_name,
    CAST(TRIM(stmt.account) AS VARCHAR)                                      AS account,
    CAST(TRIM(stmt.account_id) AS VARCHAR)                                   AS account_id,
    CAST(TRIM(stmt.account_num) AS VARCHAR)                                  AS account_num,
    CAST(TRIM(stmt.account_number) AS VARCHAR)                               AS account_number,
    {{ t24_date('stmt.accounting_date') }}                                   AS accounting_date,
    CAST(TRIM(stmt.acct_id) AS VARCHAR)                                      AS acct_id,
    COALESCE(TRY_CAST(TRIM(stmt.amount_fcy) AS DECIMAL(25, 5)), 0)           AS amount_fcy,
    COALESCE(TRY_CAST(TRIM(stmt.amount_lcy) AS DECIMAL(25, 5)), 0)           AS amount_lcy,
    CAST(TRIM(stmt.balance_type) AS VARCHAR)                                 AS balance_type,
    {{ t24_date('stmt.booking_date') }}                                      AS booking_date,
    CAST(TRIM(stmt.card_number) AS VARCHAR)                                  AS card_number,
    CAST(TRIM(stmt.co_code) AS VARCHAR)                                      AS co_code,
    CAST(TRIM(stmt.commit_action) AS VARCHAR)                                AS commit_action,
    TRY(DATE_PARSE(NULLIF(TRIM(stmt.commit_ts), ''), '%d-%b-%y %h.%i.%s.%f %p')) AS commit_ts,
    CAST(TRIM(stmt.company_code) AS VARCHAR)                                 AS company_code,
    CAST(TRIM(stmt.consol_key) AS VARCHAR)                                   AS consol_key,
    CAST(TRIM(stmt.contract_bal_id) AS VARCHAR)                              AS contract_bal_id,
    CAST(TRIM(stmt.crf_prod_cat) AS VARCHAR)                                 AS crf_prod_cat,
    CAST(TRIM(stmt.crf_type) AS VARCHAR)                                     AS crf_type,
    COALESCE(TRY_CAST(TRIM(stmt.curr_no) AS DECIMAL(10, 0)), 0)              AS curr_no,
    CAST(TRIM(stmt.currency) AS VARCHAR)                                     AS currency,
    CAST(TRIM(stmt.customer_id) AS VARCHAR)                                  AS customer_id,
    {{ t24_date('stmt.cycle_forward') }}                                     AS cycle_forward,
    CAST({{ t24_datetime('stmt.date_time') }} AS DATE)                       AS date_time,
    CAST(TRIM(stmt.department_code) AS VARCHAR)                              AS department_code,
    CAST(TRIM(stmt.drawn_account) AS VARCHAR)                                AS drawn_account,
    COALESCE(TRY_CAST(TRIM(stmt.exchange_rate) AS DECIMAL(13, 7)), 0)        AS exchange_rate,
    CAST(TRIM(stmt.internal_category) AS VARCHAR)                            AS internal_category,
    CAST(TRIM(stmt.local_ref) AS VARCHAR)                                    AS local_ref,
    {{ etl_date() }}                                                         AS etl_date
FROM stmt
LEFT JOIN m       ON TRIM(m.contract_ref_no) = TRIM(stmt.our_reference)
LEFT JOIN td      ON TRIM(td.contract_ref_no) = TRIM(stmt.our_reference)
LEFT JOIN udf     ON TRIM(udf.contract_ref_no) = TRIM(m.contract_ref_no)
LEFT JOIN udf_h   ON TRIM(udf_h.contract_ref_no) = TRIM(m.contract_ref_no)
LEFT JOIN rt_h    ON TRIM(rt_h.contract_ref_no) = TRIM(m.contract_ref_no)
LEFT JOIN col_udf ON TRIM(col_udf.col_ref) = TRIM(m.contract_ref_no)
LEFT JOIN ld_los  ON TRIM(ld_los.ext_ref_no_1) = TRIM(stmt.our_reference)
LEFT JOIN fac     ON TRIM(fac.id) = TRIM(ld_los.facility_id)
LEFT JOIN pd_los  ON TRIM(pd_los.id) = TRIM(fac.product_id)
