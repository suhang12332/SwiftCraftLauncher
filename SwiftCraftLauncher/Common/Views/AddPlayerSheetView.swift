import SwiftUI

struct AddPlayerSheetView: View {
    @Binding var playerName: String
    @Binding var isPlayerNameValid: Bool
    var onAdd: () -> Void
    var onCancel: () -> Void
    @ObservedObject var playerListViewModel: PlayerListViewModel

    var body: some View {
        CommonSheetView(
            header: {
                Text("addplayer.title".localized())
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            },
            body: {
                VStack(alignment: .leading) {
                    playerInfoSection
                        .padding(.bottom, 10)
                    playerNameInputSection
                }
            },
            footer: {
                HStack {
                    Button("common.cancel".localized(), action: onCancel)
                    Spacer()
                    Button("addplayer.create".localized(), action: onAdd)
                        .disabled(!isPlayerNameValid).keyboardShortcut(.defaultAction)
                }
            }
        )
    }

    // 说明区
    private var playerInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("addplayer.info.title".localized())
                .font(.headline)
            Text("addplayer.info.line1".localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("addplayer.info.line2".localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("addplayer.info.line3".localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("addplayer.info.line4".localized())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // 输入区
    private var playerNameInputSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("addplayer.name.label".localized())
                    .font(.headline.bold())
                Spacer()
                if !isPlayerNameValid {
                    Text(playerNameError)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            TextField("addplayer.name.placeholder".localized(), text: $playerName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: playerName) { _, newValue in
                    checkPlayerName(newValue)
                }
        }
    }

    // 校验错误提示
    private var playerNameError: String {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "addplayer.name.error.empty".localized()
        }
        if playerListViewModel.playerExists(name: trimmedName) {
            return "addplayer.name.error.duplicate".localized()
        }
        // 长度和字符集校验可根据需要扩展
        return "addplayer.name.error.invalid".localized()
    }

    private func checkPlayerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isPlayerNameValid = !trimmedName.isEmpty && !playerListViewModel.playerExists(name: trimmedName)
    }
} 
