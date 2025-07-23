import Foundation
import CryptoKit

class ModScanner {
    static let shared = ModScanner()
    private init() {}
    /// 主入口：获取 ModrinthProjectDetail
    func getModrinthProjectDetail(for fileURL: URL, completion: @escaping (ModrinthProjectDetail?) -> Void) {
        guard let hash = Self.sha1Hash(of: fileURL) else {
            completion(nil); return
        }
        if let cached = AppCacheManager.shared.get(namespace: "mod", key: hash, as: ModrinthProjectDetail.self) {
            completion(cached)
            return
        }
        ModrinthService.fetchModrinthDetail(by: hash) { modrinthDetail in
            if let detail = modrinthDetail {
                self.saveToCache(hash: hash, detail: detail)
                completion(detail)
            } else {
                ModMetadataParser.parseModMetadata(fileURL: fileURL) { modid, version in
                    guard let _ = modid, let _ = version else {
                        completion(nil)
                        return
                    }
                    completion(nil) // 如有后续逻辑可补充
                }
            }
        }
    }
    // 新增：外部调用缓存写入
    func saveToCache(hash: String, detail: ModrinthProjectDetail) {
        AppCacheManager.shared.set(namespace: "mod", key: hash, value: detail)
    }

    // MARK: - Hash
    static func sha1Hash(of url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let hash = Insecure.SHA1.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}

extension ModScanner {
    /// 获取目录下所有 jar/zip 文件及其 hash、缓存 detail
    public func localModDetails(in dir: URL) -> [(file: URL, hash: String, detail: ModrinthProjectDetail?)] {
        let fileManager = FileManager.default
        let files = (try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        let jarFiles = files.filter { ["jar", "zip"].contains($0.pathExtension.lowercased()) }
        return jarFiles.compactMap { fileURL in
            if let hash = ModScanner.sha1Hash(of: fileURL) {
                let detail = AppCacheManager.shared.get(namespace: "mod", key: hash, as: ModrinthProjectDetail.self)
                return (file: fileURL, hash: hash, detail: detail)
            }
            return nil
        }
    }

    /// 同步：仅查缓存
    func isModInstalledSync(projectId: String, in modsDir: URL) -> Bool {
        for ( _, _, detail) in localModDetails(in: modsDir) {
            if let detail = detail, detail.id == projectId {
                return true
            }
        }
        return false
    }

    /// 异步：查缓存+API+本地解析
    func isModInstalled(projectId: String, in modsDir: URL, completion: @escaping (Bool) -> Void) {
        let fileManager = FileManager.default
        let files = (try? fileManager.contentsOfDirectory(at: modsDir, includingPropertiesForKeys: nil)) ?? []
        let jarFiles = files.filter { ["jar", "zip"].contains($0.pathExtension.lowercased()) }
        if jarFiles.isEmpty {
            completion(false)
            return
        }
        let group = DispatchGroup()
        var found = false
        for fileURL in jarFiles {
            group.enter()
            getModrinthProjectDetail(for: fileURL) { detail in
                if found { group.leave(); return }
                if let detail = detail, detail.id == projectId {
                    found = true
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(found)
        }
    }

    /// 扫描目录，返回所有已识别的 ModrinthProjectDetail
    func scanResourceDirectory(_ dir: URL, completion: @escaping ([ModrinthProjectDetail]) -> Void) {
        let fileManager = FileManager.default
        let files = (try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        let jarFiles = files.filter { ["jar", "zip"].contains($0.pathExtension.lowercased()) }
        if jarFiles.isEmpty {
            completion([])
            return
        }
        var results: [ModrinthProjectDetail] = []
        let group = DispatchGroup()
        for fileURL in jarFiles {
            group.enter()
            getModrinthProjectDetail(for: fileURL) { detail in
                if let detail = detail {
                    results.append(detail)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(results)
        }
    }
}
