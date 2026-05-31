-- Inventory Risk Analysis and Sales Trend

/*

	Challenge: Identify products that are at high risk of stock depletion. 
	To do this, you must find products whose sales volume in the last 30 days 
	is at least 20% higher than their average daily sales in the previous 90 days. 
	The query should list the product name, total sales volume over the last 30 days, 
	and average daily sales over the previous 90 days.

*/


-- USE AdventureWorks2022;



WITH 
sales_CTE AS(		-- Get ranked product sales count per month per product
	SELECT 
		pp.Name prod_name,
		FORMAT(soh.OrderDate, 'yyyy, MMMM') order_date,	-- Cast to month per year
		COUNT(sod.ProductID) sold,	-- Get how much I sold of that product
		ROW_NUMBER() OVER(	-- Create ranking per product and ordered by month
			PARTITION BY pp.Name
			ORDER BY FORMAT(soh.OrderDate, 'yyyy, MMMM') DESC
		) AS month_rank
	FROM Sales.SalesOrderHeader soh
	JOIN Sales.SalesOrderDetail sod
		ON soh.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product pp
		ON sod.ProductID = pp.ProductID
	GROUP BY
		pp.Name,
		FORMAT(soh.OrderDate, 'yyyy, MMMM')
)
,last_month_CTE AS(		-- Get last month sales per product
	SELECT 
		prod_name,
		sold last_month_sale
	FROM sales_CTE
	WHERE month_rank = 1		-- Filter just last month sales
)
,last_quarter_sale_CTE AS(
	SELECT 
		prod_name,
		SUM(sold)/90.0 avg_sales		-- Avg sales for the last 3 quarter, convert to float
	FROM sales_CTE
	WHERE month_rank <= 3
	GROUP BY prod_name
)
SELECT 
	cte1.prod_name 'Product Name',
	cte1.last_month_sale 'Last Month Sales',
	cte2.avg_sales 'Avg. Sales Last Quarter',
	((cte1.last_month_sale - (cte2.avg_sales * 30))   
		/ (cte2.avg_sales * 30)) * 100 'Sales Growth (%)'		-- Get growth for the past month
FROM last_month_CTE cte1
JOIN last_quarter_sale_CTE cte2
	ON cte1.prod_name = cte2.prod_name
ORDER BY [Sales Growth (%)] DESC
;




