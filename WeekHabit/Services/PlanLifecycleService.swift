//
//  PlanLifecycleService.swift
//  WeekHabit
//

import SwiftData

enum PlanLifecycleService {
    static func delete(
        _ plan: Plan,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }
}
