# Fabric Dev/Test/Prod CI/CD Demo

End-to-end Microsoft Fabric **Dev → Test → Prod** promotion pipeline using GitHub Actions and `fabric-cli`.

## What this shows

- **One codebase, three environments.** Same Dataflow, Lakehouse, Notebook artifacts run against `dev`, `test`, `prod` SQL DBs by switching a **Variable Library value-set**.
- **No manual portal clicks** for promotion. `git push main` → auto-deploy to Test → manual approve → Prod.
- **Service Principal auth** end-to-end (no MFA in CI).

## Architecture

```
Azure SQL: sql-fabric-dtp-raj-7362.database.windows.net
  ├── salesdb-dev    (500 rows)
  ├── salesdb-test   (1,000 rows)
  └── salesdb-prod   (2,000 rows)

Fabric Capacity: fabraj64 (F64, West Europe)
  └── Workspace: ws-sales-dtp
      ├── vl_sales_dtp        (Variable Library, 3 value sets)
      ├── conn_sql_*           (3 ServicePrincipal connections)
      ├── lh_sales_{dev,test,prod}
      └── df_load_factsales    (Dataflow Gen2, uses VL)
```

## Promotion flow

```
        ┌────────────────┐
git push│   workspace:   │
main    │  ws-sales-dtp  │  ← devs work here (active value set: dev)
   │    └────────────────┘
   ▼
GitHub Actions
   │
   ├─ Job 1: deploy-test
   │    fabric-cli  →  ws-sales-test  (active value set: test)
   │
   └─ Job 2: deploy-prod  (needs `prod` env approval)
        fabric-cli  →  ws-sales-prod  (active value set: prod)
```

## Repo layout

```
.
├── .github/workflows/deploy.yml      ← CI/CD pipeline
├── workspace/                         ← Fabric items as code
│   ├── VariableLibraries/vl_sales_dtp.VariableLibrary/
│   │   ├── variables.json
│   │   ├── settings.json
│   │   └── valueSets/{dev,test,prod}.json
│   ├── Dataflows/df_load_factsales.Dataflow/
│   │   ├── mashup.pq                  ← actual Power Query M
│   │   ├── dataflow-content.json
│   │   └── .platform
│   └── Lakehouses/lh_sales_{dev,test,prod}.Lakehouse/
│       └── .platform
├── scripts/
│   ├── deploy.ps1                     ← deploys workspace/ to a target via fabric-cli
│   └── seed-sql.mjs                    ← (re)seeds the 3 SQL DBs
└── README.md
```

## How to run locally

```bash
# 1. Install fabric-cli
pip install ms-fabric-cli

# 2. Auth as the deployment SP
fab auth login --tenant $TENANT_ID \
  --service-principal --client-id $CLIENT_ID --client-secret $CLIENT_SECRET

# 3. Deploy this folder to the dev workspace
pwsh ./scripts/deploy.ps1 -Workspace ws-sales-dtp -ValueSet dev
```

## CI secrets needed (GitHub repo settings)

| Secret | Value |
|---|---|
| `FABRIC_TENANT_ID`     | `034ffceb-9251-4d52-88b3-4280cf796cf0` |
| `FABRIC_CLIENT_ID`     | App ID of `sp-fabric-sales-dtp` |
| `FABRIC_CLIENT_SECRET` | (rotate this; see `scripts/rotate-sp.ps1`) |

The SP is already a workspace **Admin** on `ws-sales-dtp`.

## Why Variable Library, not deployment rules?

Fabric Deployment Pipelines (the GUI feature) **don't yet support Dataflow Gen2 destination overrides**. The Variable Library is the supported way to make one dataflow target dev/test/prod lakehouses by activating a different value-set per workspace. CI/CD just sets the active value set after deploy.

## Refs

- Fabric Variable Library: https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview
- ms-fabric-cli: https://github.com/microsoft/fabric-cli
- This was bootstrapped end-to-end by Benji 🐾 on 2026-04-24.
