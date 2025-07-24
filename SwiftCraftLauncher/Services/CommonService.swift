import Foundation

class CommonService {
    static func availableLoaders(for minecraftVersion: String) async -> [String] {
        var result: [String] = ["vanilla"]
        await withTaskGroup(of: (String, Bool).self) { group in
            group.addTask { ("fabric", (try? await FabricLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("forge", (try? await ForgeLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("neoForge", (try? await NeoForgeService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            group.addTask { ("quilt", (try? await QuiltLoaderService.isGameVersionAvailable(for: minecraftVersion)) ?? false) }
            for await (name, available) in group {
                if available { result.append(name) }
            }
        }
        return result
    }
} 
 