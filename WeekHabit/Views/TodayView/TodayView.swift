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
    @State private var isSearchVisible = false
    @State private var searchText = ""

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
        formatter.dateFormat = "EEEE d"
        let dayText = formatter
            .string(from: referenceDate)
            .folding(options: .diacriticInsensitive, locale: locale)
            .uppercased(with: locale)
        let weekNumber = AppCalendar.current.component(.weekOfYear, from: referenceDate)
        return "\(dayText) · SEMANA \(weekNumber)"
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

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var visibleTodayHabits: [Habit] {
        guard !normalizedSearchText.isEmpty else { return todayHabits }

        return todayHabits.filter { habit in
            searchMatches([habit.title, habit.cue, habit.note])
        }
    }

    private var pendingTodayHabits: [Habit] {
        visibleTodayHabits.filter { !isCompleteForTodayList($0) }
    }

    private var completedTodayHabits: [Habit] {
        visibleTodayHabits.filter { isCompleteForTodayList($0) }
    }

    private var visiblePlans: [Plan] {
        guard !normalizedSearchText.isEmpty else { return plans }

        return plans.filter { plan in
            searchMatches([plan.title, plan.motivation])
        }
    }

    private var topStreakDays: Int {
        todayHabits.topStreakHabit(reference: referenceDate)?.streak ?? 0
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                List {
                    header
                        .todayListRow(
                            EdgeInsets(top: 18, leading: 24, bottom: 0, trailing: 24)
                        )

                    if isSearchVisible {
                        searchField
                            .todayListRow(
                                EdgeInsets(top: 10, leading: 24, bottom: 2, trailing: 24)
                            )
                    }

                    if todayHabits.isEmpty {
                        emptyTodayContent
                            .todayListRow()
                    } else {
                        todayHabitsContent
                    }

                    if !visiblePlans.isEmpty {
                        plansSection
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(8)
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(currentDateTitle)
                    .font(AppFont.captionApp)
                    .fontWeight(.bold)
                    .tracking(1.8)
                    .foregroundStyle(AppColor.mutedText)

                Text("Hoy")
                    .font(.system(size: 27, weight: .bold, design: .default))
                    .foregroundStyle(AppColor.strongText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                    isSearchVisible.toggle()
                    if !isSearchVisible {
                        searchText = ""
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.mutedText)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColor.surfaceMuted, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buscar")

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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColor.strongText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel("Crear")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.subtleText)

            TextField("Buscar hábitos o planes", text: $searchText)
                .font(AppFont.body2)
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.subtleText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpiar búsqueda")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.surfaceMuted, lineWidth: 1)
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
            remainingCount: remainingTodayCount,
            streakDays: topStreakDays
        )
        .todayListRow()

        sectionHeader("Pendientes", count: pendingTodayHabits.count)
            .todayListRow(
                EdgeInsets(top: 22, leading: 24, bottom: 2, trailing: 24)
            )

        ForEach(pendingTodayHabits) { habit in
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

        FocusSessionLauncherCard(
            remainingCount: remainingTodayCount,
            onStart: { isShowingFocusSession = true }
        )
        .todayListRow(EdgeInsets(top: 4, leading: 24, bottom: 10, trailing: 24))

        if !completedTodayHabits.isEmpty {
            sectionHeader("Completado", count: completedTodayHabits.count)
                .todayListRow(
                    EdgeInsets(top: 18, leading: 24, bottom: 8, trailing: 24)
                )

            ForEach(completedTodayHabits) { habit in
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
                .todayListRow(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
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
        }

        if !normalizedSearchText.isEmpty && visibleTodayHabits.isEmpty {
            Text("Sin hábitos para esta búsqueda.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .todayListRow(EdgeInsets(top: 2, leading: 24, bottom: 4, trailing: 24))
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        sectionHeader("Plan en curso", detail: plansHeaderDetail)
            .todayListRow(
                EdgeInsets(top: 20, leading: 24, bottom: 2, trailing: 24)
            )

        ForEach(visiblePlans) { plan in
            planRow(plan)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        sectionHeader(title, detail: habitCountText(count))
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(AppColor.strongText)

            Spacer(minLength: 12)

            Text(detail)
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
        }
    }

    private var plansHeaderDetail: String {
        if visiblePlans.count == 1, let plan = visiblePlans.first {
            return plan.daysRemainingText
        }

        return "\(visiblePlans.count) \(visiblePlans.count == 1 ? "plan" : "planes")"
    }

    private func habitCountText(_ count: Int) -> String {
        "\(count) \(count == 1 ? "hábito" : "hábitos")"
    }

    private func searchMatches(_ fields: [String?]) -> Bool {
        let query = normalizedSearchText.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_MX")
        )

        return fields.contains { field in
            guard let field else { return false }
            return field
                .folding(
                    options: [.diacriticInsensitive, .caseInsensitive],
                    locale: Locale(identifier: "es_MX")
                )
                .contains(query)
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
    func todayListRow(_ insets: EdgeInsets = EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)) -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(insets)
    }
}

#Preview {
    TodayView()
}
