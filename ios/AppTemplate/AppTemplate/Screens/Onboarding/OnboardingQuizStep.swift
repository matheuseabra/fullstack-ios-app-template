import SwiftUI

// MARK: - OnboardingQuizStep
// Renders one question step based on its type.

struct OnboardingQuizStep: View {
    let question: OnboardingQuestion
    @Binding var textInput: String
    @Binding var selectedChoice: String?
    var onChoiceSelected: (() -> Void)? = nil

    var body: some View {
        switch question.type {
        case .welcomeHero:
            welcomeHeroContent
        default:
            defaultStepContent
        }
    }

    // MARK: - Welcome Hero (Screen 0)

    private var welcomeHeroContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                // App logo — only on welcome screen
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                VStack(spacing: Spacing.lg) {
                    Text(question.headline)
                        .font(.display(question.type.headlineSize))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let sub = question.subheadline {
                        Text(sub)
                            .font(.body(17))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Default Step Content

    private var defaultStepContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(question.headline)
                    .font(.display(question.type.headlineSize))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if case .textInput = question.type {
                    // helper text rendered inside the textInput case below
                } else if let sub = question.subheadline {
                    Text(sub)
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
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

                    if let helper = question.subheadline {
                        Text(helper)
                            .font(.body(14))
                            .foregroundStyle(Color.textSecondary)
                    }
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
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Color.accent)

            VStack(spacing: Spacing.xs) {
                Text("Stay on track")
                    .font(.display(20))
                    .foregroundStyle(Color.textPrimary)
                Text("Enable reminders so you never miss a task.")
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
