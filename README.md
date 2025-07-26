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
- 🔥 **NeoForge Loader 支持**: 集成 NeoForge Loader 管理与自动安装，支持最新的 Forge 生态。
- ⚒️ **Forge Loader 支持**: 集成 Forge Loader 管理与自动安装，支持经典 Forge 模组生态。


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
- ☕️ **Java 启动路径优先级**: 启动游戏时优先使用每个游戏 profile 单独配置的 Java 路径（`gameInfo.javaPath`），如未设置则回退到全局设置的 Java 路径。
- 🔍 **Java 版本自动检测**: 在设置界面选择 Java 路径后，自动检测并显示 Java 版本，方便用户确认环境。
- 📊 **内存分配区间滑块**: 全局内存设置支持区间滑块（Xms/Xmx），可视化设置最小/最大内存，支持每个游戏单独配置。
- 🌍 **多语言选择器支持国旗图标**: 语言选择器支持显示国旗 emoji，提升辨识度和美观度。
- 📁 **路径选择控件优化**: 路径选择控件支持 Finder 风格的面包屑导航，长路径自动省略，支持重置和选择目录。
- ⚒️ **Forge Loader 支持**: 集成 Forge Loader 管理与自动安装，支持经典 Forge 模组生态。
- 🔥 **NeoForge Loader 支持**: 集成 NeoForge Loader 管理与自动安装，支持最新的 Forge 生态。 
- 🔧 **Mod Classpath 优先级与 NeoForge 兼容性增强**: mod classpath 优先于主 jar，NeoForge loader 相关库过滤更健壮。
- 🛠 **SwiftUI 兼容性与循环依赖修复**: 修复了 SwiftUI `.onChange`、`.onAppear` 相关的 AttributeGraph 循环依赖问题，提升界面稳定性。
- 🖼️ **游戏图标存储优化**: 游戏图标支持图片选择和拖入，即时预览，采用 SwiftUI AsyncImage 渲染，无 AppKit 依赖，优化存储路径管理（取消之前的base64）。
- 💾 **缓存机制优化**: 根据命名空间拆分缓存文件，每个 namespace 独立存储为单独的 json 文件，提升性能与可维护性。
