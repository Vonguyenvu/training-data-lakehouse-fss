# exg_rate — sheet 'Exchange Rate'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_CURRENCY, PG_BRONZE.T24CORE_CURRENCY_HIS

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where
- 1 · PG_BRONZE · T24CORE_CURRENCY · CUR · sub · SELECT<br>        id AS FRST_CCY_CODE,<br>        'VND' AS SCD_CCY_CODE,<br>        COALESCE(CAST(REGEXP_SUBSTR(CUR.MID_REVAL_RATE, '[^#]+') AS DECIMAL(13,7)), 1) AS mid_reval_rate,<br>        DATE_TIME AS date_time_value,<br>        999999 AS curr_no,<br>        RANK() OVER (PARTITION BY id ORDER BY DATE_TIME DESC) AS rn<br>FROM PG_BRONZE.T24CORE_CURRENCY cur<br>WHERE TO_TIMESTAMP(TO_CHAR(DATE_TIME), 'YYMMDDHH24MI') < ${ETL_DATE} + 1
- 2 · PG_BRONZE · T24CORE_CURRENCY_HIS · CUR_HIS · sub · SELECT<br>        REGEXP_SUBSTR(ch.id, '[^;]+') AS FRST_CCY_CODE,<br>        'VND' AS SCD_CCY_CODE,<br>        COALESCE(CAST(ch.MID_REVAL_RATE AS DECIMAL(13,7)), 1) AS mid_reval_rate,<br>        DATE_TIME AS date_time_value,<br>        curr_no,<br>        RANK() OVER (PARTITION BY REGEXP_SUBSTR(ch.id, '[^;]+') ORDER BY DATE_TIME DESC) AS rn<br>FROM PG_BRONZE.T24CORE_CURRENCY_HIS ch<br>WHERE TO_TIMESTAMP(TO_CHAR(DATE_TIME), 'YYMMDDHH24MI') < ${ETL_DATE} + 1
- 3 · PG_BRONZE · T24CORE_CURRENCY, T24CORE_CURRENCY_HIS · CUR_MAIN · main · SELECT FRST_CCY_CODE,SCD_CCY_CODE,mid_reval_rate,date_time_value<br>FROM (SELECT <br>        FRST_CCY_CODE, SCD_CCY_CODE, mid_reval_rate, date_time_value, <br>                RANK() OVER (PARTITION BY FRST_CCY_CODE ORDER BY curr_no DESC) AS rank<br>    FROM (<br>        SELECT * FROM cur WHERE rn = 1<br>        UNION ALL<br>        SELECT * FROM cur_his WHERE rn = 1) ) <br>WHERE rank = 1

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_CURRENCY, T24CORE_CURRENCY_HIS | DATE_TIME | ${ETL_DATE} | SNPST_DT | DATE |  | Ngày dữ liệu |  |
| T24CORE_CURRENCY, T24CORE_CURRENCY_HIS | ID | 'T24_CURRENCY' | SRC_STM_CODE | VARCHAR2 | 32 | Mã nguồn dữ liệu | Sửa thành `'T24_CURRENCY'`. |
| T24CORE_CURRENCY, T24CORE_CURRENCY_HIS | ID | CUR_MAIN.FRST_CCY_CODE | FRST_CCY_CODE | VARCHAR2 | 20 | Mã loại tiền tệ gốc |  |
| T24CORE_CURRENCY, T24CORE_CURRENCY_HIS | ID | CUR_MAIN.SCD_CCY_CODE | SCD_CCY_CODE | VARCHAR2 | 20 | Mã loại tiền tệ tính tỷ giá |  |
| T24CORE_CURRENCY, T24CORE_CURRENCY_HIS | MID_REVAL_RATE, CURR_NO, DATE_TIME | CUR_MAIN.mid_reval_rate | MID_RATE | NUMBER | 25.7 | Tỷ giá mid | Đổi `AS int` thành `AS DECIMAL(13,7)` ở cả 2 subquery trên. |
