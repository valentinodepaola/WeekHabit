//
//  FocusSession.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum FocusSessionStatus: String, Codable {
    case running
    case reviewing
    case completed
    case cancelled
}

@Model
final class FocusSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?
    var selectedHabitIDsRaw: [String]
    var completedHabitIDsRaw: [String]
    var statusRaw: String

    var selectedHabitIDs: Set<UUID> {
        get { Set(selectedHabitIDsRaw.compactMap { UUID(uuidString: $0) }) }
        set { selectedHabitIDsRaw = newValue.map(\.uuidString) }
    }

    var completedHabitIDs: Set<UUID> {
        get { Set(completedHabitIDsRaw.compactMap { UUID(uuidString: $0) }) }
        set { completedHabitIDsRaw = newValue.map(\.uuidString) }
    }

    var status: FocusSessionStatus {
        get { FocusSessionStatus(rawValue: statusRaw) ?? .running }
        set { statusRaw = newValue.rawValue }
    }

    init(
        selectedHabitIDs: Set<UUID>,
        durationSeconds: Int?,
        startedAt: Date = .now
    ) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = nil
        self.durationSeconds = durationSeconds
        self.selectedHabitIDsRaw = selectedHabitIDs.map(\.uuidString)
        self.completedHabitIDsRaw = []
        self.statusRaw = FocusSessionStatus.running.rawValue
    }
}
