import Foundation
import SwiftUI

public enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var localizedName: String {
        "settings.theme.\(rawValue)".localized()
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

class GeneralSettingsManager: ObservableObject {
    static let shared = GeneralSettingsManager()
    
    @AppStorage("selectedLanguage") public var selectedLanguage: String = Locale.preferredLanguages.first ?? "zh-Hans" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("themeMode") public var themeMode: ThemeMode = .system {
        didSet { objectWillChange.send() }
    }
    
    private init() {}
}
