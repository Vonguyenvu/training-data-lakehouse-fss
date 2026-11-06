# ou — sheet 'Organization Unit'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_COMPANY

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_COMPANY · ou · WHERE ou.ETL_DATE = ${ETL_DATE} -- Bảng danh mục Đơn vị / Chi nhánh ngân hàng

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_COMPANY | RECID | fn_hash("T24_COMPANY", ou.RECID) | OU_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_COMPANY | RECID | 1:1 | OU_CODE | VARCHAR2 | 32 | Mã chi nhánh |  |
| T24CORE_COMPANY | COMPANY_NAME | 1:1 | OU_NM | VARCHAR2 | 300 | Tên chi nhánh |  |
| T24CORE_COMPANY | RECID | ETL_DATE if not exists OU_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_COMPANY | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_COMPANY | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
