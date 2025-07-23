import Foundation
import UserNotifications
import os

struct NotificationManager {
    static func send(title: String, body: String) {
        Logger.shared.info("准备发送通知：\(title) - \(body)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.error("添加通知请求时出错：\(error.localizedDescription)")
            } else {
                Logger.shared.info("成功添加通知请求：\(request.identifier)")
            }
        }
    }

    static func requestAuthorizationIfNeeded() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                Logger.shared.info("通知权限已授予")
            } else {
                Logger.shared.warning("用户拒绝了通知权限")
            }
        } catch {
            Logger.shared.error("请求通知权限时出错: \(error.localizedDescription)")
        }
    }
} 