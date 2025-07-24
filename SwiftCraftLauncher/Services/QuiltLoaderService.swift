import Foundation

class QuiltLoaderService {
    enum QuiltError: Error, LocalizedError {
        case networkError(String)
        case invalidResponse
        case noMatchingVersion
        case downloadFailed
        case extractionFailed
        case versionJsonNotFound
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg):
                return String(format: NSLocalizedString("error.quilt.network.failed", comment: ""), msg)
            case .invalidResponse:
                return NSLocalizedString("error.quilt.invalid.response", comment: "")
            case .noMatchingVersion:
                return NSLocalizedString("error.quilt.no.matching.version", comment: "")
            case .downloadFailed:
                return NSLocalizedString("error.quilt.download.failed", comment: "")
            case .extractionFailed:
                return NSLocalizedString("error.quilt.extraction.failed", comment: "")
            case .versionJsonNotFound:
                return NSLocalizedString("error.quilt.versionjson.notfound", comment: "")
            }
        }
    }

    // 示例主流程方法
    static func fetchLatestQuiltVersion(for minecraftVersion: String) async throws -> String {
        // TODO: 实现 Quilt 版本获取逻辑
        throw QuiltError.noMatchingVersion
    }

    /// 获取所有可用 Quilt Loader 版本
    static func fetchAllQuiltLoaders(for minecraftVersion: String) async throws -> [QuiltLoaderResponse] {
        let url = URLConfig.API.Quilt.loaderBase.appendingPathComponent(minecraftVersion)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw QuiltError.invalidResponse
        }
        let decoder = JSONDecoder()
        let allLoaders = try decoder.decode([QuiltLoaderResponse].self, from: data)
        return allLoaders.filter { !$0.loader.version.lowercased().contains("beta") && !$0.loader.version.lowercased().contains("pre") }
    }

    /// 获取最新的可用 Quilt Loader 版本
    static func fetchLatestQuiltLoader(for minecraftVersion: String) async throws -> QuiltLoaderResponse {
        let loaders = try await fetchAllQuiltLoaders(for: minecraftVersion)
        guard let latest = loaders.first else {
            throw QuiltError.noMatchingVersion
        }
        return latest
    }

    /// 判断某 MC 游戏版本是否存在可用的 Quilt Loader 版本
    static func isGameVersionAvailable(for minecraftVersion: String) async throws -> Bool {
        let loaders = try await fetchAllQuiltLoaders(for: minecraftVersion)
        return !loaders.isEmpty
    }
} 
