# pst_entr — sheet 'Posting Entry'

Tầng: Silver Temp 2 (Business) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_STMT_ENTRY, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : TXN
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where · Fields
- 1 · PG_BRONZE · T24CORE_STMT_ENTRY · stmt · main · stmt.RECID NOT LIKE 'F%'<br>AND stmt.COMMIT_ACTION <> 'D'<br>AND stmt.BOOKING_DATE = ${ETL_DATE} · CASE<br>        WHEN stmt.OUR_REFERENCE LIKE 'LD%' THEN stmt.OUR_REFERENCE<br>        WHEN stmt.OUR_REFERENCE LIKE 'PD%' THEN SUBSTR(stmt.OUR_REFERENCE, 3)<br>END as contract_id, *
- 2 · PG_BRONZE · T24CORE_LD_LOANS_AND_DEPOSITS · ld · sub · left · ld.recid=stmt.contract_id · TRUNC(TO_DATE(ld.DATE_TIME, 'YYMMDDHH24MI')) <= TO_DATE(${ETL_DATE}, 'YYYYMMDD') · .
- 3 · PG_BRONZE · T24CORE_PD_PAYMENT_DUE_MV · pd · sub · left · substr(pd.RECID, 3)=stmt.contract_id · pd.FLAG_STATUS <> 'DELETE'<br>AND TRUNC(TO_DATE(pd.DATE_TIME, 'YYMMDDHH24MI')) <= TO_DATE(${ETL_DATE}, 'YYYYMMDD') · .

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_STMT_ENTRY | RECID | fn_hash("T24_STMT_ENTRY", stmt.RECID) | PST_ENTR_ID | CHAR | 32 | ID duy nhất của đối tượng trên DWH | Chuẩn hóa thành `fn_hash("T24_STMT_ENTRY", stmt.recid)`. |
| T24CORE_STMT_ENTRY | RECID | 'T24_STMT_ENTRY' | SRC_STM_CODE | VARCHAR2 | 40 | Mã nguồn dữ liệu |  |
| T24CORE_STMT_ENTRY | RECID | 1:1 | PST_ENTR_NBR | VARCHAR2 | 32 | Mã bút toán hạch toán |  |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.OUR_REFERENCE) | TXN_ID | CHAR | 32 | ID của giao dịch của bút toán trên DWH | Chuẩn hóa thành `fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.OUR_REFERENCE)`. |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | 1:1 | TXN_NBR | VARCHAR2 | 20 | Số giao dịch |  |
| T24CORE_STMT_ENTRY | CRF_TYPE | 1:1 | ACG_CR_DB_F | VARCHAR2 | 20 | Cờ đánh dấu ghi nợ/ghi có |  |
| T24CORE_STMT_ENTRY | TRANSACTION_CODE | 1:1 | TXN_CODE | VARCHAR2 | 20 | Phân loại mã giao dịch |  |
| T24CORE_STMT_ENTRY | BOOKING_DATE | 1:1 | PST_DT | DATE |  | Ngày phát sinh bút toán |  |
| T24CORE_STMT_ENTRY | AMOUNT_FCY | COALESCE(stmt.AMOUNT_FCY, 0) | PST_ENTR_AMT_FCY | NUMBER | 25.5 | Số tiền của bút toán nguyên tệ | Đóng đủ ngoặc `COALESCE(stmt.AMOUNT_FCY, 0)` và sửa Attribute thành `Posting Entry Amount FCY`. |
| T24CORE_STMT_ENTRY | AMOUNT_LCY | COALESCE(stmt.AMOUNT_LCY, 0) | PST_ENTR_AMT_LCY | NUMBER | 25.5 | Số tiền của bút toán quy đổi | Đóng đủ ngoặc `COALESCE(stmt.AMOUNT_LCY, 0)` và sửa Attribute thành `Posting Entry Amount LCY`. |
| T24CORE_STMT_ENTRY | CURRENCY | 1:1 | CCY_CODE | VARCHAR2 | 20 | Mã loại tiền | Bổ sung kiểu dữ liệu `VARCHAR2(20)`. |
| T24CORE_STMT_ENTRY | VALUE_DATE | 1:1 | VAL_DT | DATE |  | Ngày hiệu lực của bút toán |  |
| T24CORE_STMT_ENTRY | EXCHANGE_RATE | 1:1 | EXG_RATE | NUMBER | 25.7 | Tỷ giá thực hiện |  |
| T24CORE_LD_LOANS_AND_DEPOSITS, T24CORE_PD_PAYMENT_DUE_MV, T24CORE_STMT_ENTRY | CO_CODE, COMPANY_CODE | COALESCE(ld.CO_CODE, pd.CO_CODE, stmt.COMPANY_CODE) | OU_CODE | VARCHAR2 | 32 | Chi nhánh hạch toán |  |
| T24CORE_STMT_ENTRY | ACCOUNT_NUMBER | 1:1 | AC_NBR | VARCHAR2 | 40 | Số tài khoản liên quan |  |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | stmt.contract_id | AR_CODE | VARCHAR2 | 40 | Số hợp đồng liên quan |  |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.contract_id) | AR_ID | CHAR | 32 | ID hợp đồng duy nhất liên quan trên DWH | Đổi thành `fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.contract_id)`. |
| T24CORE_STMT_ENTRY | CUSTOMER_ID | fn_hash("T24_CUSTOMER", stmt.CUSTOMER_ID) | CST_ID | CHAR | 32 | ID duy nhất của khách hàng liên quan trên DWH | Đổi thành `fn_hash("T24_CUSTOMER", stmt.CUSTOMER_ID)`. |
| T24CORE_STMT_ENTRY | CUSTOMER_ID | 1:1 | CST_NBR | VARCHAR2 | 20 | Mã số khách hàng |  |
| T24CORE_STMT_ENTRY | PRODUCT_CATEGORY | 1:1 | ACG_PD_CGY | VARCHAR2 | 20 | Loại sản phẩm hạch toán |  |
| T24CORE_STMT_ENTRY | NARRATIVE | 1:1 | PST_ENTR_DSC | VARCHAR2 | 4000 | Mô tả bút toán |  |
| T24CORE_STMT_ENTRY | CONSOL_KEY | 1:1 | CONSOL_KEY | VARCHAR2 | 1000 | Consol key của bút toán STMT |  |
| T24CORE_STMT_ENTRY | SYSTEM_ID | 1:1 | MOD_CODE | VARCHAR2 | 20 | Mã phân hệ giao dịch |  |
| T24CORE_STMT_ENTRY, T24CORE_LD_LOANS_AND_DEPOSITS, T24CORE_PD_PAYMENT_DUE_MV | TRANSACTION_CODE, CATEGORY, CRF_PROD_CAT | CASE        <br>              WHEN stmt.TRANSACTION_CODE ='402' THEN 'LD_GN'<br>              WHEN stmt.TRANSACTION_CODE in ('420','423') AND COALESCE(ld.CATEGORY, pd.CATEGORY, stmt.CRF_PROD_CAT,'_') <> '21069' THEN 'LD_PR'<br>              WHEN stmt.TRANSACTION_CODE in('434','424') OR (stmt.TRANSACTION_CODE in ('420','423') AND COALESCE(ld.CATEGORY, pd.CATEGORY, stmt.CRF_PROD_CAT) ='21069') THEN 'LD_IN'<br>              WHEN stmt.TRANSACTION_CODE = '750' THEN 'PD_PR'<br>              WHEN stmt.TRANSACTION_CODE = '751' THEN 'PD_IN'<br>              WHEN stmt.TRANSACTION_CODE = '752' THEN 'PD_PE'<br>              WHEN stmt.TRANSACTION_CODE = '753' THEN 'PD_PS'<br>         END | PST_ENTR_CMPT | VARCHAR2 | 20 | Phân loại thành phần giao dịch bút toán |  |
| T24CORE_STMT_ENTRY | ACCOUNTING_DATE | 1:1 | ACG_DT | DATE |  | Ngày hạch toán của bút toán |  |
| T24CORE_STMT_ENTRY | ACCT_ID | CASE WHEN stmt.ACCT_ID IS NOT NULL THEN fn_hash("T24_ACCOUNT", stmt.ACCT_ID) ELSE NULL END | AC_ID | CHAR | 32 | ID tài khoản hạch toán trên DWH |  |
| T24CORE_STMT_ENTRY | BALANCE_TYPE | 1:1 | BAL_TP | VARCHAR2 | 20 | Loại bút toán |  |
| T24CORE_STMT_ENTRY | CARD_NUMBER | 1:1 | CARD_NBR | VARCHAR2 | 40 | Số thẻ |  |
| T24CORE_STMT_ENTRY | COMMIT_ACTION | 1:1 | CMMT_ACTN | VARCHAR2 | 20 | Trường kỹ thuật đánh dấu bản ghi IUD |  |
| T24CORE_STMT_ENTRY | COMMIT_TS | 1:1 | CMMT_TMS | TIMESTAMP |  | Thời gian ghi nhận thay đổi bản ghi trên hệ thống |  |
| T24CORE_STMT_ENTRY | CRF_PROD_CAT | 1:1 | CGY_PD_CODE | VARCHAR2 | 20 | Mã Category phân loại bút toán |  |
| T24CORE_STMT_ENTRY | CURR_NO | 1:1 | CRN_NBR | NUMBER | 22 | Trường kỹ thuật, đánh dấu version thay đổi bút toán |  |
| T24CORE_STMT_ENTRY | CYCLE_FORWARD | 1:1 | CYC_FWD | DATE |  | Chu kỳ |  |
| T24CORE_STMT_ENTRY | DATE_TIME | 1:1 | DT_TM | DATE |  | Trường kỹ thuật, ghi nhận thời gian sửa đổi |  |
| T24CORE_STMT_ENTRY | DEPARTMENT_CODE | 1:1 | DEPT_CODE | VARCHAR2 | 20 | Mã đơn vị hạch toán |  |
| T24CORE_STMT_ENTRY | DRAWN_ACCOUNT | 1:1 | DRN_AC | VARCHAR2 | 20 | Tài khoản ghi nhận số tiền rút |  |
| T24CORE_STMT_ENTRY | INTERNAL_CATEGORY | 1:1 | INR_CGY | VARCHAR2 | 20 | Mã Category nội bộ |  |
| T24CORE_STMT_ENTRY | LOCAL_REF | 1:1 | LCL_REFR | VARCHAR2 | 20 | Trường multivalue - đa nghĩa của T24 |  |
| T24CORE_STMT_ENTRY | ORIG_AMOUNT_LCY | 1:1 | ORIG_AMT_LCY | NUMBER | 25.5 | Giá trị hạch toán ban đầu quy đổi |  |
| T24CORE_STMT_ENTRY | ORIGINAL_ACCT | 1:1 | ORIG_AC | VARCHAR2 | 20 | Số tài khoản hạch toán ban đầu |  |
| T24CORE_STMT_ENTRY | ORIGINAL_AMOUNT | 1:1 | ORIG_AMT | NUMBER | 25.5 | Giá trị hạch toán ban đầu nguyên tệ |  |
| T24CORE_STMT_ENTRY | ORIGINAL_CCY | 1:1 | ORIG_CCY | VARCHAR2 | 20 | Loại tiền giao dịch ban đầu | Đổi kiểu dữ liệu thành `VARCHAR2(20)`. |
| T24CORE_STMT_ENTRY | ORIGINAL_EXCH_RATE | 1:1 | ORIG_EXG_RATE | NUMBER | 25.7 | Tỷ giá quy đổi cho loại tiền ban đầu |  |
| T24CORE_STMT_ENTRY | OUTSTANDING_BAL | 1:1 | OTSND_BAL | NUMBER | 25.5 | Dư nợ tín dụng của hợp đồng ( OUR_REFERENCE) |  |
| T24CORE_STMT_ENTRY | OVERRIDE | 1:1 | OVRD | VARCHAR2 | 20 | Ghi đè |  |
| T24CORE_STMT_ENTRY | PROCESS_FORWARD | 1:1 | PCS_FWD | VARCHAR2 | 20 | Tiến trình |  |
| T24CORE_STMT_ENTRY | RECORD_STATUS | 1:1 | RCRD_ST | VARCHAR2 | 20 | Trạng Thái bản ghi |  |
| T24CORE_STMT_ENTRY | REPAYMENT_AMT | 1:1 | REPYMT_AMT | NUMBER | 25.5 | Số tiền thu nợ |  |
| T24CORE_STMT_ENTRY | REPAYMENT_DATE | 1:1 | REPYMT_DT | DATE |  | Ngày thu |  |
| T24CORE_STMT_ENTRY | REPAYMENT_TYPE | 1:1 | REPYMT_TP | VARCHAR2 | 20 | Loại thu nợ |  |
| T24CORE_STMT_ENTRY | SUSPENSE_CATEGORY | 1:1 | SUSP_CGY | VARCHAR2 | 20 | Mã Category phân loại bút toán bị treo |  |
| T24CORE_STMT_ENTRY | SUSPNSE_VALUE_DATE | 1:1 | SUSP_VAL_DT | DATE |  | Ngày bút toán treo |  |
