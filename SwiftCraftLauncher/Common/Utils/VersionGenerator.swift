import Foundation

/// 版本号生成工具，支持主版本.次版本.修订号-预发布标识（如 1.2.3-beta）
struct VersionGenerator {
    /// 生成下一个预发布版本号（不带编号）
    /// - Parameters:
    ///   - current: 当前版本号（如 1.2.3-beta 或 1.2.3）
    ///   - preRelease: 预发布标识（如 beta, alpha, rc）
    /// - Returns: 新的版本号字符串
    static func nextPreReleaseVersion(current: String, preRelease: String = "beta") -> String {
        let regex = try! NSRegularExpression(pattern: "^([0-9]+)\\.([0-9]+)\\.([0-9]+)(?:-([a-zA-Z]+))?$")
        guard let match = regex.firstMatch(in: current, range: NSRange(current.startIndex..., in: current)) else {
            // 不符合规则，直接返回 1.0.0-preRelease
            return "1.0.0-\(preRelease)"
        }
        let major = Int((current as NSString).substring(with: match.range(at: 1))) ?? 1
        let minor = Int((current as NSString).substring(with: match.range(at: 2))) ?? 0
        let patch = Int((current as NSString).substring(with: match.range(at: 3))) ?? 0
        let pre = match.range(at: 4).location != NSNotFound ? (current as NSString).substring(with: match.range(at: 4)) : nil
        if let pre = pre, pre == preRelease {
            // 已经是该预发布标识，直接返回
            return "\(major).\(minor).\(patch)-\(preRelease)"
        } else {
            // 新增预发布标识
            return "\(major).\(minor).\(patch)-\(preRelease)"
        }
    }
} 