# dim_loan_ar — sheet 'Dimension Loan Arrangement'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.LOAN_AR, PG_SILVER.LOAN_AR_PRFL

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · LOAN_AR · a · WHERE a.SYS_EXP_DT IS NULL
- PG_SILVER · LOAN_AR_PRFL · b · (LEFT JOIN) ON a.AR_ID = b.AR_ID AND b.SYS_EXP_DT IS NULL

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| LOAN_AR | AR_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), a.AR_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Chuẩn hóa công thức tạo khóa Surrogate Key CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), a.AR_ID) và lọc SYS_EXP_DT IS NULL khi join LOAN_AR_PRFL. Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| LOAN_AR | AR_ID | 1:1 | AR_ID | CHAR | 32 | Unique key trên DWH |  |
| LOAN_AR | AR_CODE | 1:1 | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| LOAN_AR | FCC_AR_CODE | 1:1 | FCC_AR_CODE | VARCHAR2 | 40 | Mã hợp đồng FlexCube |  |
| LOAN_AR | PPR_CTR_NBR | 1:1 | PPR_CTR_NBR | VARCHAR2 | 100 | Mã hồ sơ |  |
| LOAN_AR_PRFL | AR_LCS_TP_CODE | 1:1 | AR_LCS_TP_CODE | VARCHAR2 | 40 | Trạng thái |  |
| LOAN_AR | AR_PPS_GRP_CODE | 1:1 | AR_PPS_GRP_CODE | VARCHAR2 | 40 | Mã nhóm mục đích vay |  |
| LOAN_AR | AR_PPS_TP_CODE | 1:1 | AR_PPS_TP_CODE | VARCHAR2 | 40 | Mã mụ̣c đích vay |  |
| LOAN_AR | ORIG_AMT_FCY | 1:1 | ORIG_AMT_FCY | NUMBER | 25.5 | Giá trị phê duyệt |  |
| LOAN_AR | PD_CGY_CODE | 1:1 | PD_CGY_CODE | VARCHAR2 | 20 | Mã phân loại sản phẩm |  |
| LOAN_AR_PRFL | PROM_PRGM | 1:1 | PROM_CODE | VARCHAR2 | 20 | Mã chương trình KM cho vay |  |
| LOAN_AR_PRFL | PROM_PRGM_2 | 1:1 | PROM_CODE_2 | VARCHAR2 | 20 | Mã CTKM2 |  |
| LOAN_AR | TERM_CODE | 1:1 | TERM_CODE | VARCHAR2 | 20 | Kỳ hạn |  |
| LOAN_AR | VAL_DT | 1:1 | VAL_DT | DATE |  | Ngày hiệu lực đầu tiên của hợp đồng |  |
| LOAN_AR | EFF_DT | 1:1 | EFF_DT | DATE |  | Ngaày hiệu lực hợp đồng |  |
| LOAN_AR | MAT_DT | 1:1 | MAT_DT | DATE |  | Ngày đáo hạn hợp đồng |  |
| LOAN_AR | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| LOAN_AR | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
