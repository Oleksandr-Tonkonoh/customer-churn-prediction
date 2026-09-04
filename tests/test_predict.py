from api.predictor import predict_churn

def test_predictor(customer):

    churn_probability, predicted_churn = predict_churn(customer)

    assert predicted_churn in [0, 1]
    assert (0 <= churn_probability <= 1)