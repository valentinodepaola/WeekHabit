//
//  TodayRouteViews.swift
//  WeekHabit
//

import SwiftUI

/// Vistas de destino de cada ruta de Hoy y los enlaces de acción de las secciones.
/// Viven aparte porque son una traducción mecánica de ruta a pantalla: separarlas deja
/// `TodayView` con la estructura de la pantalla y sus datos.
extension TodayView {
    // MARK: - Action bindings

    func habitActions(data: TodayViewData, on date: Date) -> TodayHabitActions {
        TodayHabitActions(
            toggleCompletion: { toggleCompletion(for: $0, data: data, on: date) },
            markMinimum: { markMinimumCompleted(for: $0, data: data, on: date) },
            openDetail: { model.selectedHabit = $0 },
            openUrgeLog: { habit in
                hasSeenUrgeTooltip = true
                model.sheetRoute = .urgeLog(habit: habit)
            },
            openSlipLog: { model.sheetRoute = .slipLog(habit: $0) },
            toggleRest: { toggleRest(for: $0, on: date) },
            requestDelete: { model.requestHabitDeletion($0) },
            openEdit: { model.coverRoute = .habit(.edit($0)) },
            openSlipContext: { model.sheetRoute = .slipLog(habit: $0) },
            undoSlip: { undoSlip(for: $0, on: date) },
            startFocus: {
                model.coverRoute = .focus(habits: data.focusCandidateHabits)
            }
        )
    }

    var planActions: TodayPlanActions {
        TodayPlanActions(
            onHabitTap: { model.selectedHabit = $0 },
            onOpenDetail: { model.detailPlan = $0 },
            onEdit: { model.coverRoute = .plan(.edit($0)) },
            onDelete: { model.requestPlanDeletion($0) }
        )
    }

    // MARK: - Routing

    @ViewBuilder
    func routeCover(_ route: TodayCoverRoute) -> some View {
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
    func routeSheet(_ route: TodaySheetRoute, data: TodayViewData, on date: Date) -> some View {
        switch route {
        case .createMenu:
            WHCreationSheet(
                focusDisabledReason: data.hasFocusCandidates ? nil : "No hay hábitos disponibles para hoy."
            ) { option in
                handleCreationSelection(option, data: data)
            }
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .help:
            TodayHelpSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.bgCanvas)
        case .quantityLog(let habit, let logDate):
            QuantityLogSheet(
                habit: habit,
                date: logDate,
                initialValue: habit.totalValue(on: logDate)
            ) { value in
                upsertQuantityEntry(
                    for: habit,
                    on: logDate,
                    value: value,
                    source: .today,
                    data: data,
                    reference: date
                )
            }
            .presentationDetents([.height(310)])
        case .slipLog(let habit):
            SlipLogSheet(
                habit: habit,
                existingEntry: habit.slipEntry(on: date)
            ) { trigger, context in
                persistSlip(for: habit, trigger: trigger, context: context, on: date)
            }
            .presentationDetents([.height(560), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .urgeLog(let habit):
            UrgeLogSheet(habit: habit) { trigger in
                persistUrge(for: habit, trigger: trigger, on: date)
            }
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.bgCanvas)
        case .recoveryPrompt(let candidate):
            RecoveryPromptView(
                candidate: candidate,
                referenceDate: date,
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
                    model.replaceSheet {
                        model.coverRoute = .focus(habits: [replacementHabit])
                    }
                },
                onSkip: {
                    model.sheetRoute = nil
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

    func handleCreationSelection(_ option: WHCreationOption, data: TodayViewData) {
        model.replaceSheet {
            switch option {
            case .habit:
                model.coverRoute = .habit(.create(prefill: .empty))
            case .plan:
                model.coverRoute = .plan(.create)
            case .focus:
                guard data.hasFocusCandidates else { return }
                model.coverRoute = .focus(habits: data.focusCandidateHabits)
            }
        }
    }

}
