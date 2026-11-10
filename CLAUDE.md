# FSS Training Lakehouse

Dự án training Data Engineer (ngân hàng): dựng lakehouse local theo kiến trúc Medallion, hiện thực hoá đặc tả mapping trong `Training_Fresher_DeepChecked.xlsx`.

**Luồng:** Oracle nguồn (6 schema `PG_T24CORE`, `PG_FLEXBO`, `PG_LOS_APP`, `PG_SMY`, `PG_SOURCE`, `PG_EBANKING`)
→ **Bronze** (`iceberg.pg_bronze`, mirror 1:1) → **Silver Temp 1/Temp 2** (`iceberg.pg_silver`) → **Gold** (`iceberg.pg_gold`).
**Toàn bộ logic là model dbt** (`dbt/models/<bronze|silver_temp1|silver_temp2|gold>/`), **thực thi trên Spark**: dbt-spark → Spark Thrift Server (`spark-thrift`, Spark `local[1]` trong cùng container, không có master/worker). Trino chỉ để truy vấn tay / pytest.

**Stack (docker-compose):** Airflow 2.10.5 (LocalExecutor, gọi dbt trong `/opt/dbt-venv`) · Spark 3.5.9 (Thrift Server, `local[1]`) · Iceberg 1.6.1 trên Nessie 0.76.6 (branch `main`) · MinIO (bucket `warehouse`) · dbt-spark · Trino 476 (đọc) · Postgres 16 (metadata Airflow).

## Tiến độ & quyết định kiến trúc

- **Tiến độ:** bảng "Trạng thái từng bảng" trong `docs/ke_hoach_trien_khai.md` (trạng thái, số dòng, `biz_date` test, việc còn mở). **Cập nhật bảng này cuối mỗi session.**
- **Đặc tả 1 bảng:** đọc `docs/spec/<bảng>.md` (TYPE, JOIN, mapping cột, business rule) — **không mở Excel**. Excel đổi thì chạy lại `scripts/export_spec.py`.
- Excel ghi Bronze/Silver/Gold là file `sql/*.sql` chạy bằng Spark; dự án **dùng dbt cho mọi tầng** (vẫn chạy trên Spark) → viết model trong `dbt/models/<tầng>/`. SQL viết theo **cú pháp Spark SQL**.

## Bản đồ thư mục

| Đường dẫn                                                  | Vai trò                                                                                                                                                                                              |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/config/bronze_tables.py`                              | **Nguồn sự thật** danh sách 28 bảng Bronze (`BronzeTable(source_schema, source_table, target_name)`). DAG và test đều đọc từ đây.                                                                    |
| `dags/bronze_to_silver.py` | DAG duy nhất, dag_id `full_luong` (trigger thủ công, `max_active_runs=1`): TaskGroup `bronze` (28 task, `src/config/bronze_tables.py`) → `silver_temp1` → `silver_temp2` → `gold` (1 task / model, phụ thuộc đọc từ `ref()` qua `dags/dbt_command.py`); cuối mỗi tầng `dbt test`, pass mới sang tầng sau. Song song max 2. |
| `schema/bronze.sql`                                        | DDL tham chiếu 28 bảng Bronze (dbt tự tạo bảng; `tests/check_bronze` so kiểu cột với file này).                                                                                                      |
| `schema/silver.sql`                                        | DDL tham khảo 28 bảng Silver (sinh từ Excel). dbt tự tạo bảng nên file này **chỉ để tra cột/kiểu/comment**, không chạy.                                                                              |
| `dbt/models/bronze/<target_name>.sql`                      | `SELECT ... FROM {{ source('oracle_<schema>', '<TABLE>') }}`; config chung ở `dbt_project.yml` (incremental `insert_overwrite`, partition `ETL_DATE`).                                               |
| `sql/test/`                                                | SQL kiểm tra tay trên Oracle.                                                                                                                                                                        |
| `dbt/models/sources.yml`                                   | 6 nguồn Oracle (`oracle_t24core`, `oracle_flexbo`, …) đọc qua catalog JDBC `oracle` của Spark (`schema: oracle.PG_X`). Silver dùng `ref('<bảng bronze>')`.                                           |
| `dbt/models/silver_temp1/`                                 | Model Silver Temp 1 + `_silver_temp1.yml` (mô tả cột + data_tests).                                                                                                                                  |
| `dbt/macros/`                                              | `fn_hash`, `t24_date`, `t24_datetime`, `t24_multi_value`, `t24_code` (số Oracle `'1602.0000000000'` → `'1602'`), `etl_date`, `biz_date`, `scd2`, `scd_backdate` (pre-hook Silver/Gold), `assert_bronze_partition` (DAG `skip_bronze`), `generate_schema_name`.                             |
| `dbt/models/silver_temp2/`                                 | Model Silver Temp 2 + `_silver_temp2.yml`.                                                                                                                                                           |
| `dbt/models/gold/` | 13 model Gold (`pg_gold`): 8 DIM SCD2 (macro `scd2`, `DIM_KEY = yyyyMMdd(ETL_CHANGE_DATE) \|\| id`), `inf_cst`, 3 `intf_loan_*`, `fct_loan_ar` (SNAPSHOT) + `_gold.yml`. DDL tham chiếu `schema/gold.sql`. |
| `docs/ke_hoach_trien_khai.md`                              | Kế hoạch theo giai đoạn + **bảng trạng thái từng bảng**.                                                                                                                                             |
| `docs/spec/`                                               | Đặc tả từng bảng Silver/Gold, sinh từ Excel bằng `scripts/export_spec.py` (đừng sửa tay).                                                                                                            |
| `common/`                                                  | Python dùng chung: `OracleConnection`, `TrinoConnection` (`.from_environment()`), exceptions, `get_logger`.                                                                                          |
| `docs/backdate.md`                                         | Logic backdate chi tiết (cờ `backdate`/`skip_bronze`, tua SCD2, SCD1, DIM, quy trình, kiểm tra `tests/check_backdate`, giới hạn, kết quả test). |
| `docs/thuc_te_vs_thiet_ke.md`                              | Tổng hợp chỗ thực tế (Oracle/Bronze) khác Excel và cách đã xử lý. Cập nhật khi làm bảng mới.                                                                                                         |
| `tests/`                                                   | pytest: `check_connection` (Oracle/Nessie/MinIO/Trino), `check_bronze` (6 check/bảng).                                                                                                               |
| `conf/spark/spark-defaults.conf`                           | Catalog `iceberg` (Nessie) + catalog JDBC `oracle` (thông tin kết nối Oracle nằm ở đây và `.env`). Thrift Server thêm `defaultCatalog=iceberg`, `timeParserPolicy=CORRECTED` (`docker-compose.yml`). |
| `conf/trino/`                                              | Catalog `iceberg` của Trino.                                                                                                                                                                         |

## Lệnh thường dùng

```bash
docker compose up -d                       # Airflow :8088, MinIO :9001, Trino :8080, Thrift UI :4040, Nessie :19120
# Full luồng 1 ngày: Bronze → Silver Temp 1 → Temp 2 → Gold (đợi run xong mới trigger ngày sau)
docker compose exec airflow-scheduler airflow dags trigger full_luong --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07"}'
# Backdate qua DAG: MỌI ngày replay (tăng dần) đều thêm "backdate": true, "skip_bronze": true (giữ partition Bronze cũ, không đọc lại Oracle)
docker compose exec airflow-scheduler airflow dags trigger full_luong --conf '{"etl_date": "2026-11-03", "biz_date": "2025-10-07", "backdate": true, "skip_bronze": true}'
# dbt (Silver)
docker compose exec dbt dbt run  --select bronze --vars '{etl_date: 2026-10-29}'   # hoặc 1 bảng: --select t24core_currency
docker compose exec dbt dbt run  --select ccy --vars '{etl_date: 2026-10-29}'
docker compose exec dbt dbt run  --select pst_entr --vars '{etl_date: 2026-11-03, biz_date: 2025-09-01}'  # bảng lọc ngày nghiệp vụ
docker compose exec dbt dbt test --select ccy
# Backdate bằng dbt (macro scd_backdate): backdate: true cho MỌI ngày replay, TĂNG DẦN tới ngày mới nhất; ngày đầu tua SCD2 về trước ngày đó
docker compose exec dbt dbt run --select tag:silver tag:gold --vars '{etl_date: 2026-11-03, biz_date: 2025-10-07, backdate: true}'
docker compose exec dbt dbt run --select tag:silver tag:gold --vars '{etl_date: 2026-11-04, biz_date: 2025-10-08, backdate: true}'   # ... tới ngày mới nhất
docker compose exec dbt dbt test --select "test_type:unit"     # unit test macro scd2 (dữ liệu giả, cần bảng đích đã build)
docker compose exec dbt dbt ls --select ccy+              # model phía sau bị ảnh hưởng
docker compose exec dbt dbt ls --select +ccy              # upstream
# Test Python (chạy trong container Airflow; tests mount read-only)
docker compose exec airflow-scheduler bash -c "cd /opt/airflow && pytest -p no:cacheprovider tests/check_bronze -k t24core_currency --etl-date 2026-10-29"
# Truy vấn nhanh
docker compose exec trino trino --execute "SELECT count(*) FROM iceberg.pg_silver.ccy"
```


## Quy ước bắt buộc

### Bronze

- Model dbt chỉ là `SELECT` (không `INSERT`, không `;`); ngày batch `{{ etl_date() }} AS ETL_DATE`.
- Mirror 1:1 **toàn bộ** cột Oracle thực tế, giữ nguyên tên cột (UPPERCASE, bọc backtick). Mọi cột dữ liệu là `STRING`: cột số/ngày phải `CAST(src.\`X\` AS STRING) AS \`X\``.
- Cột có trong Excel nhưng Oracle không có: `CAST(NULL AS STRING) AS \`COL\``.
- 3 cột audit cuối: `{{ etl_date() }} AS ETL_DATE, CURRENT_TIMESTAMP() AS INGEST_TMS, '<TARGET_NAME_UPPER>' AS SRC_STM_CODE`. Partition theo `ETL_DATE`, ghi đè đúng partition (dynamic).
- ⚠️ `tests/check_bronze` **parse bằng regex** `schema/bronze.sql` và `dbt/models/bronze/*.sql` (mẫu `CREATE TABLE IF NOT EXISTS iceberg.pg_bronze.X (` … `\n)`, `` `COL` TYPE ``, `'X' AS SRC_STM_CODE`, `CAST(NULL AS STRING) AS \`X\``). Giữ đúng định dạng này.
- Thêm/sửa 1 bảng Bronze phải cập nhật đồng thời: `src/config/bronze_tables.py`, `schema/bronze.sql`, `dbt/models/bronze/<name>.sql` + `_bronze.yml`, `dbt/models/sources.yml`.

### Silver (dbt)

- Khoá: `{{ fn_hash('<PREFIX>', '<alias.col>') }}` = `lower(hex(md5(prefix || trim(col))))`, **không có ký tự phân cách `|`**; NULL/rỗng → NULL. Prefix lấy từ cột Transform trong sheet Excel (vd `T24_CURRENCY`, `T24_CUSTOMER`, `T24_LD_LOANS_AND_DEPOSITS`).
- Ngày batch: `{{ etl_date() }}` (đọc `var('etl_date')`), không hardcode ngày. Luôn lọc nguồn `WHERE <alias>.etl_date = {{ etl_date() }}`.
- Parse giá trị T24 dạng chuỗi: `t24_date` (yyyyMMdd), `t24_datetime` (yyMMddHHmm, có lpad), `t24_multi_value` (tách `#`). Số: `TRY_CAST(TRIM(x) AS DECIMAL(p,s))`; độ dài Excel `25.5` = `DECIMAL(25,5)`.
- **SCD TYPE 1**: copy khuôn `dbt/models/silver_temp1/ccy.sql` — `incremental` + `merge` + `unique_key=<id>`, các CTE `src → tgt → changed / deleted → final`; `sys_eff_dt` giữ lần đầu, `sys_exp_dt` = ngày ID biến mất (chỉ khi `EXISTS (SELECT 1 FROM src)`), `sys_udt_dt = etl_date`.
- **SNAPSHOT**: khuôn `exg_rate.sql` — `insert_overwrite`, `partition_by=['etl_date']`.
- Cú pháp Spark: `CAST(x AS STRING)` (không dùng `VARCHAR` trơn), ngày `try_to_timestamp(x, 'yyyyMMdd')`, hash `md5(...)`. Ngày nghiệp vụ dùng `{{ biz_date() }}` (mặc định = etl_date).
- **SCD TYPE 2**: CTE `src` (cột đã CAST đúng kiểu/tên đích) rồi `{{ scd2(['<khóa>']) }}`; config `merge`, `unique_key=[<khóa>, 'sys_eff_dt']` (mẫu `silver_temp2/idv_prfl.sql`). Nguồn là lát cắt theo ngày (bút toán) → `scd2([...], close_missing=false)`. Phải chạy `etl_date` tăng dần.
- **Ngày nghiệp vụ**: so BOOKING_DATE / TXN_DATE / MOV_DATE với `{{ biz_date() }}`, không với `etl_date()`. Oracle là dữ liệu mẫu 2025-09 → 2026-02, nên test/trigger phải truyền `biz_date` (vd 2025-10-07), nếu không bảng SNAPSHOT/TXN ra 0 dòng.
- **TXN**: load như SNAPSHOT (`insert_overwrite` partition `etl_date`), mẫu `pst_entr.sql`.
- Bảng phụ không có khóa duy nhất (`PD_PAYMENT_DUE_MV`, `SAOKE_MVMT`, …) → `ROW_NUMBER()` lấy 1 dòng / khóa join trước khi join, tránh nhân dòng. Subquery `= (SELECT MAX ...)` của Excel → window function.
- Join sang bảng SCD2/DIM **bắt buộc** `AND x.sys_exp_dt IS NULL` (chống fan-out).
- Cột output cuối: `CAST(... AS STRING/DECIMAL/DATE)` tường minh, tên cột lowercase theo "Cột đích" của sheet, `on_schema_change='fail'`.
- Mỗi model mới: thêm vào `_<folder>.yml` (description kèm `[KIỂU(ĐỘ DÀI)]`, test `unique`/`not_null` cho khoá, `accepted_values` cho `src_stm_code`).
- Nessie không hỗ trợ VIEW → đừng dùng `materialized='view'` (`+file_format: iceberg` cho mọi model).
- Schema: mặc định `pg_silver`; folder `gold` → `pg_gold` (macro `generate_schema_name` dùng đúng tên, không ghép prefix).

## Workbook Excel (đặc tả)

- `Training_Fresher_DeepChecked.xlsx`: bản gốc. `Training_Fresher_DeepChecked_vs_Oracle.xlsx`: bản gốc + 2 sheet `Oracle_vs_Excel`, `Tong_hop` (đối chiếu cột Excel với Oracle thực tế, 2026-10-29). `OracleVsExcel.ods`: bản xuất của phần đối chiếu.
- Sheet quản trị: `Master` (SOP + quy ước + danh mục 48 sheet), `Phan_Cong_Task` (42 task, 8 track), `Job_dependence` (68 job: wave, bảng phải chờ, cron), `Bronze_Mapping_1_1`, `DDL` (392 cột nguồn), `Map_SRC2TRG` (lineage cột nguồn → Bronze → Silver).
- **Mỗi bảng Silver/Gold có 1 sheet riêng** đặt theo tên entity (vd bảng `CCY` → sheet `Currency`, `LOAN_AR_PRFL` → `Loan Arrangement Profile`; tra bảng ↔ sheet trong `Phan_Cong_Task`). Bố cục sheet:
  - Dòng 1 `TYPE : SCD TYPE 1|SCD TYPE 2|SNAPSHOT|TXN` → quyết định chiến lược load.
  - Khối header: bảng chính/phụ, alias (`Short table`), JOIN/ON/WHERE, các nhánh `UNION ALL`.
  - Bảng mapping: `Nguồn | Bảng nguồn | Cột nguồn | Transform | Entity | Attribute | Bảng đích | Cột đích | Kiểu | Độ dài | Diễn giải | Glossary | DDL Comment | Ghi chú kỹ thuật & Business Rule`. Cột cuối là **yêu cầu bắt buộc**.
- Excel **lệch** Oracle thực tế ở nhiều bảng (thiếu cột, sai kiểu, vd `T24CORE_CUSTOMER` Excel 63 cột nhưng Oracle chỉ 10, `T24CORE_LIMIT` thiếu 5 cột) → khi Excel và Oracle mâu thuẫn, xem sheet `Oracle_vs_Excel` và comment đầu file model; Oracle là sự thật cho Bronze.
- Đặc tả đã xuất sẵn ra `docs/spec/` — chỉ mở Excel khi cần sheet quản trị (`Master`, `Map_SRC2TRG`, …); máy chưa cài `openpyxl` → tạo venv trong scratchpad.

## Phụ thuộc giữa các wave (từ `Job_dependence`)

Wave 0 Bronze (00:30) → Wave 1 Silver Temp 1 (01:00) → Wave 2 Silver Temp 2 (01:30, `ar_tvr_smy` 01:45) → Wave 3 Gold DIM (02:00) → Wave 4 `inf_cst` (02:15) → `intf_loan_*` (02:30) → `fct_loan_ar` (02:45).
Phụ thuộc chi tiết theo bảng: cột `WAITING` của sheet `Job_dependence`; trong dbt dùng `dbt ls --select +model` / `model+`.

## Môi trường & bẫy

- Spark rất ít tài nguyên (Thrift `local[1]`, driver 1536m) → bảng lớn chạy chậm; không tăng song song DAG quá 2, dbt `threads: 1`.
- Spark `TIMESTAMP` hiện trên Trino là `timestamp(6) with time zone`.
- Trino bị kernel OOM-kill (exit 137) khi host thiếu RAM: chỉ `conf/trino/catalog` được mount, `conf/trino/config.properties` (giới hạn memory) không có tác dụng; JVM dùng heap mặc định của image. Tránh `EXCEPT`/join lớn, `docker compose up -d trino` để chạy lại.
- Endpoint nội bộ: `minio:9000`, `nessie:19120/api/v2`, `spark-thrift:10000` (dbt), `trino:8080`.
- `docker compose down -v` xoá toàn bộ dữ liệu Nessie/MinIO/Airflow.
- Không commit `.env`, không chép mật khẩu Oracle vào code/tài liệu mới.
- Ổ `/media/vu/FSS` thuộc root → git báo "dubious ownership"; cần `git config --global --add safe.directory /media/vu/FSS/Training_lakehouse`.

## Làm việc tiết kiệm token (cho Claude)

- Mở đầu session: đọc bảng trạng thái trong `docs/ke_hoach_trien_khai.md` + `docs/spec/<bảng>.md` của bảng cần làm + 1 model mẫu cùng kiểu. Không đọc lại toàn bộ thư mục model.
- **Không đọc** `dbt/logs/`, `dbt/target/`, `logs/`, `graphify-out/`, file `.xlsx/.ods`.
- Output dbt: lọc `| grep -E " OK |ERROR|rror"`. Trino: chỉ `count(*)` / vài dòng mẫu, thêm `--output-format TSV` và `2>&1 | grep -v -E 'WARN|jline'`.
- Bảng nhiều cột 1:1 (TRIM / COALESCE CAST / TO_DATE): sinh danh sách cột từ spec bằng script, không gõ tay.
- Mỗi session 1 nhóm bảng; xong thì cập nhật bảng trạng thái + `docs/thuc_te_vs_thiet_ke.md`, rồi `/clear`.
