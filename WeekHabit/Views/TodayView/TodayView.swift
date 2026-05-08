//
//  TodayView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @Query(sort: \Plan.createdAt, order: .reverse)
    private var plans: [Plan]

    @State private var coverRoute: TodayCoverRoute?
    @State private var sheetRoute: TodaySheetRoute?
    @State private var selectedHabit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteHabitAlert = false
    @State private var planToDelete: Plan?
    @State private var showDeletePlanAlert = false
    @State private var expandedPlans: Set<UUID> = []

    private var referenceDate: Date { Date() }

    private var currentWeekday: Weekday {
        AppCalendar.weekday(of: referenceDate)
    }

    private var currentDayTitle: String {
        currentWeekday.displayName
    }

    private var currentDayNameForSentence: String {
        currentDayTitle.lowercased(with: Locale(identifier: "es_MX"))
    }

    private var currentDateTitle: String {
        let locale = Locale(identifier: "es_MX")
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = locale
        formatter.dateFormat = "EEEE d 'DE' MMMM"
        return formatter
            .string(from: referenceDate)
            .folding(options: .diacriticInsensitive, locale: locale)
            .uppercased(with: locale)
    }

    private var contextualGreeting: String {
        let hour = AppCalendar.current.component(.hour, from: referenceDate)
        switch hour {
        case 5..<12: return "Buenos días"
        case 12..<19: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    private var contextualSubtitle: String {
        let today = todayHabits.count
        let tomorrow = tomorrowHabitsCount

        switch (today, tomorrow) {
        case (0, 0): return "Una semana en blanco. Hoy puedes diseñar."
        case (0, _): return "Hoy descansas. Mañana \(tomorrow == 1 ? "te espera 1." : "te esperan \(tomorrow).")"
        case (_, 0): return "Hoy son \(today). Mañana descansas."
        default: return "Hoy son \(today). Mañana \(tomorrow)."
        }
    }

    private var todayHabits: [Habit] {
        habits.filter { $0.isLoggable(on: referenceDate) }
    }

    private var tomorrowDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
    }

    private var tomorrowHabitsCount: Int {
        habits.filter { $0.isLoggable(on: tomorrowDate) }.count
    }

    private var completedTodayCount: Int {
        todayHabits.filter { isCompleteForTodayList($0) }.count
    }

    private var remainingTodayCount: Int {
        max(todayHabits.count - completedTodayCount, 0)
    }

    private var dailyProgress: Double {
        guard !todayHabits.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(todayHabits.count)
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                List {
                    header
                        .todayListRow(
                            EdgeInsets(top: AppSpacing.l, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
                        )

                    if todayHabits.isEmpty {
                        emptyTodayContent
                            .todayListRow()
                    } else {
                        todayHabitsContent
                    }

                    if !plans.isEmpty {
                        plansSection
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(AppSpacing.m)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, 120, for: .scrollContent)
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
            .alert("¿Borrar hábito?", isPresented: $showDeleteHabitAlert) {
                Button("Cancelar", role: .cancel) { habitToDelete = nil }
                Button("Borrar", role: .destructive) { deleteSelectedHabit() }
            } message: {
                Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
            }
            .alert("¿Borrar plan?", isPresented: $showDeletePlanAlert) {
                Button("Cancelar", role: .cancel) { planToDelete = nil }
                Button("Borrar", role: .destructive) { deleteSelectedPlan() }
            } message: {
                Text("Los hábitos del plan no serán eliminados.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(currentDateTitle)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Text(contextualGreeting)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text(contextualSubtitle)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                sheetRoute = .createMenu
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColor.accent)
                    .clipShape(Circle())
                    .appElevation(.low)
            }
            .accessibilityLabel("Crear")
        }
    }

    // MARK: - Empty / Habits

    private var emptyTodayContent: some View {
        TodayEmptyStateView(
            weekdayName: currentDayNameForSentence,
            tomorrowHabitsCount: tomorrowHabitsCount
        ) {
            coverRoute = .habit(.create(prefill: HabitPrefill(
                initialActiveDays: [currentWeekday],
                initialDaysPerWeek: 1
            )))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    @ViewBuilder
    private var todayHabitsContent: some View {
        DailyProgressCard(
            progress: dailyProgress,
            completedCount: completedTodayCount,
            totalCount: todayHabits.count,
            remainingCount: remainingTodayCount
        )
        .todayListRow()

        FocusSessionLauncherCard(
            remainingCount: remainingTodayCount,
            onStart: { coverRoute = .focus(habits: todayHabits) }
        )
        .todayListRow()

        HStack {
            Text("Hábitos de hoy")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(currentDayTitle)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textTertiary)
        }
        .todayListRow()

        ForEach(todayHabits) { habit in
            TodayHabitComponent(
                habit: habit,
                isCompleted: isCompleteForTodayList(habit),
                activeExperiment: experiments.activeExperiment(
                    for: habit.id,
                    reference: referenceDate
                ),
                referenceDate: referenceDate
            ) {
                toggleCompletion(for: habit)
            }
            .todayListRow()
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    habitToDelete = habit
                    showDeleteHabitAlert = true
                } label: {
                    Label("Borrar", systemImage: "trash")
                }
                .tint(AppColor.destructiveAction)

                Button {
                    coverRoute = .habit(.edit(habit))
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                .tint(AppColor.editAction)
            }
        }

        if let top = todayHabits.topStreakHabit(reference: referenceDate) {
            LongestStreakBanner(
                habitTitle: top.habit.title,
                streakDays: top.streak,
                allSameStreak: todayHabits.allShareSameCurrentStreak(reference: referenceDate)
            )
            .todayListRow()
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        Text("Planes")
            .font(AppFont.headline)
            .foregroundStyle(AppColor.textPrimary)
            .padding(.top, AppSpacing.s)
            .todayListRow()

        ForEach(plans) { plan in
            planRow(plan)
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        PlanAccordion(
            plan: plan,
            isExpanded: expandedPlans.contains(plan.id),
            onToggle: {
                withAnimation(AppMotion.smooth) {
                    if expandedPlans.contains(plan.id) {
                        expandedPlans.remove(plan.id)
                    } else {
                        expandedPlans.insert(plan.id)
                    }
                }
            },
            onHabitTap: { habit in
                selectedHabit = habit
            }
        )
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                planToDelete = plan
                showDeletePlanAlert = true
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                coverRoute = .plan(.edit(plan))
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    // MARK: - Routing

    @ViewBuilder
    private func routeCover(_ route: TodayCoverRoute) -> some View {
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
                PlanFlowView()
            case .edit(let plan):
                CreatePlanView(planToEdit: plan)
            }
        case .focus(let habits):
            FocusSessionView(habits: habits)
        }
    }

    @ViewBuilder
    private func routeSheet(_ route: TodaySheetRoute) -> some View {
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
                upsertQuantityEntry(for: habit, on: date, value: value, source: .today)
            }
            .presentationDetents([.height(310)])
        }
    }

    private func handleCreationSelection(_ option: WHCreationOption) {
        sheetRoute = nil
        // Pequeña espera para que el sheet se cierre antes de presentar el cover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            switch option {
            case .habit:
                coverRoute = .habit(.create(prefill: .empty))
            case .plan:
                coverRoute = .plan(.create)
            case .focus:
                coverRoute = .focus(habits: todayHabits)
            }
        }
    }

    // MARK: - Actions

    private func toggleCompletion(for habit: Habit) {
        if habit.trackingKind == .quantity {
            sheetRoute = .quantityLog(habit: habit, date: referenceDate)
            return
        }

        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        let willComplete = entriesForToday.isEmpty

        withAnimation(AppMotion.smooth) {
            if willComplete {
                let entry = HabitEntry(
                    date: referenceDate,
                    completedAt: .now,
                    source: .today,
                    value: 1,
                    habit: habit
                )
                modelContext.insert(entry)
            } else {
                entriesForToday.forEach { modelContext.delete($0) }
            }
        }

        if willComplete && remainingTodayCount == 1 {
            // Era el último; cierre del día.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                AppHaptics.play(.dayClosed)
            }
        }
    }

    private func isCompleteForTodayList(_ habit: Habit) -> Bool {
        if habit.isFlexibleSchedule && habit.completedDaysThisWeek(reference: referenceDate) >= habit.targetDaysPerWeek {
            return true
        }
        return habit.isCompleted(on: referenceDate)
    }

    private func upsertQuantityEntry(
        for habit: Habit,
        on date: Date,
        value: Double,
        source: HabitEntrySource
    ) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }

        withAnimation(AppMotion.smooth) {
            if value <= 0 {
                entriesForDay.forEach { modelContext.delete($0) }
                return
            }

            if let entry = entriesForDay.first {
                entry.value = value
                entry.completedCount = Int(value.rounded())
                entry.completedAt = .now
                entry.source = source
                entriesForDay.dropFirst().forEach { modelContext.delete($0) }
            } else {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: .now,
                        source: source,
                        completedCount: Int(value.rounded()),
                        value: value,
                        habit: habit
                    )
                )
            }
        }
    }

    private func deleteSelectedHabit() {
        guard let habitToDelete else { return }
        let habitID = habitToDelete.id

        withAnimation(AppMotion.smooth) {
            modelContext.delete(habitToDelete)
        }

        Task {
            await HabitReminderService.cancelReminder(forHabitID: habitID)
        }

        self.habitToDelete = nil
    }

    private func deleteSelectedPlan() {
        guard let planToDelete else { return }

        withAnimation(AppMotion.smooth) {
            modelContext.delete(planToDelete)
        }

        self.planToDelete = nil
    }
}

// MARK: - Routes

private enum TodayCoverRoute: Identifiable {
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

private enum TodaySheetRoute: Identifiable {
    case createMenu
    case quantityLog(habit: Habit, date: Date)

    var id: String {
        switch self {
        case .createMenu: return "createMenu"
        case .quantityLog(let habit, _): return "quantityLog-\(habit.id)"
        }
    }
}

// MARK: - Helpers

private extension View {
    func todayListRow(
        _ insets: EdgeInsets = EdgeInsets(top: 0, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
    ) -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(insets)
    }
}

#Preview {
    TodayView()
}
