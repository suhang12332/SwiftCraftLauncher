//  CategoryContent.swift
//  Launcher
//
//  Created by su on 2025/5/8.
//

import SwiftUI

// MARK: - CategoryContent
struct CategoryContentView: View {
    // MARK: - Properties
    let project: String
    @StateObject private var viewModel: CategoryContentViewModel
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpacts: [String]
    @Binding var selectedVersions: [String]
    @Binding var selectedLoaders: [String]
    let type: String
    let gameVersion: String?
    let gameLoader: String?

    // MARK: - Initialization
    init(
        project: String,
        type: String,
        selectedCategories: Binding<[String]>,
        selectedFeatures: Binding<[String]>,
        selectedResolutions: Binding<[String]>,
        selectedPerformanceImpacts: Binding<[String]>,
        selectedVersions: Binding<[String]>,
        selectedLoaders: Binding<[String]>,
        gameVersion: String? = nil,
        gameLoader: String? = nil
    ) {
        self.project = project
        self.type = type
        self._selectedCategories = selectedCategories
        self._selectedFeatures = selectedFeatures
        self._selectedResolutions = selectedResolutions
        self._selectedPerformanceImpacts = selectedPerformanceImpacts
        self._selectedVersions = selectedVersions
        self._selectedLoaders = selectedLoaders
        self.gameVersion = gameVersion
        self.gameLoader = gameLoader
        self._viewModel = StateObject(
            wrappedValue: CategoryContentViewModel(project: project)
        )
    }

    // MARK: - Body
    var body: some View {
        VStack {
            if let error = viewModel.error {
                ErrorView(error)
            } else {
                if type == "resource" {
                    versionSection
                }
                categorySection
                projectSpecificSections
            }
        }
        .task {
            await viewModel.loadData()
            setupDefaultSelections()
        }
    }
    
    // MARK: - Setup Methods
    private func setupDefaultSelections() {
        if let gameVersion = gameVersion {
            selectedVersions = [gameVersion]
        }
        if let gameLoader = gameLoader {
            if project != "shader" {
                selectedLoaders = [gameLoader]
            } else {
                selectedLoaders = []
            }
        }
    }

    // MARK: - Section Views
    private var categorySection: some View {
        CategorySectionView(
            title: "filter.category",
            items: viewModel.categories.map { FilterItem(id: $0.name, name: $0.name) },
            selectedItems: $selectedCategories,
            isLoading: viewModel.isLoading
        )
    }

    private var versionSection: some View {
        CategorySectionView(
            title: "filter.version",
            items: viewModel.versions.map { FilterItem(id: $0.id, name: $0.id) },
            selectedItems: $selectedVersions,
            isLoading: viewModel.isLoading,
            isVersionSection: true
        )
    }

    private var loaderSection: some View {
        CategorySectionView(
            title: "filter.loader",
            items: filteredLoaders.map { FilterItem(id: $0.name, name: $0.name) },
            selectedItems: $selectedLoaders,
            isLoading: viewModel.isLoading
        )
    }

    private var projectSpecificSections: some View {
        Group {
            switch project {
            case ProjectType.modpack, ProjectType.mod:
                if type == "resource" {
                    loaderSection
                }
                environmentSection
            case ProjectType.resourcepack:
                resourcePackSections
            case ProjectType.shader:
                loaderSection
                shaderSections
            default:
                EmptyView()
            }
        }
    }

    private var environmentSection: some View {
        CategorySectionView(
            title: "filter.environment",
            items: environmentItems,
            selectedItems: $selectedFeatures,
            isLoading: viewModel.isLoading
        )
    }

    private var resourcePackSections: some View {
        Group {
            CategorySectionView(
                title: "filter.behavior",
                items: viewModel.features.map { FilterItem(id: $0.name, name: $0.name) },
                selectedItems: $selectedFeatures,
                isLoading: viewModel.isLoading
            )
            CategorySectionView(
                title: "filter.resolutions",
                items: viewModel.resolutions.map { FilterItem(id: $0.name, name: $0.name) },
                selectedItems: $selectedResolutions,
                isLoading: viewModel.isLoading
            )
        }
    }

    private var shaderSections: some View {
        Group {
            CategorySectionView(
                title: "filter.behavior",
                items: viewModel.features.map { FilterItem(id: $0.name, name: $0.name) },
                selectedItems: $selectedFeatures,
                isLoading: viewModel.isLoading
            )
            CategorySectionView(
                title: "filter.performance",
                items: viewModel.performanceImpacts.map { FilterItem(id: $0.name, name: $0.name) },
                selectedItems: $selectedPerformanceImpacts,
                isLoading: viewModel.isLoading
            )
        }
    }

    // MARK: - Computed Properties
    private var filteredLoaders: [Loader] {
        viewModel.loaders.filter { $0.supported_project_types.contains(project) }
    }
    
    private var environmentItems: [FilterItem] {
        [
            FilterItem(id: "client", name: "environment.client".localized()),
            FilterItem(id: "server", name: "environment.server".localized())
        ]
    }
}
