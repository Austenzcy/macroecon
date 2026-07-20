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

$FontSubsetScript = Join-Path $ScriptDir "generate_font_subset.py"
if (-not (Test-Path -LiteralPath $FontSubsetScript -PathType Leaf)) {
	throw "Font subset generator is missing: $FontSubsetScript"
}

function Resolve-PythonExecutable {
	$Candidates = @()
	if (-not [string]::IsNullOrWhiteSpace($env:CONDA_PREFIX)) {
		$Candidates += (Join-Path $env:CONDA_PREFIX "python.exe")
	}
	if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
		$Candidates += (Join-Path $env:USERPROFILE "ANACD\python.exe")
	}

	$PythonCommand = Get-Command python -ErrorAction SilentlyContinue
	if ($null -ne $PythonCommand -and -not $PythonCommand.Source.Contains("WindowsApps")) {
		$Candidates += $PythonCommand.Source
	}

	foreach ($Candidate in $Candidates) {
		if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
			return $Candidate
		}
	}

	throw "Python with fonttools was not found. Install fonttools or configure a real Python executable."
}

$PythonExe = Resolve-PythonExecutable

Write-Host "Generating Web font subset..."
& $PythonExe $FontSubsetScript
if ($LASTEXITCODE -ne 0) {
	throw "Font subset generation failed. Web export was stopped."
}

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
<link rel="preload" href="index.wasm.gz" as="fetch" crossorigin="anonymous" fetchpriority="high">
<link rel="preload" href="index.pck" as="fetch" crossorigin="anonymous" fetchpriority="high">
<script id="$CompressedLoaderPatchMarker">
(function () {
  const bootStartedAt = performance.now();
  const status = document.getElementById("status");
  const progress = document.getElementById("status-progress");
  const stage = document.createElement("strong");
  const detail = document.createElement("span");
  const message = document.createElement("div");

  message.id = "macro-policy-loading-status";
  message.style.cssText = "position:absolute;bottom:17%;left:8%;right:8%;display:flex;flex-direction:column;align-items:center;gap:8px;text-align:center;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;pointer-events:none";
  stage.style.cssText = "font-size:18px;font-weight:650;color:#f3f6f8";
  detail.style.cssText = "font-size:14px;line-height:1.5;color:#b9c5ce";
  message.appendChild(stage);
  message.appendChild(detail);
  if (status && progress) {
    status.insertBefore(message, progress);
  }

  window.macroPolicySetBootStage = function (title, description) {
    stage.textContent = title;
    detail.textContent = description;
  };
  window.macroPolicyGameReady = function () {
    console.info("[Boot] LevelSelect ready in " + Math.round(performance.now() - bootStartedAt) + " ms");
    window.macroPolicySetBootStage("\u6e38\u620f\u5df2\u51c6\u5907\u5b8c\u6210", "\u6b63\u5728\u8fdb\u5165\u5173\u5361\u9009\u62e9\u2026\u2026");
  };

  window.macroPolicySetBootStage("\u6b63\u5728\u4e0b\u8f7d\u6e38\u620f\u5f15\u64ce", "\u9996\u6b21\u52a0\u8f7d\u9700\u8981\u4e0b\u8f7d\u7ea6 10 MB \u5f15\u64ce\u6587\u4ef6\uff0c\u4e4b\u540e\u8bbf\u95ee\u4f1a\u66f4\u5feb\u3002");
  console.info("[Boot] index.html loaded");
  setTimeout(function () {
    if (document.getElementById("status")) {
      detail.textContent = "\u9996\u6b21\u52a0\u8f7d\u53ef\u80fd\u9700\u8981\u5341\u51e0\u79d2\uff0c\u5b8c\u6210\u540e\u4f1a\u81ea\u52a8\u8fdb\u5165\u6e38\u620f\u3002";
    }
  }, 10000);

  if (!("DecompressionStream" in window) || !("ReadableStream" in window)) {
    console.info("[Boot] compressed wasm unavailable; using raw wasm fallback");
    window.macroPolicySetBootStage("\u6b63\u5728\u4e0b\u8f7d\u517c\u5bb9\u7248\u6e38\u620f\u5f15\u64ce", "\u5f53\u524d\u6d4f\u89c8\u5668\u4e0d\u652f\u6301\u6d41\u5f0f\u89e3\u538b\uff0c\u52a0\u8f7d\u65f6\u95f4\u53ef\u80fd\u66f4\u957f\u3002");
    return;
  }

  const originalFetch = window.fetch.bind(window);

  window.fetch = async function (resource, options) {
    const url = typeof resource === "string" ? resource : resource && resource.url;
    if (url && /(^|\/)index\.wasm(?:$|\?)/.test(url)) {
      const fetchStartedAt = performance.now();
      console.info("[Boot] index.wasm.gz fetch start");
      try {
        const gzUrl = url.replace(/index\.wasm(?=$|\?)/, "index.wasm.gz");
        const response = await originalFetch(gzUrl, options);
        if (response.ok && response.body) {
          console.info("[Boot] index.wasm.gz response in " + Math.round(performance.now() - fetchStartedAt) + " ms");
          window.macroPolicySetBootStage("\u6b63\u5728\u89e3\u538b\u5e76\u7f16\u8bd1\u6e38\u620f\u5f15\u64ce", "\u5f15\u64ce\u4e0b\u8f7d\u5b8c\u6210\uff0c\u6b63\u5728\u51c6\u5907\u8fd0\u884c\u73af\u5883\u3002");
          const headers = new Headers(response.headers);
          headers.set("content-type", "application/wasm");
          headers.delete("content-encoding");
          headers.delete("content-length");
          let decompressedBody = response.body.pipeThrough(new DecompressionStream("gzip"));
          if ("TransformStream" in window) {
            decompressedBody = decompressedBody.pipeThrough(new TransformStream({
              flush: function () {
                console.info("[Boot] wasm decompressed in " + Math.round(performance.now() - fetchStartedAt) + " ms");
                window.macroPolicySetBootStage("\u6b63\u5728\u52a0\u8f7d\u6e38\u620f\u8d44\u6e90", "\u5f15\u64ce\u5df2\u5c31\u7eea\uff0c\u6b63\u5728\u6253\u5f00\u5173\u5361\u9009\u62e9\u3002");
              }
            }));
          }
          return new Response(decompressedBody, {
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
