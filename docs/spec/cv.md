# cv — sheet 'Classification Value'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST, PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1 (LOOKUP MASTER)
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST · ud · WHERE ud.CO_CAU_NO IS NOT NULL -- Bắt buộc dùng SELECT DISTINCT ud.CO_CAU_NO (hoặc GROUP BY ud.CO_CAU_NO) để khử trùng trước khi tạo danh mục LOAN_RSTC_TP; Nhánh 2 (UNION ALL dòng 14): SELECT DISTINCT cust.ASSET_CLASS FROM PG_BRONZE.T24CORE_CUSTOMER cust WHERE cust.ASSET_CLASS IS NOT NULL

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | fn_hash("T24_CL_LOAN_RSTC_TP", ud.CO_CAU_NO) | CL_ID | CHAR | 32 | Mã duy nhất của CL |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | 1:1 | CL_CODE | VARCHAR2 | 20 | Mã phân loại |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | DECODE(ud.CO_CAU_NO, '1','1.Co cau theo thong tu 09', '2','2.Co cau theo quyet dinh 780', '3','3.Co cau khac (theo thong tu 02 hien hanh)', '4','4.Khong', '5','5.Co cau no do Covid-19', '6','6.Mien giam lai do Covid-19', '7','7.Co cau va mien giam lai do Covid-19') | CL_DSC | VARCHAR2 | 1000 | mô tả |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | 'LOAN_RSTC_TP' | CL_SCM_CODE | VARCHAR2 | 30 | Nhóm phân loại |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | 'T24_CL_LOAN_RSTC_TP' | SRC_STM_CODE | VARCHAR2 | 20 | Nguồn dữ liệu |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | ETL_DATE if not exists CL_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | ETL_DATE if CL_CODE was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| FLEXBO_PGBLD_RT_CONTRACT_UDFIELD_HIST | CO_CAU_NO | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
|  |  |  |  |  |  |  |  |
| T24CORE_CUSTOMER | ASSET_CLASS | fn_hash("T24_CL_FNC_ST", ASSET_CLASS) | CL_ID | CHAR | 32 | Mã duy nhất của CL |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 1:1 | CL_CODE | VARCHAR2 | 20 | Mã phân loại |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 'Nhom no ' \|\| ASSET_CLASS | CL_DSC | VARCHAR2 | 1000 | mô tả |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 'FNC_ST' | CL_SCM_CODE | VARCHAR2 | 30 | Nhóm phân loại |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 'T24_CL_FNC_ST' | SRC_STM_CODE | VARCHAR2 | 20 | Nguồn dữ liệu |  |
| T24CORE_CUSTOMER | ASSET_CLASS | ETL_DATE if not exists CL_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | ASSET_CLASS | ETL_DATE if CL_CODE was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | ASSET_CLASS | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
| CL_CODE | CL_DSC | CL_SCM_CODE |  |  |  |  |  |
| 1 | 1.Co cau theo thong tu 09 | LOAN_RSTC_TP |  |  |  |  |  |
| 2 | 2.Co cau theo quyet dinh 780 | LOAN_RSTC_TP |  |  |  |  |  |
| 3 | 3.Co cau khac (theo thong tu 02 hien hanh) | LOAN_RSTC_TP |  |  |  |  |  |
| 4 | 4.Khong | LOAN_RSTC_TP |  |  |  |  |  |
| 5 | 5.Co cau no do Covid-19 | LOAN_RSTC_TP |  |  |  |  |  |
| 6 | 6.Mien giam lai do Covid-19 | LOAN_RSTC_TP |  |  |  |  |  |
| 7 | 7.Co cau va mien giam lai do Covid-19 | LOAN_RSTC_TP |  |  |  |  |  |
| 1 | Nhom no 1 | FNC_ST |  |  |  |  |  |
| 2 | Nhom no 2 | FNC_ST |  |  |  |  |  |
| 3 | Nhom no 3 | FNC_ST |  |  |  |  |  |
| 4 | Nhom no 4 | FNC_ST |  |  |  |  |  |
| 5 | Nhom no 5 | FNC_ST |  |  |  |  |  |
