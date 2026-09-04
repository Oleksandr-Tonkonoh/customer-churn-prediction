-- 1. Number of orders per customer

SELECT customer_id, COUNT(*) as orders_count 
FROM orders_processed 
GROUP BY customer_id
ORDER BY orders_count DESC;


-- 2. Revenue per client

SELECT customer_id, SUM(order_value) as total_revenue
FROM orders_processed
GROUP BY customer_id
ORDER BY total_revenue DESC;


-- 3. Average order value

SELECT customer_id, COUNT(*) as orders_count, SUM(order_value) as total_revenue, ROUND(AVG(order_value), 2) as avg_order_value
FROM orders_processed
GROUP BY customer_id;


-- 4. Number of sessions for each client

SELECT customer_id, COUNT(*) as sessions_count
FROM sessions_processed
GROUP BY customer_id
ORDER BY sessions_count DESC;


-- 5. Average session duration

SELECT customer_id, COUNT(*) as sessions_count, ROUND(AVG(duration_minutes), 2) as avg_session_duration
FROM sessions_processed
GROUP BY customer_id;


-- 6. Combine clients and orders

SELECT c.customer_id, c.age, c.country, c.premium_user, 
COUNT(o.order_id) as orders_count, SUM(o.order_value) as total_revenue, ROUND(AVG(o.order_value), 2) as avg_order_value
FROM customers_processed c LEFT JOIN orders_processed o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.age, c.country, c.premium_user;


-- 7. Combine clients and sessions

SELECT c.customer_id, c.country, COUNT(s.session_id) as sessions_count, 
ROUND(AVG(s.duration_minutes), 2) as avg_session_duration, ROUND(AVG(s.pages_viewed), 2) as avg_pages_viewed
FROM customers_processed c LEFT JOIN sessions_processed s on c.customer_id = s.customer_id
GROUP BY c.customer_id, c.country;


-- 8. Complete customer profile

WITH customer_orders as (SELECT customer_id, COUNT(order_id) as orders_count, 
SUM(order_value) as total_revenue, ROUND(AVG(order_value), 2) as avg_order_value, MAX(order_date) as last_order_date
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(session_id) as sessions_count, 
ROUND(AVG(duration_minutes), 2) as avg_session_duration, ROUND(AVG(pages_viewed), 2) as avg_pages_viewed
FROM sessions_processed
GROUP BY customer_id)

SELECT c.customer_id, c.age, c.country, c.device, c.premium_user,
COALESCE(o.orders_count, 0) as orders_count, 
COALESCE(o.total_revenue, 0) as total_revenue,
COALESCE(o.avg_order_value, 0) as avg_order_value,
o.last_order_date as last_order_date,

COALESCE(s.sessions_count, 0) as sessions_count,
COALESCE(s.avg_session_duration, 0) as avg_session_duration,
COALESCE(s.avg_pages_viewed, 0) as avg_pages_viewed

FROM customers_processed c 
LEFT JOIN customer_orders o ON c.customer_id = o.customer_id 
LEFT JOIN customer_sessions s on c.customer_id = s.customer_id;


-- 9. Customer segmentation by revenue

WITH CTE as (SELECT customer_id, SUM(order_value) as total_revenue
FROM orders_processed
GROUP BY customer_id)

SELECT customer_id, total_revenue,
    CASE NTILE(4) OVER(ORDER BY total_revenue)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        WHEN 4 THEN 'VIP' 
    END AS revenue_segment
FROM CTE;


-- 10. Segmentation by activity

WITH CTE as (SELECT customer_id, COUNT(*) AS sessions_count
FROM sessions_processed
GROUP BY customer_id)

SELECT customer_id, sessions_count,
    CASE NTILE(3) OVER(ORDER BY sessions_count)
        WHEN 1 THEN 'Low activity'
        WHEN 2 THEN 'Medium activity'
        WHEN 3 THEN 'High activity' 
     END as activity_segment
FROM CTE;


-- 11. Premium vs non-premium

WITH customer_orders as (SELECT customer_id, AVG(order_value) as avg_order_value, COUNT(*) as orders_count
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(*) as sessions_count, AVG(duration_minutes) as avg_session_duration
FROM sessions_processed
GROUP BY customer_id)

SELECT c.premium_user, COUNT(*) as clients,
ROUND(AVG(o.avg_order_value), 2) as avg_order_value, ROUND(AVG(o.orders_count), 2) as avg_orders,
ROUND(AVG(s.sessions_count), 2) as avg_sessions, ROUND(AVG(s.avg_session_duration), 2) as avg_session_duration
FROM customers_processed c 
LEFT JOIN customer_orders o on c.customer_id = o.customer_id
LEFT JOIN customer_sessions s on c.customer_id = s.customer_id
GROUP BY c.premium_user;


-- 12. Comparison of countries

WITH customer_orders as (SELECT customer_id, 
AVG(order_value) as avg_order_value, SUM(order_value) as clients_revenue, COUNT(*) as orders_count
FROM orders_processed
GROUP BY customer_id)

SELECT c.country, COUNT(*) as clients,
ROUND(SUM(o.clients_revenue), 2) as total_revenue,
ROUND(AVG(o.avg_order_value), 2) as avg_order_value, 
SUM(o.orders_count) as orders,
ROUND(AVG(o.orders_count), 2) as avg_orders
FROM customers_processed c 
LEFT JOIN customer_orders o on c.customer_id = o.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC;

-- 13. Find your most valuable clients(10)

WITH customer_orders as (SELECT customer_id, COUNT(order_id) as orders_count, 
SUM(order_value) as total_revenue, ROUND(AVG(order_value), 2) as avg_order_value
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(session_id) as sessions_count
FROM sessions_processed
GROUP BY customer_id)


SELECT c.customer_id, c.country, c.premium_user,
o.total_revenue as total_revenue,
COALESCE(o.orders_count, 0) as orders_count, 
COALESCE(o.avg_order_value, 0) as avg_order_value,

COALESCE(s.sessions_count, 0) as sessions_count

FROM customers_processed c 
LEFT JOIN customer_orders o ON c.customer_id = o.customer_id 
LEFT JOIN customer_sessions s on c.customer_id = s.customer_id
ORDER BY total_revenue DESC LIMIT 10;


-- 14. Find clients with high activity but low revenue

WITH clients_revenue as (SELECT customer_id, SUM(order_value) as total_revenue
FROM orders_processed
GROUP BY customer_id),

clients_sessions as (SELECT customer_id, COUNT(*) as sessions_count
FROM sessions_processed
GROUP BY customer_id),

CTE as (SELECT r.customer_id, r.total_revenue, s.sessions_count,
    CASE NTILE(3) OVER(ORDER BY r.total_revenue)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as revenue_segmentation,
    
    CASE NTILE(3) OVER(ORDER BY s.sessions_count)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as sessions_segmentation
FROM clients_revenue r
JOIN clients_sessions s ON r.customer_id = s.customer_id)

SELECT customer_id, total_revenue, sessions_count
FROM CTE 
WHERE revenue_segmentation = 'Low' AND sessions_segmentation = 'High';
    

-- 15. Find clients with high revenue but low activity

WITH clients_revenue as (SELECT customer_id, SUM(order_value) as total_revenue
FROM orders_processed
GROUP BY customer_id),

clients_sessions as (SELECT customer_id, COUNT(*) as sessions_count
FROM sessions_processed
GROUP BY customer_id),

CTE as (SELECT r.customer_id, r.total_revenue, s.sessions_count,
    CASE NTILE(3) OVER(ORDER BY r.total_revenue)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as revenue_segmentation,
    
    CASE NTILE(3) OVER(ORDER BY s.sessions_count)
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as sessions_segmentation
FROM clients_revenue r
JOIN clients_sessions s ON r.customer_id = s.customer_id)

SELECT customer_id, total_revenue, sessions_count
FROM CTE 
WHERE revenue_segmentation = 'High' AND sessions_segmentation = 'Low';


-- 16. Create a final customer segmentation

WITH customer_orders as (SELECT customer_id, COUNT(*) as orders_count, SUM(order_value) as total_revenue
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(*) as sessions_count, ROUND(AVG(duration_minutes), 2) as avg_session_duration
FROM sessions_processed
GROUP BY customer_id)

SELECT c.customer_id, c.country, c.premium_user,
COALESCE(o.orders_count, 0) as orders_count,
COALESCE(o.total_revenue, 0) as total_revenue,

COALESCE(s.sessions_count, 0) as sessions_count,
COALESCE(s.avg_session_duration, 0) as avg_session_duration,

    CASE NTILE(3) OVER(ORDER BY COALESCE(o.orders_count, 0))
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as orders_segmentation,
    
    CASE NTILE(3) OVER(ORDER BY COALESCE(o.total_revenue, 0))
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as revenue_segmentation,
    
    CASE NTILE(3) OVER(ORDER BY COALESCE(s.sessions_count, 0))
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as sessions_segmentation,
    
    CASE NTILE(3) OVER(ORDER BY COALESCE(s.avg_session_duration, 0))
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
    END as session_duration_segmentation
    
FROM customers_processed c
LEFT JOIN customer_orders o ON c.customer_id = o.customer_id
LEFT JOIN customer_sessions s ON c.customer_id = s.customer_id;


