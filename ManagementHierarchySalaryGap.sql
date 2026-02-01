-- USE AdventureWorks2022

/*
	The "Management Hierarchy & Salary Gap" Analysis
	
	The Challenge: Identify the organizational depth of every employee and compare their salary to the average salary of their specific management branch.

	The Requirements: * Construct a full organizational hierarchy (who reports to whom) starting from the CEO.

	Calculate the "Hierarchy Level" (e.g., Level 0 for CEO, Level 1 for Direct Reports).

	For each employee, calculate the average Rate (salary) of all employees that fall under the same manager.

	Show the percentage difference between the employee's rate and that manager's average.

*/

WITH CTE AS
(	-- Join emp with job history and order last pay value to be filtered later
	SELECT 
		e.BusinessEntityID,
		e.LoginID,
		e.JobTitle,
		e.OrganizationLevel,
		e.OrganizationNode,
		e.OrganizationNode.GetAncestor(1) Branch,
		ep.Rate,
		ep.ModifiedDate,
		ROW_NUMBER() OVER(
			PARTITION BY e.BusinessEntityID
			ORDER BY ep.ModifiedDate DESC
		) Seniority
	FROM HumanResources.Employee e
	LEFT JOIN HumanResources.EmployeePayHistory ep
		ON ep.BusinessEntityID = e.BusinessEntityID
),
CTE2 AS(
	SELECT 
		*,
		AVG(Rate) OVER(
			PARTITION BY Branch
		) BranchAvgRate
	FROM CTE
	WHERE Seniority = 1
)
SELECT 
	c.BusinessEntityID,
	ISNULL(c.OrganizationLevel, 0) OrganizationLevel, -- Replacing NULL with for CEO
	p.LastName + ', ' + p.FirstName Employee,
	c.JobTitle,
	c.Rate,
	c.BranchAvgRate,
	( ( Rate / BranchAvgRate ) * 100 ) -100 "RateGap (%)"
FROM CTE2 c
JOIN Person.Person p
	ON c.BusinessEntityID = p.BusinessEntityID
ORDER BY c.OrganizationLevel
