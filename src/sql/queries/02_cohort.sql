WITH people AS(    
    SELECT 
        customers.customer_unique_id                        as customer_unique_id,
        DATE_FORMAT(MIN(order_purchase_timestamp), '%Y%m')  as cohort_month
    FROM orders
    JOIN customers ON orders.customer_id = customers.customer_id
    WHERE orders.order_status = 'delivered'
    GROUP BY customer_unique_id
    HAVING cohort_month >= '201702' AND cohort_month < '201809'
),
second_layer AS (
    SELECT DISTINCT
        customers.customer_unique_id                  as customer_unique_id,
        DATE_FORMAT(order_purchase_timestamp, '%Y%m') as purchase_month
    FROM orders
    JOIN customers ON orders.customer_id = customers.customer_id
    WHERE orders.order_status = 'delivered' AND order_purchase_timestamp >= '2017-02-01' AND order_purchase_timestamp < '2018-09-01'
)
SELECT
    COUNT(DISTINCT people.customer_unique_id)                                AS people_count,
    CONCAT(LEFT(people.cohort_month, 4), '-', RIGHT(people.cohort_month, 2)) AS cohort_month,
    PERIOD_DIFF(second_layer.purchase_month, people.cohort_month)            AS month_index
FROM people
JOIN second_layer ON people.customer_unique_id = second_layer.customer_unique_id
GROUP BY cohort_month, month_index
ORDER BY cohort_month ASC, month_index ASC;
