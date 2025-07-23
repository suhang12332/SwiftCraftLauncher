import SwiftUI

/// 显示玩家列表的视图
struct PlayerListView: View {
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
    @Environment(\.dismiss) var dismiss
    @State private var playerToDelete: Player? = nil
    @State private var showDeleteAlert = false
    @State private var showingPlayerListPopover = false

    var body: some View {
        Button(action: {
            showingPlayerListPopover.toggle()
        }) {
            PlayerSelectorLabel(selectedPlayer: playerListViewModel.currentPlayer)
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingPlayerListPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(playerListViewModel.players) { player in
                    HStack {
                        Button {
                            playerListViewModel.setCurrentPlayer(byID: player.id)
                            showingPlayerListPopover = false
                        } label: {
                            PlayerAvatarView(player: player, size: 28, cornerRadius: 7)
                            Text(player.name)
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 8)
                        Button {
                            playerToDelete = player
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "person.badge.minus")
                                .help("player.remove".localized())
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
            .frame(width: 200)
        }
        .confirmationDialog(
            "player.remove".localized(),
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("player.remove".localized(), role: .destructive) {
                if let player = playerToDelete {
                    _ = playerListViewModel.deletePlayer(byID: player.id)
                }
                playerToDelete = nil
            }.keyboardShortcut(.defaultAction)
            Button("alert.button.cancel".localized(), role: .cancel) {
                playerToDelete = nil
            }
        } message: {
            Text(String(format: "player.remove.confirm".localized(), playerToDelete?.name ?? ""))
        }
    }
}



private struct PlayerSelectorLabel: View {
    let selectedPlayer: Player?
    var body: some View {
        if let selectedPlayer = selectedPlayer {
            HStack(spacing: 6) {
                PlayerAvatarView(player: selectedPlayer, size: 22, cornerRadius: 5)
                Text(selectedPlayer.name)
                    .foregroundColor(.primary)
                    .font(.system(size: 13))
            }
        } else {
            EmptyView()
        }
    }
}

// PlayerAvatarView struct definition moved here
private struct PlayerAvatarView: View {
    let player: Player
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        Image(player.avatarName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .drawingGroup()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
