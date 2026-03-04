import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = LoginViewModel()

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundStyle(Color.accent)
                    Text("AppTemplate")
                        .font(.display(28))
                        .foregroundStyle(Color.textPrimary)
                    Text("Your tagline here")
                        .font(.body(17))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, Spacing.xs)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: Spacing.md) {
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.body(13))
                            .foregroundStyle(Color.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Sign in with Apple (HIG style)
                    if AppEnvironment.enableAppleSignIn {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { _ in
                            Task { await vm.signInWithApple() }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 54)
                        .cornerRadius(Radius.lg)
                        .disabled(vm.isLoading)
                    }

                    // Google Sign-In
                    if AppEnvironment.enableGoogleSignIn {
                        AppButton(
                            "Sign in with Google",
                            style: .ghost,
                            isLoading: vm.isLoadingGoogle
                        ) {
                            Task { await vm.signInWithGoogle() }
                        }
                        .disabled(vm.isLoading)
                    }

                    // Skip (dev shortcut — bypasses auth)
                    Button("Skip") { router.root = .onboarding }
                        .font(.body(14))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, Spacing.lg)

                // Legal footer
                HStack(spacing: 4) {
                    Text("By continuing you agree to our")
                        .foregroundStyle(Color.textTertiary)
                    Link("Terms", destination: URL(string: "https://yourapp.com/terms")!)
                        .foregroundStyle(Color.accent)
                    Text("&")
                        .foregroundStyle(Color.textTertiary)
                    Link("Privacy", destination: URL(string: "https://yourapp.com/privacy")!)
                        .foregroundStyle(Color.accent)
                }
                .font(.body(12))
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onChange(of: vm.isLoading) { _, loading in
            if !loading && vm.errorMessage == nil {
                router.advance()
            }
        }
    }
}
