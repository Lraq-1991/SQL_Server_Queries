/*
	Sales Performance: Identifying "Breakout" Months

	The Challenge: For each Sales Territory, find the months where sales grew by more than 20% compared to the previous month. 
	The report must include the current month's sales, the previous month's sales, 
	and a "growth rank" showing where that specific growth percentage stands compared to all other months for that territory.

*/

-- USE AdventureWorks2022


WITH cte AS(	-- Order data into Year and Month, and aggregate total due
	SELECT 
		TerritoryID,
		YEAR(OrderDate) SalesYear,
		MONTH(OrderDate) SalesMonth,
		SUM(TotalDue) MonthlySales
	FROM Sales.SalesOrderHeader
	GROUP BY 
		TerritoryID,
		YEAR(OrderDate),
		MONTH(OrderDate)
),
cte2 AS(	-- Calculate previous month sales per territory
	SELECT 
		*,
		LAG(MonthlySales, 1, MonthlySales
		) OVER(
			PARTITION BY TerritoryID
			ORDER BY 
				SalesYear,
				SalesMonth
		) PrevSales
	FROM cte
),
cte3 AS(	-- Calculate growth and rank it per territory, join with territory table to get territory name
	SELECT 
		st.Name Territory,
		c2.SalesYear,
		c2.SalesMonth,
		c2.MonthlySales,
		c2.PrevSales,
		((c2.MonthlySales / c2.PrevSales) * 100) - 100 "Growth(%)",
		ROW_NUMBER() OVER(
			PARTITION BY 
				c2.TerritoryID
			ORDER BY ((c2.MonthlySales / c2.PrevSales) * 100) DESC
		) GrowthRanking
	FROM cte2 c2
	JOIN Sales.SalesTerritory st
		ON c2.TerritoryID = st.TerritoryID
)
SELECT	-- Format and filter data for presentation
	Territory,
	CAST(SalesYear AS VARCHAR(5)) + ' - ' + CAST(SalesMonth AS VARCHAR(2)) "Sales Month",
	MonthlySales,
	PrevSales,
	[Growth(%)],
	GrowthRanking
FROM cte3
WHERE [Growth(%)] > 20


/*

 Bellow is the comparison between:
 
 Querying the dat formating date at first using FORMAT() to get 'yyyy - MM' ==>

 SQL Server Execution Times:
   CPU time = 94 ms,  elapsed time = 215 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2026-01-10T17:46:55.6160431-03:00



================================================================

Querying data extracting sales and month, and keep it as two separate columns 

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 139 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2026-01-10T17:48:54.0745605-03:00

==============================================================

Querying data as presented in the executed query above, date formated at the end 

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 156 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

*/