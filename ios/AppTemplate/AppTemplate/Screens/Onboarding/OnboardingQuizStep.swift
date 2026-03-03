import SwiftUI

// MARK: - OnboardingQuizStep
// Renders one question step based on its type.

struct OnboardingQuizStep: View {
    let question: OnboardingQuestion
    @Binding var textInput: String
    @Binding var selectedChoice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(question.headline)
                    .font(.display(26))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let sub = question.subheadline {
                    Text(sub)
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // Step content
            switch question.type {
            case .textInput(let placeholder):
                AppTextField(placeholder, text: $textInput)

            case .multipleChoice(let options):
                VStack(spacing: Spacing.sm) {
                    ForEach(options, id: \.self) { option in
                        ChoiceRow(
                            label: option,
                            isSelected: selectedChoice == option
                        ) {
                            HapticManager.selection()
                            selectedChoice = option
                        }
                    }
                }

            case .infoScreen(let bullets):
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.success)
                                .font(.system(size: 20))
                            Text(bullet)
                                .font(.body(16))
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                }

            case .notificationSetup:
                NotificationSetupStep()
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl)
    }
}

// MARK: - ChoiceRow

private struct ChoiceRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.body(16, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .strokeBorder(Color.border, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(Spacing.lg)
            .background(isSelected ? Color.accentMuted : Color.bgSurface)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.accent : Color.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

// MARK: - NotificationSetupStep

private struct NotificationSetupStep: View {
    @State private var requested = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Color.accent)

            VStack(spacing: Spacing.xs) {
                Text("Stay on track")
                    .font(.display(20))
                    .foregroundStyle(Color.textPrimary)
                Text("Enable reminders so you never miss a session.")
                    .font(.body(15))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if !requested {
                AppButton("Enable Reminders", style: .primary, icon: "bell.fill") {
                    Task {
                        await NotificationManager.shared.requestPermission()
                        requested = true
                    }
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                    Text("Reminders enabled")
                        .font(.body(15, weight: .semibold))
                        .foregroundStyle(Color.success)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .multilineTextAlignment(.center)
    }
}
