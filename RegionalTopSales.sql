USE AdventureWorksDW2022;

/*

2. Customer Segmentation by Loyalty and Sales Territory

For each sales territory, find the 5 most loyal customers, ranked by their total sales value. 
The definition of “loyalty” for this query is that the customer must have purchased products from at least 5 different product subcategories. 
The query should show the name of the sales territory, the customer's name, the total sales value, the number of unique subcategories purchased, 
and their ranking position (1 to 5) within their territory.

	Tables: 
		FactInternetSales (ProductKey, CustomerKey, SalesTerritoryKey)



*/

WITH sales_CTE AS (
	SELECT 
		fis.SalesTerritoryKey region_id,
		fis.CustomerKey customer_id,
		SUM(fis.SalesAmount) sales,
		COUNT(DISTINCT dp.ProductSubcategoryKey) unique_subcategories,
		ROW_NUMBER() OVER(
			PARTITION BY fis.SalesTerritoryKey
			ORDER BY SUM(fis.SalesAmount) DESC
		) ranking
	FROM FactInternetSales fis
	JOIN DimProduct dp
		ON fis.ProductKey = dp.ProductKey
	GROUP BY
		fis.SalesTerritoryKey,
		fis.CustomerKey
	HAVING COUNT(DISTINCT dp.ProductSubcategoryKey) >= 5
)
, geo_CTE AS(
	SELECT 
		DISTINCT SalesTerritoryKey id,
		EnglishCountryRegionName country
	FROM DimGeography
)
SELECT 
	cte2.country region,
	dc.FirstName + ' ' + dc.LastName customer_name,
	cte.sales,
	cte.ranking
FROM sales_CTE cte 
JOIN DimCustomer dc
	ON  dc.CustomerKey = cte.customer_id
JOIN geo_CTE cte2
	ON cte.region_id = cte2.id
WHERE cte.ranking <= 5
ORDER BY 
	region,
	sales DESC
