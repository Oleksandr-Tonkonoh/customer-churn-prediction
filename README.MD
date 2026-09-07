# Customer Churn Prediction API

A machine learning-based REST API for predicting customer churn, developed using XGBoost, FastAPI, and Docker.

The project demonstrates the full lifecycle of a machine learning solution: from data processing, model training, and interpretation to API creation, containerization, and cloud deployment.

## Features

Churn classification using XGBoost

Churn probability prediction

Customizable classification threshold

Model interpretation using SHAP

FastAPI-based REST API

Data validation via Pydantic

Testing with pytest

Docker and Docker Compose

CI/CD via GitHub Actions

Image publishing to Docker Hub

Data storage in AWS S3

ETL processes in AWS Glue

Data analysis via SQL in AWS Athena

Deployment on AWS EC2

## Machine Learning

Models evaluated:

Logistic Regression

Random Forest

XGBoost

LightGBM

Evaluation metrics:

Accuracy

Precision

Recall

F1-score

ROC-AUC

PR-AUC

The final XGBoost model uses a classification threshold tuned on the validation set.

The model uses the following features:

age

country

device

premium_user

orders_count

total_revenue

avg_order_value

sessions_count

avg_session_duration

avg_pages_viewed

SHAP is used to assess feature importance, analyze dependencies, and investigate incorrect predictions.

## Data Processing Pipeline

Synthetic e-commerce data is stored in AWS S3. AWS Glue is used to process raw CSV files and convert them to Parquet format.

AWS Athena is used to analyze the processed data using SQL. Datasets:

customers.csv

orders.csv

sessions.csv

### AWS Glue Visual ETL

Customers ETL:

![Customers ETL](images/glue-customers.png)

Orders ETL:

![Orders ETL](images/glue-orders.png)

Sessions ETL:

![Sessions ETL](images/glue-sessions.png)

## Project Structure

api/

├── __init__.py

├── main.py

├── schemas.py

└── predictor.py

models/

├── churn_model.pkl

└── churn_threshold.pkl

data/

├── ml/

├── raw/

└── processed/

glue/

├── customers-etl.py

├── orders-etl.py

└── sessions-etl.py

sql/

├── data_quality.sql

├── customer_analysis.sql

└── churn_analysis.sql

tests/

├── conftest.py

├── test_api.py

├── test_predict.py

└── test_schemas.py

notebooks/

└── customer_churn.ipynb

Dockerfile

docker-compose.yml

requirements.txt

.dockerignore

.github/

└── workflows/

├── ci.yml

├── docker-publish.yml

└── deploy.yml

## API Endpoints

GET /

Returns general API information.

GET /health

Health check endpoint.

GET /version

Returns API and model version information.

POST /predict

Predicts customer churn probability and determines the churn category. ## Prediction Example

Request:

{
"age": 44,
"country": "UA",
"device": "desktop",
"premium_user": 0,
"orders_count": 10,
"total_revenue": 100,
"avg_order_value": 10,
"sessions_count": 15,
"avg_session_duration": 15.65,
"avg_pages_viewed": 5.35
}

Response:

{
"churn_probability": 0.7342,
"predicted_churn": 1
}

## Running with Docker

docker compose up --build

API:

http://localhost:8000

Swagger:

http://localhost:8000/docs

Health check:

http://localhost:8000/health

## Running tests

pytest -v

## CI/CD

GitHub Actions automatically:

1. Runs tests
2. Builds the Docker image
3. Pushes the image to Docker Hub
4. Deploys the application to AWS EC2
5. Checks the API health endpoint

Pipeline:

GitHub → GitHub Actions → Docker Hub → AWS EC2

## Business Analysis

The model is used to identify customers at high risk of churn based on the predicted probability of leaving.

A probability threshold of 0.70 is used to identify high-risk customers.

High-risk customer analysis is conducted based on the following parameters:

country

device

Premium status

customer activity

revenue

Analysis results can be used to prioritize customer retention and re-engagement campaigns.

## Limitations

The project uses synthetic e-commerce data.

The target variable (churn) was generated using deterministic rules based on purchasing behavior and customer activity. Thus, the model demonstrates the full development cycle of an ML solution; however, its performance metrics should not be viewed as representative of real-world production deployment.

## Technologies

Python · Pandas · NumPy · FastAPI · Pydantic · scikit-learn · XGBoost · LightGBM · SHAP · SQL · AWS S3 · AWS Glue · AWS Athena · AWS EC2 · Docker · Docker Compose · GitHub Actions · Docker Hub · pytest