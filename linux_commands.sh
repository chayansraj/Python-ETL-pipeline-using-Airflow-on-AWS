update EC2 instance - sudo apt update
Install python inside VM - sudo apt install python3-pip
Install python virtual environment - sudo apt install python3.10-venv
Create python virtual environment - python3 -m venv airflow_venv
Activate your virtual environment - source airflow_venv/bin/activate
install pandas package - sudo pip install pandas


# Airflow commands
source <airflow_python_environment>/bin/activate
airflow standalone
airflow webserver
airflow scheduler


# Linux processes
ps -ef
kill pid