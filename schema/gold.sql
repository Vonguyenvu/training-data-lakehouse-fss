-- Spark SQL / Iceberg DDL cho 13 bảng PG_GOLD (iceberg.pg_gold.*), sinh từ docs/spec/ (sheet Excel).
-- dbt tự tạo bảng -> file này chỉ để tra cột / kiểu / comment, không chạy.
-- Quy ước kiểu: VARCHAR2/CHAR -> STRING (độ dài gốc trong COMMENT), NUMBER(p.s) -> DECIMAL(p,s).
-- DIM (SCD TYPE 2): MERGE theo (khóa, SYS_EFF_DT); SNAPSHOT: PARTITIONED BY (ETL_DATE), INSERT OVERWRITE theo ngày.

CREATE NAMESPACE IF NOT EXISTS iceberg.pg_gold;

-- ==================== DIM_CCY (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_ccy (
    `DIM_KEY`          STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `CCY_ID`           STRING         COMMENT 'Mã duy nhất của loại tiền trên DWH [CHAR(32)]',
    `CCY_CODE`         STRING         COMMENT 'Mã loại tiền [VARCHAR2(20)]',
    `CCY_NM`           STRING         COMMENT 'Tên loại tiền [VARCHAR2(300)]',
    `NUMERIC_CCY_CODE` STRING         COMMENT 'Mã tiền tệ dạng số [VARCHAR2(20)]',
    `SYS_EFF_DT`       DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`       DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`       DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`         DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Currency | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_PD (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_pd (
    `DIM_KEY`    STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `PD_ID`      STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `PD_CODE`    STRING         COMMENT 'Mã sản phẩm [VARCHAR2(32)]',
    `PD_NM`      STRING         COMMENT 'Tên sản phẩm [VARCHAR2(255)]',
    `SYS_EFF_DT` DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT` DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT` DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`   DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Product | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_OU (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_ou (
    `DIM_KEY`    STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `OU_ID`      STRING         COMMENT 'ID của chi nhánh [CHAR(32)]',
    `OU_CODE`    STRING         COMMENT 'Mã chi nhánh [VARCHAR2(32)]',
    `OU_NM`      STRING         COMMENT 'Tên chi nhánh [VARCHAR2(300)]',
    `SYS_EFF_DT` DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT` DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT` DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`   DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Organization Unit | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_LMT (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_lmt (
    `DIM_KEY`    STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `LMT_ID`     STRING         COMMENT 'ID của hạn mức [CHAR(32)]',
    `LMT_CODE`   STRING         COMMENT 'Mã hạn mức [VARCHAR2(32)]',
    `LMT_DSC`    STRING         COMMENT 'Mô tả hạn mức [VARCHAR2(300)]',
    `SYS_EFF_DT` DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT` DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT` DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`   DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Limit | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_RSTC_TP (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_rstc_tp (
    `DIM_KEY`      STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `RSTC_TP_ID`   STRING         COMMENT 'Mã duy nhất của loại cơ cấu trên DWH [CHAR(32)]',
    `RSTC_TP_CODE` STRING         COMMENT 'Mã loại cơ cấu [VARCHAR2(20)]',
    `RSTC_TP_DSC`  STRING         COMMENT 'Mô tả loại cơ cấu [VARCHAR2(1000)]',
    `SYS_EFF_DT`   DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`   DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`   DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`     DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Loan Restructure Type | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_FNC_ST (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_fnc_st (
    `DIM_KEY`     STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `FNC_ST_ID`   STRING         COMMENT 'Mã duy nhất của nhóm nợ trên DWH [CHAR(32)]',
    `FNC_ST_CODE` STRING         COMMENT 'Mã nhóm nợ [VARCHAR2(20)]',
    `FNC_ST_DSC`  STRING         COMMENT 'Mô tả nhóm nợ [VARCHAR2(1000)]',
    `SYS_EFF_DT`  DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`  DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`  DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`    DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Financial Status | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_LOAN_AR (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_loan_ar (
    `DIM_KEY`         STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `AR_ID`           STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `AR_CODE`         STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `FCC_AR_CODE`     STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(40)]',
    `PPR_CTR_NBR`     STRING         COMMENT 'Mã hồ sơ [VARCHAR2(100)]',
    `AR_LCS_TP_CODE`  STRING         COMMENT 'Trạng thái [VARCHAR2(40)]',
    `AR_PPS_GRP_CODE` STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(40)]',
    `AR_PPS_TP_CODE`  STRING         COMMENT 'Mã mụ̣c đích vay [VARCHAR2(40)]',
    `ORIG_AMT_FCY`    DECIMAL(25,5)  COMMENT 'Giá trị phê duyệt [NUMBER(25,5)]',
    `PD_CGY_CODE`     STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(20)]',
    `PROM_CODE`       STRING         COMMENT 'Mã chương trình KM cho vay [VARCHAR2(20)]',
    `PROM_CODE_2`     STRING         COMMENT 'Mã CTKM2 [VARCHAR2(20)]',
    `TERM_CODE`       STRING         COMMENT 'Kỳ hạn [VARCHAR2(20)]',
    `VAL_DT`          DATE           COMMENT 'Ngày hiệu lực đầu tiên của hợp đồng [DATE]',
    `EFF_DT`          DATE           COMMENT 'Ngaày hiệu lực hợp đồng [DATE]',
    `MAT_DT`          DATE           COMMENT 'Ngày đáo hạn hợp đồng [DATE]',
    `SYS_EFF_DT`      DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`      DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`      DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`        DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Loan Arrangement | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== DIM_CST (SCD TYPE 2) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.dim_cst (
    `DIM_KEY`         STRING         COMMENT 'Key của bảng [CHAR(40)]',
    `CST_ID`          STRING         COMMENT 'Unique key trên DWH [CHAR(32)]',
    `CST_CODE`        STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `CST_NM`          STRING         COMMENT 'Tên khách hàng [VARCHAR2(255)]',
    `SCTR_CODE`       STRING         COMMENT 'Mã phân loại hình khách hàng [VARCHAR2(40)]',
    `IDY_LV1_CL_CODE` STRING         COMMENT 'Mã ngành nghê kinh tế cha [VARCHAR2(20)]',
    `IDY_LV2_CL_CODE` STRING         COMMENT 'Ngành nghề kinh tế [VARCHAR2(20)]',
    `SYS_EFF_DT`      DATE           COMMENT 'Ngày hiệu lực bản ghi [DATE]',
    `SYS_EXP_DT`      DATE           COMMENT 'Ngày hết hiệu lực bản ghi [DATE]',
    `SYS_UDT_DT`      DATE           COMMENT 'Ngày cập nhật bản ghi [DATE]',
    `ETL_DATE`        DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
COMMENT 'Dimension Customer | SCD TYPE 2 | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== INF_CST (SNAPSHOT) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.inf_cst (
    `CST_CODE`           STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `OPN_DT`             DATE           COMMENT 'Ngày đăng ký [DATE]',
    `FRST_OU_CODE`       STRING         COMMENT 'CN_MO [VARCHAR2(20)]',
    `IDENTN_NBR`         STRING         COMMENT 'SO_GTTT [VARCHAR2(100)]',
    `IDENTN_ISSU_DT`     DATE           COMMENT 'Ngày cấp giấy tờ tùy thân [DATE]',
    `BSN_RGST_NBR`       STRING         COMMENT 'Số giấy phép doanh nghiệp [VARCHAR2(40)]',
    `TAX_IDENTN_NBR`     STRING         COMMENT 'Số seri hóa đơn [VARCHAR2(100)]',
    `BSN_RGST_EFF_DT`    DATE           COMMENT 'Ngày phát hành hóa đơn [DATE]',
    `BSN_RGST_EXPIRY_DT` DATE           COMMENT 'Ngày hêt hạn căn cước [DATE]',
    `GND`                STRING         COMMENT 'Giới tính [VARCHAR2(20)]',
    `CHKER_OFCR`         STRING         COMMENT 'NHOM_KH_DH [VARCHAR2(20)]',
    `DOB`                DATE           COMMENT 'Ngày sinh [DATE]',
    `OU_CODE`            STRING         COMMENT 'CN_QL [VARCHAR2(20)]',
    `VIP_TP_CODE`        STRING         COMMENT 'Phân hạng khách hàng vip [VARCHAR2(20)]',
    `VIP_EFF_DT`         DATE           COMMENT 'Ngày hiệu lực khách hàng vip [DATE]',
    `EMPE_CODE`          STRING         COMMENT 'Mã nhân viên giới thiệu [VARCHAR2(20)]',
    `SHRT_NM`            STRING         COMMENT 'Tên viết tắt khách hàng [VARCHAR2(255)]',
    `CST_NM`             STRING         COMMENT 'Tên khách hàng đầy đủ [VARCHAR2(255)]',
    `CDR_DT`             DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `SCTR_CODE`          STRING         COMMENT 'Mã phân loại khách hàng [VARCHAR2(40)]',
    `CST_GRP_CODE`       STRING         COMMENT 'Khối quản lý khách hàng [VARCHAR2(20)]',
    `MAKER_OFCR`         STRING         COMMENT 'Mã nhân viên hạch toán [VARCHAR2(20)]',
    `CTY_NM`             STRING         COMMENT 'Quốc gia cư trú hiện tại [VARCHAR2(100)]',
    `CST_ST_CODE`        STRING         COMMENT 'Trạng thái khách hàng [VARCHAR2(20)]',
    `CTY_NM_2`           STRING         COMMENT 'Quốc gia thường trú [VARCHAR2(100)]',
    `CTY_OF_CTZN_CODE`   STRING         COMMENT 'Quốc tịch [VARCHAR2(40)]',
    `OCP_CODE`           STRING         COMMENT 'Nghề nghiệp khách hàng [VARCHAR2(100)]',
    `EMAIL_ADRESS`       STRING         COMMENT 'Địa chỉ email [VARCHAR2(100)]',
    `VIP_F`              STRING         COMMENT 'Đánh dấu khách hàng vip [VARCHAR2(20)]',
    `KYC_CNL_CODE`       STRING         COMMENT 'Kênh thực hiện KYC [VARCHAR2(20)]',
    `CST_LCS_CODE`       STRING         COMMENT 'Trạng thái hoạt động [VARCHAR2(20)]',
    `STR_NM`             STRING         COMMENT 'Tên đường đầy đủ theo địa chỉ [VARCHAR2(100)]',
    `STR_ADDR`           STRING         COMMENT 'STREET [VARCHAR2(100)]',
    `TRGT_CODE`          STRING         COMMENT 'TARGET [VARCHAR2(20)]',
    `IDENTN_TP_CODE`     STRING         COMMENT 'Loại căn cước [VARCHAR2(20)]',
    `GEN_DIR_PLC`        STRING         COMMENT 'GEN_DIR_PLC [VARCHAR2(100)]',
    `OPN_OU_CODE`        STRING         COMMENT 'Chi nhánh mở CIF [VARCHAR2(20)]',
    `MGT_OU_CODE`        STRING         COMMENT 'Chi nhánh quản lý khách hàng [VARCHAR2(20)]',
    `DIR_DOB`            DATE           COMMENT 'BDAY_DIRECTOR [DATE]',
    `NAT_ID_NBR`         STRING         COMMENT 'Mã quốc gia [VARCHAR2(100)]',
    `SCD_OFCR_CODE`      STRING         COMMENT 'Mã nhân viên hạch toán thứ 2 [VARCHAR2(20)]',
    `ISSU_PLC_CODE`      STRING         COMMENT 'Nơi cấp Căn cước [VARCHAR2(20)]',
    `CNTCT_PRSN`         STRING         COMMENT 'CONTACT_PERSON [VARCHAR2(40)]',
    `MBL_BNKG_F`         STRING         COMMENT 'Đánh dấu sử dụng dịch vụ mobile banking [VARCHAR2(20)]',
    `INN_BNKG_F`         STRING         COMMENT 'Đánh dấu sử dụng dịch vụ internet banking [VARCHAR2(20)]',
    `AML_RSLT`           STRING         COMMENT 'Liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(100)]',
    `AML_CHK_F`          STRING         COMMENT 'Đánh dấu liên quan tới hệ thống Phòng Chống rửa tiền [VARCHAR2(20)]',
    `IDV_EMP_ST_CODE`    STRING         COMMENT 'Tình trạng làm việc [VARCHAR2(20)]',
    `JNT_LBY_F`          STRING         COMMENT 'Đánh dấu nợ liên đới [VARCHAR2(20)]',
    `MB_CR_ST`           STRING         COMMENT 'MB_CR_STT [VARCHAR2(20)]',
    `CST_FNC_ST_CODE`    STRING         COMMENT 'Nhóm nợ khách hàng Core tính [VARCHAR2(20)]',
    `ANUL_INCM`          DECIMAL(25,5)  COMMENT 'Thu nhập theo tháng [NUMBER(25,5)]',
    `SRC_DT_TM`          DATE           COMMENT 'DATE_TIME [DATE]',
    `PROV_NM`            STRING         COMMENT 'Tỉnh/thành phố nơi cư trú [VARCHAR2(100)]',
    `IDY_LV1_CL_CODE`    STRING         COMMENT 'Mã ngành nghê kinh tế cha [VARCHAR2(20)]',
    `REFR_CODE`          STRING         COMMENT 'Mã người tham chiếu/giới thiệu [VARCHAR2(40)]',
    `CNTCT_PRSN_PHN`     STRING         COMMENT 'PHONE_CONT_PER [VARCHAR2(100)]',
    `CTR_TMPL_CODE`      STRING         COMMENT 'MAU_HD [VARCHAR2(100)]',
    `CITY_NM`            STRING         COMMENT 'Tên thành phố theo địa chỉ [VARCHAR2(100)]',
    `VSS_CODE`           STRING         COMMENT 'Mã bảo hiểm xã hội [VARCHAR2(40)]',
    `CRS_SELL_RM_CODE`   STRING         COMMENT 'MB_RM_BANCHEO [VARCHAR2(100)]',
    `HM_NBR`             STRING         COMMENT 'Số điện thoại nhà riêng [VARCHAR2(100)]',
    `MBL_NBR`            STRING         COMMENT 'Số điện thoại di động [VARCHAR2(100)]',
    `IDY_LV2_CL_CODE`    STRING         COMMENT 'Ngành nghề kinh tế [VARCHAR2(20)]',
    `ETL_DATE`           DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (`ETL_DATE`)
COMMENT 'Interface Customer | SNAPSHOT | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== INTF_LOAN_AR (SNAPSHOT) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.intf_loan_ar (
    `CDR_DT`                       DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `AR_CODE`                      STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `EFF_DT`                       DATE           COMMENT 'Ngày hiệu lực của hợp đồng [DATE]',
    `PD_CGY_CODE`                  STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(20)]',
    `PPR_CTR_NBR`                  STRING         COMMENT 'Mã hồ sơ [VARCHAR2(100)]',
    `OU_CODE`                      STRING         COMMENT 'Mã chi nhánh hạch toán [VARCHAR2(32)]',
    `SUB_PD_CODE`                  STRING         COMMENT 'Mã sản phẩm con [VARCHAR2(20)]',
    `CST_CODE`                     STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `AR_LCS_TP_CODE`               STRING         COMMENT 'Trạng thái [VARCHAR2(40)]',
    `MUD_CODE`                     STRING         COMMENT 'Mã phân hệ [VARCHAR2(20)]',
    `FNC_ST_CODE`                  STRING         COMMENT 'Nhóm nợ hợp đồng [VARCHAR2(20)]',
    `CCY_CODE`                     STRING         COMMENT 'Loại tiền [VARCHAR2(20)]',
    `MAT_DT`                       DATE           COMMENT 'Ngày đáo hạn hợp đồng [DATE]',
    `APPROVE_AMOUNT`               DECIMAL(25,5)  COMMENT 'Số tiền phê duyệt nguyên tệ [NUMBER(25,5)]',
    `VAL_DT`                       DATE           COMMENT 'Ngày hiệu lực đầu tiên của hợp đồng [DATE]',
    `DRAWDOWN_ACCOUNT`             STRING         COMMENT 'Tài khoản giải ngân [VARCHAR2(40)]',
    `AR_TERM_TP_CODE`              STRING         COMMENT 'Mã nhóm kỳ hạn [VARCHAR2(20)]',
    `LMT_CODE`                     STRING         COMMENT 'Mã tham chiếu hạn mức [VARCHAR2(32)]',
    `INT_KEY`                      DECIMAL(22,0)  COMMENT 'Mã khóa lãi suất tham chiếu [NUMBER(22,0)]',
    `INT_SPRD`                     DECIMAL(25,7)  COMMENT 'Biên độ lãi suất [NUMBER(25,7)]',
    `INT_LQD_AR_CODE`              STRING         COMMENT 'Tài khoản thanh toán lãi [VARCHAR2(40)]',
    `FCC_AR_CODE`                  STRING         COMMENT 'Mã hợp đồng FlexCube [VARCHAR2(40)]',
    `PNY_RATE`                     DECIMAL(25,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(25,7)]',
    `ODUE_INT_RATE`                DECIMAL(25,7)  COMMENT 'Lãi suất cho quá hạn [NUMBER(25,7)]',
    `AMOUNT_CUR`                   DECIMAL(25,5)  COMMENT 'Dư nợ hiện tại nguyên tệ [NUMBER(25,5)]',
    `INT_TP`                       STRING         COMMENT 'Loại lãi suất [VARCHAR2(20)]',
    `INT_BSS`                      STRING         COMMENT 'Cơ sở tính lãi (Interest Basis) [VARCHAR2(20)]',
    `INT_FIX`                      STRING         COMMENT 'Cờ cố định lãi suất [VARCHAR2(20)]',
    `RATE`                         DECIMAL(25,7)  COMMENT 'Lãi suất hiệu lực [NUMBER(25,7)]',
    `TXN_DT`                       DATE           COMMENT 'Ngày giao dịch [DATE]',
    `ODUE_PR_AMT`                  DECIMAL(25,5)  COMMENT 'Số tiền gốc quá hạn [NUMBER(25,5)]',
    `ODUE_IN_AMT`                  DECIMAL(32,5)  COMMENT 'Lãi quá hạn [NUMBER(32,5)]',
    `ODUE_PE_AMT`                  DECIMAL(25,5)  COMMENT 'Số tiền phạt gốc quá hạn [NUMBER(25,5)]',
    `ODUE_PS_AMT`                  DECIMAL(25,5)  COMMENT 'Số tiền phạt lãi quá hạn [NUMBER(25,5)]',
    `MRGN_RATE`                    DECIMAL(25,7)  COMMENT 'Biên độ thay đổi lãi suất [NUMBER(25,7)]',
    `PD_CODE`                      STRING         COMMENT 'Mã sản phẩm [VARCHAR2(20)]',
    `KHCN_PD_CODE`                 STRING         COMMENT 'Mã sản phẩm cho vay KHCN [VARCHAR2(20)]',
    `DSBR_PRPSL_OFCR`              STRING         COMMENT 'Cán bộ đề xuất giải ngân [VARCHAR2(40)]',
    `DSBR_PRPSL_MGR`               STRING         COMMENT 'Người đề xuất giải ngân [VARCHAR2(40)]',
    `MGT_OFCR`                     STRING         COMMENT 'Cán bộ quản lý khoản vay [VARCHAR2(40)]',
    `MGT_MGR`                      STRING         COMMENT 'Người quản lý khoản vay [VARCHAR2(40)]',
    `APRV_AHR`                     STRING         COMMENT 'Cấp phê duyệt giải ngân [VARCHAR2(1000)]',
    `DBT_WVR_F`                    STRING         COMMENT 'Đánh dấu cơ cấu miễn giảm lãi [VARCHAR2(20)]',
    `NBR_OF_DBT_RSTC`              DECIMAL(22,0)  COMMENT 'Giá trị tương ứng với từng trường [NUMBER(22,0)]',
    `AR_PPS_BY_PD`                 STRING         COMMENT 'Mã sản phẩm theo mục đích vay [VARCHAR2(20)]',
    `DYS_IN_PNP_ARS`               DECIMAL(22,0)  COMMENT 'Số ngày gốc quá hạn [NUMBER(22,0)]',
    `DYS_IN_INT_ARS`               DECIMAL(22,0)  COMMENT 'Số́ ngày lãi quá hạn [NUMBER(22,0)]',
    `TOT_INT_ARS`                  DECIMAL(32,5)  COMMENT 'Tổng lãi phải trả [NUMBER(32,5)]',
    `CST_ID`                       STRING         COMMENT 'ID của khách hàng [CHAR(32)]',
    `CST_FNC_ST_CODE`              STRING         COMMENT 'Nhóm nợ khách hàng [VARCHAR2(20)]',
    `MID_RATE`                     DECIMAL(25,7)  COMMENT 'Tỷ giá [NUMBER(25,7)]',
    `AMT_LCY`                      DECIMAL(25,5)  COMMENT 'Dư nợ quy đổi VND [NUMBER(25,5)]',
    `APRV_AMT_LCY`                 DECIMAL(25,5)  COMMENT 'Số tiền phê duyệt quy đổi VND [NUMBER(25,5)]',
    `MX_DYS_IN_ARS`                DECIMAL(22,0)  COMMENT 'Số ngày quá hạn cao nhất [NUMBER(22,0)]',
    `TOT_INT_PAID_AMT_FCY`         DECIMAL(32,5)  COMMENT 'Tổng lãi đã trả [NUMBER(32,5)]',
    `AR_FNC_ST_CODE`               STRING         COMMENT 'Nhóm nợ hợp đồng [VARCHAR2(20)]',
    `JNT_LBY_F`                    STRING         COMMENT 'Cờ nợ liên đới [VARCHAR2(20)]',
    `FCC_LMT_CODE`                 STRING         COMMENT 'Mã hạn mức trên Flexcube [VARCHAR2(20)]',
    `MAKER_OFCR_CODE`              STRING         COMMENT 'ID người nhập liệu [VARCHAR2(40)]',
    `CHKER_OFCR_CODE`              STRING         COMMENT 'Mã người phê duyệt [VARCHAR2(40)]',
    `CST_GRP_CODE`                 STRING         COMMENT 'Khối khách hàng [VARCHAR2(20)]',
    `AR_PPS_TP_CODE`               STRING         COMMENT 'Mã mục đích vay [VARCHAR2(40)]',
    `AR_PPS_GRP_CODE`              STRING         COMMENT 'Mã nhóm mục đích vay [VARCHAR2(40)]',
    `LOS_CTR_CODE`                 STRING         COMMENT 'mã hợp đồng vay [VARCHAR2(40)]',
    `LOS_CTR_ID`                   STRING         COMMENT 'mã hồ sơ trên LOS [VARCHAR2(20)]',
    `DBT_RSTC_TP_CODE`             STRING         COMMENT 'Loại cơ cấu [VARCHAR2(20)]',
    `CAR_AP_CODE`                  STRING         COMMENT 'Mã hồ sơ đăng ký vay vốn mua xe [VARCHAR2(40)]',
    `SCR_TP`                       STRING         COMMENT 'Loạ̣i hình chứng khoán [VARCHAR2(20)]',
    `MAND_REPYMT`                  STRING         COMMENT 'Giá trị UDF [VARCHAR2(20)]',
    `LOS_CTR_NBR`                  STRING         COMMENT 'Số hồ sơ [VARCHAR2(40)]',
    `PROM_PRGM`                    STRING         COMMENT 'Mã chương trình KM cho vay [VARCHAR2(20)]',
    `PROM_PRGM_2`                  STRING         COMMENT 'Mã CTKM2 [VARCHAR2(20)]',
    `SCTR_CODE`                    STRING         COMMENT 'Mã thành phần kinh tế [VARCHAR2(40)]',
    `COVID19_RSTC_COMPL_DT`        DATE           COMMENT 'Ngày hết hạn cơ cấu [DATE]',
    `NGAY_THANH_TOAN_GOC_TIEPTHEO` DATE           COMMENT 'Ngày thanh toán gốc tiếp theo [DATE]',
    `SO_TIEN_THUNO_GOC`            DECIMAL(25,5)  COMMENT 'Số tiền thu nợ gốc [NUMBER(25,5)]',
    `NGAY_THANH_TOAN_LAI`          DATE           COMMENT 'Ngày thanh toán lãi [DATE]',
    `IDY_LV1_CL_CODE`              STRING         COMMENT 'Mã ngành kinh tế cha [VARCHAR2(20)]',
    `IDY_LV2_CL_CODE`              STRING         COMMENT 'Mã ngành kinh tế con [VARCHAR2(20)]',
    `TOT_ACR_INT_DUE_AMT`          DECIMAL(25,5)  COMMENT 'Lãi dự thu trong hạn [NUMBER(25,5)]',
    `NXT_ACR_INT_AMT`              DECIMAL(25,5)  COMMENT 'Lãi dự thu tiếp theo [NUMBER(25,5)]',
    `DTHU_CONLAI_DUKIEN_KYGANNHAT` DECIMAL(25,5)  COMMENT 'Dự thu còn lại dự kiến kỳ gần nhất [NUMBER(25,5)]',
    `OU_NM`                        STRING         COMMENT 'Tên chi nhánh [VARCHAR2(300)]',
    `ADDITION_DYS_IN_ARS`          DECIMAL(22,0)  COMMENT 'Số ngày quá hạn chuyển đổi [NUMBER(22,0)]',
    `BDS_TT11`                     STRING         COMMENT 'Phân loại bất động sản theo Thông tư 11 [VARCHAR2(20)]',
    `GL_ITM_CODE`                  STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(20)]',
    `CST_TP_CODE`                  STRING         COMMENT 'Loại khách hàng (KHCN/KHDN) [VARCHAR2(20)]',
    `CST_NM`                       STRING         COMMENT 'Tên đầy đủ của khách hàng [VARCHAR2(255)]',
    `ETL_DATE`                     DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (`ETL_DATE`)
COMMENT 'Interface Loan Arrangement | SNAPSHOT | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== INTF_LOAN_DSBR (SNAPSHOT) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.intf_loan_dsbr (
    `CDR_DT`              DATE           COMMENT 'Ngày dữ liệu [DATE]',
    `AR_CODE`             STRING         COMMENT 'Mã hợp đồng [VARCHAR2(40)]',
    `CST_CODE`            STRING         COMMENT 'Mã khách hàng [VARCHAR2(20)]',
    `OU_CODE`             STRING         COMMENT 'Mã chi nhánh quản lý hiện tại [VARCHAR2(32)]',
    `VAL_DT`              DATE           COMMENT 'Ngày giải ngân [DATE]',
    `EFF_DT`              DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `MAT_DT`              DATE           COMMENT 'Ngày hiệu lực hợp đồng [DATE]',
    `CCY_CODE`            STRING         COMMENT 'Loại tiền [VARCHAR2(20)]',
    `AR_PPS_TP_CODE`      STRING         COMMENT 'Mã mục đích vay [VARCHAR2(40)]',
    `PPR_CTR_NBR`         STRING         COMMENT 'Mã hồ sơ [VARCHAR2(100)]',
    `PD_CGY_CODE`         STRING         COMMENT 'Mã phân loại sản phẩm [VARCHAR2(20)]',
    `ORIG_AMT_FCY`        DECIMAL(25,5)  COMMENT 'Giá trị phê duyệt [NUMBER(25,5)]',
    `EXG_RATE_TO_LCL_CCY` DECIMAL(25,7)  COMMENT 'Tỷ giá [NUMBER(25,7)]',
    `ORIG_AMT_LCY`        DECIMAL(25,5)  COMMENT 'Giá trị phê duyệt quy đổi [NUMBER(25,5)]',
    `EMPE_NM`             STRING         COMMENT 'Tên nhân viên hạch toán [VARCHAR2(255)]',
    `EFF_RATE_PCT`        DECIMAL(25,7)  COMMENT 'Giá trị lãi suất [NUMBER(25,7)]',
    `AR_PPS_BY_IDY`       STRING         COMMENT 'Mục đích vay theo ngành kinh tế [VARCHAR2(20)]',
    `LOS_CTR_CODE`        STRING         COMMENT 'mã hợp đồng vay [VARCHAR2(40)]',
    `CAR_AP_CODE`         STRING         COMMENT 'Mã hồ sơ đăng ký vay vốn mua xe [VARCHAR2(40)]',
    `DSBR_PRPSL_OFCR`     STRING         COMMENT 'Cán bộ đề xuất giải ngân [VARCHAR2(40)]',
    `DSBR_PRPSL_MGR`      STRING         COMMENT 'Người đề xuất giải ngân [VARCHAR2(40)]',
    `PD_CODE`             STRING         COMMENT 'Mã nhóm sản phẩm [VARCHAR2(20)]',
    `PD_NM`               STRING         COMMENT 'Tên sản phẩm [VARCHAR2(255)]',
    `LOC_TERM`            STRING         COMMENT 'Kỳ hạn [VARCHAR2(20)]',
    `ETL_DATE`            DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (`ETL_DATE`)
COMMENT 'Interface Loan Disbursement | SNAPSHOT | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== INTF_LOAN_REPYMT_SHD (SNAPSHOT) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.intf_loan_repymt_shd (
    `CDR_DT`          DATE           COMMENT 'Ngày snapshot [DATE]',
    `CST_ID`          STRING         COMMENT 'Mã số định danh duy nhất của khách hàng trên dwh [CHAR(32)]',
    `CST_CODE`        STRING         COMMENT 'Mã khách hàng (CIF) [VARCHAR2(32)]',
    `AR_AVY_SHD_CODE` STRING         COMMENT 'Mã số dòng lịch trên hệ thống nguồn [VARCHAR2(32)]',
    `AR_CODE`         STRING         COMMENT 'Mã tài khoản vay [VARCHAR2(32)]',
    `OU_CODE`         STRING         COMMENT 'Chi nhánh hạch toán [VARCHAR2(32)]',
    `EFF_MAT_DT`      DATE           COMMENT 'Ngày đáo hạn thực tế [DATE]',
    `CCY_CODE`        STRING         COMMENT 'Mã loại tiền [VARCHAR2(20)]',
    `PBL_AMT_TP`      STRING         COMMENT 'Phân loại tiền cần thanh toán trong kỳ bill tương ứng (PS/PE/LD,..) [VARCHAR2(20)]',
    `PBL_AMT_LCY`     DECIMAL(25,5)  COMMENT 'Số tiền cần thanh toán quy đổi trong kỳ bill tương ứng [NUMBER(25,5)]',
    `PBL_AMT_FCY`     DECIMAL(25,5)  COMMENT 'Số tiền cần thanh toán nguyên tệ trong kỳ bill tương ứng [NUMBER(25,5)]',
    `EXG_RATE`        DECIMAL(25,7)  COMMENT 'Tỷ giá thực hiện [NUMBER(25,7)]',
    `LND_REPYMT_TP`   STRING         COMMENT 'Phân loại bút toán ( PAID/DUE) [CHAR(10)]',
    `F_LAST_OD_DT`    DECIMAL(1,0)   COMMENT 'Cờ hợp đồng có đang tồn tại kỳ trả nợ quá hạn gần nhất hay không [NUMBER(1,0)]',
    `LAST_OD_DT`      DATE           COMMENT 'Ngày đến hạn của kỳ trả nợ gần nhất đã chuyển sang quá hạn [DATE]',
    `FCC_VAL_DT`      DATE           COMMENT 'Ngày tạo bút toán ( booking_date) [DATE]',
    `MAT_DT`          DATE           COMMENT 'Ngày đáo hạn trên hợp đồng [DATE]',
    `GL_ITM_CODE`     STRING         COMMENT 'Mã hạch toán theo SBV [VARCHAR2(20)]',
    `CIC_LOAN_GRP`    DECIMAL(1,0)   COMMENT 'Phân loại nhóm nợ khách hàng [NUMBER(1,0)]',
    `CST_FULL_NM`     STRING         COMMENT 'Full tên của Khách hàng [VARCHAR2(255)]',
    `ETL_DATE`        DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (`ETL_DATE`)
COMMENT 'Interface Loan Repayment Schedu | SNAPSHOT | Gold'
TBLPROPERTIES ('format-version' = '2');

-- ==================== FCT_LOAN_AR (SNAPSHOT) ====================
CREATE TABLE IF NOT EXISTS iceberg.pg_gold.fct_loan_ar (
    `CDR_DT_DIM_KEY`         DATE           COMMENT 'Chiều ngày dữ liệu [DATE]',
    `LOAN_AR_DIM_KEY`        STRING         COMMENT 'Chiều Hợp đồng vay [CHAR(40)]',
    `CST_DIM_KEY`            STRING         COMMENT 'Chiều Khách hàng [CHAR(40)]',
    `PD_DIM_KEY`             STRING         COMMENT 'Chiều Sản phẩm [CHAR(40)]',
    `OU_DIM_KEY`             STRING         COMMENT 'Chiều chi nhánh [CHAR(40)]',
    `CCY_DIM_KEY`            STRING         COMMENT 'Chiều loại tiền [CHAR(40)]',
    `LMT_DIM_KEY`            STRING         COMMENT 'Chiều hạn mức [CHAR(40)]',
    `LOAN_RSTC_TP_DIM_KEY`   STRING         COMMENT 'Chiều loại tái cấu trúc [CHAR(40)]',
    `LOAN_AR_FNC_ST_DIM_KEY` STRING         COMMENT 'Chiều nhóm nợ hợp đồng vay [CHAR(40)]',
    `CST_FNC_ST_DIM_KEY`     STRING         COMMENT 'Chiều nhóm nợ khách hàng [CHAR(40)]',
    `MUD_CODE`               STRING         COMMENT 'Mã phân hệ [VARCHAR2(20)]',
    `PNY_RATE`               DECIMAL(25,7)  COMMENT 'Lãi phạt penalty rate [NUMBER(25,7)]',
    `ODUE_INT_RATE`          DECIMAL(25,7)  COMMENT 'Lãi suất cho quá hạn [NUMBER(25,7)]',
    `TOT_INT_ARS_FCY`        DECIMAL(32,5)  COMMENT 'Tổng lãi phải trả [NUMBER(32,5)]',
    `TOT_INT_PAID_AMT_FCY`   DECIMAL(32,5)  COMMENT 'Tổng lãi đã trả [NUMBER(32,5)]',
    `DYS_IN_PNP_ARS`         DECIMAL(32,0)  COMMENT 'Số ngày quá hạn gốc [NUMBER(32,0)]',
    `DYS_IN_INT_ARS`         DECIMAL(32,0)  COMMENT 'Số ngày quá hạn lãi [NUMBER(32,0)]',
    `MX_DYS_IN_ARS`          DECIMAL(32,0)  COMMENT 'Số ngày quá hạn cao nhất [NUMBER(32,0)]',
    `ADDITION_DYS_IN_ARS`    DECIMAL(32,0)  COMMENT 'Số ngày quá hạn chuyển đổi [NUMBER(32,0)]',
    `OTSND_AMT_LCY`          DECIMAL(32,5)  COMMENT 'Dư nợ quy đổi [NUMBER(32,5)]',
    `EXG_RATE_TO_LCL_CCY`    DECIMAL(25,7)  COMMENT 'Tỷ giá [NUMBER(25,7)]',
    `NBR_OF_DBT_RSTC`        DECIMAL(22,0)  COMMENT 'Số lần cơ cấu [NUMBER(22,0)]',
    `ETL_DATE`               DATE           COMMENT 'Ngày batch ETL ghi bản ghi (cột kỹ thuật) [DATE]'
)
USING iceberg
PARTITIONED BY (`ETL_DATE`)
COMMENT 'Fact Loan Arrangement | SNAPSHOT | Gold'
TBLPROPERTIES ('format-version' = '2');
