# Thực tế khác thiết kế (Excel `Training_Fresher_DeepChecked.xlsx`)

Cập nhật: 2026-11-04. Phạm vi: Bronze (28 bảng) + Silver Temp 1 (13 bảng).
Nguyên tắc: **Oracle / dữ liệu Bronze là sự thật**; chỗ lệch được xử lý trong code và ghi ở comment đầu file model.

---

## 1. Kiến trúc & quy trình

| Thiết kế (Excel) | Thực tế dự án | Lý do |
|---|---|---|
| Silver/Gold là `sql/silver_temp*/*.sql` chạy Spark | Model dbt-trino trong `dbt/models/<silver_temp1\|silver_temp2\|gold>/` | Quyết định dự án; incremental/merge, test, lineage có sẵn |
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

## 5. Ràng buộc vận hành (không có trong Excel)

- Bảng SCD2 phải chạy `etl_date` **tăng dần**; backfill ngày cũ sau ngày mới làm sai lịch sử.
- Test SNAPSHOT với dữ liệu hiện có: `dbt run --select cust_info_daily --vars '{etl_date: 2026-11-03, biz_date: 2025-09-26}'` (sk_lich_tra_no: `2025-10-07` cho lịch, `2025-09-02` cho bút toán).
- Câu hỏi còn mở cho mentor: grain `sk_lich_tra_no`; thứ tự ưu tiên LD > LD_HIS > PD ở `ar_rate_hist`.
