import SwiftUI

// MARK: - TasksTabView
// Root container with custom tab bar: Dashboard | Add (FAB) | Task List

struct TasksTabView: View {
    @StateObject private var vm = TasksViewModel()
    @State private var selectedTab: Tab = .dashboard
    @State private var showAddTask = false
    @State private var showSettings = false

    enum Tab: Int, CaseIterable {
        case dashboard, taskList

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .taskList:  return "list.bullet"
            }
        }

        var label: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .taskList:  return "Tasks"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(vm: vm, showSettings: $showSettings)
                case .taskList:
                    TaskListView(vm: vm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .drawer(isPresented: $showAddTask) {
            AddTaskView(vm: vm, isPresented: $showAddTask)
        }
        .task { await vm.load() }
        .onAppear { Analytics.track(.featureUsed(name: "home")) }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack {
            // Dashboard tab
            tabButton(.dashboard)

            Spacer()

            // Center FAB
            Button {
                showAddTask = true
                HapticManager.medium()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accent)
                    .clipShape(Circle())
                    .shadow(color: Color.accent.opacity(0.3), radius: 8, y: 4)
            }
            .offset(y: -16)

            Spacer()

            // Task List tab
            tabButton(.taskList)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(
            Color.bgElevated
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedTab = tab
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                    .symbolVariant(selectedTab == tab ? .fill : .none)
                Text(tab.label)
                    .font(.body(11, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? Color.accent : Color.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TasksTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
