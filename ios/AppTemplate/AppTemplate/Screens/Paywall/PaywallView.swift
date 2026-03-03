import SwiftUI
import RevenueCatUI
import RevenueCat

// MARK: - PaywallView
// Wraps RevenueCat's native PaywallView (configured in RC dashboard).
// Advances to Home on successful purchase or restore.

struct PaywallView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        RevenueCatUI.PaywallView()
            .onPurchaseCompleted { _ in
                HapticManager.success()
                router.advanceToHome()
            }
            .onRestoreCompleted { _ in
                HapticManager.success()
                router.advanceToHome()
            }
            .onAppear { Analytics.track(.paywallViewed(screen: 2)) }
    }
}

// MARK: - Legacy PlanCard (kept for reference)

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
