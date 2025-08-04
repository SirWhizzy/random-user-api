"""
Airflow DAG to generate random user data and upload to S3.
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
import boto3
import awswrangler as wr
from datetime import datetime, timedelta
import os
from generate_records import upload_to_aws


default_args = {
    'owner': 'airflow',
}

dag = DAG(
    dag_id='generate_and_upload_random_data',
    default_args=default_args,
    start_date=datetime(2023, 1, 1),
    schedule_interval='@daily', 
    catchup=False,
)

generate_and_upload_data = PythonOperator(
    task_id='generate_data',
    python_callable=upload_to_aws,
    dag=dag,
)


generate_and_upload_data
