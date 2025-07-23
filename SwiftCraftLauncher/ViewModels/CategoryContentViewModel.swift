import SwiftUI

// MARK: - Constants
private enum CategoryConstants {
    static let cacheTimeout: TimeInterval = 300
}



// MARK: - ViewModel
@MainActor
final class CategoryContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var categories: [Category] = []
    @Published private(set) var features: [Category] = []
    @Published private(set) var resolutions: [Category] = []
    @Published private(set) var performanceImpacts: [Category] = []
    @Published private(set) var versions: [GameVersion] = []
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var error: Error?
    @Published private(set) var loaders: [Loader] = []
    
    // MARK: - Private Properties
    private var lastFetchTime: Date?
    private let project: String
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(project: String) {
        self.project = project
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard shouldFetchData else { return }
        
        loadTask = Task {
            await fetchData()
        }
    }
    
    func clearCache() {
        loadTask?.cancel()
        lastFetchTime = nil
        resetData()
    }
    
    // MARK: - Private Helpers
    private var shouldFetchData: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) >= CategoryConstants.cacheTimeout || categories.isEmpty
    }
    
    private func fetchData() async {
        isLoading = true
        error = nil
        
        do {
            async let categoriesTask = ModrinthService.fetchCategories()
            async let versionsTask = ModrinthService.fetchGameVersions()
            async let loadersTask = ModrinthService.fetchLoaders()
            let (categoriesResult, versionsResult, loadersResult) = try await (categoriesTask, versionsTask, loadersTask)
            await processFetchedData(categories: categoriesResult, versions: versionsResult, loaders: loadersResult)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func processFetchedData(categories: [Category], versions: [GameVersion], loaders: [Loader]) async {
        let filteredVersions = versions
            .filter { $0.version_type == "release" }
            .sorted { $0.date > $1.date }
        
        let projectType = project == ProjectType.datapack ? ProjectType.mod : project
        let filteredCategories = categories.filter { $0.project_type == projectType }
        
        await MainActor.run {
            self.versions = filteredVersions
            self.categories = filteredCategories.filter { $0.header == CategoryHeader.categories }
            self.features = filteredCategories.filter { $0.header == CategoryHeader.features }
            self.resolutions = filteredCategories.filter { $0.header == CategoryHeader.resolutions }
            self.performanceImpacts = filteredCategories.filter { $0.header == CategoryHeader.performanceImpact }
            self.lastFetchTime = Date()
            self.loaders = loaders
        }
    }
    
    private func handleError(_ error: Error) {
        Logger.shared.error("加载数据错误: \(error)")
        Task { @MainActor in
            self.error = error
        }
    }
    
    private func resetData() {
        categories.removeAll()
        features.removeAll()
        resolutions.removeAll()
        performanceImpacts.removeAll()
        versions.removeAll()
        loaders.removeAll()
    }
    
    
} 
