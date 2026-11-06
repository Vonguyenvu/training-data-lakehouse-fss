{#- Các hàm parse giá trị T24 lưu dạng chuỗi trên PG_BRONZE (Spark SQL). Giá trị không parse được -> NULL. -#}

{#- Ngày dạng yyyyMMdd, vd '20251104'. -#}
{% macro t24_date(column) -%}
    CAST(try_to_timestamp(NULLIF(TRIM({{ column }}), ''), 'yyyyMMdd') AS DATE)
{%- endmacro %}

{#- DATE_TIME dạng yyMMddHHmm, vd '2210061056'; cột NUMBER bị mất số 0 đầu nên lpad về 10 ký tự. -#}
{% macro t24_datetime(column) -%}
    try_to_timestamp(LPAD(NULLIF(TRIM({{ column }}), ''), 10, '0'), 'yyMMddHHmm')
{%- endmacro %}

{#- Trường đa giá trị phân cách bằng '#': lấy phần tử thứ n (mặc định phần tử đầu). -#}
{% macro t24_multi_value(column, position=1) -%}
    NULLIF(SPLIT_PART({{ column }}, '#', {{ position }}), '')
{%- endmacro %}

{#- Ngày batch: dbt run --vars '{etl_date: 2026-10-29}'. Mặc định là ngày chạy. -#}
{% macro etl_date() -%}
    DATE '{{ var("etl_date", run_started_at.strftime("%Y-%m-%d")) }}'
{%- endmacro %}

{#- Ngày nghiệp vụ dùng cho điều kiện BOOKING_DATE / MOV_DATE = ngày batch của SNAPSHOT.
    Mặc định = etl_date (đúng đặc tả); test dữ liệu cũ: --vars '{etl_date: 2026-11-03, biz_date: 2025-09-26}'. -#}
{% macro biz_date() -%}
    DATE '{{ var("biz_date", var("etl_date", run_started_at.strftime("%Y-%m-%d"))) }}'
{%- endmacro %}

{#- Mã lưu kiểu NUMBER Oracle trên Bronze dạng '1602.0000000000' -> '1602' (khớp RECID bảng mã). -#}
{% macro t24_code(column) -%}
    CAST(CAST(TRY_CAST(TRIM({{ column }}) AS DECIMAL(30, 10)) AS DECIMAL(30, 0)) AS STRING)
{%- endmacro %}
