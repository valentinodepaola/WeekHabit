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

**Persistence (SwiftData).** [WeekHabitApp.swift](WeekHabit/WeekHabitApp.swift) builds the `ModelContainer` from a versioned schema declared in [HabitSchema.swift](WeekHabit/Models/HabitSchema.swift). When the persisted shape of a model changes, add a new `SchemaV2` and a `MigrationStage` in `HabitMigrationPlan` — do not edit `SchemaV1` in place. Views read/write via `@Environment(\.modelContext)` and `@Query`; there is no view-model layer.

- [Habit](WeekHabit/Models/Habit.swift) — owns `entries` with `.cascade` delete. Active days persist as `[Int]` (`activeDaysOfWeekRaw`) but expose as `Set<Weekday>` via a computed property; always read/write through `activeDaysOfWeek`. `category` persists as a `HabitCategory` enum (Codable). Domain computations (`isActive(on:)`, `isCompleted(on:)`, `completedDaysThisWeek`, `weekProgress`, `currentStreak`) live in [Habit+Domain.swift](WeekHabit/Models/Habit+Domain.swift) — extend there, not in views.
- [HabitEntry](WeekHabit/Models/HabitEntry.swift) — one record per completion event. The `init` normalizes `date` to `startOfDay` so range queries are timezone-stable.
- [Weekday](WeekHabit/Models/WeekDay.swift) — `Int` raw values match `Calendar`'s 1-based weekday convention (Sunday = 1, Monday = 2, …). Use `Weekday.ordered` for L–D display order.
- [AppCalendar](WeekHabit/Extensions/AppCalendar.swift) — single source of truth for date math (`startOfDay`, `weekday(of:)`, `weekRange(containing:)`, `isSameDay`). Always use this instead of `Calendar.current` directly so timezone/firstWeekday assumptions stay consistent.

**Navigation.** No `NavigationStack` / `TabView`. [ContentView](WeekHabit/ContentView.swift) holds `@State selectedTab: Int` and switches between `TodayView`, `HabitsView`, `WeekView`, `InsightsView` inside a `ZStack`, with [CustomTabBar](WeekHabit/Views/Components/CustomTabBar.swift) overlaid at the bottom. The tab order in the `switch` and the `tabs` array in `CustomTabBar` must stay in sync. Modal flows (e.g. `CreateHabitView`) are presented via `.fullScreenCover`.

**View organization.** Each feature lives in `Views/<Feature>View/` with a sibling `Components/` folder for view-local building blocks. Truly cross-feature pieces go in `Views/Components/` (e.g. `CustomTabBar`, `IconButton`). Mirror this when adding a new screen rather than flattening into `Views/`.

**Design system (Extensions/).** Reuse these instead of hardcoding:
- [AppBackground](WeekHabit/Extensions/AppBackground.swift) — wrap each top-level screen in `AppBackground { … }` for the app's light/dark background. Don't set background colors directly on screens.
- [AppColor](WeekHabit/Extensions/AppColor.swift) — brand palette (`accent`, `mutedText`, `surface`, …). Add new tokens here instead of inlining `Color(hex:)`. Category colors stay on [HabitCategory](WeekHabit/Models/HabitCategory.swift).
- [AppFont](WeekHabit/Extensions/AppFont.swift) — use the named tokens (`title`, `body2`, `formSectionText`, …) instead of `Font.system(...)` for text. SF Symbol sizing on `Image` still uses `.font(.system(size:))`.
- [AppRadius](WeekHabit/Extensions/AppRadius.swift) — corner-radius scale (`small`/`medium`/`large`/`pill`).
- [IconButton](WeekHabit/Views/Components/IconButton.swift) — shared brand button, two shapes via `style: .circle | .pill`. Don't introduce new bespoke buttons unless the design genuinely diverges.

**Form pattern (CreateHabitView).** [CreateHabitView](WeekHabit/Views/CreateHabitView/CreateHabitView.swift) is the reference for forms: local `@State` per field, an `isSaveDisabled` computed property gates the save button, and `.onChange(of: daysPerWeek)` keeps `selectedActiveDays` consistent with `targetDaysPerWeek`. Saving inserts directly into `modelContext` and calls `dismiss()` — no repository/service indirection.

## Conventions

- Follow the existing folder shape (`Views/<Feature>View/Components/`) when adding new screens.
- New persisted fields require updating `Habit.init` and any callers. For shape changes (renamed/removed/retyped fields), add a `SchemaV2` and a `MigrationStage` in [HabitSchema.swift](WeekHabit/Models/HabitSchema.swift) — don't mutate `SchemaV1`.
- Spanish for user-facing strings and inline comments. English is fine for type/identifier names (the codebase already mixes them — e.g. `WeekGoalComponent`, `targetDaysPerWeek`).
