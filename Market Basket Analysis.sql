/*   
	Market Basket Analysis: Product Co-Purchasing Patterns
	The Challenge: Find the top 3 product pairs that are most frequently bought together in the same order. 
	The output should exclude pairs that include the same product twice (e.g., A-B is valid, but A-A is not) 
	and should treat (A, B) and (B, A) as the same pair. Finally, show the percentage of total orders that contained this specific pair.

	Techniques Required: Self-Joins, Conditional Logic (to avoid duplicate pairs like A,B and B,A), 
	CTEs, and Mathematical Expressions using subqueries for total order counts
*/

 -- Use AdventureWorks2022;


-- In order to get unique pairs of prod id values, we will emulate a matrix and get all values bellow the diagonal


WITH cte AS( -- All possible combinations excluding the diagonal
	SELECT 
		t1.ProductID m1,
		t2.ProductID m2,
		COUNT(DISTINCT t2.SalesOrderID) orders
	FROM Sales.SalesOrderDetail t1
	JOIN Sales.SalesOrderDetail t2
		ON t1.ProductID != t2.ProductID
	GROUP BY 
		t1.ProductID,
		t2.ProductID
),
cte1 AS(	-- Create list of unique product id values
	SELECT 
		DISTINCT ProductID prodid
	FROM Sales.SalesOrderDetail
),
cte2 AS(	-- List prod id values
	SELECT 
		prodid,
		ROW_NUMBER() OVER(
			ORDER BY prodid
		) position
	FROM cte1
),
cte3 AS(	-- Create unique prod id pair combinations list
	SELECT 
		t1.prodid p1,
		t2.prodid p2
	FROM cte2 t1
	JOIN cte2 t2
		ON t1.position < t2.position
)
SELECT TOP(3)
	cte3.p1,
	cte3.p2,
	cte.orders
FROM cte3 
JOIN cte 
	ON cte3.p1 = cte.m1
	AND cte3.p2 = cte.m2
ORDER BY cte.orders DESC

