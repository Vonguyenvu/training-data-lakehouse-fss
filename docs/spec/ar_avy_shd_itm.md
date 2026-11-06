# ar_avy_shd_itm — sheet 'Arrangement Activity Schedule I'

Tầng: Silver Temp 2 (Bank-wised) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_STMT_ENTRY, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV, PG_BRONZE.T24CORE_LD_SCHEDULE_DEFINE_MV

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where · Fields
- 1 · PG_BRONZE · T24CORE_STMT_ENTRY · stmt · main · c · stmt.RECID LIKE 'F%'<br>AND stmt.COMMIT_ACTION <> 'D'<br>AND stmt.BOOKING_DATE = ${ETL_DATE} · CASE<br>        WHEN stmt.OUR_REFERENCE LIKE 'LD%' THEN stmt.OUR_REFERENCE<br>        WHEN stmt.OUR_REFERENCE LIKE 'PD%' THEN SUBSTR(stmt.OUR_REFERENCE, 3)<br>END as contract_id,<br>ABS(COALESCE(stmt.AMOUNT_LCY, 0)) as amount_lcy, *
- 3 · PG_BRONZE · T24CORE_LD_LOANS_AND_DEPOSITS · ld · sub · left · ld.recid=stmt.contract_id · TRUNC(TO_DATE(ld.DATE_TIME, 'YYMMDDHH24MI')) <= TO_DATE(${ETL_DATE}, 'YYYYMMDD') · CATEGORY,<br>co_code
- 4 · PG_BRONZE · T24CORE_PD_PAYMENT_DUE_MV · pdp · sub · left · stmt.CONTRACT_ID = pdp.CONTRACT_ID · SELECT<br>        SUBSTR(pdmv.RECID, 3) AS CONTRACT_ID,<br>        pdmv.PAYMENT_DTE_DUE,<br>        pdmv.CATEGORY,<br>        pdmv.CO_CODE<br>FROM PG_BRONZE.T24CORE_PD_PAYMENT_DUE_MV pdmv<br>WHERE pdmv.FLAG_STATUS <> 'DELETE' AND <br>      pdmv.PAYMENT_DTE_DUE = (SELECT MAX(PREV_SCHED_DATE)<br>        FROM PG_BRONZE.T24CORE_LD_SCHEDULE_DEFINE_MV WHERE CONTRACT_ID = SUBSTR(pdmv.RECID, 3)<br>        AND TO_DATE(PREV_SCHED_DATE, 'YYYYMMDD') <= TO_DATE(${ETL_DATE}, 'YYYYMMDD'))
- 5 · PG_BRONZE · T24CORE_LD_SCHEDULE_DEFINE_MV

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_STMT_ENTRY | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.RECID) | AR_AVY_SHD_ID | CHAR | 32 | ID duy nhất của mã số dòng lịch  trên DWH | Bỏ dấu `\|` để đồng nhất quy tắc băm khóa. |
| T24CORE_STMT_ENTRY | RECID | 1:1 | AR_AVY_SHD_CODE | VARCHAR2 | 32 | Mã số dòng lịch trên hệ thống nguồn |  |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | 'LOAN_PD_SHD' | AR_AVY_SHD_TP | VARCHAR2 | 32 | Phân loại của dòng lịch hợp đồng | Thêm dấu nháy đơn mở đầu `'LOAN_PD_SHD'`. |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.contract_id) | AR_ID | CHAR | 32 | ID duy nhất của hợp đồng trên DWH | Đổi thành `fn_hash("T24_LD_LOANS_AND_DEPOSITS", stmt.contract_id)`. |
| T24CORE_STMT_ENTRY | OUR_REFERENCE | stmt.contract_id | AR_CODE | VARCHAR2 | 32 | Mã của hợp đồng gốc |  |
| T24CORE_STMT_ENTRY, T24CORE_LD_LOANS_AND_DEPOSITS, T24CORE_PD_PAYMENT_DUE_MV | TRANSACTION_CODE, CATEGORY, CRF_PROD_CAT | CASE<br>        WHEN stmt.TRANSACTION_CODE = '402' THEN 'LD_GN'<br>        WHEN stmt.TRANSACTION_CODE IN ('420','423') AND COALESCE(ld.CATEGORY, pdp.CATEGORY, stmt.CRF_PROD_CAT, '_') <> '21069' THEN 'LD_PR'<br>        WHEN stmt.TRANSACTION_CODE IN ('434','424') OR (stmt.TRANSACTION_CODE IN ('420','423') AND COALESCE(ld.CATEGORY, pdp.CATEGORY, stmt.CRF_PROD_CAT) = '21069') THEN 'LD_IN'<br>        WHEN stmt.TRANSACTION_CODE = '750' THEN 'PD_PR'<br>        WHEN stmt.TRANSACTION_CODE = '751' THEN 'PD_IN'<br>        WHEN stmt.TRANSACTION_CODE = '752' THEN 'PD_PE'<br>        WHEN stmt.TRANSACTION_CODE = '753' THEN 'PD_PS'<br>END | PBL_AMT_TP | VARCHAR2 | 20 | Phân loại tiền cần thanh toán trong kỳ bill tương ứng (PS/PE/LD,..) | Đồng nhất alias `pdp.CATEGORY`. |
| T24CORE_STMT_ENTRY | AMOUNT_LCY | ABS(COALESCE(stmt.AMOUNT_LCY, 0)) | PBL_AMT_LCY | NUMBER | 25.5 | Số tiền cần thanh toán quy đổi trong kỳ bill tương ứng |  |
| T24CORE_STMT_ENTRY | AMOUNT_FCY | ABS(COALESCE(stmt.AMOUNT_FCY, 0)) | PBL_AMT_FCY | NUMBER | 25.5 | Số tiền cần thanh toán nguyên tệ trong kỳ bill tương ứng |  |
| T24CORE_STMT_ENTRY | EXCHANGE_RATE | 1:1 | EXG_RATE | NUMBER | 25.7 | Tỷ giá thực hiện | Sửa lại đúng diễn giải. |
| T24CORE_STMT_ENTRY | CURRENCY | 1:1 | CCY_CODE | VARCHAR2 | 20 | Mã loại tiền | Sửa lại đúng diễn giải 'Mã loại tiền'. |
| T24CORE_STMT_ENTRY | VALUE_DATE | 1:1 | EFF_MAT_DT | DATE |  | Ngày hiệu lực của dòng lịch |  |
| T24CORE_PD_PAYMENT_DUE_MV, T24CORE_LD_SCHEDULE_DEFINE_MV | RECID, PAYMENT_DTE_DUE, PREV_SCHED_DATE | CASE<br>        WHEN pdp.CONTRACT_ID IS NOT NULL THEN 1<br>        ELSE 0<br>END | F_LAST_OD_DT | NUMBER | 1 | Cờ hợp đồng có đang tồn tại kỳ trả nợ quá hạn gần nhất hay không | Đồng nhất alias `pdp.CONTRACT_ID` và giữ tên cột chuẩn `F_LAST_OD_DT`. |
| T24CORE_PD_PAYMENT_DUE_MV, T24CORE_LD_SCHEDULE_DEFINE_MV | PAYMENT_DTE_DUE, PREV_SCHED_DATE | TO_DATE(pdp.PAYMENT_DTE_DUE, 'YYYYMMDD') | LAST_OD_DT | DATE |  | Ngày đến hạn của kỳ trả nợ gần nhất đã chuyển sang quá hạn | Chuẩn hóa tên cột `LAST_OD_DT` khớp với INTF_LOAN_REPYMT_SHD. |
| T24CORE_STMT_ENTRY | RECID | 'T24CORE_STMT_ENTRY' | SRC_STM_CODE | VARCHAR2 | 32 | Mã nguồn dữ liệu | Sửa thành `'T24CORE_STMT_ENTRY'`. |
| T24CORE_STMT_ENTRY | CUSTOMER_ID | fn_hash("T24_CUSTOMER", stmt.CUSTOMER_ID) | CST_ID | CHAR | 32 | ID duy nhất của khách hàng liên quan trên DWH | Đổi thành `fn_hash("T24_CUSTOMER", stmt.CUSTOMER_ID)`. |
| T24CORE_STMT_ENTRY | CUSTOMER_ID | stmt.CUSTOMER_ID | CST_CODE | VARCHAR2 | 32 | Mã số khách hàng |  |
| T24CORE_STMT_ENTRY | RECID | ETL_DATE if not exists AR_AVY_SHD_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_STMT_ENTRY | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_STMT_ENTRY | BOOKING_DATE | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
