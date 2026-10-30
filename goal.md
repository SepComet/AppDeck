# AppDeck — macOS 多应用视觉工作台 MVP 开发规格

## 1. 项目目标

开发一个原生 macOS 应用 AppDeck，用于集中管理用户指定的多个应用，并通过全屏网格预览快速切换应用。

核心使用场景：

用户在日常开发中同时运行 Codex、OpenCode、Rider、Unity、Chrome、Terminal 等多个应用。由于 Dock 中应用较多，定位目标应用比较麻烦。

AppDeck 提供一个独立入口，将用户指定的应用组织成一个固定网格。点击 Dock 图标后，显示这些应用当前窗口的截图预览。用户点击目标卡片，即可切换到对应应用。

核心原则：

- 不接入 Agent API。
- 不读取终端内容或应用内部数据。
- 不进行 OCR、文本分析或 Agent 状态识别。
- 只获取窗口画面，用于视觉辨认。
- 截图只在内存中处理，不持久化、不上传。
- 尽量使用 macOS 原生 API，不引入第三方依赖。

## 2. 技术栈与运行环境

- 语言：Swift
- UI：SwiftUI
- 窗口管理：AppKit
- 窗口枚举与截图：ScreenCaptureKit
- 窗口激活：NSWorkspace、NSRunningApplication、Accessibility API
- 配置持久化：Codable + JSON
- 最低目标系统：macOS 14.0，实际 API 可用性以 Xcode SDK 为准。
- 不使用 Electron、Unity、Godot。
- 不使用第三方 UI 框架。

主要系统框架：

- AppKit
- SwiftUI
- ScreenCaptureKit
- ApplicationServices
- CoreGraphics

## 3. 功能需求

### 3.1 Dock 入口

AppDeck 必须是一个具有正常 Dock 图标的 macOS 应用。

要求：

1. 使用常规应用激活策略，保留 Dock 图标。
2. 点击 Dock 图标时，显示 AppDeck 主面板。
3. 如果 AppDeck 已经运行，不创建新的面板实例。
4. 使用 `applicationShouldHandleReopen(_:hasVisibleWindows:)` 接管 Dock 再次激活事件。
5. 按下 Escape 关闭面板。
6. 面板关闭后，AppDeck 可以继续在后台运行。

第一版不需要菜单栏常驻图标或全局快捷键。

### 3.2 应用管理

用户可以自行选择需要收纳的应用。

要求：

- 通过 NSOpenPanel 选择 `.app` 应用。
- 获取应用的 Bundle Identifier、名称、图标和安装路径。
- Bundle Identifier 作为应用唯一标识。
- 支持添加和移除应用。
- 支持调整应用排列顺序。
- 最多支持 6 个应用。
- 不允许重复添加相同 Bundle Identifier。

配置结构建议：

```
struct AppEntry: Codable, Identifiable {
    var id: String { bundleIdentifier }

    let bundleIdentifier: String
    var displayName: String
    var appPath: String
    var sortIndex: Int
}
```

持久化位置：

`~/Library/Application Support/AppDeck/apps.json`

第一版只需要一个默认分组，不需要多工作区或复杂分组管理。

### 3.3 网格展示

支持两种布局：

- 2×2：最多 4 个应用。
- 2×3：最多 6 个应用。

布局要求：

1. 以当前主显示器为目标。
2. 面板覆盖当前屏幕的主要可视区域。
3. 背景使用半透明暗色遮罩。
4. 卡片等比例展示窗口截图。
5. 卡片圆角、适当留白。
6. 卡片下方展示应用图标和名称。
7. 卡片顺序与应用管理中的顺序一致。
8. 窗口截图不可用时显示应用图标和占位状态。

每个卡片对应一个 App，而不是每一个窗口。

如果某个 App 有多个窗口，优先展示它的主窗口；无法确定主窗口时，选择该应用面积最大的可见窗口。

如果应用未运行，显示应用图标和「未运行」状态，不展示虚假的窗口预览。

### 3.4 窗口发现

通过 ScreenCaptureKit 获取当前可捕获窗口。

主要流程：

1. 调用 `SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)`。
2. 获取当前系统的窗口列表。
3. 根据窗口所属应用的 Bundle Identifier 过滤。
4. 排除 AppDeck 自己的窗口。
5. 排除尺寸过小或无效的窗口。
6. 为每个配置中的应用选出一个代表窗口。

需要考虑：

- 同一个 App 可能有多个窗口。
- 部分应用可能没有标准主窗口。
- 应用可能已经退出。
- 窗口可能处于最小化状态。
- 窗口可能无法被 ScreenCaptureKit 捕获。

第一版只保证正常显示且可捕获的窗口，不需要处理最小化窗口。

不要通过读取窗口标题或解析窗口内容来判断应用状态。

### 3.5 窗口截图

使用 ScreenCaptureKit 提供的单帧截图能力。

优先考虑：

`SCScreenshotManager.captureImage(contentFilter:configuration:)`

使用：

`SCContentFilter(desktopIndependentWindow: window)`

为每个目标窗口建立独立截图过滤器。

截图策略：

- 面板打开时立即刷新所有目标应用。
- 面板显示期间，每隔约 2 秒刷新一次。
- 面板隐藏后停止刷新。
- 截图只保留在内存中。
- 不写入磁盘。
- 不进行网络传输。
- 不使用 OCR。

性能要求：

1. 不使用 60 FPS 实时视频流。
2. 截图输出分辨率应适配卡片大小，不需要原始分辨率。
3. 控制并发截图数量，避免瞬间产生大量资源开销。
4. 禁止重复刷新任务并发堆积。
5. 面板关闭时取消未完成的刷新任务。
6. 使用内存缓存保存当前截图，面板重新打开时重新获取最新画面。

### 3.6 窗口激活

用户点击某个卡片后：

1. 隐藏 AppDeck 面板。
2. 激活目标应用。
3. 尝试将目标应用的主窗口提升至最前面。
4. 将键盘焦点交给目标应用。

优先使用：

- `NSRunningApplication.activate(options:)`
- `AXUIElementCreateApplication(pid)`
- `kAXMainWindowAttribute`
- `AXUIElementPerformAction(..., kAXRaiseAction)`

窗口匹配优先使用 Accessibility API 获取的主窗口信息，并与 ScreenCaptureKit 的窗口信息匹配。

如果无法准确匹配窗口，则退化为只激活对应 App。

如果用户没有授予辅助功能权限：

- 不要让整个功能失效。
- 仍然使用 NSRunningApplication 尝试激活应用。
- 提示用户可以授权辅助功能，以获得精确窗口切换能力。

注意：macOS 对跨应用窗口激活有系统限制，不能保证所有应用都支持完全一致的行为。需要实现合理的失败处理。

## 4. 权限管理

AppDeck 需要分别处理两类权限。

### 屏幕录制权限

用于通过 ScreenCaptureKit 获取其他应用窗口的画面。

没有权限时：

- 不允许持续尝试截图。
- 在界面中展示权限说明。
- 告知用户前往系统设置中的「隐私与安全性 → 屏幕录制」相关设置授权。
- 授权后支持重新检测并刷新。

### 辅助功能权限

用于通过 Accessibility API 精确提升目标窗口。

没有权限时：

- 降级使用 NSRunningApplication 激活 App。
- 提供授权说明。
- 支持重新检测权限状态。

不要将屏幕录制权限和辅助功能权限混为一谈。

## 5. UI 结构

建议使用 SwiftUI 负责卡片、网格和设置界面，AppKit 负责面板生命周期及窗口层级。

主要 UI：

### WorkspacePanel

负责展示应用网格。

包含：

- 顶部标题。
- 当前布局模式。
- 应用卡片网格。
- 权限状态提示。
- 设置入口。

### AppPreviewCard

负责展示单个应用。

包含：

- 窗口截图。
- 应用图标。
- 应用名称。
- 未运行或截图失败状态。

交互：

- 点击：切换到目标应用。
- 悬停：卡片轻微放大。
- 截图失败：显示占位图，不阻断其他卡片。

### SettingsView

负责应用管理。

包含：

- 已添加应用列表。
- 添加应用按钮。
- 移除应用按钮。
- 应用排序。
- 2×2 / 2×3 布局切换。
- 权限状态和授权说明。

## 6. 工程架构

建议采用以下模块划分：

```
AppDeck/
├── App/
│   ├── AppDeckApp.swift
│   └── AppDelegate.swift
│
├── Models/
│   ├── AppEntry.swift
│   └── AppPreviewState.swift
│
├── Services/
│   ├── AppGroupStore.swift
│   ├── RunningAppDiscovery.swift
│   ├── WindowDiscovery.swift
│   ├── WindowCaptureService.swift
│   ├── WindowActivationService.swift
│   └── PermissionManager.swift
│
├── Windows/
│   └── WorkspacePanelController.swift
│
├── Views/
│   ├── WorkspacePanelView.swift
│   ├── AppPreviewCard.swift
│   ├── SettingsView.swift
│   └── PermissionGuideView.swift
│
└── Resources/
```

模块职责：

**AppGroupStore**

负责应用列表的增删改查、排序和 JSON 持久化。

**RunningAppDiscovery**

负责发现当前运行中的目标应用，获取 NSRunningApplication。

**WindowDiscovery**

负责 ScreenCaptureKit 窗口枚举、应用过滤及主窗口选择。

**WindowCaptureService**

负责单帧截图、并发限制、截图缓存和刷新任务。

**WindowActivationService**

负责激活应用及提升指定窗口。

**PermissionManager**

统一检测屏幕录制和辅助功能权限。

**WorkspacePanelController**

负责创建、显示、隐藏和管理 AppKit 面板。

**WorkspacePanelView**

负责网格和卡片展示。

不要过度抽象。每个 Service 只负责一个明确职责，避免引入复杂的事件总线或不必要的依赖注入框架。

## 7. 非功能要求

- 启动速度快。
- 面板呼出响应迅速。
- 截图失败不能影响其他应用卡片。
- 关闭面板后停止截图任务。
- 不允许后台持续占用大量 CPU。
- 配置文件损坏时提供合理的默认配置。
- 应用卸载或移动后能够提示路径失效。
- 不收集用户使用数据。
- 不上传任何窗口截图。
- 不使用第三方依赖。

## 8. 开发阶段

### Phase 0：工程与 Dock 入口

完成：

- 创建原生 macOS 工程。
- 配置正常 Dock 图标。
- 实现 Dock 再次激活回调。
- 实现 NSPanel。
- 点击 Dock 显示面板。
- Escape 关闭面板。

验收：

可以从 Dock 呼出一个空白的 AppDeck 面板，再正常关闭。

### Phase 1：应用管理和窗口发现

完成：

- 选择 `.app` 文件。
- 获取 Bundle Identifier。
- 保存应用列表。
- 获取正在运行的目标应用。
- 枚举并过滤对应窗口。
- 处理应用未运行的情况。

验收：

添加 4 个应用后，能够正确识别它们的运行状态和目标窗口。

### Phase 2：截图和网格

完成：

- 屏幕录制权限检测。
- ScreenCaptureKit 单帧截图。
- 截图缓存。
- 2×2 / 2×3 网格。
- 定时刷新。
- 截图失败占位状态。

验收：

打开面板后，能够看到 4～6 个应用的真实窗口预览，且关闭面板后截图任务停止。

### Phase 3：窗口切换

完成：

- NSRunningApplication 激活。
- Accessibility API 权限检测。
- 主窗口匹配。
- AXRaise 窗口提升。
- 权限缺失时的降级逻辑。

验收：

点击卡片后，AppDeck 关闭，目标应用进入前台；存在多个窗口时，优先激活被预览的主窗口。

### Phase 4：体验完善

完成：

- 卡片悬停效果。
- 动画过渡。
- 设置页面。
- 错误状态处理。
- README 和运行说明。

验收：

整个工作流可以稳定重复使用。

## 9. 测试清单

至少使用以下应用进行测试：

- Chrome
- Terminal
- Rider
- Unity

测试场景：

1. 四个应用全部运行。
2. 部分应用没有运行。
3. 一个应用有多个窗口。
4. 应用退出后重新打开。
5. 屏幕录制权限被拒绝。
6. 辅助功能权限被拒绝。
7. 面板打开期间应用窗口发生变化。
8. 面板打开后立即点击目标卡片。
9. 连续打开和关闭面板。
10. 切换 2×2 和 2×3 布局。

## 10. 明确不做的功能

第一版不要实现：

- Agent 状态监控。
- Claude Code、Codex 等专用集成。
- 终端内容读取。
- OCR。
- 多 Agent 编排。
- 多个工作区分组。
- 自定义网格编辑器。
- 持续实时视频流。
- 云端配置同步。
- 自动窗口布局调整。
- 多显示器独立工作区。
- 开机启动和复杂快捷键系统。

这些功能都不属于当前 MVP 的核心目标。

## 11. Codex 执行要求

请直接承担工程实现工作，而不是只输出架构建议。

执行顺序：

1. 检查当前工作目录和开发环境。
2. 如果没有项目，创建原生 macOS SwiftUI + AppKit 工程。
3. 先完成 Phase 0，验证 Dock 和面板生命周期。
4. 再逐步实现后续阶段。
5. 每个阶段完成后执行编译和必要测试。
6. 发现 API 可用性或系统权限问题时，先验证实际行为，再调整实现。
7. 不要为了提前支持未来功能而扩大当前架构。
8. 不要伪造测试结果，不要在没有实际编译的情况下声称工程可运行。

最终交付：

- 完整 Xcode 工程。
- 可以本地编译运行的 App。
- README。
- 权限配置说明。
- 已知限制和测试结果。

优先保证核心工作流正确：**Dock 点击 → 展示应用网格 → 查看真实窗口 → 点击卡片 → 切换到目标应用。**
