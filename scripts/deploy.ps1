# scripts/deploy.ps1 — promote workspace items to a target Fabric workspace
# Requires: ms-fabric-cli (`pip install ms-fabric-cli`) and `fab auth login` already done.
param(
  [Parameter(Mandatory)] [string] $Workspace,         # e.g. ws-sales-test
  [Parameter(Mandatory)] [ValidateSet('dev','test','prod')] [string] $ValueSet,
  [string] $Capacity = 'fabraj64',
  [string] $InputDir = "$PSScriptRoot/../workspace"
)

$ErrorActionPreference = 'Stop'
Write-Host "→ Ensuring workspace '$Workspace' exists on capacity '$Capacity'"
fab create "$Workspace.Workspace" -P "capacityName=$Capacity" 2>$null  # ignore if exists

Write-Host "→ Importing items from $InputDir"
fab import -f "$Workspace.Workspace" --input $InputDir --force

Write-Host "→ Activating value-set '$ValueSet' on vl_sales_dtp"
fab set "$Workspace.Workspace/vl_sales_dtp.VariableLibrary" -q activeValueSet -i $ValueSet

Write-Host "→ Refreshing dataflow"
fab job run "$Workspace.Workspace/df_load_factsales.Dataflow"

Write-Host "✓ Done. Workspace $Workspace is now live with value-set=$ValueSet."
