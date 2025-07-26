import Foundation

enum AppConstants {
    static let defaultGameIcon = "default_game_icon.png"
    static let modLoaders = ["vanilla", "fabric", "forge", "neoForge", "quilt"]
    static let defaultJava = "/usr/bin/java"
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "SwiftCraftLauncher"
    }
    static let version = "0.1.0-Alpha"
}
    