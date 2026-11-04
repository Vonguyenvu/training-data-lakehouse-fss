# Graph Report - Training_lakehouse  (2026-11-04)

## Corpus Check
- Corpus is ~21,246 words - fits in a single context window. You may not need a graph.

## Summary
- 484 nodes · 655 edges · 82 communities (24 shown, 58 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 46 edges (avg confidence: 0.93)
- Token cost: 46,759 input · 0 output

## Community Hubs (Navigation)
- Oracle Connection Layer
- Pytest Bronze & Connection Checks
- Project Docs & Bronze DAG
- Bronze Iceberg DDL
- Silver Iceberg DDL
- dbt Project Config
- Nessie & Postgres Services
- Silver Temp1 Model Tests
- dbt Trino Profile
- Trino Connection
- Airflow Environment
- MinIO Init Service
- dbt Bronze Sources
- Exception Hierarchy (docker copy)
- Airflow Init & Scheduler
- dbt & Trino Services
- Nessie Service Wiring
- Connection Protocol (docker copy)
- Airflow Common & Postgres
- Docker Build Contexts
- Airflow Init Container
- MinIO Service
- Compose Volumes
- Airflow Webserver
- Spark Master
- Spark Worker
- SCD1 Pattern & fn_hash

## God Nodes (most connected - your core abstractions)
1. `TrinoConnection` - 26 edges
2. `OracleConnection` - 21 edges
3. `ConnectionFailedError` - 19 edges
4. `BronzeTable` - 17 edges
5. `Connection` - 15 edges
6. `ConfigurationError` - 15 edges
7. `get_logger()` - 13 edges
8. `services` - 12 edges
9. `TrinoConnection` - 12 edges
10. `airflow-init` - 11 edges

## Surprising Connections (you probably didn't know these)
- `test_oracle_connection()` --uses--> `OracleConnection`  [INFERRED]
  tests/check_connection/test_connection.py → common/database/oracle_connection.py
- `oracle_columns()` --uses--> `OracleConnection`  [INFERRED]
  tests/check_bronze/test_bronze_tables.py → common/database/oracle_connection.py
- `oracle_count()` --uses--> `OracleConnection`  [INFERRED]
  tests/check_bronze/test_bronze_tables.py → common/database/oracle_connection.py
- `test_all_source_columns_loaded()` --uses--> `OracleConnection`  [INFERRED]
  tests/check_bronze/test_bronze_tables.py → common/database/oracle_connection.py
- `test_row_count_matches_oracle()` --uses--> `OracleConnection`  [INFERRED]
  tests/check_bronze/test_bronze_tables.py → common/database/oracle_connection.py

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Silver load strategies by sheet TYPE** — claude_scd_type1_pattern, claude_snapshot_pattern, claude_scd_type2_pattern [EXTRACTED 1.00]

## Communities (82 total, 58 thin omitted)

### Community 0 - "Oracle Connection Layer"
Cohesion: 0.07
Nodes (12): Connection, OracleConfig, OracleConnection, TrinoConfig, ConfigurationError, ConnectionFailedError, ExtractionError, LakehouseError (+4 more)

### Community 1 - "Pytest Bronze & Connection Checks"
Cohesion: 0.12
Nodes (20): TrinoConnection, BronzeTable, bronze_columns(), ddl_columns(), oracle_columns(), oracle_count(), partition_filter(), sql_file() (+12 more)

### Community 2 - "Project Docs & Bronze DAG"
Cohesion: 0.08
Nodes (14): CLAUDE.md project guide, Training_Fresher_DeepChecked.xlsx mapping spec, Medallion architecture (Bronze/Silver/Gold), Wave dependency schedule (Job_dependence), README.md FSS Training Data Platform, Docker compose stack (Airflow, Spark, MinIO, Nessie, Trino, dbt, Postgres), requirements.txt (minio, oracledb, python-dotenv, pyspark, pytest, trino), main() (+6 more)

### Community 3 - "Bronze Iceberg DDL"
Cohesion: 0.07
Nodes (28): iceberg.pg_bronze.ebanking_col_udf_value, iceberg.pg_bronze.flexbo_pgb_contract_udf_map, iceberg.pg_bronze.flexbo_pgb_ldtb_contract_master, iceberg.pg_bronze.flexbo_pgb_los_contract_fields_tdate, iceberg.pg_bronze.flexbo_pgbld_contract_udfield_hist, iceberg.pg_bronze.flexbo_pgbld_rt_contract_udfield_hist, iceberg.pg_bronze.los_app_facility, iceberg.pg_bronze.los_app_loan_disbursement (+20 more)

### Community 4 - "Silver Iceberg DDL"
Cohesion: 0.07
Nodes (28): iceberg.pg_silver.ar_avy_shd_itm, iceberg.pg_silver.ar_bal, iceberg.pg_silver.ar_dlq_smy, iceberg.pg_silver.ar_rate_hist, iceberg.pg_silver.ar_tvr_smy, iceberg.pg_silver.ar_x_ip_rltnp, iceberg.pg_silver.ast_ar_int_smy, iceberg.pg_silver.ccy (+20 more)

### Community 5 - "dbt Project Config"
Cohesion: 0.08
Nodes (24): clean-targets, config-version, gold, +materialized, +persist_docs, silver_temp1, silver_temp2, +views_enabled (+16 more)

### Community 6 - "Nessie & Postgres Services"
Cohesion: 0.10
Nodes (25): healthcheck, NESSIE_VERSION_STORE_PERSIST_ROCKS_DATABASE_PATH, NESSIE_VERSION_STORE_TYPE, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, QUARKUS_DATASOURCE_DB_KIND, QUARKUS_HTTP_PORT (+17 more)

### Community 7 - "Silver Temp1 Model Tests"
Cohesion: 0.13
Nodes (14): column_name, data_tests, description, name, accepted_values, relationships, unique, models (+6 more)

### Community 8 - "dbt Trino Profile"
Cohesion: 0.14
Nodes (13): catalog, host, http_scheme, method, port, schema, threads, type (+5 more)

### Community 10 - "Airflow Environment"
Cohesion: 0.48
Nodes (12): environment, environment, environment, AIRFLOW__API__AUTH_BACKENDS, AIRFLOW_CONN_SPARK_DEFAULT, AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION, AIRFLOW__CORE__EXECUTOR, AIRFLOW__CORE__LOAD_EXAMPLES (+4 more)

### Community 11 - "MinIO Init Service"
Cohesion: 0.18
Nodes (11): minio, AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY, condition, command, depends_on, entrypoint (+3 more)

### Community 12 - "dbt Bronze Sources"
Cohesion: 0.20
Nodes (9): sources, database, description, name, schema, tables, description, name (+1 more)

### Community 13 - "Exception Hierarchy (docker copy)"
Cohesion: 0.27
Nodes (4): ConfigurationError, ConnectionFailedError, ExtractionError, LakehouseError

### Community 14 - "Airflow Init & Scheduler"
Cohesion: 0.20
Nodes (10): condition, command, depends_on, env_file, image, user, volumes, depends_on (+2 more)

### Community 15 - "dbt & Trino Services"
Cohesion: 0.20
Nodes (10): build, command, depends_on, environment, volumes, working_dir, trino, DBT_PROFILES_DIR (+2 more)

### Community 16 - "Nessie Service Wiring"
Cohesion: 0.20
Nodes (10): minio-init, nessie, condition, condition, trino, depends_on, env_file, image (+2 more)

### Community 18 - "Airflow Common & Postgres"
Cohesion: 0.22
Nodes (9): depends_on, postgres, condition, x-airflow-common, depends_on, env_file, image, user (+1 more)

### Community 19 - "Docker Build Contexts"
Cohesion: 0.43
Nodes (8): build, build, build, context, dockerfile, build, build, build

### Community 20 - "Airflow Init Container"
Cohesion: 0.25
Nodes (8): command, entrypoint, env_file, image, restart, user, volumes, airflow-init

### Community 21 - "MinIO Service"
Cohesion: 0.25
Nodes (8): MINIO_ROOT_PASSWORD, MINIO_ROOT_USER, command, environment, image, ports, volumes, minio

### Community 22 - "Compose Volumes"
Cohesion: 0.29
Nodes (6): name, services, volumes, minio-data, nessie-data, postgres-data

### Community 23 - "Airflow Webserver"
Cohesion: 0.29
Nodes (7): command, env_file, image, ports, user, volumes, airflow-webserver

### Community 24 - "Spark Master"
Cohesion: 0.40
Nodes (5): spark-master, command, env_file, ports, volumes

### Community 25 - "Spark Worker"
Cohesion: 0.40
Nodes (5): spark-worker, command, depends_on, env_file, volumes

## Knowledge Gaps
- **3 isolated node(s):** `fn_hash surrogate key (md5 prefix||trim(col))`, `Wave dependency schedule (Job_dependence)`, `requirements.txt (minio, oracledb, python-dotenv, pyspark, pytest, trino)`
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 274 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **58 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `Compose Volumes` to `Nessie & Postgres Services`, `MinIO Init Service`, `Airflow Init & Scheduler`, `dbt & Trino Services`, `Nessie Service Wiring`, `Airflow Init Container`, `MinIO Service`, `Airflow Webserver`, `Spark Master`, `Spark Worker`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `TrinoConnection` (e.g. with `ConfigurationError` and `ConnectionFailedError`) actually correct?**
  _`TrinoConnection` has 13 INFERRED edges - model-reasoned connections that need verification._
- **What connects `fn_hash surrogate key (md5 prefix||trim(col))`, `Wave dependency schedule (Job_dependence)`, `requirements.txt (minio, oracledb, python-dotenv, pyspark, pytest, trino)` to the rest of the system?**
  _3 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Oracle Connection Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.06746031746031746 - nodes in this community are weakly interconnected._
- **Why does `TrinoConnection` connect `Pytest Bronze & Connection Checks` to `Oracle Connection Layer`, `Project Docs & Bronze DAG`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `OracleConnection` (e.g. with `ConfigurationError` and `ConnectionFailedError`) actually correct?**
  _`OracleConnection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **Should `Pytest Bronze & Connection Checks` be split into smaller, more focused modules?**
  _Cohesion score 0.12073170731707317 - nodes in this community are weakly interconnected._