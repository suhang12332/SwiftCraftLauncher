import Foundation

enum AppConstants {
    static let defaultGameIcon = "default_game_icon.png"
    static let modLoaders = ["vanilla", "fabric", "forge", "neoForge", "quilt"]
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "SwiftCraftLauncher"
    }
    static var appVersion: String {
        VersionGenerator.nextPreReleaseVersion(current: "0.0.1", preRelease: "alpha")
    }
    
}
