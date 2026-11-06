# idv_prfl — sheet 'Individual Profile'

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
| T24CORE_CUSTOMER | ACTIVE_STATUS | 1:1 | CST_LCS_CODE | VARCHAR2 | 20 | Trạng thái bản ghi |  |
| T24CORE_CUSTOMER | AML_CHECK | 1:1 | AML_CHK_F | VARCHAR2 | 20 | Liên quan tới hệ thống Phòng Chống rửa tiền |  |
| T24CORE_CUSTOMER | AML_RESULT | 1:1 | AML_RSLT | VARCHAR2 | 100 | Liên quan tới hệ thống Phòng Chống rửa tiền |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 1:1 | CST_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ khách hàng Core tính |  |
| T24CORE_CUSTOMER | CO_CODE | 1:1 | OU_CODE | VARCHAR2 | 20 | Mã chi nhánh quản lý khách hàng |  |
| T24CORE_CUSTOMER | CUSTOMER_STATUS | 1:1 | CST_ST_CODE | VARCHAR2 | 20 | Trạng thái hiện tại của khách hàng |  |
| T24CORE_CUSTOMER | INTERNET_BANKING_SERVICE | 1:1 | INN_BNKG_F | VARCHAR2 | 20 | Dịch vụ Internet banking khách hàng giao tiếp |  |
| T24CORE_CUSTOMER | KYC_CHANNEL | 1:1 | KYC_CNL_CODE | VARCHAR2 | 20 | Kênh thực hiện KYC |  |
| T24CORE_CUSTOMER | MA_BHXH | 1:1 | VSS_CODE | VARCHAR2 | 40 | Mã bảo hiểm xã hội |  |
| T24CORE_CUSTOMER | MOBILE_BANKING_SERVICE | 1:1 | MBL_BNKG_F | VARCHAR2 | 20 | Dịch vụ sử dụng sản phẩm mobile banking |  |
| T24CORE_CUSTOMER | NATIONALITY | 1:1 | CTY_OF_CTZN_CODE | VARCHAR2 | 40 | Quốc tịch |  |
| T24CORE_CUSTOMER | NO_LIEN_DOI | 1:1 | JNT_LBY_F | VARCHAR2 | 20 | Nợ liên đới |  |
| T24CORE_CUSTOMER | TAX_SERIAL, VAT_INV_SERIAL | COALESCE(c.TAX_SERIAL, c.VAT_INV_SERIAL) | TAX_IDENTN_NBR | VARCHAR2 | 100 | Mã số thuế |  |
| T24CORE_CUSTOMER | VIP_CUSTOMER | 1:1 | VIP_F | VARCHAR2 | 20 | Đánh dấu khách hàng ưu tiên |  |
| T24CORE_CUSTOMER | VN_GENDER | 1:1 | GND | VARCHAR2 | 20 | Giới tính |  |
| T24CORE_CUSTOMER | CUS_IND_PARENT | 1:1 | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành nghê kinh tế cha |  |
| T24CORE_CUSTOMER | MB_INDUSTRY | 1:1 | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Ngành nghề kinh tế |  |
| T24CORE_CUSTOMER | BIRTH_INCORP_DATE, BDATE_LEGAL | COALESCE(c.BIRTH_INCORP_DATE, c.BDATE_LEGAL) | DOB | DATE |  | Ngày sinh khách hàng cá nhân | Bổ sung ngày sinh KHCN từ COALESCE(BIRTH_INCORP_DATE, BDATE_LEGAL) phục vụ INF_CST.DOB |
| T24CORE_CUSTOMER | FFB_TYPE | 1:1 | VIP_TP_CODE | VARCHAR2 | 20 | Phân hạng khách hàng ưu tiên (VIP) | Bổ sung từ T24CORE_CUSTOMER.FFB_TYPE phục vụ INF_CST.VIP_TP_CODE |
| T24CORE_CUSTOMER | CU_EFF_DATE | 1:1 | VIP_EFF_DT | DATE |  | Ngày hiệu lực phân hạng khách hàng VIP | Bổ sung từ T24CORE_CUSTOMER.CU_EFF_DATE phục vụ INF_CST.VIP_EFF_DT |
| T24CORE_CUSTOMER | VAT_INV_DATE | 1:1 | BSN_RGST_EFF_DT | DATE |  | Ngày phát hành hóa đơn | Bổ sung từ T24CORE_CUSTOMER.VAT_INV_DATE phục vụ INF_CST.BSN_RGST_EFF_DT |
| T24CORE_CUSTOMER | MB_CR_STT | 1:1 | MB_CR_ST | VARCHAR2 | 20 | Trạng thái quan hệ tín dụng MB | Bổ sung từ T24CORE_CUSTOMER.MB_CR_STT phục vụ INF_CST.MB_CR_ST |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists CST_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
