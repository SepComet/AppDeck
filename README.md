# AppDeck

AppDeck 是一个原生 macOS 视觉工作台：把常用应用放进固定网格，通过 ScreenCaptureKit 显示当前窗口画面，点击卡片后切换到目标应用。

当前工程使用 Swift、SwiftUI、AppKit、ScreenCaptureKit、ApplicationServices 和 CoreGraphics，不包含第三方依赖。最低目标系统为 macOS 14.0，工程默认使用 Apple Silicon `arm64` 架构。

## 当前实现

- Dock 图标和 `applicationShouldHandleReopen` 入口
- AppKit `NSPanel` 面板，支持 Esc 隐藏并在后台保留进程
- `.app` 选择、Bundle ID 去重、最多 6 个应用、删除和拖拽排序
- 设置页优先列出当前正在运行的普通应用，点击即可加入展示白名单
- `~/Library/Application Support/AppDeck/apps.json` 配置持久化，损坏时回到空配置
- 1～6 个应用的布局预设：1×1、2×1、3×1、2×2、3×2
- ScreenCaptureKit 窗口发现和单帧截图
- 每 2 秒刷新，面板隐藏时停止刷新
- 刷新时保留旧快照，新截图成功后静默替换；应用图标叠加在截图左下角
- 未运行、截图不可用和权限缺失时保留图标占位
- NSRunningApplication 激活，以及有辅助功能权限时的 AX 主窗口提升
- 屏幕录制和辅助功能权限的独立检测与设置入口
- 面板关闭后，屏幕右边缘保留悬停展开的 AppDeck 入口
- 支持全局 `⌥Space` 快捷键打开工作台
- 工作台卡片左上角显示 1～6 编号，可直接按数字键切换对应应用

## 打开和编译

1. 在安装了 Xcode 15 或更新版本的 macOS 上打开 `AppDeck.xcodeproj`。
2. 选择 `AppDeck` scheme 和 `My Mac`，目标架构保持 `arm64`。
3. 编译并运行。
4. 在系统设置的「隐私与安全性」中分别授权 AppDeck 使用「屏幕录制」和「辅助功能」。
5. 点击设置齿轮，添加 Chrome、Terminal、Rider、Unity 等应用。

命令行验证可以通过 `DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer` 指定 Xcode。当前开发机使用 Xcode 26.6，已经完成 arm64 Debug 编译和 XCTest；真实窗口截图与跨应用激活仍需在系统设置中授予对应权限后验证。开发运行时请使用固定的 `build/AppDeck.app`，不要把 DerivedData 或旧的 ad-hoc 副本加入权限列表。

## 权限和数据边界

- 屏幕录制权限只用于读取目标窗口的当前画面。
- 辅助功能权限只用于激活和提升目标应用窗口。
- 截图只保留在内存中，不写入磁盘、不上传、不做 OCR。
- 应用配置仅保存 Bundle ID、名称、路径和顺序。

## 已知限制

- 当前边缘入口只部署在主显示器。
- 最小化窗口和无法被 ScreenCaptureKit 捕获的窗口显示占位状态。
- macOS 的跨应用激活策略受目标应用和系统权限影响；没有辅助功能权限时会降级为激活应用本身。
- 辅助功能权限由当前 App bundle 的签名和路径共同识别；本地构建使用稳定的 `AppDeck Local Development` 签名时，授权状态才能跨次构建保留。
- 当前真实运行验证覆盖了 Debug 产物启动、权限缺失提示、面板关闭和同一应用重新激活；屏幕录制/辅助功能权限被拒绝时的截图与窗口提升行为需要用户授权后继续验证。

## 验证命令

```sh
DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer \
  xcodebuild test \
  -project AppDeck.xcodeproj \
  -scheme AppDeck \
  -destination 'platform=macOS,arch=arm64'
```

当前 XCTest 覆盖应用列表持久化、Bundle ID 去重、排序、容量限制和布局；最近一次执行结果为 3 tests, 0 failures。
