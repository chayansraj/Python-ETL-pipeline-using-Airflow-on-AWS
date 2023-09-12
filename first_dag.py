from airflow import DAG





default_args = {
    "owner":"airflow",
    "depends_on_past": False,
    "start_date": datetime(2023,1,1),
    "email": ['myemail@domain.com'],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2)
}