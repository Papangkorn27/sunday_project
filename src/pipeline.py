from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable

import psycopg
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = PROJECT_ROOT / "sql"


SQL_FILES = {
    "bronze_ddl": SQL_DIR / "01_bronze_ddl.sql",
    "silver_ddl": SQL_DIR / "02_silver_ddl.sql",
    "seed_bronze": SQL_DIR / "04_example_data_bronze.sql",
    "transform_silver": SQL_DIR / "05_transform_silver.sql",
    "quality_checks": SQL_DIR / "06_data_quality_checks.sql",
    "reports": SQL_DIR / "03_business_reporting.sql",
}


def load_config() -> None:
    load_dotenv(PROJECT_ROOT / ".env")


def connection_kwargs() -> dict[str, str | int]:
    if database_url := os.getenv("DATABASE_URL"):
        return {"conninfo": database_url}

    return {
        "host": os.getenv("POSTGRES_HOST", "localhost"),
        "port": int(os.getenv("POSTGRES_PORT", "5432")),
        "dbname": os.getenv("POSTGRES_DB", "sunday_assignment"),
        "user": os.getenv("POSTGRES_USER", "sunday"),
        "password": os.getenv("POSTGRES_PASSWORD", "sunday_local_password"),
    }


def read_sql(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def execute_file(conn: psycopg.Connection, key: str) -> None:
    path = SQL_FILES[key]
    print(f"Running {path.relative_to(PROJECT_ROOT)}")
    conn.execute(read_sql(path))


def split_report_queries(sql: str) -> Iterable[str]:
    for chunk in sql.split(";"):
        query = chunk.strip()
        if query:
            yield query


def print_rows(title: str, columns: list[str], rows: list[tuple]) -> None:
    print(f"\n{title}")
    print("-" * len(title))
    print(" | ".join(columns))
    for row in rows:
        print(" | ".join("" if value is None else str(value) for value in row))


def run_reports(conn: psycopg.Connection) -> None:
    for index, query in enumerate(split_report_queries(read_sql(SQL_FILES["reports"])), start=1):
        with conn.cursor() as cur:
            cur.execute(query)
            rows = cur.fetchall()
            columns = [description.name for description in cur.description]
        print_rows(f"Report {index}", columns, rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Sunday Part 2 health policy ETL.")
    parser.add_argument("--reset", action="store_true", help="Recreate bronze and silver schemas.")
    parser.add_argument("--seed", action="store_true", help="Load example source data into bronze tables.")
    parser.add_argument("--transform", action="store_true", help="Transform bronze data into silver tables.")
    parser.add_argument("--validate", action="store_true", help="Run data quality checks.")
    parser.add_argument("--reports", action="store_true", help="Run business reporting queries.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    load_config()

    should_transform = args.transform or args.reset or args.seed

    with psycopg.connect(**connection_kwargs(), autocommit=True) as conn:
        if args.reset:
            execute_file(conn, "bronze_ddl")
            execute_file(conn, "silver_ddl")

        if args.seed:
            execute_file(conn, "seed_bronze")

        if should_transform:
            execute_file(conn, "transform_silver")

        if args.validate:
            execute_file(conn, "quality_checks")
            print("Data quality checks passed.")

        if args.reports:
            run_reports(conn)

    print("\nPipeline completed successfully.")


if __name__ == "__main__":
    main()
