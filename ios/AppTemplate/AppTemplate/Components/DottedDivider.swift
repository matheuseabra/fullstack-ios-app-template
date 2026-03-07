import SwiftUI

struct DottedDivider: View {
    var color: Color = Color.border.opacity(0.55)

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        }
        .frame(height: 1)
    }
}

#Preview {
    DottedDivider()
        .padding()
}