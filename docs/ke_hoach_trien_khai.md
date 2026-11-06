# Kế hoạch triển khai dự án FSS Training Lakehouse

Cập nhật: 2026-11-04. Đặc tả: `Training_Fresher_DeepChecked.xlsx` (sheet `Job_dependence`: 68 job, `Phan_Cong_Task`: bảng ↔ sheet).
Chỗ thực tế lệch Excel: xem [`thuc_te_vs_thiet_ke.md`](thuc_te_vs_thiet_ke.md).

| Giai đoạn | Nội dung | Số job | Trạng thái |
|---|---|---|---|
| 0 | Hạ tầng docker-compose | — | Xong |
| 1 | Kết nối & thư viện dùng chung | — | Xong |
| 2 | Wave 0 — Bronze (Oracle → `pg_bronze`) | 28 | Xong |
| 3 | Wave 1 — Silver Temp 1 | 13 | Xong |
| 4 | Wave 2 — Silver Temp 2 | 15 | Đang làm |
| 5 | Wave 3/4 — Gold (DIM, interface, fact) | 12 | Chưa làm |

## Trạng thái từng bảng (nguồn sự thật tiến độ — cập nhật cuối mỗi session)

Số dòng đo trên `pg_silver` ngày 2026-11-04 (Bronze `etl_date` 2026-10-29 + 2026-11-03, hai partition giống hệt nhau).
`biz_date` = ngày nghiệp vụ dùng khi test bảng lọc BOOKING_DATE / TXN_DATE (Oracle là dữ liệu mẫu 2025).
Đặc tả từng bảng: `docs/spec/<bảng>.md`.

| Bảng | Wave | Kiểu | Trạng thái | Số dòng | biz_date test | Còn mở |
|---|---|---|---|---|---|---|
| ccy | 1 | SCD1 | Xong | 35 | — | |
| pd | 1 | SCD1 | Xong | 241 | — | |
| ou | 1 | SCD1 | Xong | 142 | — | |
| empe | 1 | SCD1 | Xong | 2.119 | — | |
| lmt | 1 | SCD1 | Xong | 18.873 | — | 5 cột NULL (Oracle thiếu) |
| cv | 1 | SCD1 | Xong | 11 | — | |
| ip_alt_identn | 1 | SCD2 | Xong | 0 | — | Oracle CUSTOMER không có NATIONAL_ID… |
| ip_elc_adr | 1 | SCD2 | Xong | 2.000 | — | Chỉ nhánh MOBILE có dữ liệu |
| ip_pst_adr | 1 | SCD2 | Xong | 0 | — | Oracle CUSTOMER không có cột địa chỉ |
| exg_rate | 1 | SNAPSHOT | Xong | 70 | — | |
| cust_info_daily | 1 | SNAPSHOT | Xong | 9.320 | 2025-09-26 | |
| sk_lich_tra_no | 1 | SNAPSHOT | Xong | 522 | 2025-10-07 | Grain cần mentor xác nhận |
| ar_rate_hist | 1 | SCD2 | Xong | 53.449 | — | Ưu tiên LD > LD_HIS > PD cần xác nhận |
| cst | 2 | SCD1 | Xong | 36.346 | — | |
| idv_prfl | 2 | SCD2 | Xong | 35.128 | — | |
| idv_emp_st | 2 | SCD2 | Xong | 35.128 | — | Cột nguồn NULL hết |
| org_prfl | 2 | SCD2 | Xong | 1.217 | — | |
| ar_bal | 2 | SNAPSHOT | Xong | 2.480 | — | |
| ar_dlq_smy | 2 | SNAPSHOT | Xong | 2.157 | — | |
| ast_ar_int_smy | 2 | SNAPSHOT | Xong | 1.822 | 2025-10-07 | |
| saoke_tindung | 2 | SNAPSHOT | Xong | 48.195 | — | |
| saoke_giaingan | 2 | SNAPSHOT | Xong | 2.480 | 2025-10-07 | Stmt 402 / company 0 khớp |
| pst_entr | 2 | TXN | Xong | 73 | 2025-10-07 (2025-09-01: 28.306) | |
| ar_avy_shd_itm | 2 | SCD2 | Xong | 58.873 | 2025-10-07 | |
| loan_ar | 2 | SCD2 | Xong | 54.483 (LD 48.195 · LD_HIS 3.549 · PD 2.739) | — | |
| loan_ar_prfl | 2 | SCD2 | Xong | 54.483 | — | e (UDFIELD_HIST) rỗng trên Bronze |
| ar_x_ip_rltnp | 2 | SCD2 | Xong | 34.286 | — | 20k hợp đồng LD không có CUSTOMER_ID → bỏ |
| ar_tvr_smy | 2 | Fact Snapshot | Xong | 1.822 | 2025-10-07 | Sheet lệch dòng Transform; TOT_ODUE = 0 (dữ liệu) |
| Gold (12 job) | 3–4 | | Chưa làm | | | |

Wave 2 xong 2026-11-05: 15/15 model, `_silver_temp2.yml` 79 test pass, chạy incremental 2026-11-03 → 2026-11-05 không sinh phiên bản thừa. Test SCD2 bằng dữ liệu giả lập: `dbt/models/silver_temp2/_unit_scd2.yml` (4 unit test dbt cho macro `scd2`: đổi giá trị, biến mất, xuất hiện lại, chạy lại cùng ngày, nguồn rỗng, lần đầu, khóa ghép) — pass. Chưa có unit test cho `close_missing=false` (`ar_avy_shd_itm`).

Backdate (2026-11-06): pre-hook `dbt/macros/scd_backdate.sql` cho mọi model Silver. Chạy ngày cũ mà không có var `backdate: true` thì bảng SCD báo lỗi; có cờ thì SCD2 được tua về trước ngày đó (xoá phiên bản `sys_eff_dt >= D`, mở lại dòng `sys_exp_dt >= D`), sau đó replay tăng dần. Đã test tay trên `org_prfl` (lịch sử giả 10-29 → 11-03 → 11-05, backdate về 11-03 rồi về 10-29): đúng từng snapshot, bảng về lại 1.217 dòng, `dbt test` 6/6 pass. SCD1 test trên `ccy` (đổi tên USD + mã giả ZZZ không có ở nguồn): chặn đúng khi không có cờ, có cờ thì chạy được, replay 11-05 cho kết quả đúng; `dbt test` 8/8 pass. SCD1 không có lịch sử nên ở giữa quá trình replay bảng không phản ánh đúng ngày D (vd ZZZ vẫn giữ `sys_exp_dt` 11-05), chỉ đúng khi đã replay tới ngày mới nhất. SCD2 viết tay test trên `ip_elc_adr` (2 thay đổi giả + khóa giả không có ở nguồn): xem từng snapshot thấy khóa bị đóng do biến mất được mở lại rồi đóng lại đúng ngày 11-03; khôi phục về 2.000 dòng, `dbt test` 9/9 pass. Qua DAG (2026-11-06): wave1 ngày 11-03 không có cờ → task `ccy` lỗi, wave2 không được trigger; có `"backdate": true` → wave1 chuyển cờ sang wave2, `org_prfl` được tua đúng; replay 11-05 thì cả 2 wave `success` (gồm `dbt test`), số dòng 28 bảng khớp mốc ban đầu. Bẫy: `biz_date` của từng partition SNAPSHOT không được lưu ở đâu cả. Replay 11-03 với 2025-10-07 làm `cust_info_daily` còn 25 dòng (gốc chạy với 2025-09-26, 9.320 dòng), phải chạy lại riêng → khi backdate phải dùng đúng `biz_date` cũ của từng bảng.

## Quy trình chung cho mỗi bảng

1. Đọc `docs/spec/<bảng>.md` (sinh từ Excel bằng `scripts/export_spec.py`): Header `TYPE` → chiến lược load; khối header → bảng chính/phụ, JOIN, WHERE; bảng mapping → cột đích, kiểu, Transform; cột "Business rule" là yêu cầu bắt buộc.
2. Kiểm tra dữ liệu thật trên Bronze (định dạng ngày/số, khóa trùng, cột Oracle thiếu) trước khi viết SQL.
3. Viết model dbt theo khuôn của loại bảng, comment đầu file ghi chỗ lệch Excel.
4. Thêm mô tả cột + test vào `_<folder>.yml`.
5. `dbt run` 2 ngày liên tiếp (lần đầu full, lần sau incremental) + `dbt test`; đối chiếu số dòng với Bronze.
6. Ghi chỗ lệch / dữ liệu không khớp vào `thuc_te_vs_thiet_ke.md`.

---

## Giai đoạn 0 — Hạ tầng

1. `docker-compose.yml`: MinIO (bucket `warehouse`), Nessie (branch `main`), Spark 3.5 standalone (master, worker) + Thrift Server, Trino (đọc), Postgres (metadata Airflow), Airflow 2.10 LocalExecutor, container `dbt`.
2. `conf/spark/spark-defaults.conf`: catalog `iceberg` (Nessie + MinIO) và catalog JDBC `oracle`; Thrift Server đặt `defaultCatalog=iceberg`, `timeParserPolicy=CORRECTED`.
3. `conf/trino/`: catalog `iceberg` trỏ cùng Nessie để truy vấn tay.
4. Giới hạn tài nguyên: `spark.cores.max=1`, executor 800m → DAG song song tối đa 2, dbt `threads: 1`.
5. Kiểm tra: `docker compose up -d`, mở Airflow :8088, Spark UI :8081, Trino :8080.

## Giai đoạn 1 — Kết nối & thư viện dùng chung

1. `common/`: `OracleConnection`, `TrinoConnection` (`.from_environment()`), exception, `get_logger`. Thông tin kết nối đọc từ `.env` (không commit).
2. `tests/check_connection`: pytest kiểm tra Oracle, Nessie, MinIO, Trino.
3. Dự án dbt `dbt/`: `profiles.yml` (dbt-spark → `spark-thrift:10000`), `dbt_project.yml` (`+file_format: iceberg`, tag theo tầng), macro `generate_schema_name`.
4. Đối chiếu Excel với Oracle thực tế → `Training_Fresher_DeepChecked_vs_Oracle.xlsx` (sheet `Oracle_vs_Excel`, `Tong_hop`).

## Giai đoạn 2 — Wave 0 Bronze (28 bảng)

1. `src/config/bronze_tables.py`: danh sách 28 bảng — nguồn sự thật cho DAG và test.
2. `dbt/models/sources.yml`: 6 nguồn Oracle qua catalog JDBC `oracle`.
3. `dbt/models/bronze/<target>.sql`: mirror 1:1 mọi cột Oracle, mọi cột `STRING`, cột Excel có mà Oracle không có → `CAST(NULL AS STRING)`, 3 cột audit `ETL_DATE`, `INGEST_TMS`, `SRC_STM_CODE`; incremental `insert_overwrite` partition `ETL_DATE`.
4. `schema/bronze.sql`: DDL tham chiếu; `tests/check_bronze`: 6 check / bảng.
5. `dags/wave0_bronze_ingest.py`: 1 task / bảng (song song 2) → `dbt test` Bronze → trigger Wave 1.
6. Kết quả: 2 partition `2026-10-29`, `2026-11-03`.

## Giai đoạn 3 — Wave 1 Silver Temp 1 (13 bảng)

1. Macro dùng chung: `fn_hash`, `t24_date`, `t24_datetime`, `t24_multi_value`, `etl_date`, `biz_date`.
2. Dựng khuôn cho từng loại bảng:
   - SCD1: `ccy.sql` (`merge`, `unique_key=<id>`, CTE `src → tgt → changed / deleted → final`).
   - SNAPSHOT: `exg_rate.sql` (`insert_overwrite`, partition `etl_date`).
   - SCD2: `ip_elc_adr.sql` (`merge`, `unique_key=<khóa> + sys_eff_dt`; đóng dòng cũ, mở phiên bản mới; nguồn rỗng không đóng dòng).
3. 13 model: `ccy`, `pd`, `ou`, `empe`, `lmt`, `cv`, `ip_alt_identn`, `ip_elc_adr`, `ip_pst_adr`, `exg_rate`, `cust_info_daily`, `sk_lich_tra_no`, `ar_rate_hist` + `_silver_temp1.yml`.
4. `dags/wave1_silver_temp1.py`: 1 task / model, phụ thuộc đọc từ `ref()` (`dags/dbt_command.py`) → `dbt test`.
5. Lỗi đã sửa: SCD2 đóng toàn bộ dòng khi Bronze chưa có partition ngày chạy.

## Giai đoạn 4 — Wave 2 Silver Temp 2 (15 bảng)

Không bảng nào đọc Temp 1; chỉ `ar_tvr_smy` đọc 3 bảng Temp 2 khác.

### Bước 4.0 — Khung

- Thư mục `dbt/models/silver_temp2/` + `_silver_temp2.yml` (tag `silver_temp2` đã có trong `dbt_project.yml`).
- Macro `scd2` (`dbt/macros/scd2.sql`): sinh phần đóng/mở phiên bản của khuôn `ip_elc_adr.sql` cho mọi cột, vì các bảng Temp 2 có tới 100+ cột.
- `dags/wave2_silver_temp2.py` (copy Wave 1); Wave 1 trigger Wave 2 cùng `etl_date`, `biz_date`. Phụ thuộc `ar_tvr_smy` tự có nhờ `ref()`.
- `biz_date` truyền qua conf DAG (`dags/dbt_command.py`), mặc định = `etl_date`: `airflow dags trigger wave0_bronze_ingest --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07"}'`.
- Đã xong: macro `scd2` (+ `close_missing=false` cho nguồn lát cắt theo ngày), macro `t24_code`, DAG wave2.

### Bước 4.1 — Khách hàng (đều từ `T24CORE_CUSTOMER`)

| Bảng | Sheet | Kiểu | Ghi chú |
|---|---|---|---|
| `cst` | Customer | SCD1 | + LEFT JOIN `T24CORE_SECTOR` lấy `CUSTOMER_TYPE` |
| `idv_prfl` | Individual Profile | SCD2 | `KHOI LIKE '%INDIV%'` |
| `idv_emp_st` | Individual Employment Status | SCD2 | `KHOI LIKE '%INDIV%'` |
| `org_prfl` | Organization Profile | SCD2 | `KHOI NOT LIKE '%INDIV%'` |

### Bước 4.2 — SNAPSHOT

| Bảng | Sheet | Nguồn |
|---|---|---|
| `ar_bal` | Arrangement Balance | `SOURCE_SAOKE_CRB` |
| `ar_dlq_smy` | Arrangement Delinquency Summary | `PD_PAYMENT_DUE_HIS_MV` (bản mới nhất / RECID) + `PD_PAYMENT_DUE` |
| `ast_ar_int_smy` | Asset Arrangement Interest Summ | `SOURCE_SAOKE_CRB` + tổng hợp `STMT_ENTRY` |
| `saoke_tindung` | SAOKE_TINDUNG | `LD` + `CUSTOMER` + `DEPT_ACCT_OFFICER` |
| `saoke_giaingan` | Saoke_GIAINGAN | `SAOKE_CRB` + `SMY_STMT_DAILY` + `SAOKE_MVMT` + `CUSTOMER` + `COMPANY` |

### Bước 4.3 — Giao dịch & lịch

| Bảng | Sheet | Kiểu | Ghi chú |
|---|---|---|---|
| `pst_entr` | Posting Entry | TXN | Load như SNAPSHOT: ghi đè partition `etl_date` (nguồn đã lọc `BOOKING_DATE` = ngày nghiệp vụ) |
| `ar_avy_shd_itm` | Arrangement Activity Schedule I | SCD2 | Join gần giống `pst_entr` + `LD_SCHEDULE_DEFINE_MV` |

### Bước 4.4 — Hợp đồng (SCD2, khó nhất — làm từng bảng, chạy xong mới sang bảng sau)

| Bảng | Sheet | Số cột | Nguồn |
|---|---|---|---|
| `loan_ar` | Loan Arrangement | ~100 | `LD` + `CONTRACT_MASTER` (version mới nhất) + 3 bảng LOS + `CUSTOMER` |
| `loan_ar_prfl` | Loan Arrangement Profile | ~120 | `LD` + 9 bảng FLEXBO / EBANKING / SAOKE_MVMT / CUSTOMER |
| `ar_x_ip_rltnp` | Arrangement x Involved Party | ~50 | `LD` + `LOS_CONTRACT_FIELDS_TDATE`, nhiều nhánh |

### Bước 4.5 — `ar_tvr_smy` (Fact Snapshot)

Đọc `SAOKE_CRB` + `pst_entr` + `ar_dlq_smy` + `loan_ar` → làm cuối.

### Quy tắc chuyển SQL Excel (Oracle) sang Spark

| Excel | Spark / dự án |
|---|---|
| `NVL`, `DECODE`, `TRUNC(d,'MM')` | `COALESCE`, `CASE`, `TRUNC(d,'MM')` / `DATE_TRUNC` |
| `TO_DATE(x,'YYYYMMDD')`, `TO_DATE(x,'YYMMDDHH24MI')` | `t24_date(x)`, `t24_datetime(x)` |
| `col = (SELECT MAX(...) WHERE k = outer.k)` | `ROW_NUMBER() OVER (PARTITION BY k ORDER BY ... DESC) = 1` |
| `${ETL_DATE}` so với ngày nghiệp vụ (`BOOKING_DATE`, `TXN_DATE`, `MOV_DATE`) | `biz_date()` |
| Bảng phụ không lọc ngày | Luôn thêm `etl_date = {{ etl_date() }}` (Bronze giữ nhiều partition) |
| `COMMIT_ACTION <> 'D'` | `COALESCE(x,'') <> 'D'` |

### Kiểm tra sau mỗi bước

```bash
docker compose exec dbt dbt run  --select <model> --vars '{etl_date: 2026-10-29}'
docker compose exec dbt dbt run  --select <model> --vars '{etl_date: 2026-11-03}'
docker compose exec dbt dbt test --select <model>
```
SNAPSHOT/TXN lọc theo ngày nghiệp vụ: thêm `biz_date` có dữ liệu (vd `2025-09-26`).

## Giai đoạn 5 — Gold (12 job)

1. Wave 3 DIM (8): `dim_ccy`, `dim_pd`, `dim_ou`, `dim_lmt`, `dim_rstc_tp`, `dim_fnc_st`, `dim_loan_ar`, `dim_cst` → `dbt/models/gold/` (schema `pg_gold`).
2. Wave 4: `inf_cst` → `intf_loan_ar`, `intf_loan_dsbr`, `intf_loan_repymt_shd` → `fct_loan_ar`.
3. Join sang bảng SCD2 luôn kèm `sys_exp_dt IS NULL`.
4. DAG `wave3_gold_dim`, `wave4_gold` nối tiếp Wave 2.
