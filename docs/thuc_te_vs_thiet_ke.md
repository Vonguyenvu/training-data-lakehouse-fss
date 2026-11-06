# Thực tế khác thiết kế (Excel `Training_Fresher_DeepChecked.xlsx`)

Cập nhật: 2026-11-04. Phạm vi: Bronze (28 bảng) + Silver Temp 1 (13 bảng).
Nguyên tắc: **Oracle / dữ liệu Bronze là sự thật**; chỗ lệch được xử lý trong code và ghi ở comment đầu file model.

---

## 1. Kiến trúc & quy trình

| Thiết kế (Excel) | Thực tế dự án | Lý do |
|---|---|---|
| Bronze/Silver/Gold là file `sql/*.sql` chạy Spark (`INSERT OVERWRITE`) | Model dbt (`dbt/models/<bronze\|silver_temp1\|silver_temp2\|gold>/`), thực thi trên Spark qua Thrift Server (dbt-spark) | Logic tập trung ở dbt: incremental/merge, test, lineage Oracle → Bronze → Silver; Spark vẫn là engine |
| Docstring DAG ghi `dag_wave0_bronze_ingest` | dag_id thật là `wave0_bronze_ingest` | Docstring sai |
| — | Nessie không hỗ trợ VIEW → `views_enabled: false`, không dùng `materialized='view'` | Giới hạn catalog |
| Excel dùng `${ETL_DATE}` cho cả ngày batch lẫn ngày nghiệp vụ | Tách `etl_date()` (partition Bronze) và `biz_date()` (BOOKING_DATE / MOV_DATE / PREV_SCHED_DATE), mặc định bằng nhau | Bronze là bản chụp toàn bộ: dữ liệu nghiệp vụ chỉ có 2025-09 → 2026-02, còn ETL_DATE là 2026-10/11 → điều kiện `BOOKING_DATE = ETL_DATE` trả 0 dòng |

## 2. Bronze: cấu trúc Excel (sheet DDL) vs Oracle

Chi tiết từng cột: sheet `Oracle_vs_Excel`, `Tong_hop` trong `Training_Fresher_DeepChecked_vs_Oracle.xlsx` (đối chiếu 2026-10-29).
Tổng: Excel 392 cột / Oracle 541 cột — 203 khớp, 122 sai kiểu, **67 cột Excel có mà Oracle không có** (Bronze nạp `CAST(NULL AS STRING)`), 216 cột chỉ Oracle có (Bronze vẫn mirror).

Bảng thiếu cột so với Excel (ảnh hưởng Silver):

| Bảng Bronze | Excel | Oracle | Thiếu trên Oracle | Ảnh hưởng |
|---|---|---|---|---|
| `t24core_customer` | 63 | 10 | 55 (NATIONAL_ID, EMAIL_ADDRESS, HOME_NUMBER, VN_STREET, VN_TOWN, COUNTRY, STREET, RESIDENCE, …) | `ip_alt_identn`, `ip_pst_adr` rỗng; `ip_elc_adr` chỉ có nhánh MOBILE |
| `t24core_limit` | 6 | 2 | 5 (LIMIT_PRODUCT, INTERNAL_AMOUNT, MAXIMUM_TOTAL, ONLINE_LIMIT_DATE, EXPIRY_DATE) | cột tương ứng của `lmt` NULL |
| `t24core_ld_loans_and_deposits` | 39 | 39 | 1 (ID) | — |
| `t24core_ld_loans_and_deposits_his` | 29 | 28 | 1 (COMMIT_ACTION) | `sk_lich_tra_no.ldh_commit_action` NULL |
| `t24core_pd_payment_due` | 21 | 21 | 1 (FLAG_STATUS) | `sk_lich_tra_no.pd_flag_status` NULL |
| `t24core_pd_payment_due_mv` | 23 | 22 | 2 (COMMIT_ACTION, ID) | cột tương ứng NULL |
| `los_app_product` | 4 | 3 | 1 (RECID) | — |
| `source_saoke_crb` | 17 | 16 | 1 | — |

Mọi cột Bronze là `STRING` (Excel ghi DATE/NUMBER) → Silver tự parse.

## 3. Định dạng dữ liệu thực tế khác Excel

Excel ghi mọi cột ngày là `TO_DATE(x, 'YYYYMMDD')`, số là `CAST(x AS DECIMAL)`. Thực tế trên Bronze:

| Cột | Định dạng thật | Xử lý |
|---|---|---|
| T24 `*_DATE` (VALUE_DATE, BOOKING_DATE T24/SMY, …) | `yyyyMMdd` (`20250902`) | macro `t24_date` |
| `DATE_TIME` (T24) | `yyMMddHHmm` (`2509032026`), mất số 0 đầu | macro `t24_datetime` → `CAST(... AS DATE)` |
| `MOV_DATE`, `BOOKING_DATE` (FLEXBO, LOS) | `yyyy-MM-dd HH:mm:ss.SSS` | `TRY_CAST(SUBSTR(x,1,10) AS DATE)` |
| `NGAY_HET_COVID19` | `dd/MM/yyyy` | `DATE_PARSE(x, '%d/%m/%Y')` |
| `COMMIT_TS` (SMY_STMT_DAILY) | `26-SEP-25 10.12.53.000000 PM` | `DATE_PARSE(x, '%d-%b-%y %h.%i.%s.%f %p')` |
| Cột NUMBER Oracle (ASSET_CLASS, SECTOR, …) | `'1602.0000000000'` | chuẩn hóa `CAST(TRY_CAST(x AS DECIMAL(20,0)) AS VARCHAR)` trước khi join/so mã |
| Số có khoảng trắng (`' 4.00'`) | `TRY_CAST` không TRIM → NULL | luôn `TRY_CAST(TRIM(x) AS DECIMAL(p,s))` |
| MID_REVAL_RATE | đa giá trị `#` | macro `t24_multi_value` |
| `STMT_ENTRY.COMMIT_ACTION` | NULL ở 18.526 / 89.869 dòng | `COALESCE(x,'') <> 'D'` (Excel `<> 'D'` sẽ loại hết dòng NULL) |

## 4. Silver Temp 1 — từng bảng

### Đặc tả sai / được sửa

| Bảng | Excel | Thực tế / đã làm | Lý do |
|---|---|---|---|
| `ar_rate_hist` | Nhánh PD: `fn_hash(..., SUBSTR(d.RECID,1,14))` | `SUBSTR(d.RECID,3,12)` | RECID PD dạng `PDLD2524400302` → (1,14) là cả chuỗi, không bao giờ khớp AR_ID của LD (`LD2524400302`). Ghi chú Excel yêu cầu "khớp khóa băm AR_ID" |
| `ar_rate_hist` | 3 nhánh `UNION ALL` | Gộp 1 dòng / AR_ID: LD > LD_HIS > PD; PE/PS_RATE lấy PD khi LD NULL | SCD2 MERGE cần khóa duy nhất mỗi ngày; 4.962 hợp đồng PD trùng LD |
| `ar_rate_hist` | Nhánh LD_HIS ghi "Khởi tạo" | Chạy mọi ngày | Đã loại hợp đồng còn trong LD nên không trùng; giữ phiên bản cuối của hợp đồng vừa tất toán |
| `ip_pst_adr` | `c.VN_STREET \|\| ',' \|\| ...`, không lọc NOT NULL | `concat_ws` bỏ phần rỗng; bỏ dòng không có phần địa chỉ nào | Trino `\|\|` trả NULL khi 1 phần NULL (Oracle thì không); tránh 2 dòng rỗng / khách hàng |
| `cust_info_daily`, `sk_lich_tra_no` | Nhiều bảng phụ không lọc `ETL_DATE` (m, col_udf, ld_los, pdhmv, sch) | Lọc `etl_date` mọi bảng | Bronze giữ nhiều partition → nhân bản dòng |
| `cust_info_daily` | `m.VERSION_NO = (SELECT MAX ...)` | `ROW_NUMBER()` | Tương đương, nhanh hơn |
| `cust_info_daily` | Join toàn bộ lịch sử `udf_h`, `rt_h` | Bản `MOV_DATE` mới nhất ≤ ngày nghiệp vụ / hợp đồng | Tránh nhân dòng (rt_h 166k dòng lịch sử) |
| `sk_lich_tra_no` | Không ghi grain; join thẳng 10 bảng | Grain = dòng PD_PAYMENT_DUE_MV × bút toán STMT_ENTRY trong ngày; pd/pdh/ldh/pdhmv lấy CURR_NO lớn nhất, sch PREV_SCHED_DATE mới nhất, mg 1 dòng / LD_ID | LD_HIS tới 15 phiên bản / hợp đồng; **cần mentor xác nhận** |
| `sk_lich_tra_no` | `cus.SECTOR = sec.RECID` | Chuẩn hóa `'1602.0000000000'` → `'1602'` | Khác định dạng → 0 dòng khớp |
| `cv` | Mã ASSET_CLASS | Chuẩn hóa `'1.0000000000'` → `'1'` | Khớp bảng mã chuẩn |
| SCD TYPE 2 (4 bảng) | `SYS_EFF_DT` = "ngày lần đầu vào hệ thống" (ip_alt_identn, ar_rate_hist) | `SYS_EFF_DT` = ngày bắt đầu phiên bản | Đúng ngữ nghĩa SCD2 theo Master guide |

### Dữ liệu thực tế không khớp (đặc tả đúng, nguồn không có dữ liệu) — ngày 2026-11-03

| Bảng | Join / cột | Kết quả | Nguyên nhân |
|---|---|---|---|
| `ip_alt_identn`, `ip_pst_adr` | toàn bảng | 0 dòng | CUSTOMER không có cột (mục 2) |
| `ip_elc_adr` | EMAIL, HOME_NUMBER | 0 dòng | như trên; MOBILE có 2.000 / 36.346 KH |
| `cust_info_daily` | `m` (CONTRACT_MASTER) | 0 khớp | `CONTRACT_REF_NO` là mã FCC (`208D...`), bút toán dùng mã T24 (`LD...`) |
| `cust_info_daily` | `ld_los` / `fac` / `pd_los` | 0 khớp | LOAN_DISBURSEMENT chỉ 47 dòng, 5 dòng qua lọc `AMND_STATE='F' AND STATUS IN ('A','U')` |
| `cust_info_daily` | `udf_h` | 0 | PGBLD_CONTRACT_UDFIELD_HIST rỗng |
| `sk_lich_tra_no` | `pdh` | 0 khớp | PD_PAYMENT_DUE_HIS.RECID toàn NULL |
| `sk_lich_tra_no` | `pdhmv`, `mg` | 0 khớp | Không có RECID / LD_ID chung với PD_PAYMENT_DUE_MV |
| `ar_rate_hist` | `mrgn_rate` (tdate) | ~0 | Chỉ 5 hợp đồng có `MOV_DATE = ORIG_VAL_DATE/VALUE_DATE` |
| `pd` | PD_NM | NULL với mã chỉ có ở FLEXBO/LD | Chỉ LOS_APP_PRODUCT có tên; 1 PRODUCT_CODE nhiều tên → lấy ID lớn nhất |

### Chất lượng nguồn cần lưu ý

- `T24CORE_PD_PAYMENT_DUE`: 8.038 dòng nhưng chỉ 2.739 RECID (dòng trùng, cùng lãi suất) → gom theo RECID.
- `T24CORE_PD_PAYMENT_DUE_MV`: không có khóa duy nhất kể cả `(RECID, PAY_TYPE)` (157 cặp / 261 dòng).
- `T24CORE_LD_SCHEDULE_DEFINE_MV`: 26.277 dòng / 26.275 CONTRACT_ID.
- 2 partition Bronze hiện có (2026-10-29, 2026-11-03) giống hệt nhau → chưa quan sát được thay đổi SCD thực tế.

## 4b. Silver Temp 2 — từng bảng (2026-11-04)

| Bảng | Excel | Thực tế / đã làm | Lý do |
|---|---|---|---|
| SCD2 (idv_prfl, idv_emp_st, org_prfl, loan_ar, ar_avy_shd_itm) | Viết tay từng bảng | Macro `scd2` | Bảng 30–100+ cột |
| `ar_avy_shd_itm` | SCD2 đóng dòng khi RECID biến mất | `close_missing=false` | Nguồn chỉ là bút toán 1 ngày → bút toán ngày trước luôn "biến mất" |
| `cst`, `idv_prfl`, `org_prfl`, `pst_entr` | So mã SECTOR / ASSET_CLASS / CATEGORY trực tiếp | Macro `t24_code` (`'1602.0000000000'` → `'1602'`) | Số Oracle lưu dạng chuỗi có phần thập phân |
| `ar_dlq_smy` | Join PD theo `a.RECID = b.RECID` | `SUBSTR(a.RECID,1,14) = b.RECID` | RECID HIS_MV có hậu tố `;n` → không bao giờ khớp |
| `pst_entr`, `ar_avy_shd_itm` | Join PD_PAYMENT_DUE_MV trực tiếp | 1 dòng / contract_id (DATE_TIME mới nhất) | PD_MV không có khóa duy nhất → nhân bút toán |
| `saoke_giaingan` | Join SAOKE_MVMT trực tiếp | 1 dòng / TRANS_REF (SBV_CODE nhỏ nhất) | 391 dòng / 38 TRANS_REF |
| `saoke_tindung` | Cột `ID` của LD | `COALESCE(ID, RECID)` | Oracle LD không có cột ID → bảng mất mã hợp đồng |
| `saoke_tindung` | `DATE_TIME` dạng `YYYYMMDD` | `t24_datetime` | Thực tế yyMMddHHmm |
| `loan_ar` | `FRST_OU_CODE` = FIRST_VALUE trong LD | Trên LD ∪ LD_HIS | Theo ghi chú sheet; LD chỉ 1 dòng / hợp đồng |
| `loan_ar` | PD trùng RECID; `MAX(APPROVE_AMOUNT)` trên chuỗi | CURR_NO lớn nhất; MAX trên số | 8.038 dòng / 2.739 RECID; MAX chuỗi sai thứ tự |
| `loan_ar_prfl` | Join e / g (UDFIELD_HIST) trực tiếp, "tránh dup" để ngỏ | 1 dòng / hợp đồng (MOV_DATE mới nhất) | g: 166.019 dòng / 3.642 hợp đồng |
| `loan_ar_prfl` | Join SAOKE_MVMT "distinct TRANS_REF, SBV_CODE" | 1 dòng / TRANS_REF (MIN SBV_CODE LIKE '39%') | 702 dòng / 38 TRANS_REF → vẫn nhân dòng nếu chỉ distinct |
| `loan_ar_prfl` | `b` join bằng OR (CONTRACT_INFOR theo ACC_FCC / LIMIT_INFOR theo FCC_LIMIT) | 2 left join, ưu tiên CONTRACT_INFOR | OR join có thể ra 2 dòng / hợp đồng |
| `loan_ar_prfl` | `NGAY_HET_COVID19`, `SO_LAN_CO_CAU` | `dd/MM/yyyy`; số Oracle `0E-10` → DECIMAL | Định dạng Bronze thực tế |
| `ar_x_ip_rltnp` | Khóa AR_ID | Khóa SCD2 (AR_ID, CST_ID); bỏ dòng CST_ID NULL; bỏ join d1 nhánh PD (không lấy cột) | Quan hệ cần đủ 2 đầu |
| `ar_tvr_smy` | Transform cột TOT_ODUE_PNP_AMT_FCY → NBR_OF_DB_IN_YR trượt 1 dòng so với Cột đích | Map theo tên: TOT_ODUE = dlq.PNP_ARS, DSBR_AMT_LTD = COALESCE(la.DSBR_AMT_FCY, la.ORIG_AMT_FCY), còn lại = stmt.<cùng tên> | Lỗi sheet |
| `ar_tvr_smy` | `ACG_CR_DB_F = 'D'/'C'` | So ký tự đầu (PST_ENTR thực tế `DEBIT`/`CREDIT`) | Nếu so nguyên chuỗi → 0 bút toán |
| `ar_tvr_smy` | MTD/YTD từ PST_ENTR | Đọc mọi partition PST_ENTR ≤ ETL_DATE, 1 dòng / PST_ENTR_ID (partition mới nhất) | PST_ENTR là TXN theo ngày |
| Bảng SNAPSHOT/TXN | `= ${ETL_DATE}` | `biz_date()` truyền qua conf DAG | Oracle là dữ liệu mẫu 2025 |

Dữ liệu không khớp: `ar_tvr_smy` — CRB chỉ có 2 hợp đồng PD, không có trong AR_DLQ_SMY → TOT_ODUE = 0; PST_ENTR số tiền đều 0. `loan_ar_prfl` — CONTRACT_UDFIELD_HIST rỗng → PROM_PRGM chỉ từ MB_MG_SAVING_MULTI; CAR_APPLICATION_CODE trống. `saoke_giaingan` — SMY_STMT_DAILY mã 402 và COMPANY (CRB.CO_CODE rỗng với LD/PD) 0 khớp; `idv_emp_st` — 3 cột nguồn không có trên Oracle.

## 5. Ràng buộc vận hành (không có trong Excel)

- Bảng SCD2 phải chạy `etl_date` **tăng dần**; backfill ngày cũ sau ngày mới làm sai lịch sử.
- Test SNAPSHOT với dữ liệu hiện có: `dbt run --select cust_info_daily --vars '{etl_date: 2026-11-03, biz_date: 2025-09-26}'` (sk_lich_tra_no: `2025-10-07` cho lịch, `2025-09-02` cho bút toán).
- Câu hỏi còn mở cho mentor: grain `sk_lich_tra_no`; thứ tự ưu tiên LD > LD_HIS > PD ở `ar_rate_hist`.
