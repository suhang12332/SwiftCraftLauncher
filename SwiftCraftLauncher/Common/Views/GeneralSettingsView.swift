import SwiftUI





public struct GeneralSettingsView: View {
    @ObservedObject private var general = GeneralSettingsManager.shared
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    @EnvironmentObject private var gameRepository: GameRepository
    private let languages = LanguageManager.shared.languages
    @State private var showDirectoryPicker = false
    public init() {}
    public var body: some View {
        Form {
            VStack(alignment: .leading) {
                Section {
                    Picker("settings.language.picker".localized(), selection: $general.selectedLanguage) {
                        ForEach(languages, id: \.1) { name, code in
                            Text(name).tag(code)
                        }
                    }
                    Picker("settings.theme.picker".localized(), selection: $general.themeMode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                }
            }
            .padding(.bottom, 20) // 只控制Section之间的垂直间距
            Section {
                LabeledContent {
                    DirectorySettingRow(
                        title: "settings.launcher_working_directory".localized(),
                        path: general.launcherWorkingDirectory.isEmpty ? (AppPaths.launcherSupportDirectory?.path ?? "") : general.launcherWorkingDirectory,
                        description: "该路径的设置只会影响到游戏存档、mod、光影等其他资源的存储位置。",
                        onChoose: { showDirectoryPicker = true },
                        onReset: {
                            if let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(AppConstants.appName) {
                                general.launcherWorkingDirectory = supportDir.path
                                gameRepository.loadGames()
                            }
                        }
                    )
                } label: {
                    Text("settings.launcher_working_directory".localized())
                }
                .fixedSize()
                .fileImporter(isPresented: $showDirectoryPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            general.launcherWorkingDirectory = url.path
                            gameRepository.loadGames()
                        }
                    case .failure:
                        break
                    }
                }
            }
            .padding(.bottom, 20) // 只控制Section之间的垂直间距
            Section {
                LabeledContent {
                    HStack {
                        Slider(
                            value: Binding(
                                get: {
                                    Double(gameSettings.concurrentDownloads)
                                },
                                set: {
                                    gameSettings.concurrentDownloads = Int(
                                        $0
                                    )
                                }
                            ),
                            in: 1...20,
                            label: { EmptyView() },
                            minimumValueLabel: { EmptyView() },
                            maximumValueLabel: { EmptyView() }
                        ).controlSize(.mini).frame(width: 200)
                        // 当前内存值显示（右对齐，固定宽度）
                        Text("\(gameSettings.concurrentDownloads)").font(
                            .subheadline
                        ).foregroundColor(.secondary).fixedSize()
                    }
                } label: {
                    Label("settings.concurrent_downloads.label".localized(),systemImage: "").labelsHidden()
                }
            }
            .padding(.bottom, 20) // 只控制Section之间的垂直间距
            Section {
                TextField("settings.minecraft_versions_url.label".localized(), text: $gameSettings.minecraftVersionManifestURL).focusable(false)
                TextField("settings.modrinth_api_url.label".localized(), text: $gameSettings.modrinthAPIBaseURL).focusable(false)
                TextField("settings.git_proxy_url.label".localized(), text: $gameSettings.gitProxyURL).focusable(false)
            }
            
        }
    }
}

#Preview {
    GeneralSettingsView()
}
