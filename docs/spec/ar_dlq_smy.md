# ar_dlq_smy — sheet 'Arrangement Delinquency Summary'

Tầng: Silver Temp 2 (Bank-wised) · Wave: WAVE_2_SILVER_TEMP2 · Chờ: PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS_MV, PG_BRONZE.T24CORE_PD_PAYMENT_DUE

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_PD_PAYMENT_DUE_HIS_MV · a · WHERE a.FLAG_STATUS = 'LIVE'<br>  AND a.PAY_TYPE IN ('PR', 'IN')<br>  AND NVL(a.PD_TYPE, '0') <> '1'<br>  AND a.RECORD_STATUS IS NULL<br>  AND NVL(a.RECORD_STATUS, '_') <> 'REVE'<br>  AND a.PAY_AMT_OUTS > 0<br>  AND a.DATE_TIME = (SELECT MAX(b2.DATE_TIME) FROM PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS_MV b2 WHERE b2.RECID = a.RECID AND a.PAY_TYPE = b2.PAY_TYPE)<br>  AND a.CURR_NO = (SELECT MAX(b2.CURR_NO) FROM PG_BRONZE.T24CORE_PD_PAYMENT_DUE_HIS_MV b2 WHERE b2.RECID = a.RECID AND a.PAY_TYPE = b2.PAY_TYPE)<br>GROUP BY SUBSTR(a.RECID, 1, 14)
- PG_BRONZE · T24CORE_PD_PAYMENT_DUE · b · (left join) a.recid = b.recid

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_PD_PAYMENT_DUE_HIS_MV | PAYMENT_DTE_DUE | ${ETL_DATE} | CDR_DT | DATE |  | Ngày dữ liệu | Gán biến ngày chạy `${ETL_DATE}` cho CDR_DT. |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS",SUBSTR(a.RECID,1,14 )) | AR_ID | CHAR | 32 | ID của hợp đồng |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | RECID | SUBSTR(a.RECID,1,14 ) | AR_CODE | VARCHAR2 | 40 | Mã hợp đồng |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | RECID | fn_hash("T24_LD_LOANS_AND_DEPOSITS", CASE WHEN a.RECID LIKE 'PDLD%' THEN SUBSTR(a.RECID, 3, 12) ELSE SUBSTR(a.RECID, 1, 14) END) | ORIG_AR_ID | CHAR | 32 | ID của hợp đồng gốc |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | RECID | CASE WHEN a.RECID LIKE 'PDLD%' THEN SUBSTR(a.RECID, 3, 12) ELSE SUBSTR(a.RECID, 1, 14) END | ORIG_AR_CODE | VARCHAR2 | 40 | Mã hợp đồng gốc |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | RECID | 'T24_PD_PAYMENT_DUE_HIS_MV' | SRC_STM_CODE | VARCHAR2 | 32 | Mã nguồn dữ liệu | Gán mã nguồn `'T24_PD_PAYMENT_DUE_HIS_MV'` cho SRC_STM_CODE. |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | PAYMENT_DTE_DUE, PAY_TYPE, CATEGORY | MIN(CASE<br>        WHEN a.PAY_TYPE = 'PR' AND a.CATEGORY <> 21069<br>        THEN TO_DATE(a.PAYMENT_DTE_DUE, 'RRRRMMDD')<br>        ELSE NULL<br>END) | PNP_PAST_DUE_DT | DATE |  | Ngày quá hạn gốc |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | PAYMENT_DTE_DUE, PAY_TYPE, CATEGORY | MIN(CASE<br>        WHEN (a.PAY_TYPE = 'IN' OR (a.CATEGORY = 21069 AND a.PAY_TYPE = 'PR'))<br>        THEN TO_DATE(a.PAYMENT_DTE_DUE, 'RRRRMMDD')<br>        ELSE NULL<br>END) | INT_PAST_DUE_DT | DATE |  | Ngày quá hạn lãi |  |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | PAY_AMT_OUTS, PAY_TYPE, CATEGORY | SUM(CASE<br>        WHEN a.PAY_TYPE = 'PR' AND a.CATEGORY <> 21069<br>        THEN a.PAY_AMT_OUTS<br>        ELSE 0<br>END) | PNP_ARS | NUMBER | 25.5 | Số tiền quá hạn gốc | Đổi từ MIN(...) sang SUM(...) cho PNP_ARS. |
| T24CORE_PD_PAYMENT_DUE_HIS_MV | PAY_AMT_OUTS, PAY_TYPE, CATEGORY | SUM(CASE<br>        WHEN (a.PAY_TYPE = 'IN' OR (a.CATEGORY = 21069 AND a.PAY_TYPE = 'PR'))<br>        THEN a.PAY_AMT_OUTS<br>        ELSE 0<br>END) | INT_ARS | NUMBER | 25.5 | Số tiền quá hạn lãi | Đổi từ MIN(...) sang SUM(...) cho INT_ARS. |
| T24CORE_PD_PAYMENT_DUE | SNQH_CHUYENDOI | MAX(b.SNQH_CHUYENDOI) | ADDITION_DYS_IN_ARS | NUMBER | 22 | Số ngày quá hạn chuyển đổi |  |
