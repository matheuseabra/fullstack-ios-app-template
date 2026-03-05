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
        case welcomeHero
        case textInput(placeholder: String = "Type here…")
        case multipleChoice(options: [ChoiceOption])
        case infoScreen(bullets: [String])
        case notificationSetup

        var headlineSize: CGFloat {
            switch self {
            case .welcomeHero: return 32
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

    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            key: "welcome",
            headline: "Get more done\nwith less stress",
            subheadline: "Your personal task manager that helps you stay focused and organized.",
            type: .welcomeHero
        ),
        OnboardingQuestion(
            key: "name",
            headline: "What should we call you?",
            subheadline: "We'll use this to personalize your experience.",
            type: .textInput(placeholder: "Enter your name")
        ),
        OnboardingQuestion(
            key: "usage_context",
            headline: "How will you use this app?",
            type: .multipleChoice(options: [
                ChoiceOption(label: "Personal",           subtitle: "Errands, habits, and daily life",       icon: "house.fill",            iconColor: .accent),
                ChoiceOption(label: "Work",               subtitle: "Projects, meetings, and deadlines",     icon: "briefcase.fill",        iconColor: .orange),
                ChoiceOption(label: "School",             subtitle: "Assignments, exams, and study plans",   icon: "book.fill",             iconColor: .green),
                ChoiceOption(label: "A bit of everything", subtitle: "All of the above",                     icon: "square.grid.2x2.fill",  iconColor: .blue),
            ])
        ),
        OnboardingQuestion(
            key: "biggest_challenge",
            headline: "What's your biggest challenge?",
            subheadline: "We'll tailor your experience to help with this.",
            type: .multipleChoice(options: [
                ChoiceOption(label: "Staying organized",    subtitle: "Too many things to track",              icon: "tray.full.fill",                     iconColor: .accent),
                ChoiceOption(label: "Prioritizing tasks",   subtitle: "Not sure what to do first",             icon: "arrow.up.arrow.down",                iconColor: .orange),
                ChoiceOption(label: "Meeting deadlines",    subtitle: "Things slip through the cracks",        icon: "clock.badge.exclamationmark.fill",   iconColor: .red),
                ChoiceOption(label: "Building consistency", subtitle: "I start strong but lose momentum",      icon: "chart.line.downtrend.xyaxis",        iconColor: .green),
            ])
        ),
        OnboardingQuestion(
            key: "task_volume",
            headline: "How many tasks do you juggle daily?",
            type: .multipleChoice(options: [
                ChoiceOption(label: "1–3 tasks",  subtitle: "I keep it simple",        icon: "leaf.fill",                    iconColor: .green),
                ChoiceOption(label: "4–7 tasks",  subtitle: "A manageable amount",     icon: "checklist",                    iconColor: .accent),
                ChoiceOption(label: "8–15 tasks", subtitle: "I stay busy",             icon: "list.bullet.rectangle.fill",   iconColor: .orange),
                ChoiceOption(label: "15+ tasks",  subtitle: "I'm always on the go",    icon: "bolt.fill",                    iconColor: .red),
            ])
        ),
        OnboardingQuestion(
            key: "solution",
            headline: "Here's how we'll help",
            type: .infoScreen(bullets: [
                "Personalized to how you work",
                "Smart reminders so nothing slips",
                "Track your progress and build momentum"
            ])
        ),
        OnboardingQuestion(
            key: "notifications",
            headline: "Never miss a task",
            subheadline: "We'll only remind you about what matters.",
            type: .notificationSetup
        ),
    ]

    var isLastStep: Bool { currentStep >= questions.count - 1 }
    var progress: Double { Double(currentStep) / Double(questions.count) }
    var currentQuestion: OnboardingQuestion { questions[currentStep] }

    /// Whether the circular FAB should be visible on the current step.
    var showsFAB: Bool {
        switch currentQuestion.type {
        case .welcomeHero, .multipleChoice:
            return false
        case .textInput, .infoScreen, .notificationSetup:
            return true
        }
    }

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

    func goBack() {
        guard currentStep > 0 else { return }
        withAnimation(.spring) {
            currentStep -= 1
            // Restore previous answer if any
            let prevQuestion = questions[currentStep]
            switch prevQuestion.type {
            case .textInput:
                textInput = (responses[prevQuestion.key]?.value as? String) ?? ""
                selectedChoice = nil
            case .multipleChoice:
                selectedChoice = responses[prevQuestion.key]?.value as? String
                textInput = ""
            default:
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
        case .welcomeHero, .infoScreen, .notificationSetup:
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
        case .welcomeHero, .infoScreen, .notificationSetup:
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
