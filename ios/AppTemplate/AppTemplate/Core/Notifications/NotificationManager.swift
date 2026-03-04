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
#if DEBUG
                // Debug local/dev builds: bypass APNs registration (which requires
                // push capability + paid Apple Developer account) and inject a
                // deterministic fake token so downstream UI/logic still works.
                // Production behavior is preserved in #else.
                let fakeToken = Data(repeating: 0xAB, count: 32)
                didRegister(deviceToken: fakeToken)
                print("[NotificationManager] Debug build — mocked APNs token injected")
#else
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
#endif
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

    // MARK: - Simulator: local notification delivery

#if targetEnvironment(simulator)
    /// Schedules a one-shot local notification to mimic a remote push.
    /// Mirrors the payload in push_payload.json so the experience matches
    /// what `xcrun simctl push` would deliver on a real device.
    func simulatePush(title: String, body: String, delay: TimeInterval = 3) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "simulated-push-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[NotificationManager] Simulated push scheduled in \(delay)s")
        } catch {
            print("[NotificationManager] Failed to schedule simulated push: \(error)")
        }
    }
#endif

    // MARK: - Private

    private func sendTokenToServer(_ token: String) async {
    #if DEBUG
        // Skip token registration for debug fake tokens.
        print("[NotificationManager] Debug build — skipping token upload (\(token.prefix(8))…)")
        return
#else
        do {
            let body = ["push_token": token]
            let _: SuccessResponse = try await APIClient.shared.put(
                APIEndpoints.notificationToken,
                body: body
            )
        } catch {
            print("[NotificationManager] Failed to register token: \(error)")
        }
#endif
    }
}

// MARK: - Shared response type
private struct SuccessResponse: Decodable { let ok: Bool }

// Needed for registerForRemoteNotifications
import UIKit
