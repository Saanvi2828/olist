CREATE VIEW statewise_rank AS
 WITH seller_rev AS (
   SELECT
    s.seller_id,
    s.seller_state,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rnk
    FROM seller_rev
)
SELECT * FROM ranked ORDER BY seller_state, rnk ASC;

SELECT seller_state, seller_id, revenue, orders, rnk
FROM statewise_rank
WHERE rnk <= 3
ORDER BY seller_state, rnk;