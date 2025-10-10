NOCOUNT ON;
USE tempdb;

-- 1. LOGICAL QUERY PROCESSING

----------------------------------------------------

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID(N'dbo.Customers', N'U') IS NOT NULL DROP TABLE
dbo.Customers;

-------------------------------------------------

CREATE TABLE dbo.Customers
(
	custid CHAR(5) NOT NULL,
	city VARCHAR(10) NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid CHAR(5) NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
		REFERENCES dbo.Customers(custid)
);

--------------------------------------------

INSERT INTO dbo.Customers(custid, city) VALUES
('FISSA', 'Madrid'),
('FRNDO', 'Madrid'),
('KRLOS', 'Madrid'),
('MRPHS', 'Zion' );
INSERT INTO dbo.Orders(orderid, custid) VALUES
(1, 'FRNDO'),
(2, 'FRNDO'),
(3, 'KRLOS'),
(4, 'KRLOS'),
(5, 'KRLOS'),
(6, 'MRPHS'),
(7, NULL );

-------------------------------------

SELECT *
FROM dbo.Customers;

SELECT *
FROM dbo.Orders;

---------------------------------

--LISTING 1-2 Query: Madrid customers with fewer than three orders

SELECT 
	c.custid,
	COUNT(orderid) order_count
FROM Customers c
LEFT OUTER JOIN Orders o
	ON c.custid = o.custid
WHERE city = 'Madrid'
GROUP BY c.custid
HAVING COUNT(orderid) < 3
ORDER BY order_count
GO

--------------------------------

-- OFFSET-FETCH

SELECT 
	orderid,
	custid
FROM Orders
ORDER BY orderid DESC
OFFSET 4 ROWS FETCH NEXT 2 ROWS ONLY
GO

SELECT TOP(3)
	orderid,
	custid 
FROM Orders
ORDER BY orderid DESC
GO

SELECT 
	orderid,
	custid
FROM Orders
ORDER BY orderid DESC
OFFSET 4 ROWS FETCH NEXT 2 ROWS ONLY
GO

--------------------------------------


-- Atempt to create a sorted view.. Clean up with this at the end
IF OBJECT_ID(N'dbo.MyOrders', N'V') IS NOT NULL
	DROP VIEW dbo.MyOrders;
GO

-- Note: This does not create a sorted 
CREATE VIEW dbo.MyOrders
AS
SELECT
	orderid,
	custid
FROM Orders
ORDER BY orderid DESC
OFFSET 0 ROWS;
GO

-- Query view
SELECT 
	orderid,
	custid
FROM MyOrders;
GO

-------------------------

-- Table Operators: JOIN, APPLY, PIVOT and UNPIVOT

-- CROSS APPLY: applies right expression to left table rows

SELECT 
	c.custid,
	c.city,
	a.orderid
FROM Customers c
	CROSS APPLY (
		SELECT TOP (2) 
			o.orderid,
			o.custid
		FROM Orders o
		WHERE o.custid = c.custid
		ORDER BY orderid DESC
	) a;
GO

-- OUTER APPLY: adds outer rows

SELECT 
	c.custid,
	c.city,
	a.orderid
FROM Customers c
	OUTER APPLY(
		SELECT TOP(2)
			o.orderid,
			o.custid
		FROM Orders o
		WHERE o.custid = c.custid
	) a;
GO


-- PIVOT: Rotates data from rows to columns

WITH cte AS
(
	SELECT
		c.city city,
		o.custid customer,
		o.orderid orderid
	FROM Orders o
	JOIN Customers c
		ON c.custid = o.custid
)
SELECT 
	customer,
	"Madrid",
	"Zion"
FROM cte AS d
PIVOT(
	COUNT(orderid) FOR city
	IN("Madrid","Zion")
) AS p;

