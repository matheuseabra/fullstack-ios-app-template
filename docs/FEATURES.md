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
Replaces the placeholder `HomeView` with a full local-first task manager. Users can create tasks with a title, note, priority (low/medium/high), and optional due date. The dashboard shows a weekly calendar strip, a circular progress ring for daily completion, and tasks filtered by the selected day. A full task list with search and segmented filtering (All/Pending/Completed) is accessible via the second tab. Tasks are stored in SwiftData (instant, offline-safe) and synced to Supabase in the background.

### Navigation
`AppRouter.root == .home` → `TasksTabView` (replaces old `HomeView`)

Custom tab bar with three zones:
- Left: **Dashboard** (`DashboardView`) — calendar + summary + daily tasks
- Center: **Add Task FAB** — raised `+` button, opens `AddTaskView` as bottom sheet
- Right: **Tasks** (`TaskListView`) — full searchable/filterable list

### Key Files

| File | Purpose |
|---|---|
| `ios/Models/TaskItem.swift` | SwiftData `@Model` — source of truth for local storage + API DTOs |
| `ios/Screens/Tasks/TasksViewModel.swift` | All business logic: CRUD, sync, derived data |
| `ios/Screens/Tasks/TasksTabView.swift` | Root container + custom tab bar |
| `ios/Screens/Tasks/DashboardView.swift` | Greeting, calendar strip, summary card, daily tasks |
| `ios/Screens/Tasks/WeekCalendarStrip.swift` | Horizontal scrollable day pills |
| `ios/Screens/Tasks/TaskSummaryCard.swift` | Circular progress ring + completion stats |
| `ios/Screens/Tasks/TaskDetailCard.swift` | Task row: checkbox, priority badge, due time |
| `ios/Screens/Tasks/TaskListView.swift` | Searchable list + segmented filter + swipe actions |
| `ios/Screens/Tasks/AddTaskView.swift` | Bottom sheet form: title, note, priority, due date |
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

---

<!-- Add new features below this line -->
