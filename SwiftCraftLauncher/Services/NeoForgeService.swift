import Foundation

struct BMCLNeoForgeVersion: Codable {
    let rawVersion: String
    let installerPath: String
    let mcversion: String
    let version: String
}

class NeoForgeService {
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
        guard let latest = versions.last else {
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
    static func fetchLatestNeoForgeProfile(for minecraftVersion: String) async throws -> ForgeLoader {
        let neoForgeVersion = try await fetchLatestNeoForgeVersion(for: minecraftVersion)
        // 可加缓存
        let versionJsonURL = URL(string: "https://github.com/neoforged/neoforge-client/releases/download/")!
            .appendingPathComponent(neoForgeVersion)
            .appendingPathComponent("version.json")
        let (data, response) = try await URLSession.shared.data(from: versionJsonURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NeoForgeError.invalidResponse
        }
        return try JSONDecoder().decode(ForgeLoader.self, from: data)
    }

    /// 安装并准备 NeoForge，返回 (loaderVersion, classpath, mainClass)
    static func setupNeoForge(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        let neoForgeProfile = try await fetchLatestNeoForgeProfile(for: gameVersion)
        guard let librariesDirectory = AppPaths.librariesDirectory else {
            throw NSError(domain: "NeoForgeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "error.neoforge.meta.libraries.notfound"])
        }
        let forgeManager = ForgeFileManager(librariesDir: librariesDirectory)
        forgeManager.onProgressUpdate = onProgressUpdate
        try await forgeManager.downloadForgeJars(libraries: neoForgeProfile.libraries)
        let classpathString = ForgeLoaderService.generateClasspath(from: neoForgeProfile, librariesDir: librariesDirectory)
        let mainClass = neoForgeProfile.mainClass
        let loaderVersion = neoForgeProfile.id
        return (loaderVersion: loaderVersion, classpath: classpathString, mainClass: mainClass)
    }
} 