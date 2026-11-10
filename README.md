# FSS Training Data Platform

Stack local phục vụ mapping trong `Training_Fresher_DeepChecked.xlsx`:

- Airflow: điều phối DAG và các bước Bronze/Silver/Gold.
- Spark: chạy Spark SQL/DataFrame.
- MinIO: object storage S3-compatible (`raw` cho landing, `warehouse` cho Iceberg).
- Nessie: catalog Iceberg dùng chung cho Spark và Trino.
- Trino: truy vấn các bảng Iceberg qua HTTP/CLI.
- dbt-trino: quản lý SQL models và kiểm thử transformation trên Trino.
- PostgreSQL: metadata database của Airflow và nguồn PostgreSQL mẫu.

## Khởi động

Yêu cầu Docker Desktop đang chạy. Từ thư mục dự án:

```powershell
docker compose up -d
docker compose ps
```

Truy cập:

- Airflow: http://localhost:8088 (`admin` / `admin`)
- MinIO Console: http://localhost:9001 (`minioadmin` / `minioadmin123`)
- Trino: http://localhost:8080
- Spark Master UI: http://localhost:8081
- Nessie API: http://localhost:19120

## Chạy dbt

Service `dbt` được build local từ [dbt/Dockerfile](./dbt/Dockerfile), kết nối tới catalog `iceberg` trên Trino.

```powershell
docker compose build dbt
docker compose up -d dbt
docker compose exec dbt dbt debug
docker compose exec dbt dbt run
docker compose exec dbt dbt test
```

Thêm các model SQL vào `dbt/models/`. Profile mặc định dùng schema `silver`; có thể đổi schema trong [dbt/profiles.yml](./dbt/profiles.yml).

## Kiểm tra Trino

```powershell
docker compose exec trino trino --execute "SHOW CATALOGS"
docker compose exec trino trino --execute "SHOW SCHEMAS FROM iceberg"
```

Trong DAG hoặc Spark job, dùng các endpoint nội bộ:

```text
S3 endpoint: http://minio:9000
Iceberg catalog: http://nessie:19120/api/v2
Spark master: spark://spark-master:7077
Trino: http://trino:8080
```

Các thư mục `dags/`, `sql/` và `src/` đã được mount vào Airflow/Spark để triển khai mapping theo các sheet Bronze, Silver và Gold trong workbook.

## Dừng và xóa dữ liệu local

```powershell
docker compose down
docker compose down -v
```

Lệnh `down -v` sẽ xóa metadata Airflow, catalog Nessie và dữ liệu MinIO.
