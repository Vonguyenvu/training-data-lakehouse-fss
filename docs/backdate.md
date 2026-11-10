# Backdate — chạy lại ngày cũ

Backdate = chạy lại một `ETL_DATE` đã qua (nguồn được sửa, logic model đổi, lần chạy trước sai) rồi **replay tăng dần**
tới ngày mới nhất, sao cho kết quả cuối giống như mọi ngày được chạy đúng ngay từ đầu.

## 1. Vì sao cần cơ chế riêng

| Loại bảng | Chạy thẳng ngày cũ thì sao |
|---|---|
| Bronze | Oracle chỉ có trạng thái **hiện tại** → chạy lại Bronze ngày D ghi đè bản chụp ngày D bằng dữ liệu hôm nay. |
| Silver/Gold SCD2 (`merge`, `unique_key` có `sys_eff_dt`) | Merge ngày D lên trạng thái đã có ngày > D → 2 phiên bản cùng mở, phiên bản đóng sai ngày. |
| Silver SCD1 (`merge`) | Không có lịch sử: ghi giá trị ngày D lên trạng thái mới hơn, chỉ đúng lại sau khi replay tới ngày mới nhất. |
| SNAPSHOT / TXN (`insert_overwrite` partition `etl_date`) | Không có trạng thái giữa các ngày → chỉ ghi đè partition D, an toàn (miễn là đúng `biz_date`). |

## 2. Hai cờ

Truyền qua form của DAG `full_luong` (nút ▶ trên Airflow UI: ô ETL_DATE, BIZ_DATE, checkbox backdate, skip_bronze)
hoặc `--conf` của CLI. `dags/dbt_command.py` đưa chúng vào `--vars` của **mọi** lệnh dbt.

| Cờ | Tác dụng |
|---|---|
| `skip_bronze: true` | TaskGroup `bronze` không chạy model (không đọc Oracle) mà chỉ `echo`; `bronze.test` chạy `dbt run-operation assert_bronze_partition` — lỗi nếu cả 28 bảng Bronze đều không có partition `ETL_DATE` (chưa từng nạp ngày đó → Silver sẽ đọc nguồn rỗng). Silver/Gold đọc partition Bronze đã có. |
| `backdate: true` | Bật nhánh tua của pre-hook `scd_backdate` (mục 3). Không có cờ mà bảng đã có dữ liệu sau `ETL_DATE` → model lỗi, DAG dừng ở tầng đó, **chưa ghi gì**. |

## 3. Logic từng tầng

### 3.1 Pre-hook `dbt/macros/scd_backdate.sql` (mọi model Silver và Gold, `dbt_project.yml`)

Chỉ tác động model `incremental` + `merge` đã có dữ liệu:

1. `ahead = MAX(sys_udt_dt) > ETL_DATE` (có cờ: `>=`, để chạy lại cả ngày mới nhất sau khi nguồn được sửa).
2. `ahead` mà không có cờ → `raise_compiler_error` (chặn).
3. `ahead` và có cờ:
   - **SCD2** (`'sys_eff_dt' in unique_key`) — tua bảng về cuối ngày D-1:
     ```sql
     DELETE FROM t WHERE sys_eff_dt >= D;                         -- phiên bản sinh từ D trở đi
     UPDATE t SET sys_exp_dt = NULL, sys_udt_dt = sys_eff_dt, etl_date = sys_eff_dt
     WHERE sys_exp_dt >= D;                                       -- mở lại phiên bản bị đóng từ D trở đi
     ```
     `sys_udt_dt`/`etl_date` trả về `sys_eff_dt` vì `scd2` và các model SCD2 viết tay (`ip_elc_adr`, `ip_pst_adr`,
     `ip_alt_identn`, `ar_rate_hist`) chỉ ghi **dòng mới** (udt = eff) hoặc **dòng đóng** (udt = exp): một dòng còn mở
     luôn có `sys_udt_dt = etl_date = sys_eff_dt`. Giữ ngày của lần đóng thì dòng mở lại mang ngày "tương lai".
   - **SCD1**: không có lịch sử để tua → chỉ cho chạy. Model SCD1 so nguồn ngày D với trạng thái hiện tại và ghi đè.
4. Model chạy bình thường (`scd2` / khuôn SCD1) trên bảng đã tua.

### 3.2 DIM Gold đọc Silver SCD1

`DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) || id`, `ETL_CHANGE_DATE` lấy từ `sys_udt_dt` của Silver (SCD1 hoặc GREATEST nhiều
bảng). Khi replay ngày D, Silver SCD1 chưa tua nên `sys_udt_dt` có thể > D → 8 DIM tính
`DATE_FORMAT(LEAST(<ngày đổi>, ETL_DATE), 'yyyyMMdd')`. Chạy xuôi, `sys_udt_dt` của Silver không bao giờ > `ETL_DATE`
nên LEAST không đổi kết quả. Ngoài ra `scd2(..., compare_exclude=['dim_key'])`: DIM_KEY đổi mà cột DIM không đổi thì
không sinh phiên bản mới.

### 3.3 SNAPSHOT / TXN

`insert_overwrite` partition `etl_date` → chỉ ghi lại partition D. **`biz_date` của từng partition không được lưu ở
đâu**: replay phải truyền đúng `biz_date` đã dùng lần đầu (xem `dag_run.conf` trong Airflow, mục 6), sai thì số dòng
partition đổi (đã gặp: `cust_info_daily` 9.320 → 25 dòng).

## 4. Quy trình

1. Xác định ngày đầu D và ngày mới nhất N; lấy `biz_date` từng ngày (mục 6). Ghi lại thời điểm bắt đầu (cho bước 4).
2. Trigger lần lượt D, D+1, …, N — **mọi** ngày có `backdate: true` và `skip_bronze: true`, đợi run trước `success`
   mới trigger ngày sau (`max_active_runs=1` chỉ xếp hàng, không sắp thứ tự ngày):
   ```bash
   docker compose exec airflow-scheduler airflow dags trigger full_luong \
     --conf '{"etl_date": "2026-11-08", "biz_date": "2026-11-08", "backdate": true, "skip_bronze": true}'
   ```
   Thiếu cờ `backdate` ở ngày giữa → bị chặn (SCD1 còn `sys_udt_dt` > ngày đó), không hỏng dữ liệu; trigger lại có cờ.
3. Nguồn được sửa ở Bronze ngày X (D ≤ X): chỉ cần backdate từ X.
4. Kiểm tra:
   ```bash
   docker compose exec airflow-scheduler bash -c "cd /opt/airflow && pytest -p no:cacheprovider -q tests/check_backdate \
     --etl-date <N> --before '<thời điểm bước 1> UTC'"
   ```
   SCD2: tối đa 1 phiên bản mở / khóa, không chồng ngày; bảng merge: không có `sys_*` > N; với `--before`: bảng merge
   giống y trước backdate (EXCEPT 2 chiều), SNAPSHOT/TXN số dòng từng partition không đổi. Hai kiểm tra `--before`
   chỉ đúng khi Bronze không đổi — nguồn đã sửa thì khác biệt phải nằm đúng ở chỗ sửa.

Chạy bằng dbt (không qua DAG, không đụng Bronze):
`dbt run --select tag:silver tag:gold --vars '{etl_date: D, biz_date: ..., backdate: true}'`.

## 5. Giới hạn

- Chỉ backdate được ngày còn partition Bronze (`assert_bronze_partition` chặn ngày chưa nạp).
- SCD1 không có lịch sử: trong lúc replay (trước khi tới N) bảng SCD1 không phản ánh đúng ngày đang chạy; sau khi tới N
  giá trị đúng, nhưng dòng bị ghi lại vì nguồn đã sửa có `sys_udt_dt` = ngày replay (vd sửa nguồn rồi trả lại như cũ:
  giá trị về đúng, `sys_udt_dt` = ngày chạy lại chứ không phải ngày đổi thật). DIM không bị ảnh hưởng (mục 3.2).
- `dbt run --full-refresh` thay bảng (REPLACE TABLE) → mất lịch sử snapshot Iceberg, `--before` không so được qua mốc đó.

## 6. Tra `biz_date` đã dùng

```bash
docker compose exec postgres psql -U airflow -d airflow -At -c \
  "SELECT run_id, state, conf FROM dag_run WHERE dag_id='full_luong' ORDER BY start_date"
```
`conf` lưu dạng pickle — xem trên UI (Browse → DAG Runs → cột Conf). Run không truyền `biz_date` → `biz_date = etl_date`.

## 7. Kiểm thử (2026-11-10)

Bronze có 2 partition 2026-11-08, 11-09; Silver/Gold bắt đầu từ 11-08 nên **đáp án** = `dbt run --full-refresh`
ngày 11-08 rồi chạy thường 11-09 (220 test pass). So 41 bảng Silver/Gold bằng EXCEPT 2 chiều.

| Kịch bản | Kết quả |
|---|---|
| A. Nguồn không đổi: DAG backdate 11-08 → 11-09 | Lần đầu lệch `dim_ccy` (USD): lỗi 1 — dòng mở lại giữ `sys_udt_dt` của lần đóng; lỗi 2 — DIM_KEY lấy `sys_udt_dt` 11-09 của Silver SCD1 khi replay 11-08. Sửa (mục 3.1, 3.2) → khớp đáp án 41/41 bảng, `check_backdate` 105/105. |
| B. Sửa Bronze 11-09 (đổi tên USD, xóa XAU, đổi mobile 1 CIF, xóa mobile + đổi `ffb_type` 1 CIF), DAG backdate 11-09 | Khớp 100% đáp án full-refresh trên Bronze đã sửa. Khác trạng thái gốc đúng chỗ sửa: `ccy`, `dim_ccy` (USD đóng 11-09 + phiên bản mới DIM_KEY 20261109…, XAU đóng), `ip_elc_adr`, `idv_prfl`, SNAPSHOT `inf_cst`, `saoke_tindung`. |
| C. Trả Bronze như cũ, DAG backdate 11-09 | Khớp gốc trừ `ccy` USD/XAU: giá trị đúng, `sys_udt_dt` = 11-09 (giới hạn SCD1, mục 5). `dim_ccy` khớp gốc. |
| Chặn | Trigger `etl_date` 2026-11-03 + `skip_bronze` (chưa có partition Bronze) → `bronze.test` lỗi, Silver/Gold không chạy. |

Sau test: Bronze 11-09 trả về như cũ (EXCEPT 2 chiều với snapshot trước khi sửa = 0), Silver/Gold build lại từ đầu
(224 test pass) và khớp bản lưu trạng thái đúng 41/41 bảng (count + `checksum` từng bảng).
So bảng lớn bằng `EXCEPT` trên Trino dễ làm Trino bị OOM-kill (máy thiếu RAM) → dùng `count(*)` + `checksum(ROW(cột...))`.
