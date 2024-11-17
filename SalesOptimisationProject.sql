--Sales Transactions
 
DROP TABLE IF EXISTS NewCost

SELECT 
    StartDate,
    EndDate,
    StandardCost,
    ProductID,
    ISNULL(EndDate, GETDATE()) AS EndDate2
INTO 
    NewCost
FROM
    Production.ProductCostHistory;

SELECT 
    SSOD.SalesOrderID,
    SSOD.SalesOrderDetailID,
    SSOD.ProductID,
	SSOD.SpecialOfferID,
	SSOH.CustomerID,
	SSOH.TerritoryID,
	SSOH.Status,
	SSOD.UnitPriceDiscount,
	CONVERT(VARCHAR, SSOH.DueDate, 23) AS [Due Date],
	CONVERT(VARCHAR, SSOH.ShipDate, 23) AS [Ship Date],
	CONVERT(VARCHAR, SSOH.OrderDate, 23) AS [Order Date],
	CASE WHEN SSOH.OnlineOrderFlag = 1 THEN 'Online'
         ELSE 'Reseller' END AS SalesChannel,
    SSOD.UnitPrice,
    (SELECT StandardCost FROM NewCost WHERE SSOD.ProductID = NewCost.ProductID AND OrderDate BETWEEN StartDate AND EndDate2) AS RealStandardCost,
    SSOD.OrderQty,
    SSOD.LineTotal AS Revenue
FROM 
    Sales.SalesOrderDetail AS SSOD
LEFT JOIN 
    Sales.SalesOrderHeader AS SSOH ON SSOH.SalesOrderID = SSOD.SalesOrderID








-- Online Customers Demographics
SELECT
    B.CustomerKey,
    B.BirthDate,
    B.MaritalStatus,
    B.Gender,
    B.YearlyIncome,
    B.TotalChildren,
    B.EnglishEducation,
    B.EnglishOccupation,
    B.NumberCarsOwned,
    B.HouseOwnerFlag,
    B.CommuteDistance,
    C.EnglishCountryRegionName
FROM 
    [AdventureWorksDW2017].[dbo].[DimCustomer] AS B
LEFT JOIN 
    [AdventureWorksDW2017].[dbo].[DimGeography] AS C ON B.GeographyKey = C.GeographyKey;





--Product
SELECT
    PPC.Name AS ProductCategory,
    PPS.Name AS ProductSubcategory,
    PP.Name AS ProductName,
	PP.ListPrice,
	PP.StandardCost,
    PP.ProductID,
	PP.DaysToManufacture,
	CASE WHEN PP.MakeFlag = 0 THEN 'Purchased' ELSE 'Manufactured' END AS ProductionMethod,
    PPS.ProductSubcategoryID,
    PPC.ProductCategoryID
	
FROM Production.Product AS PP
LEFT JOIN Production.ProductSubcategory AS PPS
    ON PP.ProductSubcategoryID = PPS.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS PPC
    ON PPS.ProductCategoryID = PPC.ProductCategoryID





--Region 

SELECT
    Name AS Country,
   [Group] AS Region,
   TerritoryID
 
FROM Sales.SalesTerritory
	

	

	
--Forecast

CREATE VIEW QuarterlyRevenue AS
SELECT
    DATEPART(QUARTER, SSOH.OrderDate) AS Quarter,
    DATEPART(YEAR, OrderDate) AS Year,
	CASE WHEN SST.Name IN('Northeast', 'Northwest', 'Southeast', 'Southwest', 'Central') THEN 'USA'
	ELSE SST.Name 
	END AS Country,
    SST.[Group] AS Region,
    CASE WHEN SSOH.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END AS SalesChannel,
    SUM(LineTotal) AS QuarterlySales
FROM
    Sales.SalesOrderDetail AS SSOD
    LEFT JOIN Sales.SalesOrderHeader AS SSOH ON SSOD.SalesOrderID = SSOH.SalesOrderID
    LEFT JOIN Sales.SalesTerritory AS SST ON SSOH.TerritoryID = SST.TerritoryID
GROUP BY
    DATEPART(QUARTER, OrderDate),
    DATEPART(YEAR, OrderDate),
    SST.[Group],
	CASE WHEN SST.Name IN('Northeast', 'Northwest', 'Southeast', 'Southwest', 'Central') THEN 'USA'
	ELSE SST.Name 
	END,
    SSOH.OnlineOrderFlag






--Market Basket 

SELECT
    
	SSOD.SalesOrderID,
	PP.Name AS ProductName
FROM Sales.SalesOrderDetail AS SSOD
LEFT JOIN Production.Product AS PP ON SSOD.ProductID = PP.ProductID






	--TotalCostForecast

CREATE VIEW TotalCost AS
WITH NewCost AS (
    SELECT 
        StartDate,
        EndDate,
        StandardCost,
        ProductID,
        ISNULL(EndDate, GETDATE()) AS EndDate2
    FROM
        Production.ProductCostHistory
)

SELECT 
    SSOD.UnitPriceDiscount,
    CONVERT(VARCHAR, SSOH.OrderDate, 23) AS [Order Date],
    CASE WHEN SSOH.OnlineOrderFlag = 1 THEN 'Online'
         ELSE 'Reseller' END AS SalesChannel,
    NC.StandardCost AS RealStandardCost,
    SSOD.OrderQty,
	CASE WHEN SST.Name IN('Northeast', 'Northwest', 'Southeast', 'Southwest', 'Central') THEN 'USA'
	ELSE SST.Name 
	END AS Country
    
FROM 
    Sales.SalesOrderDetail AS SSOD
LEFT JOIN 
    Sales.SalesOrderHeader AS SSOH ON SSOH.SalesOrderID = SSOD.SalesOrderID
LEFT JOIN Sales.SalesTerritory AS SST ON SSOH.TerritoryID = SST.TerritoryID
LEFT JOIN NewCost NC ON SSOD.ProductID = NC.ProductID AND SSOH.OrderDate BETWEEN NC.StartDate AND ISNULL(NC.EndDate, GETDATE());


select * from [dbo].[TotalCost]



--SupplyChainAnalysis

SELECT
    POD.ProductID,
    POD.PurchaseOrderDetailID,
    POD.DueDate,
    POD.UnitPrice,
    POD.LineTotal,
    POD.OrderQty,
    POD.ReceivedQty,
    POD.RejectedQty,
    POD.StockedQty,
    POH.OrderDate,
    POH.ShipDate,
    PV.Name AS Supplier,
	CASE
        WHEN PV.CreditRating = 1 THEN 'Superior'
        WHEN PV.CreditRating = 2 THEN 'Excellent'
        WHEN PV.CreditRating = 3 THEN 'Average'
        WHEN PV.CreditRating = 4 THEN 'Below Average'
        ELSE 'Unknown'
    END AS CreditRating,
    CASE
        WHEN PV.PreferredVendorStatus = 0 THEN 'Not Preferred'
        WHEN PV.PreferredVendorStatus = 1 THEN 'Preferred'
        ELSE 'Unknown'
    END AS PreferredVendorStatus,
    CASE 
        WHEN POH.ShipDate > POD.DueDate THEN DATEDIFF(day, POD.DueDate, POH.ShipDate)
        ELSE 0
    END AS Delay
FROM
    [Purchasing].[PurchaseOrderDetail] AS POD
LEFT JOIN
    [Purchasing].[PurchaseOrderHeader] AS POH ON POD.PurchaseOrderID = POH.PurchaseOrderID
LEFT JOIN Purchasing.Vendor AS PV ON POH.VendorID = PV.BusinessEntityID
