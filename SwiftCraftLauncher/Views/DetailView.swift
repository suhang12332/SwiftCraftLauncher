//
//  DetailView.swift
//  MLauncher
//
//  Created by su on 2025/6/1.
//

import SwiftUI

struct DetailView: View {
    // MARK: - Properties
    @ObservedObject private var general = GeneralSettingsManager.shared
    @Binding var selectedItem: SidebarItem
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var gameResourcesType: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var loadedProjectDetail: ModrinthProjectDetail?
    @Binding var selectTab: Int
    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int
    @Binding var gameType: Bool
    @Binding var selectedLoader: [String]
    
    @EnvironmentObject var gameRepository: GameRepository
    
    // MARK: - Body
    var body: some View {
        List {
            switch selectedItem {
            case .game(let gameId):
                gameDetailView(gameId: gameId)
            case .resource(let type):
                resourceDetailView(type: type)
            }
        }
    }
    
    // MARK: - Game Detail View
    @ViewBuilder
    private func gameDetailView(gameId: String) -> some View {
        if let gameInfo = gameRepository.getGame(by: gameId) {
            GameInfoDetailView(
                game: gameInfo,
                query: $gameResourcesType,
                currentPage: $currentPage,
                totalItems: $totalItems,
                sortIndex: $sortIndex,
                selectedVersions: $selectedVersions,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectedProjectId: $selectedProjectId,
                selectedLoaders: $selectedLoader,
                gameType: $gameType,
                selectedItem: $selectedItem
            )
        }
    }
    
    // MARK: - Resource Detail View
    @ViewBuilder
    private func resourceDetailView(type: ResourceType) -> some View {
        if selectedProjectId != nil {
            ModrinthProjectDetailView(
                selectedTab: $selectTab,
                projectDetail: loadedProjectDetail,
                currentPage: $versionCurrentPage,
                versionTotal: $versionTotal
            )
        } else {
            ModrinthDetailView(
                query: type.rawValue,
                currentPage: $currentPage,
                totalItems: $totalItems,
                sortIndex: $sortIndex,
                selectedVersions: $selectedVersions,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectedProjectId: $selectedProjectId,
                selectedLoader: $selectedLoader,
                gameInfo: nil,
                selectedItem: $selectedItem,
                gameType: $gameType
            )
        }
    }
}
