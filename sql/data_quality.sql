-- 1. Total number of customers

SELECT COUNT(*) AS total_orders
FROM customers_processed;


-- 2. Total number of orders

SELECT COUNT(*) AS total_orders
FROM orders_processed;

-- 3. Total number of sessions

SELECT COUNT(*) AS total_orders
FROM sessions_processed;

-- 4. NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS customer_id_not_null,
    COUNT(age) AS age_not_null,
    COUNT(country) AS country_not_null,
    COUNT(signup_date) AS signup_date_not_null
FROM customers_processed;

SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS order_id_not_null,
    COUNT(customer_id) AS customer_id_not_null,
    COUNT(order_date) AS order_date_not_null,
    COUNT(order_value) AS order_value_not_null
FROM orders_processed;

SELECT
    COUNT(*) AS total_rows,
    COUNT(session_id) AS session_id_not_null,
    COUNT(customer_id) AS customer_id_not_null,
    COUNT(session_date) AS session_date_not_null,
    COUNT(duration_minutes) AS duration_minutes_not_null
FROM sessions_processed;

-- 5. Duplicate customer_id

SELECT
    customer_id,
    COUNT(*) AS cnt
FROM customers_processed
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 6. Duplicate order_id

SELECT
    order_id,
    COUNT(*) AS cnt
FROM orders_processed
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 7. Duplicate session_id

SELECT
    session_id,
    COUNT(*) AS cnt
FROM sessions_processed
GROUP BY session_id
HAVING COUNT(*) > 1;

-- 8. Negative order values

SELECT *
FROM orders_processed
WHERE order_value < 0;


-- 9. Invalid dates

SELECT *
FROM customers_processed
WHERE signup_date IS NULL;

SELECT *
FROM orders_processed
WHERE order_date IS NULL;

SELECT *
FROM sessions_processed
WHERE session_date IS NULL;

-- 10. Orphan customer_id

SELECT o.customer_id
FROM orders_processed o
LEFT JOIN customers_processed c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;