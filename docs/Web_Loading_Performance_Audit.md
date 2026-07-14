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
