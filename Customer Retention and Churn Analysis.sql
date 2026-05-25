/*
	Customer Retention and Churn Analysis

	The Challenge: Identify "at-risk" customers. 

	Find all customers who made at least three purchases in 2013 
	but have not placed an order in the last six months of the available data. 
	For these customers, calculate the average time gap (in days) 
	between their orders and the difference between their last order total 
	and their lifetime average order value.
*/

-- USE AdventureWorks2022

DECLARE @LastDate DATETIME;

SELECT TOP (1)
	@LastDate = LAST_VALUE(OrderDate) OVER(
		ORDER BY OrderDate
	)
FROM Sales.SalesOrderHeader;

WITH cte1 AS(  -- Extract necessary columns to make the next calculations
	SELECT  
		YEAR(OrderDate) OrderYear,
		OrderDate,
		SalesOrderID,
		CustomerID,
		DATEDIFF(MONTH, @LastDate, OrderDate) LastOrderGap
	FROM Sales.SalesOrderHeader
),
cte2 AS( -- Filter records with 6 months from last purchase, from 2013 and at least 3 purchases 
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
	HAVING COUNT(DISTINCT SalesOrderID) >= 3 -- This filter is applied after WHERE clause
),
cte3 AS(	-- Calculate days gap, avg total per customer and last order value
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
		) DaysGap,	-- Days gap between orders
		soh.TotalDue,
		AVG(soh.TotalDue) OVER(
			PARTITION BY c2.CustomerID
		) OrderAvg,	-- Avg order total value
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
	cte3.CustomerID,
	p.FirstName + ' ' + p.LastName Customer,
	cte3.OrderAvg - cte3.LastOrderValue OrderValueDeviation,
	AVG(cte3.DaysGap) AvgDayGap
FROM cte3
JOIN Sales.Customer sc
	ON cte3.CustomerID = sc.CustomerID
JOIN Person.Person p
	ON sc.PersonID = p.BusinessEntityID
GROUP BY 
	cte3.CustomerID,
	p.FirstName + ' ' + p.LastName,
	cte3.OrderAvg - cte3.LastOrderValue
ORDER BY AvgDayGap DESC


