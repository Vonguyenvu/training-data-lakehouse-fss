# intf_loan_dsbr — sheet 'Interface Loan Disbursement'

Tầng: Silver -> Gold (Interface / Reporting) · Wave: WAVE_4_GOLD_INTERFACE · Chờ: PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_X_IP_RLTNP, PG_SILVER.EMPE, PG_SILVER.AR_RATE_HIST, PG_SILVER.PD

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where · Fields
- 1 · PG_SILVER · LOAN_AR · a · main · a.SYS_EXP_DT IS NULL
- 2 · PG_SILVER · LOAN_AR_PRFL · b · sub · LEFT JOIN · a.AR_CODE = b.AR_CODE · b.SYS_EXP_DT IS NULL
- 3 · PG_SILVER · AR_X_IP_RLTNP · c · sub · LEFT JOIN · a.AR_CODE = c.AR_CODE · c.SYS_EXP_DT IS NULL
- 4 · PG_SILVER · EMPE · d · sub · LEFT JOIN · COALESCE(c.REFRRER_OFCR, b.REFRRER_OFCR) = d.EMPE_CODE · d.SYS_EXP_DT IS NULL
- 5 · PG_SILVER · AR_RATE_HIST · e · sub · LEFT JOIN · a.AR_CODE = e.AR_CODE · e.SYS_EXP_DT IS NULL
- 6 · PG_SILVER · PD · f · sub · LEFT JOIN · a.PD_CODE = f.PD_CODE

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| LOAN_AR | EFF_DT | ${ETL_DATE} | CDR_DT | DATE |  | Ngày dữ liệu |  |
| LOAN_AR | AR_CODE | 1:1 | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| LOAN_AR | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng |  |
| LOAN_AR_PRFL | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 32 | Mã chi nhánh quản lý hiện tại |  |
| LOAN_AR | VAL_DT, EFF_DT | COALESCE(a.VAL_DT,a.EFF_DT) | VAL_DT | DATE |  | Ngày giải ngân |  |
| LOAN_AR | EFF_DT | 1:1 | EFF_DT | DATE |  | Ngày hiệu lực hợp đồng |  |
| LOAN_AR | MAT_DT | 1:1 | MAT_DT | DATE |  | Ngày hiệu lực hợp đồng |  |
| LOAN_AR | CCY_CODE | 1:1 | CCY_CODE | VARCHAR2 | 20 | Loại tiền |  |
| LOAN_AR | AR_PPS_TP_CODE | 1:1 | AR_PPS_TP_CODE | VARCHAR2 | 40 | Mã mục đích vay |  |
| LOAN_AR | PPR_CTR_NBR | 1:1 | PPR_CTR_NBR | VARCHAR2 | 100 | Mã hồ sơ |  |
| LOAN_AR | PD_CGY_CODE | 1:1 | PD_CGY_CODE | VARCHAR2 | 20 | Mã phân loại sản phẩm |  |
| LOAN_AR | ORIG_AMT_FCY | 1:1 | ORIG_AMT_FCY | NUMBER | 25.5 | Giá trị phê duyệt |  |
| LOAN_AR | CCY_CODE, EXG_RATE_TO_LCL_CCY | DECODE(a.CCY_CODE, 'VND', 1, a.EXG_RATE_TO_LCL_CCY) | EXG_RATE_TO_LCL_CCY | NUMBER | 25.7 | Tỷ giá |  |
| LOAN_AR | ORIG_AMT_FCY, CCY_CODE, EXG_RATE_TO_LCL_CCY | a.ORIG_AMT_FCY  * DECODE(a.CCY_CODE, 'VND', 1, a.EXG_RATE_TO_LCL_CCY) | ORIG_AMT_LCY | NUMBER | 25.5 | Giá trị phê duyệt quy đổi |  |
| EMPE | EMPE_NM | 1:1 | EMPE_NM | VARCHAR2 | 255 | Tên nhân viên hạch toán |  |
| AR_RATE_HIST | EFF_RATE_PCT | 1:1 | EFF_RATE_PCT | NUMBER | 25.7 | Giá trị lãi suất |  |
| LOAN_AR_PRFL | AR_PPS_BY_IDY | 1:1 | AR_PPS_BY_IDY | VARCHAR2 | 20 | Mục đích vay theo ngành kinh tế |  |
| LOAN_AR_PRFL | LOS_CTR_CODE | 1:1 | LOS_CTR_CODE | VARCHAR2 | 40 | mã hợp đồng vay |  |
| LOAN_AR_PRFL | CAR_AP_CODE | 1:1 | CAR_AP_CODE | VARCHAR2 | 40 | Mã hồ sơ đăng ký vay vốn mua xe |  |
| LOAN_AR_PRFL | DSBR_PRPSL_OFCR | 1:1 | DSBR_PRPSL_OFCR | VARCHAR2 | 40 | Cán bộ đề xuất giải ngân |  |
| LOAN_AR_PRFL | DSBR_PRPSL_MGR | 1:1 | DSBR_PRPSL_MGR | VARCHAR2 | 40 | Người đề xuất giải ngân |  |
| LOAN_AR | PD_CODE | 1:1 | PD_CODE | VARCHAR2 | 20 | Mã nhóm sản phẩm |  |
| PD | PD_NM | 1:1 | PD_NM | VARCHAR2 | 255 | Tên sản phẩm |  |
| LOAN_AR | TERM_CODE | 1:1 | LOC_TERM | VARCHAR2 | 20 | Kỳ hạn |  |
