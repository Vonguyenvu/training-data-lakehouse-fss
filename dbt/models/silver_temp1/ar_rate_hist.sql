{#-
    PG_SILVER.AR_RATE_HIST — sheet 'Arrangement Rate History', SCD TYPE 2 (khuôn: ip_elc_adr.sql).
    Khóa tự nhiên AR_ID; đổi bất kỳ cột lãi suất nào -> đóng dòng cũ, mở phiên bản mới.
    3 nguồn của sheet, gộp về 1 dòng / AR_ID (MERGE SCD2 cần khóa duy nhất mỗi ngày):
      - LD     : T24CORE_LD_LOANS_AND_DEPOSITS (hợp đồng đang sống).
      - LD_HIS : phiên bản CURR_NO lớn nhất của hợp đồng đã rời LD và không có bản REVE.
                 Sheet ghi "Khởi tạo" nhưng chạy mọi ngày: đã loại hợp đồng còn trong LD nên không trùng,
                 và giữ được phiên bản cuối của hợp đồng vừa tất toán.
      - PD     : T24CORE_PD_PAYMENT_DUE, chỉ có PE_RATE/PS_RATE; LD/LD_HIS ưu tiên, PD bù khi NULL
                 hoặc khi hợp đồng chỉ có ở PD.
    Khác Excel (đã thống nhất): khóa nhánh PD dùng SUBSTR(d.RECID, 3, 12) thay vì SUBSTR(d.RECID, 1, 14):
      RECID PD dạng 'PDLD2524400302' -> (1,14) là cả chuỗi, không bao giờ khớp AR_ID của LD ('LD2524400302').
    Bronze: MOV_DATE là chuỗi 'yyyy-MM-dd HH:mm:ss.SSS'; PD có dòng trùng RECID (cùng lãi suất) -> GROUP BY.
    Phải chạy ETL_DATE tăng dần.
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['ar_id', 'sys_eff_dt'],
    on_schema_change='fail'
) }}

WITH td AS (
    SELECT
        TRIM(d.contract_ref_no)                                   AS contract_ref_no,
        TRY_CAST(SUBSTR(TRIM(d.mov_date), 1, 10) AS DATE)         AS mov_date,
        TRY_CAST(TRIM(d.bien_do_thay_doi_ls_theo_hdtd) AS DECIMAL(25, 7)) AS mrgn_rate
    FROM {{ source('pg_bronze', 'flexbo_pgb_los_contract_fields_tdate') }} AS d
    WHERE d.etl_date = {{ etl_date() }}
),

ld AS (
    SELECT
        TRIM(a.recid)                                             AS ar_code,
        TRIM(a.int_rate_type)                                     AS int_rate_variablity_tp_code,
        {{ t24_date('a.int_value_date') }}                        AS int_rate_eff_dt,
        TRY_CAST(TRIM(a.interest_rate) AS DECIMAL(25, 7))         AS eff_rate_pct,
        TRY_CAST(TRIM(a.interest_spread) AS DECIMAL(25, 7))       AS sprd_rate_pct,
        TRY_CAST(TRIM(a.pe_rate) AS DECIMAL(25, 7))               AS pny_rate,
        TRY_CAST(TRIM(a.ps_rate) AS DECIMAL(25, 7))               AS odue_int_rate,
        {{ t24_date("COALESCE(NULLIF(TRIM(a.orig_val_date), ''), a.value_date)") }} AS val_dt
    FROM {{ source('pg_bronze', 't24core_ld_loans_and_deposits') }} AS a
    WHERE a.etl_date = {{ etl_date() }}
      AND NULLIF(TRIM(a.recid), '') IS NOT NULL
),

ldh_all AS (
    SELECT
        SPLIT_PART(TRIM(h.recid), ';', 1)                         AS ar_code,
        h.*,
        ROW_NUMBER() OVER (
            PARTITION BY SPLIT_PART(TRIM(h.recid), ';', 1)
            ORDER BY TRY_CAST(TRIM(h.curr_no) AS INTEGER) DESC
        )                                                         AS rn,
        MAX(CASE WHEN TRIM(h.record_status) = 'REVE' THEN 1 ELSE 0 END) OVER (
            PARTITION BY SPLIT_PART(TRIM(h.recid), ';', 1)
        )                                                         AS has_reve
    FROM {{ source('pg_bronze', 't24core_ld_loans_and_deposits_his') }} AS h
    WHERE h.etl_date = {{ etl_date() }}
      AND NULLIF(SPLIT_PART(TRIM(h.recid), ';', 1), '') IS NOT NULL
),

ldh AS (
    SELECT
        h.ar_code,
        TRIM(h.int_rate_type)                                     AS int_rate_variablity_tp_code,
        {{ t24_date('h.int_value_date') }}                        AS int_rate_eff_dt,
        TRY_CAST(TRIM(h.interest_rate) AS DECIMAL(25, 7))         AS eff_rate_pct,
        TRY_CAST(TRIM(h.interest_spread) AS DECIMAL(25, 7))       AS sprd_rate_pct,
        CAST(NULL AS DECIMAL(25, 7))                              AS pny_rate,       -- sheet: NULL
        CAST(NULL AS DECIMAL(25, 7))                              AS odue_int_rate,  -- sheet: NULL
        {{ t24_date("COALESCE(NULLIF(TRIM(h.orig_val_date), ''), h.value_date)") }} AS val_dt
    FROM ldh_all AS h
    WHERE h.rn = 1
      AND h.has_reve = 0
      AND NOT EXISTS (SELECT 1 FROM ld WHERE ld.ar_code = h.ar_code)
),

ld_ldh AS (
    SELECT x.*, td.mrgn_rate
    FROM (SELECT * FROM ld UNION ALL SELECT * FROM ldh) AS x
    LEFT JOIN td ON td.contract_ref_no = x.ar_code AND td.mov_date = x.val_dt
),

pd AS (
    SELECT
        SUBSTR(TRIM(p.recid), 3, 12)                              AS ar_code,
        MAX(TRY_CAST(TRIM(p.pe_rate) AS DECIMAL(25, 7)))          AS pny_rate,
        MAX(TRY_CAST(TRIM(p.ps_rate) AS DECIMAL(25, 7)))          AS odue_int_rate
    FROM {{ source('pg_bronze', 't24core_pd_payment_due') }} AS p
    WHERE p.etl_date = {{ etl_date() }}
      AND NULLIF(SUBSTR(TRIM(p.recid), 3, 12), '') IS NOT NULL
    GROUP BY 1
),

src AS (
    SELECT
        {{ fn_hash('T24_LD_LOANS_AND_DEPOSITS', 'COALESCE(l.ar_code, p.ar_code)') }} AS ar_id,
        COALESCE(l.ar_code, p.ar_code)                            AS ar_code,
        l.int_rate_variablity_tp_code,
        l.int_rate_eff_dt,
        l.eff_rate_pct,
        l.sprd_rate_pct,
        COALESCE(l.pny_rate, p.pny_rate)                          AS pny_rate,
        COALESCE(l.odue_int_rate, p.odue_int_rate)                AS odue_int_rate,
        l.mrgn_rate
    FROM ld_ldh AS l
    FULL JOIN pd AS p ON p.ar_code = l.ar_code
),

{% if is_incremental() %}
cur AS (
    SELECT * FROM {{ this }} WHERE sys_exp_dt IS NULL
),

new_ver AS (
    SELECT s.*,
           {{ etl_date() }}   AS sys_eff_dt,
           CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN cur AS c ON c.ar_id = s.ar_id
    WHERE c.ar_id IS NULL
       OR s.int_rate_variablity_tp_code IS DISTINCT FROM c.int_rate_variablity_tp_code
       OR s.int_rate_eff_dt IS DISTINCT FROM c.int_rate_eff_dt
       OR s.eff_rate_pct IS DISTINCT FROM c.eff_rate_pct
       OR s.sprd_rate_pct IS DISTINCT FROM c.sprd_rate_pct
       OR s.pny_rate IS DISTINCT FROM c.pny_rate
       OR s.odue_int_rate IS DISTINCT FROM c.odue_int_rate
       OR s.mrgn_rate IS DISTINCT FROM c.mrgn_rate
),

closed AS (
    SELECT c.ar_id, c.ar_code, c.int_rate_variablity_tp_code, c.int_rate_eff_dt,
           c.eff_rate_pct, c.sprd_rate_pct, c.pny_rate, c.odue_int_rate, c.mrgn_rate,
           c.sys_eff_dt,
           {{ etl_date() }} AS sys_exp_dt
    FROM cur AS c
    LEFT JOIN src AS s ON s.ar_id = c.ar_id
    WHERE c.sys_eff_dt < {{ etl_date() }}
      AND (
            (s.ar_id IS NULL AND EXISTS (SELECT 1 FROM ld))
         OR s.int_rate_variablity_tp_code IS DISTINCT FROM c.int_rate_variablity_tp_code
         OR s.int_rate_eff_dt IS DISTINCT FROM c.int_rate_eff_dt
         OR s.eff_rate_pct IS DISTINCT FROM c.eff_rate_pct
         OR s.sprd_rate_pct IS DISTINCT FROM c.sprd_rate_pct
         OR s.pny_rate IS DISTINCT FROM c.pny_rate
         OR s.odue_int_rate IS DISTINCT FROM c.odue_int_rate
         OR s.mrgn_rate IS DISTINCT FROM c.mrgn_rate
      )
),

final AS (
    SELECT * FROM new_ver
    UNION ALL
    SELECT * FROM closed
)
{% else %}
final AS (
    SELECT src.*,
           {{ etl_date() }}   AS sys_eff_dt,
           CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}

SELECT
    CAST(ar_id AS VARCHAR)                       AS ar_id,
    CAST(ar_code AS VARCHAR)                     AS ar_code,
    CAST(int_rate_variablity_tp_code AS VARCHAR) AS int_rate_variablity_tp_code,
    CAST(int_rate_eff_dt AS DATE)                AS int_rate_eff_dt,
    CAST(eff_rate_pct AS DECIMAL(25, 7))         AS eff_rate_pct,
    CAST(sprd_rate_pct AS DECIMAL(25, 7))        AS sprd_rate_pct,
    CAST(pny_rate AS DECIMAL(25, 7))             AS pny_rate,
    CAST(odue_int_rate AS DECIMAL(25, 7))        AS odue_int_rate,
    CAST(mrgn_rate AS DECIMAL(25, 7))            AS mrgn_rate,
    sys_eff_dt,
    sys_exp_dt,
    {{ etl_date() }}                             AS sys_udt_dt,
    {{ etl_date() }}                             AS etl_date
FROM final
