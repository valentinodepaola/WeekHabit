//
//  PlanRoute.swift
//  WeekHabit
//
//  Router unificado para CreatePlanView.
//

import Foundation

enum PlanRoute: Identifiable, Hashable {
    case create
    case edit(Plan)

    var id: String {
        switch self {
        case .create:
            return "plan-create"
        case .edit(let plan):
            return "plan-edit-\(plan.id)"
        }
    }
}
