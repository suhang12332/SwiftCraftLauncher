import SwiftUI

struct SettingsRow<Content: View>: View {
    let label: String
    let content: () -> Content
    var body: some View {
        HStack(alignment: .center) {
            Text(label.localized())
                .frame(width: 140, alignment: .leading)
            Spacer(minLength: 12)
            content()
        }
        .padding(.vertical, 4)
    }
}

public struct GeneralSettingsView: View {
    @ObservedObject private var general = GeneralSettingsManager.shared
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    @EnvironmentObject private var gameRepository: GameRepository
    private let languages = LanguageManager.shared.languages
    @State private var showDirectoryPicker = false
    public init() {}
    public var body: some View {
        Form {
            //            Section(header: Text("settings.general.title").font(.headline)) {
            //                SettingsRow(label: "settings.language.picker") {
            //                    Picker("", selection: $general.selectedLanguage) {
            //                        ForEach(languages, id: \.1) { name, code in
            //                            Text(name).tag(code)
            //                        }
            //                    }
            //                    .frame(width: 180)
            //                }
            //                SettingsRow(label: "settings.theme.picker") {
            //                    Picker("", selection: $general.themeMode) {
            //                        ForEach(ThemeMode.allCases, id: \.self) { mode in
            //                            Text(mode.localizedName).tag(mode)
            //                        }
            //                    }
            //                    .frame(width: 180)
            //                }
            //                SettingsRow(label: "settings.launcher_working_directory") {
            //                    HStack {
            //                        Button("settings.launcher_working_directory.choose".localized()) {
            //                            showDirectoryPicker = true
            //                        }
            //                        Button("settings.launcher_working_directory.reset".localized()) {
            //                            if let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(AppPaths.appName) {
            //                                general.launcherWorkingDirectory = supportDir.path
            //                                gameRepository.loadGames()
            //                            }
            //                        }
            //                        .disabled(general.launcherWorkingDirectory.isEmpty)
            //                    }
            //                }
            //                .fileImporter(isPresented: $showDirectoryPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            //                    switch result {
            //                    case .success(let urls):
            //                        if let url = urls.first {
            //                            general.launcherWorkingDirectory = url.path
            //                            gameRepository.loadGames()
            //                        }
            //                    case .failure:
            //                        break
            //                    }
            //                }
            //                if let path = general.launcherWorkingDirectory.isEmpty
            //                    ? AppPaths.launcherSupportDirectory?.path
            //                    : general.launcherWorkingDirectory, !path.isEmpty {
            //                    Text(path)
            //                        .font(.footnote)
            //                        .foregroundColor(.secondary)
            //                        .padding(.leading, 140)
            //                }
            //            }
            //            Section(header: Text("settings.general.title").font(.headline)) {
            //                SettingsRow(label: "settings.minecraft_versions_url.label") {
            //                    TextField("", text: $gameSettings.minecraftVersionManifestURL)
            //                        .frame(width: 300)
            //                }
            //                SettingsRow(label: "settings.modrinth_api_url.label") {
            //                    TextField("", text: $gameSettings.modrinthAPIBaseURL)
            //                        .frame(width: 300)
            //                }
            //                SettingsRow(label: "settings.git_proxy_url.label") {
            //                    TextField("", text: $gameSettings.gitProxyURL)
            //                        .frame(width: 300)
            //                }
            //            }
            //        }
            //        .padding()
        }
    }
}

#Preview {
    GeneralSettingsView()
}
