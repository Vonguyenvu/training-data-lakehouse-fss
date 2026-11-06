# inf_cst — sheet 'Interface Customer'

Tầng: Silver -> Gold (Interface / Reporting) · Wave: WAVE_4_GOLD_INTERFACE · Chờ: PG_SILVER.CST, PG_SILVER.IDV_PRFL, PG_SILVER.IDV_EMP_ST, PG_SILVER.ORG_PRFL, PG_SILVER.IP_ALT_IDENTN, PG_SILVER.IP_ELC_ADR, PG_SILVER.IP_PST_ADR

## Header (TYPE, bảng, JOIN, WHERE)
- TYPE : SNAPSHOT
- No · System · TABLE · Short table · Main Table · Type join · Condition JOIN · Condition where · Fields
- 1 · PG_SILVER · CST · a · main · a.SYS_EXP_DT IS NULL
- 2 · PG_SILVER · IP_ALT_IDENTN · b · sub · LEFT JOIN · a.CST_CODE = b.CST_CODE · b.SYS_EXP_DT IS NULL AND b.RN = 1 -- Dedup 1 giấy tờ chính/CIF: ROW_NUMBER() OVER (PARTITION BY CST_CODE ORDER BY IDENTN_ISSU_DT DESC) = 1
- 3 · PG_SILVER · IP_ELC_ADR · c1 · sub · LEFT JOIN · a.CST_CODE = c1.CST_CODE · c1.ELC_ADR_TP = 'EMAIL' AND c1.SYS_EXP_DT IS NULL
- 4 · PG_SILVER · IP_ELC_ADR · c2 · sub · LEFT JOIN · a.CST_CODE = c2.CST_CODE · c2.ELC_ADR_TP = 'HOME_NUMBER' AND c2.SYS_EXP_DT IS NULL
- 5 · PG_SILVER · IP_ELC_ADR · c3 · sub · LEFT JOIN · a.CST_CODE = c3.CST_CODE · c3.ELC_ADR_TP = 'MOBILE_NUMBER' AND c3.SYS_EXP_DT IS NULL
- 6 · PG_SILVER · IP_PST_ADR · d1 · sub · LEFT JOIN · a.CST_CODE = d1.CST_CODE · d1.PST_ADR_TP = 'CURRENT ADDRESS' AND d1.SYS_EXP_DT IS NULL
- 7 · PG_SILVER · IP_PST_ADR · d2 · sub · LEFT JOIN · a.CST_CODE = d2.CST_CODE · d2.PST_ADR_TP = 'PERMANENT ADDRESS' AND d2.SYS_EXP_DT IS NULL
- 8 · PG_SILVER · IDV_PRFL · e · sub · INNER JOIN · a.CST_CODE = e.CST_CODE · e.SYS_EXP_DT IS NULL
- 9 · PG_SILVER · IDV_EMP_ST · f · sub · LEFT JOIN · a.CST_CODE = f.CST_CODE · f.SYS_EXP_DT IS NULL

## Mapping
| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |
|---|---|---|---|---|---|---|---|
| CST | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng | CST_CODE |
| CST | OPN_DT | 1:1 | OPN_DT | DATE |  | Ngày đăng ký | OPN_DT |
| CST | FRST_OU_CODE | 1:1 | FRST_OU_CODE | VARCHAR2 | 20 | CN_MO | FRST_OU_CODE |
| IP_ALT_IDENTN | IDENTN_NBR | 1:1 | IDENTN_NBR | VARCHAR2 | 100 | SO_GTTT | IDENTN_NBR |
| IP_ALT_IDENTN | IDENTN_ISSU_DT | 1:1 | IDENTN_ISSU_DT | DATE |  | Ngày cấp giấy tờ tùy thân | IDENTN_ISSU_DT |
| IDV_PRFL | CST_CODE | NULL | BSN_RGST_NBR | VARCHAR2 | 40 | Số giấy phép doanh nghiệp | BSN_RGST_NBR |
| IDV_PRFL | TAX_IDENTN_NBR | 1:1 | TAX_IDENTN_NBR | VARCHAR2 | 100 | Số seri hóa đơn | TAX_IDENTN_NBR |
| IDV_PRFL | BSN_RGST_EFF_DT | 1:1 | BSN_RGST_EFF_DT | DATE |  | Ngày phát hành hóa đơn | BSN_RGST_EFF_DT |
| IP_ALT_IDENTN | IDENTN_EXPIRY_DT | 1:1 | BSN_RGST_EXPIRY_DT | DATE |  | Ngày hêt hạn căn cước | BSN_RGST_EXPIRY_DT |
| IDV_PRFL | GND | 1:1 | GND | VARCHAR2 | 20 | Giới tính | GND |
| CST | CHKER_OFCR_CODE | 1:1 | CHKER_OFCR | VARCHAR2 | 20 | NHOM_KH_DH | CHKER_OFCR |
| IDV_PRFL | DOB | 1:1 | DOB | DATE |  | Ngày sinh | DOB |
| CST | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 20 | CN_QL | OU_CODE |
| IDV_PRFL | VIP_TP_CODE | 1:1 | VIP_TP_CODE | VARCHAR2 | 20 | Phân hạng khách hàng vip | VIP_TP_CODE |
| IDV_PRFL | VIP_EFF_DT | 1:1 | VIP_EFF_DT | DATE |  | Ngày hiệu lực khách hàng vip | VIP_EFF_DT |
| CST | EMPE_CODE | 1:1 | EMPE_CODE | VARCHAR2 | 20 | Mã nhân viên giới thiệu | EMPE_CODE |
| CST | SHRT_NM | 1:1 | SHRT_NM | VARCHAR2 | 255 | Tên viết tắt khách hàng | SHRT_NM |
| CST | CST_NM | 1:1 | CST_NM | VARCHAR2 | 255 | Tên khách hàng đầy đủ | CST_NM |
| IDV_PRFL | CST_CODE | ${ETL_DATE} | CDR_DT | DATE |  | Ngày dữ liệu | CDR_DT |
| CST | SCTR_CODE | 1:1 | SCTR_CODE | VARCHAR2 | 40 | Mã phân loại khách hàng | SCTR_CODE |
| CST | CST_GRP_CODE | 1:1 | CST_GRP_CODE | VARCHAR2 | 20 | Khối quản lý khách hàng | CST_GRP_CODE |
| CST | MAKER_OFCR_CODE | 1:1 | MAKER_OFCR | VARCHAR2 | 20 | Mã nhân viên hạch toán | MAKER_OFCR |
| IP_PST_ADR | CTY_NM | d1.CTY_NM | CTY_NM | VARCHAR2 | 100 | Quốc gia cư trú hiện tại | CTY_NM |
| IDV_PRFL | CST_ST_CODE | 1:1 | CST_ST_CODE | VARCHAR2 | 20 | Trạng thái khách hàng | CST_ST_CODE |
| IP_PST_ADR | CTY_NM | d2.CTY_NM | CTY_NM_2 | VARCHAR2 | 100 | Quốc gia thường trú | CTY_NM_2 |
| IDV_PRFL | CTY_OF_CTZN_CODE | 1:1 | CTY_OF_CTZN_CODE | VARCHAR2 | 40 | Quốc tịch | CTY_OF_CTZN_CODE |
| IDV_EMP_ST | OCP_CODE | 1:1 | OCP_CODE | VARCHAR2 | 100 | Nghề nghiệp khách hàng | OCP_CODE |
| IP_ELC_ADR | ELC_ADR_VAL | c1.ELC_ADR_VAL | EMAIL_ADRESS | VARCHAR2 | 100 | Địa chỉ email | EMAIL_ADRESS |
| IDV_PRFL | VIP_F | 1:1 | VIP_F | VARCHAR2 | 20 | Đánh dấu khách hàng vip | VIP_F |
| IDV_PRFL | KYC_CNL_CODE | 1:1 | KYC_CNL_CODE | VARCHAR2 | 20 | Kênh thực hiện KYC | KYC_CNL_CODE |
| IDV_PRFL | CST_LCS_CODE | 1:1 | CST_LCS_CODE | VARCHAR2 | 20 | Trạng thái hoạt động | CST_LCS_CODE |
| IP_PST_ADR | STR_NM | d1.STR_NM | STR_NM | VARCHAR2 | 100 | Tên đường đầy đủ theo địa chỉ | STR_NM |
| CST | STR_ADDR | 1:1 | STR_ADDR | VARCHAR2 | 100 | STREET | STR_ADDR |
| CST | TRGT_CODE | 1:1 | TRGT_CODE | VARCHAR2 | 20 | TARGET | TRGT_CODE |
| IP_ALT_IDENTN | IDENTN_TP_CODE | 1:1 | IDENTN_TP_CODE | VARCHAR2 | 20 | Loại căn cước | IDENTN_TP_CODE |
| IDV_PRFL | CST_CODE | NULL | GEN_DIR_PLC | VARCHAR2 | 100 | GEN_DIR_PLC | GEN_DIR_PLC |
| CST | FRST_OU_CODE | 1:1 | OPN_OU_CODE | VARCHAR2 | 20 | Chi nhánh mở CIF | OPN_OU_CODE |
| IDV_PRFL | OU_CODE | 1:1 | MGT_OU_CODE | VARCHAR2 | 20 | Chi nhánh quản lý khách hàng | MGT_OU_CODE |
| IDV_PRFL | CST_CODE | NULL | DIR_DOB | DATE |  | BDAY_DIRECTOR | DIR_DOB |
| IP_ALT_IDENTN | IDENTN_NBR | 1:1 | NAT_ID_NBR | VARCHAR2 | 100 | Mã quốc gia | NAT_ID_NBR |
| CST | CHKER_OFCR_CODE | 1:1 | SCD_OFCR_CODE | VARCHAR2 | 20 | Mã nhân viên hạch toán thứ 2 | SCD_OFCR_CODE |
| IP_ALT_IDENTN | ISSU_PLC_CODE | 1:1 | ISSU_PLC_CODE | VARCHAR2 | 20 | Nơi cấp Căn cước | ISSU_PLC_CODE |
| IDV_PRFL | CST_CODE | NULL | CNTCT_PRSN | VARCHAR2 | 40 | CONTACT_PERSON | CNTCT_PRSN |
| IDV_PRFL | MBL_BNKG_F | 1:1 | MBL_BNKG_F | VARCHAR2 | 20 | Đánh dấu sử dụng dịch vụ mobile banking | MBL_BNKG_F |
| IDV_PRFL | INN_BNKG_F | 1:1 | INN_BNKG_F | VARCHAR2 | 20 | Đánh dấu sử dụng dịch vụ internet banking | INN_BNKG_F |
| IDV_PRFL | AML_RSLT | 1:1 | AML_RSLT | VARCHAR2 | 100 | Liên quan tới hệ thống Phòng Chống rửa tiền | AML_RSLT |
| IDV_PRFL | AML_CHK_F | 1:1 | AML_CHK_F | VARCHAR2 | 20 | Đánh dấu liên quan tới hệ thống Phòng Chống rửa tiền | AML_CHK_F |
| IDV_EMP_ST | IDV_EMP_ST_CODE | 1:1 | IDV_EMP_ST_CODE | VARCHAR2 | 20 | Tình trạng làm việc | IDV_EMP_ST_CODE |
| IDV_PRFL | JNT_LBY_F | 1:1 | JNT_LBY_F | VARCHAR2 | 20 | Đánh dấu nợ liên đới | JNT_LBY_F |
| IDV_PRFL | MB_CR_ST | 1:1 | MB_CR_ST | VARCHAR2 | 20 | MB_CR_STT | MB_CR_ST |
| IDV_PRFL | CST_FNC_ST_CODE | 1:1 | CST_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ khách hàng Core tính | CST_FNC_ST_CODE |
| IDV_EMP_ST | ANUL_INCM | 1:1 | ANUL_INCM | NUMBER | 25.5 | Thu nhập theo tháng | ANUL_INCM |
| CST | SRC_DT_TM | 1:1 | SRC_DT_TM | DATE |  | DATE_TIME | SRC_DT_TM |
| IP_PST_ADR | PROV_NM | d1.PROV_NM | PROV_NM | VARCHAR2 | 100 | Tỉnh/thành phố nơi cư trú | PROV_NM |
| IDV_PRFL | IDY_LV1_CL_CODE | 1:1 | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành nghê kinh tế cha | IDY_LV1_CL_CODE |
| CST | REFR_CODE | 1:1 | REFR_CODE | VARCHAR2 | 40 | Mã người tham chiếu/giới thiệu | REFR_CODE |
| IDV_PRFL | CST_CODE | NULL | CNTCT_PRSN_PHN | VARCHAR2 | 100 | PHONE_CONT_PER | CNTCT_PRSN_PHN |
| CST | CTR_TMPL_CODE | 1:1 | CTR_TMPL_CODE | VARCHAR2 | 100 | MAU_HD | CTR_TMPL_CODE |
| IP_PST_ADR | PROV_NM | d2.PROV_NM | CITY_NM | VARCHAR2 | 100 | Tên thành phố theo địa chỉ | CITY_NM |
| IDV_PRFL | VSS_CODE | 1:1 | VSS_CODE | VARCHAR2 | 40 | Mã bảo hiểm xã hội | VSS_CODE |
| CST | CRS_SELL_RM_CODE | 1:1 | CRS_SELL_RM_CODE | VARCHAR2 | 100 | MB_RM_BANCHEO | CRS_SELL_RM_CODE |
| IP_ELC_ADR | ELC_ADR_VAL | c2.ELC_ADR_VAL | HM_NBR | VARCHAR2 | 100 | Số điện thoại nhà riêng | HM_NBR |
| IP_ELC_ADR | ELC_ADR_VAL | c3.ELC_ADR_VAL | MBL_NBR | VARCHAR2 | 100 | Số điện thoại di động | MBL_NBR |
| IDV_PRFL | IDY_LV2_CL_CODE | 1:1 | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Ngành nghề kinh tế | IDY_LV2_CL_CODE |
|  |  |  |  |  |  |  |  |
| System | TABLE | Short table | Condition where | Fields |  |  |  |
| PG_SILVER | CST | a | a.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | IP_ALT_IDENTN | b | b.SYS_EXP_DT IS NULL AND b.RN = 1 -- Dedup 1 giấy tờ chính/CIF: ROW_NUMBER() OVER (PARTITION BY CST_CODE ORDER BY IDENTN_ISSU_DT DESC) = 1 |  |  |  |  |
| PG_SILVER | IP_ELC_ADR | c1 | c1.ELC_ADR_TP = 'EMAIL' AND c1.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | IP_ELC_ADR | c2 | c2.ELC_ADR_TP = 'HOME_NUMBER' AND c2.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | IP_ELC_ADR | c3 | c3.ELC_ADR_TP = 'MOBILE_NUMBER' AND c3.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | IP_PST_ADR | d1 | d1.PST_ADR_TP = 'CURRENT ADDRESS' AND d1.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | IP_PST_ADR | d2 | d2.PST_ADR_TP = 'PERMANENT ADDRESS' AND d2.SYS_EXP_DT IS NULL |  |  |  |  |
| PG_SILVER | ORG_PRFL | e | e.SYS_EXP_DT IS NULL |  |  |  |  |
| CST | CST_CODE | 1:1 | CST_CODE | VARCHAR2 | 20 | Mã khách hàng | CST_CODE |
| CST | OPN_DT | 1:1 | OPN_DT | DATE |  | Ngày đăng ký | OPN_DT |
| CST | FRST_OU_CODE | 1:1 | FRST_OU_CODE | VARCHAR2 | 20 | CN_MO | FRST_OU_CODE |
| IP_ALT_IDENTN | IDENTN_NBR | 1:1 | IDENTN_NBR | VARCHAR2 | 100 | SO_GTTT | IDENTN_NBR |
| IP_ALT_IDENTN | IDENTN_ISSU_DT | 1:1 | IDENTN_ISSU_DT | DATE |  | Ngày cấp giấy tờ tùy thân | IDENTN_ISSU_DT |
| ORG_PRFL | BSN_RGST_NBR | 1:1 | BSN_RGST_NBR | VARCHAR2 | 40 | Số giấy phép doanh nghiệp | BSN_RGST_NBR |
| ORG_PRFL | TAX_IDENTN_NBR | 1:1 | TAX_IDENTN_NBR | VARCHAR2 | 100 | Số seri hóa đơn | TAX_IDENTN_NBR |
| ORG_PRFL | BSN_RGST_EFF_DT | 1:1 | BSN_RGST_EFF_DT | DATE |  | Ngày phát hành hóa đơn | BSN_RGST_EFF_DT |
| IP_ALT_IDENTN | IDENTN_EXPIRY_DT | 1:1 | BSN_RGST_EXPIRY_DT | DATE |  | Ngày hêt hạn căn cước | BSN_RGST_EXPIRY_DT |
| ORG_PRFL | CST_CODE | NULL | GND | VARCHAR2 | 20 | Giới tính | GND |
| CST | CHKER_OFCR_CODE | 1:1 | CHKER_OFCR | VARCHAR2 | 20 | NHOM_KH_DH | CHKER_OFCR |
| ORG_PRFL | ESTB_DT | 1:1 | DOB | DATE |  | Ngày sinh | DOB |
| CST | OU_CODE | 1:1 | OU_CODE | VARCHAR2 | 20 | CN_QL | OU_CODE |
| ORG_PRFL | VIP_TP_CODE | 1:1 | VIP_TP_CODE | VARCHAR2 | 20 | Phân hạng khách hàng vip | VIP_TP_CODE |
| ORG_PRFL | VIP_EFF_DT | 1:1 | VIP_EFF_DT | DATE |  | Ngày hiệu lực khách hàng vip | VIP_EFF_DT |
| CST | EMPE_CODE | 1:1 | EMPE_CODE | VARCHAR2 | 20 | Mã nhân viên giới thiệu | EMPE_CODE |
| CST | SHRT_NM | 1:1 | SHRT_NM | VARCHAR2 | 255 | Tên viết tắt khách hàng | SHRT_NM |
| CST | CST_NM | 1:1 | CST_NM | VARCHAR2 | 255 | Tên khách hàng đầy đủ | CST_NM |
| CST | CST_CODE | ${ETL_DATE} | CDR_DT | DATE |  | Ngày dữ liệu | CDR_DT |
| CST | SCTR_CODE | 1:1 | SCTR_CODE | VARCHAR2 | 40 | Mã phân loại khách hàng | SCTR_CODE |
| CST | CST_GRP_CODE | 1:1 | CST_GRP_CODE | VARCHAR2 | 20 | Khối quản lý khách hàng | CST_GRP_CODE |
| CST | MAKER_OFCR_CODE | 1:1 | MAKER_OFCR | VARCHAR2 | 20 | Mã nhân viên hạch toán | MAKER_OFCR |
| IP_PST_ADR | CTY_NM | d1.CTY_NM | CTY_NM | VARCHAR2 | 100 | Quốc gia cư trú hiện tại | CTY_NM |
| ORG_PRFL | CST_ST_CODE | 1:1 | CST_ST_CODE | VARCHAR2 | 20 | Trạng thái khách hàng | CST_ST_CODE |
| IP_PST_ADR | CTY_NM | d2.CTY_NM | CTY_NM_2 | VARCHAR2 | 100 | Quốc gia thường trú | CTY_NM_2 |
| IP_PST_ADR | CST_CODE | NULL | CTY_OF_CTZN_CODE | VARCHAR2 | 40 | Quốc tịch | CTY_OF_CTZN_CODE |
| ORG_PRFL | CST_CODE | NULL | OCP_CODE | VARCHAR2 | 100 | Nghề nghiệp khách hàng | OCP_CODE |
| IP_ELC_ADR | ELC_ADR_VAL | c1.ELC_ADR_VAL | EMAIL_ADRESS | VARCHAR2 | 100 | Địa chỉ email | EMAIL_ADRESS |
| ORG_PRFL | VIP_F | 1:1 | VIP_F | VARCHAR2 | 20 | Đánh dấu khách hàng vip | VIP_F |
| ORG_PRFL | KYC_CNL_CODE | 1:1 | KYC_CNL_CODE | VARCHAR2 | 20 | Kênh thực hiện KYC | KYC_CNL_CODE |
| ORG_PRFL | CST_LCS_CODE | 1:1 | CST_LCS_CODE | VARCHAR2 | 20 | Trạng thái hoạt động | CST_LCS_CODE |
| IP_PST_ADR | STR_NM | d1.STR_NM | STR_NM | VARCHAR2 | 100 | Tên đường đầy đủ theo địa chỉ | STR_NM |
| CST | STR_ADDR | 1:1 | STR_ADDR | VARCHAR2 | 100 | STREET | STR_ADDR |
| CST | TRGT_CODE | 1:1 | TRGT_CODE | VARCHAR2 | 20 | TARGET | TRGT_CODE |
| IP_ALT_IDENTN | IDENTN_TP_CODE | 1:1 | IDENTN_TP_CODE | VARCHAR2 | 20 | Loại căn cước | IDENTN_TP_CODE |
| ORG_PRFL | GEN_DIR_PLC | 1:1 | GEN_DIR_PLC | VARCHAR2 | 100 | GEN_DIR_PLC | GEN_DIR_PLC |
| CST | FRST_OU_CODE | 1:1 | OPN_OU_CODE | VARCHAR2 | 20 | Chi nhánh mở CIF | OPN_OU_CODE |
| ORG_PRFL | OU_CODE | 1:1 | MGT_OU_CODE | VARCHAR2 | 20 | Chi nhánh quản lý khách hàng | MGT_OU_CODE |
| ORG_PRFL | DIR_DOB | 1:1 | DIR_DOB | DATE |  | BDAY_DIRECTOR | DIR_DOB |
| IP_ALT_IDENTN | IDENTN_NBR | 1:1 | NAT_ID_NBR | VARCHAR2 | 100 | Mã quốc gia | NAT_ID_NBR |
| CST | CHKER_OFCR_CODE | 1:1 | SCD_OFCR_CODE | VARCHAR2 | 20 | Mã nhân viên hạch toán thứ 2 | SCD_OFCR_CODE |
| IP_ALT_IDENTN | ISSU_PLC_CODE | 1:1 | ISSU_PLC_CODE | VARCHAR2 | 20 | Nơi cấp Căn cước | ISSU_PLC_CODE |
| ORG_PRFL | CNTCT_PRSN | 1:1 | CNTCT_PRSN | VARCHAR2 | 40 | CONTACT_PERSON | CNTCT_PRSN |
| ORG_PRFL | MBL_BNKG_F | 1:1 | MBL_BNKG_F | VARCHAR2 | 20 | Đánh dấu sử dụng dịch vụ mobile banking | MBL_BNKG_F |
| ORG_PRFL | INN_BNKG_F | 1:1 | INN_BNKG_F | VARCHAR2 | 20 | Đánh dấu sử dụng dịch vụ internet banking | INN_BNKG_F |
| ORG_PRFL | AML_RSLT | 1:1 | AML_RSLT | VARCHAR2 | 100 | Liên quan tới hệ thống Phòng Chống rửa tiền | AML_RSLT |
| ORG_PRFL | AML_CHK_F | 1:1 | AML_CHK_F | VARCHAR2 | 20 | Đánh dấu liên quan tới hệ thống Phòng Chống rửa tiền | AML_CHK_F |
| ORG_PRFL | CST_CODE | NULL | IDV_EMP_ST_CODE | VARCHAR2 | 20 | Tình trạng làm việc | IDV_EMP_ST_CODE |
| ORG_PRFL | JNT_LBY_F | 1:1 | JNT_LBY_F | VARCHAR2 | 20 | Đánh dấu nợ liên đới | JNT_LBY_F |
| ORG_PRFL | MB_CR_ST | 1:1 | MB_CR_ST | VARCHAR2 | 20 | MB_CR_STT | MB_CR_ST |
| ORG_PRFL | CST_FNC_ST_CODE | 1:1 | CST_FNC_ST_CODE | VARCHAR2 | 20 | Nhóm nợ khách hàng Core tính | CST_FNC_ST_CODE |
| ORG_PRFL | CST_CODE | NULL | ANUL_INCM | NUMBER | 25.5 | Thu nhập theo tháng | ANUL_INCM |
| CST | SRC_DT_TM | 1:1 | SRC_DT_TM | DATE |  | DATE_TIME | SRC_DT_TM |
| IP_PST_ADR | PROV_NM | d1.PROV_NM | PROV_NM | VARCHAR2 | 100 | Tỉnh/thành phố nơi cư trú | PROV_NM |
| ORG_PRFL | IDY_LV1_CL_CODE | 1:1 | IDY_LV1_CL_CODE | VARCHAR2 | 20 | Mã ngành nghê kinh tế cha | IDY_LV1_CL_CODE |
| CST | REFR_CODE | 1:1 | REFR_CODE | VARCHAR2 | 40 | Mã người tham chiếu/giới thiệu | REFR_CODE |
| ORG_PRFL | CNTCT_PRSN_PHN | 1:1 | CNTCT_PRSN_PHN | VARCHAR2 | 100 | PHONE_CONT_PER | CNTCT_PRSN_PHN |
| CST | CTR_TMPL_CODE | 1:1 | CTR_TMPL_CODE | VARCHAR2 | 100 | MAU_HD | CTR_TMPL_CODE |
| IP_PST_ADR | PROV_NM | d2.PROV_NM | CITY_NM | VARCHAR2 | 100 | Tên thành phố theo địa chỉ | CITY_NM |
| IP_PST_ADR | CST_CODE | NULL | VSS_CODE | VARCHAR2 | 40 | Mã bảo hiểm xã hội | VSS_CODE |
| CST | CRS_SELL_RM_CODE | 1:1 | CRS_SELL_RM_CODE | VARCHAR2 | 100 | MB_RM_BANCHEO | CRS_SELL_RM_CODE |
| IP_ELC_ADR | ELC_ADR_VAL | c2.ELC_ADR_VAL | HM_NBR | VARCHAR2 | 100 | Số điện thoại nhà riêng | HM_NBR |
| IP_ELC_ADR | ELC_ADR_VAL | c3.ELC_ADR_VAL | MBL_NBR | VARCHAR2 | 100 | Số điện thoại di động | MBL_NBR |
| ORG_PRFL | IDY_LV2_CL_CODE | 1:1 | IDY_LV2_CL_CODE | VARCHAR2 | 20 | Ngành nghề kinh tế | IDY_LV2_CL_CODE |
