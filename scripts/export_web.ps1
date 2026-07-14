$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
$RepoRoot = $ProjectPath
$LocalConfig = Join-Path $RepoRoot "deploy.local.ps1"

$GodotExe = ""

if (Test-Path -LiteralPath $LocalConfig) {
	. $LocalConfig
}

function Resolve-GodotExecutable {
	param(
		[Parameter(Mandatory = $true)]
		[string] $Path
	)

	if (-not (Test-Path -LiteralPath $Path)) {
		throw "Godot path does not exist: $Path"
	}

	if (Test-Path -LiteralPath $Path -PathType Leaf) {
		$ExeDirectory = Split-Path -Parent $Path
		$ConsoleSibling = Join-Path $ExeDirectory "Godot_v4.7-stable_win64_console.exe"
		if (Test-Path -LiteralPath $ConsoleSibling -PathType Leaf) {
			return $ConsoleSibling
		}

		return $Path
	}

	if (Test-Path -LiteralPath $Path -PathType Container) {
		$ConsoleExe = Join-Path $Path "Godot_v4.7-stable_win64_console.exe"
		if (Test-Path -LiteralPath $ConsoleExe -PathType Leaf) {
			return $ConsoleExe
		}

		$EditorExe = Join-Path $Path "Godot_v4.7-stable_win64.exe"
		if (Test-Path -LiteralPath $EditorExe -PathType Leaf) {
			return $EditorExe
		}
	}

	throw "Godot executable not found: $Path"
}

if ([string]::IsNullOrWhiteSpace($GodotExe) -or $GodotExe -eq "FILL_REAL_GODOT_EXE_PATH") {
	throw "GodotExe is not set. Edit deploy.local.ps1 and fill `$GodotExe."
}

$ResolvedGodotExe = Resolve-GodotExecutable -Path $GodotExe
$WebBuildPath = Join-Path $ProjectPath "web_build"
$ExportPath = Join-Path $WebBuildPath "index.html"
$ExportArg = "web_build/index.html"
$ResolvedProjectPath = $ProjectPath
$ResolvedWebBuildPath = [System.IO.Path]::GetFullPath($WebBuildPath)
$GeneratedLatestJsonPath = Join-Path $ProjectPath "latest.json"
$GeneratedRootIndexPath = Join-Path $ProjectPath "root_index"

if ((Split-Path -Leaf $ResolvedWebBuildPath) -ne "web_build") {
	throw "Refusing to clean unexpected build directory: $ResolvedWebBuildPath"
}

if (-not $ResolvedWebBuildPath.StartsWith($ResolvedProjectPath, [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Refusing to clean a build directory outside the project: $ResolvedWebBuildPath"
}

Write-Host "Godot: $ResolvedGodotExe"
Write-Host "Project: $ProjectPath"
Write-Host "Export: $ExportPath"

if (Test-Path -LiteralPath $WebBuildPath) {
	Remove-Item -LiteralPath $WebBuildPath -Recurse -Force
}

if (Test-Path -LiteralPath $GeneratedLatestJsonPath -PathType Leaf) {
	Remove-Item -LiteralPath $GeneratedLatestJsonPath -Force
}

if (Test-Path -LiteralPath $GeneratedRootIndexPath -PathType Container) {
	Remove-Item -LiteralPath $GeneratedRootIndexPath -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $WebBuildPath | Out-Null

Push-Location $ProjectPath
try {
	& $ResolvedGodotExe --headless --path . --export-release "Web" $ExportArg
	if ($LASTEXITCODE -ne 0) {
		throw "Godot Web export failed. Exit code: $LASTEXITCODE"
	}
}
finally {
	Pop-Location
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
		throw "Required export file is missing: $FilePath"
	}
}

function Write-GzipFile {
	param(
		[Parameter(Mandatory = $true)]
		[string] $SourcePath,
		[Parameter(Mandatory = $true)]
		[string] $DestinationPath
	)

	if (Test-Path -LiteralPath $DestinationPath -PathType Leaf) {
		Remove-Item -LiteralPath $DestinationPath -Force
	}

	$SourceStream = [System.IO.File]::OpenRead($SourcePath)
	try {
		$DestinationStream = [System.IO.File]::Create($DestinationPath)
		try {
			$GzipStream = New-Object System.IO.Compression.GZipStream(
				$DestinationStream,
				[System.IO.Compression.CompressionLevel]::Optimal
			)
			try {
				$SourceStream.CopyTo($GzipStream)
			}
			finally {
				$GzipStream.Dispose()
			}
		}
		finally {
			$DestinationStream.Dispose()
		}
	}
	finally {
		$SourceStream.Dispose()
	}
}

$WasmPath = Join-Path $WebBuildPath "index.wasm"
$CompressedWasmPath = Join-Path $WebBuildPath "index.wasm.gz"
Write-GzipFile -SourcePath $WasmPath -DestinationPath $CompressedWasmPath
Write-Host "Generated compressed WebAssembly: index.wasm.gz"

$IndexHtmlPath = Join-Path $WebBuildPath "index.html"
$IndexHtml = [System.IO.File]::ReadAllText($IndexHtmlPath)
$CompressedLoaderPatchMarker = "macro-policy-compressed-resource-loader"
if ($IndexHtml -notmatch [regex]::Escape($CompressedLoaderPatchMarker)) {
	$CompressedLoaderPatch = @"
<script id="$CompressedLoaderPatchMarker">
(function () {
  if (!("DecompressionStream" in window) || !("ReadableStream" in window)) {
    return;
  }

  const originalFetch = window.fetch.bind(window);

  window.fetch = async function (resource, options) {
    const url = typeof resource === "string" ? resource : resource && resource.url;
    if (url && /(^|\/)index\.wasm(?:$|\?)/.test(url)) {
      try {
        const gzUrl = url.replace(/index\.wasm(?=$|\?)/, "index.wasm.gz");
        const response = await originalFetch(gzUrl, options);
        if (response.ok && response.body) {
          const headers = new Headers(response.headers);
          headers.set("content-type", "application/wasm");
          headers.delete("content-encoding");
          headers.delete("content-length");
          return new Response(response.body.pipeThrough(new DecompressionStream("gzip")), {
            status: response.status,
            statusText: response.statusText,
            headers: headers
          });
        }
      } catch (error) {
        console.warn("Compressed wasm loading failed; falling back to raw wasm.", error);
      }
    }

    return originalFetch(resource, options);
  };
})();
</script>
"@
	if ($IndexHtml -match '<script src="index\.js"></script>') {
		$IndexHtml = $IndexHtml -replace '<script src="index\.js"></script>', "$CompressedLoaderPatch`r`n<script src=`"index.js`"></script>"
	}
	else {
		$IndexHtml = $IndexHtml + "`r`n" + $CompressedLoaderPatch
	}
	$Utf8NoBomForCompressedLoader = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($IndexHtmlPath, $IndexHtml, $Utf8NoBomForCompressedLoader)
	Write-Host "Patched index.html to prefer compressed WebAssembly."
}

$CtrlWheelPatchMarker = "macro-policy-ctrl-wheel-guard"
if ($IndexHtml -notmatch [regex]::Escape($CtrlWheelPatchMarker)) {
	$CtrlWheelPatch = @"
<script id="$CtrlWheelPatchMarker">
window.addEventListener("wheel", function (event) {
  if (event.ctrlKey) {
    event.preventDefault();
  }
}, { passive: false });
</script>
"@
	if ($IndexHtml -match "</body>") {
		$IndexHtml = $IndexHtml -replace "</body>", "$CtrlWheelPatch`r`n</body>"
	}
	else {
		$IndexHtml = $IndexHtml + "`r`n" + $CtrlWheelPatch
	}
	$Utf8NoBomForIndex = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($IndexHtmlPath, $IndexHtml, $Utf8NoBomForIndex)
	Write-Host "Patched index.html to prevent browser zoom on Ctrl+wheel."
}

Get-ChildItem -LiteralPath $WebBuildPath -Recurse -Force |
	Where-Object { -not $_.PSIsContainer -and ($_.Extension -eq ".import" -or $_.Name -eq ".gitkeep") } |
	Remove-Item -Force

$HealthPath = Join-Path $WebBuildPath "health.html"
$HealthTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
$HealthHtml = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CloudBase Healthcheck</title>
</head>
<body>
  <h1>CloudBase static hosting OK</h1>
  <p>Build time: $HealthTime</p>
</body>
</html>
"@
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($HealthPath, $HealthHtml, $Utf8NoBom)

$PckFile = Get-Item -LiteralPath (Join-Path $WebBuildPath "index.pck")
Write-Host "Web export completed. index.pck size: $($PckFile.Length) bytes"
