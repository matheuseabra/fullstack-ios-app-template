import SwiftUI

// MARK: - AppButton
// Usage: AppButton("Continue", style: .primary) { ... }
//        AppButton("Cancel", style: .ghost) { ... }
//        AppButton("Delete", style: .destructive, isLoading: vm.isLoading) { ... }

struct AppButton: View {
    enum Icon: ExpressibleByStringLiteral {
        case system(String)
        case googleMark

        init(stringLiteral value: StringLiteralType) {
            self = .system(value)
        }
    }

    let title: String
    let style: Style
    let icon: Icon?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        icon: Icon? = nil,
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
                        iconView(icon)
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

    @ViewBuilder
    private func iconView(_ icon: Icon) -> some View {
        switch icon {
        case let .system(systemName):
            Image(systemName: systemName)
                .font(.body(16, weight: .semibold))
        case .googleMark:
            GoogleMark()
        }
    }
}

private struct GoogleMark: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.06, to: 0.28)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                .rotationEffect(.degrees(6))

            Circle()
                .trim(from: 0.28, to: 0.53)
                .stroke(Color(red: 0.91, green: 0.30, blue: 0.24), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                .rotationEffect(.degrees(6))

            Circle()
                .trim(from: 0.53, to: 0.76)
                .stroke(Color(red: 0.98, green: 0.74, blue: 0.12), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                .rotationEffect(.degrees(6))

            Circle()
                .trim(from: 0.76, to: 1.0)
                .stroke(Color(red: 0.20, green: 0.66, blue: 0.33), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                .rotationEffect(.degrees(6))

            Path { path in
                path.move(to: CGPoint(x: 8.6, y: 8))
                path.addLine(to: CGPoint(x: 14.5, y: 8))
            }
            .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        }
        .frame(width: 18, height: 18)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AppButton("Continue", style: .primary) {}
        AppButton("Cancel", style: .ghost) {}
        AppButton("Delete", style: .destructive) {}
        AppButton("Loading…", style: .primary, isLoading: true) {}
        AppButton("With Icon", style: .ghost, icon: "star.fill") {}
        AppButton("Google", style: .ghost, icon: .googleMark) {}
    }
    .padding()
}
