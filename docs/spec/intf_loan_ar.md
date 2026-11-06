# intf_loan_ar — sheet 'Interface Loan Arrangement'

Tầng: Silver -> Gold (Interface / Reporting) · Wave: WAVE_4_GOLD_INTERFACE · Chờ: PG_SILVER.AR_BAL, PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_RATE_HIST, PG_SILVER.AR_DLQ_SMY, PG_SILVER.EXG_RATE, PG_SILVER.OU, PG_SILVER.AST_AR_INT_SMY, PG_GOLD.INF_CST, PG_SILVER.AR_AVY_SHD_ITM

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · WHERE a.CDR_DT = ${ETL_DATE} -- Lưu ý Grain: AR_BAL lưu theo (AR_ID, GL_ITM_CODE); các chỉ số cấp hợp đồng (APPROVE_AMOUNT, ODUE_PR_AMT, ODUE_IN_AMT...) chỉ tính trên dòng dư nợ chính hoặc khi tổng hợp báo cáo cần lọc theo GL_ITM_CODE LIKE '2%' để không cộng trùng giữa dòng gốc (2%) và dòng lãi dự thu (394%) · Fields
- 1 · PG_SILVER · AR_BAL · a · main · WHERE a.CDR_DT = ${ETL_DATE}
- 2 · PG_SILVER · LOAN_AR · b · sub · join · a.AR_ID = b.AR_ID · b.SYS_EXP_DT IS NULL
- 3 · PG_SILVER · LOAN_AR_PRFL · c · sub · left join · a.AR_ID = c.AR_ID · c.SYS_EXP_DT IS NULL
- 4 · PG_SILVER · AR_RATE_HIST · d · sub · left join · a.AR_ID = e.AR_ID · e.CDR_DT = ${ETL_DATE} -- Join 1:1 theo AR_ID (dành cho PDLD%); với hợp đồng gốc LD% dùng subquery e1 đã GROUP BY ORIG_AR_ID ở dòng 7 để tránh nhân bản dòng (Fan-out)
- 5 · PG_SILVER · AR_DLQ_SMY · e · sub · left join · CASE WHEN a.AR_CODE LIKE 'PDLD%' THEN a.AR_ID ELSE e.ORIG_AR_ID END = CASE WHEN a.AR_CODE LIKE 'PDLD%' THEN e.AR_ID ELSE a.AR_ID END · e.CDR_DT = ${ETL_DATE}
- 6 · PG_SILVER · AR_DLQ_SMY · e1 · sub · left join · CASE WHEN a.AR_CODE LIKE 'PDLD%' THEN fn_hash("T24_LD_LOANS_AND_DEPOSITS", SUBSTR(a.AR_CODE, 3, 12)) ELSE a.AR_ID END = e1.ORIG_AR_ID · (SELECT<br>  ORIG_AR_ID<br>  ,SUM(NVL(e.PNP_ARS, 0)) AS PNP_ARS<br>  ,MAX(${ETL_DATE} - e.PNP_PAST_DUE_DT) + 1 AS SO_NGAY_QH_GOC<br>  ,MAX(${ETL_DATE} - e.INT_PAST_DUE_DT) + 1 AS SO_NGAY_QH_LAI<br>  ,GREATEST(NVL(MAX(${ETL_DATE} - e.PNP_PAST_DUE_DT) + 1, 0), NVL(MAX(${ETL_DATE} - e.INT_PAST_DUE_DT) + 1, 0)) AS SONGAY_QHAN_CAONHAT<br>  ,MAX(NVL(e.ADDITION_DYS_IN_ARS, 0)) AS SNQH_CHUYENDOI<br>FROM PG_SILVER.AR_DLQ_SMY e<br>WHERE e.CDR_DT = ${ETL_DATE}<br>GROUP BY ORIG_AR_ID) e1
- 7 · PG_SILVER · EXG_RATE · f · sub · left join · b.CCY_CODE = f.FRST_CCY_CODE · f.SNPST_DT = ${ETL_DATE}
- 8 · PG_SILVER · OU · i · sub · left join · c.OU_CODE = i.OU_CODE · i.SYS_EXP_DT IS NULL
- 9 · PG_SILVER · AST_AR_INT_SMY · k · sub · left join · CASE WHEN a.AR_CODE LIKE 'PDLD%' THEN fn_hash("T24_LD_LOANS_AND_DEPOSITS", SUBSTR(a.AR_CODE, 3, 12)) ELSE a.AR_ID END = k.ORIG_AR_ID · (SELECT<br>  ORIG_AR_ID<br>  ,SUM(TOT_ACR_INT_AMT_FCY) AS TOT_ACR_INT_AMT_FCY<br>  ,SUM(TOT_INT_PAID_AMT_FCY) AS TOT_INT_PAID_AMT_FCY<br>  ,SUM(TOT_INT_DUE_AMT_FCY) AS TOT_INT_DUE_AMT_FCY<br>  ,SUM(TOT_INT_ODUE_AMT_FCY) AS TOT_INT_ODUE_AMT_FCY<br>FROM PG_SILVER.AST_AR_INT_SMY<br>WHERE CDR_DT = ${ETL_DATE}<br>GROUP BY ORIG_AR_ID) k
- 10 · PG_GOLD · INF_CST · cst · sub · left join · a.CST_CODE = cst.CST_CODE · cst.CDR_DT = ${ETL_DATE}
- 11 · PG_SILVER · AR_AVY_SHD_ITM · shd · sub · left join · a.AR_ID = shd.AR_ID · (SELECT<br>  AR_ID<br>  ,MIN(CASE WHEN PBL_AMT_TP IN ('LD_PR', 'PD_PR') THEN EFF_MAT_DT END) AS NGAY_THANH_TOAN_GOC_TIEPTHEO<br>  ,SUM(CASE WHEN PBL_AMT_TP IN ('LD_PR', 'PD_PR') THEN NVL(PBL_AMT_FCY, 0) ELSE 0 END) AS SO_TIEN_THUNO_GOC<br>  ,MIN(CASE WHEN PBL_AMT_TP IN ('LD_IN', 'PD_IN') THEN EFF_MAT_DT END) AS NGAY_THANH_TOAN_LAI<br>FROM PG_SILVER.AR_AVY_SHD_ITM<br>WHERE SYS_EXP_DT IS NULL AND EFF_MAT_DT >= ${ETL_DATE}<br>GROUP BY AR_ID) shd

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| AR_BAL | CDR_DT | ${ETL_DATE} | CDR_DT | DATE |  | Ngày dữ liệu |  |
| AR_BAL | AR_CODE | 1:1 | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| LOAN_AR | EFF_DT | 1:1 | EFF_DT | DATE |  | Ngày hiệu lực của hợp đồng |  |
| AR_BAL | PD_CGY_CODE | 1:1 | PD_CGY_CODE | VARCHAR2 | 20 | Mã phân loại sản phẩm |  |
| LOAN_AR | PPR_CTR_NBR | 1:1 | PPR_CTR_NBR | VARCHAR2 | 100 | Mã hồ sơ |  |
| LOAN_AR_PRFL | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 32 | Mã chi nhánh hạch toán |  |
| AR_BAL | SUB_PD_CODE | 1:1 | SUB_PD_CODE | VARCHAR2 | 20 | Mã sản phẩm con |  |
| AR_BAL | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng |  |
| LOAN_AR_PRFL | AR_LCS_TP_CODE | 1:1 | AR_LCS_TP_CODE | VARCHAR2 | 40 | Trạng thái |  |
| AR_BAL | MUD_CODE | 1:1 | MUD_CODE | VARCHAR2 | 20 | Mã phân hệ |  |
| LOAN_AR_PRFL | FNC_ST_CODE | 1:1 | FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ hợp đồng |  |
| LOAN_AR | CCY_CODE | 1:1 | CCY_CODE | VARCHAR2 | 20 | Loại tiền |  |
| LOAN_AR | MAT_DT | 1:1 | MAT_DT | DATE |  | Ngày đáo hạn hợp đồng |  |
| LOAN_AR | ORIG_AMT_FCY | NVL(b.ORIG_AMT_FCY, 0) | APPROVE_AMOUNT | NUMBER | 25.5 | Số tiền phê duyệt nguyên tệ |  |
| LOAN_AR | VAL_DT, FCC_VAL_DT, EFF_DT | COALESCE(b.VAL_DT, b.FCC_VAL_DT, b.EFF_DT) | VAL_DT | DATE |  | Ngày hiệu lực đầu tiên của hợp đồng |  |
| LOAN_AR_PRFL | PNP_LQD_AR_CODE | 1:1 | DRAWDOWN_ACCOUNT | VARCHAR2 | 40 | Tài khoản giải ngân |  |
| AR_BAL | AR_TERM_TP_CODE | 1:1 | AR_TERM_TP_CODE | VARCHAR2 | 20 | Mã nhóm kỳ hạn |  |
| LOAN_AR | LMT_CODE | 1:1 | LMT_CODE | VARCHAR2 | 32 | Mã tham chiếu hạn mức |  |
| LOAN_AR | AR_CODE | NULL | INT_KEY | NUMBER | 22 | Mã khóa lãi suất tham chiếu |  |
| AR_RATE_HIST | SPRD_RATE_PCT | d.SPRD_RATE_PCT | INT_SPRD | NUMBER | 25.7 | Biên độ lãi suất |  |
| LOAN_AR_PRFL | INT_LQD_AR_CODE | 1:1 | INT_LQD_AR_CODE | VARCHAR2 | 40 | Tài khoản thanh toán lãi |  |
| LOAN_AR | FCC_AR_CODE | 1:1 | FCC_AR_CODE | VARCHAR2 | 40 | Mã hợp đồng FlexCube |  |
| AR_RATE_HIST | PNY_RATE | 1:1 | PNY_RATE | NUMBER | 25.7 | Lãi phạt penalty rate |  |
| AR_RATE_HIST | ODUE_INT_RATE | 1:1 | ODUE_INT_RATE | NUMBER | 25.7 | Lãi suất cho quá hạn |  |
| AR_BAL | GL_ITM_CODE, RCVB_AMT_LCY | CASE WHEN a.GL_ITM_CODE LIKE '2%' AND a.RCVB_AMT_LCY < 0 THEN ABS(a.RCVB_AMT_LCY) ELSE 0 END | AMOUNT_CUR | NUMBER | 25.5 | Dư nợ hiện tại nguyên tệ |  |
| AR_RATE_HIST | INT_RATE_VARIABLITY_TP_CODE | d.INT_RATE_VARIABLITY_TP_CODE | INT_TP | VARCHAR2 | 20 | Loại lãi suất |  |
| LOAN_AR | AR_CODE | NULL | INT_BSS | VARCHAR2 | 20 | Cơ sở tính lãi (Interest Basis) |  |
| AR_RATE_HIST | INT_RATE_VARIABLITY_TP_CODE | CASE WHEN d.INT_RATE_VARIABLITY_TP_CODE IN ('1', 'FIX', 'FIXED') THEN 'Y' WHEN d.INT_RATE_VARIABLITY_TP_CODE IS NOT NULL THEN 'N' ELSE NULL END | INT_FIX | VARCHAR2 | 20 | Cờ cố định lãi suất |  |
| AR_RATE_HIST | EFF_RATE_PCT | d.EFF_RATE_PCT | RATE | NUMBER | 25.7 | Lãi suất hiệu lực |  |
| AR_BAL | CDR_DT | 1:1 | TXN_DT | DATE |  | Ngày giao dịch |  |
| AR_DLQ_SMY | PNP_ARS | NVL(e.PNP_ARS, NVL(e1.PNP_ARS, 0)) | ODUE_PR_AMT | NUMBER | 25.5 | Số tiền gốc quá hạn |  |
| AST_AR_INT_SMY | TOT_INT_ODUE_AMT_FCY | NVL(k.TOT_INT_ODUE_AMT_FCY, 0) | ODUE_IN_AMT | NUMBER | 32.5 | Lãi quá hạn |  |
| LOAN_AR | AR_CODE | CAST(0 AS NUMBER(25,5)) | ODUE_PE_AMT | NUMBER | 25.5 | Số tiền phạt gốc quá hạn |  |
| LOAN_AR | AR_CODE | CAST(0 AS NUMBER(25,5)) | ODUE_PS_AMT | NUMBER | 25.5 | Số tiền phạt lãi quá hạn |  |
| AR_RATE_HIST | MRGN_RATE | 1:1 | MRGN_RATE | NUMBER | 25.7 | Biên độ thay đổi lãi suất |  |
| LOAN_AR | PD_CODE | 1:1 | PD_CODE | VARCHAR2 | 20 | Mã sản phẩm |  |
| LOAN_AR, INF_CST | PD_CODE, CST_GRP_CODE | CASE WHEN cst.CST_GRP_CODE LIKE '%INDIV%' THEN b.PD_CODE ELSE NULL END | KHCN_PD_CODE | VARCHAR2 | 20 | Mã sản phẩm cho vay KHCN |  |
| LOAN_AR_PRFL | DSBR_PRPSL_OFCR | 1:1 | DSBR_PRPSL_OFCR | VARCHAR2 | 40 | Cán bộ đề xuất giải ngân |  |
| LOAN_AR_PRFL | DSBR_PRPSL_MGR | 1:1 | DSBR_PRPSL_MGR | VARCHAR2 | 40 | Người đề xuất giải ngân |  |
| LOAN_AR_PRFL | MGT_OFCR | 1:1 | MGT_OFCR | VARCHAR2 | 40 | Cán bộ quản lý khoản vay |  |
| LOAN_AR_PRFL | MGT_MGR | 1:1 | MGT_MGR | VARCHAR2 | 40 | Người quản lý khoản vay |  |
| LOAN_AR_PRFL | APRV_AHR | 1:1 | APRV_AHR | VARCHAR2 | 1000 | Cấp phê duyệt giải ngân |  |
| LOAN_AR_PRFL | DBT_WVR_F | 1:1 | DBT_WVR_F | VARCHAR2 | 20 | Đánh dấu cơ cấu miễn giảm lãi |  |
| LOAN_AR_PRFL | NBR_OF_DBT_RSTC | 1:1 | NBR_OF_DBT_RSTC | NUMBER | 22 | Giá trị tương ứng với từng trường |  |
| LOAN_AR_PRFL | AR_PPS_BY_PD | c.AR_PPS_BY_PD | AR_PPS_BY_PD | VARCHAR2 | 20 | Mã sản phẩm theo mục đích vay |  |
| AR_DLQ_SMY | PNP_PAST_DUE_DT | NVL(e1.SO_NGAY_QH_GOC, 0) | DYS_IN_PNP_ARS | NUMBER | 22 | Số ngày gốc quá hạn |  |
| AR_DLQ_SMY | INT_PAST_DUE_DT | NVL(e1.SO_NGAY_QH_LAI, 0) | DYS_IN_INT_ARS | NUMBER | 22 | Số́ ngày lãi quá hạn |  |
| AST_AR_INT_SMY | TOT_INT_DUE_AMT_FCY, TOT_INT_ODUE_AMT_FCY | NVL(k.TOT_INT_DUE_AMT_FCY, 0) + NVL(k.TOT_INT_ODUE_AMT_FCY, 0) | TOT_INT_ARS | NUMBER | 32.5 | Tổng lãi phải trả |  |
| AR_BAL | CST_ID | 1:1 | CST_ID | CHAR | 32 | ID của khách hàng |  |
| INF_CST | CST_FNC_ST_CODE | cst.CST_FNC_ST_CODE | CST_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ khách hàng | join sang INF_CST |
| EXG_RATE | MID_RATE | 1:1 | MID_RATE | NUMBER | 25.7 | Tỷ giá |  |
| AR_BAL | GL_ITM_CODE, CLS_BAL_LCY | CASE WHEN a.GL_ITM_CODE LIKE '2%' AND a.CLS_BAL_LCY < 0 THEN ABS(a.CLS_BAL_LCY) ELSE 0 END | AMT_LCY | NUMBER | 25.5 | Dư nợ quy đổi VND |  |
| LOAN_AR, EXG_RATE | ORIG_AMT_FCY, CCY_CODE, EXG_RATE_TO_LCL_CCY, MID_RATE | NVL(b.ORIG_AMT_FCY, 0) * DECODE(b.CCY_CODE, 'VND', 1, NVL(f.MID_RATE, b.EXG_RATE_TO_LCL_CCY)) | APRV_AMT_LCY | NUMBER | 25.5 | Số tiền phê duyệt quy đổi VND |  |
| AR_DLQ_SMY | PNP_PAST_DUE_DT, INT_PAST_DUE_DT, ADDITION_DYS_IN_ARS | NVL(e1.SONGAY_QHAN_CAONHAT, 0) + NVL(e1.SNQH_CHUYENDOI, 0) | MX_DYS_IN_ARS | NUMBER | 22 | Số ngày quá hạn cao nhất |  |
| AST_AR_INT_SMY | TOT_INT_PAID_AMT_FCY | NVL(k.TOT_INT_PAID_AMT_FCY, 0) | TOT_INT_PAID_AMT_FCY | NUMBER | 32.5 | Tổng lãi đã trả |  |
| LOAN_AR_PRFL | FNC_ST_CODE | c.FNC_ST_CODE | AR_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ hợp đồng | rule giống CREDIT_STATUS |
| INF_CST | JNT_LBY_F | cst.JNT_LBY_F | JNT_LBY_F | VARCHAR2 | 20 | Cờ nợ liên đới | join sang INF_CST |
| LOAN_AR | FCC_LMT_CODE | 1:1 | FCC_LMT_CODE | VARCHAR2 | 20 | Mã hạn mức trên Flexcube |  |
| LOAN_AR_PRFL | MAKER_OFCR | 1:1 | MAKER_OFCR_CODE | VARCHAR2 | 40 | ID người nhập liệu |  |
| LOAN_AR_PRFL | CHKER_OFCR | 1:1 | CHKER_OFCR_CODE | VARCHAR2 | 40 | Mã người phê duyệt |  |
| INF_CST | CST_GRP_CODE | cst.CST_GRP_CODE | CST_GRP_CODE | VARCHAR2 | 20 | Khối khách hàng | join sang INF_CST |
| LOAN_AR, LOAN_AR_PRFL | FCC_AR_CODE, AR_PPS_BY_IDY, AR_PPS_TP_CODE | CASE WHEN b.FCC_AR_CODE IS NOT NULL THEN SUBSTR(c.AR_PPS_BY_IDY, 2, LENGTH(c.AR_PPS_BY_IDY)) ELSE b.AR_PPS_TP_CODE END | AR_PPS_TP_CODE | VARCHAR2 | 40 | Mã mục đích vay |  |
| LOAN_AR | AR_PPS_GRP_CODE | 1:1 | AR_PPS_GRP_CODE | VARCHAR2 | 40 | Mã nhóm mục đích vay |  |
| LOAN_AR_PRFL | LOS_CTR_CODE | 1:1 | LOS_CTR_CODE | VARCHAR2 | 40 | mã hợp đồng vay |  |
| LOAN_AR_PRFL | LOS_CTR_ID | 1:1 | LOS_CTR_ID | VARCHAR2 | 20 | mã hồ sơ trên LOS |  |
| LOAN_AR_PRFL | DBT_RSTC_TP_CODE | 1:1 | DBT_RSTC_TP_CODE | VARCHAR2 | 20 | Loại cơ cấu | case when |
| LOAN_AR_PRFL | CAR_AP_CODE | 1:1 | CAR_AP_CODE | VARCHAR2 | 40 | Mã hồ sơ đăng ký vay vốn mua xe |  |
| LOAN_AR_PRFL | SCR_TP | 1:1 | SCR_TP | VARCHAR2 | 20 | Loạ̣i hình chứng khoán |  |
| LOAN_AR_PRFL | MAND_REPYMT | 1:1 | MAND_REPYMT | VARCHAR2 | 20 | Giá trị UDF | case when |
| LOAN_AR | LOS_CTR_NBR | 1:1 | LOS_CTR_NBR | VARCHAR2 | 40 | Số hồ sơ |  |
| LOAN_AR_PRFL | PROM_PRGM | 1:1 | PROM_PRGM | VARCHAR2 | 20 | Mã chương trình KM cho vay |  |
| LOAN_AR_PRFL | PROM_PRGM_2 | 1:1 | PROM_PRGM_2 | VARCHAR2 | 20 | Mã CTKM2 |  |
| INF_CST | SCTR_CODE | cst.SCTR_CODE | SCTR_CODE | VARCHAR2 | 40 | Mã thành phần kinh tế | join sang INF_CST |
| LOAN_AR_PRFL | COVID19_RSTC_COMPL_DT | 1:1 | COVID19_RSTC_COMPL_DT | DATE |  | Ngày hết hạn cơ cấu |  |
| AR_AVY_SHD_ITM | EFF_MAT_DT, PBL_AMT_TP | shd.NGAY_THANH_TOAN_GOC_TIEPTHEO | NGAY_THANH_TOAN_GOC_TIEPTHEO | DATE |  | Ngày thanh toán gốc tiếp theo |  |
| AR_AVY_SHD_ITM | PBL_AMT_FCY, PBL_AMT_TP, EFF_MAT_DT | NVL(shd.SO_TIEN_THUNO_GOC, 0) | SO_TIEN_THUNO_GOC | NUMBER | 25.5 | Số tiền thu nợ gốc |  |
| AR_AVY_SHD_ITM | EFF_MAT_DT, PBL_AMT_TP | shd.NGAY_THANH_TOAN_LAI | NGAY_THANH_TOAN_LAI | DATE |  | Ngày thanh toán lãi |  |
| INF_CST | IDY_LV1_CL_CODE | cst.IDY_LV1_CL_CODE | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành kinh tế cha | join sang INF_CST |
| INF_CST | IDY_LV2_CL_CODE | cst.IDY_LV2_CL_CODE | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Mã ngành kinh tế con | join sang INF_CST |
| AR_BAL | MUD_CODE, GL_ITM_CODE, RCVB_AMT_LCY | CASE WHEN a.MUD_CODE = 'LD' AND a.GL_ITM_CODE LIKE '394%' THEN ABS(a.RCVB_AMT_LCY) ELSE 0 END | TOT_ACR_INT_DUE_AMT | NUMBER | 25.5 | Lãi dự thu trong hạn |  |
| AR_BAL | MUD_CODE, GL_ITM_CODE, RCVB_AMT_LCY | CASE WHEN a.MUD_CODE = 'LD' AND a.GL_ITM_CODE LIKE '394%' THEN ABS(a.RCVB_AMT_LCY) ELSE 0 END | NXT_ACR_INT_AMT | NUMBER | 25.5 | Lãi dự thu tiếp theo | Rule giống DUTHU_TRONG_HAN |
| AST_AR_INT_SMY | TOT_ACR_INT_AMT_FCY, TOT_INT_PAID_AMT_FCY | GREATEST(NVL(k.TOT_ACR_INT_AMT_FCY, 0) - NVL(k.TOT_INT_PAID_AMT_FCY, 0), 0) | DTHU_CONLAI_DUKIEN_KYGANNHAT | NUMBER | 25.5 | Dự thu còn lại dự kiến kỳ gần nhất |  |
| OU | OU_NM | 1:1 | OU_NM | VARCHAR2 | 300 | Tên chi nhánh |  |
| AR_DLQ_SMY | ADDITION_DYS_IN_ARS | NVL(e1.SNQH_CHUYENDOI, 0) | ADDITION_DYS_IN_ARS | NUMBER | 22 | Số ngày quá hạn chuyển đổi |  |
| LOAN_AR_PRFL | BDS_TT11 | 1:1 | BDS_TT11 | VARCHAR2 | 20 | Phân loại bất động sản theo Thông tư 11 |  |
| AR_BAL | GL_ITM_CODE | 1:1 | GL_ITM_CODE | VARCHAR2 | 20 | Mã hạch toán theo SBV |  |
| INF_CST | CST_GRP_CODE | CASE WHEN cst.CST_GRP_CODE LIKE '%INDIV%' THEN 'INDIV' ELSE 'CORP' END | CST_TP_CODE | VARCHAR2 | 20 | Loại khách hàng (KHCN/KHDN) | join sang INF_CST |
| INF_CST | CST_NM | cst.CST_NM | CST_NM | VARCHAR2 | 255 | Tên đầy đủ của khách hàng | join sang INF_CST |
