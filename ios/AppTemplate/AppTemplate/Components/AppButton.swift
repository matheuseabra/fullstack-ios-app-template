import SwiftUI

// MARK: - AppButton
// Usage: AppButton("Continue", style: .primary) { ... }
//        AppButton("Cancel", style: .ghost) { ... }
//        AppButton("Delete", style: .destructive, isLoading: vm.isLoading) { ... }

struct AppButton: View {
    let title: String
    let style: Style
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    enum Style {
        case primary, ghost, destructive
    }

    var body: some View {
        Button(action: { if !isLoading { action() } }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(tintColor)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body(16, weight: .semibold))
                    }
                    Text(title)
                        .font(.body(17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(tintColor)
            .background(backgroundColor)
            .cornerRadius(Radius.lg)
            .overlay(
                style == .ghost
                    ? RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.border, lineWidth: 1.5)
                    : nil
            )
            .opacity(isLoading ? 0.75 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .accent
        case .ghost:       return .clear
        case .destructive: return .danger
        }
    }

    private var tintColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .ghost:                 return .textPrimary
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AppButton("Continue", style: .primary) {}
        AppButton("Cancel", style: .ghost) {}
        AppButton("Delete", style: .destructive) {}
        AppButton("Loading…", style: .primary, isLoading: true) {}
        AppButton("With Icon", style: .ghost, icon: "star.fill") {}
    }
    .padding()
}
