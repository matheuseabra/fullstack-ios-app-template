import SwiftUI

// MARK: - TaskCompletionCheckbox

struct TaskCompletionCheckbox: View {
    let isChecked: Bool
    var size: CGFloat = 20
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isChecked ? Color.textPrimary : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isChecked ? Color.textPrimary : Color.border.opacity(0.85), lineWidth: 1.5)
            )
            .frame(width: size, height: size)
            .overlay {
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.46, weight: .bold))
                        .foregroundStyle(Color.bg)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}