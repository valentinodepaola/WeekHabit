# CLAUDE.md

This file gives concise guidance for coding agents working in this repository.

## Project

WeekHabit is a SwiftUI iOS app for weekly habit tracking and rhythm building. It is a single Xcode project (`WeekHabit.xcodeproj`) with no Swift Package Manager dependencies or CocoaPods, and three targets: the `WeekHabit` app, the `WeekHabitWidgets` widget extension, and the `WeekHabitTests` unit test target.

Stack: Swift 5.0, SwiftUI, SwiftData, UserNotifications, iOS 26.4+, universal iPhone/iPad.

User-facing strings and code comments are in Spanish. Keep new UI strings and comments in Spanish. Type names and identifiers may stay in English, matching the existing codebase.

## Build

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

There is no lint configuration. `WeekHabitTests` is the unit test target.

## Targets and shared code

Three folders map to targets:

- `WeekHabit/` — the app: views, services, app-only extensions.
- `WeekHabitWidgets/` — the widget extension.
- `WeekHabitCore/` — **compiled into both**: `Models/`, the design tokens the widget needs
  (`AppCalendar`, `AppColor`, `AppFont`, `AppFormatters`, `AppMotion`, `AppRadius`,
  `AppSpacing`, `Color+Hex`) and `WHProgressRing`.

`WeekHabitCore` is a plain folder, not a package — each target compiles the sources into its
own module, so everything stays `internal` and nothing needs `public`.

**A new file under `WeekHabitCore/` reaches both targets automatically** (synchronized
groups), which is the whole point of the split. Code the widget must not see goes in
`WeekHabit/`. `WeekHabitCore` must not import anything from `WeekHabit/`: the extension
would fail to compile.

The SwiftData store lives in the App Group `group.com.valentino.WeekHabit`, built through
`AppGroupStore`. Only the app migrates the schema; the extension opens it read-only.

## Architecture

The app uses a pragmatic SwiftUI architecture with SwiftData.

Open architectural work lives in the repo's GitHub issues, not in a plan document.
`ARCHITECTURE.md` records the decisions already taken. Do not reopen a settled decision
without new evidence.

- Views read with `@Query`.
- Reusable mutations live in domain services such as `HabitTrackingService`, `HabitEditorService`, and `PlanEditorService`.
- Complex forms group editable state and validation in value-type drafts such as `HabitDraft` and `PlanDraft`.
- Domain logic lives in model extensions, not in layout code.
- Views keep presentation effects, navigation, haptics, and feature-local UI state.

`WeekHabitApp.swift` creates the `ModelContainer` with `Schema(versionedSchema: SchemaV17.self)` and `HabitMigrationPlan.self`.

`RootView` switches between `OnboardingView` and `ContentView` using `@AppStorage("hasCompletedAppOnboarding")`. It also refreshes habit reminders when the app starts or returns active.

## Main Models

- `Habit`: core habit entity. Supports check or quantity tracking, units, daily/specific/flexible weekly schedules, optional end date, reminders, entries, and plan associations.
- `HabitEntry`: one day/value record. `date` is normalized to start of day. `source` distinguishes `.today`, `.focusSession`, and `.manual`; `kind` distinguishes `.completed`, `.skipped`, `.missed`, `.slip`, and `.urge`.
- `StreakFreeze`: weekly wildcard that preserves a streak across a missed day. Domain logic in `Domain/StreakFreeze+Domain.swift`.
- `Plan`: groups habits around a goal with motivation, end date, target completion rate, and review state.
- `HabitExperiment`: 7-day rhythm experiment suggested by Insights.
- `FocusSession`: timer/review workflow for focused habit completion.

`Models/` is organized as the app's model layer:

- `Entities/`: SwiftData `@Model` entities and persisted enums/value accessors.
- `Domain/`: pure model behavior and business rules used by views.
- `Insights/`: insight DTOs, per-habit metrics, aggregate habit collection metrics, and insight date helpers.
- `Persistence/`: versioned SwiftData schemas and migration plan.
- `Routing/`: lightweight route value types used by navigation.
- `Support/`: model-adjacent value types such as appearance and weekday definitions.

Important domain files:

- `Domain/Habit+Scheduling.swift`: schedule checks, loggability, pauses, end dates, and week traversal.
- `Domain/Habit+Completion.swift`: daily entry state, quantities, weekly progress, and completion ratios.
- `Domain/Habit+Streaks.swift`: current/display/best streaks and streak breakdowns.
- `Domain/Habit+Freezes.swift`: freeze protection and weekly freeze candidates.
- `Domain/Habit+Recovery.swift`: recovery prompt candidates.
- `Domain/Habit+Presentation.swift`: derived copy, quantity formatting, and heatmap matrix.
- `Insights/Habit+InsightMetrics.swift`: 30-day per-habit metrics, confidence, failures, best day/hour inputs.
- `Insights/HabitCollection+Insights.swift`: aggregate snapshots, attention habit, contextual best day/hour, experiment suggestions.
- `Domain/HabitExperiment+Domain.swift`: apply, keep, revert, cancel, review experiments.
- `Domain/FocusSession+Domain.swift`: timer progress, review/completion/cancel.
- `Domain/Plan+Domain.swift`: active/finished/review state, progress, goal status.

Use `AppCalendar` for date math instead of `Calendar.current` directly.

## Navigation

`ContentView` uses a native `TabView(selection: $selectedTab)` shell. Each tab's title and icon come from the `TabItems` enum (`Views/Components/TabItems.swift`), and tabs are selected by integer `.tag(0/1/2)`.

Current tabs:

- `0`: `TodayView`
- `1`: `WeekView`
- `2`: `InsightsView`

`ContentView` also handles `WidgetDeepLink.today`: tapping the widget forces tab `0`, so the
user lands on Hoy instead of resuming wherever the app was left.

There is no separate `HabitsView` tab in the current app.

`ContentView` also presents `PlanWrapUpView` as a sheet when a plan has ended and has not been reviewed.

Common flows:

- `TodayView` creates/edits/deletes habits and plans.
- `TodayView` presents `CreateHabitView`, `PlanFlowView`, `CreatePlanView`, and `FocusSessionView`.
- `WeekView` opens `HabitDetailView` and logs manual/retroactive entries.
- `InsightsView` edits suggested habits and manages rhythm experiments.
- `HabitDetailView` presents `CreateHabitView` for editing.

Keep the tab order in `ContentView` (`.tag(0/1/2)`) synchronized with the `TabItems` cases used for each tab's label.

## Feature Notes

Habit tracking:

- Check habits toggle directly.
- Quantity habits open `QuantityLogSheet`.
- A habit is completed when `totalValue(on:) >= sessionTargetValue`.
- Flexible schedules use `HabitScheduleKind.timesPerWeek`.

Insights:

- `.today` and `.focusSession` entries are trusted.
- `.manual` entries are useful for history but not trusted as rhythm evidence.

Plans:

- Plans are created through `PlanFlowView` / `CreatePlanView`.
- First plan creation may show `PlanOnboardingView`.
- Finished plans are reviewed in `PlanWrapUpView`.
- Archiving a plan habit sets the habit `endsAt` to today.

Reminders:

- `HabitReminderService` schedules local notifications per active weekday.
- Reminders are skipped for finished habits.
- Reminder body prefers active plan motivation, then habit note, then fallback copy.

Widgets (`WeekHabitWidgets`):

- **Two widgets, both read-only** — they show and open the app, they do not log habits. Both
  derive everything they draw in one pass in a `WeekHabitCore/` value type (the views live in
  the extension, out of the test target's reach), and both read the shared store read-only
  (`WidgetStore` + `AppGroupStore.readOnlyConfiguration`). A read failure draws
  `WidgetUnavailableView` ("open the app"), never a zero — or an empty grid — that would read
  as a flawless day. Copy lives in a `*Copy` enum, never inline.
- **Pendientes de hoy** — `accessoryCircular`, `accessoryRectangular`, `systemSmall`,
  `systemMedium`. From `TodayWidgetSnapshot`; four states (`pending`, `allDone`, `rest`,
  `empty`) so an empty day never reads as a failure. The lock-screen families are
  **monochrome**: the system tints them, so they use no `AppColor` token. Opens Hoy.
- **Año de constancia** — `systemLarge` only, **home screen only** (no `accessory*`). A
  year-long GitHub-style grid, one square per day, aggregating every fixed-schedule habit; a
  day's opacity is the fraction of that day's scheduled habits that were completed. From
  `YearHeatmapSnapshot`: one `HabitDayIndex` per habit, four discrete `kind`s so "did nothing"
  never looks like "nothing was due". Flexible habits are excluded; freeze/rest days drop out
  of that habit's ratio. `HeatmapMonthSegment` (month grouping) is shared with the in-app
  `LastWeeksHeatmapCard`. Opens Insights.
- `WidgetRefreshService.reloadWidgets()` reloads all timelines when the scene leaves
  `.active` — one place, not one call per mutation; a new widget inherits the refresh.

Onboarding:

- `OnboardingView` is connected.
- It can request notification permission and create a starter habit.

## View Organization

Follow the existing folder shape:

```text
Views/
  <Feature>View/
    <Feature>View.swift
    Components/
      <ComponentName>.swift
  Components/
    SharedComponent.swift
```

Shared UI goes in `Views/Components`. Feature-specific UI stays in that feature's `Components`
folder. UI the widget also needs goes in `WeekHabitCore/Components`.

## Design System

Reuse existing tokens/helpers:

- `AppBackground`
- `AppColor`
- `AppFont`
- `AppRadius`
- `IconButton`
- `HabitAppearance`

Top-level screens should use `AppBackground`. Avoid hardcoded colors, fonts, and date calculations when a local helper exists.

Design quality is a product requirement, not a polish pass. Before implementing visible UI, inspect adjacent screens/components and match their density, radius, typography, spacing, icon language, motion, empty states, and semantic tone. Prefer small, complete interactions that feel native to the current app over large new visual patterns.

For sensitive habit states such as misses, slips, breaks, recovery, or pauses, never use punitive copy or destructive styling unless the action truly deletes data. Use neutral language, calm semantic colors, and clear next actions so the UI treats the user's input as useful data.

## Persistence Conventions

- New persisted fields require updating model initializers and callers.
- Shape changes require a new `SchemaV*` and a `MigrationStage` in `HabitMigrationPlan`.
- Do not mutate old schemas to represent new persisted shapes.
- Add reusable mutations to a domain service instead of duplicating them across views.
- Never delete or convert `.urge` entries while changing the primary daily state.

## Forms

`CreateHabitView` and `CreatePlanView` are the reference patterns:

- group editable state, validation, and normalization in a value-type draft;
- delegate persistence and relationship reconciliation to an editor service;
- show persistence failures instead of silencing them;
- dismiss only after a successful save;
- refresh side effects explicitly when needed, such as reminders.
