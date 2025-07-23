import Foundation
//
//  Common.swift
//  MLauncher
//
//  Created by su on 2025/6/28.
//
import SwiftUI

struct CommonUtil {
    // MARK: - Base64 图片解码工具
    static func imageFromBase64(_ base64: String) -> NSImage? {
        if base64.hasPrefix("data:image") {
            if let base64String = base64.split(separator: ",").last,
               let imageData = Data(base64Encoded: String(base64String)),
                let nsImage = NSImage(data: imageData)
            {
                return nsImage
            }
        } else if let imageData = Data(base64Encoded: base64),
            let nsImage = NSImage(data: imageData)
        {
            return nsImage
        }
        return nil
    }

    /// 格式化 ISO8601 字符串为相对时间（如“3天前”）
    static func formatRelativeTime(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: isoString)
        if date == nil {
            // 尝试不带毫秒的格式
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: isoString)
        }
        guard let date = date else { return isoString }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

