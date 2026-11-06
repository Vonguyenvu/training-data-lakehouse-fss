# dim_pd — sheet 'Dimension Product'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.PD

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · PD · pd

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| PD | PD_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), pd.PD_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| PD | PD_ID | 1:1 | PD_ID | CHAR | 32 | Unique key trên DWH |  |
| PD | PD_CODE | 1:1 | PD_CODE | VARCHAR2 | 32 | Mã sản phẩm |  |
| PD | PD_NM | 1:1 | PD_NM | VARCHAR2 | 255 | Tên sản phẩm |  |
| PD | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| PD | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
