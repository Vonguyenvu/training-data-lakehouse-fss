# pd — sheet 'Product'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.LOS_APP_PRODUCT, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · LOS_APP_PRODUCT, FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, T24CORE_LD_LOANS_AND_DEPOSITS · pd · WHERE pd.ETL_DATE = ${ETL_DATE} -- Bảng danh mục Sản phẩm tín dụng chuẩn hóa hợp nhất (UNION DISTINCT) từ:<br>  (1) PG_BRONZE.LOS_APP_PRODUCT (PRODUCT_CODE, PRODUCT_NAME)<br>  (2) PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE (SAN_PHAM_CHO_VAY_KHCN, SAN_PHAM_CHO_VAY_KHDN)<br>  (3) PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS (PRODUCTGR_CODE)

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| LOS_APP_PRODUCT, FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE, T24CORE_LD_LOANS_AND_DEPOSITS | PRODUCT_CODE, SAN_PHAM_CHO_VAY_KHCN, SAN_PHAM_CHO_VAY_KHDN, PRODUCTGR_CODE, ID, RECID | fn_hash("T24_PRODUCT", pd.PRODUCT_CODE) | PD_ID | CHAR | 32 | Unique key trên DWH |  |
| LOS_APP_PRODUCT | PRODUCT_CODE | 1:1 | PD_CODE | VARCHAR2 | 32 | Mã sản phẩm |  |
| LOS_APP_PRODUCT | PRODUCT_NAME | 1:1 | PD_NM | VARCHAR2 | 255 | Tên sản phẩm |  |
| LOS_APP_PRODUCT | PRODUCT_CODE | 'T24_PRODUCT' | SRC_STM_CODE | VARCHAR2 | 20 | Mã nguồn dữ liệu |  |
| LOS_APP_PRODUCT | PRODUCT_CODE | ETL_DATE if not exists PD_ID | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi | Thêm cột SYS_EFF_DT để đồng bộ với bảng hạ nguồn PG_GOLD.DIM_PD. |
| LOS_APP_PRODUCT | PRODUCT_CODE | ETL_DATE if PRODUCT_CODE was deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi | Thêm cột SYS_EXP_DT để đồng bộ với bảng hạ nguồn PG_GOLD.DIM_PD. |
| LOS_APP_PRODUCT | PRODUCT_CODE | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Hợp lệ |
