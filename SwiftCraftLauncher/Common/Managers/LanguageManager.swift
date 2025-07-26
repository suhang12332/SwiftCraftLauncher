import Foundation
import SwiftUI

/// 语言管理器
/// 只负责语言列表和 bundle
public class LanguageManager: ObservableObject {
    /// 单例实例
    public static let shared = LanguageManager()
    
    /// 支持的语言列表
    public let languages: [(String, String)] = [
        ("🇨🇳 简体中文", "zh-Hans"),
        ("🇨🇳 繁體中文", "zh-Hant"),
        ("🇺🇸 English", "en"),
    ]
    
    /// 获取当前语言的 Bundle
    public var bundle: Bundle {
        if let path = Bundle.main.path(forResource: GeneralSettingsManager.shared.selectedLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
    
    private init() {}
}

// MARK: - String Localization Extension

public extension String {
    /// 获取本地化字符串
    /// - Parameter bundle: 语言包，默认使用当前语言
    /// - Returns: 本地化后的字符串
    func localized(_ bundle: Bundle = LanguageManager.shared.bundle) -> String {
        NSLocalizedString(self, bundle: bundle, comment: "")
    }
} 
