import RevenueCatUI
import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.requestReview) private var requestReview
    @Binding var isTabBarVisible: Bool
    @State private var showSignOutConfirm = false
    @State private var showAppearanceSheet = false

    private let shareURL = URL(string: "https://apps.apple.com/app/id0000000000")!
    private let termsURL = URL(string: "https://yourapp.com/terms")!
    private let privacyURL = URL(string: "https://yourapp.com/privacy")!

    init(isTabBarVisible: Binding<Bool> = .constant(true)) {
        self._isTabBarVisible = isTabBarVisible
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        Text("Settings")
                            .font(.display(38, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        profileCard

                        settingsSection(
                            title: "Account",
                            rows: [.notifications, .subscription, .syncCalendar]
                        )

                        settingsSection(
                            title: "Support",
                            rows: [.share, .rate, .terms, .privacy]
                        )

                        settingsSection(
                            title: "App Customization",
                            rows: [.appearance, .language, .logout]
                        )
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .task { await vm.load() }
            .sheet(isPresented: $showAppearanceSheet) {
                AppearanceSheet(theme: theme)
            }
            .onAppear { Analytics.screen("Settings") }
            .onAppear { isTabBarVisible = true }
            .onChange(of: showAppearanceSheet) { _, isPresented in
                isTabBarVisible = !isPresented
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { vm.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to use the app.")
        }
    }

    private func settingsDestination<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SettingsDestinationContainer(isTabBarVisible: $isTabBarVisible, content: content())
    }

    private var profileCard: some View {
        HStack(spacing: Spacing.md) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                if let user = vm.user {
                    Text(user.fullName ?? "No name")
                        .font(.body(20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(user.email)
                        .font(.body(13))
                        .foregroundStyle(Color.textSecondary)
                } else {
                    SkeletonView(style: .row)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "square.and.pencil")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accent)
        }
        .padding(Spacing.lg)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .stroke(Color.border.opacity(0.7), lineWidth: 1)
        )
    }

    private var avatarView: some View {
        Group {
            if let avatar = vm.user?.avatarURL, let url = URL(string: avatar) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.bgSurface)
                        .overlay(ProgressView())
                }
            } else {
                Circle()
                    .fill(Color.bgSurface)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                    )
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.bg, lineWidth: 3)
        )
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.success)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.bg, lineWidth: 2))
        }
    }

    private var currentAppearance: String {
        switch theme.colorScheme {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        case nil:
            return "System"
        @unknown default:
            return "System"
        }
    }

    private enum SettingsRowKind: String, Identifiable {
        case notifications
        case subscription
        case syncCalendar
        case share
        case rate
        case terms
        case privacy
        case appearance
        case language
        case logout

        var id: String { rawValue }
    }

    private func settingsSection(title: String, rows: [SettingsRowKind]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.body(11, weight: .bold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    settingsRowView(rows[index])
                    if index < rows.count - 1 {
                        Divider()
                            .overlay(Color.border.opacity(0.6))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(Color.border.opacity(0.7), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func settingsRowView(_ row: SettingsRowKind) -> some View {
        switch row {
        case .notifications:
            NavigationLink {
                settingsDestination {
                    NotificationPreferencesView()
                }
            } label: {
                settingsRow(icon: "bell.fill", title: "Notifications")
            }
        case .subscription:
            NavigationLink {
                settingsDestination {
                    SubscriptionManagementView()
                }
            } label: {
                settingsRow(icon: "star.fill", title: "Subscription", trailing: vm.subscriptionLabel)
            }
        case .syncCalendar:
            settingsRow(icon: "arrow.triangle.2.circlepath", title: "Sync Calendar", trailing: "Google")
        case .share:
            ShareLink(item: shareURL) {
                settingsRow(icon: "square.and.arrow.up", title: "Share App")
            }
        case .rate:
            Button {
                requestReview()
            } label: {
                settingsRow(icon: "star.bubble", title: "Rate App")
            }
            .buttonStyle(.plain)
        case .terms:
            Link(destination: termsURL) {
                settingsRow(icon: "doc.text", title: "Terms of Service")
            }
        case .privacy:
            Link(destination: privacyURL) {
                settingsRow(icon: "lock.shield", title: "Privacy Policy")
            }
        case .appearance:
            Button {
                showAppearanceSheet = true
            } label: {
                settingsRow(icon: "paintpalette.fill", title: "Appearance", trailing: currentAppearance)
            }
            .buttonStyle(.plain)
        case .language:
            settingsRow(icon: "globe", title: "Language", trailing: "English")
        case .logout:
            Button {
                showSignOutConfirm = true
            } label: {
                settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Log Out", destructive: true, showsChevron: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(icon: String, title: String, trailing: String? = nil, destructive: Bool = false, showsChevron: Bool = true) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(destructive ? Color.danger : Color.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.body(15, weight: .medium))
                .foregroundStyle(destructive ? Color.danger : Color.textPrimary)

            Spacer(minLength: 0)

            if let trailing {
                Text(trailing)
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(destructive ? Color.danger : Color.textSecondary)
                    .padding(.horizontal, trailing == "Pro" ? 8 : 0)
                    .padding(.vertical, trailing == "Pro" ? 4 : 0)
                    .background(trailing == "Pro" ? Color.accent.opacity(0.12) : Color.clear)
                    .clipShape(Capsule())
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 58)
    }
}

private struct SettingsDestinationContainer<Content: View>: View {
    @Binding var isTabBarVisible: Bool
    let content: Content

    var body: some View {
        content
            .onAppear { isTabBarVisible = false }
            .onDisappear { isTabBarVisible = true }
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

// MARK: - Subscription Management (RevenueCat Customer Center)

private struct SubscriptionManagementView: View {
    var body: some View {
        CustomerCenterView()
            .navigationTitle("Manage Subscription")
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

private struct AppearanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme: AppTheme

    var body: some View {
        NavigationStack {
            Form {
                Button("System") {
                    theme.setSystem()
                }
                Button("Light") {
                    theme.setLight()
                }
                Button("Dark") {
                    theme.setDark()
                }
            }
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
