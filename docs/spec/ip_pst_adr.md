# ip_pst_adr — sheet 'Involved Party Postal Address'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.ETL_DATE = ${ETL_DATE} -- Nhánh 1: Địa chỉ cư trú hiện tại (CURRENT ADDRESS)

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key khách hàng trên DWH | Khóa băm khách hàng chuẩn |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng (CIF) | 1:1 từ c.RECID |
| T24CORE_CUSTOMER | VN_STREET | 'CURRENT ADDRESS' | PST_ADR_TP | VARCHAR2 | 20 | Loại địa chỉ bưu chính | Hằng số 'CURRENT ADDRESS' |
| T24CORE_CUSTOMER | VN_STREET, VN_TOWN, COUNTRY | c.VN_STREET \|\| ',' \|\| c.VN_TOWN \|\| ',' \|\| c.COUNTRY | PST_ADR_VAL | VARCHAR2 | 100 | Địa chỉ cư trú hiện tại đầy đủ | Ghép đường + tỉnh/thành + quốc gia |
| T24CORE_CUSTOMER | COUNTRY | 1:1 | CTY_NM | VARCHAR2 | 100 | Tên quốc gia cư trú hiện tại | 1:1 từ c.COUNTRY |
| T24CORE_CUSTOMER | VN_TOWN | 1:1 | PROV_NM | VARCHAR2 | 100 | Tên tỉnh/thành phố cư trú hiện tại | 1:1 từ c.VN_TOWN |
| T24CORE_CUSTOMER | VN_STREET | 1:1 | STR_NM | VARCHAR2 | 100 | Số nhà, tên đường cư trú hiện tại | 1:1 từ c.VN_STREET |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists (CST_ID, PST_ADR_TP) | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi SCD2 | Khóa tự nhiên tổ hợp (CST_ID, PST_ADR_TP) |
| T24CORE_CUSTOMER | RECID | ETL_DATE if record was updated/deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi SCD2 | Đóng bản ghi cũ khi thay đổi địa chỉ |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Gán ${ETL_DATE} |
|  |  |  |  |  |  |  |  |
| Bảng nguồn | Short table | Business Rule |  |  |  |  |  |
| T24CORE_CUSTOMER | c | WHERE c.ETL_DATE = ${ETL_DATE} -- Nhánh 2: Địa chỉ thường trú / đăng ký (PERMANENT ADDRESS) |  |  |  |  |  |
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key khách hàng trên DWH | Khóa băm khách hàng chuẩn |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng (CIF) | 1:1 từ c.RECID |
| T24CORE_CUSTOMER | RESID_PROVINCE | 'PERMANENT ADDRESS' | PST_ADR_TP | VARCHAR2 | 20 | Loại địa chỉ bưu chính | Hằng số 'PERMANENT ADDRESS' |
| T24CORE_CUSTOMER | RESID_PROVINCE, RESIDENCE | c.RESID_PROVINCE \|\| ',' \|\| c.RESIDENCE | PST_ADR_VAL | VARCHAR2 | 100 | Địa chỉ thường trú đầy đủ | Ghép tỉnh thường trú + quốc gia thường trú |
| T24CORE_CUSTOMER | RESIDENCE | 1:1 | CTY_NM | VARCHAR2 | 100 | Tên quốc gia thường trú | 1:1 từ c.RESIDENCE |
| T24CORE_CUSTOMER | RESID_PROVINCE | 1:1 | PROV_NM | VARCHAR2 | 100 | Tên tỉnh/thành phố thường trú | 1:1 từ c.RESID_PROVINCE |
| T24CORE_CUSTOMER | STREET | 1:1 | STR_NM | VARCHAR2 | 100 | Số nhà, tên đường thường trú | 1:1 từ c.STREET |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists (CST_ID, PST_ADR_TP) | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi SCD2 | Khóa tự nhiên tổ hợp (CST_ID, PST_ADR_TP) |
| T24CORE_CUSTOMER | RECID | ETL_DATE if record was updated/deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi SCD2 | Đóng bản ghi cũ khi thay đổi địa chỉ |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi | Gán ${ETL_DATE} |
