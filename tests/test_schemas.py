import pytest
from api.schemas import Customer
from pydantic import ValidationError


def test_valid_customer(customer):

    customer_test = Customer(**customer)

    assert customer_test.age == customer["age"]
    assert customer_test.country == customer["country"]
    assert customer_test.device == customer["device"]


def test_invalid_total_revenue(customer):

    customer["total_revenue"] = -1

    with pytest.raises(ValidationError):
        Customer(**customer)