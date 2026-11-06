# ar_bal — sheet 'Arrangement Balance'

Tầng: Silver Temp 2 (Bank-wised) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.SOURCE_SAOKE_CRB

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · SOURCE_SAOKE_CRB · a · Where APP_CODE IN ('LD', 'PD')

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| SOURCE_SAOKE_CRB | AMOUNT_CUR | 1:1 | RCVB_AMT_LCY | NUMBER | 25.5 | Số tiền dự thu |  |
| SOURCE_SAOKE_CRB | AMOUNT_LCY | 1:1 | CLS_BAL_LCY | NUMBER | 25.5 | Dư Nợ quy đổi |  |
| SOURCE_SAOKE_CRB | APP_CODE | 1:1 | MUD_CODE | VARCHAR2 | 20 | Mã phân hệ: LD, MD, AC, PD |  |
| SOURCE_SAOKE_CRB | APP_ID | 1:1 | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| SOURCE_SAOKE_CRB | APP_ID | fn_hash("T24_LD_LOANS_AND_DEPOSITS", a.APP_ID) | AR_ID | CHAR | 32 | ID hợp đồng trên DWH | Đổi kiểu dữ liệu `CHAR2` -> `CHAR`. |
| SOURCE_SAOKE_CRB | ASSET_TYPE | 1:1 | AST_TP_CODE | VARCHAR2 | 20 | Loại dư nợ, hạch toán |  |
| SOURCE_SAOKE_CRB | CATEG_CODE | 1:1 | PD_CGY_CODE | VARCHAR2 | 20 | Mã phân loại sản phẩm |  |
| SOURCE_SAOKE_CRB | CO_CODE | 1:1 | OU_CODE | VARCHAR2 | 20 | Mã chi nhánh hạch toán |  |
| SOURCE_SAOKE_CRB | CURR | 1:1 | CCY_CODE | VARCHAR2 | 20 | Loại tiền |  |
| SOURCE_SAOKE_CRB | CUS_ID | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng |  |
| SOURCE_SAOKE_CRB | CUS_ID | fn_hash("T24_CUSTOMER", a.CUS_ID) | CST_ID | CHAR | 32 | ID khách hàng trên DWH | Đổi thành `fn_hash("T24_CUSTOMER", a.CUS_ID)` và kiểu `CHAR`. |
| SOURCE_SAOKE_CRB | LOC_TERM | 1:1 | AR_TERM_TP_CODE | VARCHAR2 | 20 | Mã nhóm kỳ hạn |  |
| SOURCE_SAOKE_CRB | SBV_CODE | 1:1 | GL_ITM_CODE | VARCHAR2 | 20 | Mã hạch toán theo SBV |  |
| SOURCE_SAOKE_CRB | SBV_CODE | fn_hash("T24_GL_ITM", a.SBV_CODE) | GL_ITM_ID | CHAR | 32 | ID Mã hạch toán theo SBV | Bổ sung hàm băm cho GL_ITM_ID và đổi `CHAR2` -> `CHAR`. |
| SOURCE_SAOKE_CRB | SUB_PRO | 1:1 | SUB_PD_CODE | VARCHAR2 | 20 | Mã sản phẩm con |  |
| SOURCE_SAOKE_CRB | TXN_DATE | 1:1 | CDR_DT | DATE |  | Ngày giao dịch |  |
