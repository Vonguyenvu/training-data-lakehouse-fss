# dim_ccy — sheet 'Dimension Currency'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.CCY

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · CCY · cur

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| CCY | CCY_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), cur.CCY_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| CCY | CCY_ID | 1:1 | CCY_ID | CHAR | 32 | Mã duy nhất của loại tiền trên DWH |  |
| CCY | CCY_CODE | 1:1 | CCY_CODE | VARCHAR2 | 20 | Mã loại tiền |  |
| CCY | CCY_NM | 1:1 | CCY_NM | VARCHAR2 | 300 | Tên loại tiền |  |
| CCY | NUMERIC_CCY_CODE | 1:1 | NUMERIC_CCY_CODE | VARCHAR2 | 20 | Mã tiền tệ dạng số |  |
| CCY | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| CCY | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
