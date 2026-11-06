{#-
    Phần SCD TYPE 2 của khuôn ip_elc_adr.sql, sinh cho mọi cột (bảng Temp 2 có 100+ cột).
    Dùng: WITH src AS (<cột đã CAST đúng kiểu đích, đúng tên>) {{ scd2(['ar_id']) }}
    Model cần config: incremental + merge + unique_key = keys + ['sys_eff_dt'].
    - Key mới / xuất hiện lại / đổi bất kỳ cột nào -> mở phiên bản sys_eff_dt = ETL_DATE.
    - Dòng đang mở bị đổi giá trị, hoặc key biến mất khi nguồn có dữ liệu -> sys_exp_dt = ETL_DATE.
    `guard`: CTE dùng để kiểm tra "nguồn có dữ liệu" (mặc định src).
    `close_missing=false`: nguồn chỉ là lát cắt theo ngày (vd bút toán BOOKING_DATE = ngày chạy) -> key vắng mặt
    không có nghĩa là bị xóa, chỉ đóng dòng khi giá trị đổi.
    Phải chạy ETL_DATE tăng dần.
-#}
{% macro scd2(keys, guard='src', close_missing=true) -%}
{%- set sys_cols = ['sys_eff_dt', 'sys_exp_dt', 'sys_udt_dt', 'etl_date'] -%}
{% if is_incremental() %}
{#- unit test: `this` là CTE fixture, không introspect được -> lấy cột từ bảng thật của model được test (phải đã build). -#}
{%- set col_rel = this if model.resource_type != 'unit_test'
      else api.Relation.create(schema=model.schema, identifier=model.tested_node_unique_id.split('.')[-1]) -%}
{%- set all_cols = adapter.get_columns_in_relation(col_rel) | map(attribute='name') | map('lower') | reject('in', sys_cols) | list -%}
{%- set attrs = all_cols | reject('in', keys) | list -%}
{%- set diff -%}NOT ({% for a in attrs %}{{ 'AND ' if not loop.first }}s.{{ a }} <=> c.{{ a }} {% else %}TRUE{% endfor %}){%- endset -%}
, cur AS (
    SELECT * FROM {{ this }} WHERE sys_exp_dt IS NULL
),

new_ver AS (
    SELECT {% for c in all_cols %}s.{{ c }}, {% endfor %}
           {{ etl_date() }} AS sys_eff_dt, CAST(NULL AS DATE) AS sys_exp_dt
    FROM src AS s
    LEFT JOIN cur AS c ON {% for k in keys %}{{ 'AND ' if not loop.first }}c.{{ k }} = s.{{ k }} {% endfor %}
    WHERE c.{{ keys[0] }} IS NULL
       OR {{ diff }}
),

closed AS (
    -- sys_eff_dt = ETL_DATE (chạy lại cùng ngày) không đóng: new_ver ghi đè chính dòng đó.
    SELECT {% for c in all_cols %}c.{{ c }}, {% endfor %}
           c.sys_eff_dt, {{ etl_date() }} AS sys_exp_dt
    FROM cur AS c
    LEFT JOIN src AS s ON {% for k in keys %}{{ 'AND ' if not loop.first }}c.{{ k }} = s.{{ k }} {% endfor %}
    WHERE c.sys_eff_dt < {{ etl_date() }}
      AND (
            (s.{{ keys[0] }} IS NULL AND {{ 'EXISTS (SELECT 1 FROM ' ~ guard ~ ')' if close_missing else 'FALSE' }})
         -- chỉ so giá trị khi key còn ở nguồn (nguồn rỗng không đóng dòng)
         OR (s.{{ keys[0] }} IS NOT NULL
             AND {{ diff }})
      )
),

final AS (
    SELECT * FROM new_ver
    UNION ALL
    SELECT * FROM closed
)
{% else %}
, final AS (
    SELECT src.*, {{ etl_date() }} AS sys_eff_dt, CAST(NULL AS DATE) AS sys_exp_dt
    FROM src
)
{% endif %}
SELECT final.*, {{ etl_date() }} AS sys_udt_dt, {{ etl_date() }} AS etl_date
FROM final
{%- endmacro %}
