# org_prfl — sheet 'Organization Profile'

Tầng: Silver Temp 2 (Bank-wised) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_CUSTOMER

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_CUSTOMER · c · WHERE c.KHOI NOT LIKE '%INDIV%'

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CUSTOMER | RECID | fn_hash("T24_CUSTOMER", c.RECID) | CST_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_CUSTOMER | RECID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã CIF |  |
| T24CORE_CUSTOMER | ACTIVE_STATUS | 1:1 | CST_LCS_CODE | VARCHAR2 | 20 | Trạng thái bản ghi |  |
| T24CORE_CUSTOMER | ASSET_CLASS | 1:1 | CST_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ khách hàng Core tính |  |
| T24CORE_CUSTOMER | BIRTH_INCORP_DATE | 1:1 | ESTB_DT | DATE |  | Ngày thành lập doanh nghiệp |  |
| T24CORE_CUSTOMER | CO_CODE | 1:1 | OU_CODE | VARCHAR2 | 20 | Mã chi nhánh quản lý khách hàng |  |
| T24CORE_CUSTOMER | CUSTOMER_STATUS | 1:1 | CST_ST_CODE | VARCHAR2 | 20 | Trạng thái hiện tại của khách hàng |  |
| T24CORE_CUSTOMER | INDUSTRY | 1:1 | IDY_CL_CODE | VARCHAR2 | 40 | Mã ngành nghề đăng ký kinh doanh |  |
| T24CORE_CUSTOMER | INTERNET_BANKING_SERVICE | 1:1 | INN_BNKG_F | VARCHAR2 | 20 | Dịch vụ Internet banking khách hàng giao tiếp |  |
| T24CORE_CUSTOMER | MOBILE_BANKING_SERVICE | 1:1 | MBL_BNKG_F | VARCHAR2 | 20 | Dịch vụ sử dụng sản phẩm mobile banking |  |
| T24CORE_CUSTOMER | NO_LIEN_DOI | 1:1 | JNT_LBY_F | VARCHAR2 | 20 | Nợ liên đới |  |
| T24CORE_CUSTOMER | TAX_SERIAL, VAT_INV_SERIAL | COALESCE(c.TAX_SERIAL, c.VAT_INV_SERIAL) | TAX_IDENTN_NBR | VARCHAR2 | 100 | Mã số thuế |  |
| T24CORE_CUSTOMER | VIP_CUSTOMER | 1:1 | VIP_F | VARCHAR2 | 20 | Đánh dấu khách hàng ưu tiên |  |
| T24CORE_CUSTOMER | CUS_IND_PARENT | 1:1 | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành nghê kinh tế cha |  |
| T24CORE_CUSTOMER | MB_INDUSTRY | 1:1 | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Ngành nghề kinh tế |  |
| T24CORE_CUSTOMER | ESTAB_LIC_CODE | 1:1 | BSN_RGST_NBR | VARCHAR2 | 40 | Số giấy phép đăng ký kinh doanh | Bổ sung từ T24CORE_CUSTOMER.ESTAB_LIC_CODE phục vụ INF_CST.BSN_RGST_NBR |
| T24CORE_CUSTOMER | VAT_INV_DATE | 1:1 | BSN_RGST_EFF_DT | DATE |  | Ngày cấp giấy phép ĐKKD / phát hành hóa đơn | Bổ sung từ T24CORE_CUSTOMER.VAT_INV_DATE phục vụ INF_CST.BSN_RGST_EFF_DT |
| T24CORE_CUSTOMER | FFB_TYPE | 1:1 | VIP_TP_CODE | VARCHAR2 | 20 | Phân hạng khách hàng ưu tiên (VIP) | Bổ sung từ T24CORE_CUSTOMER.FFB_TYPE phục vụ INF_CST.VIP_TP_CODE |
| T24CORE_CUSTOMER | CU_EFF_DATE | 1:1 | VIP_EFF_DT | DATE |  | Ngày hiệu lực phân hạng khách hàng VIP | Bổ sung từ T24CORE_CUSTOMER.CU_EFF_DATE phục vụ INF_CST.VIP_EFF_DT |
| T24CORE_CUSTOMER | KYC_CHANNEL | 1:1 | KYC_CNL_CODE | VARCHAR2 | 20 | Kênh thực hiện KYC | Bổ sung từ T24CORE_CUSTOMER.KYC_CHANNEL phục vụ INF_CST.KYC_CNL_CODE |
| T24CORE_CUSTOMER | GEN_DIR_PLC | 1:1 | GEN_DIR_PLC | VARCHAR2 | 100 | Nơi sinh Tổng giám đốc / người đại diện pháp luật | Bổ sung từ T24CORE_CUSTOMER.GEN_DIR_PLC phục vụ INF_CST.GEN_DIR_PLC |
| T24CORE_CUSTOMER | BDAY_DIRECTOR | 1:1 | DIR_DOB | DATE |  | Ngày sinh Giám đốc / người đại diện pháp luật | Bổ sung từ T24CORE_CUSTOMER.BDAY_DIRECTOR phục vụ INF_CST.DIR_DOB |
| T24CORE_CUSTOMER | CONTACT_PERSON | 1:1 | CNTCT_PRSN | VARCHAR2 | 40 | Họ tên người liên hệ chính KHDN | Bổ sung từ T24CORE_CUSTOMER.CONTACT_PERSON phục vụ INF_CST.CNTCT_PRSN |
| T24CORE_CUSTOMER | PHONE_CONT_PER | 1:1 | CNTCT_PRSN_PHN | VARCHAR2 | 100 | Số điện thoại người liên hệ chính KHDN | Bổ sung từ T24CORE_CUSTOMER.PHONE_CONT_PER phục vụ INF_CST.CNTCT_PRSN_PHN |
| T24CORE_CUSTOMER | AML_RESULT | 1:1 | AML_RSLT | VARCHAR2 | 100 | Kết quả sàng lọc phòng chống rửa tiền (AML) | Bổ sung từ T24CORE_CUSTOMER.AML_RESULT phục vụ INF_CST.AML_RSLT |
| T24CORE_CUSTOMER | AML_CHECK | 1:1 | AML_CHK_F | VARCHAR2 | 20 | Cờ kiểm tra phòng chống rửa tiền (AML) | Bổ sung từ T24CORE_CUSTOMER.AML_CHECK phục vụ INF_CST.AML_CHK_F |
| T24CORE_CUSTOMER | MB_CR_STT | 1:1 | MB_CR_ST | VARCHAR2 | 20 | Trạng thái quan hệ tín dụng MB | Bổ sung từ T24CORE_CUSTOMER.MB_CR_STT phục vụ INF_CST.MB_CR_ST |
| T24CORE_CUSTOMER | RECID | ETL_DATE if not exists CST_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_CUSTOMER | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
