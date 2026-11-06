# idv_emp_st — sheet 'Individual Employment Status'

Tầng: Silver Temp 2 (Bank-wised) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.KHOI LIKE '%INDIV%'

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã CIF |  |
| T24CORE_CUSTOMER | EMPLOYMENT_STATUS | 1:1 | IDV_EMP_ST_CODE | VARCHAR2 | 20 | Trạng thái khách hàng |  |
| T24CORE_CUSTOMER | NET_MONTHLY_IN | 1:1 | ANUL_INCM | NUMBER | 25.5 | Thu nhập theo tháng |  |
| T24CORE_CUSTOMER | OCCUPATION | 1:1 | OCP_CODE | VARCHAR2 | 100 | Nghề nghiệp của khách hàng |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists CST_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
