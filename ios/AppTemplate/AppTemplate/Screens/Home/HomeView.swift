import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = HomeViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                Group {
                    if vm.isLoading {
                        loadingSkeleton
                    } else if let error = vm.errorMessage {
                        EmptyStateView(
                            icon: "wifi.slash",
                            title: "Couldn't load",
                            subtitle: error,
                            action: ("Retry", { Task { await vm.reload() } })
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.xl) {
                                // Greeting
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Hello\(vm.user?.fullName.map { ", \($0)" } ?? "") 👋")
                                        .font(.display(24))
                                        .foregroundStyle(Color.textPrimary)
                                    if let sub = vm.subscription, sub.isActive {
                                        Label("Pro", systemImage: "star.fill")
                                            .font(.body(13, weight: .semibold))
                                            .foregroundStyle(Color.accent)
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                                .padding(.top, Spacing.md)

                                // ── Add your core feature UI here ──
                                Text("Replace this with your core feature content.")
                                    .font(.body(15))
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(.horizontal, Spacing.lg)
                            }
                            .padding(.bottom, Spacing.xxl)
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { SettingsView() }
            }
        }
        .task { await vm.load() }
        .onAppear { Analytics.screen("Home") }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: Spacing.md) {
            SkeletonView(style: .row)
            SkeletonView(style: .card)
            SkeletonView(style: .row)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}
