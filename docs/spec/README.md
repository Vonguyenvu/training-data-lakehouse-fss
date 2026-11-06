# Đặc tả từng bảng (sinh từ Excel bằng `scripts/export_spec.py`, đừng sửa tay)

| Bảng | Sheet | Tầng | Wave | Chờ |
|---|---|---|---|---|
| [inf_cst](inf_cst.md) | Interface Customer | Silver -> Gold (Interface / Reporting) | WAVE_4_GOLD_INTERFACE | PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.IDV_EMP_ST, PG_SILVER.ORG_PRFL, PG_SILVER.IP_ALT_IDENTN, PG_SILVER.IP_ELC_ADR, PG_SILVER.IP_PST_ADR |
| [cst](cst.md) | Customer | Silver Temp 2 (Business) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_CUSTOMER, PG_BRONZE.T24CORE_SECTOR |
| [idv_prfl](idv_prfl.md) | Individual Profile | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_CUSTOMER |
| [idv_emp_st](idv_emp_st.md) | Individual Employment Status | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_CUSTOMER |
| [org_prfl](org_prfl.md) | Organization Profile | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_CUSTOMER |
| [ip_alt_identn](ip_alt_identn.md) | Involved Party Alternative Iden | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_CUSTOMER |
| [ip_elc_adr](ip_elc_adr.md) | Involved Party Electronic Addre | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_CUSTOMER |
| [ip_pst_adr](ip_pst_adr.md) | Involved Party Postal Address | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_CUSTOMER |
| [intf_loan_ar](intf_loan_ar.md) | Interface Loan Arrangement | Silver -> Gold (Interface / Reporting) | WAVE_4_GOLD_INTERFACE | PG_SILVER.AR_BAL, PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_RATE_HIST, PG_SILVER.AR_DLQ_SMY, PG_SILVER.EXG_RATE, PG_SILVER.OU, PG_SILVER.AST_AR_INT_SMY, PG_GOLD.INF_CST, PG_SILVER.AR_AVY_SHD_ITM |
| [loan_ar](loan_ar.md) | Loan Arrangement | Silver Temp 2 (Business) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.FLEXBO_PGB_LDTB_CONTRACT_MASTER, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, PG_BRONZE.LOS_APP_LOAN_DISBURSEMENT, PG_BRONZE.LOS_APP_FACILITY, PG_BRONZE.LOS_APP_PRODUCT, PG_BRONZE.T24CORE_CUSTOMER |
| [loan_ar_prfl](loan_ar_prfl.md) | Loan Arrangement Profile | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.EBANKING_COL_UDF_VALUE, PG_BRONZE.FLEXBO_PGB_CONTRACT_UDF_MAP, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, PG_BRONZE.FLEXBO_PGBLD_CONTRACT_UDFIELD_HIST, PG_BRONZE.T24CORE_MB_MG_SAVING_MULTI, PG_BRONZE.FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST, PG_BRONZE.SOURCE_SAOKE_MVMT, PG_BRONZE.T24CORE_CUSTOMER |
| [ar_x_ip_rltnp](ar_x_ip_rltnp.md) | Arrangement x Involved Party | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE |
| [dim_loan_ar](dim_loan_ar.md) | Dimension Loan Arrangement | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL |
| [ccy](ccy.md) | Currency | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_CURRENCY |
| [dim_ccy](dim_ccy.md) | Dimension Currency | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.CCY |
| [pd](pd.md) | Product | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.LOS_APP_PRODUCT, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS |
| [dim_pd](dim_pd.md) | Dimension Product | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.PD |
| [ou](ou.md) | Organization Unit | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_COMPANY |
| [dim_ou](dim_ou.md) | Dimension Organization Unit | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.OU |
| [empe](empe.md) | Employee | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_DEPT_ACCT_OFFICER |
| [lmt](lmt.md) | Limit | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_LIMIT |
| [dim_lmt](dim_lmt.md) | Dimension Limit | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.LMT |
| [cv](cv.md) | Classification Value | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST, PG_BRONZE.T24CORE_CUSTOMER |
| [dim_rstc_tp](dim_rstc_tp.md) | Dimension Loan Restructure Type | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.CV |
| [dim_fnc_st](dim_fnc_st.md) | Dimension Financial Status | Gold / Mart (Dimension) | WAVE_3_GOLD_DIM | PG_SILVER.CV |
| [intf_loan_dsbr](intf_loan_dsbr.md) | Interface Loan Disbursement | Silver -> Gold (Interface / Reporting) | WAVE_4_GOLD_INTERFACE | PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_X_IP_RLTNP, PG_SILVER.EMPE, PG_SILVER.AR_RATE_HIST, PG_SILVER.PD |
| [intf_loan_repymt_shd](intf_loan_repymt_shd.md) | Interface Loan Repayment Schedu | Silver -> Gold (Interface / Reporting) | WAVE_4_GOLD_INTERFACE | PG_SILVER.AR_AVY_SHD_ITM, PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL |
| [ar_avy_shd_itm](ar_avy_shd_itm.md) | Arrangement Activity Schedule I | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_STMT_ENTRY, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.T24CORE_LD_SCHEDULE_DEFINE_MV |
| [sk_lich_tra_no](sk_lich_tra_no.md) | sk_lich_tra_no | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_LD_SCHEDULE_DEFINE_MV, PG_BRONZE.T24CORE_MB_MG_SAVING_MULTI, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS_MV, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.T24CORE_SECTOR, PG_BRONZE.T24CORE_STMT_ENTRY |
| [saoke_giaingan](saoke_giaingan.md) | Saoke_GIAINGAN | Silver Temp 2 (Business) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.SMY_STMT_DAILY, PG_BRONZE.SOURCE_SAOKE_CRB, PG_BRONZE.SOURCE_SAOKE_MVMT, PG_BRONZE.T24CORE_COMPANY, PG_BRONZE.T24CORE_CUSTOMER |
| [exg_rate](exg_rate.md) | Exchange Rate | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_CURRENCY, PG_BRONZE.T24CORE_CURRENCY_HIS |
| [pst_entr](pst_entr.md) | Posting Entry | Silver Temp 2 (Business) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_STMT_ENTRY, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV |
| [saoke_tindung](saoke_tindung.md) | SAOKE_TINDUNG | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_CUSTOMER, PG_BRONZE.T24CORE_DEPT_ACCT_OFFICER |
| [cust_info_daily](cust_info_daily.md) | CUST_INFO_DAILY | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.SMY_STMT_DAILY, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, PG_BRONZE.FLEXBO_PGB_LDTB_CONTRACT_MASTER, PG_BRONZE.FLEXBO_PGB_CONTRACT_UDF_MAP, PG_BRONZE.FLEXBO_PGBLD_CONTRACT_UDFIELD_HIST, PG_BRONZE.FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST, PG_BRONZE.EBANKING_COL_UDF_VALUE, PG_BRONZE.LOS_APP_LOAN_DISBURSEMENT, PG_BRONZE.LOS_APP_FACILITY, PG_BRONZE.LOS_APP_PRODUCT |
| [ar_bal](ar_bal.md) | Arrangement Balance | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.SOURCE_SAOKE_CRB |
| [ar_rate_hist](ar_rate_hist.md) | Arrangement Rate History | Silver Temp 1 (Tech) | WAVE_1_SILVER_TEMP1 | PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE |
| [ar_dlq_smy](ar_dlq_smy.md) | Arrangement Delinquency Summary | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS_MV, PG_BRONZE.T24CORE_PD_PAYMENT_DUE |
| [ar_tvr_smy](ar_tvr_smy.md) | Arrangement Turnover Summary | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.SOURCE_SAOKE_CRB, PG_SILVER.PST_ENTR, PG_SILVER.AR_DLQ_SMY, PG_SILVER.LOAN_AR |
| [ast_ar_int_smy](ast_ar_int_smy.md) | Asset Arrangement Interest Summ | Silver Temp 2 (Bank-wised) | WAVE_2_SILVER_TEMP2 | PG_BRONZE.SOURCE_SAOKE_CRB, PG_BRONZE.T24CORE_STMT_ENTRY |
| [dim_cst](dim_cst.md) | Dimension Customer | Gold / Mart (Optional) | WAVE_3_GOLD_DIM | PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL |
| [fct_loan_ar](fct_loan_ar.md) | Fact Loan Arrangement | Gold / Mart (Optional) | WAVE_4_GOLD_FACT | PG_SILVER.LOAN_AR, PG_SILVER.AR_BAL, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_RATE_HIST, PG_SILVER.AR_DLQ_SMY, PG_SILVER.EXG_RATE, PG_SILVER.AST_AR_INT_SMY, PG_SILVER.AR_TVR_SMY, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL, PG_GOLD.DIM_LOAN_AR, PG_GOLD.DIM_CST, PG_GOLD.DIM_PD, PG_GOLD.DIM_OU, PG_GOLD.DIM_CCY, PG_GOLD.DIM_LMT, PG_GOLD.DIM_RSTC_TP, PG_GOLD.DIM_FNC_ST |
