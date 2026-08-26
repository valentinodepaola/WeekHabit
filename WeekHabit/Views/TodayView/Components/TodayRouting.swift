//
//  TodayRouting.swift
//  WeekHabit
//

import SwiftUI

enum TodayCoverRoute: Identifiable {
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

enum TodaySheetRoute: Identifiable {
    case createMenu
    case help
    case quantityLog(habit: Habit, date: Date)
    case slipLog(habit: Habit)
    case urgeLog(habit: Habit)
    case recoveryPrompt(date: Date)
    case replacementPrompt(breakHabit: Habit, replacementHabit: Habit)
    case weeklyReview(weekStart: Date)

    var id: String {
        switch self {
        case .createMenu: return "createMenu"
        case .help: return "help"
        case .quantityLog(let habit, _): return "quantityLog-\(habit.id)"
        case .slipLog(let habit): return "slipLog-\(habit.id)"
        case .urgeLog(let habit): return "urgeLog-\(habit.id)"
        case .recoveryPrompt(let date):
            return "recoveryPrompt-\(date.timeIntervalSinceReferenceDate)"
        case .replacementPrompt(let breakHabit, let replacementHabit):
            return "replacementPrompt-\(breakHabit.id)-\(replacementHabit.id)"
        case .weeklyReview(let weekStart):
            return "weeklyReview-\(weekStart.timeIntervalSinceReferenceDate)"
        }
    }
}

struct TodayFailure: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func deleting(_ error: Error) -> TodayFailure {
        TodayFailure(title: "No se pudo borrar", message: error.localizedDescription)
    }

    static func saving(_ error: Error) -> TodayFailure {
        TodayFailure(title: "No se pudo guardar", message: error.localizedDescription)
    }
}

extension View {
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
