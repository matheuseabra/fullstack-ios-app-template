import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = PaywallViewModel()

    private let features = [
        "Feature one — describe key benefit",
        "Feature two — describe key benefit",
        "Feature three — describe key benefit",
        "Feature four — describe key benefit",
    ]

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.sm) {
                            Text("Everything you need to")
                                .font(.display(22))
                                .foregroundStyle(Color.textPrimary)
                            Text("achieve your goal")
                                .font(.display(22))
                                .foregroundStyle(Color.accent)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xxl)

                        // Feature list
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            ForEach(features, id: \.self) { feature in
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.accent)
                                        .frame(width: 20)
                                    Text(feature)
                                        .font(.body(15))
                                        .foregroundStyle(Color.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)

                        // Plan cards
                        VStack(spacing: Spacing.sm) {
                            PlanCard(
                                title: "Yearly",
                                badge: "BEST VALUE",
                                price: "$29.99 / year",
                                subtitle: "= $2.49 / month",
                                isSelected: vm.selectedPlan == .yearly
                            ) { vm.selectPlan(.yearly) }

                            PlanCard(
                                title: "Monthly",
                                badge: nil,
                                price: "$7.99 / month",
                                subtitle: nil,
                                isSelected: vm.selectedPlan == .monthly
                            ) { vm.selectPlan(.monthly) }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, 200)
                }

                // Bottom CTAs
                VStack(spacing: Spacing.sm) {
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.body(13))
                            .foregroundStyle(Color.danger)
                            .multilineTextAlignment(.center)
                    }

                    AppButton("Start Free Trial", style: .primary, isLoading: vm.isLoading) {
                        Task { await vm.purchase() }
                    }
                    Button("Restore Purchases") {
                        Task { await vm.restorePurchases() }
                    }
                    .font(.body(13))
                    .foregroundStyle(Color.textSecondary)

                    // Legal
                    HStack(spacing: 4) {
                        Link("Terms", destination: URL(string: "https://yourapp.com/terms")!)
                        Text("·")
                        Link("Privacy", destination: URL(string: "https://yourapp.com/privacy")!)
                    }
                    .font(.body(11))
                    .foregroundStyle(Color.textTertiary)
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
        .onAppear { Analytics.track(.paywallViewed(screen: 2)) }
    }
}

// MARK: - PlanCard

private struct PlanCard: View {
    let title: String
    let badge: String?
    let price: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(title)
                            .font(.body(16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.body(10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accent)
                                .cornerRadius(Radius.sm)
                        }
                    }
                    Text(price)
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.body(13))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accent : Color.border, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(isSelected ? Color.accentMuted : Color.bgSurface)
            .cornerRadius(Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(isSelected ? Color.accent : Color.border, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}
