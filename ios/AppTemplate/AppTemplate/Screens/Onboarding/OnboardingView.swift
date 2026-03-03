import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: vm.progress)
                    .tint(Color.accent)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .animation(.spring, value: vm.currentStep)

                // Step content
                TabView(selection: $vm.currentStep) {
                    ForEach(vm.questions.indices, id: \.self) { index in
                        OnboardingQuizStep(
                            question: vm.questions[index],
                            textInput: $vm.textInput,
                            selectedChoice: $vm.selectedChoice
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
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 96)
            }

            // Circular FAB next / finish button
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
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: vm.isLastStep ? "checkmark" : "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(!vm.canAdvance() || vm.isSaving)
            .opacity(!vm.canAdvance() ? 0.5 : 1)
            .animation(.snappy, value: vm.canAdvance())
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .onAppear { Analytics.track(.onboardingStarted) }
    }
}
