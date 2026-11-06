# fct_loan_ar — sheet 'Fact Loan Arrangement'

Tầng: Gold / Mart (Optional) · Wave: WAVE_4_GOLD_FACT · Chờ: PG_SILVER.LOAN_AR, PG_SILVER.AR_BAL, PG_SILVER.LOAN_AR_PRFL, PG_SILVER.AR_RATE_HIST, PG_SILVER.AR_DLQ_SMY, PG_SILVER.EXG_RATE, PG_SILVER.AST_AR_INT_SMY, PG_SILVER.AR_TVR_SMY, PG_SILVER.IDV_PRFL, PG_SILVER.ORG_PRFL, PG_GOLD.DIM_LOAN_AR, PG_GOLD.DIM_CST, PG_GOLD.DIM_PD, PG_GOLD.DIM_OU, PG_GOLD.DIM_CCY, PG_GOLD.DIM_LMT, PG_GOLD.DIM_RSTC_TP, PG_GOLD.DIM_FNC_ST

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- Nguồn · Bảng nguồn · Short table · Business Rule · Ghi chú kỹ thuật & Business Rule
- PG_SILVER · LOAN_AR · a · WHERE a.SYS_EXP_DT IS NULL · Bổ sung `WHERE a.SYS_EXP_DT IS NULL`.
- PG_SILVER · AR_BAL · b · (join) (SELECT DISTINCT AR_ID, CDR_DT, MUD_CODE FROM PG_SILVER.AR_BAL WHERE CDR_DT = ${ETL_DATE}) b on a.AR_ID = b.AR_ID · Khử trùng `(SELECT DISTINCT AR_ID, CDR_DT, MUD_CODE FROM PG_SILVER.AR_BAL WHERE CDR_DT = ${ETL_DATE})` vì `AR_BAL` có nhiều dòng theo `GL_ITM_CODE` (`2%`, `394%`, `94%`) trên mỗi `AR_ID`; nếu join trực tiếp sẽ làm nhân bản số dòng và nhân gấp bội dư nợ `OTSND_AMT_LCY`.
- PG_SILVER · LOAN_AR_PRFL · c · (left join) on a.AR_ID = c.AR_ID AND c.SYS_EXP_DT IS NULL · Bổ sung `AND c.SYS_EXP_DT IS NULL`.
- PG_SILVER · AR_RATE_HIST · d · (left join) on a.AR_ID = d.AR_ID AND d.SYS_EXP_DT IS NULL · Bổ sung `AND d.SYS_EXP_DT IS NULL`.
- PG_SILVER · AR_DLQ_SMY · e · (left join) (SELECT<br>  ORIG_AR_ID<br>  ,MAX(${ETL_DATE} - e.PNP_PAST_DUE_DT) + 1 AS SO_NGAY_QH_GOC<br>  ,MAX(${ETL_DATE} - e.INT_PAST_DUE_DT) + 1 AS SO_NGAY_QH_LAI<br>  ,GREATEST(NVL(MAX(${ETL_DATE} - e.PNP_PAST_DUE_DT) + 1, 0), NVL(MAX(${ETL_DATE} - e.INT_PAST_DUE_DT) + 1, 0)) AS SONGAY_QHAN_CAONHAT<br>  ,MAX(NVL(e.ADDITION_DYS_IN_ARS, 0)) AS SNQH_CHUYENDOI<br>FROM PG_SILVER.AR_DLQ_SMY e<br>WHERE e.CDR_DT = ${ETL_DATE}<br>GROUP BY ORIG_AR_ID) e<br>on e.ORIG_AR_ID = a.AR_ID · Đổi `SUM` thành `MAX` và sửa lại dấu ngoặc đơn.
- PG_SILVER · EXG_RATE · g · (left join) on a.CCY_CODE = g.FRST_CCY_CODE AND g.SNPST_DT = ${ETL_DATE} · Đổi thành `PG_SILVER.EXG_RATE` (Task 30) và lọc `g.SNPST_DT = ${ETL_DATE}`.
- PG_SILVER · AST_AR_INT_SMY · h · (left join) (SELECT<br>  ORIG_AR_ID<br>  ,SUM(TOT_INT_PAID_AMT_FCY) AS TOT_INT_PAID_AMT_FCY<br>  ,SUM(TOT_INT_DUE_AMT_FCY) AS TOT_INT_DUE_AMT_FCY<br>  ,SUM(TOT_INT_ODUE_AMT_FCY) AS TOT_INT_ODUE_AMT_FCY<br>FROM PG_SILVER.AST_AR_INT_SMY<br>WHERE CDR_DT = ${ETL_DATE}<br>GROUP BY ORIG_AR_ID) h<br>on a.AR_ID = h.ORIG_AR_ID
- PG_SILVER · AR_TVR_SMY · k · (left join) (SELECT<br>  ORIG_AR_ID<br>  ,SUM(CLS_BAL_LCY) AS CLS_BAL_LCY<br>FROM PG_SILVER.AR_TVR_SMY<br>WHERE CDR_DT = ${ETL_DATE}<br>GROUP BY ORIG_AR_ID) k<br>on a.AR_ID = k.ORIG_AR_ID
- PG_SILVER · IDV_PRFL · l · (left join) on a.CST_ID = l.CST_ID AND l.SYS_EXP_DT IS NULL · Bổ sung `AND l.SYS_EXP_DT IS NULL`.
- PG_SILVER · ORG_PRFL · m · (left join) on a.CST_ID = m.CST_ID AND m.SYS_EXP_DT IS NULL · Bổ sung `AND m.SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_LOAN_AR · dim_ar · (join) on a.AR_ID = dim_ar.AR_ID AND dim_ar.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_CST · dim_cst · (join) on a.CST_ID = dim_cst.CST_ID AND dim_cst.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_PD · dim_pd · (left join) on a.PD_CODE = dim_pd.PD_CODE AND dim_pd.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_OU · dim_ou · (left join) on c.OU_CODE = dim_ou.OU_CODE AND dim_ou.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_CCY · dim_ccy · (left join) on a.CCY_CODE = dim_ccy.CCY_CODE AND dim_ccy.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_LMT · dim_lmt · (left join) on a.LMT_ID = dim_lmt.LMT_ID AND dim_lmt.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL` + đổi tên `DIM_LIMIT` -> `DIM_LMT` (Task 21).
- PG_GOLD · DIM_RSTC_TP · dim_rstc · (left join) on c.DBT_RSTC_TP_CODE = dim_rstc.RSTC_TP_CODE AND dim_rstc.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_FNC_ST · dim_fnc_1 · (left join) on c.FNC_ST_CODE = dim_fnc_1.FNC_ST_CODE AND dim_fnc_1.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.
- PG_GOLD · DIM_FNC_ST · dim_fnc_2 · (left join) on NVL(l.CST_FNC_ST_CODE, m.CST_FNC_ST_CODE) = dim_fnc_2.FNC_ST_CODE AND dim_fnc_2.SYS_EXP_DT IS NULL · Bổ sung `SYS_EXP_DT IS NULL`.

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| AR_BAL | CDR_DT | ${ETL_DATE} | CDR_DT_DIM_KEY | DATE |  | Chiều ngày dữ liệu |  |
| DIM_LOAN_AR | DIM_KEY | dim_ar.DIM_KEY | LOAN_AR_DIM_KEY | CHAR | 40 | Chiều Hợp đồng vay |  |
| DIM_CST | DIM_KEY | dim_cst.DIM_KEY | CST_DIM_KEY | CHAR | 40 | Chiều Khách hàng |  |
| DIM_PD | DIM_KEY | dim_pd.DIM_KEY | PD_DIM_KEY | CHAR | 40 | Chiều Sản phẩm |  |
| DIM_OU | DIM_KEY | dim_ou.DIM_KEY | OU_DIM_KEY | CHAR | 40 | Chiều chi nhánh |  |
| DIM_CCY | DIM_KEY | dim_ccy.DIM_KEY | CCY_DIM_KEY | CHAR | 40 | Chiều loại tiền |  |
| DIM_LMT | DIM_KEY | dim_lmt.DIM_KEY | LMT_DIM_KEY | CHAR | 40 | Chiều hạn mức | Đổi thành `DIM_LMT`. |
| DIM_RSTC_TP | DIM_KEY | dim_rstc.DIM_KEY | LOAN_RSTC_TP_DIM_KEY | CHAR | 40 | Chiều loại tái cấu trúc |  |
| DIM_FNC_ST | DIM_KEY | dim_fnc_1.DIM_KEY | LOAN_AR_FNC_ST_DIM_KEY | CHAR | 40 | Chiều nhóm nợ hợp đồng vay |  |
| DIM_FNC_ST | DIM_KEY | dim_fnc_2.DIM_KEY | CST_FNC_ST_DIM_KEY | CHAR | 40 | Chiều nhóm nợ khách hàng |  |
| AR_BAL | MUD_CODE | 1:1 | MUD_CODE | VARCHAR2 | 20 | Mã phân hệ |  |
| AR_RATE_HIST | PNY_RATE | 1:1 | PNY_RATE | NUMBER | 25.7 | Lãi phạt penalty rate |  |
| AR_RATE_HIST | ODUE_INT_RATE | 1:1 | ODUE_INT_RATE | NUMBER | 25.7 | Lãi suất cho quá hạn |  |
| AST_AR_INT_SMY | TOT_INT_DUE_AMT_FCY, TOT_INT_ODUE_AMT_FCY | NVL(h.TOT_INT_DUE_AMT_FCY, 0) + NVL(h.TOT_INT_ODUE_AMT_FCY, 0) | TOT_INT_ARS_FCY | NUMBER | 32.5 | Tổng lãi phải trả |  |
| AST_AR_INT_SMY | TOT_INT_PAID_AMT_FCY | NVL(h.TOT_INT_PAID_AMT_FCY, 0) | TOT_INT_PAID_AMT_FCY | NUMBER | 32.5 | Tổng lãi đã trả |  |
| AR_DLQ_SMY | PNP_PAST_DUE_DT | NVL(e.SO_NGAY_QH_GOC, 0) | DYS_IN_PNP_ARS | NUMBER | 32 | Số ngày quá hạn gốc | Tính `SO_NGAY_QH_GOC` bằng hàm `MAX(...)` thay vì `SUM(...)`. |
| AR_DLQ_SMY | INT_PAST_DUE_DT | NVL(e.SO_NGAY_QH_LAI, 0) | DYS_IN_INT_ARS | NUMBER | 32 | Số ngày quá hạn lãi | Tính `SO_NGAY_QH_LAI` bằng hàm `MAX(...)` thay vì `SUM(...)`. |
| AR_DLQ_SMY | PNP_PAST_DUE_DT, INT_PAST_DUE_DT, ADDITION_DYS_IN_ARS | NVL(e.SONGAY_QHAN_CAONHAT, 0) + NVL(e.SNQH_CHUYENDOI, 0) | MX_DYS_IN_ARS | NUMBER | 32 | Số ngày quá hạn cao nhất | Tính số ngày quá hạn cao nhất từ GREATEST(MAX(PNP_PAST_DUE_DT), MAX(INT_PAST_DUE_DT)) + 1 tại subquery e. |
| AR_DLQ_SMY | ADDITION_DYS_IN_ARS | NVL(e.SNQH_CHUYENDOI, 0) | ADDITION_DYS_IN_ARS | NUMBER | 32 | Số ngày quá hạn chuyển đổi |  |
| AR_TVR_SMY | CLS_BAL_LCY | NVL(k.CLS_BAL_LCY, 0) | OTSND_AMT_LCY | NUMBER | 32.5 | Dư nợ quy đổi |  |
| EXG_RATE | MID_RATE | 1:1 | EXG_RATE_TO_LCL_CCY | NUMBER | 25.7 | Tỷ giá | Đổi thành `EXG_RATE`. |
| LOAN_AR_PRFL | NBR_OF_DBT_RSTC | 1:1 | NBR_OF_DBT_RSTC | NUMBER | 22 | Số lần cơ cấu |  |
