import Foundation

enum FabricSetupError: LocalizedError {
    case loaderInfoNotFound
    case appSupportDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .loaderInfoNotFound:
            return "error.fabric.loader.info.missing".localized()
        case .appSupportDirectoryNotFound:
            return "error.app.support.missing".localized()
        }
    }
}

class FabricLoaderService {
//    static func fetchLoaders(for minecraftVersion: String) async throws -> [FabricLoaderResponse] {
//        let url = URLConfig.API.Fabric.loader.appendingPathComponent(minecraftVersion)
//        let (data, response) = try await URLSession.shared.data(from: url)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        let decoder = JSONDecoder()
//        return try decoder.decode([FabricLoaderResponse].self, from: data)
//    }
//    /// 获取最新的稳定版Loader版本号
//    static func fetchLatestStableLoaderVersion(for minecraftVersion: String) async throws -> FabricLoaderResponse? {
//        let loaders = try await fetchLoaders(for: minecraftVersion)
//        return loaders.first(where: { $0.loader.stable })
//    }
    /// 获取所有 Loader 版本
    static func fetchAllLoaderVersions(for minecraftVersion: String) async throws -> [FabricLoader] {
        let url = URLConfig.API.Fabric.loader.appendingPathComponent(minecraftVersion)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        var result: [FabricLoader] = []
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                let singleData = try JSONSerialization.data(withJSONObject: item)
                let decoder = JSONDecoder()
                if let loader = try? decoder.decode(FabricLoader.self, from: singleData) {
                    result.append(loader)
                }
            }
        }
        return result
    }

    /// 判断某 MC 游戏版本是否存在（即该版本有可用的 Loader）
    static func isGameVersionAvailable(for minecraftVersion: String) async throws -> Bool {
        let allLoaders = try await fetchAllLoaderVersions(for: minecraftVersion)
        return !allLoaders.isEmpty
    }

    /// 获取最新的稳定版 Loader 版本
    static func fetchLatestStableLoaderVersion(for minecraftVersion: String) async throws -> FabricLoader? {
        let allLoaders = try await fetchAllLoaderVersions(for: minecraftVersion)
        return allLoaders.first(where: { $0.loader.stable })
    }
    /// Maven 坐标转相对路径
    static func mavenCoordinateToRelativePath(_ coordinate: String) -> String? {
        let parts = coordinate.split(separator: ":")
        guard parts.count == 3 else { return nil }
        let group = parts[0].replacingOccurrences(of: ".", with: "/")
        let artifact = parts[1]
        let version = parts[2]
        return "\(group)/\(artifact)/\(version)/\(artifact)-\(version).jar"
    }

    /// Maven 坐标转 FabricMC Maven 仓库 URL
    static func mavenCoordinateToURL(_ coordinate: String) -> URL? {
        guard let relPath = mavenCoordinateToRelativePath(coordinate) else { return nil }
        return URLConfig.API.Fabric.maven.appendingPathComponent(relPath)
    }
    /// 根据 FabricLoader 生成 classpath 字符串
    static func generateClasspath(from loader: FabricLoader, librariesDir: URL) -> String {
        var mavenCoords: [String] = [loader.loader.maven, loader.intermediary.maven]
        let libs = loader.launcherMeta.libraries
        mavenCoords.append(contentsOf: libs.common.map { $0.name })
        mavenCoords.append(contentsOf: libs.client.map { $0.name })
        let jarPaths = mavenCoords.compactMap { coordinate -> String? in
            guard let relPath = mavenCoordinateToRelativePath(coordinate) else { return nil }
            return librariesDir.appendingPathComponent(relPath).path
        }
        return jarPaths.joined(separator: ":")
    }
    /// 封装 Fabric 设置流程：获取版本、下载、生成 Classpath
    static func setupFabric(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        guard let loader = try await fetchLatestStableLoaderVersion(for: gameVersion) else {
            throw FabricSetupError.loaderInfoNotFound
        }
        var mavenCoords: [String] = [loader.loader.maven, loader.intermediary.maven]
        let libs = loader.launcherMeta.libraries
        mavenCoords.append(contentsOf: libs.common.map { $0.name })
        mavenCoords.append(contentsOf: libs.client.map { $0.name })
        let jarUrls = mavenCoords.compactMap { mavenCoordinateToURL($0) }
        guard let librariesDirectory = AppPaths.librariesDirectory else {
            throw FabricSetupError.appSupportDirectoryNotFound
        }
        let fabricManager = FabricFileManager(librariesDir: librariesDirectory)
        fabricManager.onProgressUpdate = onProgressUpdate
        try await fabricManager.downloadFabricJars(urls: jarUrls)
        let classpathString = generateClasspath(from: loader, librariesDir: librariesDirectory)
        let mainClass = loader.launcherMeta.mainClass.client
        return (loaderVersion: loader.loader.version, classpath: classpathString, mainClass: mainClass)
    }

    static func setup(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        return try await setupFabric(for: gameVersion, gameInfo: gameInfo, onProgressUpdate: onProgressUpdate)
    }
}

extension FabricLoaderService: ModLoaderHandler {} 
