from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from .schemas import Customer, PredictionResponse
from .predictor import predict_churn
import logging

logger = logging.getLogger(__name__)

app = FastAPI()

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request,
                                       exc: RequestValidationError):
    errors = []
    for error in exc.errors():
        errors.append({
            "field": error["loc"][-1],
            "message": error["msg"]
        })

    return JSONResponse(status_code=422,
                        content={
                            "message": "Validation failed",
                            "errors": errors 
                        })


@app.exception_handler(Exception)
async def general_exception_handler(request: Request,
                                    exc: Exception):
    logger.exception("Unhandled error: %s %s",
                     request.method,
                     request.url)

    return JSONResponse(status_code=500,
                        content={"detail": "Internal server error"})


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict_customer_churn(customer: Customer):

    customer_data = customer.model_dump()

    churn_probability, predicted_churn = predict_churn(customer_data)

    return {"churn_probability": round(churn_probability, 4),
                "predicted_churn": predicted_churn}

    