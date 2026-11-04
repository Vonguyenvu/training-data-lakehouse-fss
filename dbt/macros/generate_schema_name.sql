{#- Dùng đúng tên schema khai báo (+schema: pg_gold) thay vì ghép <target>_<custom> mặc định của dbt. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ (custom_schema_name or target.schema) | trim }}
{%- endmacro %}
