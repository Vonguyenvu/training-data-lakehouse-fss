# dim_fnc_st — sheet 'Dimension Financial Status'

Tầng: Gold / Mart (Dimension) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.CV

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_SILVER · CV · cv · WHERE CL_SCM_CODE = 'FNC_ST'

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| CV | CL_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), cv.CL_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| CV | CL_ID | 1:1 | FNC_ST_ID | CHAR | 32 | Mã duy nhất của nhóm nợ trên DWH |  |
| CV | CL_CODE | 1:1 | FNC_ST_CODE | VARCHAR2 | 20 | Mã nhóm nợ |  |
| CV | CL_DSC | 1:1 | FNC_ST_DSC | VARCHAR2 | 1000 | Mô tả nhóm nợ |  |
| CV | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| CV | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
