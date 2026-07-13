# CloudBase Loading Issue Report

诊断时间：2026-07-10 12:25 +08:00

线上地址：

```text
https://macropolicymanager-d3cqtfccac7ec-1426634259.tcloudbaseapp.com
```

## 1. 本地导出结论

已运行：

```powershell
.\scripts\export_web.ps1
```

结果：导出成功。Godot 4.7 console 输出无致命错误，`index.pck` 大小为 `13,320,104 bytes`。

本地 Godot 短启动检查：

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 3
```

结果：退出码 0，无脚本解析错误。

## 2. 本地 web_build 文件大小和哈希

| 文件 | 大小 bytes | SHA256 |
|---|---:|---|
| `index.html` | 5,464 | `732F9D2D8049874ACF192D8743415EA9C5C814974DF76DE0EDAD656E99A80E22` |
| `index.js` | 279,815 | `68586D6DAAFC93C6E697B3FB258976874AA7459B8931165EBB1DC3C9614CC42C` |
| `index.wasm` | 39,509,339 | `7EDA98958EB09135A1ACB54A4323A00B1A55AF1997F15FA1CDC2B93E3DF46656` |
| `index.pck` | 13,320,104 | `D926ADBE08B825097C72889DAE1A136554AFF8A73344B9BE12447AB59E702CC0` |

附加文件存在：

| 文件 | 大小 bytes |
|---|---:|
| `index.audio.worklet.js` | 7,298 |
| `index.audio.position.worklet.js` | 2,973 |
| `health.html` | 297 |

## 3. 本地 HTTP 运行检查

尝试通过 Python 启动：

```powershell
python -m http.server 8000 --bind 127.0.0.1
```

在当前 Codex/PowerShell 环境中，后台服务或并行 curl 无法稳定连上 `127.0.0.1:8000`，因此未能自动确认本地浏览器是否进入游戏。

已确认：

- 本地导出文件完整。
- Godot Web 导出无致命错误。
- Godot 本地 headless 短启动无脚本解析错误。

## 4. 线上 curl -I 检查结果

### index.html

- HTTP：`200 OK`
- Content-Type：`text/html`
- Content-Length：`5464`
- Cache-Control：`max-age=120`
- ETag：`"91b0b96361b835fa680db8c5b0da2e00"`
- Last-Modified：`Thu, 09 Jul 2026 19:41:13 GMT`

### index.js

- HTTP：`200 OK`
- Content-Type：`application/javascript`
- Content-Length：`279815`
- Cache-Control：`max-age=31536000`
- ETag：`"b446038961637ab9195fec557690806e"`
- Last-Modified：`Thu, 09 Jul 2026 19:41:13 GMT`

### index.wasm

- HTTP：`200 OK`
- Content-Type：`application/wasm`
- Content-Length：`39509339`
- Cache-Control：`max-age=120`
- ETag：`"4371f72a4958d565d04af2450f03f3cd-38"`
- Last-Modified：`Thu, 09 Jul 2026 19:41:14 GMT`

### index.pck

- HTTP：`200 OK`
- Content-Type：`application/octet-stream`
- Content-Length：`13320104`
- Cache-Control：`max-age=120`
- ETag：`"d627bccc08755a63e173563af3b6e5da-13"`
- Last-Modified：`Thu, 09 Jul 2026 19:41:14 GMT`

### Audio worklets

`index.audio.worklet.js`

- HTTP：`200 OK`
- Content-Type：`application/javascript`
- Content-Length：`7298`
- Cache-Control：`max-age=31536000`

`index.audio.position.worklet.js`

- HTTP：`200 OK`
- Content-Type：`application/javascript`
- Content-Length：`2973`
- Cache-Control：`max-age=31536000`

## 5. 线上下载文件哈希

| 文件 | 线上 SHA256 | 是否匹配本地 |
|---|---|---|
| `index.html` | `732F9D2D8049874ACF192D8743415EA9C5C814974DF76DE0EDAD656E99A80E22` | 是 |
| `index.js` | `68586D6DAAFC93C6E697B3FB258976874AA7459B8931165EBB1DC3C9614CC42C` | 是 |
| `index.wasm` | `7EDA98958EB09135A1ACB54A4323A00B1A55AF1997F15FA1CDC2B93E3DF46656` | 是 |
| `index.pck` | `D926ADBE08B825097C72889DAE1A136554AFF8A73344B9BE12447AB59E702CC0` | 是 |

结论：当前线上根目录核心 Godot 文件与本地最新导出完全一致，未发现上传损坏或 CDN 提供旧核心文件。

## 6. tcb hosting list 结果

确认线上存在：

- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`
- `index.audio.worklet.js`
- `index.audio.position.worklet.js`
- `health.html`

同时发现线上仍存在旧的 `.import` 文件：

- `index.apple-touch-icon.png.import`
- `index.icon.png.import`
- `index.png.import`

这些 `.import` 文件不是 Godot Web runtime 的加载目标，通常不应导致加载页卡住，但建议后续清理。

关键状态：

- `latest.json` 当前为 `404 Not Found`。
- 根目录 `/` 当前返回的是 Godot 原始 `index.html`，不是版本化启动页。
- 当前线上还没有体现版本化部署入口。

## 7. export_presets.cfg 检查结论

检查结果：

- preset 名称：`Web`
- platform：`Web`
- 导出路径：`web_build/index.html`
- `variant/thread_support=false`
- `variant/extensions_support=false`
- 未发现 C# 项目文件。
- 未发现 GDExtension 文件。
- 未启用多线程 Web 导出。

## 8. index.html / index.js 引用一致性

本地和线上 `index.html` 一致：

- `<script src="index.js"></script>`
- `executable="index"`
- `fileSizes.index.pck=13320104`
- `fileSizes.index.wasm=39509339`
- `GODOT_THREADS_ENABLED=false`

`index.js` 会按 `executable` 加载：

- `index.wasm`
- `index.pck`
- `index.audio.worklet.js`
- `index.audio.position.worklet.js`

线上对应文件均存在，文件大小与本地一致。

## 9. healthcheck 页面

已创建并上传：

```text
/health.html
```

访问检查：

- HTTP：`200 OK`
- Content-Type：`text/html`
- Content-Length：`297`
- 页面内容包含：`CloudBase static hosting OK`

结论：CloudBase 静态托管本身可以正常提供静态 HTML 文件。

## 10. 是否发现 wasm/pck/js 缺失或不一致

未发现。

- `index.wasm` 可访问，`Content-Type=application/wasm`，大小匹配。
- `index.pck` 可访问，大小匹配。
- `index.js` 可访问，大小匹配。
- 四个核心文件线上下载哈希与本地完全一致。

## 11. 是否怀疑 CDN 缓存

部分怀疑，但不是唯一解释。

支持缓存相关的证据：

- `index.js` 和 audio worklet 的 `Cache-Control=max-age=31536000`。
- 根目录尚未切换到版本化启动页，`latest.json` 仍为 404。

不支持“核心文件旧缓存混用”的证据：

- 当前 curl 下载的线上 `index.html/index.js/index.wasm/index.pck` 与本地哈希完全一致。
- 无痕窗口也卡住，说明不仅是普通浏览器缓存问题。

## 12. 是否怀疑 Content-Type / MIME

暂不作为首要怀疑。

- `index.wasm` 是 `application/wasm`，正常。
- `index.js` 和 worklet 是 `application/javascript`，正常。
- `index.pck` 是 `application/octet-stream`，可接受。

## 13. 是否怀疑 Godot runtime

是，当前更倾向怀疑 Godot runtime 初始化阶段或浏览器环境中的 runtime 错误。

原因：

- 静态托管正常。
- 核心文件存在且哈希一致。
- MIME 关键项正常。
- 页面卡在 Godot 加载层，说明问题可能发生在 `engine.startGame()` 之后、进入场景之前。

当前无法在 Codex 环境中用浏览器自动化抓取线上控制台：Playwright 库存在，但内置浏览器缺失；改用系统 Edge 时被当前环境网络策略拦截，报 `net::ERR_NETWORK_ACCESS_DENIED`。

## 14. 未执行的诊断步骤

未添加 `Build: cloud-debug-001` 到 MainMenu/TestScene。

原因：已经发现线上根目录尚未部署版本化启动页，且核心文件哈希一致但 runtime 卡住。此时添加场景内标识未必能提供新信息，因为如果 Godot runtime 没进入场景，标识不会显示。

## 15. 下一步建议

1. 先执行版本化部署：

```powershell
.\scripts\build_and_deploy.ps1
```

这会让根目录变成轻量启动页，并部署 `latest.json`。之后访问主网址应跳转到：

```text
/releases/<BuildId>/index.html
```

2. 部署后检查：

```powershell
curl.exe --ssl-no-revoke -I "https://macropolicymanager-d3cqtfccac7ec-1426634259.tcloudbaseapp.com/latest.json"
curl.exe --ssl-no-revoke -L "https://macropolicymanager-d3cqtfccac7ec-1426634259.tcloudbaseapp.com/latest.json"
```

3. 浏览器中打开 DevTools Console，记录第一条红色错误。重点看：

- WebAssembly 编译/实例化错误
- WebGL 2.0 不可用
- `index.pck` fetch / decode / mount 失败
- Audio worklet 加载错误
- Cross-origin isolation / SharedArrayBuffer 相关错误

4. 如果版本化部署后仍卡住，再添加 `Build: cloud-debug-001`。如果仍看不到该标识，可确认问题发生在 Godot runtime 进入主场景之前。

5. 后续可清理 CloudBase 根目录遗留的 `.import` 文件，但这不是当前卡住问题的主要嫌疑。

## 16. 最终修复结果

更新日期：2026-07-13

CloudBase 线上加载问题已修复，Godot Web + CloudBase 自动部署链路已经验证通过，网站可以正常运行。

最终采用的修复策略：

- 使用版本化部署，完整 Godot Web 构建上传到 `releases/<BuildId>/`。
- 根目录 `index.html` 改为轻量启动页。
- 根目录 `latest.json` 指向最新 release。
- 启动页通过 `latest.json?v=Date.now()` 获取最新版本，避免旧 `index.js`、`index.wasm`、`index.pck` 混用。
- `latest.json` 和启动页改为无 BOM UTF-8 输出，降低浏览器 JSON 解析风险。
- 导出脚本会在导出前清理 `latest.json` 和 `root_index/`，避免部署元数据进入 Godot `.pck`。

最终线上核验结果：

- 主网址可以访问。
- `latest.json` 可以访问，并指向最新 release。
- release 目录中的 `index.html`、`index.js`、`index.wasm`、`index.pck` 均可访问。
- `index.wasm` 的 `Content-Type` 为 `application/wasm`。
- Godot Web 页面可以正常运行。
