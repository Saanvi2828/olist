CREATE VIEW delay_category_analysis AS
SELECT 
CASE
    WHEN delay_days IS NULL THEN NULL
    WHEN delay_days <= 0 THEN '1. On time or early'
    WHEN delay_days <= 3 THEN '2. 1-3 days late'
    WHEN delay_days <= 7 THEN '3. 4-7 days late'
    ELSE '4. 8+ days late'
END AS delay_cat,
COUNT(*) AS orders,
AVG(review_score) AS avg_score
FROM order_base
WHERE order_status = 'delivered' AND delay_days IS NOT NULL
GROUP BY delay_cat;
