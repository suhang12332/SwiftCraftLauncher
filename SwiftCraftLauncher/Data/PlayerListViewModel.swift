import Foundation
import SwiftUI

/// A view model that manages the list of players and interacts with PlayerDataManager.
class PlayerListViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayer: Player? = nil
    
    private let dataManager = PlayerDataManager()
    
    init() {
        loadPlayers()
    }
    
    /// Loads players from PlayerDataManager.
    func loadPlayers() {
        players = dataManager.loadPlayers()
        currentPlayer = players.first(where: { $0.isCurrent })
        Logger.shared.debug("玩家列表已加载，数量: \(players.count)")
        Logger.shared.debug("当前玩家 (加载后): \(currentPlayer?.name ?? "无")")
    }
    
    /// Adds a new player.
    /// - Parameter name: The name of the player to add.
    /// - Returns: True if the player was added successfully, false otherwise.
    func addPlayer(name: String) -> Bool {
        let success = dataManager.addPlayer(name: name)
        if success {
            loadPlayers()
            Logger.shared.debug("玩家 \(name) 添加成功，列表已更新。")
            Logger.shared.debug("当前玩家 (添加后): \(currentPlayer?.name ?? "无")")
        } else {
            Logger.shared.debug("添加玩家 \(name) 失败。")
        }
        return success
    }
    
    /// Deletes a player based on its ID.
    /// - Parameter id: The ID of the player to delete.
    /// - Returns: True if the player was deleted successfully, false otherwise.
    func deletePlayer(byID id: String) -> Bool {
        let success = dataManager.deletePlayer(byID: id)
        if success {
            if currentPlayer?.id == id {
                currentPlayer = players.first(where: { $0.isCurrent }) ?? players.first
                if currentPlayer == nil && !players.isEmpty {
                    setCurrentPlayer(byID: players[0].id)
                } else if currentPlayer == nil && players.isEmpty {
                    Logger.shared.debug("当前玩家被删除，且列表已空。")
                }
            }
            loadPlayers()
            Logger.shared.debug("玩家 (ID: \(id)) 删除成功，列表已更新。")
        } else {
            Logger.shared.debug("删除玩家 (ID: \(id)) 失败。")
        }
        return success
    }
    
    /// Sets the given player as the current player based on its ID.
    /// - Parameter playerId: The ID of the player to set as current.
    func setCurrentPlayer(byID playerId: String) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else {
            Logger.shared.debug("尝试设置不存在的玩家为当前玩家 (ID: \(playerId))")
            return
        }
        for i in 0..<players.count {
            players[i].isCurrent = (i == index)
        }
        currentPlayer = players[index]
        dataManager.savePlayers(players)
        Logger.shared.debug("已设置玩家 (ID: \(playerId), 姓名: \(currentPlayer?.name ?? "未知")) 为当前玩家，数据已保存。")
    }
    
    /// Checks if a player with the given name exists.
    /// - Parameter name: The name to check.
    /// - Returns: True if a player with the name exists, false otherwise.
    func playerExists(name: String) -> Bool {
        dataManager.playerExists(name: name)
    }
} 
