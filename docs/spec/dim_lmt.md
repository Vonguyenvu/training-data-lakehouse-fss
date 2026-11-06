# dim_lmt — sheet 'Dimension Limit'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.LMT

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · LMT · l

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| LMT | LMT_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), l.LMT_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| LMT | LMT_ID | 1:1 | LMT_ID | CHAR | 32 | ID của hạn mức |  |
| LMT | LMT_CODE | 1:1 | LMT_CODE | VARCHAR2 | 32 | Mã hạn mức |  |
| LMT | LMT_DSC | 1:1 | LMT_DSC | VARCHAR2 | 300 | Mô tả hạn mức |  |
| LMT | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| LMT | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
