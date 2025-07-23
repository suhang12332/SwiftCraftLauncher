import Foundation

enum ModrinthService {


    static func searchProjects(
        facets: [[String]]? = nil,
        index: String,
        offset: Int = 0,
        limit: Int,
        query: String?
    ) async throws -> ModrinthResult {
        var components = URLComponents(
            url: URLConfig.API.Modrinth.search,
            resolvingAgainstBaseURL: true
        )!
        var queryItems = [
            URLQueryItem(name: "index", value: index),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, 100))),
        ]
        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let facets = facets {
            let facetsJson = try JSONEncoder().encode(facets)
            if let facetsString = String(data: facetsJson, encoding: .utf8) {
                queryItems.append(
                    URLQueryItem(name: "facets", value: facetsString)
                )
            }
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }
        Logger.shared.info("Modrinth 搜索 URL：\(url.absoluteString)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ModrinthResult.self, from: data)
    }

    static func fetchLoaders() async throws -> [Loader] {
        let (data, _) = try await URLSession.shared.data(
            from: URLConfig.API.Modrinth.Tag.loader
        )
        Logger.shared.info("Modrinth 搜索 URL：\(URLConfig.API.Modrinth.Tag.loader)")
        return try JSONDecoder().decode([Loader].self, from: data)
    }

    static func fetchCategories() async throws -> [Category] {
        let (data, _) = try await URLSession.shared.data(
            from: URLConfig.API.Modrinth.Tag.category
        )
        Logger.shared.info("Modrinth 搜索 URL：\(URLConfig.API.Modrinth.Tag.category)")
        return try JSONDecoder().decode([Category].self, from: data)
    }
    

    static func fetchGameVersions() async throws -> [GameVersion] {
        let (data, _) = try await URLSession.shared.data(
            from: URLConfig.API.Modrinth.Tag.gameVersion
        )
        Logger.shared.info("Modrinth 搜索 URL：\(URLConfig.API.Modrinth.Tag.gameVersion)")
        return try JSONDecoder().decode([GameVersion].self, from: data)
    }

    static func fetchProjectDetails(id: String) async throws -> ModrinthProjectDetail {
        let url = URLConfig.API.Modrinth.project(id: id)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        Logger.shared.info("Modrinth 搜索 URL：\(url)")
        return try decoder.decode(ModrinthProjectDetail.self, from: data)
    }

    static func fetchProjectVersions(id: String) async throws -> [ModrinthProjectDetailVersion] {
        let url = URLConfig.API.Modrinth.version(id: id)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        Logger.shared.info("Modrinth 搜索 URL：\(url)")
        return try decoder.decode([ModrinthProjectDetailVersion].self, from: data)
    }
    
    static func fetchProjectVersionsFilter(
            id: String,
            selectedVersions: [String],
            selectedLoaders: [String],
            type: String
        ) async throws -> [ModrinthProjectDetailVersion] {
            let versions = try await fetchProjectVersions(id: id)
            var loaders = selectedLoaders
            if type == "datapack" {
                loaders = ["datapack"]
            }else if type == "resourcepack" {
                loaders = ["minecraft"]
            }
            return versions.filter { version in
                // 必须同时满足版本和 loader 匹配
                let versionMatch = selectedVersions.isEmpty || !Set(version.gameVersions).isDisjoint(with: selectedVersions)
                let loaderMatch = loaders.isEmpty || !Set(version.loaders).isDisjoint(with: loaders)
                return versionMatch && loaderMatch
            }
        }

    static func fetchProjectDependencies(type: String,cachePath: URL,id: String, selectedVersions: [String], selectedLoaders: [String]) async throws -> ModrinthProjectDependency {
        // 1. 获取所有筛选后的版本
        let versions = try await fetchProjectVersionsFilter(id: id, selectedVersions: selectedVersions, selectedLoaders: selectedLoaders,type: type)
        // 只取第一个版本
        guard let firstVersion = versions.first else {
            return ModrinthProjectDependency(projects: [])
        }
        
        // 2. 收集所有依赖的projectId
        var dependencyProjectIds = Set<String>()
        
        let missingIds = firstVersion.dependencies
            .filter { $0.dependencyType == "required" }
            .compactMap(\.projectId)
            .filter { !ModScanner.shared.isModInstalledSync(projectId: $0, in: cachePath) }

        missingIds.forEach { dependencyProjectIds.insert($0) }
        
        
        // 3. 获取所有依赖项目详情
        var dependencyProjects: [ModrinthProjectDetail] = []
        for depId in dependencyProjectIds {
            do {
                let detail = try await fetchProjectDetails(id: depId)
                dependencyProjects.append(detail)
            } catch {
                Logger.shared.error("Failed to fetch dependency project detail for id: \(depId), error: \(error)")
            }
        }
        // 4. 只返回第一个版本
        let _: [ModrinthProjectDetailVersion] = [firstVersion]
        return ModrinthProjectDependency(projects: dependencyProjects)
    }
    // 过滤出 primary == true 的文件
    static func filterPrimaryFiles(from files: [ModrinthVersionFile]?) -> ModrinthVersionFile? {
        return files?.filter { $0.primary == true }.first
    }
    

    /// 通过文件 hash 查询 Modrinth API，返回 ModrinthProjectDetail（用版本详情解码并字段映射）
    static func fetchModrinthDetail(by hash: String, completion: @escaping (ModrinthProjectDetail?) -> Void) {
        let url = URLConfig.API.Modrinth.versionFile(hash: hash)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            guard let version = try? decoder.decode(ModrinthProjectDetailVersion.self, from: data) else {
                completion(nil)
                return
            }
            Task {
                do {
                    let detail = try await ModrinthService.fetchProjectDetails(id: version.id)
                    await MainActor.run {
                        completion(detail)
                    }
                } catch {
                    await MainActor.run {
                        completion(nil)
                    }
                }
            }
        }
        task.resume()
    }
}


