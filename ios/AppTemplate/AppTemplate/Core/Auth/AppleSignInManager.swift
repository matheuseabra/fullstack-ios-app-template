import Foundation
import AuthenticationServices

// MARK: - AppleSignInManager
// Uses native AuthenticationServices (no SPM package needed).

@MainActor
final class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()

    @Published private(set) var isLoading = false
    @Published var error: Error?

    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }

        let authorization = try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthManagerError.missingToken
        }

#if canImport(Supabase)
        // Exchange Apple token for Supabase session
        // try await supabaseClient.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: token))
        // await AuthManager.shared.refreshSession()
        _ = token
#else
        await AuthManager.shared.setAuthenticated(token: token)
#endif
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            continuation?.resume(returning: authorization)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Errors
enum AuthManagerError: LocalizedError {
    case missingToken
    var errorDescription: String? { "Unable to retrieve authentication token." }
}

import UIKit
