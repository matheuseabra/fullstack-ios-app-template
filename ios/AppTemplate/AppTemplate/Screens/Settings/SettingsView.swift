import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var theme: AppTheme
    @State private var showSignOutConfirm = false

    var body: some View {
        List {
            // Account
            Section("Account") {
                if let user = vm.user {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName ?? "No name")
                                .font(.body(15, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text(user.email)
                                .font(.body(13))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                } else {
                    SkeletonView(style: .row)
                        .listRowInsets(.init())
                }

                NavigationLink("Manage Subscription") {
                    SubscriptionManagementView()
                }
            }

            // Preferences
            Section("Preferences") {
                Picker("Appearance", selection: Binding(
                    get: { theme.colorScheme == nil ? "system" : theme.colorScheme == .dark ? "dark" : "light" },
                    set: { v in
                        switch v {
                        case "light":  theme.setLight()
                        case "dark":   theme.setDark()
                        default:       theme.setSystem()
                        }
                    }
                )) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

                NavigationLink("Notification Preferences") {
                    NotificationPreferencesView()
                }
            }

            // Support
            Section("Support") {
                LinkRow(label: "Help & FAQ", url: "https://yourapp.com/help")
                LinkRow(label: "Send Feedback", url: "mailto:hello@yourapp.com")
                Button("Rate the App") {
                    // TODO: SKStoreReviewController.requestReview()
                }
                .foregroundStyle(Color.textPrimary)
            }

            // Legal
            Section {
                LinkRow(label: "Privacy Policy", url: "https://yourapp.com/privacy")
                LinkRow(label: "Terms of Service", url: "https://yourapp.com/terms")
                Button("Sign Out", role: .destructive) {
                    showSignOutConfirm = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .confirmationDialog("Are you sure?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { vm.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to use the app.")
        }
    }
}

// MARK: - LinkRow

private struct LinkRow: View {
    let label: String
    let url: String

    var body: some View {
        if let dest = URL(string: url) {
            Link(destination: dest) {
                HStack {
                    Text(label)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }
}

// MARK: - Stub sub-screens (Phase 8 fills these in)

private struct SubscriptionManagementView: View {
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            EmptyStateView(icon: "creditcard", title: "Subscription", subtitle: "Manage via the App Store.", action: nil)
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationPreferencesView: View {
    @State private var enabled = true
    @State private var reminderTime = Date()

    var body: some View {
        Form {
            Toggle("Enable Reminders", isOn: $enabled)
            if enabled {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
