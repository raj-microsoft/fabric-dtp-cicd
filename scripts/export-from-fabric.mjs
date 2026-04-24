// Export Fabric items as files for git
import { execSync } from 'child_process';
import fs from 'fs'; import path from 'path';

const tok = JSON.parse(execSync('az account get-access-token --resource https://api.fabric.microsoft.com/', {encoding:'utf8'})).accessToken;
const ws = 'fd884b2f-a840-4d6d-862b-941534bdb612';
const root = 'C:\\Users\\dev\\projects\\fabric-dtp-cicd\\workspace';

async function fetchJson(url, opts={}) {
  const r = await fetch(url, { ...opts, headers: { Authorization: `Bearer ${tok}`, 'Content-Type':'application/json', ...(opts.headers||{}) } });
  if (r.status === 202) return { lro: r.headers.get('location') };
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : null };
}

async function poll(loc) {
  for (let i=0;i<30;i++) {
    await new Promise(r=>setTimeout(r,2000));
    const r = await fetch(loc, { headers: { Authorization: `Bearer ${tok}` } });
    const j = await r.json();
    if (j.status === 'Succeeded') {
      const r2 = await fetch(loc + '/result', { headers: { Authorization: `Bearer ${tok}` } });
      return await r2.json();
    }
    if (j.status === 'Failed') throw new Error(JSON.stringify(j.error));
  }
}

async function exportItem(itemId, folder) {
  fs.mkdirSync(folder, { recursive: true });
  const r = await fetchJson(`https://api.fabric.microsoft.com/v1/workspaces/${ws}/items/${itemId}/getDefinition`, { method: 'POST' });
  let defn = r.body?.definition;
  if (r.lro) {
    const result = await poll(r.lro);
    defn = result.definition;
  }
  for (const p of defn.parts) {
    const out = path.join(folder, p.path);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, Buffer.from(p.payload, 'base64'));
    console.log(`  ${p.path} (${Buffer.from(p.payload,'base64').length} bytes)`);
  }
}

console.log('VariableLibrary →');
await exportItem('5b689957-5772-4fd8-8653-9590a628969a', path.join(root,'VariableLibraries','vl_sales_dtp.VariableLibrary'));
console.log('\nDataflow → (already exported, refreshing)');
await exportItem('9c168224-80d2-4640-8f68-f3a27fded375', path.join(root,'Dataflows','df_load_factsales.Dataflow'));
console.log('\nDone.');
