from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class BronzeTable:
    source_schema: str
    source_table: str
    target_name: str

    @property
    def target_table(self) -> str:
        return f"iceberg.pg_bronze.{self.target_name}"

    @property
    def task_id(self) -> str:
        return self.target_name


BRONZE_TABLES: list[BronzeTable] = [
    BronzeTable("PG_EBANKING", "COL_UDF_VALUE", "ebanking_col_udf_value"),
    BronzeTable("PG_FLEXBO", "PGBLD_CONTRACT_UDFIELD_HIST", "flexbo_pgbld_contract_udfield_hist"),
    BronzeTable("PG_FLEXBO", "PGBLD_RT_CONTRACT_UDFIELD_HIST", "flexbo_pgbld_rt_contract_udfield_hist"),
    BronzeTable("PG_FLEXBO", "PGB_CONTRACT_UDF_MAP", "flexbo_pgb_contract_udf_map"),
    BronzeTable("PG_FLEXBO", "PGB_LDTB_CONTRACT_MASTER", "flexbo_pgb_ldtb_contract_master"),
    BronzeTable("PG_FLEXBO", "PGB_LOS_CONTRACT_FIELDS_TDATE", "flexbo_pgb_los_contract_fields_tdate"),
    BronzeTable("PG_LOS_APP", "FACILITY", "los_app_facility"),
    BronzeTable("PG_LOS_APP", "LOAN_DISBURSEMENT", "los_app_loan_disbursement"),
    BronzeTable("PG_LOS_APP", "PRODUCT", "los_app_product"),
    BronzeTable("PG_SMY", "STMT_ENTRY_LOAN_GRA", "smy_stmt_daily"),
    BronzeTable("PG_SOURCE", "SAOKE_CRB", "source_saoke_crb"),
    BronzeTable("PG_SOURCE", "SAOKE_MVMT", "source_saoke_mvmt"),
    BronzeTable("PG_T24CORE", "COMPANY", "t24core_company"),
    BronzeTable("PG_T24CORE", "CURRENCY", "t24core_currency"),
    BronzeTable("PG_T24CORE", "CURRENCY_HIS", "t24core_currency_his"),
    BronzeTable("PG_T24CORE", "CUSTOMER", "t24core_customer"),
    BronzeTable("PG_T24CORE", "DEPT_ACCT_OFFICER", "t24core_dept_acct_officer"),
    BronzeTable("PG_T24CORE", "LD_LOANS_AND_DEPOSITS", "t24core_ld_loans_and_deposits"),
    BronzeTable("PG_T24CORE", "LD_LOANS_AND_DEPOSITS_HIS", "t24core_ld_loans_and_deposits_his"),
    BronzeTable("PG_T24CORE", "LD_SCHEDULE_DEFINE_MV", "t24core_ld_schedule_define_mv"),
    BronzeTable("PG_T24CORE", "LIMIT", "t24core_limit"),
    BronzeTable("PG_T24CORE", "MB_MG_SAVING_MULTI", "t24core_mb_mg_saving_multi"),
    BronzeTable("PG_T24CORE", "PD_PAYMENT_DUE", "t24core_pd_payment_due"),
    BronzeTable("PG_T24CORE", "PD_PAYMENT_DUE_HIS", "t24core_pd_payment_due_his"),
    BronzeTable("PG_T24CORE", "PD_PAYMENT_DUE_HIS_MV", "t24core_pd_payment_due_his_mv"),
    BronzeTable("PG_T24CORE", "PD_PAYMENT_DUE_MV", "t24core_pd_payment_due_mv"),
    BronzeTable("PG_T24CORE", "SECTOR", "t24core_sector"),
    BronzeTable("PG_T24CORE", "STMT_ENTRY", "t24core_stmt_entry"),
]
