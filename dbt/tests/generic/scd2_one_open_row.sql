{#-
    SCD2: mỗi khóa tự nhiên chỉ có tối đa 1 dòng đang mở (sys_exp_dt IS NULL).
    Dùng ở mức model: data_tests: [{scd2_one_open_row: {arguments: {key_columns: [cst_id, elc_adr_tp]}}}]
-#}
{% test scd2_one_open_row(model, key_columns) %}
SELECT {{ key_columns | join(', ') }}, COUNT(*) AS n_open
FROM {{ model }}
WHERE sys_exp_dt IS NULL
GROUP BY {{ key_columns | join(', ') }}
HAVING COUNT(*) > 1
{% endtest %}
