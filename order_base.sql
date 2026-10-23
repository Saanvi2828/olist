CREATE DATABASE olist;
USE olist; 
describe orders;
ALTER TABLE orders MODIFY order_id VARCHAR(50);
CREATE INDEX idx_orders_order ON orders (order_id);
ALTER TABLE orders
MODIFY COLUMN customer_id VARCHAR(50);

ALTER TABLE orders
MODIFY COLUMN order_id VARCHAR(50);

ALTER TABLE order_items
MODIFY COLUMN order_id VARCHAR(50);

ALTER TABLE order_items
MODIFY COLUMN product_id VARCHAR(50);

ALTER TABLE order_items
MODIFY COLUMN seller_id VARCHAR(50);

-- Payments table
ALTER TABLE payments
MODIFY COLUMN order_id VARCHAR(50);

ALTER TABLE reviews
MODIFY COLUMN order_id VARCHAR(50);

ALTER TABLE customers
MODIFY COLUMN customer_id VARCHAR(50);

ALTER TABLE sellers
MODIFY COLUMN seller_id VARCHAR(50);

ALTER TABLE products
MODIFY COLUMN product_id VARCHAR(50);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_payments_order ON payments (order_id);
CREATE INDEX idx_orderitems_order ON order_items (order_id);
CREATE INDEX idx_reviews_order ON reviews (order_id);
CREATE INDEX idx_customers_customer ON customers (customer_id);
CREATE INDEX idx_orders_product ON orders (product_id);
CREATE INDEX idx_orders_sellers ON orders (seller_id);
CREATE INDEX idx_sellers_sellers ON sellers (seller_id);
CREATE INDEX idx_product_product ON products (product_id);

SELECT COUNT(*) FROM orders;

SELECT
order_id,
sum(price) AS item_revenue,
sum(freight_value) AS total_freight,
count(*) as number_of_items
FROM order_items
GROUP BY order_id; 

SELECT COUNT(*), COUNT(DISTINCT order_id)
FROM (
    SELECT order_id, SUM(price) AS item_revenue
    FROM order_items
    GROUP BY order_id
) t;

SELECT
order_id,
sum(payment_value) AS total_paid
FROM payments
GROUP BY order_id;

WITH ranked_reviews AS (
SELECT order_id,
review_score,
row_number() OVER (
PARTITION BY order_id
ORDER BY
 review_creation_date DESC,
 review_answer_timestamp DESC
 ) AS RN
 FROM REVIEWS
 )
 SELECT order_id,review_score
 FROM ranked_reviews
 WHERE rn = 1; 
 
SELECT o.order_id, o.order_status, c.customer_state
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

describe orders;

CREATE VIEW order_base AS
WITH items AS (
    SELECT order_id,
           SUM(price) AS item_revenue,
           SUM(freight_value) AS freight,
           COUNT(*) AS num_items
    FROM order_items
    GROUP BY order_id
),
pay AS (
  SELECT
order_id,
sum(payment_value) AS total_paid
FROM payments
GROUP BY order_id
),
ranked_reviews AS (
SELECT order_id,review_score
FROM(
SELECT order_id,
review_score,
row_number() OVER (
PARTITION BY order_id
ORDER BY
 review_creation_date DESC,
 review_answer_timestamp DESC
 ) AS RN
 FROM REVIEWS
 )ranked
 WHERE rn = 1
)
SELECT
    o.order_id,
    o.order_status,
    o.order_delivered_carrier_date,
	o.order_delivered_customer_date,
	o.order_estimated_delivery_date,
    o.order_purchase_timestamp,
    c.customer_state,
    i.item_revenue,
    i.freight, 
    p.total_paid, 
    r.review_score,
    
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,

    DATEDIFF(DATE(o.order_delivered_customer_date),
             DATE(o.order_estimated_delivery_date)) AS delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1
        ELSE 0
    END AS is_late   
    
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN items i     ON o.order_id = i.order_id
LEFT JOIN pay p   ON o.order_id = p.order_id
LEFT JOIN ranked_reviews r   ON o.order_id = r.order_id;

SELECT COUNT(*), COUNT(DISTINCT order_id) FROM order_base;   
SELECT SUM(item_revenue) FROM order_base;                    
SELECT MIN(delay_days), MAX(delay_days) FROM order_base;     
SELECT MIN(review_score), MAX(review_score) FROM order_base; 

SELECT is_late, COUNT(*) AS orders, AVG(review_score) AS avg_score
FROM order_base
WHERE order_status = "delivered"
GROUP BY is_late
