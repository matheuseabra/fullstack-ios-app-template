import SwiftUI

struct TrialExplainerView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Headline
                        VStack(spacing: Spacing.sm) {
                            Text("🎉")
                                .font(.system(size: 56))
                            Text("Start Free Today")
                                .font(.display(28))
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Full access for 7 days — no charge until Day 8.")
                                .font(.body(16))
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Spacing.xxl)

                        // Timeline
                        TrialTimeline()

                        // Trust bullets
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            TrustBullet(icon: "checkmark.circle.fill", text: "Full access starts immediately")
                            TrustBullet(icon: "bell.fill", text: "Reminder sent before you're charged")
                            TrustBullet(icon: "xmark.circle.fill", text: "Cancel anytime — no questions asked")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, 160)
                }

                // CTAs pinned at bottom
                VStack(spacing: Spacing.sm) {
                    NavigationLink {
                        PaywallView()
                            .navigationBarBackButtonHidden()
                    } label: {
                        AppButton("Start My Free Trial") {
                            Analytics.track(.trialStarted)
                            HapticManager.medium()
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.track(.trialStarted)
                        HapticManager.medium()
                    })

                    AppButton("No thanks", style: .ghost) {
                        Analytics.track(.paywallDismissed)
                        router.advanceToHome()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
                .background(
                    LinearGradient(
                        colors: [Color.bg.opacity(0), Color.bg],
                        startPoint: .top, endPoint: .center
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear { Analytics.track(.paywallViewed(screen: 1)) }
    }
}

// MARK: - Trial Timeline

private struct TrialTimeline: View {
    var body: some View {
        HStack(spacing: 0) {
            TimelineNode(label: "Today", sublabel: "Free", color: .accent)
            TimelineLine()
            TimelineNode(label: "Day 7", sublabel: "Still Free", color: .accent)
            TimelineLine()
            TimelineNode(label: "Day 8+", sublabel: "Only if you stay", color: .textTertiary)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

private struct TimelineNode: View {
    let label: String
    let sublabel: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.body(13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text(sublabel)
                .font(.body(11))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

private struct TimelineLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.border)
            .frame(height: 1.5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 36)
    }
}

// MARK: - Trust Bullet

private struct TrustBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.success)
                .frame(width: 24)
            Text(text)
                .font(.body(15))
                .foregroundStyle(Color.textPrimary)
        }
    }
}
