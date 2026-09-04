-- 1. Find the date of your last order

SELECT c.customer_id, MAX(o.order_date) as last_order_date
FROM customers_processed c 
LEFT JOIN orders_processed o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;


-- 2. Find the date of the last session

SELECT c.customer_id, MAX(s.session_date) as last_session_date
FROM customers_processed c 
LEFT JOIN sessions_processed s ON c.customer_id = s.customer_id
GROUP BY c.customer_id;


-- 3. Calculate the days since the last order
-- Analysis date: 2026-08-29

SELECT c.customer_id, MAX(o.order_date) as last_order_date, 
DATE_DIFF('day', MAX(o.order_date), DATE '2026-08-29') as days_since_last_order
FROM customers_processed c 
LEFT JOIN orders_processed o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;


-- 4. Identify churn
-- Analysis date: 2026-08-29

WITH customer_orders as (SELECT customer_id, MAX(order_date) as last_order_date, 
                         DATE_DIFF('day', MAX(order_date), DATE '2026-08-29') as days_since_last_order
FROM orders_processed
GROUP BY customer_id)

SELECT customer_id, last_order_date, days_since_last_order, 
    CASE 
        WHEN last_order_date IS NULL THEN 'No purchase'
        WHEN days_since_last_order > 90 THEN 'Churn'
        ELSE 'Active'
    END as churn_status
FROM customer_orders;


-- 5. Create a customer churn dataset
-- Analysis date: 2026-08-29

WITH customer_orders as (SELECT customer_id, COUNT(*) as orders_count, ROUND(SUM(order_value), 2) as total_revenue,
ROUND(AVG(order_value), 2) as avg_order_value, MAX(order_date) as last_order_date, 
DATE_DIFF('day', MAX(order_date), DATE '2026-08-29') as days_since_last_order
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(*) as sessions_count, MAX(session_date) as last_session_date,
ROUND(AVG(duration_minutes), 2) as avg_session_duration, ROUND(AVG(pages_viewed), 2) as avg_pages_viewed
FROM sessions_processed
GROUP BY customer_id)

SELECT c.customer_id, c.country, c.age, c.device, c.premium_user,

COALESCE(o.orders_count, 0) as orders_count,
COALESCE(o.total_revenue, 0) as total_revenue,
COALESCE(o.avg_order_value, 0) as avg_order_value,
o.last_order_date as last_order_date,

COALESCE(s.sessions_count, 0) as sessions_count,
s.last_session_date,
COALESCE(s.avg_session_duration, 0) as avg_session_duration,
COALESCE(s.avg_pages_viewed, 0) as avg_pages_viewed,

o.days_since_last_order as days_since_last_order,
    CASE 
        WHEN o.last_order_date IS NULL THEN 'No purchase'
        WHEN o.days_since_last_order > 90 THEN 'Churn'
        ELSE 'Active'
    END as churn_status

FROM customers_processed c
LEFT JOIN customer_orders o ON c.customer_id = o.customer_id
LEFT JOIN customer_sessions s ON c.customer_id = s.customer_id;


-- 6. Compare churned, active and no-purchase customers

SELECT churn_status, COUNT(*) as customers,
ROUND(AVG(total_revenue), 2) as avg_revenue,
ROUND(AVG(orders_count), 2) as avg_orders,
ROUND(AVG(sessions_count), 2) as avg_sessions,
ROUND(AVG(avg_session_duration), 2) as avg_session_duration,
ROUND(AVG(avg_pages_viewed), 2) as avg_pages_viewed
FROM customer_churn
GROUP BY churn_status;


-- 7. Churn rate

WITH churned_customers as (SELECT customer_id FROM customer_churn 
WHERE churn_status = 'Churn')

SELECT COUNT(*) as total_customers,
COUNT(ch.customer_id) as churned_customers,
ROUND(COUNT(ch.customer_id) * 100.0 / COUNT(*), 2) as churn_rate_pct
FROM customer_churn c 
LEFT JOIN churned_customers ch ON c.customer_id = ch.customer_id;



-- 8. Churn rate by country

WITH churned_customers as (SELECT customer_id FROM customer_churn 
WHERE churn_status = 'Churn')

SELECT c.country, COUNT(c.customer_id) as customers_count, 
       COUNT(ch.customer_id) as churned_customers, 
       ROUND(COUNT(ch.customer_id) * 100.0 / COUNT(c.customer_id), 2) as churn_rate
FROM customer_churn c 
LEFT JOIN churned_customers ch ON c.customer_id = ch.customer_id
GROUP BY c.country
ORDER BY churn_rate DESC;


-- 9. Churn rate premium vs non-premium

WITH churned_customers as (SELECT customer_id FROM customer_churn 
WHERE churn_status = 'Churn')

SELECT c.premium_user, COUNT(c.customer_id) as customers_count, 
       COUNT(ch.customer_id) as churned_customers, 
       ROUND(COUNT(ch.customer_id) * 100.0 / COUNT(c.customer_id), 2) as churn_rate
FROM customer_churn c 
LEFT JOIN churned_customers ch ON c.customer_id = ch.customer_id
GROUP BY c.premium_user
ORDER BY churn_rate DESC;


-- 10. Churn rate by device

WITH churned_customers as (SELECT customer_id FROM customer_churn 
WHERE churn_status = 'Churn')

SELECT c.device, COUNT(c.customer_id) as customers_count, 
       COUNT(ch.customer_id) as churned_customers, 
       ROUND(COUNT(ch.customer_id) * 100.0 / COUNT(c.customer_id), 2) as churn_rate
FROM customer_churn c 
LEFT JOIN churned_customers ch ON c.customer_id = ch.customer_id
GROUP BY c.device
ORDER BY churn_rate DESC;


-- 11. Calculate average duration per page

SELECT  ROUND(SUM(COALESCE(duration_minutes, 0))/ SUM(COALESCE(pages_viewed, 0)), 2) as duration_per_page
FROM sessions_processed;


-- 12. Calculate average duration per page of a client

SELECT customer_id, ROUND(avg_session_duration / avg_pages_viewed, 2) as avg_duration_per_page 
FROM customer_churn;


-- 13. Compare the current session with the previous one

SELECT customer_id, session_date, duration_minutes, 
LAG(duration_minutes) OVER (PARTITION BY customer_id ORDER BY session_date) as previous_duration,
ROUND(duration_minutes - LAG(duration_minutes) OVER (PARTITION BY customer_id ORDER BY session_date), 2) as duration_diff
FROM sessions_processed
ORDER BY customer_id, session_date;


-- 14. Find clients with a significant drop in activity

WITH customer_duration_diff as (SELECT customer_id, session_date, duration_minutes, 
LAG(duration_minutes) OVER (PARTITION BY customer_id ORDER BY session_date) as previous_duration,
ROUND(duration_minutes - LAG(duration_minutes) OVER (PARTITION BY customer_id ORDER BY session_date), 2) as duration_diff
FROM sessions_processed),

customers_with_negative_duration_diff as (SELECT customer_id, 
MIN(duration_diff) as max_negative_duration_diff
FROM customer_duration_diff WHERE duration_diff < 0 GROUP BY customer_id)

SELECT customer_id, max_negative_duration_diff FROM customers_with_negative_duration_diff 
ORDER BY max_negative_duration_diff;


-- 15. Churn risk score

WITH CTE as (SELECT customer_id, days_since_last_order, 
                    CASE NTILE(3) OVER(ORDER BY orders_count)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as orders_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_session_duration)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as session_duration_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_pages_viewed)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as pages_viewed_segmentation
FROM customer_churn)

SELECT customer_id, 
       (
       CASE WHEN days_since_last_order > 180 THEN 5 WHEN days_since_last_order > 90 THEN 3 ELSE 0 END +
       CASE WHEN orders_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN session_duration_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN pages_viewed_segmentation = 'Low' THEN 2 ELSE 0 END
       ) as churn_risk_score
FROM CTE 
ORDER BY churn_risk_score DESC;


-- 16. Divide clients by risk

WITH CTE as (SELECT customer_id, days_since_last_order, 
                    CASE NTILE(3) OVER(ORDER BY orders_count)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as orders_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_session_duration)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as session_duration_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_pages_viewed)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as pages_viewed_segmentation
FROM customer_churn), 

CTE2 as (SELECT customer_id, 
       (
       CASE WHEN days_since_last_order > 180 THEN 5 WHEN days_since_last_order > 90 THEN 3 ELSE 0 END +
       CASE WHEN orders_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN session_duration_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN pages_viewed_segmentation = 'Low' THEN 2 ELSE 0 END
       ) as churn_risk_score
FROM CTE)

SELECT customer_id, churn_risk_score,
       CASE 
          WHEN churn_risk_score <= 5 THEN 'Low Risk'
          WHEN churn_risk_score > 5 AND churn_risk_score <= 8 THEN 'Medium Risk'
          ELSE 'High Risk'
      END as churn_risk_score_segmentation
FROM CTE2;      
     

-- 17. TOP 10 Potentially Leaving Clients

WITH CTE as (SELECT customer_id, country, premium_user, total_revenue, orders_count, last_order_date, days_since_last_order,
                    sessions_count, avg_session_duration, avg_pages_viewed, 
                    CASE NTILE(3) OVER(ORDER BY orders_count)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as orders_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_session_duration)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as session_duration_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_pages_viewed)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as pages_viewed_segmentation
FROM customer_churn),

CTE2 as (SELECT customer_id, country, premium_user, total_revenue, orders_count, last_order_date, days_since_last_order,
                sessions_count, avg_session_duration, avg_pages_viewed,
       (
       CASE WHEN days_since_last_order > 180 THEN 5 WHEN days_since_last_order > 90 THEN 3 ELSE 0 END +
       CASE WHEN orders_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN session_duration_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN pages_viewed_segmentation = 'Low' THEN 2 ELSE 0 END
       ) as churn_risk_score
FROM CTE)

SELECT customer_id, country, premium_user, total_revenue, orders_count, last_order_date, days_since_last_order,
       sessions_count, avg_session_duration, avg_pages_viewed, churn_risk_score,
       CASE 
          WHEN churn_risk_score <= 5 THEN 'Low Risk'
          WHEN churn_risk_score > 5 AND churn_risk_score <= 8 THEN 'Medium Risk'
          ELSE 'High Risk'
      END as churn_risk_score_segmentation
FROM CTE2 ORDER BY churn_risk_score DESC LIMIT 10;


-- 18. Find valuable clients with high churn risk

WITH CTE as (SELECT customer_id, total_revenue, days_since_last_order, churn_status,
                    CASE NTILE(3) OVER(ORDER BY orders_count)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as orders_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_session_duration)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as session_duration_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_pages_viewed)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as pages_viewed_segmentation,
                    
                     CASE NTILE(3) OVER(ORDER BY total_revenue)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as revenue_segmentation
FROM customer_churn),

CTE2 as (SELECT customer_id, total_revenue, days_since_last_order, churn_status, revenue_segmentation,
       (
       CASE WHEN days_since_last_order > 180 THEN 5 WHEN days_since_last_order > 90 THEN 3 ELSE 0 END +
       CASE WHEN orders_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN session_duration_segmentation = 'Low' THEN 2 ELSE 0 END +
       CASE WHEN pages_viewed_segmentation = 'Low' THEN 2 ELSE 0 END
       ) as churn_risk_score
FROM CTE),

CTE3 as (SELECT customer_id, total_revenue, days_since_last_order, churn_status, revenue_segmentation, churn_risk_score,
       CASE 
          WHEN churn_risk_score <= 5 THEN 'Low Risk'
          WHEN churn_risk_score > 5 AND churn_risk_score <= 8 THEN 'Medium Risk'
          ELSE 'High Risk'
      END as churn_risk_score_segmentation
FROM CTE2)

SELECT customer_id, total_revenue, days_since_last_order, churn_status, churn_risk_score
FROM CTE3 
WHERE churn_risk_score_segmentation = 'High Risk' AND revenue_segmentation = 'High';


-- 19. Find new but inactive clients

WITH customer_registrations as (SELECT customer_id, signup_date
FROM customers_processed),

customer_orders as (SELECT customer_id, COUNT(*) as orders_count
FROM orders_processed
GROUP BY customer_id),

customer_sessions as (SELECT customer_id, COUNT(*) as sessions_count
FROM sessions_processed
GROUP BY customer_id),

CTE as (SELECT r.customer_id, 
               CAST(r.signup_date AS DATE) AS signup_date,
               COALESCE(o.orders_count, 0) AS orders_count,
               COALESCE(s.sessions_count, 0) AS sessions_count,
               CASE NTILE(3) OVER(ORDER BY orders_count)
                  WHEN 1 THEN 'Low'
                  WHEN 2 THEN 'Medium'
                  WHEN 3 THEN 'High'
               END as orders_count_segmentation,
               
               CASE NTILE(3) OVER(ORDER BY sessions_count)
                  WHEN 1 THEN 'Low'
                  WHEN 2 THEN 'Medium'
                  WHEN 3 THEN 'High'
               END as sessions_count_segmentation
FROM customer_registrations r
LEFT JOIN customer_orders o ON r.customer_id = o.customer_id
LEFT JOIN customer_sessions s ON r.customer_id = s.customer_id)

SELECT customer_id, signup_date, orders_count, sessions_count
FROM CTE WHERE signup_date >= DATE '2026-08-29' - INTERVAL '90' DAY 
AND orders_count_segmentation = 'Low' AND sessions_count_segmentation = 'Low';


-- 20. Final churn report

WITH CTE as (SELECT customer_id, country, device, premium_user, 
                    total_revenue, orders_count, avg_order_value, last_order_date, days_since_last_order, 
                    sessions_count, last_session_date, avg_session_duration, avg_pages_viewed, 
                    churn_status,
                    CASE NTILE(3) OVER(ORDER BY orders_count)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as orders_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_session_duration)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as session_duration_segmentation,
                    
                    CASE NTILE(3) OVER(ORDER BY avg_pages_viewed)
                        WHEN 1 THEN 'Low'
                        WHEN 2 THEN 'Medium'
                        WHEN 3 THEN 'High'
                    END as pages_viewed_segmentation
FROM customer_churn),

CTE2 as (SELECT customer_id, country, device, premium_user, 
                total_revenue, orders_count, avg_order_value, last_order_date, days_since_last_order, 
                sessions_count, last_session_date, avg_session_duration, avg_pages_viewed, 
                churn_status,
                (
                    CASE WHEN days_since_last_order > 180 THEN 5 WHEN days_since_last_order > 90 THEN 3 ELSE 0 END +
                    CASE WHEN orders_segmentation = 'Low' THEN 2 ELSE 0 END +
                    CASE WHEN session_duration_segmentation = 'Low' THEN 2 ELSE 0 END +
                    CASE WHEN pages_viewed_segmentation = 'Low' THEN 2 ELSE 0 END
                ) as churn_risk_score
FROM CTE)

SELECT customer_id, country, device, premium_user, 
       total_revenue, orders_count, avg_order_value, last_order_date, days_since_last_order, 
       sessions_count, last_session_date, avg_session_duration, avg_pages_viewed, 
       churn_status, churn_risk_score,
       CASE 
          WHEN churn_risk_score <= 5 THEN 'Low Risk'
          WHEN churn_risk_score > 5 AND churn_risk_score <= 8 THEN 'Medium Risk'
          ELSE 'High Risk'
      END as churn_risk_score_segmentation
FROM CTE2;


