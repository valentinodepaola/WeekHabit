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

    @Query(sort: \StreakFreeze.usedAt, order: .reverse)
    private var streakFreezes: [StreakFreeze]

    @State private var coverRoute: TodayCoverRoute?
    @State private var sheetRoute: TodaySheetRoute?
    @State private var selectedHabit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteHabitAlert = false
    @State private var planToDelete: Plan?
    @State private var showDeletePlanAlert = false
    @State private var expandedPlans: Set<UUID> = []
    @State private var didShowRecoveryPromptThisSession = false
    @Namespace private var habitSectionNamespace

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
        todayHabits.filter {
            !isCompleteForTodayList($0)
                && !$0.isSkipped(on: referenceDate)
                && !$0.isSlip(on: referenceDate)
        }
    }

    private var completedHabits: [Habit] {
        todayHabits.filter {
            isCompleteForTodayList($0)
                && !$0.isSkipped(on: referenceDate)
                && !$0.isSlip(on: referenceDate)
        }
    }

    private var skippedHabits: [Habit] {
        todayHabits.filter { $0.isSkipped(on: referenceDate) }
    }

    private var slippedHabits: [Habit] {
        todayHabits.filter { $0.isSlip(on: referenceDate) }
    }

    private var weeklyFreezes: [StreakFreeze] {
        let habitIDs = Set(todayHabits.filter { $0.allowsWeeklyFreeze }.map(\.id))
        let weekStart = AppCalendar.weekRange(containing: referenceDate).lowerBound
        return streakFreezes
            .filter { habitIDs.contains($0.habitID) && AppCalendar.isSameDay($0.weekStartDate, weekStart) }
            .sorted { $0.protectedDate < $1.protectedDate }
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

    private var activeTodayCount: Int {
        max(todayHabits.count - skippedHabits.count, 0)
    }

    private var remainingTodayCount: Int {
        pendingHabits.count
    }

    private var dailyProgress: Double {
        guard activeTodayCount > 0 else { return 0 }
        return Double(completedTodayCount) / Double(activeTodayCount)
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
            .animation(
                AppMotion.respectful(AppMotion.gentle, reduceMotion),
                value: todayHabitSectionSignature
            )
            .task {
                applyWeeklyFreezes(reference: referenceDate)
                presentRecoveryPromptIfNeeded()
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
        DailyProgressCard(
            progress: dailyProgress,
            completedCount: completedTodayCount,
            totalCount: activeTodayCount,
            remainingCount: remainingTodayCount,
            slipCount: slippedHabits.count
        )
        .todayListRow(
            EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
        )

        if let freezeMessage = weeklyFreezeMessage {
            TodayFreezeBanner(message: freezeMessage)
                .todayListRow(
                    EdgeInsets(top: 0, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                )
        }

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
                referenceDate: referenceDate,
                onUrge: habit.isBreakHabit ? {
                    sheetRoute = .urgeLog(habit: habit)
                } : nil,
                onSlip: habit.isBreakHabit ? {
                    sheetRoute = .slipLog(habit: habit)
                } : nil
            ) {
                toggleCompletion(for: habit)
            }
            .todayHabitSectionMotion(habit.id, in: habitSectionNamespace, reduceMotion: reduceMotion)
            .todayListRow()
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    toggleRest(for: habit)
                } label: {
                    Label("Hoy descanso", systemImage: "pause.circle")
                }
                .tint(habit.habitColor)

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
            onStart: {
                coverRoute = .focus(habits: todayHabits.filter {
                    !$0.isSkipped(on: referenceDate) && !$0.isSlip(on: referenceDate)
                })
            }
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
                .todayHabitSectionMotion(habit.id, in: habitSectionNamespace, reduceMotion: reduceMotion)
                .todayListRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        toggleRest(for: habit)
                    } label: {
                        Label("Hoy descanso", systemImage: "pause.circle")
                    }
                    .tint(habit.habitColor)

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

        if !slippedHabits.isEmpty {
            sectionHeader(title: "Slips registrados", count: slippedHabits.count)
                .padding(.top, AppSpacing.xl)
                .todayListRow()

            ForEach(slippedHabits) { habit in
                TodaySlipHabitRow(
                    habit: habit,
                    metadata: slipMetadata(for: habit),
                    onEdit: {
                        sheetRoute = .slipLog(habit: habit)
                    },
                    onUndo: {
                        undoSlip(for: habit)
                    }
                )
                .todayHabitSectionMotion(habit.id, in: habitSectionNamespace, reduceMotion: reduceMotion)
                .todayListRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        undoSlip(for: habit)
                    } label: {
                        Label("Deshacer slip", systemImage: "arrow.uturn.backward.circle")
                    }
                    .tint(AppColor.warning)

                    Button {
                        sheetRoute = .slipLog(habit: habit)
                    } label: {
                        Label("Editar contexto", systemImage: "pencil")
                    }
                    .tint(AppColor.editAction)
                }
            }
        }

        if !skippedHabits.isEmpty {
            sectionHeader(title: "Descansos", count: skippedHabits.count)
                .padding(.top, AppSpacing.xl)
                .todayListRow()

            ForEach(skippedHabits) { habit in
                TodayHabitComponent(
                    habit: habit,
                    isCompleted: false,
                    isSkipped: true,
                    activeExperiment: experiments.activeExperiment(
                        for: habit.id,
                        reference: referenceDate
                    ),
                    referenceDate: referenceDate
                ) {
                    toggleCompletion(for: habit)
                }
                .todayHabitSectionMotion(habit.id, in: habitSectionNamespace, reduceMotion: reduceMotion)
                .todayListRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        toggleRest(for: habit)
                    } label: {
                        Label("Quitar descanso", systemImage: "arrow.uturn.backward.circle")
                    }
                    .tint(habit.habitColor)

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

    private var todayHabitSectionSignature: String {
        let pending = pendingHabits.map { "p:\($0.id.uuidString)" }
        let completed = completedHabits.map { "c:\($0.id.uuidString)" }
        let skipped = skippedHabits.map { "s:\($0.id.uuidString)" }
        let slipped = slippedHabits.map { "sl:\($0.id.uuidString)" }
        let freezes = weeklyFreezes.map { "f:\($0.id.uuidString)" }
        return (pending + completed + skipped + slipped + freezes).joined(separator: "|")
    }

    private var weeklyFreezeMessage: String? {
        guard let freeze = weeklyFreezes.first else { return nil }
        let weekday = weekdayName(for: freeze.protectedDate)

        if weeklyFreezes.count == 1 {
            return "Comodín usado el \(weekday). Tu racha sigue viva."
        }

        return "\(weeklyFreezes.count) comodines usados esta semana. Tu racha sigue viva."
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
        case .slipLog(let habit):
            SlipLogSheet(
                habit: habit,
                existingEntry: habit.slipEntry(on: referenceDate)
            ) { trigger, context in
                persistSlip(for: habit, trigger: trigger, context: context)
            }
            .presentationDetents([.height(560), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .urgeLog(let habit):
            UrgeLogSheet(habit: habit) { trigger in
                persistUrge(for: habit, trigger: trigger)
            }
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .recoveryPrompt(let candidate):
            RecoveryPromptView(
                candidate: candidate,
                referenceDate: referenceDate,
                onSave: { reason in
                    persistRecoveryMiss(candidate, reason: reason)
                },
                onSkip: {
                    persistRecoveryMiss(candidate, reason: nil)
                }
            )
            .presentationDetents([.height(570), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .replacementPrompt(let breakHabit, let replacementHabit):
            ReplacementPromptView(
                breakHabit: breakHabit,
                replacementHabit: replacementHabit,
                onStart: {
                    sheetRoute = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        coverRoute = .focus(habits: [replacementHabit])
                    }
                },
                onSkip: {
                    sheetRoute = nil
                }
            )
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
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
                coverRoute = .focus(habits: todayHabits.filter {
                    !$0.isSkipped(on: referenceDate) && !$0.isSlip(on: referenceDate)
                })
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
            AppCalendar.isSameDay($0.date, referenceDate) && $0.kind == .completed
        }
        let stateEntriesForToday = entriesForToday.filter { $0.kind != .urge }

        let willComplete = !habit.isCompleted(on: referenceDate)

        transitionHabitBetweenSections {
            if willComplete {
                stateEntriesForToday.forEach { modelContext.delete($0) }
                let entry = HabitEntry(
                    date: referenceDate,
                    completedAt: .now,
                    source: .today,
                    value: 1,
                    habit: habit
                )
                modelContext.insert(entry)
            } else {
                entriesForToday
                    .filter { $0.kind == .completed }
                    .forEach { modelContext.delete($0) }
            }
        }

        if willComplete && remainingTodayCount == 1 {
            // Era el último; cierre del día.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                AppHaptics.play(.dayClosed)
            }
        }
    }

    private func applyWeeklyFreezes(reference: Date) {
        for habit in habits where habit.allowsWeeklyFreeze {
            guard let protectedDate = habit.weeklyFreezeCandidate(reference: reference),
                  !streakFreezes.containsFreeze(for: habit, weekContaining: protectedDate) else {
                continue
            }

            modelContext.insert(StreakFreeze(habit: habit, protectedDate: protectedDate))
        }
    }

    private func presentRecoveryPromptIfNeeded() {
        guard !didShowRecoveryPromptThisSession,
              sheetRoute == nil,
              coverRoute == nil,
              let candidate = habits.recoveryPromptCandidate(reference: referenceDate) else {
            return
        }

        didShowRecoveryPromptThisSession = true
        sheetRoute = .recoveryPrompt(candidate)
    }

    private func weekdayName(for date: Date) -> String {
        AppCalendar.weekday(of: date)
            .displayName
            .lowercased(with: Locale(identifier: "es_MX"))
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

    private func slipMetadata(for habit: Habit) -> String {
        guard let entry = habit.slipEntry(on: referenceDate) else {
            return "Slip registrado"
        }

        var parts: [String] = []

        if let completedAt = entry.completedAt {
            let formatter = DateFormatter()
            formatter.calendar = AppCalendar.current
            formatter.locale = Locale(identifier: "es_MX")
            formatter.dateFormat = "HH:mm"
            parts.append(formatter.string(from: completedAt))
        }

        if let trigger = entry.slipTrigger {
            parts.append(trigger.title)
        }

        let trimmedContext = entry.slipContext?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedContext.isEmpty {
            parts.append(trimmedContext)
        }

        return parts.isEmpty ? "Slip registrado" : parts.joined(separator: " · ")
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
        let stateEntriesForDay = entriesForDay.filter { $0.kind != .urge }

        transitionHabitBetweenSections {
            if value <= 0 {
                entriesForDay
                    .filter { $0.kind == .completed }
                    .forEach { modelContext.delete($0) }
                return
            }

            if let entry = stateEntriesForDay.first {
                entry.kind = .completed
                entry.value = value
                entry.completedCount = Int(value.rounded())
                entry.completedAt = .now
                entry.source = source
                stateEntriesForDay.dropFirst().forEach { modelContext.delete($0) }
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

    private func toggleRest(for habit: Habit) {
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }
        let stateEntriesForToday = entriesForToday.filter { $0.kind != .urge }
        let willSkip = !habit.isSkipped(on: referenceDate)

        transitionHabitBetweenSections {
            stateEntriesForToday.forEach { modelContext.delete($0) }

            if willSkip {
                modelContext.insert(
                    HabitEntry(
                        date: referenceDate,
                        completedAt: nil,
                        source: .today,
                        kind: .skipped,
                        completedCount: 0,
                        value: 0,
                        habit: habit
                    )
                )
            }
        }
    }

    private func persistSlip(for habit: Habit, trigger: SlipTrigger?, context: String?) {
        guard habit.isBreakHabit else { return }

        let hadSlipBefore = habit.isSlip(on: referenceDate)
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }
        let stateEntriesForToday = entriesForToday.filter { $0.kind != .urge }

        transitionHabitBetweenSections {
            if let existingSlip = stateEntriesForToday.first(where: { $0.kind == .slip }) {
                existingSlip.completedAt = existingSlip.completedAt ?? .now
                existingSlip.source = .today
                existingSlip.completedCount = 0
                existingSlip.value = 0
                existingSlip.slipTrigger = trigger
                existingSlip.slipContext = context
                stateEntriesForToday
                    .filter { $0.id != existingSlip.id }
                    .forEach { modelContext.delete($0) }
            } else {
                stateEntriesForToday.forEach { modelContext.delete($0) }
                modelContext.insert(
                    HabitEntry(
                        date: referenceDate,
                        completedAt: .now,
                        source: .today,
                        kind: .slip,
                        completedCount: 0,
                        value: 0,
                        slipTrigger: trigger,
                        slipContext: context,
                        habit: habit
                    )
                )
            }

            deleteFreeze(for: habit, on: referenceDate)
        }

        if !hadSlipBefore {
            presentReplacementPromptAfterCurrentSheet(for: habit)
        }
    }

    private func persistUrge(for habit: Habit, trigger: SlipTrigger?) {
        guard habit.isBreakHabit else { return }

        modelContext.insert(
            HabitEntry(
                date: referenceDate,
                completedAt: .now,
                source: .today,
                kind: .urge,
                completedCount: 0,
                value: 0,
                slipTrigger: trigger,
                habit: habit
            )
        )

        presentReplacementPromptAfterCurrentSheet(for: habit)
    }

    private func undoSlip(for habit: Habit) {
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate) && $0.kind == .slip
        }

        transitionHabitBetweenSections {
            entriesForToday.forEach { modelContext.delete($0) }
        }
    }

    private func presentReplacementPromptAfterCurrentSheet(for habit: Habit) {
        guard let replacementHabit = habit.replacementHabit else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard coverRoute == nil else { return }
            sheetRoute = .replacementPrompt(breakHabit: habit, replacementHabit: replacementHabit)
        }
    }

    private func deleteFreeze(for habit: Habit, on date: Date) {
        streakFreezes
            .filter { $0.habitID == habit.id && AppCalendar.isSameDay($0.protectedDate, date) }
            .forEach { modelContext.delete($0) }
    }

    private func persistRecoveryMiss(_ candidate: RecoveryPromptCandidate, reason: HabitFailureReason?) {
        let entriesForDay = candidate.habit.entries.filter {
            AppCalendar.isSameDay($0.date, candidate.date)
        }
        let stateEntriesForDay = entriesForDay.filter { $0.kind != .urge }

        if let existingMiss = stateEntriesForDay.first(where: { $0.kind == .missed }) {
            existingMiss.failureReasonKind = reason
            stateEntriesForDay
                .filter { $0.kind == .missed && $0.id != existingMiss.id }
                .forEach { modelContext.delete($0) }
            sheetRoute = nil
            return
        }

        guard stateEntriesForDay.isEmpty else {
            sheetRoute = nil
            return
        }

        modelContext.insert(
            HabitEntry(
                date: candidate.date,
                completedAt: nil,
                source: .today,
                kind: .missed,
                completedCount: 0,
                value: 0,
                failureReason: reason,
                habit: candidate.habit
            )
        )
        sheetRoute = nil
    }

    private func transitionHabitBetweenSections(_ mutation: @escaping () -> Void) {
        guard let animation = AppMotion.respectful(AppMotion.gentle, reduceMotion) else {
            withoutTodayListAnimation(mutation)
            return
        }

        withAnimation(animation) {
            mutation()
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
    case slipLog(habit: Habit)
    case urgeLog(habit: Habit)
    case recoveryPrompt(RecoveryPromptCandidate)
    case replacementPrompt(breakHabit: Habit, replacementHabit: Habit)

    var id: String {
        switch self {
        case .createMenu: return "createMenu"
        case .quantityLog(let habit, _): return "quantityLog-\(habit.id)"
        case .slipLog(let habit): return "slipLog-\(habit.id)"
        case .urgeLog(let habit): return "urgeLog-\(habit.id)"
        case .recoveryPrompt(let candidate): return "recoveryPrompt-\(candidate.id)"
        case .replacementPrompt(let breakHabit, let replacementHabit):
            return "replacementPrompt-\(breakHabit.id)-\(replacementHabit.id)"
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

    @ViewBuilder
    func todayHabitSectionMotion(
        _ habitID: UUID,
        in namespace: Namespace.ID,
        reduceMotion: Bool
    ) -> some View {
        if reduceMotion {
            self
        } else {
            matchedGeometryEffect(
                id: "today-habit-\(habitID.uuidString)",
                in: namespace,
                properties: .frame,
                anchor: .center
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.985, anchor: .center)),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.985, anchor: .center))
                )
            )
            .zIndex(1)
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

            completedIconBadge
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(AppColor.bgElevated.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(AppColor.divider.opacity(0.7), lineWidth: 1)
        }
    }

    private var completedIconBadge: some View {
        ZStack {
            Circle()
                .fill(habit.habitColor.opacity(0.14))

            Image(systemName: habit.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(habit.habitColor)
        }
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
    }
}

private struct TodaySlipHabitRow: View {
    let habit: Habit
    let metadata: String
    let onEdit: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColor.warning)
                .frame(width: 32, height: 32)
                .background(AppColor.warning.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                        .strokeBorder(AppColor.warning.opacity(0.34), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(habit.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(metadata)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: AppSpacing.xs) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.editAction)
                        .frame(width: 32, height: 32)
                        .background(AppColor.editAction.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Editar contexto de \(habit.title)")

                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.warning)
                        .frame(width: 32, height: 32)
                        .background(AppColor.warning.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deshacer slip de \(habit.title)")
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(AppColor.warning.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct TodayFreezeBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.info)
                .frame(width: 30, height: 30)
                .background(AppColor.info.opacity(0.14))
                .clipShape(Circle())

            Text(message)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.info.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.info.opacity(0.22), lineWidth: 1)
        }
    }
}

#Preview {
    TodayView()
}
