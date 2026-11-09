{#-
    dbt run-operation assert_bronze_partition --vars '{etl_date: ...}'
    DAG chạy thay cho Bronze khi conf có skip_bronze (chạy lại Silver/Gold từ partition Bronze đã có, không đọc lại Oracle).
    Lỗi nếu cả 28 bảng Bronze đều không có dòng nào ở partition ETL_DATE (partition chưa từng nạp -> Silver sẽ đọc nguồn rỗng).
    Bảng rỗng lẻ chỉ ghi log: có bảng rỗng hợp lệ (vd flexbo_pgbld_contract_udfield_hist).
-#}
{% macro assert_bronze_partition() %}
{%- set parts = [] -%}
{%- for node in graph.nodes.values() if node.resource_type == 'model' and node.fqn[1] == 'bronze' -%}
    {%- do parts.append("SELECT '" ~ node.name ~ "' AS t, COUNT(*) AS n FROM " ~ node.schema ~ "." ~ node.alias
        ~ " WHERE ETL_DATE = " ~ etl_date()) -%}
{%- endfor -%}
{%- set rows = run_query(parts | join(' UNION ALL ')).rows -%}
{%- set empty = rows | selectattr(1, 'equalto', 0) | map(attribute=0) | list -%}
{%- if empty | length == rows | length -%}
    {{ exceptions.raise_compiler_error('Bronze chưa có partition ETL_DATE = ' ~ etl_date()
        ~ ' (cả ' ~ rows | length ~ ' bảng đều rỗng) -> không dùng skip_bronze được, chạy Bronze trước.') }}
{%- endif -%}
{{ log('Bronze ETL_DATE = ' ~ etl_date() ~ ': ' ~ (rows | length - empty | length) ~ '/' ~ rows | length
    ~ ' bảng có dữ liệu' ~ ('; rỗng: ' ~ empty | join(', ') if empty else ''), info=True) }}
{% endmacro %}
