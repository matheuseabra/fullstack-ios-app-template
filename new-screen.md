# Workflow: Scaffold a New SwiftUI Screen

**Trigger:** Agent asked to build a new screen or view in the iOS app.

---

## Prerequisites
- Stitch MCP connected
- XcodeBuildMCP connected
- Skills loaded: `swiftui-expert-skill`, `mobile-ios-design`

---

## Steps

### 1. Design Exploration with Stitch MCP

Use Stitch to explore design concepts before writing any code.

```
stitch: create_design(
  prompt: "iOS 17 dark mode [SCREEN NAME] screen, minimal UI, 
           deep black background #0A0A0A, violet accent #6C63FF, 
           SF Pro fonts, bottom tab navigation, [key elements of screen]"
)
```

Iterate on the design until it matches the app's design system (see `docs/DESIGN_SYSTEM.md`).

### 2. Export References

Export both PNG and HTML for the agent to reference while coding:

```
stitch: export_png(design_id: "[id]")
  → Save to: .agents/design-refs/[screen-name].png

stitch: export_html(design_id: "[id]")
  → Save to: .agents/design-refs/[screen-name].html
```

### 3. Convert to SwiftUI

Load the `swiftui-expert-skill` and convert the design to a SwiftUI view.

**Rules:**
- Use design tokens from `ios/Design/` — never hardcode colors, spacing, or fonts
- Follow the ViewModel pattern: View owns `@StateObject`, ViewModel is `@MainActor class`
- Add skeleton loading state if the screen fetches data
- Add empty state with `EmptyStateView` if the screen shows a list
- Wire up haptics on key interactions (see `docs/DESIGN_SYSTEM.md`)
- Fire Analytics event on screen appear: `Analytics.track(.screenViewed("[name]"))`

**File targets:**
```
ios/Screens/[FeatureName]/[FeatureName]View.swift
ios/Screens/[FeatureName]/[FeatureName]ViewModel.swift
```

**ViewModel template:**
```swift
@MainActor
class [FeatureName]ViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var error: AppError?

  func load() async {
    isLoading = true
    defer { isLoading = false }
    do {
      // fetch data
    } catch {
      self.error = error as? AppError
    }
  }
}
```

**View template:**
```swift
struct [FeatureName]View: View {
  @StateObject private var vm = [FeatureName]ViewModel()

  var body: some View {
    // Your view here
    .task { await vm.load() }
    .onAppear { Analytics.track(.screenViewed("[feature_name]")) }
  }
}

#Preview {
  [FeatureName]View()
    .preferredColorScheme(.dark)
}
```

### 4. Build Verification

Run a build to catch any compile errors:

```
xcode: build(scheme: "MyApp", destination: "iPhone 16 Pro Simulator")
```

If there are errors:
```
xcode: get_build_errors()
```

Fix all errors before continuing. Do not skip this step.

### 5. Register in AppRouter

Add the new screen to `ios/App/AppRouter.swift`:

```swift
// In the NavigationPath destination handler:
case .featureName:
  FeatureNameView()
```

If it's a tab item, add to `ios/App/MainTabView.swift`.

---

## Checklist

- [ ] Stitch design explored and exported
- [ ] View matches design system (colors, typography, spacing)
- [ ] ViewModel created with proper async patterns
- [ ] Skeleton loading state (if data fetching)
- [ ] Empty state (if list/collection)
- [ ] Haptic feedback on key interactions
- [ ] Analytics event fires on screen appear
- [ ] `xcode: build` passes with no errors
- [ ] Screen registered in AppRouter
- [ ] Dark mode preview added
