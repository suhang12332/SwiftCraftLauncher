import Foundation

class CommonService {
    static func availableLoaders(for minecraftVersion: String) async -> [String] {
        let cacheNamespace = "modloaders"
        if let cached = AppCacheManager.shared.get(namespace: cacheNamespace, key: minecraftVersion, as: [String].self) {
            return cached
        }
        let isLatest = await MinecraftService.isLatestReleaseVersion(currentVersion: minecraftVersion)
        let loaders = await fetchAndCacheLoaders(for: minecraftVersion, namespace: cacheNamespace)
        // 只有最新版本且结果数量为5时才写入缓存
        if isLatest && loaders.count == 5 {
            AppCacheManager.shared.set(namespace: cacheNamespace, key: minecraftVersion, value: loaders)
        }
        return loaders
    }

    private static func fetchAndCacheLoaders(for minecraftVersion: String, namespace: String) async -> [String] {
        var result: [String] = ["vanilla"]
        await withTaskGroup(of: (String, Bool).self) { group in
            group.addTask { ("fabric", (try? await FabricLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("forge", (try? await ForgeLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("neoforge", (try? await NeoForgeLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("quilt", (try? await QuiltLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            for await (name, available) in group {
                if available { result.append(name) }
            }
        }
        AppCacheManager.shared.set(namespace: namespace, key: minecraftVersion, value: result)
        return result
    }
    // forge 和 neoforge 通用的classpath生成
    static func generateClasspath(from loader: ForgeLoader, librariesDir: URL) -> String {
        let jarPaths: [String] = loader.libraries.map { lib in
            let artifact = lib.downloads.artifact
            return librariesDir.appendingPathComponent(artifact.path).path
        }
        return jarPaths.joined(separator: ":")
    }
}
 
