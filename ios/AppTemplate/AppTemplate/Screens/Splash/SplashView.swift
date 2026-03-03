import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.92

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(systemName: "app.fill")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(Color.accent)
                Text("AppTemplate")
                    .font(.display(28))
                    .foregroundStyle(Color.textPrimary)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                opacity = 1
                scale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.advance()
                }
            }
        }
    }
}
