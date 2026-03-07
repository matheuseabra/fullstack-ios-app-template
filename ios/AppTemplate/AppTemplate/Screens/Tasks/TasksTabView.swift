import SwiftUI

// MARK: - TasksTabView
// Root signed-in shell matching the Stitch bottom navigation.

struct TasksTabView: View {
    @StateObject private var vm = TasksViewModel()
    @State private var selectedTab: Tab = .today
    @State private var showAddTask = false

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
                Group {
                    switch selectedTab {
                    case .today:
                        DashboardView(vm: vm)
                    case .calendar:
                        TaskListView(vm: vm)
                    case .stats:
                        StatsView(vm: vm)
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                customTabBar
                    .frame(width: proxy.size.width)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height - proxy.safeAreaInsets.bottom
                    )
            }
        }
        .ignoresSafeArea(.keyboard)
        .drawer(isPresented: $showAddTask, detents: [.large]) {
            TaskFormView(vm: vm, isPresented: $showAddTask)
        }
        .task { await vm.load() }
        .onAppear { Analytics.track(.featureUsed(name: "home")) }
    }

    private var customTabBar: some View {
        let fabSize: CGFloat = 56

        return ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black.opacity(0.94))
                .frame(maxWidth: 364)
                .frame(height: 82)
                .shadow(color: .black.opacity(0.22), radius: 20, y: 12)

            HStack(spacing: 0) {
                tabButton(.today)
                tabButton(.calendar)
                Color.clear.frame(width: fabSize + Spacing.xxl)
                tabButton(.stats)
                tabButton(.settings)
            }
            .frame(maxWidth: 364)

            Button {
                if selectedTab == .today {
                    vm.selectedDate = Date()
                }   
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
            .offset(y: -4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .background(Color.clear)
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedTab = tab
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: selectedTab == tab ? .semibold : .regular))
                Circle()
                    .fill(selectedTab == tab ? Color.accent : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(selectedTab == tab ? Color.white : Color.white.opacity(0.38))
            .frame(maxWidth: .infinity)
            .frame(height: 82)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.accessibilityID ?? "")
    }
}

#Preview {
    TasksTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
