import SwiftUI

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
        case multipleChoice(options: [String])
        case infoScreen(bullets: [String])
        case notificationSetup
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
            headline: "What should we call you?",
            subheadline: "You can always change this later.",
            type: .textInput(placeholder: "Your first name")
        ),
        OnboardingQuestion(
            key: "primary_goal",
            headline: "What's your main goal?",
            type: .multipleChoice(options: ["Option A", "Option B", "Option C", "Option D"])
        ),
        OnboardingQuestion(
            key: "commitment",
            headline: "How much time can you commit daily?",
            type: .multipleChoice(options: ["5 min", "10 min", "20 min", "30+ min"])
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

    var isLastStep: Bool { currentStep >= questions.count - 1 }
    var progress: Double { Double(currentStep) / Double(questions.count) }
    var currentQuestion: OnboardingQuestion { questions[currentStep] }

    // MARK: - Navigation

    func advance() {
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
    }
}
