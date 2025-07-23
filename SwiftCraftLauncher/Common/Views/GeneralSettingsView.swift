import SwiftUI

public struct GeneralSettingsView: View {
    @ObservedObject private var general = GeneralSettingsManager.shared
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    private let languages = LanguageManager.shared.languages
    public init() {}
    public var body: some View {
        HStack {
            Form {
                Section() {
                    SettingRow(label: "settings.language.picker") {
                        Picker("", selection: $general.selectedLanguage) {
                            ForEach(languages, id: \.1) { name, code in
                                Text(name).tag(code)
                            }
                        }
                    }

                    SettingRow(label: "settings.theme.picker") {
                        Picker("", selection: $general.themeMode) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(mode.localizedName).tag(mode)
                            }
                        }
                    }
                    Spacer().frame(height: 20)

                    SettingRow(label: "settings.minecraft_versions_url.label") {
                        TextField("".localized(), text: $gameSettings.minecraftVersionManifestURL)
                    }

                    SettingRow(label: "settings.modrinth_api_url.label") {
                        TextField("".localized(), text: $gameSettings.modrinthAPIBaseURL)
                    }

                    SettingRow(label: "settings.git_proxy_url.label") {
                        TextField("", text: $gameSettings.gitProxyURL)
                    }
                }
            }
        }
        
    }
} 

#Preview {
    GeneralSettingsView()
}
