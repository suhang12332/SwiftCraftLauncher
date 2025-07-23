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
} 