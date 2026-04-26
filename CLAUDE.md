# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

WeekHabit is a SwiftUI iOS app for tracking weekly habits. Single Xcode project (`WeekHabit.xcodeproj`), no Swift Package Manager dependencies, no test target. Swift 5.0, deployment target iOS 26.4, universal (iPhone + iPad). UI strings and code comments are in Spanish — keep new strings/comments in Spanish to match.

## Build & Run

Open `WeekHabit.xcodeproj` in Xcode and run the `WeekHabit` scheme on a Simulator. From CLI:

```bash
# Build for simulator
xcodebuild -project WeekHabit.xcodeproj -scheme WeekHabit -destination 'platform=iOS Simulator,name=iPhone 16' build

# Quick syntax check (no signing)
xcodebuild -project WeekHabit.xcodeproj -scheme WeekHabit -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

There is no test target and no lint configuration.

## Architecture

**Persistence (SwiftData).** The model container is registered once in [WeekHabitApp.swift](WeekHabit/WeekHabitApp.swift) for `[Habit.self, HabitEntry.self]`. Views read/write via `@Environment(\.modelContext)` and `@Query`. There is no view-model layer — views talk to SwiftData directly.

- [Habit](WeekHabit/Models/Habit.swift) — owns `entries` with `.cascade` delete. Active days are stored as `[Int]` (`activeDaysOfWeekRaw`) but exposed as `Set<Weekday>` via a computed property; always read/write through `activeDaysOfWeek`. The `category` field is a free `String` persisted as the `rawValue` of [HabitCategory](WeekHabit/Models/HabitCategory.swift) — convert via the `habitCategory` computed property, which falls back to `.personal` for unknown values.
- [HabitEntry](WeekHabit/Models/HabitEntry.swift) — one record per completion event for a `Habit`.
- [Weekday](WeekHabit/Models/WeekDay.swift) — `Int` raw values intentionally match `Calendar`'s 1-based weekday convention (Sunday = 1, Monday = 2, …). Use `Weekday.ordered` for L–D display order rather than `allCases`.

**Navigation.** No `NavigationStack` / `TabView`. [ContentView](WeekHabit/ContentView.swift) holds `@State selectedTab: Int` and switches between `TodayView`, `HabitsView`, `WeekView`, `InsightsView` inside a `ZStack`, with [CustomTabBar](WeekHabit/Views/Components/CustomTabBar.swift) overlaid at the bottom. The tab order in the `switch` and the `tabs` array in `CustomTabBar` must stay in sync. Modal flows (e.g. `CreateHabitView`) are presented via `.fullScreenCover`.

**View organization.** Each feature lives in `Views/<Feature>View/` with a sibling `Components/` folder for view-local building blocks. Truly cross-feature pieces go in `Views/Components/` (e.g. `CustomTabBar`, `ButtonWithIcon`). Mirror this when adding a new screen rather than flattening into `Views/`.

**Design system (Extensions/).** Reuse these instead of hardcoding:
- [AppBackground](WeekHabit/Extensions/AppBackground.swift) — wrap each top-level screen in `AppBackground { … }` for the app's light/dark background. Don't set background colors directly on screens.
- [AppFont](WeekHabit/Extensions/AppFont.swift) — use the named tokens (`title`, `body2`, `formSectionText`, …) instead of `Font.system(...)`.
- [Color+Hex](WeekHabit/Extensions/Color+Hex.swift) — colors throughout the app are written as `Color(hex: "#…")` literals; there is no central palette enum yet, so the same brand hexes (e.g. `#c2573c` accent, `#6b6458` muted text, `#f5f1ea` light bg, `#121010` dark bg) are repeated across views.

**Form pattern (CreateHabitView).** [CreateHabitView](WeekHabit/Views/CreateHabitView/CreateHabitView.swift) is the reference for forms: local `@State` per field, an `isSaveDisabled` computed property gates the save button, and `.onChange(of: daysPerWeek)` keeps `selectedActiveDays` consistent with `targetDaysPerWeek`. Saving inserts directly into `modelContext` and calls `dismiss()` — no repository/service indirection.

## Conventions

- Follow the existing folder shape (`Views/<Feature>View/Components/`) when adding new screens.
- New persisted fields require updating both `Habit.init` and any callers; there are no migrations configured.
- Spanish for user-facing strings and inline comments. English is fine for type/identifier names (the codebase already mixes them — e.g. `WeekGoalComponent`, `targetDaysPerWeek`).
