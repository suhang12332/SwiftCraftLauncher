import Foundation
import ZIPFoundation
class ModMetadataParser {
    /// 解析 modid 和 version
    static func parseModMetadata(fileURL: URL, completion: @escaping (_ modid: String?, _ version: String?) -> Void) {
        do {
            let archive = try Archive(url: fileURL, accessMode: .read)
        // 1. Forge (mods.toml)
        if let entry = archive["META-INF/mods.toml"] {
            if let (modid, version) = parseForgeToml(archive: archive, entry: entry) {
                Logger.shared.info("ModMetadataParser: 解析 mods.toml 成功: \(modid) \(version)")
                completion(modid, version)
                return
            } else {
                Logger.shared.warning("ModMetadataParser: 解析 mods.toml 失败: \(fileURL.lastPathComponent)")
            }
        }
        // 2. Fabric (fabric.mod.json)
        if let entry = archive["fabric.mod.json"] {
            if let (modid, version) = parseFabricJson(archive: archive, entry: entry) {
                Logger.shared.info("ModMetadataParser: 解析 fabric.mod.json 成功: \(modid) \(version)")
                completion(modid, version)
                return
            } else {
                Logger.shared.warning("ModMetadataParser: 解析 fabric.mod.json 失败: \(fileURL.lastPathComponent)")
            }
        }
        // 3. 旧 Forge (mcmod.info)
        if let entry = archive["mcmod.info"] {
            if let (modid, version) = parseMcmodInfo(archive: archive, entry: entry) {
                Logger.shared.info("ModMetadataParser: 解析 mcmod.info 成功: \(modid) \(version)")
                completion(modid, version)
                return
            } else {
                Logger.shared.warning("ModMetadataParser: 解析 mcmod.info 失败: \(fileURL.lastPathComponent)")
            }
        }
        Logger.shared.warning("ModMetadataParser: 未能识别任何元数据: \(fileURL.lastPathComponent)")
        completion(nil, nil)
        } catch {
            Logger.shared.warning("ModMetadataParser: 无法打开压缩包: \(fileURL.lastPathComponent), error: \(error)")
            completion(nil, nil)
            return
        }
    }

    private static func parseForgeToml(archive: Archive, entry: Entry) -> (String, String)? {
        var data = Data()
        do {
            try _ = archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return nil
        }
        guard let tomlString = String(data: data, encoding: .utf8) else { return nil }
        let modid = matchFirst(in: tomlString, pattern: #"modId\s*=\s*[\"']([^\"']+)[\"']"#)
        let version = matchFirst(in: tomlString, pattern: #"version\s*=\s*[\"']([^\"']+)[\"']"#)
        if let modid = modid, let version = version {
            return (modid, version)
        }
        return nil
    }

    private static func parseFabricJson(archive: Archive, entry: Entry) -> (String, String)? {
        var data = Data()
        do {
            try _ = archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let modid = json["id"] as? String, let version = json["version"] as? String else { return nil }
        return (modid, version)
    }

    private static func parseMcmodInfo(archive: Archive, entry: Entry) -> (String, String)? {
        var data = Data()
        do {
            try _ = archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return nil
        }
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let first = arr.first else { return nil }
        guard let modid = first["modid"] as? String, let version = first["version"] as? String else { return nil }
        return (modid, version)
    }

    private static func matchFirst(in text: String, pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex?.firstMatch(in: text, range: nsrange),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
