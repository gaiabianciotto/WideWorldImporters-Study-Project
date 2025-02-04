# WideWorldImporters-Study-Project

## Project Overview

The **WideWorldImporters-Study-Project** is a SQL-based study project that involves querying and analyzing data within the ```WideWorldImporters``` database. The project consists of multiple tasks aimed at understanding data consistency, updating records, creating stored procedures, and identifying financial losses due to unconverted orders.

## Tasks

### Task 1: Consistency Check between Orders and Invoices

#### Objective:

Write a SQL query to report the consistency between orders and their corresponding invoices.

Output Requirements:

For each ```(CustomerID, CustomerName)```, the result should include:

```TotalNBOrders ```: Total number of orders

```TotalNBInvoices```: Total number of invoices converted from an order

```OrdersTotalValue```: Total value of orders

```InvoicesTotalValue```: Total value of invoices

```AbsoluteValueDifference```: Absolute difference between ```OrdersTotalValue``` and ```InvoicesTotalValue```

Sorting Order:

Highest ```AbsoluteValueDifference```

Lowest to highest ```TotalNBOrders```

Alphabetical ```CustomerName```

#### SQL Query:

```sql
SELECT c.CustomerID, c.CustomerName,
COUNT(DISTINCT o.OrderID) AS TotalNBOrders,
COUNT(DISTINCT i.InvoiceID) AS TotalNBInvoices,
SUM(DISTINCT ol.UnitPrice * ol.Quantity) AS OrdersTotalValue,
SUM(DISTINCT l.UnitPrice * l.Quantity) AS InvoicesTotalValue,
ABS(SUM(DISTINCT ol.UnitPrice * ol.Quantity) - SUM(DISTINCT l.UnitPrice * l.Quantity)) AS AbsoluteValueDifference
FROM Sales.Customers AS c
INNER JOIN Sales.Orders AS o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
INNER JOIN Sales.Invoices AS i ON o.OrderID = i.OrderID
INNER JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY AbsoluteValueDifference DESC, TotalNBOrders ASC, c.CustomerName ASC;
```

### Task 2: Updating Invoice Line

#### Objective:

For ```CustomerId = 1060``` (CustomerName = 'Anand Mudaliyar'), identify the first InvoiceLine of their first invoice and increase the ```UnitPrice``` by ```20```.

#### SQL Query:
```sql
UPDATE Sales.InvoiceLines
SET UnitPrice = UnitPrice + 20
WHERE InvoiceLineID = (
    SELECT TOP 1 InvoiceLineID
    FROM Sales.InvoiceLines AS Il
    WHERE Il.InvoiceID = (
        SELECT TOP 1 InvoiceID FROM Sales.Invoices AS I WHERE I.CustomerID = 1060 ORDER BY InvoiceID)
    ORDER BY InvoiceLineID
);
```

### Task 3: Report Customer Turnover

#### Objective:

Create a stored procedure ```ReportCustomerTurnover``` with two parameters:

```Choice``` (integer): Specifies the reporting period (monthly, quarterly, or yearly)

```Year``` (integer): Specifies the year for the report

Behavior:

Choice = 1: Monthly turnover for the specified ```Year```

Choice = 2: Quarterly turnover for the specified ```Year```

Choice = 3: Yearly turnover (for years 2013-2016)

Default values: ```Choice = 1```, ```Year = 2013```

#### SQL Stored Procedure:
```sql
CREATE PROCEDURE ReportCustomerTurnover
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
            YEAR(I.InvoiceDate) AS InvoiceYear,
            COALESCE(SUM(IL.UnitPrice * IL.Quantity), 0) AS TotalTurnover
        FROM Sales.Invoices AS I
        INNER JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID
        INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
        WHERE YEAR(I.InvoiceDate) BETWEEN 2013 AND 2016
        GROUP BY C.CustomerName, YEAR(I.InvoiceDate)
        ORDER BY C.CustomerName, InvoiceYear;
    END
    ELSE IF @choice = 1
    BEGIN
        SELECT C.CustomerName, ... -- Monthly Turnover Calculation
        FROM Sales.Invoices AS I
        ... -- Monthly turnover aggregation logic
    END
    ELSE IF @choice = 2
    BEGIN
        SELECT C.CustomerName, ... -- Quarterly Turnover Calculation
        FROM Sales.Invoices AS I
        ... -- Quarterly turnover aggregation logic
    END
END;
GO
```
Example Execution:
```sql
EXECUTE [dbo].[ReportCustomerTurnover] @ayear = 2014, @choice = 1;
```
### Task 4: Identifying Highest Loss Due to Unconverted Orders

#### Objective:

Report the highest financial loss caused by orders that were not converted into invoices, categorized by customer category. The result should also identify the customer responsible for the highest loss.

#### SQL Query:
```sql
WITH MaxLossCTE AS (
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
)
SELECT CustomerCategoryName, CustomerID, CustomerName, MaxLoss
FROM MaxLossCTE
WHERE RowNum = 1
ORDER BY MaxLoss DESC;
```
## Conclusion

This study project provides a structured approach to analyzing order and invoice consistency, updating financial records, generating customer turnover reports, and identifying revenue losses using SQL queries and stored procedures.

This repository is a great resource for anyone looking to deepen their understanding of SQL and database analytics using ```WideWorldImporters``` as a dataset.

## License

This project is open-source and intended for educational purposes. Feel free to use and modify the queries as needed.

## Author

Gaia Bianciotto

## Contact

For any questions or suggestions, feel free to reach out via GitHub Issues.

