import SwiftUI

// MARK: - AppDrawer
// A lightweight bottom-sheet wrapper using SwiftUI's sheet with a custom detent.
// Usage:
//   @State private var showDrawer = false
//   AppDrawer(isPresented: $showDrawer) { /* content */ }

struct AppDrawer<Content: View>: View {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let content: () -> Content

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                content()
                    .presentationDetents(detents)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Radius.xl)
                    .background(Color.bgElevated)
            }
    }
}

// MARK: - Convenience View Modifier

extension View {
    /// Attaches a bottom-sheet drawer
    func drawer<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            AppDrawer(isPresented: isPresented, detents: detents, content: content)
        )
    }
}

#Preview {
    struct Preview: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color.bg.ignoresSafeArea()
                Button("Open Drawer") { show = true }
            }
            .drawer(isPresented: $show) {
                VStack(spacing: Spacing.md) {
                    Text("Drawer Content")
                        .font(.display(20))
                    AppButton("Confirm", style: .primary) { show = false }
                }
                .padding(Spacing.xl)
            }
        }
    }
    return Preview()
}
