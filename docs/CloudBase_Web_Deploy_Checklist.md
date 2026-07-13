# CloudBase Web 部署检查清单

本清单用于验证 Godot 4.7 单线程 Web Export 到 CloudBase 静态托管的路线是否可行。当前验证项目使用 GDScript、2D、Compatibility 渲染，不使用 C#、GDExtension、Thread Support 或需要 COOP/COEP 响应头的功能。

## 1. 本地导出

1. 使用 Godot 4.7 打开项目根目录。
2. 打开 Project Settings，确认 Rendering Method 为 `gl_compatibility` / Compatibility。
3. 打开 Export 面板，选择 `Web` 预设。
4. 确认导出路径为 `web_build/index.html`。
5. 确认未启用 Thread Support。
6. 确认未启用 Extensions/GDExtension 支持。
7. 执行 Web 导出。

导出后，`web_build/` 中至少应包含：

- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`

## 2. 本地浏览器验证

不要直接双击 `index.html`。请在 `web_build/` 目录启动一个本地静态服务器，例如：

```bash
python -m http.server 8080
```

然后访问：

```text
http://localhost:8080/
```

检查项目：

- 页面能打开并显示主菜单。
- 点击“点击开始”后进入测试场景。
- BGM 在点击后播放，而不是页面加载时自动播放。
- 点击政策卡后出现 Tween 动画。
- 点击政策卡后指标 Y、u、π、Debt 发生变化。
- 点击政策卡后播放卡牌音效。
- 浏览器控制台没有致命错误。
- Network 面板中 `.wasm`、`.pck`、`.js` 均成功加载。

## 3. 上传到 CloudBase 静态托管

1. 进入 CloudBase 控制台。
2. 打开对应环境。
3. 进入“静态网站托管”。
4. 开通或进入静态托管服务。
5. 将 `web_build/` 目录中的所有文件上传到静态托管根目录。
6. 确保托管根目录下直接存在 `index.html`，不要额外套一层 `web_build/` 文件夹。
7. 发布后打开 CloudBase 提供的访问域名。

## 4. CloudBase 线上检查

上线后逐项检查：

- `index.html` 是否能打开。
- `.wasm` 是否加载成功。
- `.pck` 是否加载成功。
- `.js` 是否加载成功。
- 点击“点击开始”后 BGM 是否播放。
- 点击政策卡后是否有动画和音效。
- 指标数字是否变化。
- 浏览器控制台是否有致命错误。
- Network 面板中 `.wasm` 的 `Content-Type` 是否为 `application/wasm`。

如果 `.wasm` 的 `Content-Type` 不是 `application/wasm`，先记录为性能风险，不要立即放弃部署路线。重点观察项目是否仍可加载、运行和播放音频。

## 5. 线程与响应头说明

当前验证项目不启用 Thread Support，因此不需要配置 COOP/COEP 响应头。

请不要为了第一版验证主动开启多线程 Web 导出。CloudBase 静态托管是否方便配置 COOP/COEP 尚未确认，所以第一版以单线程 Web 导出为准。

## 6. 人工确认记录

请在完成 CloudBase 线上测试后记录：

- 测试日期：
- Godot 版本：
- CloudBase 访问 URL：
- 浏览器与版本：
- `index.html` 是否打开：
- `.wasm` 是否加载：
- `.wasm Content-Type`：
- `.pck` 是否加载：
- `.js` 是否加载：
- 点击后 BGM 是否播放：
- 点击政策卡后 SFX 是否播放：
- 控制台是否有致命错误：
- 结论：通过 / 暂缓 / 失败
