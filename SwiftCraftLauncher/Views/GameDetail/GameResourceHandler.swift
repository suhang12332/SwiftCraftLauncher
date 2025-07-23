import Foundation
import SwiftUI

struct GameResourceHandler {
    static func updateButtonState(
        gameInfo: GameVersionInfo?,
        project: ModrinthProject,
        gameRepository: GameRepository,
        addButtonState: Binding<ModrinthDetailCardView.AddButtonState>
    ) {
        guard let gameInfo = gameInfo,
              let modsDir = AppPaths.modsDirectory(gameName: gameInfo.gameName) else { return }
        ModScanner.shared.isModInstalled(projectId: project.projectId, in: modsDir) { installed in
            DispatchQueue.main.async {
                if installed {
                    addButtonState.wrappedValue = .installed
                } else if addButtonState.wrappedValue == .installed {
                    addButtonState.wrappedValue = .idle
                }
            }
        }
    }

    static func performDelete(fileURL: URL) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: fileURL)
    }

    @MainActor
    static func downloadWithDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        var actuallyDownloaded: [ModrinthProjectDetail] = []
        var visited: Set<String> = []
        await ModrinthDependencyDownloader.downloadAllDependenciesRecursive(
            for: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            actuallyDownloaded: &actuallyDownloaded,
            visited: &visited
        )
        updateButtonState()
    }

    @MainActor
    static func downloadSingleResource(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        _ = await ModrinthDependencyDownloader.downloadMainResourceOnly(
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            filterLoader: query != "shader"
        )
            updateButtonState()
    }

    @MainActor
    static func prepareManualDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel
    ) async -> Bool {
        guard let gameInfo = gameInfo else { return false }
        depVM.isLoadingDependencies = true
        do {
            let missing = try await ModrinthDependencyDownloader.getMissingDependencies(
                for: project.projectId,
                gameInfo: gameInfo
            )
            
            if missing.isEmpty {
                depVM.isLoadingDependencies = false
                return false
            }
            var versionDict: [String: [ModrinthProjectDetailVersion]] = [:]
            var selectedVersionDict: [String: String] = [:]
            for dep in missing {
                let versions = try? await ModrinthService.fetchProjectVersions(id: dep.id)
                let filteredVersions = versions?.filter {
                    $0.loaders.contains(gameInfo.modLoader) && $0.gameVersions.contains(gameInfo.gameVersion)
                } ?? []
                versionDict[dep.id] = filteredVersions
                if let first = filteredVersions.first {
                    selectedVersionDict[dep.id] = first.id
                }
            }
            depVM.missingDependencies = missing
            depVM.dependencyVersions = versionDict
            depVM.selectedDependencyVersion = selectedVersionDict
            depVM.isLoadingDependencies = false
            depVM.resetDownloadStates()
            return true
        } catch {
            depVM.missingDependencies = []
            depVM.dependencyVersions = [:]
            depVM.selectedDependencyVersion = [:]
            depVM.isLoadingDependencies = false
            depVM.resetDownloadStates()
            return false
        }
    }

    @MainActor
    static func downloadAllDependenciesAndMain(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        let dependencies = depVM.missingDependencies
        let selectedVersions = depVM.selectedDependencyVersion
        let dependencyVersions = depVM.dependencyVersions

        let allSucceeded = await ModrinthDependencyDownloader.downloadManualDependenciesAndMain(
            dependencies: dependencies,
            selectedVersions: selectedVersions,
            dependencyVersions: dependencyVersions,
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            onDependencyDownloadStart: { depId in
                depVM.dependencyDownloadStates[depId] = .downloading
            },
            onDependencyDownloadFinish: { depId, success in
                depVM.dependencyDownloadStates[depId] = success ? .success : .failed
            }
        )

        if allSucceeded {
            updateButtonState()
            depVM.showDependenciesSheet = false
        } else {
            depVM.overallDownloadState = .failed
        }
    }
    
    @MainActor
    static func downloadMainResourceAfterDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        
        let success = await ModrinthDependencyDownloader.downloadMainResourceOnly(
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository
        )
        
        if success {
            updateButtonState()
            depVM.showDependenciesSheet = false
        } else {
            Logger.shared.error("dependency.download.main_resource.failed".localized())
        }
    }

    @MainActor
    static func retryDownloadDependency(
        dep: ModrinthProjectDetail,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository
    ) async {
        guard let gameInfo = gameInfo,
              let versionId = depVM.selectedDependencyVersion[dep.id],
              let versions = depVM.dependencyVersions[dep.id],
              let version = versions.first(where: { $0.id == versionId }),
              let primaryFile = ModrinthService.filterPrimaryFiles(from: version.files) else {
            depVM.dependencyDownloadStates[dep.id] = .failed
            return
        }
        depVM.dependencyDownloadStates[dep.id] = .downloading
        do {
            _ = try await DownloadManager.downloadResource(
                for: gameInfo,
                urlString: primaryFile.url,
                resourceType: dep.projectType,
                expectedSha1: primaryFile.hashes.sha1
            )
            
            var resourceToAdd = dep
            resourceToAdd.fileName = primaryFile.filename
            resourceToAdd.type = query
            depVM.dependencyDownloadStates[dep.id] = .success
        } catch {
            depVM.dependencyDownloadStates[dep.id] = .failed
        }
    }
} 
