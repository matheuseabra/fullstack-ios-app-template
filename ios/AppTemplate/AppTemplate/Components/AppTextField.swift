import SwiftUI

// MARK: - AppTextField
// Usage: AppTextField("Email", text: $email)
//        AppTextField("Password", text: $password, isSecure: true)
//        AppTextField("Phone", text: $phone, keyboard: .phonePad)

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboard: UIKeyboardType

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboard = keyboard
    }

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
            }
        }
        .font(.body(19))
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.bgSurface)
        .clipShape(.rect(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(isFocused ? Color.borderFocus : Color.border, lineWidth: 1.5)
        )
        .focused($isFocused)
        .animation(.snappy, value: isFocused)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AppTextField("Email address", text: .constant(""))
        AppTextField("Password", text: .constant("secret"), isSecure: true)
    }
    .padding()
}
