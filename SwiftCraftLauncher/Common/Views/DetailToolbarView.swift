import SwiftUI

/// 详情区域工具栏内容
public struct DetailToolbarView: ToolbarContent {
    @Binding var selectedItem: SidebarItem
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
    @Binding var sortIndex: String
    @Binding var gameResourcesType: String
    @Binding var gameType: Bool  // false = local, true = server
    @Binding var currentPage: Int
    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int
    @EnvironmentObject var gameRepository: GameRepository
    let totalItems: Int
    @Binding var project: ModrinthProjectDetail?
    @Binding var selectProjectId: String?
    @Binding var selectedTab: Int
    @Binding var gameId: String?

    // MARK: - Computed Properties
    var totalPages: Int {
        max(1, Int(ceil(Double(totalItems) / Double(20))))
    }

    private func handlePageChange(_ increment: Int) {
        let newPage = currentPage + increment
        if newPage >= 1 && newPage <= totalPages {
            currentPage = newPage
        }
    }

    private var currentGame: GameVersionInfo? {
        if case .game(let gameId) = selectedItem {
            return gameRepository.getGame(by: gameId)
        }
        return nil
    }

    public var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            switch selectedItem {
            case .game:
                if let game = currentGame {
                    if !gameType {
                        if let iconURL = AppPaths.profileDirectory(gameName: game.gameName)?.appendingPathComponent(game.gameIcon),
                           FileManager.default.fileExists(atPath: iconURL.path) {
                            AsyncImage(url: iconURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .interpolation(.none)
                                        .frame(width: 22, height: 22)
                                        .cornerRadius(6)
                                case .failure:
                                    Image("default_game_icon")
                                        .resizable()
                                        .interpolation(.none)
                                        .frame(width: 22, height: 22)
                                        .cornerRadius(6)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image("default_game_icon")
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 22, height: 22)
                                .cornerRadius(6)
                        }
                        Text(game.gameName)
                            .font(.headline)
                        Spacer()
                    }
                    resourcesTypeMenu
                    resourcesMenu
                    if gameType {
                        sortMenu
                        paginationControls
                    }
                    Spacer()
                    Button(action: {
                        Task {
                            await MinecraftLaunchCommand(
                                player: playerListViewModel.currentPlayer,
                                game: game,
                                gameRepository: gameRepository
                            ).launchGame()
                        }
                    }) {
                        Label("play.fill".localized(), systemImage: "play.fill")
                    }
                    .disabled(game.isRunning)
                    if let gameDir = AppPaths.profileDirectory(gameName: game.gameName) {
                        Link(destination: gameDir) {
                            Label("play.fill".localized(), systemImage: "folder")
                        }
                    }
                }
            case .resource:
                if selectProjectId != nil {
                    ModrinthProjectDetailToolbarView(
                        projectDetail: project,
                        selectedTab: $selectedTab,
                        versionCurrentPage: $versionCurrentPage,
                        versionTotal: $versionTotal,
                        gameId: gameId,
                        onBack: {
                            if let id = gameId {
                                selectedItem = .game(id)
                            } else {
                                selectProjectId = nil
                                selectedTab = 0
                            }
                        }
                    )
                } else {
                    sortMenu
                    paginationControls
                    Spacer()
                }
            }
        }
    }

    private var currentSortTitle: String {
        "menu.sort.\(sortIndex)".localized()
    }
    private var currentResourceTitle: String {
        "resource.content.type.\(gameResourcesType)".localized()
    }
    private var currentResourceTypeTitle: String {
        gameType
            ? "resource.content.type.server".localized()
            : "resource.content.type.local".localized()
    }

    private var sortMenu: some View {
        Menu {
            ForEach(
                ["relevance", "downloads", "follows", "newest", "updated"],
                id: \.self
            ) { sort in
                Button("menu.sort.\(sort)".localized()) {
                    sortIndex = sort
                }
            }
        } label: {
            Text(currentSortTitle)
        }
        .help("player.add".localized())
    }

    private var resourcesMenu: some View {
        Menu {
            ForEach(resourceTypesForCurrentGame, id: \.self) { sort in
                Button("resource.content.type.\(sort)".localized()) {
                    gameResourcesType = sort
                }
            }
        } label: {
            Text(currentResourceTitle)
        }
        .help("player.add".localized())
    }

    private var resourcesTypeMenu: some View {
        Button(action: {
            gameType.toggle()
        }) {
            Label(
                currentResourceTypeTitle,
                systemImage: gameType
                    ? "tray.and.arrow.down" : "icloud.and.arrow.down"
            )
        }
        .help("view.mode.title".localized())
    }

    private var paginationControls: some View {
        HStack(spacing: 8) {
            Button(action: { handlePageChange(-1) }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage == 1)
            HStack(spacing: 8) {
                Text(
                    String(
                        format: "pagination.current".localized(),
                        currentPage
                    )
                )
                Divider().frame(height: 16)
                Text(String(format: "pagination.total".localized(), totalPages))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Button(action: { handlePageChange(1) }) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage == totalPages)
        }
    }

    private var resourceTypesForCurrentGame: [String] {
        var types = ["datapack", "resourcepack"]
        if let game = currentGame, game.modLoader.lowercased() != "vanilla" {
            types.insert("mod", at: 0)
            types.insert("shader", at: 2)
        }
        return types
    }
}
