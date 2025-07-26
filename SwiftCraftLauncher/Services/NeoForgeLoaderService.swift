import Foundation

struct BMCLNeoForgeVersion: Codable {
    let rawVersion: String
    let installerPath: String
    let mcversion: String
    let version: String
}



class NeoForgeLoaderService {
    enum NeoForgeError: Error, LocalizedError {
        case networkError(String)
        case invalidResponse
        case noMatchingVersion
        case downloadFailed
        case extractionFailed
        case versionJsonNotFound
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg): return String(format: NSLocalizedString("error.neoforge.network.failed", comment: ""), msg)
            case .invalidResponse: return NSLocalizedString("error.neoforge.invalid.response", comment: "")
            case .noMatchingVersion: return NSLocalizedString("error.neoforge.no.matching.version", comment: "")
            case .downloadFailed: return NSLocalizedString("error.neoforge.download.failed", comment: "")
            case .extractionFailed: return NSLocalizedString("error.neoforge.extraction.failed", comment: "")
            case .versionJsonNotFound: return NSLocalizedString("error.neoforge.versionjson.notfound", comment: "")
            }
        }
    }



    /// 获取最新的可用 NeoForge 版本
    static func fetchLatestNeoForgeVersion(for minecraftVersion: String) async throws -> String {
        let versions = try await fetchAllNeoForgeVersions(for: minecraftVersion)
        guard let latest = versions.first else {
            throw NeoForgeError.noMatchingVersion
        }
        return latest
    }

    /// 判断某 MC 游戏版本是否存在可用的 NeoForge 版本
    static func isGameVersionAvailable(for minecraftVersion: String) async throws -> Bool {
        let versions = try await fetchAllNeoForgeVersions(for: minecraftVersion)
        return !versions.isEmpty
    }



    /// 通过BMCLAPI获取所有可用NeoForge版本的version字符串集合
    static func fetchAllNeoForgeVersions(for minecraftVersion: String) async throws -> [String] {
        let url = URLConfig.API.NeoForge.bmclListBase.appendingPathComponent(minecraftVersion)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NeoForgeError.invalidResponse
        }
        let decoder = JSONDecoder()
        let allVersions = try decoder.decode([BMCLNeoForgeVersion].self, from: data)
        return allVersions.map { $0.version }.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })
    }

    /// 获取最新的 NeoForge profile（version.json）
    static func fetchLatestNeoForgeProfileFull(for minecraftVersion: String) async throws -> ForgeLoader {
        
        var loader = try await fetchLatestNeoForgeProfile(for: minecraftVersion)
        let version = loader.version!
        let basePath = "net/neoforged/neoforge/\(version)"
        let jarName = "neoforge-\(version)-client.jar"
        let mavenUrl = URLConfig.API.NeoForge.gitReleasesBase
            .appendingPathComponent(version)
            .appendingPathComponent("neoforge-\(version)-client.jar").absoluteString
        loader.libraries.append(ForgeLibrary(
            name: "net.neoforged:neoforge:\(version):client",
            downloads: ForgeLibraryDownloads(
                artifact: ForgeLibraryArtifact(
                    path: "\(basePath)/\(jarName)",
                    url: mavenUrl,
                    sha1: "",
                    size: 0
                )
            )
        ))
        
        return loader
    }
    
    /// 获取最新的 NeoForge profile（version.json）不拼接的client
    static func fetchLatestNeoForgeProfile(for minecraftVersion: String) async throws -> ForgeLoader {
        let neoForgeVersion = try await fetchLatestNeoForgeVersion(for: minecraftVersion)
        // 1. 查全局缓存
        if let cached = AppCacheManager.shared.get(namespace: "neoforge", key: neoForgeVersion, as: ForgeLoader.self) {
            return cached
        }
        let versionJsonURL = URLConfig.API.NeoForge.gitReleasesBase
            .appendingPathComponent(neoForgeVersion)
            .appendingPathComponent("version.json")
        var finalURLString = versionJsonURL.absoluteString
        let proxy = GameSettingsManager.shared.gitProxyURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !proxy.isEmpty {
            finalURLString = proxy + "/" + versionJsonURL.absoluteString
        }
        let (data, response) = try await URLSession.shared.data(from: URL(string: finalURLString)!)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NeoForgeError.invalidResponse
        }
        
        var loader = try JSONDecoder().decode(ForgeLoader.self, from: data)
        loader.version = neoForgeVersion
        AppCacheManager.shared.set(namespace: "neoforge", key: neoForgeVersion, value: loader)
        return loader
    }


    /// 安装并准备 NeoForge，返回 (loaderVersion, classpath, mainClass)
    static func setupNeoForge(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        let neoForgeProfile = try await fetchLatestNeoForgeProfileFull(for: gameVersion)
        guard let librariesDirectory = AppPaths.librariesDirectory else {
            throw NSError(domain: "NeoForgeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "error.neoforge.meta.libraries.notfound"])
        }
        let forgeManager = ForgeFileManager(librariesDir: librariesDirectory)
        forgeManager.onProgressUpdate = onProgressUpdate
        try await forgeManager.downloadForgeJars(libraries: neoForgeProfile.libraries)
        // neoforge 比较特殊,classpath不需要拼接client和universal.jar
        let result = try await fetchLatestNeoForgeProfile(for: gameVersion)
        // 移除 name 以 net.neoforged:neoforge: 开头且以 :universal 结尾的库
        var filteredResult = result
        filteredResult.libraries = result.libraries.filter { lib in
            !(lib.name.hasPrefix("net.neoforged:neoforge:") && lib.name.hasSuffix(":universal"))
        }
        let classpathString = CommonService.generateClasspath(from: filteredResult, librariesDir: librariesDirectory)
        let mainClass = neoForgeProfile.mainClass
        let loaderVersion = neoForgeProfile.version!
        return (loaderVersion: loaderVersion, classpath: classpathString, mainClass: mainClass)
    }
    static func setup(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        return try await setupNeoForge(for: gameVersion, gameInfo: gameInfo, onProgressUpdate: onProgressUpdate)
    }
}

extension NeoForgeLoaderService: ModLoaderHandler {}
