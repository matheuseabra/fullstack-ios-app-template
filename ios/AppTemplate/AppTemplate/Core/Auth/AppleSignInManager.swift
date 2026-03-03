import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - AppleSignInManager

@MainActor
final class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()

    @Published private(set) var isLoading = false

    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private var currentNonce: String?

    // MARK: - Sign In

    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }

        let nonce = randomNonceString()
        currentNonce = nonce

        let authorization = try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else {
            throw AuthManagerError.missingToken
        }

        try await AuthManager.shared.signInWithApple(idToken: idToken, nonce: nonce)
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
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

// MARK: - Presentation Context

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

// MARK: - Error

enum AuthManagerError: LocalizedError {
    case missingToken
    var errorDescription: String? { "Unable to retrieve authentication token." }
}
