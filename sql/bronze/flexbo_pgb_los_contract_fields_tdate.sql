-- Source: PG_FLEXBO.PGB_LOS_CONTRACT_FIELDS_TDATE
-- Target: iceberg.pg_bronze.flexbo_pgb_los_contract_fields_tdate
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgb_los_contract_fields_tdate
SELECT
    src.`LOS_CONTRACT_CODE`,
    src.`MOV_DATE`,
    src.`MDVAY_SP`,
    src.`MDVAY_NKT`,
    src.`CAR_APPLICATION_CODE`,
    src.`CAN_BO_DE_XUAT_GN`,
    src.`TT_PP_DE_XUAT_GN`,
    src.`CONTRACT_REF_NO`,
    src.`BDS_TT11`,
    CAST(src.`BIEN_DO_THAY_DOI_LS_THEO_HDTD` AS STRING) AS `BIEN_DO_THAY_DOI_LS_THEO_HDTD`,
    src.`CAP_PHE_DUYET_GNTL`,
    src.`CBTD_QL_KHOAN_VAY`,
    src.`CO_CAU_NO_MIEN_GIAM_LAI`,
    src.`CT_KHUYEN_MAI_CHO_VAY`,
    src.`CTKM2`,
    src.`LOAI_CHUNG_KHOAN`,
    CAST(src.`LOS_CONTRACT_ID` AS STRING) AS `LOS_CONTRACT_ID`,
    src.`SAN_PHAM_CHO_VAY_KHCN`,
    src.`SAN_PHAM_CHO_VAY_KHDN`,
    CAST(src.`SO_LAN_CO_CAU` AS STRING) AS `SO_LAN_CO_CAU`,
    src.`TP_PP_QL_KHOAN_VAY`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGB_LOS_CONTRACT_FIELDS_TDATE AS src;
