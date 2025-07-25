import Foundation
//import ZIPFoundation

struct BMCLForgeFile: Codable {
    let format: String
    let category: String
    let hash: String
}

struct BMCLForgeVersion: Codable {
    let _id: String
    let __v: Int
    let build: Int
    let files: [BMCLForgeFile]
    let mcversion: String
    let modified: String
    let version: String
}

class ForgeLoaderService {
    enum ForgeLoaderError: Error, LocalizedError {
        case networkError(String)
        case invalidResponse
        case noMatchingVersion
        case downloadFailed
        case extractionFailed
        case versionJsonNotFound
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg): return String(format: "error.forge.network.failed".localized(), msg)
            case .invalidResponse: return "error.forge.invalid.response".localized()
            case .noMatchingVersion: return "error.forge.no.matching.version".localized()
            case .downloadFailed: return "error.forge.installer.download.failed".localized()
            case .extractionFailed: return "error.forge.installer.extraction.failed".localized()
            case .versionJsonNotFound: return "error.forge.version.json.notfound".localized()
            }
        }
    }

    static func fetchLatestForgeProfile(for minecraftVersion: String) async throws -> ForgeLoader {
        let forgeVersion = try await fetchLatestForgeVersion(for: minecraftVersion)
        // 1. 查全局缓存
        if let cached = AppCacheManager.shared.get(namespace: "forge", key: forgeVersion, as: ForgeLoader.self) {
            return cached
        }
        // 2. 直接下载 version.json
        let versionJsonURL = URLConfig.API.Forge.gitReleasesBase
            .appendingPathComponent(forgeVersion)
            .appendingPathComponent("version.json")
        var finalURLString = versionJsonURL.absoluteString
        let proxy = GameSettingsManager.shared.gitProxyURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !proxy.isEmpty {
            finalURLString = proxy + "/" + versionJsonURL.absoluteString
        }
        let (data, response) = try await URLSession.shared.data(from: URL(string: finalURLString)!)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ForgeLoaderError.invalidResponse
        }
        var loader = try JSONDecoder().decode(ForgeLoader.self, from: data)
        // 替换指定library的artifact.url
        let targetName = "net.minecraftforge:forge:\(forgeVersion):client"
        let targetURL = URLConfig.API.Forge.gitReleasesBase
            .appendingPathComponent(forgeVersion)
            .appendingPathComponent("forge-\(forgeVersion)-client.jar").absoluteString
        for i in 0..<loader.libraries.count {
            if loader.libraries[i].name == targetName {
                loader.libraries[i].downloads.artifact.url = targetURL
            }
        }
        AppCacheManager.shared.set(namespace: "forge", key: forgeVersion, value: loader)
        return loader
    }

    /// 通过BMCLAPI获取所有可用Forge版本详细信息
    static func fetchAllForgeVersions(for minecraftVersion: String) async throws -> [BMCLForgeVersion] {
        let url = URLConfig.API.Forge.bmclListBase.appendingPathComponent(minecraftVersion)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ForgeLoaderError.invalidResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode([BMCLForgeVersion].self, from: data)
    }
    
    /// 通过BMCLAPI获取所有可用Forge版本详细信息
    static func fetchAllForgeVersionStrings(for minecraftVersion: String) async throws -> [String] {
        let versions = try await fetchAllForgeVersions(for: minecraftVersion)
        return versions.map { $0.mcversion+"-"+$0.version }
            .sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })
    }

    static func fetchLatestForgeVersion(for minecraftVersion: String) async throws -> String {
        let versions = try await fetchAllForgeVersions(for: minecraftVersion)
        guard let latest = versions.last else {
            throw ForgeLoaderError.noMatchingVersion
        }
        return latest.mcversion + "-" + latest.version
    }



    static func setupForge(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        let forgeProfile = try await fetchLatestForgeProfile(for: gameVersion)
        guard let librariesDirectory = AppPaths.librariesDirectory else {
            throw NSError(domain: "ForgeLoaderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "error.forge.meta.libraries.notfound".localized()])
        }
        let forgeManager = ForgeFileManager(librariesDir: librariesDirectory)
        forgeManager.onProgressUpdate = onProgressUpdate
        try await forgeManager.downloadForgeJars(libraries: forgeProfile.libraries)
        let classpathString = CommonService.generateClasspath(from: forgeProfile, librariesDir: librariesDirectory)
        let mainClass = forgeProfile.mainClass
        let loaderVersion = forgeProfile.id
        return (loaderVersion: loaderVersion, classpath: classpathString, mainClass: mainClass)
    }

    /// 判断某 MC 游戏版本是否存在可用的 Forge 版本
    static func isGameVersionAvailable(for minecraftVersion: String) async throws -> Bool {
        let versions = try await fetchAllForgeVersions(for: minecraftVersion)
        return !versions.isEmpty
    }

    static func setup(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        return try await setupForge(for: gameVersion, gameInfo: gameInfo, onProgressUpdate: onProgressUpdate)
    }
}

extension ForgeLoaderService: ModLoaderHandler {} 
 
