from __future__ import annotations

from dotenv import load_dotenv

from common.database.oracle_connection import OracleConnection


SOURCE_TABLES = (
    ("PG_EBANKING", "COL_UDF_VALUE"),
    ("PG_FLEXBO", "PGBLD_CONTRACT_UDFIELD_HIST"),
    ("PG_FLEXBO", "PGBLD_RT_CONTRACT_UDFIELD_HIST"),
    ("PG_FLEXBO", "PGB_CONTRACT_UDF_MAP"),
    ("PG_FLEXBO", "PGB_LDTB_CONTRACT_MASTER"),
    ("PG_FLEXBO", "PGB_LOS_CONTRACT_FIELDS_TDATE"),
    ("PG_LOS_APP", "FACILITY"),
    ("PG_LOS_APP", "LOAN_DISBURSEMENT"),
    ("PG_LOS_APP", "PRODUCT"),
    ("PG_SMY", "STMT_ENTRY_LOAN_GRA"),
    ("PG_SOURCE", "SAOKE_CRB"),
    ("PG_SOURCE", "SAOKE_MVMT"),
    ("PG_T24CORE", "COMPANY"),
    ("PG_T24CORE", "CURRENCY"),
    ("PG_T24CORE", "CURRENCY_HIS"),
    ("PG_T24CORE", "CUSTOMER"),
    ("PG_T24CORE", "DEPT_ACCT_OFFICER"),
    ("PG_T24CORE", "LD_LOANS_AND_DEPOSITS"),
    ("PG_T24CORE", "LD_LOANS_AND_DEPOSITS_HIS"),
    ("PG_T24CORE", "LD_SCHEDULE_DEFINE_MV"),
    ("PG_T24CORE", "LIMIT"),
    ("PG_T24CORE", "MB_MG_SAVING_MULTI"),
    ("PG_T24CORE", "PD_PAYMENT_DUE"),
    ("PG_T24CORE", "PD_PAYMENT_DUE_HIS"),
    ("PG_T24CORE", "PD_PAYMENT_DUE_HIS_MV"),
    ("PG_T24CORE", "PD_PAYMENT_DUE_MV"),
    ("PG_T24CORE", "SECTOR"),
    ("PG_T24CORE", "STMT_ENTRY"),
)


def test_oracle_source_tables() -> None:
    load_dotenv()
    oracle = OracleConnection.from_environment()
    connection = oracle.connect()

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1 FROM dual")
            assert cursor.fetchone()[0] == 1

            missing_tables = []
            for owner, table_name in SOURCE_TABLES:
                cursor.execute(
                    """
                    SELECT 1
                    FROM all_tables
                    WHERE owner = :owner
                      AND table_name = :table_name
                    """,
                    owner=owner,
                    table_name=table_name,
                )
                if cursor.fetchone() is None:
                    missing_tables.append(f"{owner}.{table_name}")

            assert not missing_tables, (
                "Missing Oracle source tables: "
                + ", ".join(missing_tables)
            )
    finally:
        oracle.close()


if __name__ == "__main__":
    test_oracle_source_tables()
    print(f"Oracle connection and {len(SOURCE_TABLES)} source tables succeeded")
