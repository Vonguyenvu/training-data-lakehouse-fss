{#-
    pre_hook cho mọi model Silver (dbt_project.yml). Chỉ tác động bảng incremental `merge` (SCD1/SCD2) đã có dữ liệu.
    - Bảng đã có lần chạy sau ETL_DATE (MAX(sys_udt_dt) > ETL_DATE) mà không truyền var `backdate: true` -> báo lỗi,
      vì merge ngày cũ lên trạng thái mới sẽ hỏng dữ liệu (SCD2 sinh 2 dòng cùng mở).
    - Có `backdate: true`:
        SCD2 (unique_key chứa sys_eff_dt): tua bảng về trước ETL_DATE: xóa phiên bản mở từ ETL_DATE trở đi,
          mở lại phiên bản bị đóng từ ETL_DATE trở đi.
        SCD1: không có lịch sử để tua, chỉ cho chạy; trạng thái đúng lại sau khi replay tới ngày mới nhất.
    Sau đó PHẢI replay tăng dần từ ETL_DATE tới ngày mới nhất (không cần backdate nữa).
-#}
{% macro scd_backdate() %}
{%- if execute and is_incremental() and config.get('incremental_strategy') == 'merge' -%}
  {%- set ahead = run_query('SELECT COALESCE(MAX(sys_udt_dt) > ' ~ etl_date() ~ ', FALSE) FROM ' ~ this).columns[0].values()[0] -%}
  {%- if ahead -%}
    {%- if var('backdate', false) not in [true, 'true', 'True'] -%}
      {{ exceptions.raise_compiler_error(this ~ ' đã có dữ liệu sau ' ~ etl_date() ~ '. Chạy backdate: thêm var backdate: true cho ngày đầu tiên, rồi replay tăng dần tới ngày mới nhất.') }}
    {%- endif -%}
    {%- if 'sys_eff_dt' in config.get('unique_key') -%}
      {% call statement('scd_backdate_delete', fetch_result=False) %}
        DELETE FROM {{ this }} WHERE sys_eff_dt >= {{ etl_date() }}
      {% endcall %}
      {% call statement('scd_backdate_reopen', fetch_result=False) %}
        UPDATE {{ this }} SET sys_exp_dt = NULL WHERE sys_exp_dt >= {{ etl_date() }}
      {% endcall %}
    {%- endif -%}
  {%- endif -%}
{%- endif -%}
{% endmacro %}
