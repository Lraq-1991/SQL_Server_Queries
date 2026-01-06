/*
	Customer Retention and Churn Analysis

	The Challenge: Identify "at-risk" customers. 

	Find all customers who made at least three purchases in 2013 
	but have not placed an order in the last six months of the available data. 
	For these customers, calculate the average time gap (in days) 
	between their orders and the difference between their last order total 
	and their lifetime average order value.
*/

DECLARE @LastDate DATETIME;

SELECT TOP (1)
	@LastDate = LAST_VALUE(OrderDate) OVER(
		ORDER BY OrderDate
	)
FROM Sales.SalesOrderHeader;

WITH cte1 AS(
	SELECT  
		YEAR(OrderDate) OrderYear,
		OrderDate,
		SalesOrderID,
		CustomerID,
		DATEDIFF(MONTH, @LastDate, OrderDate) LastOrderGap
	FROM Sales.SalesOrderHeader
),
cte2 AS(
	SELECT 
		OrderYear,
		CustomerID,
		COUNT(DISTINCT SalesOrderID) Purchases
	FROM cte1
	WHERE LastOrderGap >= 6
		AND OrderYear = 2013
	GROUP BY 
		OrderYear,
		CustomerID
	HAVING COUNT(DISTINCT SalesOrderID) >= 3
),
cte3 AS(
	SELECT DISTINCT 
		c2.CustomerID,
		soh.OrderDate,
		DATEDIFF(
			DAY,
			LAG(OrderDate, 1, OrderDate) OVER(
				PARTITION BY c2.CustomerID
				ORDER BY soh.OrderDate
			),
			soh.OrderDate
		) DaysGap,
		soh.TotalDue,
		AVG(soh.TotalDue) OVER(
			PARTITION BY c2.CustomerID
		) OrderAvg,
		LAST_VALUE(soh.TotalDue) OVER(
			PARTITION BY c2.CustomerID
			ORDER BY soh.OrderDate
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) LastOrderValue
	FROM cte2 c2
	JOIN Sales.SalesOrderHeader soh
		ON c2.CustomerID = soh.CustomerID
)
SELECT 
	CustomerID,
	OrderAvg - LastOrderValue OrderValueDeviation,
	AVG(DaysGap) AvgDayGap
FROM cte3
GROUP BY 
	CustomerID,
	OrderAvg - LastOrderValue




