from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

from pyspark.sql import SparkSession


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a Spark SQL file")
    parser.add_argument("--sql-file", required=True)
    parser.add_argument("--etl-date", required=True)
    return parser.parse_args()


def split_statements(text: str) -> list[str]:
    lines = [line for line in text.splitlines() if not line.lstrip().startswith("--")]
    return [s.strip() for s in "\n".join(lines).split(";") if s.strip()]


def main() -> None:
    args = parse_args()
    date.fromisoformat(args.etl_date)
    text = Path(args.sql_file).read_text(encoding="utf-8-sig")
    text = re.sub(r"\$\{ETL_DATE\}", args.etl_date, text)

    spark = SparkSession.builder.appName(f"run-sql-{Path(args.sql_file).stem}").getOrCreate()
    try:
        for statement in split_statements(text):
            spark.sql(statement)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
