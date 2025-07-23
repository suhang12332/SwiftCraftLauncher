import SwiftUI

// MARK: - Main View
struct ModrinthDetailView: View {
    // MARK: - Properties
    let query: String
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var selectedLoader: [String]
    let gameInfo: GameVersionInfo?
    @Binding var selectedItem: SidebarItem

    @StateObject private var viewModel = ModrinthSearchViewModel()
    @State private var hasLoaded = false
    @State private var searchText: String = ""
    @State private var searchTimer: Timer? = nil
    @Binding var gameType: Bool
    @State private var lastSearchKey: String = ""
    @State private var lastSearchParams: String = ""

    private var searchKey: String {
        [
            query,
            sortIndex,
            selectedVersions.joined(separator: ","),
            selectedCategories.joined(separator: ","),
            selectedFeatures.joined(separator: ","),
            selectedResolutions.joined(separator: ","),
            selectedPerformanceImpact.joined(separator: ","),
            selectedLoader.joined(separator: ","),
            String(currentPage),
            String(gameType)
        ].joined(separator: "|")
    }

    // MARK: - Body
    var body: some View {
        LazyVStack {
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            } else if let error = viewModel.error {
                ErrorView(error)
            } else if viewModel.results.isEmpty {
                EmptyResultView()
            } else {
                resultList
            }
        }
        .task { if gameType {
            await initialLoadIfNeeded()
        } }
        .onChange(of: searchKey) { _, newKey in
            if newKey != lastSearchKey {
                lastSearchKey = newKey
                triggerSearch()
            }
        }
        .onChange(of: viewModel.totalHits) { _, newValue in totalItems = newValue }
        .searchable(text: $searchText)
        .onChange(of: searchText) { _, _ in
            debounceSearch()
        }
    }

    // MARK: - Private Methods
    private func initialLoadIfNeeded() async {
        if !hasLoaded {
            hasLoaded = true
            await performSearch()
        }
    }

    private func triggerSearch() {
        Task { await performSearch() }
    }

    private func resetPageAndSearch() {
        currentPage = 1
        triggerSearch()
    }

    private func debounceSearch() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: false
        ) { _ in
            Task { await performSearch() }
        }
    }

    private func performSearch() async {
        let params = [
            query,
            sortIndex,
            selectedVersions.joined(separator: ","),
            selectedCategories.joined(separator: ","),
            selectedFeatures.joined(separator: ","),
            selectedResolutions.joined(separator: ","),
            selectedPerformanceImpact.joined(separator: ","),
            selectedLoader.joined(separator: ","),
            String(currentPage),
            String(gameType),
            searchText
        ].joined(separator: "|")
        if params == lastSearchParams {
            // 完全重复，不请求
            return
        }
        lastSearchParams = params
        await viewModel.search(
            projectType: query,
            page: currentPage,
            query: searchText,
            sortIndex: sortIndex,
            versions: selectedVersions,
            categories: selectedCategories,
            features: selectedFeatures,
            resolutions: selectedResolutions,
            performanceImpact: selectedPerformanceImpact,
            loaders: selectedLoader
        )
    }

    // MARK: - Result List
    private var resultList: some View {
        ForEach(viewModel.results, id: \.projectId) { mod in
            ModrinthDetailCardView(
                project: mod,
                selectedVersions: selectedVersions,
                selectedLoaders: selectedLoader,
                gameInfo: gameInfo,
                query: query,
                type: true,
                selectedItem: $selectedItem
            )
            .padding(.vertical, ModrinthConstants.UI.verticalPadding)
            .listRowInsets(
                EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            )
            .onTapGesture {
                selectedProjectId = mod.projectId
                if let type = ResourceType(rawValue: query) {
                    selectedItem = .resource(type)
                }
            }
        }
    }
}
