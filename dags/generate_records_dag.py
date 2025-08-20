from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from generate_records_api import fetch_random_users, upload_to_rds

dag = DAG(
    dag_id='random_api_user_dag',
    start_date=datetime(2023, 1, 1),
    schedule_interval='@daily', 
    catchup=False,
)

generate_data = PythonOperator(
    task_id='data_from_api',
    python_callable=fetch_random_users,
    dag=dag,
)

upload_data_to_rds = PythonOperator(
    task_id='upload_to_rds',
    python_callable=upload_to_rds,
    dag=dag,
)

generate_data >> upload_data_to_rds