/*
	Product Sales Trend Analysis

	For each product category, calculate monthly sales totals and 3-month moving average for sales
*/

-- USE AdventureWorks2022

WITH cte1 AS(
	SELECT 
		pc.Name Category, 
		DATEPART(q,OrderDate) OrderQuarter,
		MONTH(soh.OrderDate) OrderMonth,
		SUM(sod.OrderQty * sod.UnitPrice) Revenue
	FROM Sales.SalesOrderHeader soh
	JOIN Sales.SalesOrderDetail sod
		ON soh.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product p 
		ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory sc
		ON p.ProductSubcategoryID = sc.ProductSubcategoryID
	JOIN Production.ProductCategory pc
		ON sc.ProductCategoryID = pc.ProductCategoryID
	GROUP BY 
		pc.Name,
		DATEPART(q,OrderDate),
		MONTH(soh.OrderDate)
)
SELECT 
	Category,
	DATENAME(MONTH, DATEADD(MONTH, OrderMonth, -1)) "Month",
	Revenue Sold,
	AVG(Revenue) OVER(
		PARTITION BY 
			Category, 
			OrderQuarter
		ORDER BY OrderMonth
	) "Moving Avg."
FROM cte1 

