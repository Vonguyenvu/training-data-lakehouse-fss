-- Source: PG_FLEXBO.PGB_LOS_CONTRACT_FIELDS_TDATE
-- Target: iceberg.pg_bronze.flexbo_pgb_los_contract_fields_tdate
-- Yêu cầu: đã chạy schema/bronze.sql; catalog JDBC `oracle` khai báo trong spark-defaults.conf.
-- INSERT OVERWRITE chỉ ghi đè partition ETL_DATE (spark.sql.sources.partitionOverwriteMode=dynamic).

INSERT OVERWRITE iceberg.pg_bronze.flexbo_pgb_los_contract_fields_tdate
SELECT
    src.`BDS_TT11`,
    src.`BIEN_DO_THAY_DOI_LS_THEO_HDTD`,
    src.`CAN_BO_DE_XUAT_GN`,
    src.`CAP_PHE_DUYET_GNTL`,
    src.`CAR_APPLICATION_CODE`,
    src.`CBTD_QL_KHOAN_VAY`,
    src.`CONTRACT_REF_NO`,
    src.`CO_CAU_NO_MIEN_GIAM_LAI`,
    src.`LOS_CONTRACT_CODE`,
    src.`LOS_CONTRACT_ID`,
    src.`MDVAY_NKT`,
    src.`MDVAY_SP`,
    src.`MOV_DATE`,
    src.`SAN_PHAM_CHO_VAY_KHCN`,
    src.`SAN_PHAM_CHO_VAY_KHDN`,
    src.`SO_LAN_CO_CAU`,
    src.`TP_PP_QL_KHOAN_VAY`,
    src.`TT_PP_DE_XUAT_GN`,
    CAST('${ETL_DATE}' AS DATE) AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_LOS_CONTRACT_FIELDS_TDATE' AS SRC_STM_CODE
FROM oracle.PG_FLEXBO.PGB_LOS_CONTRACT_FIELDS_TDATE AS src;
