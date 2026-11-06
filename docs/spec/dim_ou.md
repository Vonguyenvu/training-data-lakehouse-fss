# dim_ou — sheet 'Dimension Organization Unit'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.OU

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · OU · ou

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| OU | OU_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), ou.OU_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| OU | OU_ID | 1:1 | OU_ID | CHAR | 32 | ID của chi nhánh |  |
| OU | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 32 | Mã chi nhánh |  |
| OU | OU_NM | 1:1 | OU_NM | VARCHAR2 | 300 | Tên chi nhánh |  |
| OU | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| OU | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
