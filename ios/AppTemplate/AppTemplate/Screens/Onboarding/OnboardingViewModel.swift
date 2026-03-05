import SwiftUI

// MARK: - ChoiceOption

struct ChoiceOption: Identifiable {
    let id: String
    let label: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color

    init(
        label: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accent
    ) {
        self.id = label
        self.label = label
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }
}

// MARK: - Question Model

struct OnboardingQuestion {
    let key: String
    let headline: String
    let subheadline: String?
    let type: QuestionType

    init(key: String, headline: String, subheadline: String? = nil, type: QuestionType) {
        self.key = key
        self.headline = headline
        self.subheadline = subheadline
        self.type = type
    }

    enum QuestionType {
        case textInput(placeholder: String = "Type here…")
        case multipleChoice(options: [ChoiceOption])
        case infoScreen(bullets: [String])
        case notificationSetup

        /// Headline size matched to Stitch design: name quiz = 34pt, others = 28pt.
        var headlineSize: CGFloat {
            switch self {
            case .textInput: return 34
            default: return 28
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var responses: [String: AnyCodable] = [:]
    @Published var textInput = ""
    @Published var selectedChoice: String? = nil
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Configure questions per app
    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            key: "name",
            headline: "What is your name?",
            subheadline: "This helps us personalize your experience and results.",
            type: .textInput(placeholder: "Enter your name")
        ),
        OnboardingQuestion(
            key: "primary_goal",
            headline: "What is your main goal?",
            subheadline: "Select the option that best describes what you want to achieve.",
            type: .multipleChoice(options: [
                ChoiceOption(label: "Build Muscle",    subtitle: "Increase strength and mass",  icon: "figure.strengthtraining.traditional", iconColor: .accent),
                ChoiceOption(label: "Lose Weight",     subtitle: "Burn fat and stay lean",       icon: "flame.fill",   iconColor: .orange),
                ChoiceOption(label: "Improve Health",  subtitle: "Feel better every day",        icon: "leaf.fill",    iconColor: .green),
                ChoiceOption(label: "Stay Active",     subtitle: "Build a daily habit",          icon: "figure.run",   iconColor: .blue),
            ])
        ),
        OnboardingQuestion(
            key: "commitment",
            headline: "How much time can you commit daily?",
            type: .multipleChoice(options: [
                ChoiceOption(label: "5 min",  subtitle: "A quick daily habit",         icon: "bolt.fill",          iconColor: .yellow),
                ChoiceOption(label: "10 min", subtitle: "Steady and consistent",       icon: "clock.fill",         iconColor: .accent),
                ChoiceOption(label: "20 min", subtitle: "Solid progress, fast results",icon: "chart.line.uptrend.xyaxis", iconColor: .green),
                ChoiceOption(label: "30+ min",subtitle: "Maximum gains",               icon: "trophy.fill",        iconColor: .orange),
            ])
        ),
        OnboardingQuestion(
            key: "solution",
            headline: "Here's how we get you there",
            type: .infoScreen(bullets: [
                "Personalized to your goals",
                "Takes less than 10 minutes daily",
                "See results in 7 days"
            ])
        ),
        OnboardingQuestion(
            key: "notifications",
            headline: "Set your daily reminder",
            subheadline: "We'll only send reminders you've set.",
            type: .notificationSetup
        ),
    ]

    /// Questions filtered by active feature flags (e.g. removes notification
    /// setup step when notifications are disabled).
    lazy var activeQuestions: [OnboardingQuestion] = {
        questions.filter { q in
            switch q.type {
            case .notificationSetup:
                return AppEnvironment.enableNotifications
            default:
                return true
            }
        }
    }()

    var isLastStep: Bool { currentStep >= activeQuestions.count - 1 }
    var progress: Double { Double(currentStep) / Double(activeQuestions.count) }
    var currentQuestion: OnboardingQuestion { activeQuestions[currentStep] }

    // MARK: - Navigation

    func advance() {
        guard !isSaving else { return }
        Analytics.track(.onboardingStepCompleted(step: currentStep, key: currentQuestion.key))
        captureCurrentAnswer()
        HapticManager.selection()

        if isLastStep {
            Task { await finish() }
        } else {
            withAnimation(.spring) {
                currentStep += 1
                textInput = ""
                selectedChoice = nil
            }
        }
    }

    func canAdvance() -> Bool {
        switch currentQuestion.type {
        case .textInput:
            return !textInput.trimmingCharacters(in: .whitespaces).isEmpty
        case .multipleChoice:
            return selectedChoice != nil
        case .infoScreen, .notificationSetup:
            return true
        }
    }

    // MARK: - Private

    private func captureCurrentAnswer() {
        let key = currentQuestion.key
        switch currentQuestion.type {
        case .textInput:
            let val = textInput.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty { responses[key] = AnyCodable(val) }
        case .multipleChoice:
            if let choice = selectedChoice { responses[key] = AnyCodable(choice) }
        case .infoScreen, .notificationSetup:
            break
        }
    }

    private func finish() async {
        isSaving = true
        defer { isSaving = false }

#if DEBUG
    // MOCK (Debug only): Skip the API call on local/dev builds so onboarding
    // is never blocked by network/DB issues on either simulator or device.
    // Production behavior is preserved in the #else branch below.
    // TODO: Remove this block once end-to-end backend integration is stable.
        try? await Task.sleep(for: .milliseconds(400)) // simulate brief network feel
        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
        Analytics.track(.onboardingCompleted)
        AppRouter.shared.advanceToPaywall()
#else
        let apiResponses = responses.map {
            OnboardingResponse(questionKey: $0.key, answer: $0.value)
        }

        do {
            let _: SubmitOnboardingResponse = try await APIClient.shared.post(
                APIEndpoints.onboardingResponses,
                body: SubmitOnboardingRequest(responses: apiResponses)
            )
            UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
            Analytics.track(.onboardingCompleted)
            AppRouter.shared.advanceToPaywall()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
#endif
    }
}
