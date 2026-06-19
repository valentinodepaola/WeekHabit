//
//  FocusSessionEditorService.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum FocusSessionEditorService {
    static func start(
        selectedHabitIDs: Set<UUID>,
        durationSeconds: Int?,
        startedAt: Date = .now,
        modelContext: ModelContext
    ) throws -> FocusSession {
        let session = FocusSession(
            selectedHabitIDs: selectedHabitIDs,
            durationSeconds: durationSeconds,
            startedAt: startedAt
        )
        modelContext.insert(session)
        try modelContext.save()
        return session
    }
}
