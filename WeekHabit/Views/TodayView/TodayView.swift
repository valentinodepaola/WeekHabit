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

    @Query(sort: \WeeklyReview.reviewedAt, order: .reverse)
    private var weeklyReviews: [WeeklyReview]

    @AppStorage("weeklyReviewWeekdayRaw") private var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue
    @AppStorage(OnceFlag.hasSeenFreezeExplainer.rawValue) private var hasSeenFreezeExplainer = false
    @AppStorage(OnceFlag.hasSeenUrgeTooltip.rawValue) private var hasSeenUrgeTooltip = false

    @State private var coverRoute: TodayCoverRoute?
    @State private var milestoneCover: MilestoneCelebrationPayload?
    @State private var sheetRoute: TodaySheetRoute?
    @State private var deferredNoteEntry: HabitEntry?
    @State private var selectedHabit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteHabitAlert = false
    @State private var planToDelete: Plan?
    @State private var showDeletePlanAlert = false
    @State private var deleteFailure: TodayDeleteFailure?
    @State private var expandedPlans: Set<UUID> = []
    @State private var detailPlan: Plan?
    @State private var latestFreezeExplainerMessage: String?
    @State private var didShowRecoveryPromptThisSession = false
    @Namespace private var habitSectionNamespace

    private var referenceDate: Date { Date() }

    private var currentWeekday: Weekday {
        AppCalendar.weekday(of: referenceDate)
    }

    private var currentDateTitle: String {
        AppFormatters.uppercasedString(
            from: referenceDate,
            format: "EEEE d 'DE' MMMM",
            foldingDiacritics: true
        )
    }

    private var todayHabits: [Habit] {
        habits.loggableToday(on: referenceDate)
    }

    private var pendingHabits: [Habit] { todayHabits.pendingToday(on: referenceDate) }
    private var completedHabits: [Habit] { todayHabits.completedToday(on: referenceDate) }
    private var skippedHabits: [Habit] { todayHabits.skippedToday(on: referenceDate) }
    private var slippedHabits: [Habit] { todayHabits.slippedToday(on: referenceDate) }

    private var weeklyFreezes: [StreakFreeze] {
        let habitIDs = Set(todayHabits.filter { $0.allowsWeeklyFreeze }.map(\.id))
        return streakFreezes.usedInWeek(of: referenceDate, habitIDs: habitIDs)
    }

    private var freezeExplainerMessage: String? {
        guard !hasSeenFreezeExplainer else { return nil }
        return latestFreezeExplainerMessage ?? weeklyFreezes.todayBannerMessage()
    }

    private var tomorrowHabitsCount: Int {
        let tomorrow = AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return habits.loggableToday(on: tomorrow).count
    }

    private var completedTodayCount: Int { todayHabits.completedCountToday(on: referenceDate) }
    private var activeTodayCount: Int { todayHabits.activeCountToday(on: referenceDate) }
    private var remainingTodayCount: Int { pendingHabits.count }
    private var dailyProgress: Double { todayHabits.dailyProgress(on: referenceDate) }
    private var focusCandidateHabits: [Habit] {
        todayHabits.filter {
            !$0.isSkipped(on: referenceDate) && !$0.isSlip(on: referenceDate)
        }
    }

    private var focusDisabledReason: String? {
        focusCandidateHabits.isEmpty ? "No hay hábitos disponibles para hoy." : nil
    }

    private var weeklyReviewWeekStart: Date? {
        WeeklyReviewService.needsReview(
            reference: referenceDate,
            preferredWeekday: Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday,
            existingReviews: weeklyReviews,
            habits: habits
        )
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                List {
                    TodayHeaderSection(
                        dateTitle: currentDateTitle,
                        onCreateTap: { sheetRoute = .createMenu }
                    )
                    .todayListRow(
                        EdgeInsets(top: AppSpacing.l, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
                    )

                    if let weeklyReviewWeekStart {
                        WeeklyReviewBanner(
                            weekRangeText: weekRangeText(for: weeklyReviewWeekStart),
                            onTap: { sheetRoute = .weeklyReview(weekStart: weeklyReviewWeekStart) }
                        )
                        .todayListRow(
                            EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                        )
                    }

                    if todayHabits.isEmpty {
                        emptyTodayContent.todayListRow()
                    } else {
                        TodayHabitListSection(
                            todayHabits: todayHabits,
                            pendingHabits: pendingHabits,
                            completedHabits: completedHabits,
                            skippedHabits: skippedHabits,
                            slippedHabits: slippedHabits,
                            experiments: experiments,
                            referenceDate: referenceDate,
                            progress: dailyProgress,
                            completedCount: completedTodayCount,
                            activeCount: activeTodayCount,
                            remainingCount: remainingTodayCount,
                            slipCount: slippedHabits.count,
                            freezeMessage: freezeExplainerMessage,
                            showsUrgeExplainer: !hasSeenUrgeTooltip,
                            namespace: habitSectionNamespace,
                            reduceMotion: reduceMotion,
                            onDismissFreezeExplainer: {
                                latestFreezeExplainerMessage = nil
                                hasSeenFreezeExplainer = true
                            },
                            onDismissUrgeExplainer: { hasSeenUrgeTooltip = true },
                            actions: habitActions
                        )
                    }

                    if !plans.isEmpty {
                        TodayPlansSection(
                            plans: plans,
                            expandedPlans: $expandedPlans,
                            actions: planActions
                        )
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(AppSpacing.m)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, AppSpacing.xl, for: .scrollContent)
            }
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .fullScreenCover(item: $coverRoute) { route in
                routeCover(route)
            }
            .fullScreenCover(item: $milestoneCover, onDismiss: presentDeferredNoteIfNeeded) { payload in
                MilestoneCelebrationView(habit: payload.habit, milestone: payload.milestone)
            }
            .sheet(item: $sheetRoute) { route in
                routeSheet(route)
            }
            .sheet(item: $detailPlan) { plan in
                PlanDetailView(plan: plan)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.bgCanvas)
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
            .alert(item: $deleteFailure) { failure in
                Alert(
                    title: Text("No se pudo borrar"),
                    message: Text(failure.message),
                    dismissButton: .default(Text("Entendido"))
                )
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

    private var emptyTodayContent: some View {
        TodayEmptyStateView(
            weekdayName: AppFormatters.lowercased(currentWeekday.displayName),
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

    private var todayHabitSectionSignature: String {
        let pending = pendingHabits.map { "p:\($0.id.uuidString)" }
        let completed = completedHabits.map { "c:\($0.id.uuidString)" }
        let skipped = skippedHabits.map { "s:\($0.id.uuidString)" }
        let slipped = slippedHabits.map { "sl:\($0.id.uuidString)" }
        let freezes = weeklyFreezes.map { "f:\($0.id.uuidString)" }
        return (pending + completed + skipped + slipped + freezes).joined(separator: "|")
    }

    // MARK: - Action bindings

    private var habitActions: TodayHabitActions {
        TodayHabitActions(
            toggleCompletion: { toggleCompletion(for: $0) },
            markMinimum: { markMinimumCompleted(for: $0, on: referenceDate) },
            openDetail: { selectedHabit = $0 },
            openUrgeLog: { habit in
                hasSeenUrgeTooltip = true
                sheetRoute = .urgeLog(habit: habit)
            },
            openSlipLog: { sheetRoute = .slipLog(habit: $0) },
            toggleRest: { toggleRest(for: $0) },
            requestDelete: { habit in
                habitToDelete = habit
                showDeleteHabitAlert = true
            },
            openEdit: { coverRoute = .habit(.edit($0)) },
            openSlipContext: { sheetRoute = .slipLog(habit: $0) },
            undoSlip: { undoSlip(for: $0) },
            startFocus: {
                coverRoute = .focus(habits: focusCandidateHabits)
            }
        )
    }

    private var planActions: TodayPlanActions {
        TodayPlanActions(
            onHabitTap: { selectedHabit = $0 },
            onOpenDetail: { detailPlan = $0 },
            onEdit: { coverRoute = .plan(.edit($0)) },
            onDelete: { plan in
                planToDelete = plan
                showDeletePlanAlert = true
            }
        )
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
                onCreateMinimum: { title in
                    createMinimumVersion(for: candidate, title: title)
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
        case .weeklyReview(let weekStart):
            WeeklyReviewView(weekStart: weekStart)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.bgCanvas)
        case .noteEntry(let entry):
            EntryNoteSheet(entry: entry)
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

    private func toggleCompletion(for habit: Habit) {
        if habit.trackingKind == .quantity {
            sheetRoute = .quantityLog(habit: habit, date: referenceDate)
            return
        }

        let willComplete = !habit.isCompleted(on: referenceDate)
        let closesDay = willComplete && remainingTodayCount == 1
        var result: HabitTrackingResult?

        transitionHabitBetweenSections {
            result = HabitTrackingService.toggleCompletion(
                for: habit,
                on: referenceDate,
                source: .today,
                completedAt: .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if closesDay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                AppHaptics.play(.dayClosed)
            }
        }

        if willComplete, let insertedEntry = result?.entry {
            presentLiveMilestoneIfNeeded(
                for: habit,
                on: referenceDate,
                noteEntry: insertedEntry,
                afterDayClosed: closesDay
            )
        }
    }

    private func markMinimumCompleted(for habit: Habit, on date: Date) {
        guard !habit.isCompleted(on: date) else { return }

        let closesDay = AppCalendar.isSameDay(date, referenceDate) && remainingTodayCount == 1

        transitionHabitBetweenSections {
            _ = HabitTrackingService.markMinimum(
                for: habit,
                on: date,
                source: .today,
                completedAt: .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if closesDay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                AppHaptics.play(.dayClosed)
            }
        }

        presentLiveMilestoneIfNeeded(for: habit, on: date, afterDayClosed: closesDay)
    }

    @discardableResult
    private func presentLiveMilestoneIfNeeded(
        for habit: Habit,
        on date: Date,
        noteEntry: HabitEntry? = nil,
        afterDayClosed: Bool = false
    ) -> Bool {
        guard let milestone = habit.crossedMilestone(on: date) else {
            if let noteEntry {
                sheetRoute = .noteEntry(entry: noteEntry)
            }
            return false
        }

        habit.markMilestoneCelebrated(milestone)
        if let noteEntry {
            deferredNoteEntry = noteEntry
        }

        let delay: TimeInterval = afterDayClosed ? 1.75 : 0.6
        let payload = MilestoneCelebrationPayload(habit: habit, milestone: milestone)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            milestoneCover = payload
        }
        return true
    }

    private func presentDeferredNoteIfNeeded() {
        guard let entry = deferredNoteEntry else { return }
        deferredNoteEntry = nil
        scheduleDeferredNotePresentation(entry: entry, attempt: 0)
    }

    private func scheduleDeferredNotePresentation(entry: HabitEntry, attempt: Int) {
        let maxAttempts = 6
        let delay: TimeInterval = attempt == 0 ? 0.25 : 0.4

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if sheetRoute == nil {
                sheetRoute = .noteEntry(entry: entry)
                return
            }
            guard attempt < maxAttempts else { return }
            scheduleDeferredNotePresentation(entry: entry, attempt: attempt + 1)
        }
    }

    private func applyWeeklyFreezes(reference: Date) {
        let insertedFreezes = HabitTrackingService.applyWeeklyFreezes(
            to: habits,
            existing: streakFreezes,
            reference: reference,
            modelContext: modelContext
        )

        if !insertedFreezes.isEmpty && !hasSeenFreezeExplainer {
            latestFreezeExplainerMessage = insertedFreezes.todayBannerMessage()
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

    private func weekRangeText(for weekStart: Date) -> String {
        let weekEnd = AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(AppFormatters.string(from: weekStart, format: "d MMM")) - \(AppFormatters.string(from: weekEnd, format: "d MMM"))"
    }

    private func upsertQuantityEntry(
        for habit: Habit,
        on date: Date,
        value: Double,
        source: HabitEntrySource
    ) {
        let wasCompleted = habit.isCompleted(on: date)
        let closesDay = source == .today
            && AppCalendar.isSameDay(date, referenceDate)
            && !wasCompleted
            && remainingTodayCount == 1
        var result: HabitTrackingResult?

        transitionHabitBetweenSections {
            result = HabitTrackingService.upsertQuantity(
                for: habit,
                on: date,
                value: value,
                source: source,
                completedAt: source == .manual ? nil : .now,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        guard value > 0 else { return }

        if result?.becameCompleted == true {
            AppHaptics.play(.quantityCompleted)
            if closesDay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    AppHaptics.play(.dayClosed)
                }
            }
            if source == .today {
                presentLiveMilestoneIfNeeded(for: habit, on: date, afterDayClosed: closesDay)
            }
        } else if result?.isCompleted == false {
            AppHaptics.play(.quantityLogged)
        }
    }

    private func toggleRest(for habit: Habit) {
        transitionHabitBetweenSections {
            HabitTrackingService.toggleRest(
                for: habit,
                on: referenceDate,
                source: .today,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        AppHaptics.play(.skipToggled)
    }

    private func persistSlip(for habit: Habit, trigger: SlipTrigger?, context: String?) {
        var didCreateSlip = false

        transitionHabitBetweenSections {
            didCreateSlip = HabitTrackingService.recordSlip(
                for: habit,
                on: referenceDate,
                trigger: trigger,
                context: context,
                modelContext: modelContext,
                streakFreezes: streakFreezes
            )
        }

        if didCreateSlip {
            presentReplacementPromptAfterCurrentSheet(for: habit)
        }
    }

    private func persistUrge(for habit: Habit, trigger: SlipTrigger?) {
        HabitTrackingService.recordUrge(
            for: habit,
            on: referenceDate,
            trigger: trigger,
            modelContext: modelContext
        )

        presentReplacementPromptAfterCurrentSheet(for: habit)
    }

    private func undoSlip(for habit: Habit) {
        transitionHabitBetweenSections {
            HabitTrackingService.undoSlip(
                for: habit,
                on: referenceDate,
                modelContext: modelContext
            )
        }
    }

    private func presentReplacementPromptAfterCurrentSheet(for habit: Habit) {
        guard let replacementHabit = habit.replacementHabit else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard coverRoute == nil else { return }
            sheetRoute = .replacementPrompt(breakHabit: habit, replacementHabit: replacementHabit)
        }
    }

    private func persistRecoveryMiss(_ candidate: RecoveryPromptCandidate, reason: HabitFailureReason?) {
        HabitTrackingService.recordRecoveryMiss(
            candidate,
            reason: reason,
            modelContext: modelContext
        )
        saveRecoveryPromptState()
        sheetRoute = nil
    }

    private func createMinimumVersion(for candidate: RecoveryPromptCandidate, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        candidate.habit.minimumViableTitle = trimmed
        HabitTrackingService.recordRecoveryMiss(
            candidate,
            reason: nil,
            modelContext: modelContext
        )
        saveRecoveryPromptState()
        sheetRoute = nil
        AppHaptics.play(.selection)
    }

    private func saveRecoveryPromptState() {
        do {
            try modelContext.save()
        } catch {
            print("WeekHabit recovery prompt save failed: \(error)")
        }
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

        do {
            try withAnimation(AppMotion.smooth) {
                try HabitLifecycleService.delete(habitToDelete, modelContext: modelContext)
            }
        } catch {
            deleteFailure = TodayDeleteFailure(message: error.localizedDescription)
            return
        }

        Task {
            await HabitReminderService.cancelReminder(forHabitID: habitID)
        }

        self.habitToDelete = nil
    }

    private func deleteSelectedPlan() {
        guard let planToDelete else { return }

        do {
            try withAnimation(AppMotion.smooth) {
                try PlanLifecycleService.delete(planToDelete, modelContext: modelContext)
            }
        } catch {
            deleteFailure = TodayDeleteFailure(message: error.localizedDescription)
            return
        }

        self.planToDelete = nil
    }
}

#Preview {
    TodayView()
}
