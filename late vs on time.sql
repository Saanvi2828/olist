CREATE VIEW late_v_ontime AS
SELECT is_late, COUNT(*) AS orders, AVG(review_score) AS avg_score
FROM order_base
WHERE order_status = "delivered"
GROUP BY is_late;