import Foundation

struct ResourceFileManager {
    /// 删除指定游戏 profile 下 type 文件夹内的资源文件
    /// - Parameters:
    ///   - gameInfo: 游戏信息
    ///   - resource: 资源对象（需包含 type 和 slug）
    static func deleteResourceFile(for gameInfo: GameVersionInfo, resource: ModrinthProjectDetail) {
        let type = resource.projectType
        guard let fileName = resource.fileName else { return }
        guard let dir = directory(for: type, gameName: gameInfo.gameName, fileName: fileName) else { return }
        
            let fileURL = dir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func directory(for type: String, gameName: String, fileName: String) -> URL? {
        switch type.lowercased() {
        case "mod":
            return AppPaths.modsDirectory(gameName: gameName)
        case "datapack":
            if fileName.lowercased().hasSuffix(".jar") {
                return AppPaths.modsDirectory(gameName: gameName)
            }
            return AppPaths.datapacksDirectory(gameName: gameName)
        case "shaderpack":
            return AppPaths.shaderpacksDirectory(gameName: gameName)
        case "resourcepack":
            return AppPaths.resourcepacksDirectory(gameName: gameName)
        default:
            return nil
        }
    }
} 
