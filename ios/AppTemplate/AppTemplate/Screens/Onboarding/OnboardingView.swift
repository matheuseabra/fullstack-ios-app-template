import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back button (from second screen onwards)
                if vm.currentStep > 0 {
                    HStack {
                        Button { vm.goBack() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                }

                // Progress bar
                ProgressView(value: vm.progress)
                    .tint(Color.accent)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.sm)
                    .animation(.spring, value: vm.currentStep)

                // Step content
                TabView(selection: $vm.currentStep) {
                    ForEach(vm.questions.indices, id: \.self) { index in
                        OnboardingQuizStep(
                            question: vm.questions[index],
                            textInput: $vm.textInput,
                            selectedChoice: $vm.selectedChoice,
                            onChoiceSelected: {
                                // Auto-advance after brief delay so user sees selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    vm.advance()
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring, value: vm.currentStep)
            }

            // Error banner
            if let error = vm.errorMessage {
                Text(error)
                    .font(.body(13))
                    .foregroundStyle(Color.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 96)
            }

            // Bottom actions — varies by step type
            if vm.showsFAB {
                // Circular FAB next / finish button (text input, info, notifications)
                Button {
                    vm.advance()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.accent.opacity(0.4), radius: 12, y: 4)
                        if vm.isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.bg)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: vm.isLastStep ? "checkmark" : "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.bg)
                        }
                    }
                }
                .disabled(!vm.canAdvance() || vm.isSaving)
                .opacity(!vm.canAdvance() ? 0.5 : 1)
                .animation(.snappy, value: vm.canAdvance())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
            // Multiple choice screens: no bottom button (auto-advance on tap)
        }
        .onAppear { Analytics.screen("Onboarding") }
    }
}
