import SwiftUI

struct DottedDivider: View {
    var color: Color = Color.textTertiary.opacity(0.45)

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: size.width, y: 0))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
        }
        .frame(height: 1.5)
    }
}

#Preview {
    DottedDivider()
        .padding()
}
