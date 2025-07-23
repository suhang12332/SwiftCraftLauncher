import Foundation
import CommonCrypto

class DownloadManager {
    enum ResourceType: String {
        case mod, datapack, shader, resourcepack
        
        var folderName: String {
            switch self {
            case .mod: return "mods"
            case .datapack: return "datapacks"
            case .shader: return "shaderpacks"
            case .resourcepack: return "resourcepacks"
            }
        }
        
        init?(from string: String) {
            switch string.lowercased() {
            case "mod": self = .mod
            case "datapack": self = .datapack
            case "shader": self = .shader
            case "resourcepack": self = .resourcepack
            default: return nil
            }
        }
    }
    /// 下载资源文件
    /// - Parameters:
    ///   - game: 游戏信息
    ///   - urlString: 下载地址
    ///   - resourceType: 资源类型（如 "mod", "datapack", "shader", "resourcepack"）
    ///   - expectedSha1: 预期 SHA1 值
    /// - Returns: 下载到的本地文件 URL
    static func downloadResource(for game: GameVersionInfo, urlString: String, resourceType: String, expectedSha1: String? = nil) async throws -> URL {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        guard let type = ResourceType(from: resourceType) else {
            throw NSError(domain: "DownloadManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "未知资源类型"])
        }
        let resourceDir: URL? = {
            switch type {
            case .mod:
                return AppPaths.modsDirectory(gameName: game.gameName)
            case .datapack:
                if url.lastPathComponent.lowercased().hasSuffix(".jar") {
                    return AppPaths.modsDirectory(gameName: game.gameName)
                }
                return AppPaths.datapacksDirectory(gameName: game.gameName)
            case .shader:
                return AppPaths.shaderpacksDirectory(gameName: game.gameName)
            case .resourcepack:
                return AppPaths.resourcepacksDirectory(gameName: game.gameName)
            }
        }()
        guard let resourceDirUnwrapped = resourceDir else {
            throw NSError(domain: "DownloadManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "资源目录获取失败"])
        }
        let destURL = resourceDirUnwrapped.appendingPathComponent(url.lastPathComponent)
        return try await downloadFile(urlString: urlString, destinationURL: destURL, expectedSha1: expectedSha1)
    }
    /// 通用下载文件到指定路径（不做任何目录结构拼接）
    /// - Parameters:
    ///   - urlString: 下载地址
    ///   - destinationURL: 目标文件路径
    ///   - expectedSha1: 预期 SHA1 值
    /// - Returns: 下载到的本地文件 URL
    static func downloadFile(urlString: String, destinationURL: URL, expectedSha1: String? = nil) async throws -> URL {
        Logger.shared.info("下载文件 \(urlString) -> \(destinationURL.path)")
        var finalURLString = urlString
        if urlString.hasPrefix("https://github.com/") {
            let proxy = GameSettingsManager.shared.gitProxyURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !proxy.isEmpty {
                finalURLString = proxy + "/" + urlString
            }
        }
        guard let url = URL(string: finalURLString) else { throw URLError(.badURL) }
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destinationURL.path) {
            if let expectedSha1 = expectedSha1 {
                let actualSha1 = try? calculateFileSHA1(at: destinationURL)
                if actualSha1 == expectedSha1 {
                    Logger.shared.info("文件已存在且 SHA1 校验通过，跳过下载: \(destinationURL.path)")
                    return destinationURL
                }
            } else {
                Logger.shared.info("文件已存在，跳过下载: \(destinationURL.path)")
                return destinationURL
            }
        }
        
        // Download with retry
        let retryCount = 3
        let retryDelay: TimeInterval = 2
        var lastError: Error?
        
        for attempt in 0..<retryCount {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                try data.write(to: destinationURL)
                if let expectedSha1 = expectedSha1 {
                    let actualSha1 = try calculateFileSHA1(at: destinationURL)
                    if actualSha1 != expectedSha1 {
                        try? fileManager.removeItem(at: destinationURL)
                        throw NSError(domain: "DownloadManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "SHA1 校验失败"])
                    }
                }
                return destinationURL
            } catch {
                lastError = error
                if attempt < retryCount - 1 {
                    Logger.shared.warning("下载失败，\(retryDelay)秒后重试 (\(attempt + 1)/\(retryCount)): \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? URLError(.unknown)
    }

    static func calculateFileSHA1(at url: URL) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }
        var context = CC_SHA1_CTX()
        CC_SHA1_Init(&context)
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: 1024 * 1024)
            if !data.isEmpty {
                data.withUnsafeBytes { bytes in
                    _ = CC_SHA1_Update(&context, bytes.baseAddress, CC_LONG(data.count))
                }
                return true
            }
            return false
        }) {}
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = CC_SHA1_Final(&digest, &context)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
} 
