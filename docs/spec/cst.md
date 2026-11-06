# cst — sheet 'Customer'

Tầng: Silver Temp 2 (Business) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_CUSTOMER, PG_BRONZE.T24CORE_SECTOR

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.ETL_DATE = ${ETL_DATE} -- Bảng thực thể Khách hàng trung tâm (SCD Type 1)
- PG_BRONZE · T24CORE_SECTOR · s · (LEFT JOIN) ON c.SECTOR = s.RECID AND s.ETL_DATE = ${ETL_DATE}

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã CIF |  |
| T24CORE_CUSTOMER | KHOI | 1:1 | CST_GRP_CODE | VARCHAR2 | 20 | mã Khối quản lý khách hàng |  |
| T24CORE_CUSTOMER | OPEN_COMPANY | 1:1 | FRST_OU_CODE | VARCHAR2 | 20 | Chi nhánh mở |  |
| T24CORE_CUSTOMER | COMPANY_BOOK | 1:1 | OU_CODE | VARCHAR2 | 20 | Mã chi nhánh mở CIF |  |
| T24CORE_CUSTOMER | ACCOUNT_OFFICER | 1:1 | MAKER_OFCR_CODE | VARCHAR2 | 20 | Mã nhân viên hạch toán |  |
| T24CORE_CUSTOMER | SECOND_OFFICER | 1:1 | CHKER_OFCR_CODE | VARCHAR2 | 20 | Mã nhân viên hạch toán thứ 2 |  |
| T24CORE_CUSTOMER | REFERRED_BY | 1:1 | REFR_CODE | VARCHAR2 | 40 | Mã người tham chiếu/giới thiệu |  |
| T24CORE_CUSTOMER | SECTOR | 1:1 | SCTR_CODE | VARCHAR2 | 40 | Mã phân loại hình khách hàng |  |
| T24CORE_CUSTOMER | SHORT_NAME | 1:1 | SHRT_NM | VARCHAR2 | 255 | Tên viết tắt khách hàng |  |
| T24CORE_CUSTOMER | VN_FULL_NAME | 1:1 | CST_NM | VARCHAR2 | 255 | Tên khách hàng đầy đủ |  |
| T24CORE_CUSTOMER | CONTACT_DATE | 1:1 | OPN_DT | DATE |  | Ngày khách hàng liên hệ/mở CIF |  |
| T24CORE_CUSTOMER | ACCOUNT_OFFICER | 1:1 | EMPE_CODE | VARCHAR2 | 20 | Mã nhân viên quản lý / giới thiệu | Bổ sung từ T24CORE_CUSTOMER.ACCOUNT_OFFICER phục vụ INF_CST.EMPE_CODE |
| T24CORE_CUSTOMER | STREET | 1:1 | STR_ADDR | VARCHAR2 | 100 | Địa chỉ đường phố gốc trên CIF | Bổ sung từ T24CORE_CUSTOMER.STREET phục vụ INF_CST.STR_ADDR |
| T24CORE_CUSTOMER | TARGET | 1:1 | TRGT_CODE | VARCHAR2 | 20 | Mã phân khúc khách hàng mục tiêu | Bổ sung từ T24CORE_CUSTOMER.TARGET phục vụ INF_CST.TRGT_CODE |
| T24CORE_CUSTOMER | DATE_TIME, TXN_DATE | COALESCE(c.DATE_TIME, c.TXN_DATE) | SRC_DT_TM | DATE |  | Thời gian cập nhật bản ghi nguồn | Bổ sung từ T24CORE_CUSTOMER.DATE_TIME phục vụ INF_CST.SRC_DT_TM |
| T24CORE_CUSTOMER | MAU_HD | 1:1 | CTR_TMPL_CODE | VARCHAR2 | 100 | Mã biểu mẫu hợp đồng chuẩn | Bổ sung từ T24CORE_CUSTOMER.MAU_HD phục vụ INF_CST.CTR_TMPL_CODE |
| T24CORE_CUSTOMER | MB_RM_BANCHEO | 1:1 | CRS_SELL_RM_CODE | VARCHAR2 | 100 | Mã nhân sự bán chéo sản phẩm | Bổ sung từ T24CORE_CUSTOMER.MB_RM_BANCHEO phục vụ INF_CST.CRS_SELL_RM_CODE |
| T24CORE_SECTOR | CUSTOMER_TYPE | s.CUSTOMER_TYPE | CST_TP_CODE | VARCHAR2 | 40 | Loại khách hàng (theo phân khúc Sector) | Map từ T24CORE_SECTOR.CUSTOMER_TYPE qua LEFT JOIN c.SECTOR = s.RECID |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists CST_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
