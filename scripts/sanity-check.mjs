import sql from 'mssql';
import { execSync } from 'child_process';
import fs from 'fs';

const SERVER = 'sql-fabric-dtp-raj-7362.database.windows.net';
const DBS = ['salesdb-dev','salesdb-test','salesdb-prod'];
const token = JSON.parse(execSync('az account get-access-token --resource https://database.windows.net/', {encoding:'utf8'})).accessToken;

const queries = [
  { name: 'identity', sql: `SELECT @@SERVERNAME AS Server, DB_NAME() AS Db, SUSER_SNAME() AS LoggedInAs;` },
  { name: 'top10',    sql: `SELECT TOP 5 SaleDate, OrderNumber, CustomerName, Country, ProductName, Quantity, TotalAmount FROM dbo.FactSales ORDER BY SaleDate DESC;` },
  { name: 'summary',  sql: `SELECT Environment, COUNT(*) AS Rows, CAST(SUM(TotalAmount) AS DECIMAL(15,2)) AS Total, MIN(SaleDate) AS MinDate, MAX(SaleDate) AS MaxDate, COUNT(DISTINCT ProductId) AS Products, COUNT(DISTINCT CustomerId) AS Customers FROM dbo.FactSales GROUP BY Environment;` },
  { name: 'regions',  sql: `SELECT TOP 4 Region, CAST(SUM(TotalAmount) AS DECIMAL(15,2)) AS Revenue, COUNT(*) AS Orders FROM dbo.FactSales GROUP BY Region ORDER BY Revenue DESC;` },
];

for (const db of DBS) {
  console.log(`\n========== ${db} ==========`);
  const pool = await sql.connect({
    server: SERVER, database: db,
    options: { encrypt: true },
    authentication: { type: 'azure-active-directory-access-token', options: { token } },
  });
  for (const q of queries) {
    const r = await pool.request().query(q.sql);
    console.log(`\n-- ${q.name}`);
    console.table(r.recordset);
  }
  await pool.close();
}
