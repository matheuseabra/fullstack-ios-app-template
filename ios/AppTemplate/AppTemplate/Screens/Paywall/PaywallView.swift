import SwiftUI
import RevenueCat

// MARK: - PaywallView
// Screen 2 — Custom pricing plans matching "Paywall Pricing Plans" Stitch design.
// Replaces RevenueCat's native PaywallView with a fully custom UI while
// keeping the RevenueCat SDK for purchase / restore logic.

struct PaywallView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = PaywallViewModel()

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        Analytics.track(.paywallDismissed)
                        router.advanceToHome()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: Hero Icon
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.accent)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.accent.opacity(0.25), radius: 12, y: 6)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(.white)
                            )
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, Spacing.xl)

                        // MARK: Title
                        VStack(spacing: Spacing.sm) {
                            Text("Unlock Full Access")
                                .font(.display(30))
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("Join 10,000+ members getting more done\nevery day with premium features.")
                                .font(.body(15))
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, Spacing.xxl + Spacing.sm)

                        // MARK: Plan Cards
                        VStack(spacing: Spacing.lg) {
                            // Yearly Plan
                            PlanCard(
                                title: "Yearly",
                                subtitle: yearlySubtitle,
                                priceLabel: yearlyPricePerMonth,
                                pricePeriod: "per month",
                                badge: "Best Value",
                                isSelected: vm.selectedPlan == .yearly
                            ) {
                                HapticManager.selection()
                                vm.selectedPlan = .yearly
                            }

                            // Monthly Plan
                            PlanCard(
                                title: "Monthly",
                                subtitle: monthlySubtitle,
                                priceLabel: monthlyPrice,
                                pricePeriod: "per month",
                                badge: nil,
                                isSelected: vm.selectedPlan == .monthly
                            ) {
                                HapticManager.selection()
                                vm.selectedPlan = .monthly
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)

                        // MARK: Features List
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            FeatureRow(text: "Unlimited projects and cloud storage")
                            FeatureRow(text: "Advanced AI-powered organization")
                            FeatureRow(text: "Priority 24/7 customer support")
                        }
                        .padding(.horizontal, Spacing.xl + Spacing.sm)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .padding(.bottom, 200) // space for pinned CTA
                }

                // MARK: Pinned CTA Area
                VStack(spacing: Spacing.lg) {
                    // Subscribe button
                    Button {
                        HapticManager.medium()
                        Task { await vm.purchase() }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Start 7-Day Free Trial")
                                    .font(.body(18, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        .shadow(color: Color.accent.opacity(0.3), radius: 16, y: 8)
                    }
                    .disabled(vm.isLoading)
                    .opacity(vm.isLoading ? 0.75 : 1)
                    .animation(.snappy, value: vm.isLoading)

                    // Legal text
                    Text("By subscribing, you agree to our [Terms of Service](https://example.com/terms) and [Privacy Policy](https://example.com/privacy). Subscription automatically renews unless turned off.")
                        .font(.body(11))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .tint(Color.textSecondary)

                    // Footer actions
                    HStack(spacing: Spacing.xl) {
                        Button {
                            Task { await vm.restorePurchases() }
                        } label: {
                            Text("Restore Purchase")
                                .font(.body(12, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                        }

                        Circle()
                            .fill(Color.border)
                            .frame(width: 4, height: 4)

                        Button {
                            Analytics.track(.paywallDismissed)
                            router.advanceToHome()
                        } label: {
                            Text("Not Now")
                                .font(.body(12, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                        }
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
        .task { await vm.loadOfferings() }
        .onAppear { Analytics.track(.paywallViewed(screen: 2)) }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "Something went wrong.")
        }
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
                        .foregroundStyle(.white)
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
                .font(.body(14, weight: .medium))
                .foregroundStyle(Color.textPrimary)
        }
    }
}
