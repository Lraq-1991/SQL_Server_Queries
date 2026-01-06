/*
	Top Customers by Profitability Across Years

	Which customers generated the highest net (top 10 total purchase) 
	each year, and how does their ranking change over time?

	Logic: sum up total purchase per client per year, generate ranking over each year
*/

WITH cte AS(
	SELECT 
		YEAR(OrderDate) SalesYear,
		CustomerID,
		SUM(TotalDue) Net
	FROM Sales.SalesOrderHeader 
	GROUP BY 
		YEAR(OrderDate),
		CustomerID
),
cte2 AS(
	SELECT 
		*,
		ROW_NUMBER() OVER(
			PARTITION BY SalesYear
			ORDER BY Net DESC
		) AS Ranking 
	FROM cte
)
SELECT 
	c2.SalesYear,
	p.LastName + ', ' + p.FirstName Customer,
	c2.Ranking
FROM cte2 c2
JOIN Sales.Customer cx
	ON c2.CustomerID = cx.CustomerID
JOIN Person.Person p
	ON cx.PersonID = p.BusinessEntityID
WHERE Ranking <= 10
ORDER BY	
	SalesYear,
	Ranking 


