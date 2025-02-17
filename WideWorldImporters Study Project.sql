-- Task 1:

USE WideWorldImporters
select c.CustomerID, c.CustomerName,
count( DISTINCT o.OrderID) as TotalNBOrders, 
count( DISTINCT i.InvoiceID) as TotalNBInvoices, 
SUM( DISTINCT ol.UnitPrice*ol.Quantity) as OrdersTotalValue,
SUM(DISTINCT l.UnitPrice*l.Quantity) as InvoicesTotalValue,
ABS(SUM( DISTINCT ol.UnitPrice*ol.Quantity)-SUM(DISTINCT l.UnitPrice*l.Quantity)) as  AbsoluteValueDifference 
FROM Sales.Customers as c 
INNER JOIN sales.Orders as o 
on c.CustomerID=o.CustomerID 
INNER JOIN sales.OrderLines as ol
on o.OrderID=ol.OrderID
INNER JOIN Sales.Invoices as i 
on o.OrderID = i.OrderID 
INNER JOIN sales.InvoiceLines as l
on i.InvoiceID = l.InvoiceID
GROUP BY c.CustomerID, c.CustomerName 
ORDER BY AbsoluteValueDifference Desc,TotalNBOrders, c.CustomerName 

-- Task 2:

USE WideWorldImporters
UPDATE Sales.InvoiceLines 
SET UnitPrice = Unitprice+20
WHERE InvoiceLineID=
(
SELECT TOP 1 InvoiceLineID
FROM Sales.InvoiceLines as Il 
where Il.InvoiceID=(SELECT TOP 1 InvoiceID
FROM sales.Invoices as I where I.CustomerID= 1060 ORDER BY InvoiceID)
ORDER BY InvoiceLineID 
); 

-- Task 3:

CREATE PROCEDURE ReportCustomerTurnover2
    @ayear INT = 2013,   
    @choice INT = 1     
AS
BEGIN
    SET NOCOUNT ON;

   
    IF @choice NOT IN (1, 2, 3)
        SET @choice = 1;

    
    IF @choice = 3
    BEGIN
        
        SELECT 
    C.CustomerName,
    COALESCE(SUM(CASE WHEN YEAR(I.InvoiceDate) = 2013 THEN IL.UnitPrice * IL.Quantity END), 0) AS Turnover_2013,
    COALESCE(SUM(CASE WHEN YEAR(I.InvoiceDate) = 2014 THEN IL.UnitPrice * IL.Quantity END), 0) AS Turnover_2014,
    COALESCE(SUM(CASE WHEN YEAR(I.InvoiceDate) = 2015 THEN IL.UnitPrice * IL.Quantity END), 0) AS Turnover_2015,
    COALESCE(SUM(CASE WHEN YEAR(I.InvoiceDate) = 2016 THEN IL.UnitPrice * IL.Quantity END), 0) AS Turnover_2016
FROM Sales.Invoices AS I
INNER JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID
INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
WHERE YEAR(I.InvoiceDate) BETWEEN 2013 AND 2016
GROUP BY C.CustomerName
ORDER BY C.CustomerName;
    END
    ELSE IF @choice = 1
    BEGIN
        
  SELECT 
    C.CustomerName,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 1 THEN IL.UnitPrice * IL.Quantity END), 0) AS Jan,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 2 THEN IL.UnitPrice * IL.Quantity END), 0) AS Feb,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 3 THEN IL.UnitPrice * IL.Quantity END), 0) AS Mar,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 4 THEN IL.UnitPrice * IL.Quantity END), 0) AS Apr,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 5 THEN IL.UnitPrice * IL.Quantity END), 0) AS May,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 6 THEN IL.UnitPrice * IL.Quantity END), 0) AS Jun,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 7 THEN IL.UnitPrice * IL.Quantity END), 0) AS Jul,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 8 THEN IL.UnitPrice * IL.Quantity END), 0) AS Aug,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 9 THEN IL.UnitPrice * IL.Quantity END), 0) AS Sep,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 10 THEN IL.UnitPrice * IL.Quantity END), 0) AS Oct,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 11 THEN IL.UnitPrice * IL.Quantity END), 0) AS Nov,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) = 12 THEN IL.UnitPrice * IL.Quantity END), 0) AS Dec
FROM Sales.Customers AS C
LEFT JOIN Sales.Invoices AS I ON C.CustomerID = I.CustomerID AND YEAR(I.InvoiceDate) = @ayear
LEFT JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID
GROUP BY C.CustomerName
ORDER BY C.CustomerName;
    END
    ELSE IF @choice = 2
    BEGIN
        
       SELECT 
    C.CustomerName,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) IN (1,2,3) THEN IL.UnitPrice * IL.Quantity END), 0) AS Q1,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) IN (4,5,6) THEN IL.UnitPrice * IL.Quantity END), 0) AS Q2,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) IN (7,8,9) THEN IL.UnitPrice * IL.Quantity END), 0) AS Q3,
    COALESCE(SUM(CASE WHEN MONTH(I.InvoiceDate) IN (10,11,12) THEN IL.UnitPrice * IL.Quantity END), 0) AS Q4
FROM Sales.Customers AS C
LEFT JOIN Sales.Invoices AS I ON C.CustomerID = I.CustomerID AND YEAR(I.InvoiceDate) = @ayear
LEFT JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID
GROUP BY C.CustomerName
ORDER BY C.CustomerName;
    END
END;
Go
-- EXAMPLE WITH 2, 2015;
 GO
DECLARE @ayear int;
DECLARE @choice int;
   SET @ayear = 2015
   SET @choice  = 2
EXECUTE  [dbo].[ReportCustomerTurnover2] 
   @ayear
  ,@choice;
GO 

-- Task 4:

USE WideWorldImporters
SELECT CustomerCategoryName, MaxLoss, CustomerName, CustomerID
FROM (
    SELECT 
        c.CustomerID, 
        c.CustomerName, 
        cc.CustomerCategoryName, 
        SUM(ol.Quantity * ol.UnitPrice) AS MaxLoss,
        ROW_NUMBER() OVER (PARTITION BY cc.CustomerCategoryName ORDER BY SUM(ol.Quantity * ol.UnitPrice) DESC) AS RowNum
    FROM Sales.Customers AS c
    INNER JOIN Sales.CustomerCategories AS cc ON cc.CustomerCategoryID = c.CustomerCategoryID
    INNER JOIN Sales.Orders AS o ON o.CustomerID = c.CustomerID
    INNER JOIN Sales.OrderLines AS ol ON ol.OrderID = o.OrderID
    LEFT OUTER JOIN Sales.Invoices AS i ON i.OrderID = o.OrderID
    WHERE i.OrderID IS NULL
    GROUP BY cc.CustomerCategoryName, c.CustomerID, c.CustomerName
) As Maxlosstable
WHERE RowNum = 1
ORDER BY MaxLoss DESC;




