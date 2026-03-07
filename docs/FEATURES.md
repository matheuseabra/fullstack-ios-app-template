# Features

> Registry of all implemented features. Every new feature must be documented here.
> See `.agents/AGENTS.md` → Documentation Rule for the template and instructions.

---

## Task Manager

**Status:** ✅ Implemented
**Migration:** `supabase/migrations/0010_tasks.sql`
**iOS screens:** `ios/AppTemplate/AppTemplate/Screens/Tasks/`
**Backend routes:** `backend/src/routes/tasks.ts`

### What it does
Replaces the placeholder `HomeView` with a full local-first task manager. Users can create tasks with a title, note, priority (low/medium/high), and optional due date. The signed-in shell now follows the latest Stitch refresh: a Today task list, a calendar timeline view, a productivity stats dashboard, and a settings/profile tab anchored by a floating add-task button. Tasks are stored in SwiftData (instant, offline-safe) and synced to Supabase in the background.

### Navigation
`AppRouter.root == .home` → `TasksTabView` (replaces old `HomeView`)

Custom tab bar with five zones:
- Left: **Today** (`DashboardView`) — grouped task list for the current day
- Left-center: **Calendar** (`TaskListView`) — week strip + timeline layout for the selected date
- Center: **Add Task FAB** — raised `+` button, opens `AddTaskView` as bottom sheet
- Right-center: **Stats** (`StatsView`) — weekly progress and task health metrics
- Right: **Settings** (`SettingsView`) — account, appearance, and subscription management

### Key Files

| File | Purpose |
|---|---|
| `ios/Models/TaskItem.swift` | SwiftData `@Model` — source of truth for local storage + API DTOs |
| `ios/Screens/Tasks/TasksViewModel.swift` | All business logic: CRUD, sync, derived data |
| `ios/Screens/Tasks/TasksTabView.swift` | Root signed-in shell + Stitch-style bottom navigation |
| `ios/Screens/Tasks/DashboardView.swift` | Today task list grouped into time buckets |
| `ios/Screens/Tasks/WeekCalendarStrip.swift` | Week selector used by the calendar timeline view |
| `ios/Screens/Tasks/TaskDetailCard.swift` | Stitch-style task card used in Today lists |
| `ios/Screens/Tasks/TaskListView.swift` | Calendar timeline layout for tasks on the selected date |
| `ios/Screens/Tasks/StatsView.swift` | Weekly progress, streak, completion rate, overdue counts |
| `ios/Screens/Tasks/AddTaskView.swift` | Bottom sheet create/edit form matching the Stitch task composer |
| `ios/AppTemplate/AppTemplate/Screens/Settings/SettingsView.swift` | Settings/profile tab used inside the signed-in shell |
| `ios/Core/Storage/LocalDatabase.swift` | `TaskItem.self` registered in SwiftData Schema |
| `ios/Core/Storage/SyncManager.swift` | `pull()` fetches all tasks and merges (server-wins) |
| `ios/Core/Network/APIEndpoints.swift` | `tasks`, `task(_ id:)` endpoints |
| `ios/Core/Network/APIClient.swift` | `delete<T>()` method added |
| `backend/src/routes/tasks.ts` | `GET/POST /api/tasks`, `GET/PUT/DELETE /api/tasks/:id` |
| `backend/src/schemas/task.schema.ts` | Zod: `createTaskSchema`, `updateTaskSchema` |
| `backend/src/types/database.ts` | `tasks` table Row/Insert/Update types |
| `supabase/migrations/0010_tasks.sql` | Tasks table, RLS, indexes, `set_updated_at` trigger |

### Data Model (`TaskItem`)

```swift
@Model final class TaskItem {
    var id: UUID           // unique local ID
    var title: String
    var note: String
    var isCompleted: Bool
    var priority: Priority // .low | .medium | .high
    var dueDate: Date?
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var supabaseId: String?        // set after first successful sync
    var syncStatus: SyncStatus     // .synced | .pendingUpload | .pendingUpdate | .pendingDelete
}
```

### API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/tasks` | List all tasks for authenticated user |
| `POST` | `/api/tasks` | Create task |
| `GET` | `/api/tasks/:id` | Get single task |
| `PUT` | `/api/tasks/:id` | Update task |
| `DELETE` | `/api/tasks/:id` | Delete task |

All endpoints require Bearer JWT (Supabase auth token). RLS enforces user isolation at DB level.

### Analytics Events

| Event | Trigger |
|---|---|
| `featureUsed("home")` | View appears |
| `featureUsed("today")` | Today tab becomes visible |
| `featureUsed("calendar")` | Calendar timeline tab becomes visible |
| `featureUsed("stats")` | Stats tab becomes visible |
| `featureUsed("settings")` | Settings tab becomes visible |
| `featureUsed("task_created")` | User adds a task |
| `featureUsed("task_completed")` | User checks off a task |
| `featureUsed("task_uncompleted")` | User unchecks a completed task |
| `featureUsed("task_deleted")` | User deletes a task |

### Sync Strategy

Local-first with server-wins conflict resolution:
1. **On app launch** — `SyncManager.pullIfNeeded()` fetches all tasks from API, merges into SwiftData
2. **On local write** — saved to SwiftData immediately (optimistic), then push to server in background
3. **Conflict** — server value wins for tasks where `syncStatus == .synced`; pending local changes are preserved
4. **DEBUG builds** — server sync disabled (`#if !DEBUG` guard); local SwiftData only

## Stitch Screen Refresh

**Status:** ✅ Implemented
**Migration:** N/A
**iOS screens:** `ios/AppTemplate/AppTemplate/Screens/Splash/`, `ios/AppTemplate/AppTemplate/Screens/Onboarding/`, `ios/AppTemplate/AppTemplate/Screens/Paywall/`, `ios/AppTemplate/AppTemplate/Screens/Settings/`, `ios/AppTemplate/AppTemplate/Screens/Tasks/`
**Backend routes:** N/A

### What it does
Applies the exported Stitch references from `designs/` to the live iOS experience. The refresh updates the splash screen, onboarding option cards, the paywall presentation, the signed-in task shell, the settings/profile surface, and adds a stats screen while preserving the existing task model, SwiftData storage, and backend task sync contract.

### Key files
- `designs/01-today-task-list-view-fbf03bb7ada14cc8a18a84c0c9c1e85d.html` — Today task list reference
- `designs/02-create-task-bottom-sheet-eadb8edc3071429dadf9b8f322f876ed.html` — create/edit bottom-sheet reference
- `designs/03-calendar-timeline-view-365a2101a52145dab247bf83b0370732.html` — calendar timeline reference
- `designs/04-today-task-list-view-a8b065d1651244d594be03892098a50c.html` — splash reference
- `designs/05-today-task-list-view-c5aee00ccc85427e8d7a79be77547301.html` — onboarding option-card reference
- `designs/06-today-task-list-view-e254a9943a614cddbdda51c8410dc30d.html` — paywall reference
- `designs/07-today-task-list-view-bfd0e6560c774c8bad21efb4e6b31b1e.html` — settings reference
- `designs/08-today-task-list-view-0eada8dd12684401973439c881e160ae.html` — stats reference

---

<!-- Add new features below this line -->
