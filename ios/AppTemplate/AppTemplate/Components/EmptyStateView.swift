import SwiftUI

// MARK: - EmptyStateView
// Usage: EmptyStateView(icon: "tray", title: "Nothing here", subtitle: "Start by adding something.")
//        EmptyStateView(icon: "wifi.slash", title: "Offline", subtitle: "...", action: ("Retry", { vm.reload() }))

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (label: String, handler: () -> Void)?
    let illustrationAsset: String?

    init(
        icon: String,
        title: String,
        subtitle: String,
        action: (label: String, handler: () -> Void)? = nil,
        illustrationAsset: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.illustrationAsset = illustrationAsset
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if let illustrationAsset {
                Image(illustrationAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .padding(.bottom, Spacing.xs)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.display(20))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.body(17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                AppButton(action.label, style: .ghost, action: action.handler)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "tray",
        title: "Nothing here yet",
        subtitle: "Start by adding your first item.",
        action: ("Get Started", {})
    )
    .background(Color.bg)
}
