//
//  TodayView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    @State private var outgoingHabitIDs: Set<UUID> = []
    @State private var incomingHabitIDs: Set<UUID> = []

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

    private var todayHabits: [Habit] {
        habits.filter { $0.isLoggable(on: referenceDate) }
    }

    private var pendingHabits: [Habit] {
        todayHabits.filter { !isCompleteForTodayList($0) }
    }

    private var completedHabits: [Habit] {
        todayHabits.filter { isCompleteForTodayList($0) }
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

                Text("Hoy")
                    .font(AppFont.title.bold())
                    .foregroundStyle(AppColor.textPrimary)
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
        sectionHeader(title: "Pendientes", count: pendingHabits.count)
            .todayListRow(
                EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
            )

        ForEach(pendingHabits) { habit in
            TodayHabitComponent(
                habit: habit,
                isCompleted: false,
                activeExperiment: experiments.activeExperiment(
                    for: habit.id,
                    reference: referenceDate
                ),
                referenceDate: referenceDate
            ) {
                toggleCompletion(for: habit)
            }
            .todayCompletionTransition(transitionPhase(for: habit))
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

        FocusSessionLauncherCard(
            remainingCount: remainingTodayCount,
            onStart: { coverRoute = .focus(habits: todayHabits) }
        )
        .todayListRow()

        if !completedHabits.isEmpty {
            sectionHeader(title: "Completados", count: completedHabits.count)
                .padding(.top, AppSpacing.xl)
                .todayListRow()

            ForEach(completedHabits) { habit in
                TodayCompletedHabitRow(
                    habit: habit,
                    metadata: completionMetadata(for: habit)
                ) {
                    toggleCompletion(for: habit)
                }
                .todayCompletionTransition(transitionPhase(for: habit))
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

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Text(habitCountText(count))
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func habitCountText(_ count: Int) -> String {
        count == 1 ? "1 hábito" : "\(count) hábitos"
    }

    private func transitionPhase(for habit: Habit) -> TodayCompletionTransitionPhase {
        if outgoingHabitIDs.contains(habit.id) {
            return .outgoing
        }

        if incomingHabitIDs.contains(habit.id) {
            return .incoming
        }

        return .idle
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
                CreatePlanView()
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

        transitionHabitBetweenSections(habit.id) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
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

    private func completionMetadata(for habit: Habit) -> String {
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        guard let entry = entriesForToday.sorted(by: { lhs, rhs in
            (lhs.completedAt ?? lhs.date) > (rhs.completedAt ?? rhs.date)
        }).first else {
            return "Meta semanal alcanzada"
        }

        let sourceText: String
        switch entry.source {
        case .today:
            sourceText = "marca confiable"
        case .focusSession:
            sourceText = "sesión de ritmo"
        case .manual:
            sourceText = "registrado después"
        }

        guard let completedAt = entry.completedAt else {
            return sourceText
        }

        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: completedAt)) · \(sourceText)"
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

        withoutTodayListAnimation {
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

    private func transitionHabitBetweenSections(_ habitID: UUID, mutation: @escaping () -> Void) {
        guard !reduceMotion else {
            withoutTodayListAnimation(mutation)
            return
        }

        withAnimation(AppMotion.linearOut) {
            _ = outgoingHabitIDs.insert(habitID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withoutTodayListAnimation {
                _ = incomingHabitIDs.insert(habitID)
                mutation()
                _ = outgoingHabitIDs.remove(habitID)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                withAnimation(AppMotion.linearOut) {
                    _ = incomingHabitIDs.remove(habitID)
                }
            }
        }
    }

    private func withoutTodayListAnimation(_ mutation: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            mutation()
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

    func todayCompletionTransition(_ phase: TodayCompletionTransitionPhase) -> some View {
        opacity(phase.opacity)
            .scaleEffect(phase.scale, anchor: .center)
            .allowsHitTesting(phase == .idle)
    }
}

private enum TodayCompletionTransitionPhase {
    case idle
    case outgoing
    case incoming

    var opacity: Double {
        switch self {
        case .idle:
            return 1
        case .outgoing, .incoming:
            return 0
        }
    }

    var scale: CGFloat {
        switch self {
        case .idle:
            return 1
        case .outgoing:
            return 0.97
        case .incoming:
            return 0.985
        }
    }
}

private struct TodayCompletedHabitRow: View {
    let habit: Habit
    let metadata: String
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            Button(action: onToggle) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(habit.habitColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Desmarcar \(habit.title)")

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(habit.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textSecondary)
                    .strikethrough(true, color: AppColor.textSecondary)
                    .lineLimit(1)

                Text(metadata)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.s)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    }
}

#Preview {
    TodayView()
}
