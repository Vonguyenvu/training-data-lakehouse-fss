{#-
    pre_hook cho mọi model Silver và Gold (dbt_project.yml). Chỉ tác động bảng incremental `merge` (SCD1/SCD2) đã có dữ liệu.
    - Bảng đã có lần chạy sau ETL_DATE (MAX(sys_udt_dt) > ETL_DATE) mà không truyền var `backdate: true` -> báo lỗi,
      vì merge ngày cũ lên trạng thái mới sẽ hỏng dữ liệu (SCD2 sinh 2 dòng cùng mở).
    - Có `backdate: true` (kể cả khi ETL_DATE = ngày mới nhất, MAX(sys_udt_dt) >= ETL_DATE):
        SCD2 (unique_key chứa sys_eff_dt): tua bảng về trước ETL_DATE: xóa phiên bản mở từ ETL_DATE trở đi,
          mở lại phiên bản bị đóng từ ETL_DATE trở đi.
        SCD1: không có lịch sử để tua, chỉ cho chạy; trạng thái đúng lại sau khi replay tới ngày mới nhất.
    Sau đó PHẢI replay tăng dần từ ETL_DATE tới ngày mới nhất, VẪN truyền backdate: true cho mọi ngày replay:
    dòng được mở lại / dòng SCD1 không đổi vẫn giữ SYS_UDT_DT cũ (> ngày đang replay), thiếu cờ thì ngày replay
    ở giữa bị chặn. Cờ an toàn cho mọi ngày: phiên bản đã ghi khi replay có SYS_EFF_DT < ngày kế tiếp nên không bị xóa.
    Qua DAG thêm "skip_bronze": true để không ghi đè partition Bronze cũ bằng dữ liệu Oracle hiện tại.
-#}
{% macro scd_backdate() %}
{%- if execute and is_incremental() and config.get('incremental_strategy') == 'merge' -%}
  {%- set backdate = var('backdate', false) in [true, 'true', 'True'] -%}
  {#- có cờ thì tua cả khi ETL_DATE = ngày mới nhất (chạy lại ngày đó sau khi nguồn được sửa), tránh phiên bản thừa -#}
  {%- set ahead = run_query('SELECT COALESCE(MAX(sys_udt_dt) ' ~ ('>=' if backdate else '>') ~ ' ' ~ etl_date() ~ ', FALSE) FROM ' ~ this).columns[0].values()[0] -%}
  {%- if ahead -%}
    {%- if not backdate -%}
      {{ exceptions.raise_compiler_error(this ~ ' đã có dữ liệu sau ' ~ etl_date() ~ '. Chạy backdate: thêm var backdate: true cho ngày đầu tiên, rồi replay tăng dần tới ngày mới nhất.') }}
    {%- endif -%}
    {%- if 'sys_eff_dt' in config.get('unique_key') -%}
      {% call statement('scd_backdate_delete', fetch_result=False) %}
        DELETE FROM {{ this }}
        WHERE sys_eff_dt >= {{ etl_date() }}
      {% endcall %}
      {% call statement('scd_backdate_reopen', fetch_result=False) %}
        UPDATE {{ this }} SET sys_exp_dt = NULL
        WHERE sys_exp_dt >= {{ etl_date() }}
      {% endcall %}
    {%- endif -%}
  {%- endif -%}
{%- endif -%}
{% endmacro %}
