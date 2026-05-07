//
//  TodayView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
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
    
    @State private var createHabitRoute: TodayCreateHabitRoute?
    @State private var isShowingCreatePlan = false
    @State private var editHabitRoute: TodayEditHabitRoute?
    @State private var editPlanRoute: TodayEditPlanRoute?
    @State private var habitToDelete: Habit?
    @State private var showDeleteHabitAlert = false
    @State private var planToDelete: Plan?
    @State private var showDeletePlanAlert = false
    @State private var selectedHabit: Habit?
    @State private var expandedPlans: Set<UUID> = []
    @State private var isShowingFocusSession = false
    @State private var quantityHabit: Habit?

    private var referenceDate: Date {
        Date()
    }
    
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
    
    private var todayHabits: [Habit] {
        habits.filter { habit in
            habit.isLoggable(on: referenceDate)
        }
    }
    
    private var tomorrowDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
    }
    
    private var tomorrowHabitsCount: Int {
        habits.filter { habit in
            habit.isLoggable(on: tomorrowDate)
        }.count
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
                            EdgeInsets(top: 15, leading: 16, bottom: 0, trailing: 16)
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
                .listRowSpacing(18)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, 120, for: .scrollContent)
            }
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .fullScreenCover(item: $createHabitRoute) { route in
                switch route {
                case .standard:
                    CreateHabitView()
                case .today(let weekday):
                    CreateHabitView(
                        initialDaysPerWeek: 1,
                        initialActiveDays: [weekday]
                    )
                }
            }
            .fullScreenCover(isPresented: $isShowingCreatePlan) {
                PlanFlowView()
            }
            .fullScreenCover(item: $editHabitRoute) { route in
                CreateHabitView(habitToEdit: route.habit)
            }
            .fullScreenCover(item: $editPlanRoute) { route in
                CreatePlanView(planToEdit: route.plan)
            }
            .fullScreenCover(isPresented: $isShowingFocusSession) {
                FocusSessionView(habits: todayHabits)
            }
            .alert("¿Borrar hábito?", isPresented: $showDeleteHabitAlert) {
                Button("Cancelar", role: .cancel) { habitToDelete = nil }
                Button("Borrar", role: .destructive) { deleteSelectedHabit() }
            } message: {
                Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
            }
            .alert("¿Eliminar plan?", isPresented: $showDeletePlanAlert) {
                Button("Cancelar", role: .cancel) { planToDelete = nil }
                Button("Eliminar", role: .destructive) { deleteSelectedPlan() }
            } message: {
                Text("Los hábitos del plan no serán eliminados.")
            }
            .sheet(item: $quantityHabit) { habit in
                QuantityLogSheet(
                    habit: habit,
                    date: referenceDate,
                    initialValue: habit.totalValue(on: referenceDate)
                ) { value in
                    upsertQuantityEntry(for: habit, on: referenceDate, value: value, source: .today)
                }
                .presentationDetents([.height(310)])
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentDateTitle)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.mutedText)

                Text("Buenos días")
                    .font(AppFont.title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    createHabitRoute = .standard
                } label: {
                    Label("Nuevo hábito", systemImage: "plus.circle")
                }

                Button {
                    isShowingCreatePlan = true
                } label: {
                    Label("Nuevo plan", systemImage: "target")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20).bold())
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Crear")
        }
    }

    private var emptyTodayContent: some View {
        TodayEmptyStateView(
            weekdayName: currentDayNameForSentence,
            tomorrowHabitsCount: tomorrowHabitsCount
        ) {
            createHabitRoute = .today(currentWeekday)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
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
            onStart: { isShowingFocusSession = true }
        )
        .todayListRow()

        HStack {
            Text("Hábitos de hoy")
                .font(AppFont.subtitle2)
            Spacer()
            Text(self.currentDayTitle)
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
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
                    editHabitRoute = TodayEditHabitRoute(habit: habit)
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
            .font(AppFont.subtitle2)
            .foregroundStyle(AppColor.strongText)
            .padding(.top, 10)
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
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
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
                Label("Eliminar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                editPlanRoute = TodayEditPlanRoute(plan: plan)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func toggleCompletion(for habit: Habit) {
        if habit.trackingKind == .quantity {
            quantityHabit = habit
            return
        }

        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if entriesForToday.isEmpty {
                let entry = HabitEntry(
                    date: referenceDate,
                    completedAt: .now,
                    source: .today,
                    value: 1,
                    habit: habit
                )
                modelContext.insert(entry)
            } else {
                entriesForToday.forEach { entry in
                    modelContext.delete(entry)
                }
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

        withAnimation(.easeInOut(duration: 0.2)) {
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

        withAnimation(.easeInOut(duration: 0.2)) {
            modelContext.delete(habitToDelete)
        }

        Task {
            await HabitReminderService.cancelReminder(forHabitID: habitID)
        }

        self.habitToDelete = nil
    }

    private func deleteSelectedPlan() {
        guard let planToDelete else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            modelContext.delete(planToDelete)
        }

        self.planToDelete = nil
    }
}

private enum TodayCreateHabitRoute: Identifiable {
    case standard
    case today(Weekday)
    
    var id: String {
        switch self {
        case .standard:
            return "standard"
        case .today(let weekday):
            return "today-\(weekday.rawValue)"
        }
    }
}

private struct TodayEditHabitRoute: Identifiable {
    let habit: Habit
    var id: UUID { habit.id }
}

private struct TodayEditPlanRoute: Identifiable {
    let plan: Plan
    var id: UUID { plan.id }
}

private extension View {
    func todayListRow(_ insets: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)) -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(insets)
    }
}

#Preview {
    TodayView()
}
