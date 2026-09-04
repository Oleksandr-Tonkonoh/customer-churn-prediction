# Customer Churn Prediction API

ML REST API for customer churn prediction built with XGBoost, FastAPI and Docker.

## Features

XGBoost churn classification

Churn probability prediction

Custom classification threshold

FastAPI REST API

Pydantic validation

pytest tests

Docker & Docker Compose

GitHub Actions CI/CD

Docker Hub image publishing

## Project Structure

api/

├── __init__.py

├── main.py

├── schemas.py

└── predictor.py

models/

├── churn_model.pkl

└── churn_threshold.pkl

tests/

├── conftest.py

├── test_api.py

├── test_predict.py

└── test_schemas.py

Dockerfile

docker-compose.yml

requirements.txt

.dockerignore

.github/

└── workflows/

    ├── ci.yml

    └── docker-publish.yml

## API Endpoints

GET /health

Health check endpoint.

POST /predict

Predict customer churn probability and classification.

## Run with Docker

docker compose up --build

API:

http://localhost:8000

Swagger:

http://localhost:8000/docs

## Run Tests

pytest -v

## Technologies

Python · FastAPI · XGBoost · scikit-learn · pandas · Pydantic · pytest · Docker · GitHub Actions · Docker Hub