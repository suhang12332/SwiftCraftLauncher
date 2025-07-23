import Foundation

enum MinecraftService {

    /// Fetches the list of Minecraft versions from Mojang's version manifest.
    /// - Returns: A MojangVersionManifest object containing the latest versions and a list of all versions.
    /// - Throws: An error if the request fails or the data is invalid.
    static func fetchVersionManifest() async throws -> MojangVersionManifest {
        let (data, _) = try await URLSession.shared.data(
            from: URLConfig.API.Minecraft.versionList
        )
        Logger.shared.info("Modrinth 搜索 URL：\(URLConfig.API.Minecraft.versionList)")
        return try JSONDecoder().decode(MojangVersionManifest.self, from: data)
    }

    // Add other Minecraft related API calls here in the future
}
