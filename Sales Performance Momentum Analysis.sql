/*
	The "Sales Performance Momentum" Analysis

		The Goal: Identify "consistent winners" among Sales People. 
		
		The Question: For each salesperson, calculate their total sales for each month in 2013. 
		Then, determine the Month-over-Month (MoM) percentage growth. 
		Finally, filter the list to show only those salespeople who had a positive growth rate 
		for at least three consecutive months.

*/

 USE AdventureWorks2022;

/*

SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Sales'
	AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

*/

/*
SET STATISTICS IO ON;
SET STATISTICS TIME ON; 
*/


-- Adding computed column to use it as nonclustered index

/*
ALTER TABLE Sales.SalesOrderHeader
ADD SalesYear AS YEAR(OrderDate);

ALTER TABLE Sales.SalesOrderHeader
ADD MonthNumber AS MONTH(OrderDate);
*/


-- Creating nonclustered index to increase performance

/*
CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_Year
	ON Sales.SalesOrderHeader (SalesYear);
*/


-- Execute query before query tunning

WITH cte1 AS(	-- Extract Year and Month from orderdate column
	SELECT 
		YEAR(OrderDate) SalesYear,
		MONTH(OrderDate) MonthNumber,	-- This will be used to order months in the following CTEs
		SalesPersonID,
		TotalDue
	FROM Sales.SalesOrderHeader
),
cte2 AS(	-- Total sales per month per salesperson
	SELECT 
		cte1.SalesPersonID,
		cte1.MonthNumber,
		SUM(cte1.TotalDue) MonthProduction
	FROM cte1
	WHERE SalesYear = 2013
		AND SalesPersonID IS NOT NULL
	GROUP BY
		cte1.SalesPersonID,
		cte1.MonthNumber
),
cte3 AS(	-- Calculate month over month sales variation per salesperson
	SELECT
		cte2.SalesPersonID,
		cte2.MonthNumber,
		cte2.MonthProduction,
		CASE	-- Filter months where growth > 0
			WHEN ((cte2.MonthProduction / (	   -- Using LAG() to retrieve previous value, being current value the default outcome, and apply percentage calculation
			LAG(cte2.MonthProduction,1,cte2.MonthProduction)
			OVER(
				PARTITION BY cte2.SalesPersonID
				ORDER BY cte2.MonthNumber
			)
		)) * 100 ) - 100 <= 0 
		THEN 0
		ELSE 1
		END AS "MOM Variation(%)"
	FROM cte2
),
cte4 AS(
	SELECT 
		*,
		SUM(cte3.[MOM Variation(%)]) OVER(
			PARTITION BY cte3.SalesPersonID, cte3.[MOM Variation(%)]
			ORDER BY cte3.MonthNumber
		) AS Cumulative
	FROM cte3
)
SELECT 
	DISTINCT cte4.SalesPersonID,
	p.LastName + ', ' + p.LastName FullName
FROM cte4
JOIN Person.Person p
	ON cte4.SalesPersonID = p.BusinessEntityID
WHERE cte4.Cumulative > 2;
GO


-- Execute this query after query tunning

WITH cte1 AS(	-- total sales per salesperson per month
	SELECT	
		SalesPersonID,
		MonthNumber,
		SUM(TotalDue) AS MonthlySales
	FROM Sales.SalesOrderHeader
	WHERE SalesYear = 2013
		AND SalesPersonID IS NOT NULL
	GROUP BY 
		SalesPersonID,
		MonthNumber
),
cte2 AS(
	SELECT 
		*,
		CASE 
			WHEN (
				(( cte1.MonthlySales / LAG(cte1.MonthlySales) OVER(
					PARTITION BY cte1.SalesPersonID
					ORDER BY cte1.MonthNumber
				) ) * 100) - 100
			) > 0
			THEN 1
			ELSE 0
		END AS "MoM Variation"
	FROM cte1
),
cte3 AS(
	SELECT 
		*,
		SUM(cte2.[MoM Variation]) OVER(
			PARTITION BY cte2.SalesPersonID, cte2.[MoM Variation]
			ORDER BY cte2.MonthNumber
		) AS Cummulative
	FROM cte2
)
SELECT 
	DISTINCT cte3.SalesPersonID Id,
	p.LastName + ', ' + p.FirstName SalesPerson
FROM cte3
JOIN Person.Person p
	ON cte3.SalesPersonID = p.BusinessEntityID
WHERE Cummulative > 2





/*
1. Results before query tunning ==>

SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 43 ms.

(15 rows affected)
Table 'Person'. Scan count 0, logical reads 45, physical reads 4, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 218, logical reads 1105, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'SalesOrderHeader'. Scan count 1, logical reads 686, physical reads 3, page server reads 0, read-ahead reads 682, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 54 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2026-01-02T09:10:09.7705286-08:00


========================================================================================================

2. Results after query tunning ==>

SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 15 ms, elapsed time = 17 ms.

(15 rows affected)
Table 'Worktable'. Scan count 218, logical reads 1105, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Person'. Scan count 0, logical reads 147, physical reads 3, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'SalesOrderHeader'. Scan count 1, logical reads 686, physical reads 1, page server reads 0, read-ahead reads 682, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 55 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2026-01-02T09:51:38.5543016-08:00

*/



/*
Conclusion: Used non-persistent computed columns to avoid extra calculations,
but the cost of CPU is greater when working using that option. So it does not present any advantage. 
*/