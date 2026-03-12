import SwiftUI

// MARK: - Skeleton / Shimmer Loading Placeholder
// Usage: SkeletonView(style: .row)
//        SkeletonView(style: .card)

struct SkeletonView: View {
    let style: Style

    enum Style { case row, card }

    @State private var phase: CGFloat = -1

    var body: some View {
        Group {
            switch style {
            case .row: rowShape
            case .card: cardShape
            }
        }
        .overlay(shimmer)
        .onAppear { startAnimation() }
    }

    // MARK: - Shapes

    private var rowShape: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.bgSurface)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Capsule().fill(Color.bgSurface).frame(height: 14).frame(maxWidth: 140)
                Capsule().fill(Color.bgSurface).frame(height: 12).frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(Spacing.md)
    }

    private var cardShape: some View {
        RoundedRectangle(cornerRadius: Radius.lg)
            .fill(Color.bgSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
    }

    // MARK: - Shimmer Overlay

    private var shimmer: some View {
        Canvas { context, size in
            let width = size.width
            let gradient = Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .white.opacity(0.15), location: 0.5),
                .init(color: .clear, location: 1),
            ])
            let start = CGPoint(x: (phase - 1) * width, y: 0)
            let end = CGPoint(x: (phase + 1) * width, y: 0)
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(gradient, startPoint: start, endPoint: end))
        }
        .clipped()
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SkeletonView(style: .row)
        SkeletonView(style: .row)
        SkeletonView(style: .card)
    }
    .padding()
    .background(Color.bg)
}
