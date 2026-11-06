# ip_elc_adr — sheet 'Involved Party Electronic Addre'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.EMAIL_ADDRESS IS NOT NULL AND c.ETL_DATE = ${ETL_DATE} -- Nhánh 1: Địa chỉ Email của khách hàng

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key khách hàng trên DWH | Khóa băm khách hàng chuẩn |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng (CIF) | 1:1 từ c.RECID |
| T24CORE_CUSTOMER | EMAIL_ADDRESS | 'EMAIL' | ELC_ADR_TP | VARCHAR2 | 20 | Loại địa chỉ điện tử (EMAIL / HOME_NUMBER / MOBILE_NUMBER) | Gán hằng số 'EMAIL' |
| T24CORE_CUSTOMER | EMAIL_ADDRESS | 1:1 | ELC_ADR_VAL | VARCHAR2 | 100 | Giá trị địa chỉ liên lạc điện tử | Lấy trực tiếp từ c.EMAIL_ADDRESS |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists (CST_ID, ELC_ADR_TP) | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi SCD2 | Khóa tự nhiên tổ hợp (CST_ID, ELC_ADR_TP) |
| T24CORE_CUSTOMER | RECID | ETL_DATE if record was updated/deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi SCD2 | Đóng bản ghi cũ khi thay đổi giá trị |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Gán ${ETL_DATE} |
|  |  |  |  |  |  |  |  |
| Bảng nguồn | Short table | Business Rule |  |  |  |  |  |
| T24CORE_CUSTOMER | c | WHERE c.HOME_NUMBER IS NOT NULL AND c.ETL_DATE = ${ETL_DATE} -- Nhánh 2: Số điện thoại bàn / nhà riêng của khách hàng |  |  |  |  |  |
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key khách hàng trên DWH | Khóa băm khách hàng chuẩn |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng (CIF) | 1:1 từ c.RECID |
| T24CORE_CUSTOMER | HOME_NUMBER | 'HOME_NUMBER' | ELC_ADR_TP | VARCHAR2 | 20 | Loại địa chỉ điện tử (EMAIL / HOME_NUMBER / MOBILE_NUMBER) | Gán hằng số 'HOME_NUMBER' |
| T24CORE_CUSTOMER | HOME_NUMBER | 1:1 | ELC_ADR_VAL | VARCHAR2 | 100 | Giá trị địa chỉ liên lạc điện tử | Lấy trực tiếp từ c.HOME_NUMBER |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists (CST_ID, ELC_ADR_TP) | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi SCD2 | Khóa tự nhiên tổ hợp (CST_ID, ELC_ADR_TP) |
| T24CORE_CUSTOMER | RECID | ETL_DATE if record was updated/deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi SCD2 | Đóng bản ghi cũ khi thay đổi giá trị |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Gán ${ETL_DATE} |
|  |  |  |  |  |  |  |  |
| Bảng nguồn | Short table | Business Rule |  |  |  |  |  |
| T24CORE_CUSTOMER | c | WHERE c.MOBILE_NUMBER IS NOT NULL AND c.ETL_DATE = ${ETL_DATE} -- Nhánh 3: Số điện thoại di động của khách hàng |  |  |  |  |  |
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key khách hàng trên DWH | Khóa băm khách hàng chuẩn |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng (CIF) | 1:1 từ c.RECID |
| T24CORE_CUSTOMER | MOBILE_NUMBER | 'MOBILE_NUMBER' | ELC_ADR_TP | VARCHAR2 | 20 | Loại địa chỉ điện tử (EMAIL / HOME_NUMBER / MOBILE_NUMBER) | Gán hằng số 'MOBILE_NUMBER' |
| T24CORE_CUSTOMER | MOBILE_NUMBER | 1:1 | ELC_ADR_VAL | VARCHAR2 | 100 | Giá trị địa chỉ liên lạc điện tử | Lấy trực tiếp từ c.MOBILE_NUMBER |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists (CST_ID, ELC_ADR_TP) | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi SCD2 | Khóa tự nhiên tổ hợp (CST_ID, ELC_ADR_TP) |
| T24CORE_CUSTOMER | RECID | ETL_DATE if record was updated/deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi SCD2 | Đóng bản ghi cũ khi thay đổi giá trị |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Gán ${ETL_DATE} |
