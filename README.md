# Python ETL pipeline using Airflow on AWS
This project demonstrates how to build and automate an ETL pipeline written in Python and schedule it using open source Apache Airflow orchestration tool on AWS EC2 instance.


# Project Goals 

1. Data Ingestion - Create a data ingestion pipeline to extract data from OpenWeather API.
2. Data Storage - Create a data storage repository using AWS S3 buckets.
3. Data Transformation - Create ETL job to extract the data, do simple transformations and load the clean data using Airflow.
4. Data Pipeline - Create a data pipeline written in Python that extracts data from API calls and store it in AWS S3 buckets.
5. Pipeline Automation - Create scheduling service using Apace Airflow to trigger the data pipeline and automate the process.



# Data Architecture

The architecture (Data flow) used in this project uses different Open source and cloud components as described below:

<p align="center">
  <img width="1000" height="550" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/a63db442-0e05-48e9-9c03-27d808053c09">
  <h6 align = "center" > Source: Author </h6>
</p>

# Dataset Used

In this project, we are building a data pipeline that extracts data through an API call to Openweathermap. API calls are made using Airflow through HTTPoperator. 
The API call looks something like this : 
```python
https://api.openweathermap.org/data/2.5/weather?q={city name}&appid={API key}
```

where there are two parameters
1. q - City name: Takes the name of any city in the world, the name goes in lowercase
2. API key - It can be obtained after creating an account on Openweathermap.org. The API key is unique to each account, make sure you do not share it.

The resulting data is in json format with the following structure with an example call of London city: 

```
https://api.openweathermap.org/data/2.5/weather?q=London&appid={API key}
```

```json
     {
     "coord": {
       "lon": -0.13,
       "lat": 51.51
     },
     "weather": [
       {
         "id": 300,
         "main": "Drizzle",
         "description": "light intensity drizzle",
         "icon": "09d"
       }
     ],
     "base": "stations",
     "main": {
       "temp": 280.32,
       "pressure": 1012,
       "humidity": 81,
       "temp_min": 279.15,
       "temp_max": 281.15
     },
     "visibility": 10000,
     "wind": {
       "speed": 4.1,
       "deg": 80
     },
     "clouds": {
       "all": 90
     },
     "dt": 1485789600,
     "sys": {
       "type": 1,
       "id": 5091,
       "message": 0.0103,
       "country": "GB",
       "sunrise": 1485762037,
       "sunset": 1485794875
     },
     "id": 2643743,
     "name": "London",
     "cod": 200
     }
```


# Tools used in this project

1. **Apache Airflow** - It is basically an open source orchestration or some might say a workflow tool that allows one to programatically author, maintain, monitor and schedule workflows. It is one of the mnost commonly used workflow tools for data engineering purposes. It is highly scalable and comes with standalone service as well as containarized service as well. We can easily visualize our data pipelines' dependencies, progress, logs, code, trigger tasks, and success status.
2. **AWS EC2** - Amazon Elastic Compute Cloud (Amazon EC2) is a web service that provides secure, resizable compute capacity in the cloud. It is a virtual environment where users run their own applications while the system is completely managed by Amazon. A user can create, launch, and terminate server-instances as needed, paying by the second for active servers – hence the term "elastic". EC2 provides users with control over the geographical location of instances that allows for latency optimization and high levels of redundancy.
3. **AWS S3** - Amazon Simple Storage Service (Amazon S3) is a storage service that offers high scalability, data availability, security, and performance. It stores the data as objects within buckets and is readily available for integration with thousands of applications. An object is a file and any metadata that describes the file. A bucket is a container for objects.

# Implementation

* **Step 1** - Since all the computations and code will be written in a virtual environment. The first task is to commission AWS EC2 VM and install python dependencies along with airflow and pandas. We will create a python virtual envionrment and install all the dependencies inside that environment such that our process is contained in a safe environment. This will our airflow server and we will be running airflow standalone in this machine. 

<p align="center">
  <img width="650" height="500" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/6d0500b7-06e9-464a-b343-89c32e56dfda">
  <h6 align = "center" > Source: Author </h6>
</p>

Airflow has four core components that are important for its function:
1. Airflow webserver -  A Flask server running with Gunicorn that serves the Airflow UI.  
2. Airflow scheduler - A Daemon responsible for scheduling jobs. This is a multi-threaded Python process that determines what tasks need to be run, when they need to be run, and where they run.
3. Airflow database - A database where all DAG and task metadata are stored. This is typically a Postgres database, but MySQL, MsSQL, and SQLite are also supported.
4. Airflow executor - The mechanism for running tasks. An executor is running within the scheduler whenever Airflow is operational.

An airflow UI is generated when the webserver is up and running with some pre-defined DAGs as shown below:

<p align="center">
  <img  height="500" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/b85b7b02-deed-4dc3-93e5-a373e79d74a2">
  <h6 align = "center" > Source: Author </h6>
</p>




* **Step 2** - In order for airflow to make API calls to open weather, there needs to be a connection between two services which can be done using 'connections' tab in airflow. This will allow airflow to access openweather map using HTTP operator.

<p align="center">
  <img  height="500" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/55509511-414a-438a-9612-5b9168a7ec23">
  <h6 align = "center" > Source: Author </h6>
</p>

* **Step 3** - It is time to create our first DAG (Directed Acyclic Graph) with proper imports and dependencies. This step is subdivided into three steps each accounting for a task within our DAG. Create dag file for example weather_dag.py and add the required import and libraries:
  
      ```Pyhton
      from airflow import DAG
      from datetime import timedelta, datetime
      from airflow.providers.http.sensors.http import HttpSensor
      from airflow.providers.http.operators.http import SimpleHttpOperator
      from airflow.operators.python_operator import PythonOperator
      import pandas as pd
      import json
      ``` 
      Every DAG has some default arguments needed to run tasks according to the settings, you can set the default_args as following:
      ```Python
      default_args = {
      "owner":"airflow",
      "depends_on_past": False,
      "start_date": datetime(2023,1,1),
      "email": ['myemail@domain.com'],
      "email_on_failure": True,
      "email_on_retry": False,
      "retries": 2,
      "retry_delay": timedelta(minutes=3),}
      ```
     * **Task 1** - Tasks are written inside the DAGs using operators. Here, we use the *HTTPSensor* Operator to check if the API is callable or not. You use your API key and choose any city in which you are interested.
      
      ```Python
      with DAG("weather_dag",
         default_args = default_args,
         schedule_interval= "@hourly",
         catchup=False,) as dag:
    

        is_weather_api_available = HttpSensor(
            task_id = "is_weather_api_available",
            endpoint = "data/2.5/weather?q=Stockholm&appid=<API Key>",
            http_conn_id='weather_map_api')
      
      ```
  
  * **Task 2** - This task calls the weather API and invokes a GET method to get the data in json format. We use a lambda function to convert the load into a text.


      ```Python
      extract_weather_data = SimpleHttpOperator(
            task_id = "extract_weather_data",
            http_conn_id="weather_map_api",
            endpoint = "data/2.5/weather?q=Stockholm&appid=<API Key>",
            method= "GET",
            response_filter = lambda r:json.loads(r.text),
            log_response = True,
        )
      ```

  * **Task 3** - This task calls a python function that transforms the json format into csv file and store it in AWS S3 buckets. You can define the schedule intervals in which you want to execute your DAG, based on default_args.


      ```Python
      transform_load_weather_data = PythonOperator(
            task_id = "transform_load_weather_data",
            python_callable= transform_load_data,
        )
      ```
  After implementing above step, if we go over to Airflow UI, we can see the tasks inside DAG, the directed chain is achieved by adding tasks ordering at the end of the DAG.
 <h4 align ='center' >   is_weather_api_available >> extract_weather_data >> transform_load_weather_data </h4>
  
<p align="center">
  <img  height="500" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/1e3c5466-256f-47ed-a926-5cb69c0f2663">
  <h6 align = "center" > Source: Author </h6>
</p>

* **Step 4** - We can write the tranform function and give appropriate permissions to airflow for using AWS S3 and proper session credentials. For every transaction, AWS creates a session window that allows a service to interact with AWS components.

<p align="center">
  <img  height="600" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/d142838b-1643-4498-b952-56c35fd89569">
  <h6 align = "center" > Source: Author </h6>
</p>  


* **Step 5** - Now, we can see that, we have csv files stored in AWS S3 buckets using data pipeline that we just created.
<p align="center">
  <img  height="600" src="https://github.com/chayansraj/Python-ETL-pipeline-using-Airflow-on-AWS/assets/22219089/d9ab4360-badf-49fc-be86-eddf0f6ceb57">
  <h6 align = "center" > Source: Author </h6>
</p>  



