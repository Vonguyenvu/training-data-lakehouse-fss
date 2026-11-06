# intf_loan_repymt_shd — sheet 'Interface Loan Repayment Schedu'

Tầng: Silver -> Gold (Interface / Reporting) · Wave: WAVE_4_GOLD_INTERFACE · Chờ: PG_SILVER.AR_AVY_SHD_ITM, PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where · Fields
- 1 · PG_SILVER · AR_AVY_SHD_ITM · arr_shd · main · arr_shd.AR_AVY_SHD_TP = 'LOAN_PD_SHD'<br>AND ${ETL_DATE} <= arr_shd.EFF_MAT_DT<br>AND arr_shd.SYS_EXP_DT IS NULL
- 2 · PG_SILVER · LOAN_AR · arr_loan · sub · left · arr_shd.AR_ID = arr_loan.AR_ID · arr_loan.SYS_EXP_DT IS NULL
- 3 · PG_SILVER · LOAN_AR_PRFL · arr_prfl · sub · left · arr_shd.AR_ID = arr_prfl.AR_ID · arr_prfl.SYS_EXP_DT IS NULL
- 4 · PG_SILVER · CST · cst · sub · left · arr_shd.CST_ID = cst.CST_ID · cst.SYS_EXP_DT IS NULL
- 5 · PG_SILVER · IDV_PRFL · cst_idv · sub · left · arr_shd.CST_ID = cst_idv.CST_ID · cst_idv.SYS_EXP_DT IS NULL
- 6 · PG_SILVER · ORG_PRFL · cst_org · sub · left · arr_shd.CST_ID = cst_org.CST_ID · cst_org.SYS_EXP_DT IS NULL

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| AR_AVY_SHD_ITM | EFF_MAT_DT | ${ETL_DATE} | CDR_DT | DATE |  | Ngày snapshot |  |
| AR_AVY_SHD_ITM | CST_ID | 1:1 | CST_ID | CHAR | 32 | Mã số định danh duy nhất của khách hàng trên dwh |  |
| AR_AVY_SHD_ITM | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 32 | Mã khách hàng (CIF) |  |
| AR_AVY_SHD_ITM | AR_AVY_SHD_CODE | 1:1 | AR_AVY_SHD_CODE | VARCHAR2 | 32 | Mã số dòng lịch trên hệ thống nguồn |  |
| AR_AVY_SHD_ITM | AR_CODE | 1:1 | AR_CODE | VARCHAR2 | 32 | Mã tài khoản vay |  |
| LOAN_AR_PRFL | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 32 | Chi nhánh hạch toán |  |
| AR_AVY_SHD_ITM | EFF_MAT_DT | 1:1 | EFF_MAT_DT | DATE |  | Ngày đáo hạn thực tế |  |
| AR_AVY_SHD_ITM | CCY_CODE | 1:1 | CCY_CODE | VARCHAR2 | 20 | Mã loại tiền |  |
| AR_AVY_SHD_ITM | PBL_AMT_TP | 1:1 | PBL_AMT_TP | VARCHAR2 | 20 | Phân loại tiền cần thanh toán trong kỳ bill tương ứng (PS/PE/LD,..) |  |
| AR_AVY_SHD_ITM | PBL_AMT_LCY | 1:1 | PBL_AMT_LCY | NUMBER | 25.5 | Số tiền cần thanh toán quy đổi trong kỳ bill tương ứng |  |
| AR_AVY_SHD_ITM | PBL_AMT_FCY | 1:1 | PBL_AMT_FCY | NUMBER | 25.5 | Số tiền cần thanh toán nguyên tệ trong kỳ bill tương ứng |  |
| AR_AVY_SHD_ITM | EXG_RATE | 1:1 | EXG_RATE | NUMBER | 25.7 | Tỷ giá thực hiện |  |
| AR_AVY_SHD_ITM | PBL_AMT_TP | 'DUE' | LND_REPYMT_TP | CHAR | 10 | Phân loại bút toán ( PAID/DUE) |  |
| AR_AVY_SHD_ITM | F_LAST_OD_DT | 1:1 | F_LAST_OD_DT | NUMBER | 1 | Cờ hợp đồng có đang tồn tại kỳ trả nợ quá hạn gần nhất hay không |  |
| AR_AVY_SHD_ITM | LAST_OD_DT | 1:1 | LAST_OD_DT | DATE |  | Ngày đến hạn của kỳ trả nợ gần nhất đã chuyển sang quá hạn |  |
| LOAN_AR | FCC_VAL_DT | 1:1 | FCC_VAL_DT | DATE |  | Ngày tạo bút toán ( booking_date) |  |
| LOAN_AR | MAT_DT | 1:1 | MAT_DT | DATE |  | Ngày đáo hạn trên hợp đồng |  |
| LOAN_AR_PRFL | GL_ITM_CODE | 1:1 | GL_ITM_CODE | VARCHAR2 | 20 | Mã hạch toán theo SBV |  |
| IDV_PRFL, ORG_PRFL | CST_FNC_ST_CODE | CAST(COALESCE(cst_org.CST_FNC_ST_CODE, cst_idv.CST_FNC_ST_CODE, '1') AS NUMBER(1,0)) | CIC_LOAN_GRP | NUMBER | 1 | Phân loại nhóm nợ khách hàng |  |
| CST | CST_NM | cst.CST_NM | CST_FULL_NM | VARCHAR2 | 255 | Full tên của Khách hàng |  |
