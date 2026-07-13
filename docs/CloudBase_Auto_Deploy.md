# CloudBase 自动导出与部署

本文档用于验证小样阶段的自动化导出与 CloudBase 静态托管部署。当前项目继续使用 Godot 4.7、GDScript、Compatibility 渲染，不启用 Thread Support，不启用 Extensions Support。

当前部署采用版本化发布：每次构建上传到 `releases/<BuildId>/`，根目录只放启动页 `index.html` 和 `latest.json`。

## 1. 准备 CloudBase CLI

请先安装并登录 CloudBase CLI。登录命令：

```powershell
tcb login
```

登录成功后，可运行以下命令确认 `tcb` 可用：

```powershell
tcb --version
```

## 2. 创建本地部署配置

复制根目录下的示例配置：

```powershell
Copy-Item .\deploy.local.example.ps1 .\deploy.local.ps1
```

打开 `deploy.local.ps1`，填写你的 CloudBase 环境 ID：

```powershell
$CloudBaseEnvId = "macropolicymanager-d3cqtfccac7ec"
```

同时填写真实 Godot 可执行文件路径：

```powershell
$GodotExe = "C:\Users\Lenovo\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
```

`deploy.local.ps1` 只需要保留：

```powershell
$CloudBaseEnvId = "macropolicymanager-d3cqtfccac7ec"
$GodotExe = "C:\Users\Lenovo\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
```

不要在 `deploy.local.ps1` 中填写 `$ProjectPath`。脚本会根据自身位置自动推导项目根目录，避免中文项目路径在 PowerShell 编码环境中被误读。

如果 `$GodotExe` 指向 GUI 版 Godot exe，导出脚本会先确认该路径存在，然后优先使用同目录下的 `Godot_v4.7-stable_win64_console.exe` 执行命令行导出。

## 3. 为什么需要版本化部署

Godot Web 导出通常由 `index.html`、`index.js`、`index.wasm`、`index.pck` 等文件共同组成。这些文件必须来自同一次构建。

如果浏览器或 CDN 缓存导致旧 `index.js` 搭配新 `index.pck`，或新 `index.html` 搭配旧 `index.wasm`，Godot 可能停留在加载界面，普通标签页更容易遇到这种缓存混用；无痕窗口正常通常也说明问题来自缓存。

版本化部署的策略是：

- 每次构建生成一个 `BuildId`，格式为 `yyyyMMdd-HHmmss`
- 完整 Godot Web 构建上传到 `releases/<BuildId>/`
- 根目录的 `latest.json` 记录最新构建地址
- 根目录的 `index.html` 是轻量启动页，会请求 `latest.json?v=Date.now()` 并跳转到最新版

这样每个 release 目录内的 JS/PCK/WASM 文件始终来自同一次构建，避免混用。

## 4. 一键构建并部署

在项目根目录运行：

```powershell
.\scripts\build_and_deploy.ps1
```

脚本会先执行：

```powershell
.\scripts\export_web.ps1
```

成功后再执行：

```powershell
.\scripts\deploy_cloudbase.ps1
```

任一步失败都会停止。

CloudBase CLI 在 Windows PowerShell 中偶尔会把普通进度信息写到 stderr，或在已经显示上传成功后返回异常退出码。部署脚本会根据 CLI 输出做二次判断：只有输出明确包含“部署完成/上传成功/失败 0 个文件”时才继续；真正上传失败仍会中止。

默认使用版本化部署。如需临时调试旧的根目录覆盖部署：

```powershell
.\scripts\build_and_deploy.ps1 -LegacyRootDeploy $true
```

## 5. 单独导出 Web

如果只想重新生成 Web 构建：

```powershell
.\scripts\export_web.ps1
```

导出脚本会：

- 清理旧的 `web_build/`
- 使用 Godot Web preset `Web`
- 导出到 `web_build/index.html`
- 检查 `index.html`、`index.js`、`index.wasm`、`index.pck`
- 删除不需要部署的 `.import` 文件和 `.gitkeep`

## 6. 单独部署 CloudBase

如果 `web_build/` 已经存在且只想部署：

```powershell
.\scripts\deploy_cloudbase.ps1
```

版本化部署会执行：

```powershell
tcb hosting deploy "<项目根目录>\web_build" "releases/<BuildId>" -e $CloudBaseEnvId
tcb hosting deploy "<项目根目录>\latest.json" "latest.json" -e $CloudBaseEnvId
tcb hosting deploy "<项目根目录>\root_index\index.html" "index.html" -e $CloudBaseEnvId
```

如需指定构建 ID：

```powershell
.\scripts\deploy_cloudbase.ps1 -BuildId 20260710-120000
```

如需临时调试旧的根目录覆盖部署：

```powershell
.\scripts\deploy_cloudbase.ps1 -LegacyRootDeploy $true
```

## 7. 线上验收

正式测试优先使用 CloudBase 静态托管主网址。主网址会打开启动页，读取最新 `latest.json`，再跳转到 `/releases/<BuildId>/index.html`。

Web 版本应允许页面或主界面在高度不足时滚动，并保留底部安全留白，避免会议记录、顾问提示或确认按钮被系统任务栏遮挡。

当前 PolicyDesk 的右侧信息面板显示“已经发生的宏观状态”，不是政策预测器；玩家选中政策卡但尚未确认时，右侧面板不提前展示政策结果。理论面板是可选辅助面板，默认关闭。

UI 缩放是 Godot 内部 UI scale，不依赖浏览器缩放。普通滚轮用于滚动，Ctrl + 鼠标滚轮用于 UI 缩放，缩放按钮作为辅助入口保留。PolicyDesk 使用 `ScrollContainer + 外侧黑色安全边距` 适配不同浏览器窗口高度和未来桌面版窗口高度。

Web 导出后，`scripts/export_web.ps1` 会自动 patch `index.html`，只阻止 Ctrl + wheel 触发浏览器默认缩放；普通滚轮不受影响。

检查：

- 页面能打开
- `index.html`、`index.js`、`index.wasm`、`index.pck` 均能加载
- 中文显示正常
- 主菜单显示“宏观政策模拟器”和“开始游戏”
- 点击“开始游戏”后进入“消费信心下滑”情境开场
- 情境开场显示模型标签“封闭经济｜短期｜价格刚性｜IS-LM”
- 点击“进入政策会议”后进入政策桌面
- 政策桌面显示顶部标签、左侧政策卡、中间地图、右侧指标和底部顾问
- Ctrl + 鼠标滚轮可以调整 PolicyDesk UI 缩放，普通滚轮仍可滚动
- BGM 在玩家点击后播放
- 政策卡 hover/点击有基础反馈
- 浏览器控制台没有致命错误
- Network 中 `.wasm` 的 `Content-Type` 如不是 `application/wasm`，先记录为性能风险

如果主网址仍旧卡在 Godot 加载界面，可以临时使用以下方式绕过浏览器缓存：

```text
https://你的 CloudBase 访问域名/?v=当前时间戳
```

也可以直接查看根目录的 `latest.json`，确认其中的 `url` 是否指向最新的 `/releases/<BuildId>/index.html`。

## 8. 本地生成文件

版本化部署脚本会在本地生成：

- `root_index/index.html`
- `latest.json`

这些是部署生成物，已通过 `.gitignore` 排除。

## 9. 安全提醒

不要提交以下内容：

- `deploy.local.ps1`
- CloudBase 账号 token
- 密钥、SecretId、SecretKey
- 任何私人访问凭据

这些内容已通过 `.gitignore` 排除。
