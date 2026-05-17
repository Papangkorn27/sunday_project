# Sunday Assignment Part 2 - Data Pipeline and Data Modeling

This project implements the Part 2 bonus for the Sunday Data Engineer assignment. It provides PostgreSQL DDL, a normalized silver data model, business reporting SQL, a Python ETL pipeline, and a local Airflow scheduler.

## Architecture

- `bronze` schema keeps source-aligned tables.
- `silver` schema keeps cleaned relational tables for reporting.
- `src/pipeline.py` runs the local ETL workflow.
- `dags/sunday_health_policy_pipeline.py` schedules the same workflow in Airflow.
- `docker-compose.yml` starts one PostgreSQL container plus Airflow services.
- `Dockerfile.airflow` builds a small local Airflow image with the Python pipeline dependencies installed.

The local stack uses one PostgreSQL container with two databases:

- `sunday_assignment` for assignment data.
- `airflow_metadata` for Airflow metadata.

## Prerequisites

- `uv`
- Docker Desktop or OrbStack
- Docker Compose v2

Before running Docker commands, make sure the Docker daemon is running.

## Setup

Create the local Python environment:

```bash
UV_CACHE_DIR=.uv-cache uv venv
UV_CACHE_DIR=.uv-cache uv sync
```

Create local secrets:

```bash
cp .env.example .env
```

Update `.env` if you want different database or Airflow credentials. The real `.env` file is ignored by Git.

## Run PostgreSQL

```bash
docker compose up -d --build postgres
```

Check service health:

```bash
docker compose ps
```

## Run the Pipeline Manually

```bash
UV_CACHE_DIR=.uv-cache uv run python src/pipeline.py --reset --seed --validate --reports
```

This command:

1. Recreates bronze and silver schemas.
2. Loads sample source data into bronze.
3. Transforms bronze data into silver.
4. Runs data quality checks.
5. Runs the three reporting queries.

## Run Airflow

Initialize Airflow:

```bash
docker compose up airflow-init
```

Start the webserver and scheduler:

```bash
docker compose up -d airflow-webserver airflow-scheduler
```

Open Airflow:

```text
http://localhost:8080
```

Default local credentials come from `.env`.

Test the DAG from the Airflow container:

```bash
docker compose exec airflow-scheduler airflow dags test sunday_health_policy_pipeline 2026-05-17
```

The DAG runs:

```text
load_bronze_and_transform_silver
  -> run_data_quality_checks
  -> run_reporting_queries
```

## Expected Sample Results

For the provided sample data:

- The most popular plans for `AAA Co` are `A` and `B`, tied with 3 covered members each.
- Covered customers by preferred hospital on `2021-02-01`:
  - `Rajvithi`: 3
  - `Siriraj`: 3
  - `Rama`: 2
- Tenure is calculated from each member's earliest coverage start date to latest coverage end date.

## Data Quality Checks

`sql/06_data_quality_checks.sql` validates:

- Policy effective date is not after expiry date.
- Company name is present.
- Member national ID is present.
- Gender is `M`, `F`, or null.
- Source plan codes exist in `bronze.plan_list`.
- Member coverage dates are within policy dates.
- Employee additions expire on the same date as the main policy.
- Duplicate policy-member records are prevented.

## Design Assumptions

- `company_name` is treated as unique because no company registration ID is provided.
- Source employee ID is treated as `national_id`.
- Customer list records start on the main policy effective date.
- Employee addition records start on their own effective date.
- Employee additions expire on the main policy expiry date.
- `BKK` and `Bkk` are standardized to `Bangkok`.
- Known hospital typos are standardized in silver; currently `Siriaj` is mapped to `Siriraj`.
- No employee removal is required.

## Useful Commands

Stop services:

```bash
docker compose down
```

Reset all container data:

```bash
docker compose down --volumes --remove-orphans
```

Validate Compose syntax:

```bash
docker compose config --quiet
```

Compile Python files:

```bash
UV_CACHE_DIR=.uv-cache uv run python -m compileall src dags
```
