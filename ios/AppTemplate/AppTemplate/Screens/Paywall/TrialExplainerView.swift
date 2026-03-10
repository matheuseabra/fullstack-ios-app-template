import SwiftUI

// MARK: - TrialExplainerView
// Screen 1 of the paywall flow — matches "Paywall Trial Screen" Stitch design.
// Hero icon + title → benefits list → vertical timeline → CTA + legal footer.

struct TrialExplainerView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // No close button: hard paywall enforced
                HStack { Spacer() }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: Hero Section
                        VStack(spacing: Spacing.lg) {
                            // App icon with glow
                            ZStack {
                                Circle()
                                    .fill(Color.accent.opacity(0.25))
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 30)

                                RoundedRectangle(cornerRadius: 26)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.accent.opacity(0.85),
                                                Color.accent
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)
                                    .shadow(color: Color.accent.opacity(0.4), radius: 20, y: 10)
                                    .overlay(
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 36, weight: .medium))
                                            .foregroundStyle(Color.bg)
                                    )
                            }
                            .padding(.bottom, Spacing.md)

                            Text("Start your 7-day\nfree trial")
                                .font(.display(28, weight: .heavy))
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, Spacing.xxl)

                        // MARK: Benefits List
                        VStack(spacing: Spacing.xl) {
                            BenefitRow(text: "Unlock all premium features")
                            BenefitRow(text: "Ad-free creative experience")
                            BenefitRow(text: "Unlimited cloud sync")
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)

                        // MARK: Timeline Card
                        VStack(alignment: .leading, spacing: 0) {
                            // Step 1
                            HStack(alignment: .top, spacing: Spacing.lg) {
                                // Node + connector
                                VStack(spacing: 0) {
                                    TimelineNodeCircle(icon: "star.fill")
                                    Rectangle()
                                        .fill(Color.accent)
                                        .frame(width: 3, height: 40)
                                }
                                .frame(width: 26)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Today: Trial Starts")
                                        .font(.body(15, weight: .bold))
                                        .foregroundStyle(Color.textPrimary)
                                    Text("Unlock full access instantly")
                                        .font(.body(13))
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .padding(.top, 2)
                            }

                            // Step 2
                            HStack(alignment: .top, spacing: Spacing.lg) {
                                TimelineNodeCircle(icon: "bell.fill")
                                    .frame(width: 26)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Day 5: Reminder")
                                        .font(.body(15, weight: .bold))
                                        .foregroundStyle(Color.textPrimary)
                                    Text("We'll notify you trial is ending")
                                        .font(.body(13))
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(Spacing.xl)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .padding(.bottom, 200) // space for pinned CTA
                }

                // MARK: Pinned CTA Area
                VStack(spacing: Spacing.lg) {
                    // Primary CTA
                    NavigationLink {
                        PaywallView()
                            .navigationBarBackButtonHidden()
                    } label: {
                        Text("Try Free & Subscribe")
                            .font(.body(17, weight: .bold))
                            .foregroundStyle(Color.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.accent.opacity(0.85),
                                        Color.accent
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.accent.opacity(0.35), radius: 16, y: 8)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.medium()
                    })

                    // Disclaimer
                    Text("Then $39.99/year. Cancel anytime in Settings\nat least 24 hours before the trial ends.")
                        .font(.body(12))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)

                    // Footer links
                    HStack {
                        FooterLink("Restore Purchase") {
                            Task {
                                try? await PaymentManager.shared.restorePurchases()
                                if PaymentManager.shared.hasProAccess {
                                    HapticManager.success()
                                    router.advanceToHome()
                                }
                            }
                        }
                        Spacer()
                        FooterLink("Terms of Use") {}
                        Spacer()
                        FooterLink("Privacy Policy") {}
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
                .background(
                    LinearGradient(
                        colors: [Color.bg.opacity(0), Color.bg, Color.bg],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear { Analytics.screen("TrialExplainer") }
    }
}

// MARK: - Benefit Row
// Purple circle with checkmark + label — matches Stitch benefits list.

private struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.accentMuted)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accent)
            }
            Text(text)
                .font(.body(17, weight: .medium))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Timeline Node Circle

private struct TimelineNodeCircle: View {
    let icon: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accent)
                .frame(width: 26, height: 26)
                .shadow(color: Color.accent.opacity(0.3), radius: 4, y: 2)
                .overlay(
                    Circle()
                        .stroke(Color.bg.opacity(0.5), lineWidth: 3)
                )
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.bg)
        }
    }
}

// MARK: - Footer Link

private struct FooterLink: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body(10, weight: .bold))
                .foregroundStyle(Color.textSecondary.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}
