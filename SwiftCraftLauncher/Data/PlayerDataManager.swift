import Foundation

/// Handles saving and loading player data using UserDefaults.
class PlayerDataManager {
    private let playersKey = "savedPlayers"
    
    /// Adds a new player with the given name.
    /// - Parameter name: The name of the player to add.
    /// - Returns: True if the player was added successfully, false otherwise (e.g., name already exists, or initialization fails).
    func addPlayer(name: String) -> Bool {
        var players = loadPlayers()
        if playerExists(name: name) {
            Logger.shared.debug("已存在同名玩家: \(name)")
            return false
        }
        guard let newPlayer = try? Player(name: name, isCurrent: players.isEmpty) else {
            Logger.shared.debug("创建玩家实例失败: \(name)")
            return false
        }
        players.append(newPlayer)
        savePlayers(players)
        Logger.shared.debug("已添加新玩家: \(name)")
        return true
    }
    
    /// Loads all saved players from UserDefaults.
    /// - Returns: An array of Player objects.
    func loadPlayers() -> [Player] {
        guard let playersData = UserDefaults.standard.data(forKey: playersKey) else {
            return []
        }
        let decoder = JSONDecoder()
        if let players = try? decoder.decode([Player].self, from: playersData) {
            return players
        } else {
            Logger.shared.debug("解码玩家数据失败")
            return []
        }
    }
    
    /// Checks if a player with the given name exists (case-insensitive).
    /// - Parameter name: The name to check.
    /// - Returns: True if a player with the name exists, false otherwise.
    func playerExists(name: String) -> Bool {
        loadPlayers().contains { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Deletes a player with the given ID.
    /// - Parameter id: The ID of the player to delete.
    /// - Returns: True if the player was deleted successfully, false otherwise (e.g., player not found).
    func deletePlayer(byID id: String) -> Bool {
        var players = loadPlayers()
        let initialCount = players.count
        players.removeAll { $0.id == id }
        if players.count < initialCount {
            savePlayers(players)
            Logger.shared.debug("已删除玩家 (ID: \(id))")
            return true
        } else {
            Logger.shared.debug("未找到要删除的玩家 (ID: \(id))")
            return false
        }
    }
    
    /// Saves the array of players to UserDefaults.
    /// - Parameter players: The array of Player objects to save.
    func savePlayers(_ players: [Player]) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(players) {
            UserDefaults.standard.set(encodedData, forKey: playersKey)
            Logger.shared.debug("玩家数据已保存")
        } else {
            Logger.shared.debug("编码玩家数据失败")
        }
    }
} 
