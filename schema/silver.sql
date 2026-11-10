-- Spark SQL / Iceberg DDL cho 28 bảng PG_SILVER (iceberg.pg_silver.*).
-- Nguồn thiết kế: các sheet entity trong Training_Fresher_DeepChecked.xlsx (cột đích, kiểu, độ dài, diễn giải).
-- Quy ước kiểu: VARCHAR2/CHAR -> STRING (độ dài gốc ghi trong COMMENT), NUMBER(p.s) -> DECIMAL(p,s), DATE/TIMESTAMP giữ nguyên.
-- SNAPSHOT/TXN: PARTITIONED BY (ETL_DATE), ghi bằng INSERT OVERWRITE theo ngày.
-- SCD TYPE 1/2: không partition, cập nhật bằng MERGE INTO; SCD2 dùng SYS_EFF_DT/SYS_EXP_DT/SYS_UDT_DT.
-- Mọi bảng có thêm cột kỹ thuật ETL_DATE (ngày batch ghi bản ghi) nếu sheet chưa khai báo.
-- Chạy một lần trước khi nạp dữ liệu.

CREATE NAMESPACE IF NOT EXISTS iceberg.pg_silver;

-- ==================== SILVER TEMP 1 ====================

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ip_alt_identn (
    `CST_ID`            STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`          STRING         COMMENT 'Mã CIF [VARCHAR2(20)]',
    `IDENTN_TP_CODE`    STRING         COMMENT 'Loại giấy tờ [VARCHAR2(20)]',
    `IDENTN_ISSU_DT`    DATE           COMMENT 'Ngày cấp giấy tờ [DATE]',
    `IDENTN_EXPIRY_DT`  DATE           COMMENT 'Ngày hêt hạn giấy tờ [DATE]',
    `ISSU_PLC_CODE`     STRING         COMMENT 'Nơi cấp giấy tờ [VARCHAR2(20)]',
    `IDENTN_NBR`        STRING         COMMENT 'Mã giấy tờ [VARCHAR2(100)]',
    `SYS_EFF_DT`        DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`        DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`        DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`          DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Involved Party Alternative Iden | SCD TYPE 2 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ip_elc_adr (
    `CST_ID`       STRING         COMMENT 'Unique key khách hàng trên DWH [CHAR(32)]',
    `CST_CODE`     STRING         COMMENT 'Mã khách hàng (CIF) [VARCHAR2(20)]',
    `ELC_ADR_TP`   STRING         COMMENT 'Loại địa chỉ điện tử (EMAIL / HOME_NUMBER / MOBILE_NUMBER) [VARCHAR2(20)]',
    `ELC_ADR_VAL`  STRING         COMMENT 'Giá trị địa chỉ liên lạc điện tử [VARCHAR2(100)]',
    `SYS_EFF_DT`   DATE           COMMENT 'Ngày hiệu lực bản ghi SCD2 [DATE]',
    `SYS_EXP_DT`   DATE           COMMENT 'Ngày hết hiệu lực bản ghi SCD2 [DATE]',
    `SYS_UDT_DT`   DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`     DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Involved Party Electronic Addre | SCD TYPE 2 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ip_pst_adr (
    `CST_ID`       STRING         COMMENT 'Unique key khách hàng trên DWH [CHAR(32)]',
    `CST_CODE`     STRING         COMMENT 'Mã khách hàng (CIF) [VARCHAR2(20)]',
    `PST_ADR_TP`   STRING         COMMENT 'Loại địa chỉ bưu chính [VARCHAR2(20)]',
    `PST_ADR_VAL`  STRING         COMMENT 'Địa chỉ cư trú hiện tại đầy đủ [VARCHAR2(100)]',
    `CTY_NM`       STRING         COMMENT 'Tên quốc gia cư trú hiện tại [VARCHAR2(100)]',
    `PROV_NM`      STRING         COMMENT 'Tên tỉnh/thành phố cư trú hiện tại [VARCHAR2(100)]',
    `STR_NM`       STRING         COMMENT 'Số nhà, tên đường cư trú hiện tại [VARCHAR2(100)]',
    `SYS_EFF_DT`   DATE           COMMENT 'Ngày hiệu lực bản ghi SCD2 [DATE]',
    `SYS_EXP_DT`   DATE           COMMENT 'Ngày hết hiệu lực bản ghi SCD2 [DATE]',
    `SYS_UDT_DT`   DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`     DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Involved Party Postal Address | SCD TYPE 2 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ccy (
    `CCY_ID`            STRING         COMMENT 'Mã duy nhất của loại tiền trên DWH [CHAR(32)]',
    `CCY_CODE`          STRING         COMMENT 'Mã loại tiền [VARCHAR2(20)]',
    `CCY_NM`            STRING         COMMENT 'Tên loại tiền [VARCHAR2(300)]',
    `NUMERIC_CCY_CODE`  STRING         COMMENT 'Mã tiền tệ dạng số [VARCHAR2(20)]',
    `SRC_STM_CODE`      STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(20)]',
    `SYS_EFF_DT`        DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`        DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`        DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`          DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Currency | SCD TYPE 1 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.pd (
    `PD_ID`         STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `PD_CODE`       STRING         COMMENT 'Mã sản phẩm [VARCHAR2(32)]',
    `PD_NM`         STRING         COMMENT 'Tên sản phẩm [VARCHAR2(255)]',
    `SRC_STM_CODE`  STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(20)]',
    `SYS_EFF_DT`    DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`    DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`    DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`      DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Product | SCD TYPE 1 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ou (
    `OU_ID`       STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `OU_CODE`     STRING         COMMENT 'Mã chi nhánh [VARCHAR2(32)]',
    `OU_NM`       STRING         COMMENT 'Tên chi nhánh [VARCHAR2(300)]',
    `SYS_EFF_DT`  DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`  DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`  DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`    DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Organization Unit | SCD TYPE 1 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.empe (
    `EMPE_ID`     STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `EMPE_CODE`   STRING         COMMENT 'Mã NHÂN VIÊN [VARCHAR2(20)]',
    `EMPE_NM`     STRING         COMMENT 'Tên NHÂN VIÊN [VARCHAR2(255)]',
    `SYS_EFF_DT`  DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`  DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`  DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`    DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Employee | SCD TYPE 1 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.lmt (
    `LMT_ID`        STRING         COMMENT 'ID của hạn mức [CHAR(32)]',
    `LMT_CODE`      STRING         COMMENT 'Mã hạn mức [VARCHAR2(32)]',
    `LMT_DSC`       STRING         COMMENT 'Mô tả hạn mức [VARCHAR2(300)]',
    `INR_LMT_AMT`   DECIMAL(25,5)  COMMENT 'Số tiền hạn mức nội bộ được cấp [NUMBER(25,5)]',
    `MAX_TOT_LMT`   DECIMAL(25,5)  COMMENT 'Tổng hạn mức tối đa được phê duyệt [NUMBER(25,5)]',
    `ONL_LMT_DT`    DATE           COMMENT 'Ngày hiệu lực hạn mức trực tuyến [DATE]',
    `LMT_EXP_DT`    DATE           COMMENT 'Ngày hết hạn hạn mức tín dụng [DATE]',
    `SRC_STM_CODE`  STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(20)]',
    `SYS_EFF_DT`    DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`    DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`    DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`      DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Limit | SCD TYPE 1 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.cv (
    `CL_ID`         STRING         COMMENT 'Mã duy nhất của CL [CHAR(32)]',
    `CL_CODE`       STRING         COMMENT 'Mã phân loại [VARCHAR2(20)]',
    `CL_DSC`        STRING         COMMENT 'mô tả [VARCHAR2(1000)]',
    `CL_SCM_CODE`   STRING         COMMENT 'Nhóm phân loại [VARCHAR2(30)]',
    `SRC_STM_CODE`  STRING         COMMENT 'Nguồn dữ liệu [VARCHAR2(20)]',
    `SYS_EFF_DT`    DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`    DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`    DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`      DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Classification Value | SCD TYPE 1 (LOOKUP MASTER) | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.sk_lich_tra_no (
    `LD_MB_RM_BANCHEO`       STRING         COMMENT 'ID nhân viên giới thiệu [VARCHAR2(100)]',
    `LD_ORIG_VAL_DATE`       DATE           COMMENT 'Ngày hiệu lực đầu tiên của hợp đồng [DATE]',
    `LD_PE_RATE`             DECIMAL(13,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(13,7)]',
    `LD_PRIN_LIQ_ACCT`       STRING         COMMENT 'Tài khoản thanh toán gốc [VARCHAR2(100)]',
    `LD_PRODUCTGR_CODE`      STRING         COMMENT 'Mã nhóm sản phẩm [VARCHAR2(100)]',
    `PS_RATE`                DECIMAL(13,7)  COMMENT 'Lãi suất cho quá hạn [NUMBER(13,7)]',
    `LD_REAL_RATE`           DECIMAL(13,7)  COMMENT 'Lãi suât thực tế [NUMBER(13,7)]',
    `LD_RECID`               STRING         COMMENT 'Mã hợp đồng [VARCHAR2(100)]',
    `LD_RECORD_STATUS`       STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(100)]',
    `STATUS`                 STRING         COMMENT 'Trạng thái [VARCHAR2(100)]',
    `LD_USE_OF_LOAN`         STRING         COMMENT 'Mã mục đích vay [VARCHAR2(100)]',
    `LD_USE_OF_LOAN_CHA`     STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(100)]',
    `LD_VALUE_DATE`          DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `LDH_ACC_FCC`            STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(100)]',
    `AMOUNT`                 DECIMAL(25,5)  COMMENT 'Dự nợ hợp đồng [NUMBER(25,5)]',
    `LDH_APPROVE_AMOUNT`     DECIMAL(25,5)  COMMENT 'Giá trị giải ngân [NUMBER(25,5)]',
    `LDH_CATEGORY`           STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(100)]',
    `LDH_CO_CODE`            STRING         COMMENT 'Mã chi nhánh [VARCHAR2(100)]',
    `LDH_COMMIT_ACTION`      STRING         COMMENT 'Trường COMMIT_ACTION của bảng nguồn T24CORE.LD_LOANS_AND_DEPOSITS_HIS [VARCHAR2(100)]',
    `CRA_LD`                 STRING         COMMENT 'Mã hồ sơ [VARCHAR2(100)]',
    `LDH_CURR_NO`            DECIMAL(10,0)  COMMENT 'Version của bản ghi [NUMBER(10,0)]',
    `LDH_CURRENCY`           STRING         COMMENT 'Mã loại tiền [VARCHAR2(100)]',
    `CUSTOMER_ID`            STRING         COMMENT 'Mã khách hành [VARCHAR2(100)]',
    `LDH_DATE_TIME`          DATE           COMMENT 'Ngày nhập liệu Core [DATE]',
    `DRAWDOWN_NET_AMT`       DECIMAL(25,5)  COMMENT 'Số tiền thực tế giải ngân [NUMBER(25,5)]',
    `EXCG_RATE`              DECIMAL(13,7)  COMMENT 'Tỷ giá quy đổi [NUMBER(13,7)]',
    `FIN_MAT_DATE`           DATE           COMMENT 'Ngày đáo hạn [DATE]',
    `INT_LIQ_ACCT`           STRING         COMMENT 'Tài khoản thanh toán lãi [VARCHAR2(100)]',
    `INT_RATE_TYPE`          STRING         COMMENT 'Loại lãi suất: cố định, thả nổi [VARCHAR2(20)]',
    `INT_VALUE_DATE`         DATE           COMMENT 'Ngày thu lãi [DATE]',
    `INTEREST_RATE`          DECIMAL(13,7)  COMMENT 'Giá trị lãi suất [NUMBER(13,7)]',
    `INTEREST_SPREAD`        DECIMAL(13,7)  COMMENT 'Biên độ lãi suất [NUMBER(13,7)]',
    `LOC_TERM`               STRING         COMMENT 'Kỳ hạn [VARCHAR2(100)]',
    `LDH_MB_RM_BANCHEO`      STRING         COMMENT 'ID nhân viên giới thiệu [VARCHAR2(100)]',
    `LDH_ORIG_VAL_DATE`      DATE           COMMENT 'Ngày hiệu lực đầu tiên của hợp đồng [DATE]',
    `LDH_PRIN_LIQ_ACCT`      STRING         COMMENT 'tài khoản thanh toán gốc [VARCHAR2(100)]',
    `LDH_REAL_RATE`          DECIMAL(13,7)  COMMENT 'Lãi suâất thực tế [NUMBER(13,7)]',
    `LDH_RECID`              STRING         COMMENT 'Mã Hợp đồng [VARCHAR2(100)]',
    `LDH_RECORD_STATUS`      STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(100)]',
    `LDH_USE_OF_LOAN`        STRING         COMMENT 'Mã Mục đích vay [VARCHAR2(100)]',
    `LDH_USE_OF_LOAN_CHA`    STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(100)]',
    `LDH_VALUE_DATE`         DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `CONTRACT_ID`            STRING         COMMENT 'Mã Hợp đồng [VARCHAR2(100)]',
    `PREV_SCHED_DATE`        DATE           COMMENT 'Ngày thanh toán gần nhất [DATE]',
    `LD_ID`                  STRING         COMMENT 'Mã Hợp đồng [VARCHAR2(100)]',
    `MG_PRODUCTGR_CODE`      STRING         COMMENT 'Mã sản phẩm [VARCHAR2(100)]',
    `AUTHORISER`             STRING         COMMENT 'ID người phê duyệt [VARCHAR2(100)]',
    `PD_CREDIT_STATUS`       STRING         COMMENT 'Tình trạng tín dụng [VARCHAR2(100)]',
    `PD_CURR_NO`             DECIMAL(10,0)  COMMENT 'Version hiện tại của bản ghi [NUMBER(10,0)]',
    `PD_CUSTOMER`            STRING         COMMENT 'Mã Khách hàng [VARCHAR2(100)]',
    `PD_FLAG_STATUS`         STRING         COMMENT 'Trường FLAG_STATUS của bảng nguồn T24CORE.PD_PAYMENT_DUE [VARCHAR2(100)]',
    `INPUTTER`               STRING         COMMENT 'ID người nhập liệu [VARCHAR2(100)]',
    `LOS_FAC_CODE`           STRING         COMMENT 'Số hồ sơ [VARCHAR2(100)]',
    `PD_ORIGINAL_MAT`        DATE           COMMENT 'Kỳ hạn gốc [DATE]',
    `PD_PD_TYPE`             STRING         COMMENT 'Pd_type = 1 là các khoản phạt gốc quá hạn, lãi quá hạn đc migrate sang thành phần IN Null là gốc, lãi quá hạn [VARCHAR2(100)]',
    `PD_PE_RATE`             DECIMAL(13,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(13,7)]',
    `PD_PENALTY_RATE`        DECIMAL(13,7)  COMMENT 'Lãi suất phạt quá hạn danh nghĩa (Penalty Rate) [NUMBER(13,7)]',
    `PD_RECID`               STRING         COMMENT 'Mã hợp đồng [VARCHAR2(100)]',
    `SNQH_CHUYENDOI`         DECIMAL(10,0)  COMMENT 'Số ngày quá hạn chuyển đổi [NUMBER(10,0)]',
    `PD_USE_OF_LOAN`         STRING         COMMENT 'Mã mục đích vay [VARCHAR2(100)]',
    `PD_USE_OF_LOAN_CHA`     STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(100)]',
    `PDH_CURR_NO`            DECIMAL(10,0)  COMMENT 'Trường CURR_NO của bảng nguồn T24CORE.PD_PAYMENT_DUE_HIS [NUMBER(10,0)]',
    `PDH_PD_TYPE`            STRING         COMMENT 'Loại sản phẩm [VARCHAR2(100)]',
    `PDH_RECID`              STRING         COMMENT 'Số hồ sơ [VARCHAR2(100)]',
    `PDHMV_ACC_FCC`          STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(100)]',
    `PDHMV_APPROVE_AMOUNT`   DECIMAL(25,5)  COMMENT 'Giá trị giải ngân [NUMBER(25,5)]',
    `PDHMV_CATEGORY`         STRING         COMMENT 'Mã phân loại sản phẩm vay [VARCHAR2(100)]',
    `PDHMV_CO_CODE`          STRING         COMMENT 'Mã chi nhánh [VARCHAR2(100)]',
    `PDHMV_CREDIT_STATUS`    STRING         COMMENT 'Nhóm nợ hợp đồng [VARCHAR2(100)]',
    `PDHMV_CURR_NO`          DECIMAL(10,0)  COMMENT 'Version hiện tại của bản ghi [NUMBER(10,0)]',
    `PDHMV_CUSTOMER`         STRING         COMMENT 'Mã khách hàng [VARCHAR2(100)]',
    `PDHMV_DATE_TIME`        DATE           COMMENT 'Trường DATE_TIME của bảng nguồn T24CORE.PD_PAYMENT_DUE_HIS_MV [DATE]',
    `PDHMV_FINAL_DUE_DATE`   DATE           COMMENT 'Ngày trả nơ cuối khi quá hạn [DATE]',
    `PDHMV_FLAG_STATUS`      STRING         COMMENT 'Cờ đánh dấu trạng thái bản ghi [VARCHAR2(100)]',
    `PDHMV_ORIGINAL_MAT`     DATE           COMMENT 'Ngày đáo hạn gốc [DATE]',
    `PDHMV_PAY_TYPE`         STRING         COMMENT 'Loại hình thanh toán [VARCHAR2(100)]',
    `PDHMV_PD_TYPE`          STRING         COMMENT 'Loại sản phẩm [VARCHAR2(100)]',
    `PDHMV_PE_RATE`          DECIMAL(13,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(13,7)]',
    `PDHMV_PENALTY_RATE`     DECIMAL(13,7)  COMMENT 'Lãi suất phạt quá hạn danh nghĩa lịch sử [NUMBER(13,7)]',
    `PDHMV_RECID`            STRING         COMMENT 'Key bản ghi [VARCHAR2(100)]',
    `PDHMV_RECORD_STATUS`    STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(100)]',
    `PDHMV_REPAYMENT_ACCT`   STRING         COMMENT 'Số tài khoản thanh toán [VARCHAR2(100)]',
    `ACC_FCC`                STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(100)]',
    `APPROVE_AMOUNT`         DECIMAL(25,5)  COMMENT 'Giá trị giải ngân [NUMBER(25,5)]',
    `CATEGORY`               STRING         COMMENT 'Mã phân loại sản phẩm vay [VARCHAR2(100)]',
    `CO_CODE`                STRING         COMMENT 'Mã chi nhánh [VARCHAR2(100)]',
    `COMMIT_ACTION`          STRING         COMMENT 'Trường COMMIT_ACTION của bảng nguồn T24CORE.PD_PAYMENT_DUE_MV [VARCHAR2(100)]',
    `CREDIT_STATUS`          STRING         COMMENT 'Nhóm nợ hợp đồng [VARCHAR2(100)]',
    `CURR_NO`                DECIMAL(10,0)  COMMENT 'Version hiện tại của bản ghi [NUMBER(10,0)]',
    `CUSTOMER`               STRING         COMMENT 'Mã khách hàng [VARCHAR2(100)]',
    `DATE_TIME`              DATE           COMMENT 'Trường DATE_TIME của bảng nguồn T24CORE.PD_PAYMENT_DUE_MV [DATE]',
    `FINAL_DUE_DATE`         DATE           COMMENT 'Ngày trả nơ cuối khi quá hạn [DATE]',
    `FLAG_STATUS`            STRING         COMMENT 'Cờ đánh dấu trạng thái bản ghi [VARCHAR2(100)]',
    `ID`                     STRING         COMMENT 'Mã hợp đồng [VARCHAR2(100)]',
    `ORIGINAL_MAT`           DATE           COMMENT 'Ngày đáo hạn gốc [DATE]',
    `PAY_AMT_OUTS`           DECIMAL(25,5)  COMMENT 'Số tiền còn lại chưa thanh toán [NUMBER(25,5)]',
    `PAY_TYPE`               STRING         COMMENT 'Loại hình thanh toán [VARCHAR2(100)]',
    `PAYMENT_DTE_DUE`        DATE           COMMENT 'Hạn thanh toán [DATE]',
    `PD_TYPE`                STRING         COMMENT 'Loại sản phẩm [VARCHAR2(100)]',
    `PE_RATE`                DECIMAL(13,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(13,7)]',
    `PENALTY_RATE`           DECIMAL(13,7)  COMMENT 'Lãi suất phạt quá hạn danh nghĩa (Multi-value) [NUMBER(13,7)]',
    `RECID`                  STRING         COMMENT 'Key bản ghi [VARCHAR2(100)]',
    `RECORD_STATUS`          STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(100)]',
    `REPAID_AMT`             DECIMAL(25,5)  COMMENT 'Số tiền đã trả [NUMBER(25,5)]',
    `REPAYMENT_ACCT`         STRING         COMMENT 'Số tài khoản thanh toán [VARCHAR2(100)]',
    `CUSTOMER_TYPE`          STRING         COMMENT 'Loại khách hàng [VARCHAR2(100)]',
    `SEC_RECID`              STRING         COMMENT 'Mã định danh [VARCHAR2(100)]',
    `AMOUNT_FCY`             DECIMAL(25,5)  COMMENT 'Dư nợ nguyên tệ [NUMBER(25,5)]',
    `AMOUNT_LCY`             DECIMAL(25,5)  COMMENT 'Dư nợ quy đổi [NUMBER(25,5)]',
    `BOOKING_DATE`           DATE           COMMENT 'Ngay but toan ghi nhan vao he thong [DATE]',
    `STMT_CURRENCY`          STRING         COMMENT 'Loai tien but toan [VARCHAR2(100)]',
    `OUR_REFERENCE`          STRING         COMMENT 'Ma tham chieu [VARCHAR2(100)]',
    `STMT_RECID`             STRING         COMMENT 'Mã giao dịch, Unique ID [VARCHAR2(100)]',
    `TRANSACTION_CODE`       STRING         COMMENT 'Mã giao dịch [VARCHAR2(100)]',
    `STMT_VALUE_DATE`        DATE           COMMENT 'Ngay Hieu luc but toan [DATE]',
    `PDHMV_PAYMENT_DTE_DUE`  DATE           COMMENT 'Hạn thanh toán lịch sử quá hạn [DATE]',
    `PDHMV_PAY_AMT_OUTS`     DECIMAL(25,5)  COMMENT 'Số tiền quá hạn còn lại chưa thanh toán [NUMBER(25,5)]',
    `ETL_DATE`               DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'sk_lich_tra_no | SNAPSHOT (Silver Temp 1 - Technical Schedule Staging) | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.exg_rate (
    `SNPST_DT`       DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `SRC_STM_CODE`   STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(32)]',
    `FRST_CCY_CODE`  STRING         COMMENT 'Mã loại tiền tệ gốc [VARCHAR2(20)]',
    `SCD_CCY_CODE`   STRING         COMMENT 'Mã loại tiền tệ tính tỷ giá [VARCHAR2(20)]',
    `MID_RATE`       DECIMAL(25,7)  COMMENT 'Tỷ giá mid [NUMBER(25,7)]',
    `ETL_DATE`       DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Exchange Rate | SNAPSHOT | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.cust_info_daily (
    `COL_REF`                  STRING         COMMENT 'Cột Tham chiếu [VARCHAR2(100)]',
    `FUNCTION_CODE`            STRING         COMMENT 'Mã chức năng [VARCHAR2(100)]',
    `UDF_VALUE`                STRING         COMMENT 'Giá trị UDF [VARCHAR2(100)]',
    `UDF_MAP_CONTRACT_REF_NO`  STRING         COMMENT 'Mã HĐ tham chiếu [VARCHAR2(100)]',
    `FIELD_NAME`               STRING         COMMENT 'Tên trường [VARCHAR2(255)]',
    `FIELD_VAL`                STRING         COMMENT 'Giá trị tương ứng với từng trường [VARCHAR2(100)]',
    `FCC_BOOKING_DATE`         DATE           COMMENT 'Ngày ghi nhận [DATE]',
    `FCC_CONTRACT_REF_NO`      STRING         COMMENT 'Mã Hợp đồng [VARCHAR2(100)]',
    `VERSION_NO`               DECIMAL(10,0)  COMMENT 'Version của bản ghi [NUMBER(10,0)]',
    `CAN_BO_DE_XUAT_GN`        STRING         COMMENT 'Cán bộ đề xuất giải ngân [VARCHAR2(100)]',
    `CAR_APPLICATION_CODE`     STRING         COMMENT 'Mã hồ sơ đăng kí vay vốn [VARCHAR2(100)]',
    `LOS_TD_CONTRACT_REF_NO`   STRING         COMMENT 'Mã hợp đồng giải ngân [VARCHAR2(100)]',
    `LOS_CONTRACT_CODE`        STRING         COMMENT 'mã hợp đồng vay [VARCHAR2(100)]',
    `MDVAY_NKT`                STRING         COMMENT 'Mục đích vay theo ngành kinh tế [VARCHAR2(100)]',
    `MDVAY_SP`                 STRING         COMMENT 'Mục đích vay theo sản phẩm [VARCHAR2(100)]',
    `LOS_TD_MOV_DATE`          DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `TT_PP_DE_XUAT_GN`         STRING         COMMENT 'Người đề xuất giải ngân [VARCHAR2(100)]',
    `UDFH_CONTRACT_REF_NO`     STRING         COMMENT 'Mã hợp đồng [VARCHAR2(100)]',
    `CT_KHUYEN_MAI_CHO_VAY`    STRING         COMMENT 'Mã chương trình KM cho vay [VARCHAR2(100)]',
    `CTKM2`                    STRING         COMMENT 'Mã CTKM2 [VARCHAR2(100)]',
    `UDFH_MOV_DATE`            DATE           COMMENT 'Ngày phát sinh [DATE]',
    `CO_CAU_NO`                STRING         COMMENT 'Cơ cấu nợ [VARCHAR2(100)]',
    `RTH_CONTRACT_REF_NO`      STRING         COMMENT 'Mã Hợp đồng [VARCHAR2(100)]',
    `NGAY_HET_COVID19`         DATE           COMMENT 'Ngày hết covid/ Ngày hết hạn cơ cấu [DATE]',
    `FAC_ID`                   STRING         COMMENT 'Key của bản ghi [VARCHAR2(100)]',
    `PRODUCT_ID`               STRING         COMMENT 'Mã sản phẩm [VARCHAR2(100)]',
    `AMND_STATE`               STRING         COMMENT 'Trạng thái Hợp đồng [VARCHAR2(100)]',
    `LOS_DSBR_BOOKING_DATE`    DATE           COMMENT 'Ngày ghi nhận [DATE]',
    `EXT_REF_NO_1`             STRING         COMMENT 'Số tham chiếu bên ngoài [VARCHAR2(100)]',
    `FACILITY_ID`              STRING         COMMENT 'Mã định danh hạn mức tín dụng [VARCHAR2(100)]',
    `STATUS`                   STRING         COMMENT 'Trạng thái tín dụng [VARCHAR2(100)]',
    `PROD_ID`                  STRING         COMMENT 'Key của bản ghi [VARCHAR2(100)]',
    `PRODUCT_CODE`             STRING         COMMENT 'Mã sản phẩm [VARCHAR2(100)]',
    `PRODUCT_NAME`             STRING         COMMENT 'Tên sản phẩm [VARCHAR2(255)]',
    `ACCOUNT`                  STRING         COMMENT 'Trường ACCOUNT của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `ACCOUNT_ID`               STRING         COMMENT 'Trường ACCOUNT_ID của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `ACCOUNT_NUM`              STRING         COMMENT 'Trường ACCOUNT_NUM của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `ACCOUNT_NUMBER`           STRING         COMMENT 'Số tài khoản liên quan [VARCHAR2(100)]',
    `ACCOUNTING_DATE`          DATE           COMMENT 'Ngày hạch toán [DATE]',
    `ACCT_ID`                  STRING         COMMENT 'Maã định danh tài khoản [VARCHAR2(100)]',
    `AMOUNT_FCY`               DECIMAL(25,5)  COMMENT 'Dư nợ nguyên tệ [NUMBER(25,5)]',
    `AMOUNT_LCY`               DECIMAL(25,5)  COMMENT 'Dư nợ quy đổi [NUMBER(25,5)]',
    `BALANCE_TYPE`             STRING         COMMENT 'Loại bút toán [VARCHAR2(20)]',
    `BOOKING_DATE`             DATE           COMMENT 'Ngay but toan ghi nhan vao he thong [DATE]',
    `CARD_NUMBER`              STRING         COMMENT 'Số thẻ [VARCHAR2(100)]',
    `CO_CODE`                  STRING         COMMENT 'Trường CO_CODE của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `COMMIT_ACTION`            STRING         COMMENT 'Trường kỹ thuật đánh dấu bản ghi IUD [VARCHAR2(100)]',
    `COMMIT_TS`                TIMESTAMP      COMMENT 'Thời điểm ghi nhận commit giao dịch trên Core T24 [TIMESTAMP]',
    `COMPANY_CODE`             STRING         COMMENT 'Mã chi nhánh hạch toán [VARCHAR2(100)]',
    `CONSOL_KEY`               STRING         COMMENT 'Consol key của bút toán STMT [VARCHAR2(100)]',
    `CONTRACT_BAL_ID`          STRING         COMMENT 'Trường CONTRACT_BAL_ID của bảng nguồn SMY.STMT_DAILY [VARCHAR2(40)]',
    `CRF_PROD_CAT`             STRING         COMMENT 'Mã Category phân loại bút toán [VARCHAR2(100)]',
    `CRF_TYPE`                 STRING         COMMENT 'Cờ đánh dấu ghi nợ/ghi có [VARCHAR2(100)]',
    `CURR_NO`                  DECIMAL(10,0)  COMMENT 'Trường kỹ thuật, đánh dấu version thay đổi bút toán [NUMBER(10,0)]',
    `CURRENCY`                 STRING         COMMENT 'Loai tien but toan [VARCHAR2(100)]',
    `CUSTOMER_ID`              STRING         COMMENT 'Mã khách hàng ứng với Account_number [VARCHAR2(100)]',
    `CYCLE_FORWARD`            DATE           COMMENT 'Cờ kết chuyển chu kỳ hạch toán (Cycle Forward) [DATE]',
    `DATE_TIME`                DATE           COMMENT 'Trường kỹ thuật, ghi nhận thời gian sửa đổi [DATE]',
    `DEPARTMENT_CODE`          STRING         COMMENT 'Mã đơn vị hạch toán [VARCHAR2(100)]',
    `DRAWN_ACCOUNT`            STRING         COMMENT 'Tài khoản ghi nhận số tiền rút [VARCHAR2(100)]',
    `EXCHANGE_RATE`            DECIMAL(13,7)  COMMENT 'Tỷ giá quy đổi [NUMBER(13,7)]',
    `INTERNAL_CATEGORY`        STRING         COMMENT 'Mã Category nội bộ [VARCHAR2(100)]',
    `LOCAL_REF`                STRING         COMMENT 'Trường multivalue - đa nghĩa của T24 [VARCHAR2(100)]',
    `ETL_DATE`                 DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'CUST_INFO_DAILY | SNAPSHOT (Silver Temp 1 - Daily Customer & Contract Info) | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_rate_hist (
    `AR_ID`                        STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `AR_CODE`                      STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `INT_RATE_VARIABLITY_TP_CODE`  STRING         COMMENT 'Loại lãi suất : Fix , float [VARCHAR2(20)]',
    `INT_RATE_EFF_DT`              DATE           COMMENT 'Ngày hiệu lực lãi suất [DATE]',
    `EFF_RATE_PCT`                 DECIMAL(25,7)  COMMENT 'Giá trị lãi suất [NUMBER(25,7)]',
    `SPRD_RATE_PCT`                DECIMAL(25,7)  COMMENT 'Biên độ lãi suất [NUMBER(25,7)]',
    `PNY_RATE`                     DECIMAL(25,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(25,7)]',
    `ODUE_INT_RATE`                DECIMAL(25,7)  COMMENT 'Lãi suất cho quá hạn [NUMBER(25,7)]',
    `MRGN_RATE`                    DECIMAL(25,7)  COMMENT 'Biên độ thay đổi lãi suất [NUMBER(25,7)]',
    `SYS_EFF_DT`                   DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`                   DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`                   DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`                     DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Arrangement Rate History | SCD TYPE 2 | Silver Temp 1 (Tech)'
TBLPROPERTIES ('format-version' = '2');

-- ==================== SILVER TEMP 2 ====================

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.cst (
    `CST_ID`            STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`          STRING         COMMENT 'Mã CIF [VARCHAR2(20)]',
    `CST_GRP_CODE`      STRING         COMMENT 'mã Khối quản lý khách hàng [VARCHAR2(20)]',
    `FRST_OU_CODE`      STRING         COMMENT 'Chi nhánh mở [VARCHAR2(20)]',
    `OU_CODE`           STRING         COMMENT 'Mã chi nhánh mở CIF [VARCHAR2(20)]',
    `MAKER_OFCR_CODE`   STRING         COMMENT 'Mã nhân viên hạch toán [VARCHAR2(20)]',
    `CHKER_OFCR_CODE`   STRING         COMMENT 'Mã nhân viên hạch toán thứ 2 [VARCHAR2(20)]',
    `REFR_CODE`         STRING         COMMENT 'Mã người tham chiếu/giới thiệu [VARCHAR2(40)]',
    `SCTR_CODE`         STRING         COMMENT 'Mã phân loại hình khách hàng [VARCHAR2(40)]',
    `SHRT_NM`           STRING         COMMENT 'Tên viết tắt khách hàng [VARCHAR2(255)]',
    `CST_NM`            STRING         COMMENT 'Tên khách hàng đầy đủ [VARCHAR2(255)]',
    `OPN_DT`            DATE           COMMENT 'Ngày khách hàng liên hệ/mở CIF [DATE]',
    `EMPE_CODE`         STRING         COMMENT 'Mã nhân viên quản lý / giới thiệu [VARCHAR2(20)]',
    `STR_ADDR`          STRING         COMMENT 'Địa chỉ đường phố gốc trên CIF [VARCHAR2(100)]',
    `TRGT_CODE`         STRING         COMMENT 'Mã phân khúc khách hàng mục tiêu [VARCHAR2(20)]',
    `SRC_DT_TM`         DATE           COMMENT 'Thời gian cập nhật bản ghi nguồn [DATE]',
    `CTR_TMPL_CODE`     STRING         COMMENT 'Mã biểu mẫu hợp đồng chuẩn [VARCHAR2(100)]',
    `CRS_SELL_RM_CODE`  STRING         COMMENT 'Mã nhân sự bán chéo sản phẩm [VARCHAR2(100)]',
    `CST_TP_CODE`       STRING         COMMENT 'Loại khách hàng (theo phân khúc Sector) [VARCHAR2(40)]',
    `SYS_EFF_DT`        DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`        DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`        DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`          DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Customer | SCD TYPE 1 | Silver Temp 2 (Business)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.idv_prfl (
    `CST_ID`            STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`          STRING         COMMENT 'Mã CIF [VARCHAR2(20)]',
    `CST_LCS_CODE`      STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(20)]',
    `AML_CHK_F`         STRING         COMMENT 'Liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(20)]',
    `AML_RSLT`          STRING         COMMENT 'Liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(100)]',
    `CST_FNC_ST_CODE`   STRING         COMMENT 'Nhóm nợ khách hàng Core tính [VARCHAR2(20)]',
    `OU_CODE`           STRING         COMMENT 'Mã chi nhánh quản lý khách hàng [VARCHAR2(20)]',
    `CST_ST_CODE`       STRING         COMMENT 'Trạng thái hiện tại của khách hàng [VARCHAR2(20)]',
    `INN_BNKG_F`        STRING         COMMENT 'Dịch vụ Internet banking khách hàng giao tiếp [VARCHAR2(20)]',
    `KYC_CNL_CODE`      STRING         COMMENT 'Kênh thực hiện KYC [VARCHAR2(20)]',
    `VSS_CODE`          STRING         COMMENT 'Mã bảo hiểm xã hội [VARCHAR2(40)]',
    `MBL_BNKG_F`        STRING         COMMENT 'Dịch vụ sử dụng sản phẩm mobile banking [VARCHAR2(20)]',
    `CTY_OF_CTZN_CODE`  STRING         COMMENT 'Quốc tịch [VARCHAR2(40)]',
    `JNT_LBY_F`         STRING         COMMENT 'Nợ liên đới [VARCHAR2(20)]',
    `TAX_IDENTN_NBR`    STRING         COMMENT 'Mã số thuế [VARCHAR2(100)]',
    `VIP_F`             STRING         COMMENT 'Đánh dấu khách hàng ưu tiên [VARCHAR2(20)]',
    `GND`               STRING         COMMENT 'Giới tính [VARCHAR2(20)]',
    `IDY_LV1_CL_CODE`   STRING         COMMENT 'Mã ngành nghê kinh tế cha [VARCHAR2(20)]',
    `IDY_LV2_CL_CODE`   STRING         COMMENT 'Ngành nghề kinh tế [VARCHAR2(20)]',
    `DOB`               DATE           COMMENT 'Ngày sinh khách hàng cá nhân [DATE]',
    `VIP_TP_CODE`       STRING         COMMENT 'Phân hạng khách hàng ưu tiên (VIP) [VARCHAR2(20)]',
    `VIP_EFF_DT`        DATE           COMMENT 'Ngày hiệu lực phân hạng khách hàng VIP [DATE]',
    `BSN_RGST_EFF_DT`   DATE           COMMENT 'Ngày phát hành hóa đơn [DATE]',
    `MB_CR_ST`          STRING         COMMENT 'Trạng thái quan hệ tín dụng MB [VARCHAR2(20)]',
    `SYS_EFF_DT`        DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`        DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`        DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`          DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Individual Profile | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.idv_emp_st (
    `CST_ID`           STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`         STRING         COMMENT 'Mã CIF [VARCHAR2(20)]',
    `IDV_EMP_ST_CODE`  STRING         COMMENT 'Trạng thái khách hàng [VARCHAR2(20)]',
    `ANUL_INCM`        DECIMAL(25,5)  COMMENT 'Thu nhập theo tháng [NUMBER(25,5)]',
    `OCP_CODE`         STRING         COMMENT 'Nghề nghiệp của khách hàng [VARCHAR2(100)]',
    `SYS_EFF_DT`       DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`       DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`       DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Individual Employment Status | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.org_prfl (
    `CST_ID`           STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`         STRING         COMMENT 'Mã CIF [VARCHAR2(20)]',
    `CST_LCS_CODE`     STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(20)]',
    `CST_FNC_ST_CODE`  STRING         COMMENT 'Nhóm nợ khách hàng Core tính [VARCHAR2(20)]',
    `ESTB_DT`          DATE           COMMENT 'Ngày thành lập doanh nghiệp [DATE]',
    `OU_CODE`          STRING         COMMENT 'Mã chi nhánh quản lý khách hàng [VARCHAR2(20)]',
    `CST_ST_CODE`      STRING         COMMENT 'Trạng thái hiện tại của khách hàng [VARCHAR2(20)]',
    `IDY_CL_CODE`      STRING         COMMENT 'Mã ngành nghề đăng ký kinh doanh [VARCHAR2(40)]',
    `INN_BNKG_F`       STRING         COMMENT 'Dịch vụ Internet banking khách hàng giao tiếp [VARCHAR2(20)]',
    `MBL_BNKG_F`       STRING         COMMENT 'Dịch vụ sử dụng sản phẩm mobile banking [VARCHAR2(20)]',
    `JNT_LBY_F`        STRING         COMMENT 'Nợ liên đới [VARCHAR2(20)]',
    `TAX_IDENTN_NBR`   STRING         COMMENT 'Mã số thuế [VARCHAR2(100)]',
    `VIP_F`            STRING         COMMENT 'Đánh dấu khách hàng ưu tiên [VARCHAR2(20)]',
    `IDY_LV1_CL_CODE`  STRING         COMMENT 'Mã ngành nghê kinh tế cha [VARCHAR2(20)]',
    `IDY_LV2_CL_CODE`  STRING         COMMENT 'Ngành nghề kinh tế [VARCHAR2(20)]',
    `BSN_RGST_NBR`     STRING         COMMENT 'Số giấy phép đăng ký kinh doanh [VARCHAR2(40)]',
    `BSN_RGST_EFF_DT`  DATE           COMMENT 'Ngày cấp giấy phép ĐKKD / phát hành hóa đơn [DATE]',
    `VIP_TP_CODE`      STRING         COMMENT 'Phân hạng khách hàng ưu tiên (VIP) [VARCHAR2(20)]',
    `VIP_EFF_DT`       DATE           COMMENT 'Ngày hiệu lực phân hạng khách hàng VIP [DATE]',
    `KYC_CNL_CODE`     STRING         COMMENT 'Kênh thực hiện KYC [VARCHAR2(20)]',
    `GEN_DIR_PLC`      STRING         COMMENT 'Nơi sinh Tổng giám đốc / người đại diện pháp luật [VARCHAR2(100)]',
    `DIR_DOB`          DATE           COMMENT 'Ngày sinh Giám đốc / người đại diện pháp luật [DATE]',
    `CNTCT_PRSN`       STRING         COMMENT 'Họ tên người liên hệ chính KHDN [VARCHAR2(40)]',
    `CNTCT_PRSN_PHN`   STRING         COMMENT 'Số điện thoại người liên hệ chính KHDN [VARCHAR2(100)]',
    `AML_RSLT`         STRING         COMMENT 'Kết quả sàng lọc phòng chống rửa tiền (AML) [VARCHAR2(100)]',
    `AML_CHK_F`        STRING         COMMENT 'Cờ kiểm tra phòng chống rửa tiền (AML) [VARCHAR2(20)]',
    `MB_CR_ST`         STRING         COMMENT 'Trạng thái quan hệ tín dụng MB [VARCHAR2(20)]',
    `SYS_EFF_DT`       DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`       DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`       DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Organization Profile | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.loan_ar (
    `SRC_STM_CODE`         STRING         COMMENT 'Mã hệ thống nguồn dữ liệu [VARCHAR2(40)]',
    `AR_ID`                STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `AR_CODE`              STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `FCC_AR_CODE`          STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(40)]',
    `ORIG_AMT_FCY`         DECIMAL(25,5)  COMMENT 'Giá trị phê duyệt [NUMBER(25,5)]',
    `CHKER_OFCR_CODE`      STRING         COMMENT 'Mã người phê duyệt [VARCHAR2(20)]',
    `PD_CGY_CODE`          STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(20)]',
    `FRST_OU_CODE`         STRING         COMMENT 'Mã chi nhánh quản lý đầu tiên [VARCHAR2(20)]',
    `PPR_CTR_NBR`          STRING         COMMENT 'Mã hồ sơ [VARCHAR2(100)]',
    `CCY_CODE`             STRING         COMMENT 'Loại tiền [VARCHAR2(20)]',
    `CST_CODE`             STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `CST_ID`               STRING         COMMENT 'Mã khách hàng [CHAR(32)]',
    `DSBR_AMT_FCY`         DECIMAL(25,5)  COMMENT 'Số tiền thực tế giải ngân [NUMBER(25,5)]',
    `EXG_RATE_TO_LCL_CCY`  DECIMAL(25,7)  COMMENT 'Tỷ giá quy đổi [NUMBER(25,7)]',
    `FCC_LMT_CODE`         STRING         COMMENT 'Mã hạn mức trên Flexcube [VARCHAR2(20)]',
    `MAT_DT`               DATE           COMMENT 'Ngày đáo hạn hợp đồng [DATE]',
    `MAKER_OFCR_CODE`      STRING         COMMENT 'ID người nhập liệu [VARCHAR2(20)]',
    `LMT_CODE`             STRING         COMMENT 'Mã tham chiếu hạn mức [VARCHAR2(32)]',
    `LMT_ID`               STRING         COMMENT 'Mã tham chiếu hạn mức [CHAR(32)]',
    `TERM_CODE`            STRING         COMMENT 'Kỳ hạn [VARCHAR2(20)]',
    `LOS_CTR_NBR`          STRING         COMMENT 'Số hồ sơ [VARCHAR2(40)]',
    `REFRRER_OFCR_CODE`    STRING         COMMENT 'ID nhân viên giới thiệu [VARCHAR2(20)]',
    `VAL_DT`               DATE           COMMENT 'Ngày hiệu lực đầu tiên của hợp đồng [DATE]',
    `PD_CODE`              STRING         COMMENT 'Mã nhóm sản phẩm [VARCHAR2(20)]',
    `AR_PPS_TP_CODE`       STRING         COMMENT 'Mã mục đích vay [VARCHAR2(40)]',
    `AR_PPS_GRP_CODE`      STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(40)]',
    `EFF_DT`               DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `FCC_VAL_DT`           DATE           COMMENT 'Ngày ghi nhận [DATE]',
    `SYS_EFF_DT`           DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`           DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`           DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`             DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Loan Arrangement | SCD TYPE 2 | Silver Temp 2 (Business)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.loan_ar_prfl (
    `SRC_STM_CODE`           STRING         COMMENT 'Mã hệ thống nguồn dữ liệu [VARCHAR2(40)]',
    `AR_ID`                  STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `AR_CODE`                STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `INT_LQD_AR_CODE`        STRING         COMMENT 'Tài khoản thanh toán lãi [VARCHAR2(40)]',
    `INT_LQD_AR_ID`          STRING         COMMENT 'ID Tài khoản thanh toán lãi [CHAR(32)]',
    `PNP_LQD_AR_CODE`        STRING         COMMENT 'Tài khoản thanh toán gốc [VARCHAR2(40)]',
    `PNP_LQD_AR_ID`          STRING         COMMENT 'ID Tài khoản thanh toán gốc [CHAR(32)]',
    `AR_LCS_TP_CODE`         STRING         COMMENT 'Trạng thái [VARCHAR2(40)]',
    `OU_CODE`                STRING         COMMENT 'Mã chi nhánh quản lý hiện tại [VARCHAR2(32)]',
    `MAND_REPYMT`            STRING         COMMENT 'Giá trị UDF [VARCHAR2(20)]',
    `NBR_OF_DBT_RSTC`        DECIMAL(22,0)  COMMENT 'Giá trị tương ứng với từng trường [NUMBER(22,0)]',
    `SCR_TP`                 STRING         COMMENT 'Giá trị tương ứng với từng trường [VARCHAR2(20)]',
    `CAR_AP_CODE`            STRING         COMMENT 'Mã hồ sơ đăng ký vay vốn [VARCHAR2(40)]',
    `LOS_CTR_CODE`           STRING         COMMENT 'mã hợp đồng vay [VARCHAR2(40)]',
    `LOS_CTR_ID`             STRING         COMMENT 'mã hồ sơ trên LOS [VARCHAR2(20)]',
    `DBT_WVR_F`              STRING         COMMENT 'Đánh dấu cơ cấu miễn giảm [VARCHAR2(20)]',
    `AR_PPS_BY_IDY`          STRING         COMMENT 'Mục đích vay theo ngành kinh tế [VARCHAR2(20)]',
    `AR_PPS_BY_PD`           STRING         COMMENT 'Mục đích vay theo sản phẩm [VARCHAR2(20)]',
    `DSBR_PRPSL_OFCR`        STRING         COMMENT 'Cán bộ đề xuất giải ngân [VARCHAR2(40)]',
    `DSBR_PRPSL_MGR`         STRING         COMMENT 'Người đề xuất giải ngân [VARCHAR2(40)]',
    `MGT_OFCR`               STRING         COMMENT 'Cán bộ quản lý khoản vay [VARCHAR2(40)]',
    `MGT_MGR`                STRING         COMMENT 'Người quản lý khoản vay [VARCHAR2(40)]',
    `APRV_AHR`               STRING         COMMENT 'Cấp phê duyệt giải ngân [VARCHAR2(1000)]',
    `CHKER_OFCR`             STRING         COMMENT 'Mã người phê duyệt [VARCHAR2(40)]',
    `MAKER_OFCR`             STRING         COMMENT 'ID người nhập liệu [VARCHAR2(40)]',
    `REFRRER_OFCR`           STRING         COMMENT 'ID nhân viên giới thiệu [VARCHAR2(40)]',
    `PROM_PRGM`              STRING         COMMENT 'Mã chương trình KM cho vay [VARCHAR2(20)]',
    `PROM_PRGM_2`            STRING         COMMENT 'Mã CTKM2 [VARCHAR2(20)]',
    `DBT_RSTC_TP_CODE`       STRING         COMMENT 'Cơ cấu nợ [VARCHAR2(20)]',
    `COVID19_RSTC_COMPL_DT`  DATE           COMMENT 'Ngày hết covid/ Ngày hết hạn cơ cấu [DATE]',
    `GL_ITM_CODE`            STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(20)]',
    `GL_ITM_ID`              STRING         COMMENT 'ID Mã hạch toán theo SBV [CHAR(32)]',
    `FNC_ST_CODE`            STRING         COMMENT 'Nhóm nợ hợp đồng [VARCHAR2(20)]',
    `BDS_TT11`               STRING         COMMENT 'Phân loại bất động sản theo Thông tư 11 [VARCHAR2(20)]',
    `SYS_EFF_DT`             DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`             DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`             DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`               DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Loan Arrangement Profile | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_x_ip_rltnp (
    `SRC_STM_CODE`     STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(40)]',
    `AR_ID`            STRING         COMMENT 'Unique key hợp đồng trên DWH [CHAR(32)]',
    `AR_CODE`          STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `CST_ID`           STRING         COMMENT 'ID khách hàng trên DWH [CHAR(32)]',
    `CST_CODE`         STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `MAKER_OFCR`       STRING         COMMENT 'ID người nhập liệu [VARCHAR2(40)]',
    `CHKER_OFCR`       STRING         COMMENT 'Mã người phê duyệt [VARCHAR2(40)]',
    `REFRRER_OFCR`     STRING         COMMENT 'ID nhân viên giới thiệu [VARCHAR2(40)]',
    `DSBR_PRPSL_OFCR`  STRING         COMMENT 'Cán bộ đề xuất giải ngân [VARCHAR2(40)]',
    `DSBR_PRPSL_MGR`   STRING         COMMENT 'Người đề xuất giải ngân [VARCHAR2(40)]',
    `MGT_OFCR`         STRING         COMMENT 'Cán bộ quản lý khoản vay [VARCHAR2(40)]',
    `MGT_MGR`          STRING         COMMENT 'Người quản lý khoản vay [VARCHAR2(40)]',
    `APRV_AHR`         STRING         COMMENT 'Cấp phê duyệt giải ngân [VARCHAR2(1000)]',
    `SYS_EFF_DT`       DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`       DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`       DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Arrangement x Involved Party | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_avy_shd_itm (
    `AR_AVY_SHD_ID`    STRING         COMMENT 'ID duy nhất của mã số dòng lịch trên DWH [CHAR(32)]',
    `AR_AVY_SHD_CODE`  STRING         COMMENT 'Mã số dòng lịch trên hệ thống nguồn [VARCHAR2(32)]',
    `AR_AVY_SHD_TP`    STRING         COMMENT 'Phân loại của dòng lịch hợp đồng [VARCHAR2(32)]',
    `AR_ID`            STRING         COMMENT 'ID duy nhất của hợp đồng trên DWH [CHAR(32)]',
    `AR_CODE`          STRING         COMMENT 'Mã của hợp đồng gốc [VARCHAR2(32)]',
    `PBL_AMT_TP`       STRING         COMMENT 'Phân loại tiền cần thanh toán trong kỳ bill tương ứng (PS/PE/LD,..) [VARCHAR2(20)]',
    `PBL_AMT_LCY`      DECIMAL(25,5)  COMMENT 'Số tiền cần thanh toán quy đổi trong kỳ bill tương ứng [NUMBER(25,5)]',
    `PBL_AMT_FCY`      DECIMAL(25,5)  COMMENT 'Số tiền cần thanh toán nguyên tệ trong kỳ bill tương ứng [NUMBER(25,5)]',
    `EXG_RATE`         DECIMAL(25,7)  COMMENT 'Tỷ giá thực hiện [NUMBER(25,7)]',
    `CCY_CODE`         STRING         COMMENT 'Mã loại tiền [VARCHAR2(20)]',
    `EFF_MAT_DT`       DATE           COMMENT 'Ngày hiệu lực của dòng lịch [DATE]',
    `F_LAST_OD_DT`     DECIMAL(1,0)   COMMENT 'Cờ hợp đồng có đang tồn tại kỳ trả nợ quá hạn gần nhất hay không [NUMBER(1,0)]',
    `LAST_OD_DT`       DATE           COMMENT 'Ngày đến hạn của kỳ trả nợ gần nhất đã chuyển sang quá hạn [DATE]',
    `SRC_STM_CODE`     STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(32)]',
    `CST_ID`           STRING         COMMENT 'ID duy nhất của khách hàng liên quan trên DWH [CHAR(32)]',
    `CST_CODE`         STRING         COMMENT 'Mã số khách hàng [VARCHAR2(32)]',
    `SYS_EFF_DT`       DATE           COMMENT 'Ngày bản ghi lần đầu tiên vào hệ thống [DATE]',
    `SYS_EXP_DT`       DATE           COMMENT 'Ngày hết hạn của bản ghi [DATE]',
    `SYS_UDT_DT`       DATE           COMMENT 'Ngày update dữ liệu gần nhất [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Arrangement Activity Schedule I | SCD TYPE 2 | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.saoke_giaingan (
    `NARRATIVE`           STRING         COMMENT 'Mô tả bút toán [VARCHAR2(255)]',
    `ORIG_AMOUNT_LCY`     DECIMAL(25,5)  COMMENT 'Giá trị hạch toán ban đầu quy đổi [NUMBER(25,5)]',
    `ORIGINAL_ACCT`       STRING         COMMENT 'Số tài khoản hạch toán ban đầu [VARCHAR2(100)]',
    `ORIGINAL_AMOUNT`     DECIMAL(25,5)  COMMENT 'Giá trị hạch toán ban đầu nguyên tệ [NUMBER(25,5)]',
    `ORIGINAL_CCY`        STRING         COMMENT 'Loại tiền giao dịch ban đầu [VARCHAR2(100)]',
    `ORIGINAL_EXCH_RATE`  DECIMAL(13,7)  COMMENT 'Tỷ giá quy đổi cho loại tiền ban đầu [NUMBER(13,7)]',
    `OUR_REFERENCE`       STRING         COMMENT 'Ma tham chieu [VARCHAR2(100)]',
    `OUTSTANDING_BAL`     DECIMAL(25,5)  COMMENT 'Dư nợ tín dụng của hợp đồng ( OUR_REFERENCE) [NUMBER(25,5)]',
    `OVERRIDE`            STRING         COMMENT 'Cờ cảnh báo [VARCHAR2(100)]',
    `PROCESS_FORWARD`     STRING         COMMENT 'Cờ xử lý chuyển tiếp bút toán hạch toán (Process Forward) [VARCHAR2(100)]',
    `PROCESSING_DATE`     DATE           COMMENT 'Trường PROCESSING_DATE của bảng nguồn SMY.STMT_DAILY [DATE]',
    `PRODUCT_CATEGORY`    STRING         COMMENT 'Loại sản phẩm hạch toán [VARCHAR2(100)]',
    `STMT_RECID`          STRING         COMMENT 'Mã giao dịch, Unique ID [VARCHAR2(100)]',
    `RECORD_STATUS`       STRING         COMMENT 'Trạng Thái bản ghi [VARCHAR2(100)]',
    `REPAYMENT_AMT`       DECIMAL(25,5)  COMMENT 'Số tiền thu nợ [NUMBER(25,5)]',
    `REPAYMENT_DATE`      DATE           COMMENT 'Ngày thu [DATE]',
    `REPAYMENT_TYPE`      STRING         COMMENT 'Loại thu nợ [VARCHAR2(100)]',
    `STMT_ENTRY_ID`       STRING         COMMENT 'Trường STMT_ENTRY_ID của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `STMT_NO`             STRING         COMMENT 'Trường STMT_NO của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `SUSPENSE_CATEGORY`   STRING         COMMENT 'Mã Category phân loại bút toán bị treo [VARCHAR2(100)]',
    `SUSPNSE_VALUE_DATE`  DATE           COMMENT 'Ngày bút toán treo [DATE]',
    `SYSTEM_ID`           STRING         COMMENT 'Mã phân hệ [VARCHAR2(100)]',
    `THEIR_REFERENCE`     STRING         COMMENT 'Trường THEIR_REFERENCE của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `TRANS_REFERENCE`     STRING         COMMENT 'Trường TRANS_REFERENCE của bảng nguồn SMY.STMT_DAILY [VARCHAR2(100)]',
    `TRANSACTION_CODE`    STRING         COMMENT 'Mã giao dịch [VARCHAR2(100)]',
    `STMT_TXN_DATE`       DATE           COMMENT 'Trường TXN_DATE của bảng nguồn SMY.STMT_DAILY [DATE]',
    `VALUE_DATE`          DATE           COMMENT 'Ngay Hieu luc but toan [DATE]',
    `ACC_FCC`             STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(100)]',
    `AMOUNT_CUR`          DECIMAL(25,5)  COMMENT 'Số tiền dự thu [NUMBER(25,5)]',
    `AMOUNT_LCY`          DECIMAL(25,5)  COMMENT 'Dư Nợ quy đổi [NUMBER(25,5)]',
    `APP_CODE`            STRING         COMMENT 'Mã phân hệ: LD, MD, AC, PD [VARCHAR2(100)]',
    `APP_ID`              STRING         COMMENT 'Mã hợp đồng [VARCHAR2(100)]',
    `ASSET_CLASS`         STRING         COMMENT 'Nhóm nợ khách hàng Core tính [VARCHAR2(100)]',
    `ASSET_TYPE`          STRING         COMMENT 'Loại dư nợ, hạch toán [VARCHAR2(100)]',
    `CATEG_CODE`          STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(100)]',
    `CO_CODE`             STRING         COMMENT 'Mã chi nhánh hạch toán [VARCHAR2(100)]',
    `CURR`                STRING         COMMENT 'Loại tiền [VARCHAR2(100)]',
    `CUS_ID`              STRING         COMMENT 'Mã khách hàng [VARCHAR2(100)]',
    `DATE`                DATE           COMMENT 'Ngày giao dịch YYYYMMDD [DATE]',
    `LOC_TERM`            STRING         COMMENT 'Trường LOC_TERM của bảng nguồn SOURCE.SAOKE_CRB [VARCHAR2(100)]',
    `MAT_DATE`            DATE           COMMENT 'Ngày đáo hạn hợp đồng [DATE]',
    `SBV_CODE`            STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(100)]',
    `SUB_PRO`             STRING         COMMENT 'Mã sản phẩm con [VARCHAR2(100)]',
    `TXN_DATE`            DATE           COMMENT 'Ngày giao dịch [DATE]',
    `VAL_DATE`            DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `MVMT_SBV_CODE`       STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(100)]',
    `TRANS_REF`           STRING         COMMENT 'Mã tham chiếu giao dịch [VARCHAR2(100)]',
    `MVMT_TXN_DATE`       DATE           COMMENT 'Ngày thực hiện giao dịch [DATE]',
    `COMPANY_NAME`        STRING         COMMENT 'Tên chi nhánh [VARCHAR2(255)]',
    `COMP_RECID`          STRING         COMMENT 'Mã chi nhánh [VARCHAR2(100)]',
    `ACCOUNT_OFFICER`     STRING         COMMENT 'Mã nhân viên hạch toán [VARCHAR2(100)]',
    `ACTIVE_STATUS`       STRING         COMMENT 'Trạng thái bản ghi [VARCHAR2(100)]',
    `AML_CHECK`           STRING         COMMENT 'Liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(100)]',
    `AML_RESULT`          STRING         COMMENT 'Liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(100)]',
    `BDATE_LEGAL`         DATE           COMMENT 'Ngày sinh của người đại diện theo pháp luật [DATE]',
    `BDAY_DIRECTOR`       DATE           COMMENT 'Ngày sinh giám đốc công ty [DATE]',
    `BIRTH_INCORP_DATE`   DATE           COMMENT 'Ngày thành lập doanh nghiệp [DATE]',
    `CUS_CO_CODE`         STRING         COMMENT 'Mã chi nhánh quản lý khách hàng [VARCHAR2(100)]',
    `COMPANY_BOOK`        STRING         COMMENT 'Mã chi nhánh mở CIF [VARCHAR2(100)]',
    `CONTACT_DATE`        DATE           COMMENT 'Ngày khách hàng liên hệ/mở CIF [DATE]',
    `CONTACT_PERSON`      STRING         COMMENT 'Họ tên người liên hệ của khách hàng doanh nghiệp [VARCHAR2(100)]',
    `COUNTRY`             STRING         COMMENT 'Tên quốc gia nơi cư trú / đặt trụ sở [VARCHAR2(100)]',
    `CU_EFF_DATE`         DATE           COMMENT 'Ngày hiệu lực phân hạng khách hàng VIP [DATE]',
    `CUS_IND_PARENT`      STRING         COMMENT 'Mã ngành nghê kinh tế cha [VARCHAR2(100)]',
    `CUSTOMER_STATUS`     STRING         COMMENT 'Trạng thái hiện tại của khách hàng [VARCHAR2(100)]',
    `DATE_TIME`           DATE           COMMENT 'Ngày giờ bản ghi nhập liệu [DATE]',
    `EMAIL_ADDRESS`       STRING         COMMENT 'Địa chỉ emai [VARCHAR2(255)]',
    `EMPLOYMENT_STATUS`   STRING         COMMENT 'Mã tình trạng việc làm của khách hàng cá nhân [VARCHAR2(100)]',
    `ESTAB_LIC_CODE`      STRING         COMMENT 'Số giấy phép thành lập / đăng ký kinh doanh [VARCHAR2(100)]',
    `FFB_TYPE`            STRING         COMMENT 'Phân hạng khách hàng ưu tiên (VIP Type) [VARCHAR2(100)]',
    `GEN_DIR_PLC`         STRING         COMMENT 'Nơi sinh / quốc tịch của Tổng giám đốc / người đại diện [VARCHAR2(100)]',
    `HOME_NUMBER`         STRING         COMMENT 'Số điện thoại nhà tiêng [VARCHAR2(100)]',
    `INDUSTRY`            STRING         COMMENT 'Mã ngành nghề đăng ký kinh doanh [VARCHAR2(100)]',
    `ETL_DATE`            DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Saoke_GIAINGAN | SNAPSHOT (Silver Temp 2 - Business Disbursement Statement) | Silver Temp 2 (Business)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.pst_entr (
    `PST_ENTR_ID`       STRING         COMMENT 'ID duy nhất của đối tượng trên DWH [CHAR(32)]',
    `SRC_STM_CODE`      STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(40)]',
    `PST_ENTR_NBR`      STRING         COMMENT 'Mã bút toán hạch toán [VARCHAR2(32)]',
    `TXN_ID`            STRING         COMMENT 'ID của giao dịch của bút toán trên DWH [CHAR(32)]',
    `TXN_NBR`           STRING         COMMENT 'Số giao dịch [VARCHAR2(20)]',
    `ACG_CR_DB_F`       STRING         COMMENT 'Cờ đánh dấu ghi nợ/ghi có [VARCHAR2(20)]',
    `TXN_CODE`          STRING         COMMENT 'Phân loại mã giao dịch [VARCHAR2(20)]',
    `PST_DT`            DATE           COMMENT 'Ngày phát sinh bút toán [DATE]',
    `PST_ENTR_AMT_FCY`  DECIMAL(25,5)  COMMENT 'Số tiền của bút toán nguyên tệ [NUMBER(25,5)]',
    `PST_ENTR_AMT_LCY`  DECIMAL(25,5)  COMMENT 'Số tiền của bút toán quy đổi [NUMBER(25,5)]',
    `CCY_CODE`          STRING         COMMENT 'Mã loại tiền [VARCHAR2(20)]',
    `VAL_DT`            DATE           COMMENT 'Ngày hiệu lực của bút toán [DATE]',
    `EXG_RATE`          DECIMAL(25,7)  COMMENT 'Tỷ giá thực hiện [NUMBER(25,7)]',
    `OU_CODE`           STRING         COMMENT 'Chi nhánh hạch toán [VARCHAR2(32)]',
    `AC_NBR`            STRING         COMMENT 'Số tài khoản liên quan [VARCHAR2(40)]',
    `AR_CODE`           STRING         COMMENT 'Số hợp đồng liên quan [VARCHAR2(40)]',
    `AR_ID`             STRING         COMMENT 'ID hợp đồng duy nhất liên quan trên DWH [CHAR(32)]',
    `CST_ID`            STRING         COMMENT 'ID duy nhất của khách hàng liên quan trên DWH [CHAR(32)]',
    `CST_NBR`           STRING         COMMENT 'Mã số khách hàng [VARCHAR2(20)]',
    `ACG_PD_CGY`        STRING         COMMENT 'Loại sản phẩm hạch toán [VARCHAR2(20)]',
    `PST_ENTR_DSC`      STRING         COMMENT 'Mô tả bút toán [VARCHAR2(4000)]',
    `CONSOL_KEY`        STRING         COMMENT 'Consol key của bút toán STMT [VARCHAR2(1000)]',
    `MOD_CODE`          STRING         COMMENT 'Mã phân hệ giao dịch [VARCHAR2(20)]',
    `PST_ENTR_CMPT`     STRING         COMMENT 'Phân loại thành phần giao dịch bút toán [VARCHAR2(20)]',
    `ACG_DT`            DATE           COMMENT 'Ngày hạch toán của bút toán [DATE]',
    `AC_ID`             STRING         COMMENT 'ID tài khoản hạch toán trên DWH [CHAR(32)]',
    `BAL_TP`            STRING         COMMENT 'Loại bút toán [VARCHAR2(20)]',
    `CARD_NBR`          STRING         COMMENT 'Số thẻ [VARCHAR2(40)]',
    `CMMT_ACTN`         STRING         COMMENT 'Trường kỹ thuật đánh dấu bản ghi IUD [VARCHAR2(20)]',
    `CMMT_TMS`          TIMESTAMP      COMMENT 'Thời gian ghi nhận thay đổi bản ghi trên hệ thống [TIMESTAMP]',
    `CGY_PD_CODE`       STRING         COMMENT 'Mã Category phân loại bút toán [VARCHAR2(20)]',
    `CRN_NBR`           DECIMAL(22,0)  COMMENT 'Trường kỹ thuật, đánh dấu version thay đổi bút toán [NUMBER(22,0)]',
    `CYC_FWD`           DATE           COMMENT 'Chu kỳ [DATE]',
    `DT_TM`             DATE           COMMENT 'Trường kỹ thuật, ghi nhận thời gian sửa đổi [DATE]',
    `DEPT_CODE`         STRING         COMMENT 'Mã đơn vị hạch toán [VARCHAR2(20)]',
    `DRN_AC`            STRING         COMMENT 'Tài khoản ghi nhận số tiền rút [VARCHAR2(20)]',
    `INR_CGY`           STRING         COMMENT 'Mã Category nội bộ [VARCHAR2(20)]',
    `LCL_REFR`          STRING         COMMENT 'Trường multivalue - đa nghĩa của T24 [VARCHAR2(20)]',
    `ORIG_AMT_LCY`      DECIMAL(25,5)  COMMENT 'Giá trị hạch toán ban đầu quy đổi [NUMBER(25,5)]',
    `ORIG_AC`           STRING         COMMENT 'Số tài khoản hạch toán ban đầu [VARCHAR2(20)]',
    `ORIG_AMT`          DECIMAL(25,5)  COMMENT 'Giá trị hạch toán ban đầu nguyên tệ [NUMBER(25,5)]',
    `ORIG_CCY`          STRING         COMMENT 'Loại tiền giao dịch ban đầu [VARCHAR2(20)]',
    `ORIG_EXG_RATE`     DECIMAL(25,7)  COMMENT 'Tỷ giá quy đổi cho loại tiền ban đầu [NUMBER(25,7)]',
    `OTSND_BAL`         DECIMAL(25,5)  COMMENT 'Dư nợ tín dụng của hợp đồng ( OUR_REFERENCE) [NUMBER(25,5)]',
    `OVRD`              STRING         COMMENT 'Ghi đè [VARCHAR2(20)]',
    `PCS_FWD`           STRING         COMMENT 'Tiến trình [VARCHAR2(20)]',
    `RCRD_ST`           STRING         COMMENT 'Trạng Thái bản ghi [VARCHAR2(20)]',
    `REPYMT_AMT`        DECIMAL(25,5)  COMMENT 'Số tiền thu nợ [NUMBER(25,5)]',
    `REPYMT_DT`         DATE           COMMENT 'Ngày thu [DATE]',
    `REPYMT_TP`         STRING         COMMENT 'Loại thu nợ [VARCHAR2(20)]',
    `SUSP_CGY`          STRING         COMMENT 'Mã Category phân loại bút toán bị treo [VARCHAR2(20)]',
    `SUSP_VAL_DT`       DATE           COMMENT 'Ngày bút toán treo [DATE]',
    `ETL_DATE`          DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Posting Entry | TXN | Silver Temp 2 (Business)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.saoke_tindung (
    `INTERNET_BANKING_SERVICE`  STRING         COMMENT 'Dịch vụ Internet banking khách hàng giao tiếp [VARCHAR2(100)]',
    `KHOI`                      STRING         COMMENT 'mã Khối quản lý khách hàng [VARCHAR2(100)]',
    `KYC_CHANNEL`               STRING         COMMENT 'Kênh thực hiện KYC [VARCHAR2(100)]',
    `MA_BHXH`                   STRING         COMMENT 'Mã bảo hiểm xã hội [VARCHAR2(100)]',
    `MAU_HD`                    STRING         COMMENT 'Mã biểu mẫu hợp đồng chuẩn áp dụng cho khách hàng [VARCHAR2(100)]',
    `MB_CR_STT`                 STRING         COMMENT 'Trạng thái quan hệ tín dụng của khách hàng tại ngân hàng [VARCHAR2(100)]',
    `MB_INDUSTRY`               STRING         COMMENT 'Ngành nghề kinh tế [VARCHAR2(100)]',
    `MB_RM_BANCHEO`             STRING         COMMENT 'Mã nhân sự bán chéo sản phẩm [VARCHAR2(100)]',
    `MOBILE_BANKING_SERVICE`    STRING         COMMENT 'Dịch vụ sử dụng sản phẩm mobile banking [VARCHAR2(100)]',
    `MOBILE_NUMBER`             STRING         COMMENT 'Số điện thoại di động [VARCHAR2(100)]',
    `NAT_ID_EXP_DATE`           DATE           COMMENT 'Ngày hêt hạn CC [DATE]',
    `NAT_ID_ISS_DATE`           DATE           COMMENT 'Ngày cấp Căn cước [DATE]',
    `NAT_ID_ISS_PLC`            STRING         COMMENT 'Nơi cấp Căn cước [VARCHAR2(100)]',
    `NAT_ID_TYPE`               STRING         COMMENT 'Loại căn cước [VARCHAR2(100)]',
    `NATIONAL_ID`               STRING         COMMENT 'Số giấy tờ định danh quốc gia (CCCD/CMND) [VARCHAR2(100)]',
    `NATIONALITY`               STRING         COMMENT 'Quốc tịch [VARCHAR2(100)]',
    `NET_MONTHLY_IN`            DECIMAL(25,5)  COMMENT 'Thu nhập theo tháng [NUMBER(25,5)]',
    `NO_LIEN_DOI`               STRING         COMMENT 'Nợ liên đới [VARCHAR2(100)]',
    `OCCUPATION`                STRING         COMMENT 'Nghề nghiệp của khách hàng [VARCHAR2(100)]',
    `OPEN_COMPANY`              STRING         COMMENT 'Chi nhánh mở [VARCHAR2(100)]',
    `PHONE_CONT_PER`            STRING         COMMENT 'Số điện thoại của người liên hệ chính - KH tổ chức [VARCHAR2(100)]',
    `CUS_RECID`                 STRING         COMMENT 'Mã CIF [VARCHAR2(100)]',
    `REFERRED_BY`               STRING         COMMENT 'Mã người tham chiếu/giới thiệu [VARCHAR2(100)]',
    `RESID_PROVINCE`            STRING         COMMENT 'Tỉnh/thành phố nơi cư trú [VARCHAR2(100)]',
    `RESIDENCE`                 STRING         COMMENT 'Quốc gia cư trú [VARCHAR2(100)]',
    `SECOND_OFFICER`            STRING         COMMENT 'Mã nhân viên hạch toán thứ 2 [VARCHAR2(100)]',
    `SECTOR`                    STRING         COMMENT 'Mã phân loại hình khách hàng [VARCHAR2(100)]',
    `SHORT_NAME`                STRING         COMMENT 'Tên viết tắt khách hàng [VARCHAR2(255)]',
    `STREET`                    STRING         COMMENT 'Tên đường theo địa chỉ [VARCHAR2(255)]',
    `TARGET`                    STRING         COMMENT 'Mã phân khúc đối tượng khách hàng mục tiêu (Target Code) [VARCHAR2(100)]',
    `TAX_SERIAL`                STRING         COMMENT 'Mã số thuế [VARCHAR2(100)]',
    `TXN_DATE`                  DATE           COMMENT 'Ngày giao dịch / ngày cập nhật dữ liệu khách hàng [DATE]',
    `VAT_INV_DATE`              DATE           COMMENT 'Ngày phát hành hóa đơn [DATE]',
    `VAT_INV_SERIAL`            STRING         COMMENT 'Số seri hóa đơn [VARCHAR2(100)]',
    `VIP_CUSTOMER`              STRING         COMMENT 'Đánh dấu khách hàng ưu tiên [VARCHAR2(100)]',
    `VN_FULL_NAME`              STRING         COMMENT 'Tên khách hàng đầy đủ [VARCHAR2(255)]',
    `VN_GENDER`                 STRING         COMMENT 'Giới tính [VARCHAR2(100)]',
    `VN_STREET`                 STRING         COMMENT 'Tên đường theo địa chỉ [VARCHAR2(255)]',
    `VN_TOWN`                   STRING         COMMENT 'Tên thành phố theo địa chỉ [VARCHAR2(255)]',
    `NAME`                      STRING         COMMENT 'Tên nhân viên hạch toán [VARCHAR2(255)]',
    `DAO_RECID`                 STRING         COMMENT 'Mã nhân viên hạch toán thứ 2 [VARCHAR2(100)]',
    `ACC_FCC`                   STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(100)]',
    `AMOUNT`                    DECIMAL(25,5)  COMMENT 'Dự nợ hợp đồng [NUMBER(25,5)]',
    `APPROVE_AMOUNT`            DECIMAL(25,5)  COMMENT 'Giá trị phê duyệt [NUMBER(25,5)]',
    `AUTHORISER`                STRING         COMMENT 'Mã người phê duyệt [VARCHAR2(100)]',
    `CATEGORY`                  STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(100)]',
    `CO_CODE`                   STRING         COMMENT 'Mã chi nhánh quản lý hiện tại [VARCHAR2(100)]',
    `COMMIT_ACTION`             STRING         COMMENT 'Trường COMMIT_ACTION của bảng nguồn T24CORE.LD_LOANS_AND_DEPOSITS [VARCHAR2(100)]',
    `CRA_LD`                    STRING         COMMENT 'Số hồ sơ giải ngân [VARCHAR2(100)]',
    `CURR_NO`                   DECIMAL(10,0)  COMMENT 'Version bản ghi hiện tại [NUMBER(10,0)]',
    `CURRENCY`                  STRING         COMMENT 'Loại tiền [VARCHAR2(100)]',
    `CUSTOMER_ID`               STRING         COMMENT 'Mã khách hàng [VARCHAR2(100)]',
    `DATE_TIME`                 DATE           COMMENT 'Ngày nhập liệu Core [DATE]',
    `DRAWDOWN_NET_AMT`          DECIMAL(25,5)  COMMENT 'Số tiền thực tế giải ngân [NUMBER(25,5)]',
    `EXCG_RATE`                 DECIMAL(13,7)  COMMENT 'Tỷ giá quy đổi [NUMBER(13,7)]',
    `FCC_LIMIT`                 STRING         COMMENT 'Mã hạn mức trên Flexcube [VARCHAR2(100)]',
    `FIN_MAT_DATE`              DATE           COMMENT 'Ngày đáo hạn hợp đồng [DATE]',
    `ID`                        STRING         COMMENT 'Thay = trường RECID [VARCHAR2(100)]',
    `INPUTTER`                  STRING         COMMENT 'ID người nhập liệu [VARCHAR2(100)]',
    `INT_LIQ_ACCT`              STRING         COMMENT 'Tài khoản thanh toán lãi [VARCHAR2(100)]',
    `INT_RATE_TYPE`             STRING         COMMENT 'Loại lãi suất : Fix , float [VARCHAR2(20)]',
    `INT_VALUE_DATE`            DATE           COMMENT 'Ngày hiệu lực lãi suất [DATE]',
    `INTEREST_RATE`             DECIMAL(13,7)  COMMENT 'Giá trị lãi suất [NUMBER(13,7)]',
    `INTEREST_SPREAD`           DECIMAL(13,7)  COMMENT 'Biên độ lãi suất [NUMBER(13,7)]',
    `LIMIT_REFERENCE`           STRING         COMMENT 'Mã tham chiếu hạn mức [VARCHAR2(100)]',
    `LOC_TERM`                  STRING         COMMENT 'Kỳ hạn [VARCHAR2(100)]',
    `LOS_FAC_CODE`              STRING         COMMENT 'Số hồ sơ [VARCHAR2(100)]',
    `ETL_DATE`                  DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'SAOKE_TINDUNG | SNAPSHOT (Silver Temp 2 - Business Credit Statement) | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_bal (
    `RCVB_AMT_LCY`     DECIMAL(25,5)  COMMENT 'Số tiền dự thu [NUMBER(25,5)]',
    `CLS_BAL_LCY`      DECIMAL(25,5)  COMMENT 'Dư Nợ quy đổi [NUMBER(25,5)]',
    `MUD_CODE`         STRING         COMMENT 'Mã phân hệ: LD, MD, AC, PD [VARCHAR2(20)]',
    `AR_CODE`          STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `AR_ID`            STRING         COMMENT 'ID hợp đồng trên DWH [CHAR(32)]',
    `AST_TP_CODE`      STRING         COMMENT 'Loại dư nợ, hạch toán [VARCHAR2(20)]',
    `PD_CGY_CODE`      STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(20)]',
    `OU_CODE`          STRING         COMMENT 'Mã chi nhánh hạch toán [VARCHAR2(20)]',
    `CCY_CODE`         STRING         COMMENT 'Loại tiền [VARCHAR2(20)]',
    `CST_CODE`         STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `CST_ID`           STRING         COMMENT 'ID khách hàng trên DWH [CHAR(32)]',
    `AR_TERM_TP_CODE`  STRING         COMMENT 'Mã nhóm kỳ hạn [VARCHAR2(20)]',
    `GL_ITM_CODE`      STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(20)]',
    `GL_ITM_ID`        STRING         COMMENT 'ID Mã hạch toán theo SBV [CHAR(32)]',
    `SUB_PD_CODE`      STRING         COMMENT 'Mã sản phẩm con [VARCHAR2(20)]',
    `CDR_DT`           DATE           COMMENT 'Ngày giao dịch [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Arrangement Balance | SNAPSHOT | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_dlq_smy (
    `CDR_DT`               DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `AR_ID`                STRING         COMMENT 'ID của hợp đồng [CHAR(32)]',
    `AR_CODE`              STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `ORIG_AR_ID`           STRING         COMMENT 'ID của hợp đồng gốc [CHAR(32)]',
    `ORIG_AR_CODE`         STRING         COMMENT 'Mã hợp đồng gốc [VARCHAR2(40)]',
    `SRC_STM_CODE`         STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(32)]',
    `PNP_PAST_DUE_DT`      DATE           COMMENT 'Ngày quá hạn gốc [DATE]',
    `INT_PAST_DUE_DT`      DATE           COMMENT 'Ngày quá hạn lãi [DATE]',
    `PNP_ARS`              DECIMAL(25,5)  COMMENT 'Số tiền quá hạn gốc [NUMBER(25,5)]',
    `INT_ARS`              DECIMAL(25,5)  COMMENT 'Số tiền quá hạn lãi [NUMBER(25,5)]',
    `ADDITION_DYS_IN_ARS`  DECIMAL(22,0)  COMMENT 'Số ngày quá hạn chuyển đổi [NUMBER(22,0)]',
    `ETL_DATE`             DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Arrangement Delinquency Summary | SNAPSHOT | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ar_tvr_smy (
    `CDR_DT`                 DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `SRC_STM_CODE`           STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(32)]',
    `AR_ID`                  STRING         COMMENT 'ID hợp đồng [CHAR(32)]',
    `AR_CODE`                STRING         COMMENT 'Mã hợp đồng [VARCHAR2(32)]',
    `ORIG_AR_ID`             STRING         COMMENT 'ID hợp đồng gốc [CHAR(32)]',
    `ORIG_AR_CODE`           STRING         COMMENT 'Mã hợp đồng gốc [VARCHAR2(40)]',
    `CLS_BAL_FCY`            DECIMAL(32,5)  COMMENT 'Dư nợ còn lại nguyên tệ [NUMBER(32,5)]',
    `CLS_BAL_LCY`            DECIMAL(32,5)  COMMENT 'Dư nợ còn lại quy đổi [NUMBER(32,5)]',
    `TOT_RECBL_PNP_AMT_FCY`  DECIMAL(32,5)  COMMENT 'Tổng dư nợ gốc có thể thu được [NUMBER(32,5)]',
    `TOT_DUE_PNP_AMT_FCY`    DECIMAL(32,5)  COMMENT 'Tổng dư nợ gốc đến hạn [NUMBER(32,5)]',
    `TOT_ODUE_PNP_AMT_FCY`   DECIMAL(32,5)  COMMENT 'Tổng dư nợ gốc quá hạn [NUMBER(32,5)]',
    `DSBR_AMT_LTD_FCY`       DECIMAL(32,5)  COMMENT 'Tổng giá trị giải ngân từ trước đến nay [NUMBER(32,5)]',
    `DB_AMT_IN_DAY_FCY`      DECIMAL(32,5)  COMMENT 'Số tiền ghi nợ trong ngày [NUMBER(32,5)]',
    `NBR_OF_DB_IN_DAY`       DECIMAL(32,5)  COMMENT 'Số giao dịch ghi nợ trong ngày [NUMBER(32,5)]',
    `CR_AMT_IN_DAY_FCY`      DECIMAL(32,5)  COMMENT 'Số tiền ghi có trong ngày [NUMBER(32,5)]',
    `NBR_OF_CR_IN_DAY`       DECIMAL(32,5)  COMMENT 'Số giao dịch ghi có trong ngày [NUMBER(32,5)]',
    `DB_AMT_IN_MO_FCY`       DECIMAL(32,5)  COMMENT 'Số tiền ghi nợ trong tháng [NUMBER(32,5)]',
    `NBR_OF_DB_IN_MO`        DECIMAL(32,5)  COMMENT 'Số giao dịch ghi nợ trong tháng [NUMBER(32,5)]',
    `CR_AMT_IN_MO_FCY`       DECIMAL(32,5)  COMMENT 'Số tiền ghi có trong tháng [NUMBER(32,5)]',
    `NBR_OF_CR_IN_MO`        DECIMAL(32,5)  COMMENT 'Số giao dịch ghi có trong tháng [NUMBER(32,5)]',
    `DB_AMT_IN_YR_FCY`       DECIMAL(32,5)  COMMENT 'Số tiền ghi nợ trong năm [NUMBER(32,5)]',
    `NBR_OF_DB_IN_YR`        DECIMAL(32,5)  COMMENT 'Số giao dịch ghi nợ trong năm [NUMBER(32,5)]',
    `CR_AMT_IN_YR_FCY`       DECIMAL(32,5)  COMMENT 'Số tiền ghi có trong năm [NUMBER(32,5)]',
    `NBR_OF_CR_IN_YR`        DECIMAL(32,5)  COMMENT 'Số giao dịch ghi có trong năm [NUMBER(32,5)]',
    `ETL_DATE`               DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Arrangement Turnover Summary | Fact Snapshot | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');

CREATE TABLE IF NOT EXISTS iceberg.pg_silver.ast_ar_int_smy (
    `CDR_DT`                DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `SRC_STM_CODE`          STRING         COMMENT 'Mã nguồn dữ liệu [VARCHAR2(32)]',
    `AR_ID`                 STRING         COMMENT 'ID hợp đồng [CHAR(32)]',
    `AR_CODE`               STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `ORIG_AR_ID`            STRING         COMMENT 'ID hợp đồng gốc [CHAR(32)]',
    `ORIG_AR_CODE`          STRING         COMMENT 'Mã hợp đồng gốc [VARCHAR2(40)]',
    `TOT_ACR_INT_AMT_FCY`   DECIMAL(32,5)  COMMENT 'Lãi dự thu [NUMBER(32,5)]',
    `TOT_INT_PAID_AMT_FCY`  DECIMAL(32,5)  COMMENT 'Lãi đã trả [NUMBER(32,5)]',
    `TOT_INT_DUE_AMT_FCY`   DECIMAL(32,5)  COMMENT 'Lãi phải trả đến hạn [NUMBER(32,5)]',
    `TOT_INT_ODUE_AMT_FCY`  DECIMAL(32,5)  COMMENT 'Lãi phải trả quá hạn [NUMBER(32,5)]',
    `ETL_DATE`              DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (ETL_DATE)
COMMENT 'Asset Arrangement Interest Summ | SNAPSHOT | Silver Temp 2 (Bank-wised)'
TBLPROPERTIES ('format-version' = '2');
