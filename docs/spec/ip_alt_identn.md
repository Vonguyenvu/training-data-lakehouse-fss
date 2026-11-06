# ip_alt_identn — sheet 'Involved Party Alternative Iden'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.NATIONAL_ID IS NOT NULL AND c.ETL_DATE = ${ETL_DATE} -- Bảng định danh giấy tờ tùy thân (SCD Type 2)

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã CIF |  |
| T24CORE_CUSTOMER | NAT_ID_TYPE | 1:1 | IDENTN_TP_CODE | VARCHAR2 | 20 | Loại giấy tờ |  |
| T24CORE_CUSTOMER | NAT_ID_ISS_DATE | 1:1 | IDENTN_ISSU_DT | DATE |  | Ngày cấp giấy tờ |  |
| T24CORE_CUSTOMER | NAT_ID_EXP_DATE | 1:1 | IDENTN_EXPIRY_DT | DATE |  | Ngày hêt hạn giấy tờ |  |
| T24CORE_CUSTOMER | NAT_ID_ISS_PLC | 1:1 | ISSU_PLC_CODE | VARCHAR2 | 20 | Nơi cấp giấy tờ |  |
| T24CORE_CUSTOMER | NATIONAL_ID | 1:1 | IDENTN_NBR | VARCHAR2 | 100 | Mã giấy tờ |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists CST_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
