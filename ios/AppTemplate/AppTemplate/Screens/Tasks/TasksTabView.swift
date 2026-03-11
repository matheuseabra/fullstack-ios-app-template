import SwiftUI

// MARK: - TasksTabView
// Root signed-in shell matching the Stitch bottom navigation.

struct TasksTabView: View {
    @StateObject private var vm = TasksViewModel()
    @State private var selectedTab: Tab = .today
    @State private var previousTab: Tab = .today
    @State private var showAddTask = false
    @State private var isTabBarVisible = true

    enum Tab: Int, CaseIterable {
        case today, calendar, stats, settings

        var icon: String {
            switch self {
            case .today: return "house.fill"
            case .calendar: return "calendar"
            case .stats: return "chart.bar.fill"
            case .settings: return "person.fill"
            }
        }

        var accessibilityID: String? {
            switch self {
            case .today: return "tasksTab.dashboardButton"
            case .calendar: return "tasksTab.listButton"
            case .stats, .settings: return nil
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                currentScreen
                    .id(selectedTab)
                    .transition(tabTransition)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isTabBarVisible {
                    customTabBar
                        .frame(width: proxy.size.width)
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height - proxy.safeAreaInsets.bottom
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .drawer(isPresented: $showAddTask, detents: [.large]) {
            TaskFormView(vm: vm, isPresented: $showAddTask)
        }
        .animation(.easeInOut(duration: 0.2), value: isTabBarVisible)
        .task { await vm.load() }
        .onAppear { Analytics.screen("Home") }
        .onChange(of: selectedTab) { _, _ in
            isTabBarVisible = true
        }
        .onChange(of: showAddTask) { _, isPresented in
            isTabBarVisible = !isPresented
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .today:
            DashboardView(vm: vm, isTabBarVisible: $isTabBarVisible)
        case .calendar:
            TaskListView(vm: vm, isTabBarVisible: $isTabBarVisible)
        case .stats:
            StatsView(vm: vm)
        case .settings:
            SettingsView(isTabBarVisible: $isTabBarVisible)
        }
    }

    private var tabTransition: AnyTransition {
        if selectedTab.rawValue >= previousTab.rawValue {
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        }

        return .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
    }

    private var customTabBar: some View {
        let fabSize: CGFloat = 56

        return ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.94))
                .frame(width: 364)
                .frame(height: 82)
                .shadow(color: .black.opacity(0.22), radius: 20, y: 12)

            HStack(spacing: 0) {
                tabSlot(.today)
                tabSlot(.calendar)
                Color.clear
                    .frame(maxWidth: .infinity)
                tabSlot(.stats)
                tabSlot(.settings)
            }
            .frame(width: 364)

            Button {
                showAddTask = true
                HapticManager.medium()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(width: fabSize, height: fabSize)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .white.opacity(0.08), radius: 10, y: 2)
            }
            .accessibilityIdentifier("tasksTab.addButton")
            .offset(y: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .background(Color.clear)
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            guard selectedTab != tab else { return }

            previousTab = selectedTab
            withAnimation(.easeInOut(duration: 0.24)) {
                selectedTab = tab
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 0) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: selectedTab == tab ? .semibold : .regular))
            }
            .foregroundStyle(selectedTab == tab ? Color.white : Color.white.opacity(0.38))
            .frame(maxWidth: .infinity)
            .frame(height: 82)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.accessibilityID ?? "")
    }

    private func tabSlot(_ tab: Tab) -> some View {
        tabButton(tab)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}

#Preview {
    TasksTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
