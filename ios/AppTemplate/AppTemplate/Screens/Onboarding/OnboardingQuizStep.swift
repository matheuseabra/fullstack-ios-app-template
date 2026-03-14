import SwiftUI

// MARK: - OnboardingQuizStep
// Renders one question step based on its type.

struct OnboardingQuizStep: View {
    let question: OnboardingQuestion
    @Binding var textInput: String
    @Binding var selectedChoice: String?
    var onChoiceSelected: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        defaultStepContent
    }

    // MARK: - Default Step Content

    private var defaultStepContent: some View {
        let isCenteredHeader = question.key == "solution" || question.key == "notifications"
        let illustrationName: String? = {
            switch question.key {
            case "solution": return "reading"
            case "notifications": return "reminders"
            default: return nil
            }
        }()

        return VStack(alignment: isCenteredHeader ? .center : .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: isCenteredHeader ? .center : .leading, spacing: Spacing.xs) {
                if let illustrationName {
                    Image(illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)
                        .padding(.bottom, Spacing.xs)
                }

                Text(question.headline)
                    .font(.display(question.type.headlineSize, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(isCenteredHeader ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: isCenteredHeader ? .center : .leading)

                if let sub = question.subheadline {
                    Text(sub)
                        .font(.body(17))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(isCenteredHeader ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: isCenteredHeader ? .center : .leading)
                }
            }

            // Step content
            switch question.type {
            case .textInput(let placeholder):
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    TextField(placeholder, text: $textInput)
                        .font(.display(24, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.vertical, Spacing.md)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(
                                    textInput.isEmpty ? Color.border : Color.accent
                                )
                                .animation(.snappy, value: textInput.isEmpty)
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

            }

            case .multipleChoice(let options):
                VStack(spacing: Spacing.sm) {
                    ForEach(options) { option in
                        OptionCard(
                            option: option,
                            isSelected: selectedChoice == option.id
                        ) {
                            HapticManager.selection()
                            selectedChoice = option.id
                            onChoiceSelected?()
                        }
                    }
                }

            case .infoScreen(let bullets):
                VStack(alignment: isCenteredHeader ? .center : .leading, spacing: Spacing.lg) {
                    VStack(alignment: isCenteredHeader ? .center : .leading, spacing: Spacing.md) {
                        ForEach(bullets) { bullet in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: bullet.icon)
                                    .foregroundStyle(Color.accent)
                                    .font(.system(size: 20))
                                Text(bullet.text)
                                    .font(.body(16))
                                    .foregroundStyle(Color.textPrimary)
                                    .multilineTextAlignment(isCenteredHeader ? .center : .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: isCenteredHeader ? .center : .leading)
                        }
                    }
                    
                    // Testimonial card
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.accent)
                                .font(.system(size: 14))
                            Text("4.8")
                                .font(.body(14, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text("• 2.3K reviews")
                                .font(.body(14))
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        Text("\"This app actually helped me stay focused. Finally, something that works!\"")
                            .font(.body(15))
                            .foregroundStyle(Color.textPrimary)
                            .lineSpacing(1.5)
                        
                        Text("Sarah M.")
                            .font(.body(14, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.lg)
                    .background(Color.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.border.opacity(0.5), lineWidth: 1)
                    )
                }

            case .notificationSetup:
                NotificationSetupStep()

            case .welcomeHero:
                EmptyView()
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxl)
    }
}

// MARK: - OptionCard
// Matches the Stitch "Onboarding Goal Quiz" card design:
// icon in a tinted rounded square + title + optional subtitle,
// full-card border highlight when selected, subtle shadow at rest.

private struct OptionCard: View {
    let option: ChoiceOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                if let icon = option.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(option.iconColor.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(option.iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.body(16, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accent : Color.textPrimary)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.body(13))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(isSelected ? Color.accent : Color.border, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0 : 0.04), radius: 6, y: 2)
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
