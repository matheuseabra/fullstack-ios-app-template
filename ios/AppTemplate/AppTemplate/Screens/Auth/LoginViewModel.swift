import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isLoadingApple  = false
    @Published var isLoadingGoogle = false
    @Published var errorMessage: String?

    private let apple  = AppleSignInManager.shared
    private let google = GoogleSignInManager.shared

    var isLoading: Bool { isLoadingApple || isLoadingGoogle }

    func signInWithApple() async {
        isLoadingApple = true
        errorMessage = nil
        defer { isLoadingApple = false }
        do {
            try await apple.signIn()
            Analytics.track(.login(method: "apple"))
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }

    func signInWithGoogle() async {
        isLoadingGoogle = true
        errorMessage = nil
        defer { isLoadingGoogle = false }
        do {
            try await google.signIn()
            Analytics.track(.login(method: "google"))
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}
