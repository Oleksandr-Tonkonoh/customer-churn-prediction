import pytest
from fastapi.testclient import TestClient
from api.main import app


@pytest.fixture
def client():

    return TestClient(app)


@pytest.fixture
def customer():

    return {
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
