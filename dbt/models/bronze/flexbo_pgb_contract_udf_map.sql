{#- Nguồn Oracle PG_FLEXBO.PGB_CONTRACT_UDF_MAP -> iceberg.pg_bronze.flexbo_pgb_contract_udf_map (mirror 1:1, mọi cột STRING). -#}
SELECT
    src.`CONTRACT_REF_NO`,
    src.`FIELD_NAME`,
    src.`FIELD_VAL`,
    {{ etl_date() }} AS ETL_DATE,
    CURRENT_TIMESTAMP() AS INGEST_TMS,
    'FLEXBO_PGB_CONTRACT_UDF_MAP' AS SRC_STM_CODE
FROM {{ source('oracle_flexbo', 'PGB_CONTRACT_UDF_MAP') }} AS src
