//
//  TodayView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @Query(sort: \Habit.createdAt, order: .reverse)
    var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    var experiments: [HabitExperiment]

    @Query(sort: \Plan.createdAt, order: .reverse)
    var plans: [Plan]

    @Query(sort: \StreakFreeze.usedAt, order: .reverse)
    var streakFreezes: [StreakFreeze]

    @Query(sort: \WeeklyReview.reviewedAt, order: .reverse)
    var weeklyReviews: [WeeklyReview]

    @AppStorage("weeklyReviewWeekdayRaw") var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue
    @AppStorage(OnceFlag.hasSeenFreezeExplainer.rawValue) var hasSeenFreezeExplainer = false
    @AppStorage(OnceFlag.hasSeenUrgeTooltip.rawValue) var hasSeenUrgeTooltip = false
    @AppStorage(OnceFlag.hasSeenTodayHelp.rawValue) var hasSeenTodayHelp = false
    /// Último día en que la hoja de recuperación se auto-presentó, como intervalo desde la fecha
    /// de referencia; `0` es "nunca". No cabe en `OnceFlag`: ese enum son banderas booleanas de
    /// "ya lo vio una vez", y esta es una fecha que se renueva cada día.
    @AppStorage("recoveryPromptLastAutoPresentedDay") var recoveryPromptLastAutoPresentedDay: Double = 0

    @State var model = TodayScreenModel()
    @Namespace var habitSectionNamespace

    var referenceDate: Date { Date() }

    var lastRecoveryPromptDay: Date? {
        guard recoveryPromptLastAutoPresentedDay > 0 else { return nil }
        return Date(timeIntervalSinceReferenceDate: recoveryPromptLastAutoPresentedDay)
    }

    var currentWeekday: Weekday {
        AppCalendar.weekday(of: referenceDate)
    }

    var currentDateTitle: String {
        AppFormatters.uppercasedString(
            from: referenceDate,
            format: "EEEE d 'DE' MMMM",
            foldingDiacritics: true
        )
    }

    /// Los datos derivados se construyen una sola vez por render y se pasan a las secciones
    /// y a las acciones. Ver `TodayViewData`.
    func makeData(on date: Date) -> TodayViewData {
        TodayViewData(
            habits: habits,
            streakFreezes: streakFreezes,
            weeklyReviews: weeklyReviews,
            weeklyReviewWeekday: Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday,
            referenceDate: date
        )
    }

    var body: some View {
        let date = referenceDate
        let data = makeData(on: date)

        NavigationStack {
            AppBackground {
                List {
                    TodayHeaderSection(
                        dateTitle: currentDateTitle,
                        onHelpTap: {
                            hasSeenTodayHelp = true
                            model.sheetRoute = .help
                        },
                        onCreateTap: { model.sheetRoute = .createMenu }
                    )
                    .todayListRow(
                        EdgeInsets(top: AppSpacing.l, leading: AppSpacing.l, bottom: 0, trailing: AppSpacing.l)
                    )

                    if let weeklyReviewWeekStart = data.weeklyReviewWeekStart {
                        WeeklyReviewBanner(
                            weekRangeText: weekRangeText(for: weeklyReviewWeekStart),
                            onTap: { model.sheetRoute = .weeklyReview(weekStart: weeklyReviewWeekStart) }
                        )
                        .todayListRow(
                            EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                        )
                    }

                    if !data.recoveryCandidates.isEmpty {
                        RecoveryPromptBanner(
                            pendingCount: data.recoveryCandidates.count,
                            onTap: { model.sheetRoute = .recoveryPrompt(date: AppCalendar.startOfDay(for: date)) }
                        )
                        .todayListRow(
                            EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l)
                        )
                    }

                    if data.isEmpty {
                        emptyTodayContent(tomorrowHabitsCount: data.tomorrowHabitsCount)
                            .todayListRow()
                    } else {
                        TodayHabitListSection(
                            todayHabits: data.todayHabits,
                            pendingHabits: data.partition.pending,
                            completedHabits: data.partition.completed,
                            skippedHabits: data.partition.skipped,
                            slippedHabits: data.partition.slipped,
                            experiments: experiments,
                            referenceDate: date,
                            progress: data.partition.progress,
                            completedCount: data.partition.completedCount,
                            activeCount: data.partition.activeCount,
                            remainingCount: data.remainingCount,
                            slipCount: data.partition.slipped.count,
                            freezeMessage: freezeExplainerMessage(for: data),
                            showsUrgeExplainer: !hasSeenUrgeTooltip,
                            namespace: habitSectionNamespace,
                            reduceMotion: reduceMotion,
                            onDismissFreezeExplainer: {
                                model.latestFreezeExplainerMessage = nil
                                hasSeenFreezeExplainer = true
                            },
                            onDismissUrgeExplainer: { hasSeenUrgeTooltip = true },
                            actions: habitActions(data: data, on: date)
                        )
                    }

                    if !plans.isEmpty {
                        TodayPlansSection(
                            plans: plans,
                            expandedPlans: $model.expandedPlans,
                            actions: planActions
                        )
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(AppSpacing.m)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, AppSpacing.xl, for: .scrollContent)
            }
            .navigationDestination(item: $model.selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .fullScreenCover(item: $model.coverRoute) { route in
                routeCover(route)
            }
            .fullScreenCover(item: $model.milestoneCover) { payload in
                MilestoneCelebrationView(habit: payload.habit, milestone: payload.milestone)
            }
            .sheet(item: $model.sheetRoute) { route in
                routeSheet(route, data: data, on: date)
            }
            .sheet(item: $model.detailPlan) { plan in
                PlanDetailView(plan: plan)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColor.bgCanvas)
            }
            .alert("¿Borrar hábito?", isPresented: $model.isConfirmingHabitDeletion) {
                Button("Cancelar", role: .cancel) { model.habitToDelete = nil }
                Button("Borrar", role: .destructive) { deleteSelectedHabit() }
            } message: {
                Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
            }
            .alert("¿Borrar plan?", isPresented: $model.isConfirmingPlanDeletion) {
                Button("Cancelar", role: .cancel) { model.planToDelete = nil }
                Button("Borrar", role: .destructive) { deleteSelectedPlan() }
            } message: {
                Text("Los hábitos del plan no serán eliminados.")
            }
            .alert(item: $model.failure) { failure in
                Alert(
                    title: Text(failure.title),
                    message: Text(failure.message),
                    dismissButton: .default(Text("Entendido"))
                )
            }
            .animation(
                AppMotion.respectful(AppMotion.gentle, reduceMotion),
                value: data.sectionSignature
            )
            .task {
                applyWeeklyFreezes(reference: date)
                // La hoja se auto-presenta una vez por día natural: si el usuario ya la cerró hoy,
                // vuelve por el banner, no sola.
                // Los candidatos se recalculan acá y no se leen de `data`: `data` es de este
                // render, o sea de **antes** de `applyWeeklyFreezes`, y un día que el comodín
                // acaba de cubrir ya no es un pendiente. Con el valor de `data` la hoja se abría
                // con una lista vacía.
                if model.presentRecoveryPromptIfNeeded(
                    lastAutoPresentedDay: lastRecoveryPromptDay,
                    reference: date,
                    hasCandidates: !habits.recoveryPromptCandidates(reference: date).isEmpty
                ) {
                    recoveryPromptLastAutoPresentedDay = AppCalendar
                        .startOfDay(for: date)
                        .timeIntervalSinceReferenceDate
                }
                // La ayuda cede el turno: si la recuperación ya ocupó la hoja, el flag no se marca
                // y vuelve a intentarlo en el próximo arranque.
                if !hasSeenTodayHelp, model.presentHelpIfPossible() {
                    hasSeenTodayHelp = true
                }
            }
        }
    }

    func emptyTodayContent(tomorrowHabitsCount: Int) -> some View {
        TodayEmptyStateView(
            weekdayName: AppFormatters.lowercased(currentWeekday.displayName),
            tomorrowHabitsCount: tomorrowHabitsCount
        ) {
            model.coverRoute = .habit(.create(prefill: HabitPrefill(
                initialActiveDays: [currentWeekday],
                initialDaysPerWeek: 1
            )))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    func freezeExplainerMessage(for data: TodayViewData) -> String? {
        guard !hasSeenFreezeExplainer else { return nil }
        return model.latestFreezeExplainerMessage ?? data.weeklyFreezes.todayBannerMessage()
    }

}

#Preview {
    TodayView()
}
