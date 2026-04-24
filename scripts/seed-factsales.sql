-- FactSales: flattened star schema
IF OBJECT_ID('dbo.FactSales','U') IS NOT NULL DROP TABLE dbo.FactSales;
CREATE TABLE dbo.FactSales (
    SaleId          INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate        DATE            NOT NULL,
    OrderNumber     VARCHAR(20)     NOT NULL,
    CustomerId      INT             NOT NULL,
    CustomerName    NVARCHAR(100)   NOT NULL,
    CustomerSegment VARCHAR(20)     NOT NULL,
    Country         VARCHAR(40)     NOT NULL,
    Region          VARCHAR(20)     NOT NULL,
    ProductId       INT             NOT NULL,
    ProductName     NVARCHAR(100)   NOT NULL,
    Category        VARCHAR(40)     NOT NULL,
    SubCategory     VARCHAR(40)     NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL,
    DiscountPct     DECIMAL(5,2)    NOT NULL,
    TaxPct          DECIMAL(5,2)    NOT NULL,
    NetAmount       AS (CAST(Quantity * UnitPrice * (1 - DiscountPct/100.0) AS DECIMAL(12,2))) PERSISTED,
    TaxAmount       AS (CAST(Quantity * UnitPrice * (1 - DiscountPct/100.0) * (TaxPct/100.0) AS DECIMAL(12,2))) PERSISTED,
    TotalAmount     AS (CAST(Quantity * UnitPrice * (1 - DiscountPct/100.0) * (1 + TaxPct/100.0) AS DECIMAL(12,2))) PERSISTED,
    SalesRep        NVARCHAR(80)    NOT NULL,
    Channel         VARCHAR(20)     NOT NULL,
    LoadedAt        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    Environment     VARCHAR(10)     NOT NULL
);
CREATE INDEX IX_FactSales_Date ON dbo.FactSales(SaleDate);
CREATE INDEX IX_FactSales_Region ON dbo.FactSales(Region);
CREATE INDEX IX_FactSales_Category ON dbo.FactSales(Category);

-- Generate ~1000 rows of sample data per environment (env name passed via @env)
DECLARE @env VARCHAR(10) = '__ENV__';
DECLARE @rows INT = CASE @env WHEN 'dev' THEN 500 WHEN 'test' THEN 1000 WHEN 'prod' THEN 2000 ELSE 1000 END;

;WITH N AS (
  SELECT TOP (@rows) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
  FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
R AS (
  SELECT n,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r1,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r2,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r3,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r4,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r5,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r6,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r7,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r8,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r9,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r10,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r11,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r12,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r13,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r14,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r15,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r16,
    (CHECKSUM(NEWID()) & 0x7FFFFFFF) AS r17
  FROM N
)
INSERT INTO dbo.FactSales
(SaleDate, OrderNumber, CustomerId, CustomerName, CustomerSegment, Country, Region,
 ProductId, ProductName, Category, SubCategory, Quantity, UnitPrice, DiscountPct, TaxPct,
 SalesRep, Channel, Environment)
SELECT
  DATEADD(DAY, -(r1 % 365), CAST(GETDATE() AS DATE)),
  CONCAT('ORD-', RIGHT('00000000' + CAST(n AS VARCHAR), 8)),
  100 + (r2 % 250),
  CHOOSE(1+(r3 %10),
    'Contoso Ltd','Fabrikam BV','Northwind Co','Adventure Works','Tailspin Toys',
    'Wide World Importers','Litware Inc','Proseware Holdings','Wingtip Toys','Lucerne Publishing'),
  CHOOSE(1+(r4 %3), 'Enterprise','SMB','Consumer'),
  CHOOSE(1+(r5 %8),
    'Netherlands','Germany','France','UK','Spain','Italy','India','USA'),
  CHOOSE(1+(r6 %4), 'EMEA','EMEA','APAC','AMER'),
  1000 + (r7 % 50),
  CHOOSE(1+(r8 %12),
    'Surface Pro 11','Surface Laptop 7','Xbox Series X','Azure Credits Pack',
    'M365 Business Premium','Power BI Pro Seat','HoloLens 2','Cloud PC Standard',
    'Office 2024 LTSC','Visual Studio Enterprise','GitHub Copilot Seat','Defender for Cloud'),
  CHOOSE(1+(r9 %4), 'Hardware','Software','Cloud','Subscription'),
  CHOOSE(1+(r10%6),
    'Devices','Productivity','Compute','Security','DevTools','Gaming'),
  1 + (r11 % 25),
  CAST(50 + (r12 % 5000) + (r13 % 99) / 100.0 AS DECIMAL(10,2)),
  CAST((r14 % 25) AS DECIMAL(5,2)),
  CAST(CHOOSE(1+(r15%4), 0, 9, 19, 21) AS DECIMAL(5,2)),
  CHOOSE(1+(r16%8),
    'Raj Balakrishnan','Priya Sharma','John Smith','Anna Müller',
    'Sophie Dubois','Marco Rossi','Yuki Tanaka','Diego Hernandez'),
  CHOOSE(1+(r17%4), 'Direct','Partner','Online','Retail'),
  @env
FROM R;

SELECT COUNT(*) AS Rows, SUM(TotalAmount) AS Total, MIN(SaleDate) AS MinDate, MAX(SaleDate) AS MaxDate
FROM dbo.FactSales;
