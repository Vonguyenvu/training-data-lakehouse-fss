from __future__ import annotations

import argparse
import os
import re
from datetime import date

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F


IDENTIFIER = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load one Oracle table to Iceberg Bronze")
    parser.add_argument("--source-schema", required=True)
    parser.add_argument("--source-table", required=True)
    parser.add_argument("--target-table", required=True)
    parser.add_argument("--etl-date", required=True)
    return parser.parse_args()


def validate_identifier(value: str, name: str) -> str:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"Invalid {name}: {value!r}")
    return value.upper()


def read_oracle_table(
    spark: SparkSession,
    source_schema: str,
    source_table: str,
) -> DataFrame:
    return (
        spark.read.format("jdbc")
        .option("url", os.environ["ORACLE_JDBC_URL"])
        .option("dbtable", f"{source_schema}.{source_table}")
        .option("user", os.environ["ORACLE_USERNAME"])
        .option("password", os.environ["ORACLE_PASSWORD"])
        .option("driver", "oracle.jdbc.OracleDriver")
        .option("fetchsize", os.getenv("ORACLE_FETCH_SIZE", "10000"))
        .load()
    )


def load_to_bronze(
    spark: SparkSession,
    source_schema: str,
    source_table: str,
    target_table: str,
    etl_date: str,
) -> None:
    source_schema = validate_identifier(source_schema, "source_schema")
    source_table = validate_identifier(source_table, "source_table")
    target_parts = target_table.split(".")
    if len(target_parts) != 3:
        raise ValueError("target_table must be catalog.schema.table")
    target_table = ".".join(
        validate_identifier(part, "target_table")
        for part in target_parts
    )
    date.fromisoformat(etl_date)

    source_df = read_oracle_table(spark, source_schema, source_table)
    bronze_df = (
        source_df
        .withColumn("ETL_DATE", F.to_date(F.lit(etl_date)))
        .withColumn("INGEST_TMS", F.current_timestamp())
        .withColumn("SRC_STM_CODE", F.lit(f"{source_schema}_{source_table}"))
        .cache()
    )

    row_count = bronze_df.count()

    if spark.catalog.tableExists(target_table):
        bronze_df.writeTo(target_table).overwritePartitions()
    else:
        (
            bronze_df.writeTo(target_table)
            .using("iceberg")
            .tableProperty("format-version", "2")
            .partitionedBy("ETL_DATE")
            .create()
        )

    bronze_df.unpersist()
    print(f"Loaded {row_count:,} rows into {target_table}")


def main() -> None:
    args = parse_args()
    spark = (
        SparkSession.builder
        .appName(f"oracle-to-bronze-{args.source_table}")
        .getOrCreate()
    )
    try:
        load_to_bronze(
            spark,
            args.source_schema,
            args.source_table,
            args.target_table,
            args.etl_date,
        )
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
