import Foundation

class CommonService {
    static func availableLoaders(for minecraftVersion: String) async -> [String] {
        let cacheNamespace = "modloaders"
        let isLatest = await MinecraftService.isLatestReleaseVersion(currentVersion: minecraftVersion)
        if isLatest {
            return await fetchAndCacheLoaders(for: minecraftVersion, namespace: cacheNamespace)
        } else {
            if let cached = AppCacheManager.shared.get(namespace: cacheNamespace, key: minecraftVersion, as: [String].self) {
                return cached
            } else {
                return await fetchAndCacheLoaders(for: minecraftVersion, namespace: cacheNamespace)
            }
        }
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
} 
 
