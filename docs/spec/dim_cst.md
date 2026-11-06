# dim_cst — sheet 'Dimension Customer'

Tầng: Gold / Mart (Optional) · Wave: WAVE_3_GOLD_DIM · Chờ: PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Main Table · Type join · Condition JOIN · Condition where
- PG_SILVER · CST · cst · main · WHERE cst.SYS_EXP_DT IS NULL
- PG_SILVER · IDV_PRFL · idv · sub · left · cst.cst_id = idv.cst_id AND idv.SYS_EXP_DT IS NULL
- PG_SILVER · ORG_PRFL · org · sub · left · cst.cst_id = org.cst_id AND org.SYS_EXP_DT IS NULL

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| CST | CST_ID | CONCAT(TO_CHAR(ETL_CHANGE_DATE, 'YYYYMMDD'), cst.CST_ID) | DIM_KEY | CHAR | 40 | Key của bảng | Biến `ETL_CHANGE_DATE` được tính bằng `COALESCE(SYS_UDT_DT, SYS_EFF_DT, ${ETL_DATE})`. |
| CST | CST_ID | 1:1 | CST_ID | CHAR | 32 | Unique key trên DWH |  |
| CST | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng |  |
| CST | CST_NM | 1:1 | CST_NM | VARCHAR2 | 255 | Tên khách hàng |  |
| CST | SCTR_CODE | 1:1 | SCTR_CODE | VARCHAR2 | 40 | Mã phân loại hình khách hàng |  |
| IDV_PRFL, ORG_PRFL | IDY_LV1_CL_CODE | NVL(idv.IDY_LV1_CL_CODE, org.IDY_LV1_CL_CODE) | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành nghê kinh tế cha | Sửa thành `cst.cst_id = idv.cst_id AND idv.SYS_EXP_DT IS NULL` và `cst.cst_id = org.cst_id AND org.SYS_EXP_DT IS NULL`. |
| IDV_PRFL, ORG_PRFL | IDY_LV2_CL_CODE | NVL(idv.IDY_LV2_CL_CODE, org.IDY_LV2_CL_CODE) | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Ngành nghề kinh tế |  |
| CST | SYS_EFF_DT | 1:1 | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| CST | SYS_EXP_DT | 1:1 | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
