import UIKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - AppDelegate
// Handles UIKit lifecycle callbacks that SwiftUI's App protocol doesn't expose.

final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        GoogleSignInManager.shared.configure()
        return true
    }

    // MARK: - Remote Notifications (APNs)

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationManager.shared.didRegister(deviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
#if targetEnvironment(simulator)
        // Should not reach here — NotificationManager skips registerForRemoteNotifications()
        // on Simulator. Belt-and-suspenders: inject fake token silently if it ever does.
        let fakeToken = Data(repeating: 0xAB, count: 32)
        Task { @MainActor in
            NotificationManager.shared.didRegister(deviceToken: fakeToken)
        }
#else
        // On a real device this means the Push Notifications capability is missing
        // from the provisioning profile. Requires a paid Apple Developer account.
        // TODO: Enable Push Notifications in the Apple Developer Portal and add
        //       aps-environment = development to AppTemplate.entitlements.
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
#endif
    }

    // MARK: - Google Sign-In URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
#if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
#else
        return false
#endif
    }
}
