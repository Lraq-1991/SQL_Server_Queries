-- 1. Hierarchical Manager Reporting & Organizational DepthThe Challenge: 

--	For every employee, identify their manager and their "level" in the corporate hierarchy (where the CEO is Level 1).

USE AdventureWorks2022;
GO

WITH Hierarchy_CTE -- CTE with emp ID and its manager
AS(
	SELECT 
		emp1.BusinessEntityID,
		CASE	-- Cleaning Organization level results, change NULL to 0
			WHEN emp1.OrganizationLevel IS NULL THEN 0
			ELSE emp1.OrganizationLevel
		END AS Organization_Level,
		emp1.JobTitle,
		CASE	-- Assigning Manager ID. It will be assigned CTO in case Org. level is NULL 
			WHEN emp1.OrganizationLevel IS NULL THEN 0	
			WHEN emp1.OrganizationLevel = 1 THEN 1
			ELSE emp2.BusinessEntityID
		END AS ManagerID	
	FROM HumanResources.Employee emp1
	LEFT JOIN HumanResources.Employee emp2
		ON emp1.OrganizationNode.GetAncestor(1) = emp2.OrganizationNode	-- Using organization node hexacode to retrive employee manager, with GetAncestor method I can retrieve employee´s manager BusinessEmpID 
)
SELECT	-- Populating the results
	cte.BusinessEntityID EmployeeID,
	p.LastName + ', ' + p.FirstName Employee_Name,
	cte.JobTitle,
	cte.Organization_Level,
	CASE 
		WHEN cte.ManagerID = 0 THEN 'N/A' 
		ELSE p2.LastName + ', ' + p2.FirstName
	END AS Manager
FROM Hierarchy_CTE cte
LEFT JOIN Person.Person p
	ON cte.BusinessEntityID = p.BusinessEntityID
LEFT JOIN Person.Person p2
	ON cte.ManagerID = p2.BusinessEntityID
ORDER BY EmployeeID
