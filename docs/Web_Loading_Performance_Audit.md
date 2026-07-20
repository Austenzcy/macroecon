# Web Loading Performance Audit

Date: 2026-07-15

Build investigated before fix: `20260715-023600`

Fixed build: `20260715-025823`

## Symptom

CloudBase online Godot Web build stayed on the Godot loading screen for several minutes and did not reach `MainMenu` in a reasonable time.

## Diagnosis

The problem was in the download stage, before Godot project scripts started.

Evidence from online curl timing before the fix:

| File | HTTP | Size | Time | Content-Type |
|---|---:|---:|---:|---|
| `index.html` | 200 | 5,650 bytes | 10.859 s | `text/html` |
| `index.js` | 200 | 279,815 bytes | 25.505 s | `application/javascript` |
| `index.wasm` | 200 | 39,509,339 bytes | 166.226 s | `application/wasm` |
| `index.pck` | 200 | 13,521,476 bytes | 124.444 s | `application/octet-stream` |

`index.wasm` had the correct MIME type, and `index.pck` was reachable, so this was not primarily a missing-file or MIME problem. The loading screen was slow because the browser had to download a large raw WebAssembly file and a large pack file over a slow path.

## Root Causes

1. `index.wasm` was served raw at about 37.7 MiB. Gzip compression reduced it to about 9.6 MiB, but CloudBase static hosting was not automatically serving a compressed variant.
2. `index.pck` included the full Simplified Chinese font at about 17.8 MB, even though the current prototype only needs a small subset of glyphs.

## Fixes

### Font Subset

`assets/fonts/NotoSansSC-Regular.ttf` was replaced with a project-specific subset generated from the current Godot scripts, scenes, data, and theme text.

The original full font is kept locally as:

```text
assets/fonts/NotoSansSC-Regular.full.ttf.bak
```

That backup is ignored by Git and should not be exported.

### Compressed WebAssembly Loader

`scripts/export_web.ps1` now:

1. Generates `web_build/index.wasm.gz` after every Godot Web export.
2. Patches `web_build/index.html` with `macro-policy-compressed-resource-loader`.
3. Uses browser `DecompressionStream` to fetch `index.wasm.gz`, decompress it in the browser, and pass decompressed bytes to Godot as `application/wasm`.
4. Falls back to raw `index.wasm` if compressed loading is unavailable.

This keeps Godot's normal runtime path intact while reducing transfer size on browsers that support `DecompressionStream`.

## Size Comparison

| File | Before | After |
|---|---:|---:|
| `assets/fonts/NotoSansSC-Regular.ttf` | 17,773,248 bytes | 359,112 bytes |
| `index.pck` | 13,521,476 bytes | 481,572 bytes |
| `index.wasm` | 39,509,339 bytes | 39,509,339 bytes |
| `index.wasm.gz` | not deployed | 10,111,653 bytes |
| `index.js` | 279,815 bytes | 279,815 bytes |

## Online Verification After Fix

BuildId: `20260715-025823`

`latest.json` points to:

```text
/releases/20260715-025823/index.html
```

Online curl timing after the fix:

| File | HTTP | Size | Time | Content-Type |
|---|---:|---:|---:|---|
| `index.html` | 200 | 6,879 bytes | 0.949 s | `text/html` |
| `index.js` | 200 | 279,815 bytes | 1.216 s | `application/javascript` |
| `index.wasm.gz` | 200 | 10,111,653 bytes | 5.392 s | `application/octet-stream` |
| `index.pck` | 200 | 481,572 bytes | 0.776 s | `application/octet-stream` |

The release `index.html` contains the compressed wasm loader marker:

```text
macro-policy-compressed-resource-loader
```

## Current Conclusion

The original multi-minute loading screen was caused by large resource downloads, not by CloudBase deployment failure, Godot thread support, GDExtension, or missing core files.

The current build should reach the Godot startup phase much faster because the transferred payload is now roughly:

```text
index.js + index.wasm.gz + index.pck ~= 10.9 MB
```

instead of:

```text
index.js + index.wasm + index.pck ~= 53.3 MB
```

## Known Limits

1. The font subset only includes glyphs used by current project scripts, scenes, data, and theme files. When full narrative JSON is added later, regenerate the font subset or temporarily restore a larger font.
2. Browsers without `DecompressionStream` will fall back to raw `index.wasm`, so they may still load more slowly.
3. CloudBase may still apply CDN caching. Versioned release paths should continue to be used.

## Follow-Up

Before adding the complete narrative JSON, check whether new text introduces characters missing from the subset font and regenerate the subset as part of the build process if needed.

## Automated Font Subset Generation

LevelSelect's new chapter instruction introduced glyphs that were absent from the previous one-off font subset. The text source was valid UTF-8 in `scripts/scenes/LevelSelect.gd`; the displayed squares were missing glyphs rather than damaged content.

`scripts/generate_font_subset.py` now rebuilds the actual project font at `assets/fonts/NotoSansSC-Regular.ttf` from the local ignored full-font source `assets/fonts/NotoSansSC-Regular.full.ttf.bak`.

The generator scans UTF-8 text from `.gd`, `.tscn`, `.tres`, `.json`, and `.cfg` files under the project. It excludes `.git`, `.godot`, `.godot_cli_user`, `web_build`, `releases`, `root_index`, `docs`, temporary/backup directories, `node_modules`, and `.bak` files. A fixed UI/economics character set is added as a safety net, including chapter/lock/hint labels, ASCII letters and digits, punctuation, `π`, and directional arrows.

`scripts/export_web.ps1` runs the generator before Godot Web export. If Python, fonttools, the full font, or subset validation is unavailable, export stops instead of silently packaging an old font. The generator reports scanned-file count, unique-character count, output size, and validates `顺、序、解、锁、关、卡、提、示、π、↑、↓`.

When adding visible game text later, place it in the normal scenes, scripts, or data directories and the next export will include it automatically. Do not move the full font backup into an exported resource path.

### Current Export Check

BuildId: `20260720-152552`

| File | Size |
|---|---:|
| `assets/fonts/NotoSansSC-Regular.ttf` | 492,644 bytes |
| `web_build/index.pck` | 716,704 bytes |
| `web_build/index.wasm.gz` | 10,111,653 bytes |
| `web_build/index.js` | 279,815 bytes |

CloudBase checks for this release returned HTTP 200 for `index.html`, `index.js`, `index.pck`, and `index.wasm.gz`. One command-line timing sample measured 0.90 seconds for HTML, 2.91 seconds for PCK, 12.94 seconds for JS, and 34.26 seconds for compressed wasm. These timings are CDN/network samples rather than a full browser startup benchmark; the release still transfers the compressed 10.1 MB wasm payload rather than the 39.5 MB raw wasm payload.

## Web Loading Performance Audit - 2026-07-20

BuildId: `20260720-214725`

### Finding

The dominant cold-start cost is downloading the Godot engine from CloudBase, not parsing the project data or building the LevelSelect scene. The same 10.1 MB `index.wasm.gz` took about 40 seconds in cold command-line samples, while the browser's second visit reused the cached asset and reached LevelSelect in 7.6 seconds.

The browser console showed no Godot, GDScript, WebGL, resource, or autoload errors after the final fix. Boot markers showed:

```text
Cold browser run:
wasm downloaded and decompressed: 34.7 s
LevelSelect ready: 47.0 s

Warm browser run:
wasm decompressed from cache: 0.8 s
LevelSelect ready: 7.6 s
```

The in-app test browser cannot access the local loopback server, so an equivalent local browser startup time could not be recorded in this environment. Local export and script compilation completed successfully in 65.6 seconds; this is a build-time check, not a page-load benchmark.

### Current Artifacts

| File | Size |
|---|---:|
| `index.html` | 10,266 bytes |
| `index.js` | 279,815 bytes |
| `index.wasm` | 39,509,339 bytes |
| `index.wasm.gz` | 10,111,653 bytes |
| `index.pck` | 717,056 bytes |
| font subset | 492,644 bytes |
| all JSON data | 139,628 bytes |
| total release files | 50,677,779 bytes |

The raw wasm remains in the release only as a compatibility fallback. Supported browsers request `index.wasm.gz`; they do not also download `index.wasm`. No full Chinese font, `.bak` font, docs, releases, Web exports, screenshots, or temporary directories were found in the PCK. There are no duplicate exported font resources or large image/audio assets.

### Changes

1. The generated page preloads `index.wasm.gz` and `index.pck` so the largest transfers can begin before the Godot launcher asks for them.
2. The compressed loader retains streaming gzip decompression and WebAssembly compilation, with raw wasm used only for unsupported browsers or a failed compressed request.
3. The loading page now reports download, decompression/compilation, resource loading, and game-ready stages. After ten seconds it explains that the first engine download may take longer.
4. Boot diagnostics are concise and report only major stage timing.
5. Synthesized BGM/SFX streams are now created lazily after a user gesture instead of during autoload startup.
6. LevelSelect reports its ready state to the Web loading page.

### Network And Cache

All release files and `latest.json` returned HTTP 200. `index.wasm.gz` and `index.pck` use `application/octet-stream`; the loader converts the decompressed wasm response to `application/wasm`. CloudBase currently returns `Cache-Control: max-age=120` for versioned release assets, including wasm and PCK. This is shorter than ideal and explains why a visit after two minutes may behave like another cold load.

The current CloudBase CLI does not expose per-path cache-header configuration. Configure the hosting cache in the CloudBase console when available:

```text
/releases/**  -> public, max-age=31536000, immutable
/latest.json  -> no-cache
/index.html   -> no-cache or short cache
```

Reference: https://cloud.tencent.com/document/product/876/123943

### Remaining Bottleneck

Godot Standard Web requires a roughly 10.1 MB compressed engine download and then browser-side WASM compilation. On a slow or cold CloudBase edge this transfer can still take 35-45 seconds. The project PCK is already below 1 MB, so further project-resource trimming will not materially remove that engine cost. The highest-value next step is long-lived caching for BuildId-versioned release assets; a later investigation could compare a smaller custom Godot Web template, but that is outside this maintenance pass.
