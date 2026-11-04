-- Active: 1793162562206@@192.168.26.180@1521
-- Kiểm tra 28 bảng nguồn có tồn tại trên Oracle hay không.
-- Kết quả mong đợi: 28 dòng.

SELECT
    owner,
    table_name
FROM all_tables
WHERE
       (owner = 'PG_EBANKING' AND table_name IN ('COL_UDF_VALUE'))
    OR (owner = 'PG_FLEXBO' AND table_name IN (
            'PGBLD_CONTRACT_UDFIELD_HIST',
            'PGBLD_RT_CONTRACT_UDFIELD_HIST',
            'PGB_CONTRACT_UDF_MAP',
            'PGB_LDTB_CONTRACT_MASTER',
            'PGB_LOS_CONTRACT_FIELDS_TDATE'
       ))
    OR (owner = 'PG_LOS_APP' AND table_name IN (
            'FACILITY',
            'LOAN_DISBURSEMENT',
            'PRODUCT'
       ))
    OR (owner = 'PG_SMY' AND table_name IN ('STMT_ENTRY_LOAN_GRA'))
    OR (owner = 'PG_SOURCE' AND table_name IN (
            'SAOKE_CRB',
            'SAOKE_MVMT'
       ))
    OR (owner = 'PG_T24CORE' AND table_name IN (
            'COMPANY',
            'CURRENCY',
            'CURRENCY_HIS',
            'CUSTOMER',
            'DEPT_ACCT_OFFICER',
            'LD_LOANS_AND_DEPOSITS',
            'LD_LOANS_AND_DEPOSITS_HIS',
            'LD_SCHEDULE_DEFINE_MV',
            'LIMIT',
            'MB_MG_SAVING_MULTI',
            'PD_PAYMENT_DUE',
            'PD_PAYMENT_DUE_HIS',
            'PD_PAYMENT_DUE_HIS_MV',
            'PD_PAYMENT_DUE_MV',
            'SECTOR',
            'STMT_ENTRY'
       ))
ORDER BY
    owner,
    table_name;
