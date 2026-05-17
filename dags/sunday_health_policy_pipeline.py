from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


default_args = {
    "owner": "sunday-data-engineering",
    "retries": 0,
}


with DAG(
    dag_id="sunday_health_policy_pipeline",
    description="Load bronze data, transform silver tables, validate, and run reports.",
    default_args=default_args,
    start_date=datetime(2021, 1, 1),
    schedule="0 1 * * *",
    catchup=False,
    tags=["sunday", "health-policy", "assignment"],
) as dag:
    load_and_transform = BashOperator(
        task_id="load_bronze_and_transform_silver",
        bash_command="python /opt/airflow/src/pipeline.py --reset --seed --transform",
    )

    run_data_quality_checks = BashOperator(
        task_id="run_data_quality_checks",
        bash_command="python /opt/airflow/src/pipeline.py --validate",
    )

    run_reporting_queries = BashOperator(
        task_id="run_reporting_queries",
        bash_command="python /opt/airflow/src/pipeline.py --reports",
    )

    load_and_transform >> run_data_quality_checks >> run_reporting_queries
