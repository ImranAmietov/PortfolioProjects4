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
  



