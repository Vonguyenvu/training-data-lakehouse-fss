# FSS Training Lakehouse

Dự án training Data Engineer (ngân hàng): dựng lakehouse local theo kiến trúc Medallion, hiện thực hoá đặc tả mapping trong `Training_Fresher_DeepChecked.xlsx`.

**Luồng:** Oracle nguồn (6 schema `PG_T24CORE`, `PG_FLEXBO`, `PG_LOS_APP`, `PG_SMY`, `PG_SOURCE`, `PG_EBANKING`)
→ **Bronze** (`iceberg.pg_bronze`, Spark SQL, mirror 1:1) → **Silver Temp 1/Temp 2** (`iceberg.pg_silver`, dbt-trino) → **Gold** (`iceberg.pg_gold`, dbt — chưa làm).

**Stack (docker-compose):** Airflow 2.10.5 (LocalExecutor) · Spark 3.5.9 · Iceberg 1.6.1 trên Nessie 0.76.6 (branch `main`) · MinIO (bucket `warehouse`) · Trino 476 · dbt-trino · Postgres 16 (metadata Airflow).

## Tiến độ & quyết định kiến trúc

- **Tiến độ không ghi ở đây** — tự kiểm tra: `ls dbt/models/*/ dags/` rồi so với danh sách 68 job trong sheet `Job_dependence` (cột `OBJECT_NAME`, `GRP_OBJ`). Bảng nào chưa có file model là chưa làm.
- Excel ghi Silver/Gold là `sql/silver_temp*/*.sql` chạy bằng Spark, nhưng dự án **đã chọn dbt** cho Silver trở đi → viết model trong `dbt/models/<silver_temp1|silver_temp2|gold>/`. Bronze vẫn là Spark SQL.

## Bản đồ thư mục

| Đường dẫn | Vai trò |
|---|---|
| `src/config/bronze_tables.py` | **Nguồn sự thật** danh sách 28 bảng Bronze (`BronzeTable(source_schema, source_table, target_name)`). DAG và test đều đọc từ đây. |
| `src/jobs/run_sql.py` | Spark job chạy 1 file SQL: thay `${ETL_DATE}`, bỏ dòng bắt đầu bằng `--`, tách câu theo `;`. |
| `dags/wave0_bronze_ingest.py` | `create_tables` (chạy `schema/bronze.sql`) → 28 task `bronze_<target_name>` song song (max 2). Trigger thủ công. |
| `schema/bronze.sql` | DDL Iceberg 28 bảng Bronze. |
| `schema/silver.sql` | DDL tham khảo 28 bảng Silver (sinh từ Excel). dbt tự tạo bảng nên file này **chỉ để tra cột/kiểu/comment**, không chạy. |
| `sql/bronze/<target_name>.sql` | `INSERT OVERWRITE iceberg.pg_bronze.X SELECT ... FROM oracle.<SCHEMA>.<TABLE>`. |
| `sql/test/` | SQL kiểm tra tay trên Oracle. |
| `dbt/models/sources.yml` | Khai báo 28 bảng `source('pg_bronze', ...)`. |
| `dbt/models/silver_temp1/` | Model Silver Temp 1 + `_silver_temp1.yml` (mô tả cột + data_tests). |
| `dbt/macros/` | `fn_hash`, `t24_date`, `t24_datetime`, `t24_multi_value`, `etl_date`, `generate_schema_name`. |
| `common/` | Python dùng chung: `OracleConnection`, `TrinoConnection` (`.from_environment()`), exceptions, `get_logger`. |
| `docs/thuc_te_vs_thiet_ke.md` | Tổng hợp chỗ thực tế (Oracle/Bronze) khác Excel và cách đã xử lý. Cập nhật khi làm bảng mới. |
| `tests/` | pytest: `check_connection` (Oracle/Nessie/MinIO/Trino), `check_bronze` (6 check/bảng). |
| `conf/spark/spark-defaults.conf` | Catalog `iceberg` (Nessie) + catalog JDBC `oracle` (thông tin kết nối Oracle nằm ở đây và `.env`). |
| `conf/trino/` | Catalog `iceberg` của Trino. |

## Lệnh thường dùng

```bash
docker compose up -d                       # Airflow :8088, MinIO :9001, Trino :8080, Spark UI :8081, Nessie :19120
# Bronze
docker compose exec airflow-scheduler airflow dags trigger wave0_bronze_ingest --conf '{"etl_date": "2026-10-29"}'
# dbt (Silver)
docker compose exec dbt dbt run  --select ccy --vars '{etl_date: 2026-10-29}'
docker compose exec dbt dbt test --select ccy
docker compose exec dbt dbt ls --select ccy+              # model phía sau bị ảnh hưởng
docker compose exec dbt dbt ls --select +ccy              # upstream
# Test Python (chạy trong container Airflow; tests mount read-only)
docker compose exec airflow-scheduler bash -c "cd /opt/airflow && pytest -p no:cacheprovider tests/check_bronze -k t24core_currency --etl-date 2026-10-29"
# Truy vấn nhanh
docker compose exec trino trino --execute "SELECT count(*) FROM iceberg.pg_silver.ccy"
```

Lưu ý: docstring trong DAG ghi `dag_wave0_bronze_ingest` là **sai**, dag_id đúng là `wave0_bronze_ingest`.

## Quy ước bắt buộc

### Bronze
- Mirror 1:1 **toàn bộ** cột Oracle thực tế, giữ nguyên tên cột (UPPERCASE, bọc backtick). Mọi cột dữ liệu là `STRING`: cột số/ngày phải `CAST(src.\`X\` AS STRING) AS \`X\``.
- Cột có trong Excel nhưng Oracle không có: `CAST(NULL AS STRING) AS \`COL\``.
- 3 cột audit cuối: `CAST('${ETL_DATE}' AS DATE) AS ETL_DATE, CURRENT_TIMESTAMP() AS INGEST_TMS, '<TARGET_NAME_UPPER>' AS SRC_STM_CODE`. Partition theo `ETL_DATE`, `INSERT OVERWRITE` (dynamic partition).
- ⚠️ `tests/check_bronze` **parse bằng regex** `schema/bronze.sql` và `sql/bronze/*.sql` (mẫu `CREATE TABLE IF NOT EXISTS iceberg.pg_bronze.X (` … `\n)`, `` `COL` TYPE ``, `'X' AS SRC_STM_CODE`, `CAST(NULL AS STRING) AS \`X\``). Giữ đúng định dạng này.
- Thêm/sửa 1 bảng Bronze phải cập nhật đồng thời: `src/config/bronze_tables.py`, `schema/bronze.sql`, `sql/bronze/<name>.sql`, `dbt/models/sources.yml`.
- File SQL không được chứa `;` trong chuỗi literal (run_sql tách câu theo `;`). File có thể có BOM → đọc bằng `utf-8-sig`.

### Silver (dbt)
- Khoá: `{{ fn_hash('<PREFIX>', '<alias.col>') }}` = `lower(hex(md5(prefix || trim(col))))`, **không có ký tự phân cách `|`**; NULL/rỗng → NULL. Prefix lấy từ cột Transform trong sheet Excel (vd `T24_CURRENCY`, `T24_CUSTOMER`, `T24_LD_LOANS_AND_DEPOSITS`).
- Ngày batch: `{{ etl_date() }}` (đọc `var('etl_date')`), không hardcode ngày. Luôn lọc nguồn `WHERE <alias>.etl_date = {{ etl_date() }}`.
- Parse giá trị T24 dạng chuỗi: `t24_date` (yyyyMMdd), `t24_datetime` (yyMMddHHmm, có lpad), `t24_multi_value` (tách `#`). Số: `TRY_CAST(TRIM(x) AS DECIMAL(p,s))`; độ dài Excel `25.5` = `DECIMAL(25,5)`.
- **SCD TYPE 1**: copy khuôn `dbt/models/silver_temp1/ccy.sql` — `incremental` + `merge` + `unique_key=<id>`, các CTE `src → tgt → changed / deleted → final`; `sys_eff_dt` giữ lần đầu, `sys_exp_dt` = ngày ID biến mất (chỉ khi `EXISTS (SELECT 1 FROM src)`), `sys_udt_dt = etl_date`.
- **SNAPSHOT**: khuôn `exg_rate.sql` — `delete+insert`, `unique_key='etl_date'`, `partitioning ARRAY['etl_date']`.
- **SCD TYPE 2**: chưa có mẫu; theo Master guide: đóng dòng cũ `SYS_EXP_DT = ETL_DATE`, chèn dòng mới `SYS_EFF_DT = ETL_DATE, SYS_EXP_DT = NULL`; mỗi business key chỉ 1 dòng `SYS_EXP_DT IS NULL`.
- Join sang bảng SCD2/DIM **bắt buộc** `AND x.sys_exp_dt IS NULL` (chống fan-out).
- Cột output cuối: `CAST(... AS VARCHAR/DECIMAL/DATE)` tường minh, tên cột lowercase theo "Cột đích" của sheet, `on_schema_change='fail'`.
- Mỗi model mới: thêm vào `_<folder>.yml` (description kèm `[KIỂU(ĐỘ DÀI)]`, test `unique`/`not_null` cho khoá, `accepted_values` cho `src_stm_code`).
- Nessie không hỗ trợ VIEW → `views_enabled: false`; đừng dùng `materialized='view'`.
- Schema: mặc định `pg_silver`; folder `gold` → `pg_gold` (macro `generate_schema_name` dùng đúng tên, không ghép prefix).

## Workbook Excel (đặc tả)

- `Training_Fresher_DeepChecked.xlsx`: bản gốc. `Training_Fresher_DeepChecked_vs_Oracle.xlsx`: bản gốc + 2 sheet `Oracle_vs_Excel`, `Tong_hop` (đối chiếu cột Excel với Oracle thực tế, 2026-10-29). `OracleVsExcel.ods`: bản xuất của phần đối chiếu.
- Sheet quản trị: `Master` (SOP + quy ước + danh mục 48 sheet), `Phan_Cong_Task` (42 task, 8 track), `Job_dependence` (68 job: wave, bảng phải chờ, cron), `Bronze_Mapping_1_1`, `DDL` (392 cột nguồn), `Map_SRC2TRG` (lineage cột nguồn → Bronze → Silver).
- **Mỗi bảng Silver/Gold có 1 sheet riêng** đặt theo tên entity (vd bảng `CCY` → sheet `Currency`, `LOAN_AR_PRFL` → `Loan Arrangement Profile`; tra bảng ↔ sheet trong `Phan_Cong_Task`). Bố cục sheet:
  - Dòng 1 `TYPE : SCD TYPE 1|SCD TYPE 2|SNAPSHOT|TXN` → quyết định chiến lược load.
  - Khối header: bảng chính/phụ, alias (`Short table`), JOIN/ON/WHERE, các nhánh `UNION ALL`.
  - Bảng mapping: `Nguồn | Bảng nguồn | Cột nguồn | Transform | Entity | Attribute | Bảng đích | Cột đích | Kiểu | Độ dài | Diễn giải | Glossary | DDL Comment | Ghi chú kỹ thuật & Business Rule`. Cột cuối là **yêu cầu bắt buộc**.
- Excel **lệch** Oracle thực tế ở nhiều bảng (thiếu cột, sai kiểu, vd `T24CORE_CUSTOMER` Excel 63 cột nhưng Oracle chỉ 10, `T24CORE_LIMIT` thiếu 5 cột) → khi Excel và Oracle mâu thuẫn, xem sheet `Oracle_vs_Excel` và comment đầu file model; Oracle là sự thật cho Bronze.
- Đọc nhanh 1 sheet (cần `openpyxl`, máy chưa cài sẵn → dùng venv):
  ```bash
  python -c "import openpyxl,sys; ws=openpyxl.load_workbook('Training_Fresher_DeepChecked_vs_Oracle.xlsx',read_only=True,data_only=True)[sys.argv[1]]; [print(' | '.join(str(c) for c in r if c is not None)) for r in ws.iter_rows(values_only=True) if any(r)]" "Currency"
  ```

## Phụ thuộc giữa các wave (từ `Job_dependence`)

Wave 0 Bronze (00:30) → Wave 1 Silver Temp 1 (01:00) → Wave 2 Silver Temp 2 (01:30, `ar_tvr_smy` 01:45) → Wave 3 Gold DIM (02:00) → Wave 4 `inf_cst` (02:15) → `intf_loan_*` (02:30) → `fct_loan_ar` (02:45).
Phụ thuộc chi tiết theo bảng: cột `WAITING` của sheet `Job_dependence`; trong dbt dùng `dbt ls --select +model` / `model+`.

## Môi trường & bẫy

- Spark rất ít tài nguyên (`spark.cores.max=1`, executor 800m) → bảng lớn chạy chậm; không tăng song song DAG quá 2.
- Spark `TIMESTAMP` hiện trên Trino là `timestamp(6) with time zone`.
- Trino user dbt = `dbt`; catalog `iceberg`. Endpoint nội bộ: `minio:9000`, `nessie:19120/api/v2`, `spark://spark-master:7077`, `trino:8080`.
- `docker compose down -v` xoá toàn bộ dữ liệu Nessie/MinIO/Airflow.
- Không commit `.env`, không chép mật khẩu Oracle vào code/tài liệu mới.
- Ổ `/media/vu/FSS` thuộc root → git báo "dubious ownership"; cần `git config --global --add safe.directory /media/vu/FSS/Training_lakehouse`.
