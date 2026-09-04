def test_health(client):
    response = client.get("/health")

    assert response.status_code == 200

    assert response.json() == {"status": "ok"}


def test_predict_churn(client, customer):
    response = client.post("/predict",
                           json=customer)

    assert response.status_code == 200

    customer_data = response.json()

    assert "predicted_churn" in customer_data
    assert "churn_probability" in customer_data
    
    assert customer_data["predicted_churn"] in [0, 1]
    assert 0 <= customer_data["churn_probability"] <= 1


def test_invalid_customer(client, customer):
    customer["total_revenue"] = -1

    response = client.post("/predict",
                           json=customer)

    assert response.status_code == 422

    customer_data = response.json()
    
    assert customer_data["message"] == ("Validation failed")
    assert "errors" in customer_data