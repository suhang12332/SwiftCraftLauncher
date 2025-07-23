import Foundation
import SwiftUI

// MARK: - 兼容游戏过滤
func filterCompatibleGames(
    detail: ModrinthProjectDetail,
    gameRepository: GameRepository,
    resourceType: String,
    projectId: String
) -> [GameVersionInfo] {
    let supportedVersions = Set(detail.gameVersions)
    let supportedLoaders = Set(detail.loaders.map { $0.lowercased() })
    return gameRepository.games.compactMap { game in
        let localLoader = game.modLoader.lowercased()
        let match: Bool = {
            switch (resourceType, localLoader) {
            case ("datapack", "vanilla"):
                return supportedVersions.contains(game.gameVersion) && supportedLoaders.contains("datapack")
            case ("shader", let loader) where loader != "vanilla":
                return supportedVersions.contains(game.gameVersion)
            case ("resourcepack", "vanilla"):
                return supportedVersions.contains(game.gameVersion) && supportedLoaders.contains("minecraft")
            case ("resourcepack", _):
                return supportedVersions.contains(game.gameVersion)
            default:
                return supportedVersions.contains(game.gameVersion) && supportedLoaders.contains(localLoader)
            }
        }()
        guard match else { return nil }
        if let modsDir = AppPaths.modsDirectory(gameName: game.gameName),
           ModScanner.shared.isModInstalledSync(projectId: projectId, in: modsDir) {
            return nil
        }
        return game
    }
}

// MARK: - 依赖相关状态
private struct DependencyState {
    var dependencies: [ModrinthProjectDetail] = []
    var versions: [String: [ModrinthProjectDetailVersion]] = [:]
    var selected: [String: ModrinthProjectDetailVersion?] = [:]
    var isLoading = false
}

// MARK: - 主资源添加 Sheet
struct GlobalResourceSheet: View {
    let project: ModrinthProject
    let resourceType: String
    @Binding var isPresented: Bool
    @EnvironmentObject var gameRepository: GameRepository
    @State private var selectedGame: GameVersionInfo? = nil
    @State private var selectedVersion: ModrinthProjectDetailVersion? = nil
    @State private var availableVersions: [ModrinthProjectDetailVersion] = []
    @State private var projectDetail: ModrinthProjectDetail? = nil
    @State private var isLoading = true
    @State private var error: Error? = nil
    @State private var dependencyState = DependencyState()
    @State private var hasLoadedDetail = false
    @State private var isDownloadingAll = false
    @State private var isDownloadingMainOnly = false

    var body: some View {
        CommonSheetView(
            header: {
                Text(selectedGame.map { String(format: "global_resource.add_for_game".localized(), $0.gameName) } ?? "global_resource.add".localized())
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            },
            body: {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else if let error = error {
                    ErrorView(error)
                } else if let detail = projectDetail {
                    let compatibleGames = filterCompatibleGames(detail: detail, gameRepository: gameRepository, resourceType: resourceType, projectId: project.projectId)
                    if compatibleGames.isEmpty {
                        Text("global_resource.no_game_list".localized()).foregroundColor(.secondary).padding()
                    } else {
                        VStack {
                            CommonSheetGameBody(compatibleGames: compatibleGames, selectedGame: $selectedGame)
                            if let game = selectedGame {
                                Spacer().frame(minHeight: 20)
                                VersionPickerForSheet(
                                    project: project,
                                    resourceType: resourceType,
                                    selectedGame: $selectedGame,
                                    selectedVersion: $selectedVersion,
                                    availableVersions: $availableVersions,
                                    onVersionChange: { version in
                                        if resourceType == "mod", let v = version {
                                            loadDependencies(for: v, game: game)
                                        } else {
                                            dependencyState = DependencyState()
                                        }
                                    }
                                )
                                if resourceType == "mod" && !GameSettingsManager.shared.autoDownloadDependencies {
                                    DependencySection(state: dependencyState)
                                }
                            }
                        }
                    }
                }
            },
            footer: {
                FooterButtons(
                    project: project,
                    resourceType: resourceType,
                    isPresented: $isPresented,
                    projectDetail: projectDetail,
                    selectedGame: selectedGame,
                    selectedVersion: selectedVersion,
                    dependencyState: dependencyState,
                    isDownloadingAll: $isDownloadingAll,
                    isDownloadingMainOnly: $isDownloadingMainOnly,
                    gameRepository: gameRepository,
                    loadDependencies: loadDependencies
                )
            }
        )
        .onAppear {
            if !hasLoadedDetail {
                hasLoadedDetail = true
                loadDetail()
            }
        }
    }

    private func loadDetail() {
        isLoading = true
        error = nil
        Task {
            do {
                let detail = try await ModrinthService.fetchProjectDetails(id: project.projectId)
                await MainActor.run {
                    self.projectDetail = detail
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    private func loadDependencies(for version: ModrinthProjectDetailVersion, game: GameVersionInfo) {
        dependencyState.isLoading = true
        Task {
            do {
                let missing = try await ModrinthDependencyDownloader.getMissingDependencies(
                    for: project.projectId,
                    gameInfo: game
                )
                var depVersions: [String: [ModrinthProjectDetailVersion]] = [:]
                var depSelected: [String: ModrinthProjectDetailVersion?] = [:]
                for dep in missing {
                    let versions = try await ModrinthService.fetchProjectVersions(id: dep.id)
                    let filtered = versions.filter {
                        $0.loaders.contains(game.modLoader) &&
                        $0.gameVersions.contains(game.gameVersion)
                    }
                    depVersions[dep.id] = filtered
                    depSelected[dep.id] = filtered.first
                }
                await MainActor.run {
                    dependencyState = DependencyState(dependencies: missing, versions: depVersions, selected: depSelected, isLoading: false)
                }
            } catch {
                await MainActor.run {
                    dependencyState = DependencyState(isLoading: false)
                }
            }
        }
    }
}

// MARK: - 依赖区块
private struct DependencySection: View {
    let state: DependencyState
    var body: some View {
        if state.isLoading {
            ProgressView().controlSize(.small)
        } else if !state.dependencies.isEmpty {
            Spacer().frame(minHeight: 20)
            VStack {
                ForEach(state.dependencies, id: \ .id) { dep in
                    VStack(alignment: .leading) {
                        Text(dep.title).font(.headline).bold()
                        if let versions = state.versions[dep.id], !versions.isEmpty {
                            Picker("global_resource.dependency_version".localized(), selection: .constant(state.selected[dep.id] ?? versions.first)) {
                                ForEach(versions, id: \ .id) { v in
                                    Text(v.name).tag(Optional(v))
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text("global_resource.no_version".localized()).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Footer 按钮区块
private struct FooterButtons: View {
    let project: ModrinthProject
    let resourceType: String
    @Binding var isPresented: Bool
    let projectDetail: ModrinthProjectDetail?
    let selectedGame: GameVersionInfo?
    let selectedVersion: ModrinthProjectDetailVersion?
    let dependencyState: DependencyState
    @Binding var isDownloadingAll: Bool
    @Binding var isDownloadingMainOnly: Bool
    let gameRepository: GameRepository
    let loadDependencies: (ModrinthProjectDetailVersion, GameVersionInfo) -> Void

    var body: some View {
        if let detail = projectDetail {
            let compatibleGames = filterCompatibleGames(detail: detail, gameRepository: gameRepository, resourceType: resourceType, projectId: project.projectId)
            if compatibleGames.isEmpty {
                HStack {
                    Spacer()
                    Button("common.close".localized()) { isPresented = false }
                }
            } else {
                HStack {
                    Button("common.close".localized()) { isPresented = false }
                    Spacer()
                    if resourceType == "mod" {
                        if GameSettingsManager.shared.autoDownloadDependencies {
                            if selectedVersion != nil {
                                Button(action: downloadAll) {
                                    if isDownloadingAll {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Text("global_resource.download_all".localized())
                                    }
                                }
                                .disabled(isDownloadingAll)
                                .keyboardShortcut(.defaultAction)
                            }
                        } else if !dependencyState.isLoading {
                            if dependencyState.dependencies.isEmpty {
                                if selectedVersion != nil {
                                    Button(action: downloadMainOnly) {
                                        if isDownloadingMainOnly {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Text("global_resource.download".localized())
                                        }
                                    }
                                }
                            } else {
                                if selectedVersion != nil {
                                    Button(action: downloadMainOnly) {
                                        if isDownloadingMainOnly {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Text("global_resource.download_main_only".localized())
                                        }
                                    }
                                    
                                    Button(action: downloadAllManual) {
                                        if isDownloadingAll {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Text("global_resource.download_all".localized())
                                        }
                                    }
                                    .disabled(isDownloadingAll || isDownloadingMainOnly)
                                    .keyboardShortcut(.defaultAction)
                                }
                            }
                        }
                    } else {
                        if selectedVersion != nil {
                            Button(action: downloadResource) {
                                if isDownloadingAll {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text("global_resource.download".localized())
                                }
                            }
                            .disabled(isDownloadingAll)
                            .keyboardShortcut(.defaultAction)
                        }
                    }
                }
            }
        } else {
            HStack {
                Spacer()
                Button("common.close".localized()) { isPresented = false }
            }
        }
    }

    private func downloadAll() {
        guard let game = selectedGame, let _ = selectedVersion else { return }
        isDownloadingAll = true
        Task {
            var actuallyDownloaded: [ModrinthProjectDetail] = []
            var visited: Set<String> = []
            await ModrinthDependencyDownloader.downloadAllDependenciesRecursive(
                for: project.projectId,
                gameInfo: game,
                query: resourceType,
                gameRepository: gameRepository,
                actuallyDownloaded: &actuallyDownloaded,
                visited: &visited
            )
            await MainActor.run {
                isDownloadingAll = false
                isPresented = false
            }
        }
    }
    private func downloadMainOnly() {
        guard let game = selectedGame, let _ = selectedVersion else { return }
        isDownloadingMainOnly = true
        Task {
            let _ = await ModrinthDependencyDownloader.downloadMainResourceOnly(
                mainProjectId: project.projectId,
                gameInfo: game,
                query: resourceType,
                gameRepository: gameRepository,
                filterLoader: false
            )
            await MainActor.run {
                isDownloadingMainOnly = false
                isPresented = false
            }
        }
    }
    private func downloadAllManual() {
        guard let game = selectedGame, let _ = selectedVersion else { return }
        isDownloadingAll = true
        Task {
            let _ = await ModrinthDependencyDownloader.downloadManualDependenciesAndMain(
                dependencies: dependencyState.dependencies,
                selectedVersions: dependencyState.selected.compactMapValues { $0?.id },
                dependencyVersions: dependencyState.versions,
                mainProjectId: project.projectId,
                gameInfo: game,
                query: resourceType,
                gameRepository: gameRepository,
                onDependencyDownloadStart: { _ in },
                onDependencyDownloadFinish: { _, _ in }
            )
            await MainActor.run {
                isDownloadingAll = false
                isPresented = false
            }
        }
    }
    private func downloadResource() {
        guard let game = selectedGame, let _ = selectedVersion else { return }
        isDownloadingAll = true
        Task {
            let _ = await ModrinthDependencyDownloader.downloadMainResourceOnly(
                mainProjectId: project.projectId,
                gameInfo: game,
                query: resourceType,
                gameRepository: gameRepository,
                filterLoader: false
            )
            await MainActor.run {
                isDownloadingAll = false
                isPresented = false
            }
        }
    }
}



// MARK: - 游戏选择区块
struct CommonSheetGameBody: View {
    let compatibleGames: [GameVersionInfo]
    @Binding var selectedGame: GameVersionInfo?
    var body: some View {
        Picker("global_resource.select_game".localized(), selection: $selectedGame) {
            Text("global_resource.please_select_game".localized()).tag(Optional<GameVersionInfo>(nil))
            ForEach(compatibleGames, id: \ .id) { game in
                Text(game.gameName).tag(Optional(game))
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - 版本选择区块
struct VersionPickerForSheet: View {
    let project: ModrinthProject
    let resourceType: String
    @Binding var selectedGame: GameVersionInfo?
    @Binding var selectedVersion: ModrinthProjectDetailVersion?
    @Binding var availableVersions: [ModrinthProjectDetailVersion]
    var onVersionChange: ((ModrinthProjectDetailVersion?) -> Void)? = nil
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView().controlSize(.small)
            } else if !availableVersions.isEmpty {
                Text(project.title).font(.headline).bold().frame(maxWidth: .infinity, alignment: .leading)
                Picker("global_resource.select_version".localized(), selection: $selectedVersion) {
                    ForEach(availableVersions, id: \ .id) { version in
                        if resourceType == "shader" {
                            let loaders = version.loaders.joined(separator: ", ")
                            Text("\(version.name) (\(loaders))").tag(Optional(version))
                        } else {
                            Text(version.name).tag(Optional(version))
                        }
                    }
                }
                .pickerStyle(.menu)
            } else {
                Text("global_resource.no_version_available".localized()).foregroundColor(.secondary)
            }
        }
        .onAppear(perform: loadVersions)
        .onChange(of: selectedGame) { loadVersions() }
        .onChange(of: selectedVersion) { _, newValue in
            onVersionChange?(newValue)
        }
    }

    private func loadVersions() {
        isLoading = true
        error = nil
        Task {
            do {
                let allVersions = try await ModrinthService.fetchProjectVersions(id: project.projectId)
                guard let game = selectedGame else {
                    await MainActor.run {
                        availableVersions = []
                        selectedVersion = nil
                        isLoading = false
                    }
                    return
                }
                let loader: String
                if resourceType == "datapack" && game.modLoader.lowercased() == "vanilla" {
                    loader = "datapack"
                } else if resourceType == "resourcepack" && game.modLoader.lowercased() == "vanilla" {
                    loader = "minecraft"
                } else {
                    loader = game.modLoader
                }
                let filtered: [ModrinthProjectDetailVersion]
                if resourceType == "shader" || resourceType == "resourcepack" {
                    filtered = allVersions.filter {
                        $0.gameVersions.contains(game.gameVersion)
                    }
                } else {
                    filtered = allVersions.filter {
                        $0.gameVersions.contains(game.gameVersion) &&
                        $0.loaders.contains(loader)
                    }
                }
                await MainActor.run {
                    availableVersions = filtered
                    selectedVersion = filtered.first
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}
