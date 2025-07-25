# SwiftCraftLauncher

## 主要特性

- 纯 SwiftUI 构建，支持 macOS。
- 游戏图标支持图片选择和拖入，**即时预览**，无需保存即可看到效果。
- 选择/拖入图片后，图片会先写入临时目录用于预览，只有在点击“保存”时才会写入到 profile 目录（`~/Library/Application Support/SwiftCraftLauncher/profiles/游戏名/default_game_icon.png`）。
- 所有图片渲染均采用 SwiftUI 的 `AsyncImage(url:)`，**无 AppKit/NSImage 依赖**。
- 支持多种 mod loader（Fabric、Forge 等），采用协议统一接口，易于扩展。
- **缓存机制优化**：每个 namespace 独立存储为单独的 json 文件，提升性能与可维护性。
- **下载优化**：下载文件时如未指定 SHA1，若本地已存在则自动跳过下载，避免重复。
- 代码结构清晰，易于维护和二次开发。

## 运行环境

- macOS 13+（推荐 macOS 14+，以获得最佳 SwiftUI 体验）
- Xcode 15+

## 目录结构

- `Views/AddGame/GameFormView.swift`：新增/编辑游戏主界面，包含图片选择、拖入、预览、保存等逻辑。
- `Common/Views/SidebarView.swift`、`GameDetail/GameInfoDetailView.swift` 等：游戏图标渲染均采用 profile 目录下的图片。

## 图片存储与预览说明

- 选择或拖入图片后，图片会写入临时目录并立即预览。
- 点击“保存”时，图片会被写入到对应游戏的 profile 目录下，文件名为 `default_game_icon.png`。
- 预览和主界面渲染均优先使用 profile 目录下的图片，无需 base64，无需 AppKit。

## 缓存机制说明

- 所有缓存均以 namespace 为单位，分别存储为 `~/Library/Application Support/SwiftCraftLauncher/cache/namespace.json`，互不影响，便于扩展和清理。

## 下载优化说明

- 下载文件时如未指定 SHA1（`expectedSha1` 为空或空字符串），若本地已存在目标文件，则自动跳过下载，提升效率。
- 如指定 SHA1，则严格校验文件完整性。

## 贡献与开发

欢迎提交 issue 或 PR 参与开发！ 