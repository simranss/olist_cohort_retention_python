SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as purchase_month, 
    COUNT(*)                                       AS order_count
FROM orders
WHERE order_purchase_timestamp >= '2017-02-01' AND order_purchase_timestamp < '2018-09-01'
GROUP BY purchase_month
ORDER BY purchase_month ASC;

SELECT 
    order_status, 
    COUNT(*)                                                        AS order_count, 
    CONCAT(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2), '%') AS percentage
FROM orders
WHERE order_purchase_timestamp >= '2017-02-01' AND order_purchase_timestamp < '2018-09-01'
GROUP BY order_status
ORDER BY order_count DESC;

SELECT 
    order_status,
    COUNT(*) - COUNT(order_approved_at)             AS missing_approved,
    COUNT(*) - COUNT(order_delivered_carrier_date)  AS missing_shipped,
    COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivered
FROM orders
WHERE order_purchase_timestamp >= '2017-02-01' AND order_purchase_timestamp < '2018-09-01'
GROUP BY order_status
ORDER BY missing_approved DESC, missing_shipped DESC, missing_delivered DESC;

WITH people AS(
    SELECT 
        customers.customer_unique_id as customer_unique_id, 
        COUNT(*)                     as order_count
    FROM orders
    JOIN customers ON orders.customer_id = customers.customer_id
    WHERE orders.order_status = 'delivered' AND orders.order_purchase_timestamp >= '2017-02-01' AND orders.order_purchase_timestamp < '2018-09-01'
    GROUP BY customers.customer_unique_id
)
SELECT
    COUNT(*)                                AS total_customers,
    SUM(order_count > 1)                    AS repeat_customers,
    CONCAT(ROUND(100.0 * AVG(order_count > 1), 2), '%')  AS repeat_pct
FROM people;

SELECT 
    orders.order_id, 
    customers.customer_unique_id, 
    orders.order_purchase_timestamp, 
    orders.order_status
FROM orders
JOIN customers ON orders.customer_id = customers.customer_id
WHERE customers.customer_unique_id = '8d50f5eadf50201ccdcedfb9e2ac8455' AND orders.order_purchase_timestamp >= '2017-02-01' AND orders.order_purchase_timestamp < '2018-09-01'
ORDER BY orders.order_purchase_timestamp;

SELECT 
    SUM(order_approved_at < order_purchase_timestamp)                 AS invalid_approved,
    SUM(order_delivered_carrier_date < order_approved_at)             AS invalid_shipped,
    SUM(order_delivered_customer_date < order_delivered_carrier_date) AS invalid_delivered,
    SUM(order_delivered_customer_date < order_purchase_timestamp)     AS invalid_purchased
FROM orders
WHERE orders.order_purchase_timestamp >= '2017-02-01' AND orders.order_purchase_timestamp < '2018-09-01';

SELECT 
    payment_type,
    COUNT(*)                                                        AS payment_rows_count,
    COUNT(DISTINCT order_id)                                        AS distinct_order_payment_rows_count,
    CONCAT(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2), '%') AS percentage,
    SUM(payment_value)                                              AS total_value
FROM order_payments
GROUP BY payment_type
ORDER BY payment_rows_count DESC;

SELECT COUNT(DISTINCT order_id) FROM order_payments;

SELECT 
    orders.order_id, 
    orders.order_status 
FROM orders 
LEFT JOIN order_payments ON orders.order_id = order_payments.order_id 
WHERE order_payments.order_id IS NULL;

