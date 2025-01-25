-- The ratio of the average check of one user to the average check for all users
SELECT
  *,
  AVG(total_price) OVER() AS avg_all,
  CASE 
  WHEN total_price>=AVG(total_price) OVER() THEN True ELSE False END AS valuable_customer
FROM Table_order;

-- Top 5% of clients
WITH b1 AS (SELECT
customer_id, SUM(total_price) AS sum_order,
FROM`ua-trends-434818.orders.Table_order`
GROUP BY 1 ), b2 AS( SELECT *,
                 PERCENT_RANK() OVER(ORDER BY sum_order) as percent_ranks
                 FROM b1)

SELECT * FROM b2 
WHERE percent_ranks>=0.95; 
  
-- Number of orders from users
WITH b1 AS (SELECT *,
ROW_NUMBER() OVER(PARTITION BY customer_id order by order_date) AS rn
FROM`ua-trends-434818.orders.Table_order`)

SELECT rn, COUNT(1) FROM b1
GROUP by 1; 

--Average difference between first and last order amounts
WITH b1 AS (SELECT *,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rn,
FIRST_VALUE(total_price) OVER(PARTITION BY customer_id ORDER BY order_date) AS fv
FROM`ua-trends-434818.orders.Table_order`)

SELECT
AVG(fv-total_price) AS avg_diff,
AVG(fv-total_price)*100/AVG(total_price) AS avg_prc_diff
FROM b1
WHERE rn>=1;

--We create the status of buyers by weekly activities
--report (https://lookerstudio.google.com/s/muwsht1zYTw)
WITH b1 AS (SELECT *,
MOD(ABS(order_id), 1000) AS box_id 
FROM `ua-trends-434818.orders.Table_order` )
, b2 AS 
(SELECT box_id,
DATE_TRUNC(order_date, WEEK) AS date_week, 
SUM(total_price) AS sum_price
FROM b1
GROUP BY 1, 2), 

post_proir_week AS(
SELECT box_id,
LAG(date_week) OVER(PARTITION BY box_id ORDER BY date_week) AS proir_week,
date_week,
LEAD(date_week) OVER(PARTITION BY box_id ORDER BY date_week) AS post_week,
FROM  b2), 

b3 AS (SELECT *,
CASE 
  WHEN proir_week is null THEN 'New'
  WHEN post_week is null 
      AND date_week != date_trunc(current_date(),WEEK)
      AND date_week != date_trunc(current_date(),WEEK) - INTERVAL 1 week
      THEN 'Dormant'
  WHEN date_week= proir_week + INTERVAL 1 week THEN 'Retained'
  WHEN date_week> proir_week + INTERVAL 1 week THEN 'Ressurected'
  END AS status
FROM post_proir_week)

SELECT date_week, status, COUNT(1) as buyers
FROM b3
GROUP BY 1, 2;





