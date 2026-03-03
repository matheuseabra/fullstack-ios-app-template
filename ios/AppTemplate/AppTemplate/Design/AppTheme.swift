import SwiftUI

// MARK: - App Theme
// Manages color scheme preference persisted in UserDefaults.

@MainActor
final class AppTheme: ObservableObject {
    static let shared = AppTheme()

    @AppStorage("colorScheme") private var storedScheme: String = "system"

    var colorScheme: ColorScheme? {
        switch storedScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil  // follows system
        }
    }

    func setLight()  { storedScheme = "light" }
    func setDark()   { storedScheme = "dark" }
    func setSystem() { storedScheme = "system" }
}
