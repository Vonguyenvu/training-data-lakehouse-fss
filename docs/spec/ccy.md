# ccy — sheet 'Currency'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_CURRENCY

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CURRENCY · cur

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CURRENCY | ID | fn_hash("T24_CURRENCY",cur.ID) | CCY_ID | CHAR | 32 | Mã duy nhất của loại tiền trên DWH |  |
| T24CORE_CURRENCY | ID | 1:1 | CCY_CODE | VARCHAR2 | 20 | Mã loại tiền |  |
| T24CORE_CURRENCY | CCY_NAME | 1:1 | CCY_NM | VARCHAR2 | 300 | Tên loại tiền |  |
| T24CORE_CURRENCY | NUMERIC_CCY_CODE | 1:1 | NUMERIC_CCY_CODE | VARCHAR2 | 20 | Mã tiền tệ dạng số |  |
| T24CORE_CURRENCY | ID | 'T24_CURRENCY' | SRC_STM_CODE | VARCHAR2 | 20 | Mã nguồn dữ liệu | Sửa thành `'T24_CURRENCY'`. |
| T24CORE_CURRENCY | ID | ETL_DATE if not exists CCY_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CURRENCY | ID | ETL_DATE if ID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CURRENCY | DATE_TIME | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
