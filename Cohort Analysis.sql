/*
	Multi-Year Customer Retention (Cohort Analysis)

	The Challenge: Group customers into "Cohorts" based on the year of their first purchase. 
	For each cohort, track their total spending year-over-year. 
	The final output should be pivoted so that rows are the "Join Year" 
	and columns are "Year 1 Total," "Year 2 Total," etc., showing how much revenue each cohort generated as they aged.

*/

-- USE AdventureWorks2022

WITH cte AS( -- Extract Joined Year, Year of each order and amount spent
	SELECT 
		YEAR(FIRST_VALUE(OrderDate) OVER(
			PARTITION BY CustomerID
			ORDER BY OrderDate
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		)) JoinYear,
		YEAR(OrderDate) OrderYear,
		TotalDue
	FROM Sales.SalesOrderHeader
)
SELECT -- Create matrix with Join Year as rows and Order year as columns, NULL values were replaced with 0
	JoinYear AS "Join Year",
	ISNULL([2011],0) AS "Total Purchase 2011 $",
	ISNULL([2012],0) AS "Total Purchase 2012 $",
	ISNULL([2013],0) AS "Total Purchase 2013 $",
	ISNULL([2014],0) AS "Total Purchase 2014 $"
FROM cte SourceQuery
PIVOT(
	SUM(TotalDue) FOR OrderYear
	IN ([2011],[2012],[2013],[2014])
) PivotTable
ORDER BY [Join Year];