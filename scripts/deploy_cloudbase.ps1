param(
	[string] $BuildId = (Get-Date -Format "yyyyMMdd-HHmmss"),
	[bool] $LegacyRootDeploy = $false
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
$RepoRoot = $ProjectPath
$LocalConfig = Join-Path $RepoRoot "deploy.local.ps1"

if (-not (Test-Path -LiteralPath $LocalConfig -PathType Leaf)) {
	throw "Missing local deploy config: $LocalConfig. Copy deploy.local.example.ps1 to deploy.local.ps1 and fill CloudBaseEnvId."
}

. $LocalConfig

if (-not (Get-Command tcb -ErrorAction SilentlyContinue)) {
	throw "tcb command not found. Please install CloudBase CLI and run tcb login."
}

if ([string]::IsNullOrWhiteSpace($CloudBaseEnvId) -or $CloudBaseEnvId -eq "FILL_YOUR_CLOUDBASE_ENV_ID") {
	throw "CloudBaseEnvId is not set. Edit deploy.local.ps1 and fill `$CloudBaseEnvId."
}

$WebBuildPath = Join-Path $ProjectPath "web_build"
if (-not (Test-Path -LiteralPath $WebBuildPath -PathType Container)) {
	throw "web_build directory not found. Run scripts/export_web.ps1 first."
}

$RequiredFiles = @(
	"index.html",
	"index.js",
	"index.wasm",
	"index.pck"
)

foreach ($FileName in $RequiredFiles) {
	$FilePath = Join-Path $WebBuildPath $FileName
	if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
		throw "Required deploy file is missing: $FilePath"
	}
}

$RootIndexPath = Join-Path $ProjectPath "root_index"
$RootIndexHtmlPath = Join-Path $RootIndexPath "index.html"
$LatestJsonPath = Join-Path $ProjectPath "latest.json"
$HealthPath = Join-Path $WebBuildPath "health.html"
$ReleaseUrl = "/releases/$BuildId/index.html"
$UpdatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

New-Item -ItemType Directory -Force -Path $RootIndexPath | Out-Null

$RootIndexHtml = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Macro Policy Game</title>
  <style>
    html, body {
      height: 100%;
      margin: 0;
      background: #101418;
      color: #f3f6f8;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    body {
      display: grid;
      place-items: center;
    }
    main {
      width: min(480px, calc(100% - 48px));
      text-align: center;
      line-height: 1.7;
    }
    h1 {
      margin: 0 0 12px;
      font-size: 24px;
      font-weight: 650;
    }
    p {
      margin: 0;
      color: #aeb8c2;
      font-size: 15px;
    }
    .error {
      color: #ffb4a8;
    }
  </style>
</head>
<body>
  <main>
    <h1 id="status">&#27491;&#22312;&#36827;&#20837;&#26368;&#26032;&#29256;&#28216;&#25103;&#8230;&#8230;</h1>
    <p id="detail">&#27491;&#22312;&#26816;&#26597;&#26368;&#26032;&#26500;&#24314;&#12290;</p>
  </main>
  <script>
    (async function () {
      const status = document.getElementById("status");
      const detail = document.getElementById("detail");
      try {
        const response = await fetch("latest.json?v=" + Date.now(), { cache: "no-store" });
        if (!response.ok) {
          throw new Error("latest.json HTTP " + response.status);
        }
        const latest = await response.json();
        if (!latest || !latest.url) {
          throw new Error("latest.json missing url");
        }
        detail.textContent = "\u6784\u5efa\u7248\u672c\uff1a" + (latest.buildId || "unknown");
        window.location.replace(latest.url);
      } catch (error) {
        status.textContent = "\u65e0\u6cd5\u8fdb\u5165\u6700\u65b0\u7248\u6e38\u620f";
        status.className = "error";
        detail.textContent = "\u8bf7\u5237\u65b0\u9875\u9762\uff0c\u6216\u7a0d\u540e\u91cd\u8bd5\u3002\u9519\u8bef\uff1a" + error.message;
      }
    })();
  </script>
</body>
</html>
"@

$LatestJson = @{
	buildId = $BuildId
	url = $ReleaseUrl
	updatedAt = $UpdatedAt
} | ConvertTo-Json

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($RootIndexHtmlPath, $RootIndexHtml, $Utf8NoBom)
[System.IO.File]::WriteAllText($LatestJsonPath, $LatestJson, $Utf8NoBom)

function Invoke-TcbHostingDeploy {
	param(
		[Parameter(Mandatory = $true)]
		[string] $LocalPath,
		[string] $CloudPath = "",
		[Parameter(Mandatory = $true)]
		[string] $Description
	)

	Write-Host $Description

	$PreviousErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	try {
		if ([string]::IsNullOrWhiteSpace($CloudPath)) {
			$Output = & tcb hosting deploy $LocalPath -e $CloudBaseEnvId 2>&1
		}
		else {
			$Output = & tcb hosting deploy $LocalPath $CloudPath -e $CloudBaseEnvId 2>&1
		}

		$ExitCode = $LASTEXITCODE
	}
	finally {
		$ErrorActionPreference = $PreviousErrorActionPreference
	}

	$Output | ForEach-Object { Write-Host $_ }

	if ($ExitCode -eq 0) {
		return
	}

	$OutputText = $Output -join "`n"
	$LooksSuccessful =
		($OutputText -match "Deployment complete") -and
		(
			($OutputText -match "File deployment successful") -or
			($OutputText -match "Successfully uploaded\s+\d+\s+file\(s\)")
		) -and
		(
			($OutputText -match "Failed to upload\s+0\s+file\(s\)") -or
			($OutputText -notmatch "Failed to upload\s+[1-9]\d*\s+file\(s\)")
		)

	if ($LooksSuccessful) {
		Write-Warning "CloudBase CLI returned exit code $ExitCode after reporting a successful upload. Continuing."
		return
	}

	throw "$Description failed. Exit code: $ExitCode"
}

if ($LegacyRootDeploy) {
	Invoke-TcbHostingDeploy -LocalPath $WebBuildPath -Description "Legacy root deploy enabled. Deploying web_build to CloudBase hosting root: $CloudBaseEnvId"
}
else {
	$ReleaseTarget = "releases/$BuildId"
	Invoke-TcbHostingDeploy -LocalPath $WebBuildPath -CloudPath $ReleaseTarget -Description "Deploying release build to CloudBase hosting: $ReleaseTarget"
	Invoke-TcbHostingDeploy -LocalPath $LatestJsonPath -CloudPath "latest.json" -Description "Deploying latest.json to CloudBase hosting root..."
	Invoke-TcbHostingDeploy -LocalPath $RootIndexHtmlPath -CloudPath "index.html" -Description "Deploying root launcher index.html to CloudBase hosting root..."

	if (Test-Path -LiteralPath $HealthPath -PathType Leaf) {
		Invoke-TcbHostingDeploy -LocalPath $HealthPath -CloudPath "health.html" -Description "Deploying health.html to CloudBase hosting root..."
	}
}

Write-Host "CloudBase deploy command completed."
Write-Host "BuildId: $BuildId"
Write-Host "Release URL: $ReleaseUrl"
Write-Host "Open the CloudBase hosting root URL for acceptance testing."
