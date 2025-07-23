import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// 工具类：负责将本地 jar/zip 文件导入到指定资源目录
struct LocalResourceInstaller {
    enum ResourceType {
        case mod, datapack, resourcepack
        
        var directoryName: String {
            switch self {
            case .mod: return "mods"
            case .datapack: return "datapacks"
            case .resourcepack: return "resourcepacks"
            }
        }
        
        /// 支持的文件扩展名
        var allowedExtensions: [String] {
            switch self {
            case .mod: return ["jar"]
            case .datapack, .resourcepack: return ["zip"]
            }
        }
    }
    
    enum InstallError: Error, LocalizedError {
        case invalidFileType
        case fileCopyFailed(Error)
        case securityScopeFailed
        case destinationUnavailable
        
        var errorDescription: String? {
            switch self {
            case .invalidFileType:
                return "不支持的文件类型。请导入 .jar 或 .zip 文件。"
            case .fileCopyFailed(let err):
                return "文件复制失败：\(err.localizedDescription)"
            case .securityScopeFailed:
                return "无法访问所选文件。"
            case .destinationUnavailable:
                return "目标文件夹不存在。"
            }
        }
    }
    
    /// 安装本地资源文件到指定目录
    /// - Parameters:
    ///   - fileURL: 用户选中的本地文件
    ///   - resourceType: 资源类型（mods/datapacks/resourcepacks）
    ///   - gameRoot: 游戏根目录（如 .minecraft）
    /// - Throws: InstallError
    static func install(fileURL: URL, resourceType: ResourceType, gameRoot: URL) throws {
        // 检查扩展名
        guard let ext = fileURL.pathExtension.lowercased() as String?,
              resourceType.allowedExtensions.contains(ext) else {
            throw InstallError.invalidFileType
        }
        // 目标目录
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: gameRoot.path, isDirectory: &isDir), isDir.boolValue else {
            throw InstallError.destinationUnavailable
        }
        // 处理安全作用域
        let needsSecurity = fileURL.startAccessingSecurityScopedResource()
        defer { if needsSecurity { fileURL.stopAccessingSecurityScopedResource() } }
        if !needsSecurity {
            throw InstallError.securityScopeFailed
        }
        // 目标文件路径
        let destURL = gameRoot.appendingPathComponent(fileURL.lastPathComponent)
        // 如果已存在，先移除
        if FileManager.default.fileExists(atPath: destURL.path) {
            try? FileManager.default.removeItem(at: destURL)
        }
        do {
            try FileManager.default.copyItem(at: fileURL, to: destURL)
        } catch {
            throw InstallError.fileCopyFailed(error)
        }
    }
}

extension LocalResourceInstaller {
    struct ImportButton: View {
        let query: String
        let gameName: String
        let onResourceChanged: () -> Void

        @State private var showImporter = false
        @State private var importErrorMessage: String?

        var body: some View {
            Button {
                showImporter = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .controlSize(.large)
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: {
                    if #available(macOS 11.0, *) {
                        var types: [UTType] = []
                        if query == "mod", let jarType = UTType(filenameExtension: "jar") {
                            types.append(jarType)
                        }
                        if query == "datapack" || query == "resourcepack" {
                            types.append(.zip)
                        }
                        return types
                    } else {
                        return []
                    }
                }(),
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first else { return }
                    let gameRootOpt = AppPaths.resourceDirectory(for: query, gameName: gameName)
                    guard let gameRoot = gameRootOpt else {
                        importErrorMessage = "找不到游戏目录"
                        return
                    }
                    // 兼容原有扩展名校验
                    let allowedExtensions: [String]
                    switch query {
                    case "mod": allowedExtensions = ["jar"]
                    case "datapack", "resourcepack": allowedExtensions = ["zip"]
                    default: allowedExtensions = []
                    }
                    do {
                        guard let ext = fileURL.pathExtension.lowercased() as String?, allowedExtensions.contains(ext) else {
                            throw LocalResourceInstaller.InstallError.invalidFileType
                        }
                        try LocalResourceInstaller.install(
                            fileURL: fileURL,
                            resourceType: .mod, // 这里 resourceType 只用于 install 的 allowedExtensions 校验，已在上面手动校验
                            gameRoot: gameRoot
                        )
                        onResourceChanged()
                    } catch {
                        importErrorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert("导入失败", isPresented: Binding(get: { importErrorMessage != nil }, set: { _ in importErrorMessage = nil })) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }
} 
 