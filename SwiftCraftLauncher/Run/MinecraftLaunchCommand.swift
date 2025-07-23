import Foundation

/// Minecraft 启动命令生成器
struct MinecraftLaunchCommand {
    let player: Player?
    let game: GameVersionInfo
    let gameRepository: GameRepository
    
    /// 启动游戏
    public func launchGame() async {
        do {
            let command = game.launchCommand
            try await launchGameProcess(command: command)
        } catch {
            await handleLaunchError(error)
        }
    }
    
    /// 启动游戏进程
    private func launchGameProcess(command: String) async throws {
        let javaPath = GameSettingsManager.shared.defaultJavaPath
        Logger.shared.info("启动游戏进程: \(javaPath) \(command)")
        let scriptContent = """
        #!/bin/bash
        \(javaPath) \(command)
        """
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("launch_\(game.id).sh")
        do {
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        } catch {
            Logger.shared.error("写入启动脚本失败: \(error.localizedDescription)")
            throw error
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        await MainActor.run {
            _ = gameRepository.updateGameStatus(id: game.id, isRunning: true)
        }
        do {
            try process.run()
        } catch {
            Logger.shared.error("启动进程失败: \(error.localizedDescription)")
            _ = gameRepository.updateGameStatus(id: game.id, isRunning: false)
            throw error
        }
        let gameId = game.id
        process.terminationHandler = { _ in
            Task { @MainActor in
                _ = self.gameRepository.updateGameStatus(id: gameId, isRunning: false)
                // 清理临时脚本文件
                // try? FileManager.default.removeItem(at: scriptURL)
            }
        }
    }
    
    /// 处理启动错误
    private func handleLaunchError(_ error: Error) async {
        Logger.shared.error("启动游戏失败：\(error.localizedDescription)")
        _ = gameRepository.updateGameStatus(id: game.id, isRunning: false)
        // TODO: 显示错误提示
    }
}

/// 启动错误类型
private enum LaunchError: LocalizedError {
    case appSupportDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .appSupportDirectoryNotFound:
            return "error.app.support.missing".localized()
        }
    }
}
 
