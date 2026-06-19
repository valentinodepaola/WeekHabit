//
//  WeekView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \StreakFreeze.usedAt, order: .reverse)
    private var streakFreezes: [StreakFreeze]

    @Query(sort: \WeeklyReview.reviewedAt, order: .reverse)
    private var weeklyReviews: [WeeklyReview]

    @AppStorage("weeklyReviewWeekdayRaw") private var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue

    @State private var weekOffset: Int = 0
    @State private var selectedHabit: Habit?
    @State private var coverRoute: WeekCoverRoute?
    @State private var sheetRoute: WeekSheetRoute?

    private var referenceDate: Date {
        AppCalendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: .now) ?? .now
    }

    private var weekRange: Range<Date> {
        AppCalendar.weekRange(containing: referenceDate)
    }

    private var visibleHabits: [Habit] {
        AppPerformance.measure("Week visible habits") {
            habits.filter { habit in
                daysInWeek.contains { habit.isLoggable(on: $0) || habit.isCompleted(on: $0) }
            }
        }
    }

    private var daysInWeek: [Date] {
        (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: weekRange.lowerBound)
        }
    }

    private var monthYearLabel: String {
        AppFormatters.uppercasedString(
            from: referenceDate,
            format: "MMMM yyyy",
            foldingDiacritics: true
        )
    }

    private var weekNumber: Int {
        AppCalendar.current.component(.weekOfYear, from: referenceDate)
    }

    private var completedDisplay: String {
        let completed = completedThisWeek
        return completed == 0 ? "—" : "\(completed)"
    }

    private var totalGoal: Int {
        AppPerformance.measure("Week total goal") {
            visibleHabits.reduce(0) { $0 + $1.targetDaysPerWeek }
        }
    }

    private var completedThisWeek: Int {
        AppPerformance.measure("Week completed count") {
            visibleHabits.reduce(0) { partial, habit in
                partial + habit.completedDaysThisWeek(reference: referenceDate)
            }
        }
    }

    private var consistencyDisplay: String {
        guard totalGoal > 0, completedThisWeek > 0 else { return "—" }
        let percentage = min(1, Double(completedThisWeek) / Double(totalGoal)) * 100
        return "\(Int(percentage))%"
    }

    private var completedLabel: String {
        let hasBreak = visibleHabits.contains { $0.isBreakHabit }
        let hasBuild = visibleHabits.contains { !$0.isBreakHabit }
        if hasBreak && !hasBuild { return "Evitados" }
        if hasBreak { return "Marcados" }
        return "Completados"
    }

    private var focusCandidateHabits: [Habit] {
        habits.filter {
            $0.isLoggable(on: .now) && !$0.isSkipped(on: .now) && !$0.isSlip(on: .now)
        }
    }

    private var focusDisabledReason: String? {
        focusCandidateHabits.isEmpty ? "No hay hábitos disponibles para hoy." : nil
    }

    private var weeklyReviewWeekStart: Date? {
        WeeklyReviewService.needsReview(
            reference: .now,
            preferredWeekday: Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday,
            existingReviews: weeklyReviews,
            habits: habits
        )
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                VStack(alignment: .leading, spacing: 0) {
                    WeekHeaderSection(
                        monthYearLabel: monthYearLabel,
                        weekNumber: weekNumber,
                        weekOffset: $weekOffset,
                        onShowLegend: { sheetRoute = .legend },
                        onCreate: { sheetRoute = .createMenu }
                    )

                    dayStrip
                    contentArea
                        .padding(.top, AppSpacing.s)
                }
                .navigationDestination(item: $selectedHabit) { habit in
                    HabitDetailView(habit: habit)
                }
                .fullScreenCover(item: $coverRoute) { route in
                    routeCover(route)
                }
                .sheet(item: $sheetRoute) { route in
                    routeSheet(route)
                }
                .task {
                    applyWeeklyFreezes(reference: .now)
                }
            }
        }
    }

    private var dayStrip: some View {
        WeekPulseSection(
            pulses: daysInWeek.map(dayPulse(for:)),
            completedThisWeek: completedThisWeek,
            totalGoal: totalGoal
        )
        .padding(.bottom, AppSpacing.s)
    }

    private func dayPulse(for date: Date) -> WeekDayPulse {
        AppPerformance.measure("Week day pulse") {
            let scheduledHabits = visibleHabits.filter { $0.isLoggable(on: date) }
            let completed = scheduledHabits.filter { $0.isCompleted(on: date) }.count

            return WeekDayPulse(
                date: date,
                isToday: AppCalendar.isSameDay(date, .now),
                isFuture: AppCalendar.startOfDay(for: date) > AppCalendar.startOfDay(for: .now),
                completed: completed,
                scheduled: scheduledHabits.count
            )
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if visibleHabits.isEmpty {
            VStack(spacing: AppSpacing.m) {
                if let weeklyReviewWeekStart {
                    WeeklyReviewBanner(
                        weekRangeText: weekRangeText(for: weeklyReviewWeekStart),
                        onTap: { sheetRoute = .weeklyReview(weekStart: weeklyReviewWeekStart) }
                    )
                }

                WeekEmptyStateCard(onCreate: { sheetRoute = .createMenu })
            }
            .padding(.horizontal, AppSpacing.l)
            Spacer()
        } else {
            List {
                if let weeklyReviewWeekStart {
                    WeeklyReviewBanner(
                        weekRangeText: weekRangeText(for: weeklyReviewWeekStart),
                        onTap: { sheetRoute = .weeklyReview(weekStart: weeklyReviewWeekStart) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
                }

                ForEach(visibleHabits) { habit in
                    WeekGridRow(
                        habit: habit,
                        daysInWeek: daysInWeek,
                        referenceDate: referenceDate,
                        today: .now,
                        onSelectHabit: { selectedHabit = habit },
                        onToggle: { date in toggleCompletion(for: habit, on: date) },
                        onSkip: { date in toggleRest(for: habit, on: date) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l))
                }

                Section {
                    summarySection
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: AppSpacing.xl, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l))
                }
            }
            .listStyle(.plain)
            .listRowSpacing(AppSpacing.xs)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, AppSpacing.xl, for: .scrollContent)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("RESUMEN")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            HStack(spacing: AppSpacing.s) {
                StatTile(label: completedLabel, value: completedDisplay, icon: "checkmark.circle.fill")
                StatTile(label: "Meta total", value: "\(totalGoal)", icon: "target")
                StatTile(label: "Consistencia", value: consistencyDisplay, icon: "chart.bar.fill")
            }
        }
    }

    // MARK: - Routing

    @ViewBuilder
    private func routeCover(_ route: WeekCoverRoute) -> some View {
        switch route {
        case .habit(let habitRoute):
            switch habitRoute {
            case .create(let prefill):
                CreateHabitView(
                    initialDaysPerWeek: prefill.initialDaysPerWeek ?? 7,
                    initialActiveDays: prefill.initialActiveDays
                )
            case .edit(let habit):
                CreateHabitView(habitToEdit: habit)
            }
        case .plan(let planRoute):
            switch planRoute {
            case .create:
                CreatePlanView()
            case .edit(let plan):
                CreatePlanView(planToEdit: plan)
            }
        case .focus(let habits):
            FocusSessionView(habits: habits)
        }
    }

    @ViewBuilder
    private func routeSheet(_ route: WeekSheetRoute) -> some View {
        switch route {
        case .legend:
            WeekLegendSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.bgCanvas)
        case .createMenu:
            WHCreationSheet(focusDisabledReason: focusDisabledReason) { option in
                handleCreationSelection(option)
            }
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .quantityLog(let habit, let date):
            QuantityLogSheet(
                habit: habit,
                date: date,
                initialValue: habit.totalValue(on: date)
            ) { value in
                upsertQuantityEntry(for: habit, on: date, value: value)
            }
            .presentationDetents([.height(310)])
        case .weeklyReview(let weekStart):
            WeeklyReviewView(weekStart: weekStart)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.bgCanvas)
        }
    }

    private func handleCreationSelection(_ option: WHCreationOption) {
        sheetRoute = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            switch option {
            case .habit:
                coverRoute = .habit(.create(prefill: .empty))
            case .plan:
                coverRoute = .plan(.create)
            case .focus:
                guard !focusCandidateHabits.isEmpty else { return }
                coverRoute = .focus(habits: focusCandidateHabits)
            }
        }
    }

    // MARK: - Actions

    private func toggleCompletion(for habit: Habit, on date: Date) {
        if habit.trackingKind == .quantity {
            sheetRoute = .quantityLog(habit: habit, date: date)
            return
        }

        let willMark = !habit.isCompleted(on: date)

        _ = withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            HabitTrackingService.toggleCompletion(
                for: habit,
                on: date,
                source: .manual,
                completedAt: nil,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if willMark {
            habit.markCurrentMilestoneSilently(on: date)
        }

        AppHaptics.play(willMark ? .selection : .selection)
        applyWeeklyFreezes(reference: .now)
    }

    private func upsertQuantityEntry(for habit: Habit, on date: Date, value: Double) {
        _ = withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            HabitTrackingService.upsertQuantity(
                for: habit,
                on: date,
                value: value,
                source: .manual,
                completedAt: nil,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if value > 0, habit.totalValue(on: date) >= habit.sessionTargetValue {
            habit.markCurrentMilestoneSilently(on: date)
        }

        AppHaptics.play(.selection)
        applyWeeklyFreezes(reference: .now)
    }

    private func toggleRest(for habit: Habit, on date: Date) {
        _ = withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            HabitTrackingService.toggleRest(
                for: habit,
                on: date,
                source: AppCalendar.isSameDay(date, .now) ? .today : .manual,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        AppHaptics.play(.selection)
        applyWeeklyFreezes(reference: .now)
    }

    private func weekRangeText(for weekStart: Date) -> String {
        let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(AppFormatters.string(from: weekStart, format: "d MMM")) - \(AppFormatters.string(from: weekEnd, format: "d MMM"))"
    }

    private func applyWeeklyFreezes(reference: Date) {
        HabitTrackingService.applyWeeklyFreezes(
            to: habits,
            existing: streakFreezes,
            reference: reference,
            modelContext: modelContext
        )
    }
}

// MARK: - Routes

private enum WeekCoverRoute: Identifiable {
    case habit(HabitRoute)
    case plan(PlanRoute)
    case focus(habits: [Habit])

    var id: String {
        switch self {
        case .habit(let route): return "habit-\(route.id)"
        case .plan(let route): return "plan-\(route.id)"
        case .focus(let habits): return "focus-\(habits.map { $0.id.uuidString }.joined(separator: ","))"
        }
    }
}

private enum WeekSheetRoute: Identifiable {
    case legend
    case createMenu
    case quantityLog(habit: Habit, date: Date)
    case weeklyReview(weekStart: Date)

    var id: String {
        switch self {
        case .legend: return "legend"
        case .createMenu: return "createMenu"
        case .quantityLog(let habit, let date): return "quantityLog-\(habit.id)-\(date.timeIntervalSinceReferenceDate)"
        case .weeklyReview(let weekStart): return "weeklyReview-\(weekStart.timeIntervalSinceReferenceDate)"
        }
    }
}

#Preview {
    WeekView()
}
