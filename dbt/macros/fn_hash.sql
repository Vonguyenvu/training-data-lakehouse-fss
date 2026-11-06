{#-
    fn_hash("<SYSTEM_PREFIX>", <COL>) theo Master guide: khóa CHAR(32) = MD5 hex (chữ thường) của
    prefix + giá trị, không có ký tự phân cách. Giá trị NULL/rỗng -> NULL.
    Ví dụ: {{ fn_hash('T24_CURRENCY', 'cur.currency_code') }}
-#}
{% macro fn_hash(prefix, column) -%}
    CASE
        WHEN NULLIF(TRIM({{ column }}), '') IS NULL THEN NULL
        ELSE md5(CONCAT('{{ prefix }}', TRIM({{ column }})))  {#- Spark md5: hex chữ thường trên byte UTF-8 -#}
    END
{%- endmacro %}
