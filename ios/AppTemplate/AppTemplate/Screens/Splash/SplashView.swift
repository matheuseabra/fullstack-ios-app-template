import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.88

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            Circle()
                .fill(Color.accent.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: 110, y: -220)

            Circle()
                .fill(Color.accent.opacity(0.06))
                .frame(width: 180, height: 180)
                .blur(radius: 20)
                .offset(x: -120, y: 260)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Spacing.xxl) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.xl)
                            .fill(Color.accent)
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.accent.opacity(0.28), radius: 18, y: 10)

                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(Color.white.opacity(0.92), lineWidth: 4)
                            .frame(width: 42, height: 42)
                    }

                    VStack(spacing: Spacing.sm) {
                        Text("AppTemplate")
                            .font(.display(36, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text("Tasks & Focus")
                            .font(.body(13, weight: .semibold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                VStack(spacing: Spacing.lg) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.bgSurface)
                            .frame(width: 128, height: 6)

                        Capsule()
                            .fill(Color.accent)
                            .frame(width: 42, height: 6)
                    }

                    Text("Minimal Design Lab")
                        .font(.body(11, weight: .bold))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.bottom, Spacing.xxxl)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                opacity = 1
                scale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.advance()
                }
            }
        }
    }
}
