from pydantic import BaseModel, Field
from typing import Literal


class Customer(BaseModel):
    age: int = Field(ge=18)
    country: Literal["UA", "SK", "CZ", "PL", "HU"]
    device: Literal["desktop", "mobile", "tablet"]
    premium_user: int = Field(ge=0, le=1)

    orders_count: int = Field(ge=0)
    total_revenue: float = Field(ge=0)
    avg_order_value: float = Field(ge=0)

    sessions_count: int = Field(ge=0)
    avg_session_duration: float = Field(ge=0)
    avg_pages_viewed: float = Field(ge=0)

    model_config = {
        "json_schema_extra": {
            "example": {
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
        }
    }


class PredictionResponse(BaseModel):
    churn_probability: float
    predicted_churn: int