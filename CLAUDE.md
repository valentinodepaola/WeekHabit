# CLAUDE.md

This file gives concise guidance for coding agents working in this repository.

## Project

WeekHabit is a SwiftUI iOS app for weekly habit tracking and rhythm building. It is a single Xcode project (`WeekHabit.xcodeproj`) with no Swift Package Manager dependencies, no CocoaPods, and no test target.

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

There is no lint configuration and no test target.

## Architecture

The app uses a lightweight Model-View style with SwiftUI + SwiftData.

- Views read with `@Query`.
- Views mutate with `@Environment(\.modelContext)`.
- Domain logic lives in model extensions, not in layout code.
- There is no ViewModel, repository, networking, authentication, or external sync layer.

`WeekHabitApp.swift` creates the `ModelContainer` with `Schema(versionedSchema: SchemaV12.self)` and `HabitMigrationPlan.self`.

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

- `Domain/Habit+Domain.swift`: schedule checks, loggability, quantities, streaks and streak breakdowns, weekly progress, heatmap matrix.
- `Insights/Habit+InsightMetrics.swift`: 30-day per-habit metrics, confidence, failures, best day/hour inputs.
- `Insights/HabitCollection+Insights.swift`: aggregate snapshots, attention habit, contextual best day/hour, experiment suggestions.
- `Domain/HabitExperiment+Domain.swift`: apply, keep, revert, cancel, review experiments.
- `Domain/FocusSession+Domain.swift`: timer progress, review/completion/cancel.
- `Domain/Plan+Domain.swift`: active/finished/review state, progress, goal status.

Use `AppCalendar` for date math instead of `Calendar.current` directly.

## Navigation

`ContentView` uses a manual `ZStack` tab shell with `selectedTab` and `CustomTabBar`.

Current tabs:

- `0`: `TodayView`
- `1`: `WeekView`
- `2`: `InsightsView`

There is no separate `HabitsView` tab in the current app.

`ContentView` also presents `PlanWrapUpView` as a sheet when a plan has ended and has not been reviewed.

Common flows:

- `TodayView` creates/edits/deletes habits and plans.
- `TodayView` presents `CreateHabitView`, `PlanFlowView`, `CreatePlanView`, and `FocusSessionView`.
- `WeekView` opens `HabitDetailView` and logs manual/retroactive entries.
- `InsightsView` edits suggested habits and manages rhythm experiments.
- `HabitDetailView` presents `CreateHabitView` for editing.

Keep the tab order in `ContentView` synchronized with `CustomTabBar.tabs`.

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

Shared UI goes in `Views/Components`. Feature-specific UI stays in that feature's `Components` folder.

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
- Keep data mutations in the owning view unless a reusable service already exists.

## Forms

`CreateHabitView` and `CreatePlanView` are the reference patterns:

- local `@State` per field;
- computed `isSaveDisabled`;
- normalize values before saving;
- insert/update directly with `modelContext`;
- dismiss after save;
- refresh side effects explicitly when needed, such as reminders.
