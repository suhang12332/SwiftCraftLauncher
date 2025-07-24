//
//  SwiftCraftLauncherApp.swift
//  SwiftCraftLauncher
//
//  Created by su on 2025/7/23.
//

import SwiftUI

@main
struct SwiftCraftLauncherApp: App {
    // MARK: - StateObjects
    @StateObject private var playerListViewModel = PlayerListViewModel()
    @StateObject private var gameRepository = GameRepository()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(playerListViewModel)
                .environmentObject(gameRepository)
            
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowResizability(.contentMinSize)
        
        Settings {
            SettingsView().environmentObject(gameRepository)
        }
    }
}
