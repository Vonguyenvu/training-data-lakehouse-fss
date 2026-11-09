{#-
    PG_GOLD.INF_CST — sheet 'Interface Customer', SNAPSHOT theo ETL_DATE (khuôn: silver_temp1/exg_rate.sql).
    2 nhánh UNION ALL trên PG_SILVER.CST a (SYS_EXP_DT IS NULL):
      - Cá nhân: INNER JOIN IDV_PRFL e, LEFT JOIN IDV_EMP_ST f.
      - Tổ chức: INNER JOIN ORG_PRFL e (cột riêng của cá nhân -> NULL và ngược lại, đúng Transform của sheet).
    Chung 2 nhánh: IP_ALT_IDENTN b (1 giấy tờ / CIF: IDENTN_ISSU_DT mới nhất), IP_ELC_ADR c1/c2/c3 (EMAIL / HOME / MOBILE),
    IP_PST_ADR d1/d2 (CURRENT / PERMANENT ADDRESS). Mọi bảng SCD2 lọc SYS_EXP_DT IS NULL; join theo CST_CODE.
    CDR_DT = ETL_DATE. Chạy lại cùng ngày thay thế partition ETL_DATE đó (insert_overwrite).
-#}
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by=['etl_date'],
    on_schema_change='fail'
) }}

WITH a AS (
    SELECT *
    FROM {{ ref('cst') }}
    WHERE sys_exp_dt IS NULL
),

alt AS (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.cst_code ORDER BY x.identn_issu_dt DESC, x.identn_nbr) AS rn
    FROM {{ ref('ip_alt_identn') }} AS x
    WHERE x.sys_exp_dt IS NULL
),

elc AS (
    SELECT *
    FROM {{ ref('ip_elc_adr') }}
    WHERE sys_exp_dt IS NULL
),

pst AS (
    SELECT *
    FROM {{ ref('ip_pst_adr') }}
    WHERE sys_exp_dt IS NULL
),

idv AS (
    SELECT *
    FROM {{ ref('idv_prfl') }}
    WHERE sys_exp_dt IS NULL
),

emp AS (
    SELECT *
    FROM {{ ref('idv_emp_st') }}
    WHERE sys_exp_dt IS NULL
),

org AS (
    SELECT *
    FROM {{ ref('org_prfl') }}
    WHERE sys_exp_dt IS NULL
),

indiv AS (
    SELECT
        CAST(a.cst_code AS STRING) AS cst_code,
        CAST(a.opn_dt AS DATE) AS opn_dt,
        CAST(a.frst_ou_code AS STRING) AS frst_ou_code,
        CAST(b.identn_nbr AS STRING) AS identn_nbr,
        CAST(b.identn_issu_dt AS DATE) AS identn_issu_dt,
        CAST(NULL AS STRING) AS bsn_rgst_nbr,
        CAST(e.tax_identn_nbr AS STRING) AS tax_identn_nbr,
        CAST(e.bsn_rgst_eff_dt AS DATE) AS bsn_rgst_eff_dt,
        CAST(b.identn_expiry_dt AS DATE) AS bsn_rgst_expiry_dt,
        CAST(e.gnd AS STRING) AS gnd,
        CAST(a.chker_ofcr_code AS STRING) AS chker_ofcr,
        CAST(e.dob AS DATE) AS dob,
        CAST(a.ou_code AS STRING) AS ou_code,
        CAST(e.vip_tp_code AS STRING) AS vip_tp_code,
        CAST(e.vip_eff_dt AS DATE) AS vip_eff_dt,
        CAST(a.empe_code AS STRING) AS empe_code,
        CAST(a.shrt_nm AS STRING) AS shrt_nm,
        CAST(a.cst_nm AS STRING) AS cst_nm,
        CAST({{ etl_date() }} AS DATE) AS cdr_dt,
        CAST(a.sctr_code AS STRING) AS sctr_code,
        CAST(a.cst_grp_code AS STRING) AS cst_grp_code,
        CAST(a.maker_ofcr_code AS STRING) AS maker_ofcr,
        CAST(d1.cty_nm AS STRING) AS cty_nm,
        CAST(e.cst_st_code AS STRING) AS cst_st_code,
        CAST(d2.cty_nm AS STRING) AS cty_nm_2,
        CAST(e.cty_of_ctzn_code AS STRING) AS cty_of_ctzn_code,
        CAST(f.ocp_code AS STRING) AS ocp_code,
        CAST(c1.elc_adr_val AS STRING) AS email_adress,
        CAST(e.vip_f AS STRING) AS vip_f,
        CAST(e.kyc_cnl_code AS STRING) AS kyc_cnl_code,
        CAST(e.cst_lcs_code AS STRING) AS cst_lcs_code,
        CAST(d1.str_nm AS STRING) AS str_nm,
        CAST(a.str_addr AS STRING) AS str_addr,
        CAST(a.trgt_code AS STRING) AS trgt_code,
        CAST(b.identn_tp_code AS STRING) AS identn_tp_code,
        CAST(NULL AS STRING) AS gen_dir_plc,
        CAST(a.frst_ou_code AS STRING) AS opn_ou_code,
        CAST(e.ou_code AS STRING) AS mgt_ou_code,
        CAST(NULL AS DATE) AS dir_dob,
        CAST(b.identn_nbr AS STRING) AS nat_id_nbr,
        CAST(a.chker_ofcr_code AS STRING) AS scd_ofcr_code,
        CAST(b.issu_plc_code AS STRING) AS issu_plc_code,
        CAST(NULL AS STRING) AS cntct_prsn,
        CAST(e.mbl_bnkg_f AS STRING) AS mbl_bnkg_f,
        CAST(e.inn_bnkg_f AS STRING) AS inn_bnkg_f,
        CAST(e.aml_rslt AS STRING) AS aml_rslt,
        CAST(e.aml_chk_f AS STRING) AS aml_chk_f,
        CAST(f.idv_emp_st_code AS STRING) AS idv_emp_st_code,
        CAST(e.jnt_lby_f AS STRING) AS jnt_lby_f,
        CAST(e.mb_cr_st AS STRING) AS mb_cr_st,
        CAST(e.cst_fnc_st_code AS STRING) AS cst_fnc_st_code,
        CAST(f.anul_incm AS DECIMAL(25, 5)) AS anul_incm,
        CAST(a.src_dt_tm AS DATE) AS src_dt_tm,
        CAST(d1.prov_nm AS STRING) AS prov_nm,
        CAST(e.idy_lv1_cl_code AS STRING) AS idy_lv1_cl_code,
        CAST(a.refr_code AS STRING) AS refr_code,
        CAST(NULL AS STRING) AS cntct_prsn_phn,
        CAST(a.ctr_tmpl_code AS STRING) AS ctr_tmpl_code,
        CAST(d2.prov_nm AS STRING) AS city_nm,
        CAST(e.vss_code AS STRING) AS vss_code,
        CAST(a.crs_sell_rm_code AS STRING) AS crs_sell_rm_code,
        CAST(c2.elc_adr_val AS STRING) AS hm_nbr,
        CAST(c3.elc_adr_val AS STRING) AS mbl_nbr,
        CAST(e.idy_lv2_cl_code AS STRING) AS idy_lv2_cl_code
    FROM a
    INNER JOIN idv AS e ON a.cst_code = e.cst_code
    LEFT JOIN emp AS f ON a.cst_code = f.cst_code
    LEFT JOIN alt AS b
        ON
            a.cst_code = b.cst_code
            AND b.rn = 1
    LEFT JOIN elc AS c1
        ON
            a.cst_code = c1.cst_code
            AND c1.elc_adr_tp = 'EMAIL'
    LEFT JOIN elc AS c2
        ON
            a.cst_code = c2.cst_code
            AND c2.elc_adr_tp = 'HOME_NUMBER'
    LEFT JOIN elc AS c3
        ON
            a.cst_code = c3.cst_code
            AND c3.elc_adr_tp = 'MOBILE_NUMBER'
    LEFT JOIN pst AS d1
        ON
            a.cst_code = d1.cst_code
            AND d1.pst_adr_tp = 'CURRENT ADDRESS'
    LEFT JOIN pst AS d2
        ON
            a.cst_code = d2.cst_code
            AND d2.pst_adr_tp = 'PERMANENT ADDRESS'
),

corp AS (
    SELECT
        CAST(a.cst_code AS STRING) AS cst_code,
        CAST(a.opn_dt AS DATE) AS opn_dt,
        CAST(a.frst_ou_code AS STRING) AS frst_ou_code,
        CAST(b.identn_nbr AS STRING) AS identn_nbr,
        CAST(b.identn_issu_dt AS DATE) AS identn_issu_dt,
        CAST(e.bsn_rgst_nbr AS STRING) AS bsn_rgst_nbr,
        CAST(e.tax_identn_nbr AS STRING) AS tax_identn_nbr,
        CAST(e.bsn_rgst_eff_dt AS DATE) AS bsn_rgst_eff_dt,
        CAST(b.identn_expiry_dt AS DATE) AS bsn_rgst_expiry_dt,
        CAST(NULL AS STRING) AS gnd,
        CAST(a.chker_ofcr_code AS STRING) AS chker_ofcr,
        CAST(e.estb_dt AS DATE) AS dob,
        CAST(a.ou_code AS STRING) AS ou_code,
        CAST(e.vip_tp_code AS STRING) AS vip_tp_code,
        CAST(e.vip_eff_dt AS DATE) AS vip_eff_dt,
        CAST(a.empe_code AS STRING) AS empe_code,
        CAST(a.shrt_nm AS STRING) AS shrt_nm,
        CAST(a.cst_nm AS STRING) AS cst_nm,
        CAST({{ etl_date() }} AS DATE) AS cdr_dt,
        CAST(a.sctr_code AS STRING) AS sctr_code,
        CAST(a.cst_grp_code AS STRING) AS cst_grp_code,
        CAST(a.maker_ofcr_code AS STRING) AS maker_ofcr,
        CAST(d1.cty_nm AS STRING) AS cty_nm,
        CAST(e.cst_st_code AS STRING) AS cst_st_code,
        CAST(d2.cty_nm AS STRING) AS cty_nm_2,
        CAST(NULL AS STRING) AS cty_of_ctzn_code,
        CAST(NULL AS STRING) AS ocp_code,
        CAST(c1.elc_adr_val AS STRING) AS email_adress,
        CAST(e.vip_f AS STRING) AS vip_f,
        CAST(e.kyc_cnl_code AS STRING) AS kyc_cnl_code,
        CAST(e.cst_lcs_code AS STRING) AS cst_lcs_code,
        CAST(d1.str_nm AS STRING) AS str_nm,
        CAST(a.str_addr AS STRING) AS str_addr,
        CAST(a.trgt_code AS STRING) AS trgt_code,
        CAST(b.identn_tp_code AS STRING) AS identn_tp_code,
        CAST(e.gen_dir_plc AS STRING) AS gen_dir_plc,
        CAST(a.frst_ou_code AS STRING) AS opn_ou_code,
        CAST(e.ou_code AS STRING) AS mgt_ou_code,
        CAST(e.dir_dob AS DATE) AS dir_dob,
        CAST(b.identn_nbr AS STRING) AS nat_id_nbr,
        CAST(a.chker_ofcr_code AS STRING) AS scd_ofcr_code,
        CAST(b.issu_plc_code AS STRING) AS issu_plc_code,
        CAST(e.cntct_prsn AS STRING) AS cntct_prsn,
        CAST(e.mbl_bnkg_f AS STRING) AS mbl_bnkg_f,
        CAST(e.inn_bnkg_f AS STRING) AS inn_bnkg_f,
        CAST(e.aml_rslt AS STRING) AS aml_rslt,
        CAST(e.aml_chk_f AS STRING) AS aml_chk_f,
        CAST(NULL AS STRING) AS idv_emp_st_code,
        CAST(e.jnt_lby_f AS STRING) AS jnt_lby_f,
        CAST(e.mb_cr_st AS STRING) AS mb_cr_st,
        CAST(e.cst_fnc_st_code AS STRING) AS cst_fnc_st_code,
        CAST(NULL AS DECIMAL(25, 5)) AS anul_incm,
        CAST(a.src_dt_tm AS DATE) AS src_dt_tm,
        CAST(d1.prov_nm AS STRING) AS prov_nm,
        CAST(e.idy_lv1_cl_code AS STRING) AS idy_lv1_cl_code,
        CAST(a.refr_code AS STRING) AS refr_code,
        CAST(e.cntct_prsn_phn AS STRING) AS cntct_prsn_phn,
        CAST(a.ctr_tmpl_code AS STRING) AS ctr_tmpl_code,
        CAST(d2.prov_nm AS STRING) AS city_nm,
        CAST(NULL AS STRING) AS vss_code,
        CAST(a.crs_sell_rm_code AS STRING) AS crs_sell_rm_code,
        CAST(c2.elc_adr_val AS STRING) AS hm_nbr,
        CAST(c3.elc_adr_val AS STRING) AS mbl_nbr,
        CAST(e.idy_lv2_cl_code AS STRING) AS idy_lv2_cl_code
    FROM a
    INNER JOIN org AS e ON a.cst_code = e.cst_code
    LEFT JOIN alt AS b
        ON
            a.cst_code = b.cst_code
            AND b.rn = 1
    LEFT JOIN elc AS c1
        ON
            a.cst_code = c1.cst_code
            AND c1.elc_adr_tp = 'EMAIL'
    LEFT JOIN elc AS c2
        ON
            a.cst_code = c2.cst_code
            AND c2.elc_adr_tp = 'HOME_NUMBER'
    LEFT JOIN elc AS c3
        ON
            a.cst_code = c3.cst_code
            AND c3.elc_adr_tp = 'MOBILE_NUMBER'
    LEFT JOIN pst AS d1
        ON
            a.cst_code = d1.cst_code
            AND d1.pst_adr_tp = 'CURRENT ADDRESS'
    LEFT JOIN pst AS d2
        ON
            a.cst_code = d2.cst_code
            AND d2.pst_adr_tp = 'PERMANENT ADDRESS'
)

SELECT
    u.*,
    {{ etl_date() }} AS etl_date
FROM (
    SELECT * FROM indiv
    UNION ALL
    SELECT * FROM corp
) AS u
