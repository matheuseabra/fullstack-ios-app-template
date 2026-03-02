# Design System

> Minimal dark-first UI. Room to expand in any direction. Every decision is a constraint that enables speed.

---

## Theme

### Color Palette

```swift
// AppColors.swift
extension Color {
  // Backgrounds — layered depth
  static let bg          = Color("bg")           // #0A0A0A  true dark base
  static let bgElevated  = Color("bgElevated")   // #141414  cards, sheets
  static let bgSurface   = Color("bgSurface")    // #1E1E1E  inputs, rows

  // Text
  static let textPrimary    = Color("textPrimary")   // #F2F2F2
  static let textSecondary  = Color("textSecondary") // #8A8A8A
  static let textTertiary   = Color("textTertiary")  // #4A4A4A

  // Brand — swap per app
  static let accent      = Color("accent")       // #6C63FF  purple default
  static let accentMuted = Color("accentMuted")  // #6C63FF at 15% opacity

  // Semantic
  static let success = Color("success")   // #34C759
  static let warning = Color("warning")   // #FF9F0A
  static let danger  = Color("danger")    // #FF453A

  // Borders
  static let border     = Color("border")     // #2A2A2A
  static let borderFocus = Color("borderFocus") // accent at 60%
}
```

> **Niche swap:** Change only `accent` color to shift the entire app's personality.
> - Education: `#4FACFE` (sky blue)
> - Productivity: `#6C63FF` (violet, default)
> - Health: `#30D158` (mint green)

---

## Typography

Two system fonts — no font loading, no performance hit.

```swift
// AppFonts.swift
extension Font {
  // Headlines — SF Pro Display (system rounded = friendly)
  static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }

  // Body — SF Pro Text (system default = readable)
  static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .default)
  }

  // Monospace — for numbers, codes
  static func mono(_ size: CGFloat) -> Font {
    .system(size: size, weight: .regular, design: .monospaced)
  }
}

// Usage scale
// display(34) — Hero / Splash title
// display(28) — Screen title
// display(22) — Section header
// body(17)    — Primary body
// body(15)    — Secondary body / captions
// body(13)    — Labels / metadata
// mono(15)    — Numbers, stats
```

---

## Icons

**FeatherIcons** via Swift Package:
`https://github.com/feathericons/feather-swift`

```swift
// Usage
Image(feather: .chevronRight)
  .foregroundColor(.textSecondary)
  .frame(width: 20, height: 20)
```

---

## Spacing

8-point grid. No arbitrary values.

```swift
// AppSpacing.swift
enum Spacing {
  static let xs  : CGFloat = 4
  static let sm  : CGFloat = 8
  static let md  : CGFloat = 16
  static let lg  : CGFloat = 24
  static let xl  : CGFloat = 32
  static let xxl : CGFloat = 48
  static let xxxl: CGFloat = 64
}
```

---

## Corner Radii

```swift
enum Radius {
  static let sm  : CGFloat = 8
  static let md  : CGFloat = 12
  static let lg  : CGFloat = 16
  static let xl  : CGFloat = 24
  static let pill: CGFloat = 999
}
```

---

## Components

### AppButton

```swift
// Three variants
AppButton("Continue", style: .primary)   // accent fill
AppButton("Maybe later", style: .ghost)  // transparent, text only
AppButton("Delete", style: .destructive) // danger color

// With icon
AppButton("Next", icon: .chevronRight, style: .primary)

// Loading state built-in
AppButton("Save", style: .primary, isLoading: viewModel.isSaving)
```

### AppTextField

```swift
AppTextField("Your name", text: $name)
AppTextField("Email", text: $email, keyboardType: .emailAddress)
AppTextField("Password", text: $password, isSecure: true)
```

### SkeletonView

```swift
// Wrap any view in skeleton
SkeletonView(isLoading: viewModel.isLoading) {
  ContentRow(item: item)
}

// Or use directly
SkeletonRow()      // generic row shimmer
SkeletonCard()     // generic card shimmer
```

### EmptyStateView

```swift
EmptyStateView(
  illustration: "empty-tasks",   // asset name
  title: "Nothing here yet",
  subtitle: "Add your first item to get started",
  action: ("Add Item", { /* action */ })
)
```

### AppModal / AppDrawer

```swift
// Bottom drawer (most common)
.sheet(isPresented: $showSettings) {
  AppDrawer {
    SettingsView()
  }
}

// Full modal
.fullScreenCover(isPresented: $showPaywall) {
  PaywallView()
}
```

---

## Navigation

**Tab bar** — fixed, background matches `bg` color, no separator line.

```swift
// Tabs stay the same across niches
// Only icons + labels change
TabItem(icon: .home,    label: "Home",    tab: .home)
TabItem(icon: .zap,     label: "Today",   tab: .today)
TabItem(icon: .user,    label: "Profile", tab: .profile)
```

**Stack navigation** — `NavigationStack` with custom slide transition.

---

## Transitions

```swift
// AppTransitions.swift
extension AnyTransition {
  static let slideUp = AnyTransition.asymmetric(
    insertion: .move(edge: .bottom).combined(with: .opacity),
    removal: .move(edge: .bottom).combined(with: .opacity)
  )

  static let slidePush = AnyTransition.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
  )

  static let fadeScale = AnyTransition.asymmetric(
    insertion: .opacity.combined(with: .scale(scale: 0.95)),
    removal: .opacity.combined(with: .scale(scale: 0.95))
  )
}
```

---

## Haptics

```swift
// HapticManager.swift
enum HapticManager {
  static func light()    { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
  static func medium()   { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
  static func heavy()    { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
  static func success()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
  static func error()    { UINotificationFeedbackGenerator().notificationOccurred(.error) }
  static func selection(){ UISelectionFeedbackGenerator().selectionChanged() }
}

// Key moments to fire haptics:
// .light    — tab switch, row tap
// .medium   — completing a task, quiz answer select
// .heavy    — destructive action confirm
// .success  — payment success, onboarding complete
// .error    — validation fail, network error
// .selection — option picker change
```

---

## Dark / Light Mode

```swift
// AppTheme.swift
class AppTheme: ObservableObject {
  @AppStorage("colorScheme") var colorScheme: String = "dark"

  var scheme: ColorScheme {
    colorScheme == "light" ? .light : .dark
  }
}

// In App.swift
@StateObject private var theme = AppTheme()

WindowGroup {
  ContentView()
    .preferredColorScheme(theme.scheme)
    .environmentObject(theme)
}
```
