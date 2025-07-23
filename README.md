# SwiftCraftLauncher

> 本项目采用 [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.txt) 许可证开源。

## 🚀 简介

SwiftCraftLauncher 是一个现代化的 macOS版的 Minecraft 启动器，为用户提供快速、高效的应用程序访问体验。通过简洁的界面和智能的搜索功能，让您的应用程序启动变得更加便捷。

## ✨ 主要特性

- 🎯 快速启动应用程序
- 🔍 智能搜索功能
- 🎨 现代化用户界面
- ⚡️ 高性能运行
- 🛠 可自定义配置
- 📦 **Modrinth 项目详情集成**: 查看 Modrinth 上的项目详细信息，包括版本、作者和链接。
- 🎮 **游戏信息管理**: 显示本地游戏版本信息，并支持启动游戏以及管理相关设置。
- 🧩 **Fabric Loader 支持**: 集成 Fabric Loader 管理与自动安装，便于模组环境搭建。
- 🛡 **启动命令构建优化**: Minecraft 启动命令构建器重构，JVM 参数拼接更清晰，移除冗余参数，提升启动兼容性与可维护性。
- 🌍 **全局资源添加（Global Resource Add）**: 支持通过统一的 Sheet 添加 mod、数据包（datapack）、光影（shader）、资源包（resourcepack）等多种资源类型，自动筛选兼容的本地游戏，支持依赖检测与一键下载、版本筛选、国际化和优化的用户体验。
- 🗂 **一键打开游戏目录**: 在资源详情页可一键打开当前游戏所在的文件夹（Finder）。

## 🧑‍💻 开发者接口变更

### ModrinthDependencyDownloader.downloadMainResourceOnly 新增参数

`downloadMainResourceOnly` 现已支持 `filterLoader: Bool` 参数（默认 `true`），用于控制是否对 mod loader 进行过滤：

```swift
let success = await ModrinthDependencyDownloader.downloadMainResourceOnly(
    mainProjectId: "xxxx",
    gameInfo: gameInfo,
    query: "mod",
    gameRepository: gameRepository,
    filterLoader: false // 不进行 loader 过滤
)
```

- `filterLoader = true`（默认）：只下载与当前游戏 loader 匹配的版本。
- `filterLoader = false`：不对 loader 进行过滤，下载所有可用版本。

## 🛠 技术栈

- SwiftUI
- Swift
- macOS

## 📦 安装要求

- macOS 11.0 或更高版本
- Xcode 13.0 或更高版本
- Swift 5.5 或更高版本

## 🚀 快速开始

1. 克隆仓库
```bash
git clone https://github.com/suhang12332/SwiftCraftLauncher.git
```

2. 打开项目
```bash
cd SwiftCraftLauncher
open SwiftCraftLauncher.xcodeproj
```

3. 在 Xcode 中构建并运行项目

## 📝 许可证

本项目采用 GNU Affero General Public License v3.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献

欢迎提交 Pull Requests 和 Issues！

## 📧 联系方式

如有任何问题或建议，请随时联系我。 

## 🆕 近期更新

- 新增全局资源添加 Sheet，支持 mod、datapack、shader、resourcepack 的一键下载、依赖检测与版本筛选。
- 资源详情页支持一键打开游戏目录（Finder）。
- 兼容 macOS 14，更新 onChange API 用法，消除弃用警告。
- 重构 Minecraft 启动命令构建器，移除 `additionalArgs` 参数，JVM 启动参数拼接逻辑更简洁。
- 支持 Fabric Loader 的自动安装与管理。
- 优化代码结构，提升可读性与维护性。
- 删除未使用的旧文件，精简项目结构。 