# empe — sheet 'Employee'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_DEPT_ACCT_OFFICER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_DEPT_ACCT_OFFICER · empe · WHERE empe.ETL_DATE = ${ETL_DATE} -- Bảng danh mục Cán bộ / Nhân viên ngân hàng

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_DEPT_ACCT_OFFICER | RECID | fn_hash("T24_EMPLOYEE", empe.RECID) | EMPE_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_DEPT_ACCT_OFFICER | RECID | 1:1 | EMPE_CODE | VARCHAR2 | 20 | Mã NHÂN VIÊN |  |
| T24CORE_DEPT_ACCT_OFFICER | NAME | 1:1 | EMPE_NM | VARCHAR2 | 255 | Tên NHÂN VIÊN |  |
| T24CORE_DEPT_ACCT_OFFICER | RECID | ETL_DATE if not exists EMPE_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_DEPT_ACCT_OFFICER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_DEPT_ACCT_OFFICER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
