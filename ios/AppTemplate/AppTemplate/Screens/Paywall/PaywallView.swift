import SwiftUI
import RevenueCat

// MARK: - PaywallView
// Single-screen premium paywall matching the latest Stitch export.

struct PaywallView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = PaywallViewModel()
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            dismissPaywall(trackDismissed: true)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .frame(width: 34, height: 34)
                                .background(Color.bgSurface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.xxl) {
                            VStack(spacing: Spacing.sm) {
                                Text("Unlock Premium")
                                    .font(.display(32, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Text("Master your productivity with unlimited tasks and advanced insights.")
                                    .font(.body(15))
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, Spacing.md)

                            timelineCard

                            VStack(spacing: Spacing.md) {
                                PlanCard(
                                    title: "Yearly Plan",
                                    subtitle: yearlySubtitle,
                                    priceLabel: yearlyPricePerMonth,
                                    pricePeriod: "per month",
                                    badge: "Best Value",
                                    isSelected: vm.selectedPlan == .yearly
                                ) {
                                    HapticManager.selection()
                                    vm.selectedPlan = .yearly
                                    Analytics.track(.planSelected(plan: PaywallViewModel.Plan.yearly.rawValue))
                                }

                                PlanCard(
                                    title: "Monthly Plan",
                                    subtitle: monthlySubtitle,
                                    priceLabel: monthlyPrice,
                                    pricePeriod: "per month",
                                    badge: nil,
                                    isSelected: vm.selectedPlan == .monthly
                                ) {
                                    HapticManager.selection()
                                    vm.selectedPlan = .monthly
                                    Analytics.track(.planSelected(plan: PaywallViewModel.Plan.monthly.rawValue))
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                                FeatureRow(text: "Cloud Sync")
                                FeatureRow(text: "Unlimited Tasks")
                                FeatureRow(text: "Priority Support")
                                FeatureRow(text: "Custom Themes")
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, 220)
                    }

                    VStack(spacing: Spacing.md) {
                        Button {
                            HapticManager.medium()
                            Analytics.track(.trialStarted)
                            Task {
                                if await vm.purchase() {
                                    dismissPaywall()
                                }
                            }
                        } label: {
                            Group {
                                if vm.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(Color.bg)
                                } else {
                                    Text("Start Free Trial")
                                        .font(.body(20, weight: .bold))
                                }
                            }
                            .foregroundStyle(Color.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading)

                        Text("By starting your trial, you agree to our Terms of Service and Privacy Policy. Subscription renews automatically.")
                            .font(.body(11))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: Spacing.xl) {
                            Button("Restore Purchase") {
                                Task {
                                    if await vm.restorePurchases() {
                                        dismissPaywall()
                                    }
                                }
                            }
                            .font(.body(12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)

                            Circle()
                                .fill(Color.border)
                                .frame(width: 4, height: 4)

                            Button("Not Now") {
                                dismissPaywall(trackDismissed: true)
                            }
                            .font(.body(12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
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
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .task { await vm.loadOfferings() }
        .onAppear { Analytics.screen("Paywall") }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "Something went wrong.")
        }
    }

    private func dismissPaywall(trackDismissed: Bool = false) {
        if trackDismissed {
            Analytics.track(.paywallDismissed)
        }

        if let onDismiss {
            onDismiss()
        } else {
            router.advanceToHome()
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            PaywallTimelineRow(icon: "lock.open.fill", title: "Today: Trial starts", subtitle: "Get 7 days of full access for free.", accent: true)
            PaywallTimelineRow(icon: "bell.fill", title: "Day 5: Reminder", subtitle: "We’ll let you know your trial is about to end.", accent: false)
            PaywallTimelineRow(icon: "creditcard.fill", title: "Day 7: First charge", subtitle: "Subscription begins unless you cancel first.", accent: false)
        }
        .padding(Spacing.xl)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .stroke(Color.border.opacity(0.75), lineWidth: 1)
        )
    }

    // MARK: - Price Helpers

    private var yearlySubtitle: String {
        if let pkg = vm.yearlyPackage {
            return "7-day free trial, then \(pkg.storeProduct.localizedPriceString)/year"
        }
        return "7-day free trial, then $29.99/year"
    }

    private var yearlyPricePerMonth: String {
        if let pkg = vm.yearlyPackage {
            let monthly = NSDecimalNumber(decimal: pkg.storeProduct.price)
                .dividing(by: 12)
            let fmt = NumberFormatter()
            fmt.numberStyle = .currency
            fmt.locale = pkg.storeProduct.priceFormatter?.locale ?? .current
            return fmt.string(from: monthly) ?? "$2.49"
        }
        return "$2.49"
    }

    private var monthlySubtitle: String {
        "Billed monthly"
    }

    private var monthlyPrice: String {
        if let pkg = vm.monthlyPackage {
            return pkg.storeProduct.localizedPriceString
        }
        return "$4.99"
    }
}

private struct PaywallTimelineRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(accent ? Color.accent : Color.bgSurface)
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent ? Color.bg : Color.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.body(12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - PlanCard
// Selected / deselected plan card matching the Stitch pricing layout.

private struct PlanCard: View {
    let title: String
    let subtitle: String
    let priceLabel: String
    let pricePeriod: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Radio button
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accent : Color.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body(18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.body(13))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.leading, Spacing.sm)

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceLabel)
                        .font(.body(18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(pricePeriod)
                        .font(.body(10, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)
                }
            }
            .padding(Spacing.xl)
            .background(isSelected ? Color.bgElevated : Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(isSelected ? Color.accent : Color.border, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.body(10, weight: .bold))
                        .foregroundStyle(Color.bg)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 5)
                        .background(Color.accent)
                        .clipShape(Capsule())
                        .shadow(color: Color.accent.opacity(0.3), radius: 4, y: 2)
                        .offset(x: -Spacing.xl, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accent)
            Text(text)
                .font(.body(13, weight: .medium))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}
