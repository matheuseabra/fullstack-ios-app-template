import Foundation
import UserNotifications

// MARK: - NotificationManager

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pushToken: String?

    // MARK: - Permission

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            await refreshStatus()
        } catch {
            print("[NotificationManager] Permission request failed: \(error)")
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Token Registration

    /// Call this from AppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        pushToken = token
        Task { await sendTokenToServer(token) }
    }

    // MARK: - Private

    private func sendTokenToServer(_ token: String) async {
        do {
            let body = ["push_token": token]
            let _: SuccessResponse = try await APIClient.shared.put(
                APIEndpoints.notificationToken,
                body: body
            )
        } catch {
            print("[NotificationManager] Failed to register token: \(error)")
        }
    }
}

// MARK: - Shared response type
private struct SuccessResponse: Decodable { let ok: Bool }

// Needed for registerForRemoteNotifications
import UIKit
