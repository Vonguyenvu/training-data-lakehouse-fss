# lmt — sheet 'Limit'

Tầng: Silver Temp 1 (Tech) · Wave: WAVE_1_SILVER_TEMP1 · Chờ: PG_BRONZE.T24CORE_LIMIT

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SCD TYPE 1
- Nguồn · Bảng nguồn · Short table · Business Rule
- PG_BRONZE · T24CORE_LIMIT · l · WHERE l.ETL_DATE = ${ETL_DATE} -- Bảng danh mục Hạn mức tín dụng

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| T24CORE_LIMIT | RECID | fn_hash("T24_LIMIT", l.RECID) | LMT_ID | CHAR | 32 | ID của hạn mức |  |
| T24CORE_LIMIT | RECID | 1:1 | LMT_CODE | VARCHAR2 | 32 | Mã hạn mức |  |
| T24CORE_LIMIT | LIMIT_PRODUCT | 1:1 | LMT_DSC | VARCHAR2 | 300 | Mô tả hạn mức | Map 1:1 từ T24CORE_LIMIT.LIMIT_PRODUCT sang LMT_DSC. |
| T24CORE_LIMIT | INTERNAL_AMOUNT | 1:1 | INR_LMT_AMT | NUMBER | 25.5 | Số tiền hạn mức nội bộ được cấp | Bổ sung ánh xạ 1:1 từ T24CORE_LIMIT.INTERNAL_AMOUNT |
| T24CORE_LIMIT | MAXIMUM_TOTAL | 1:1 | MAX_TOT_LMT | NUMBER | 25.5 | Tổng hạn mức tối đa được phê duyệt | Bổ sung ánh xạ 1:1 từ T24CORE_LIMIT.MAXIMUM_TOTAL |
| T24CORE_LIMIT | ONLINE_LIMIT_DATE | 1:1 | ONL_LMT_DT | DATE |  | Ngày hiệu lực hạn mức trực tuyến | Bổ sung ánh xạ 1:1 từ T24CORE_LIMIT.ONLINE_LIMIT_DATE |
| T24CORE_LIMIT | EXPIRY_DATE | 1:1 | LMT_EXP_DT | DATE |  | Ngày hết hạn hạn mức tín dụng | Bổ sung ánh xạ 1:1 từ T24CORE_LIMIT.EXPIRY_DATE |
| T24CORE_LIMIT | RECID | 'T24_LIMIT' | SRC_STM_CODE | VARCHAR2 | 20 | Mã nguồn dữ liệu | Sửa thành `'T24_LIMIT'`. |
| T24CORE_LIMIT | RECID | ETL_DATE if not exists LMT_ID | SYS_EFF_DT | DATE |  | Ngày hiệu lực bản ghi |  |
| T24CORE_LIMIT | RECID | ETL_DATE if RECID was deleted | SYS_EXP_DT | DATE |  | Ngày hết hiệu lực bản ghi |  |
| T24CORE_LIMIT | ONLINE_LIMIT_DATE | ETL_DATE | SYS_UDT_DT | DATE |  | Ngày cập nhật bản ghi |  |
