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
        habits.filter { habit in
            daysInWeek.contains { habit.isLoggable(on: $0) || habit.isCompleted(on: $0) }
        }
    }

    private var daysInWeek: [Date] {
        (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: weekRange.lowerBound)
        }
    }

    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
            .string(from: referenceDate)
            .folding(options: .diacriticInsensitive, locale: formatter.locale)
            .uppercased(with: formatter.locale)
    }

    private var weekNumber: Int {
        AppCalendar.current.component(.weekOfYear, from: referenceDate)
    }

    private var completedDisplay: String {
        let completed = completedThisWeek
        return completed == 0 ? "—" : "\(completed)"
    }

    private var totalGoal: Int {
        visibleHabits.reduce(0) { $0 + $1.targetDaysPerWeek }
    }

    private var completedThisWeek: Int {
        visibleHabits.reduce(0) { partial, habit in
            partial + habit.completedDaysThisWeek(reference: referenceDate)
        }
    }

    private var consistencyDisplay: String {
        guard totalGoal > 0, completedThisWeek > 0 else { return "—" }
        let percentage = min(1, Double(completedThisWeek) / Double(totalGoal)) * 100
        return "\(Int(percentage))%"
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                VStack(alignment: .leading, spacing: 0) {
                    WeekHeaderSection(
                        monthYearLabel: monthYearLabel,
                        weekNumber: weekNumber,
                        weekOffset: $weekOffset,
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
            }
        }
    }

    private var dayStrip: some View {
        HStack(spacing: WeekGridLayout.cellSpacing) {
            ForEach(daysInWeek, id: \.self) { date in
                DayColumn(date: date, isToday: AppCalendar.isSameDay(date, .now))
            }
        }
        .padding(.leading, 34)
        .padding(.trailing, 30)
        .padding(.bottom, AppSpacing.s)
    }

    @ViewBuilder
    private var contentArea: some View {
        if visibleHabits.isEmpty {
            WeekEmptyStateCard(onCreate: { sheetRoute = .createMenu })
                .padding(.horizontal, AppSpacing.l)
            Spacer()
        } else {
            List {
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
            .contentMargins(.bottom, 120, for: .scrollContent)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("RESUMEN")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            HStack(spacing: AppSpacing.s) {
                StatTile(label: "Completados", value: completedDisplay, icon: "checkmark.circle.fill")
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
        case .createMenu:
            WHCreationSheet { option in
                handleCreationSelection(option)
            }
            .presentationDetents([.height(380), .medium])
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
                let todayHabits = habits.filter { $0.isLoggable(on: .now) && !$0.isSkipped(on: .now) }
                coverRoute = .focus(habits: todayHabits)
            }
        }
    }

    // MARK: - Actions

    private func toggleCompletion(for habit: Habit, on date: Date) {
        if habit.trackingKind == .quantity {
            sheetRoute = .quantityLog(habit: habit, date: date)
            return
        }

        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }
        let willMark = !habit.isCompleted(on: date)

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            if willMark {
                entriesForDay.forEach { modelContext.delete($0) }
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: nil,
                        source: .manual,
                        value: 1,
                        habit: habit
                    )
                )
            } else {
                entriesForDay.forEach { modelContext.delete($0) }
            }
        }

        AppHaptics.play(willMark ? .selection : .selection)
    }

    private func upsertQuantityEntry(for habit: Habit, on date: Date, value: Double) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            if value <= 0 {
                entriesForDay.forEach { modelContext.delete($0) }
            } else if let entry = entriesForDay.first {
                entry.kind = .completed
                entry.value = value
                entry.completedCount = Int(value.rounded())
                entry.completedAt = nil
                entry.source = .manual
                entriesForDay.dropFirst().forEach { modelContext.delete($0) }
            } else {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: nil,
                        source: .manual,
                        completedCount: Int(value.rounded()),
                        value: value,
                        habit: habit
                    )
                )
            }
        }

        AppHaptics.play(.selection)
    }

    private func toggleRest(for habit: Habit, on date: Date) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }
        let willSkip = !habit.isSkipped(on: date)

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            entriesForDay.forEach { modelContext.delete($0) }

            if willSkip {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: nil,
                        source: AppCalendar.isSameDay(date, .now) ? .today : .manual,
                        kind: .skipped,
                        completedCount: 0,
                        value: 0,
                        habit: habit
                    )
                )
            }
        }

        AppHaptics.play(.selection)
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
    case createMenu
    case quantityLog(habit: Habit, date: Date)

    var id: String {
        switch self {
        case .createMenu: return "createMenu"
        case .quantityLog(let habit, let date): return "quantityLog-\(habit.id)-\(date.timeIntervalSinceReferenceDate)"
        }
    }
}

#Preview {
    WeekView()
}
