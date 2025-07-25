import Foundation

class AppCacheManager {
    static let shared = AppCacheManager()
    private let queue = DispatchQueue(label: "AppCacheManager.queue")

    private func fileURL(for namespace: String) -> URL {
        guard let dir = AppPaths.launcherSupportDirectory?.appendingPathComponent("cache") else {
            fatalError("AppCacheManager: 无法获取缓存目录")
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(namespace).json")
    }

    // MARK: - Public API
    func set<T: Codable>(namespace: String, key: String, value: T) {
        queue.sync {
            var nsDict = loadNamespace(namespace)
            if let data = try? JSONEncoder().encode(value) {
                nsDict[key] = data
                saveNamespace(namespace, dict: nsDict)
            }
        }
    }

    func get<T: Codable>(namespace: String, key: String, as type: T.Type) -> T? {
        return queue.sync {
            let nsDict = loadNamespace(namespace)
            guard let data = nsDict[key] else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
    }

    func remove(namespace: String, key: String) {
        queue.sync {
            var nsDict = loadNamespace(namespace)
            nsDict.removeValue(forKey: key)
            saveNamespace(namespace, dict: nsDict)
        }
    }

    func clear(namespace: String) {
        queue.sync {
            saveNamespace(namespace, dict: [:])
        }
    }

    func clearAll() {
        queue.sync {
            guard let dir = AppPaths.launcherSupportDirectory?.appendingPathComponent("cache") else { return }
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension == "json" {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Persistence
    private func loadNamespace(_ namespace: String) -> [String: Data] {
        let url = fileURL(for: namespace)
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        guard let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: Data].self, from: data)) ?? [:]
    }

    private func saveNamespace(_ namespace: String, dict: [String: Data]) {
        let url = fileURL(for: namespace)
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: url)
        }
    }
} 