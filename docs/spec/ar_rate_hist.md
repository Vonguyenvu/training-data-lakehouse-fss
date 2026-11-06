# ar_rate_hist — sheet 'Arrangement Rate History'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS, PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS, PG_BRONZE.T24CORE_PD_PAYMENT_DUE, PG_BRONZE.FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 2
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_LD_LOANS_AND_DEPOSITS · a
- PG_BRONZE · FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE · d · (left join) ON d.CONTRACT_REF_NO = a.RECID<br>AND d.MOV_DATE = TO_DATE(COALESCE(a.ORIG_VAL_DATE,a.VALUE_DATE), 'YYYYMMDD')

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_LD_LOANS_AND_DEPOSITS | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS", a.RECID) | AR_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | RECID | 1:1 | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | INT_RATE_TYPE | 1:1 | INT_RATE_VARIABLITY_TP_CODE | VARCHAR2 | 20 | Loại lãi suất : Fix , float |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | INT_VALUE_DATE | 1:1 | INT_RATE_EFF_DT | DATE |  | Ngày hiệu lực lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | INTEREST_RATE | 1:1 | EFF_RATE_PCT | NUMBER | 25.7 | Giá trị lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | INTEREST_SPREAD | 1:1 | SPRD_RATE_PCT | NUMBER | 25.7 | Biên độ lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | PE_RATE | 1:1 | PNY_RATE | NUMBER | 25.7 | Lãi phạt penalty rate |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | PS_RATE | 1:1 | ODUE_INT_RATE | NUMBER | 25.7 | Lãi suất cho quá hạn |  |
| FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE | BIEN_DO_THAY_DOI_LS_THEO_HDTD | 1:1 | MRGN_RATE | NUMBER | 25.7 | Biên độ thay đổi lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | RECID | ETL_DATE if not exists AR_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_LD_LOANS_AND_DEPOSITS | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
| Khởi tạo |  |  |  |  |  |  |  |
| Bảng nguồn | Short table | Business Rule |  |  |  |  |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | ldh | WHERE ldh.CURR_NO =  (SELECT  max(CURR_NO) FROM PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS t<br>WHERE SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1) = SUBSTR(t.RECID,1,INSTR(t.RECID,';')-1) )<br><br>AND NOT EXISTS (SELECT * FROM PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS_HIS t<br>WHERE SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1) = SUBSTR(t.RECID,1,INSTR(t.RECID,';')-1)<br>AND NVL(t.RECORD_STATUS,'_') = 'REVE' )<br><br>and NOT EXISTS (SELECT * FROM PG_BRONZE.T24CORE_LD_LOANS_AND_DEPOSITS ld<br>WHERE SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1) = ld.RECID ) |  |  |  |  |  |
| FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE | d | (left join) ON d.CONTRACT_REF_NO = SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1)<br>AND d.MOV_DATE  = TO_DATE(COALESCE(ldh.ORIG_VAL_DATE,ldh.VALUE_DATE), 'YYYYMMDD') |  |  |  |  |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS",SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1)) | AR_ID | CHAR | 32 | Unique key trên DWH |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1) | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng | Cắt bỏ hậu tố ';curr_no' bằng SUBSTR(ldh.RECID,1,INSTR(ldh.RECID,';')-1) cho AR_CODE ở Nhánh 2 (LD_HIS) để khớp với LOAN_AR.AR_CODE. |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | INT_RATE_TYPE | 1:1 | INT_RATE_VARIABLITY_TP_CODE | VARCHAR2 | 20 | Loại lãi suất : Fix , float |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | INT_VALUE_DATE | 1:1 | INT_RATE_EFF_DT | DATE |  | Ngày hiệu lực lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | INTEREST_RATE | 1:1 | EFF_RATE_PCT | NUMBER | 25.7 | Giá trị lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | INTEREST_SPREAD | 1:1 | SPRD_RATE_PCT | NUMBER | 25.7 | Biên độ lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | NULL | PNY_RATE | NUMBER | 25.7 | Lãi phạt penalty rate |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | NULL | ODUE_INT_RATE | NUMBER | 25.7 | Lãi suất cho quá hạn |  |
| FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE | BIEN_DO_THAY_DOI_LS_THEO_HDTD | 1:1 | MRGN_RATE | NUMBER | 25.7 | Biên độ thay đổi lãi suất |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | ETL_DATE if not exists AR_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_LD_LOANS_AND_DEPOSITS_HIS | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
|  |  |  |  |  |  |  |  |
| Bảng nguồn | Short table | Business Rule |  |  |  |  |  |
| T24CORE_PD_PAYMENT_DUE | d |  |  |  |  |  |  |
| T24CORE_PD_PAYMENT_DUE | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS", SUBSTR(d.RECID, 1, 14)) | AR_ID | CHAR | 32 | Unique key trên DWH | Khai báo alias `d` và sửa thành `SUBSTR(d.RECID, 1, 14)`. |
| T24CORE_PD_PAYMENT_DUE | RECID | SUBSTR(d.RECID, 1, 14) | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng | Cắt SUBSTR(d.RECID, 1, 14) cho AR_CODE ở Nhánh 3 (PD) để khớp với khóa băm AR_ID ở dòng 46. |
| T24CORE_PD_PAYMENT_DUE | RECID | NULL | INT_RATE_VARIABLITY_TP_CODE | VARCHAR2 | 20 | Loại lãi suất : Fix , float |  |
| T24CORE_PD_PAYMENT_DUE | RECID | NULL | INT_RATE_EFF_DT | DATE |  | Ngày hiệu lực lãi suất |  |
| T24CORE_PD_PAYMENT_DUE | RECID | NULL | EFF_RATE_PCT | NUMBER | 25.7 | Giá trị lãi suất |  |
| T24CORE_PD_PAYMENT_DUE | RECID | NULL | SPRD_RATE_PCT | NUMBER | 25.7 | Biên độ lãi suất |  |
| T24CORE_PD_PAYMENT_DUE | PE_RATE | 1:1 | PNY_RATE | NUMBER | 25.7 | Lãi phạt penalty rate |  |
| T24CORE_PD_PAYMENT_DUE | PS_RATE | 1:1 | ODUE_INT_RATE | NUMBER | 25.7 | Lãi suất cho quá hạn |  |
| T24CORE_PD_PAYMENT_DUE | RECID | NULL | MRGN_RATE | NUMBER | 25.7 | Biên độ thay đổi lãi suất |  |
| T24CORE_PD_PAYMENT_DUE | RECID | ETL_DATE if not exists AR_ID | SYS_EFF_DT | DATE |  | Ngày bản ghi lần đầu tiên vào hệ thống |  |
| T24CORE_PD_PAYMENT_DUE | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hạn của bản ghi |  |
| T24CORE_PD_PAYMENT_DUE | RECID | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày update dữ liệu gần nhất |  |
