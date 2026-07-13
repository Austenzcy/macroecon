param(
	[bool] $LegacyRootDeploy = $false
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
$ExportScript = Join-Path $ScriptDir "export_web.ps1"
$DeployScript = Join-Path $ScriptDir "deploy_cloudbase.ps1"
$BuildId = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Project: $ProjectPath"
Write-Host "BuildId: $BuildId"
Write-Host "LegacyRootDeploy: $LegacyRootDeploy"

Write-Host "Step 1/2: Export Godot Web build..."
& $ExportScript
if ($LASTEXITCODE -ne 0) {
	throw "Export script failed. Exit code: $LASTEXITCODE"
}

Write-Host "Step 2/2: Deploy to CloudBase hosting..."
& $DeployScript -BuildId $BuildId -LegacyRootDeploy $LegacyRootDeploy
if ($LASTEXITCODE -ne 0) {
	throw "Deploy script failed. Exit code: $LASTEXITCODE"
}

Write-Host "Build and deploy completed."
Write-Host "Release URL: /releases/$BuildId/index.html"
Write-Host "Open the CloudBase hosting root URL and follow docs/CloudBase_Auto_Deploy.md for acceptance testing."
