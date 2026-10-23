USE olist;
CREATE VIEW state_wise_analysis AS
SELECT
    COUNT(*) AS orders,
    ROUND(AVG(is_late)*100, 1) AS late_rate,
    AVG(delay_days) AS avg_delay_days,
    AVG(DATEDIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp)) 
) AS estimated_days,
    AVG(review_score) AS avg_review_score,
    customer_state,
    SUM(is_late) AS late_orders
FROM order_base
WHERE order_status = 'delivered' AND delay_days IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) > 100
ORDER BY late_rate DESC;