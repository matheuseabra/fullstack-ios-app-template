import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.88

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

                Text("AppTemplate")
                    .font(.display(36, weight: .bold))
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
            Task {
                try? await Task.sleep(for: .seconds(2.1))
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                try? await Task.sleep(for: .milliseconds(300))
                router.advance()
            }
        }
    }
}
