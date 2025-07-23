import Foundation

class AppCacheManager {
    static let shared = AppCacheManager()
    private var cache: [String: [String: Data]] = [:] // namespace: [key: encodedData]
    private let cacheFileURL: URL
    private let queue = DispatchQueue(label: "AppCacheManager.queue")

    private init() {
        guard let fileURL = AppPaths.appCacheFile else {
            fatalError("AppCacheManager: 无法获取缓存文件路径")
        }
        self.cacheFileURL = fileURL
        loadCache()
    }

    // MARK: - Public API
    func set<T: Codable>(namespace: String, key: String, value: T) {
        queue.sync {
            var ns = cache[namespace] ?? [:]
            if let data = try? JSONEncoder().encode(value) {
                ns[key] = data
                cache[namespace] = ns
                persistCache()
            }
        }
    }

    func get<T: Codable>(namespace: String, key: String, as type: T.Type) -> T? {
        return queue.sync {
            guard let ns = cache[namespace], let data = ns[key] else {
                return nil
            }
            if let result = try? JSONDecoder().decode(T.self, from: data) {
                return result
            } else {
                return nil
            }
        }
    }

    func remove(namespace: String, key: String) {
        queue.sync {
            cache[namespace]?.removeValue(forKey: key)
            persistCache()
        }
    }

    func clear(namespace: String) {
        queue.sync {
            cache[namespace] = [:]
            persistCache()
        }
    }

    func clearAll() {
        queue.sync {
            cache.removeAll()
            persistCache()
        }
    }

    // MARK: - Persistence
    private func persistCache() {
        do {
            let data = try JSONEncoder().encode(cache)
            try FileManager.default.createDirectory(at: cacheFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: cacheFileURL)
        } catch {
            // do nothing
        }
    }

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let loaded = try JSONDecoder().decode([String: [String: Data]].self, from: data)
            cache = loaded
        } catch {
            // do nothing
        }
    }
} 