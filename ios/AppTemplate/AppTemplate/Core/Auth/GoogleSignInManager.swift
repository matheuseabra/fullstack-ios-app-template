import Foundation
import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn

// MARK: - GoogleSignInManager

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()

    @Published private(set) var isLoading = false

    /// Call once at app launch (after PaymentManager.configure).
    func configure() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: AppEnvironment.googleClientID
        )
    }

    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthManagerError.missingToken
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthManagerError.missingToken
        }

        let accessToken = result.user.accessToken.tokenString
        try await AuthManager.shared.signInWithGoogle(idToken: idToken, accessToken: accessToken)
    }
}

#else
// MARK: - Stub (compiles without GoogleSignIn package)

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    @Published private(set) var isLoading = false

    func configure() {}

    func signIn() async throws {
        throw AuthManagerError.missingToken
    }
}
#endif
