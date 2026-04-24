// Seed FactSales into salesdb-{dev,test,prod} using AAD token auth
import sql from 'mssql';
import { execSync } from 'child_process';
import fs from 'fs';

const SERVER = 'sql-fabric-dtp-raj-7362.database.windows.net';
const ENV_DBS = [['dev','salesdb-dev'], ['test','salesdb-test'], ['prod','salesdb-prod']];

const tokenJson = execSync('az account get-access-token --resource https://database.windows.net/', { encoding: 'utf8' });
const token = JSON.parse(tokenJson).accessToken;

const ddl = fs.readFileSync('C:\\Users\\dev\\Desktop\\seed-factsales.sql', 'utf8');

for (const [env, db] of ENV_DBS) {
  console.log(`\n=== ${db} (env=${env}) ===`);
  const cfg = {
    server: SERVER,
    database: db,
    options: { encrypt: true, trustServerCertificate: false },
    authentication: { type: 'azure-active-directory-access-token', options: { token } },
    requestTimeout: 120000,
  };
  const pool = await sql.connect(cfg);
  // Split sql by GO if needed; ours has no GO, run as one batch
  const script = ddl.replace(/__ENV__/g, env);
  // Need to split because IF/CREATE/INSERT/SELECT in one batch is OK in T-SQL
  const r = await pool.request().query(script);
  // Last result set has the counts
  const rec = r.recordset || (r.recordsets && r.recordsets[r.recordsets.length-1]);
  console.log('Result:', rec);
  await pool.close();
}
console.log('\nAll three DBs seeded.');
