{#-
    Override dbt-spark 1.9: bản gốc dùng run_query cho ALTER ... COMMENT; qua Thrift câu ALTER không có
    result set -> 'NoneType' object is not iterable. Dùng statement không fetch kết quả.
-#}
{% macro spark__alter_column_comment(relation, column_dict) %}
  {% for column_name in column_dict %}
    {% set comment = column_dict[column_name]['description'] | replace("'", "\\'") %}
    {% set col = adapter.quote(column_name) if column_dict[column_name]['quote'] else column_name %}
    {% call statement('alter_column_comment_' ~ loop.index, fetch_result=False) %}
      alter table {{ relation }} alter column {{ col }} comment '{{ comment }}'
    {% endcall %}
  {% endfor %}
{% endmacro %}
