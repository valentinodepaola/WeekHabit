//
//  FocusSession+Domain.swift
//  WeekHabit
//

import Foundation

extension FocusSession {
    func elapsedSeconds(reference: Date = .now) -> Int {
        Swift.max(0, Int(reference.timeIntervalSince(startedAt)))
    }

    func remainingSeconds(reference: Date = .now) -> Int? {
        guard let durationSeconds else { return nil }
        return Swift.max(0, durationSeconds - elapsedSeconds(reference: reference))
    }

    func progress(reference: Date = .now) -> Double? {
        guard let durationSeconds, durationSeconds > 0 else { return nil }
        return Swift.min(1, Double(elapsedSeconds(reference: reference)) / Double(durationSeconds))
    }

    func finishForReview(reference: Date = .now) {
        guard status == .running else { return }
        status = .reviewing
        endedAt = reference
    }

    func complete(completedHabitIDs: Set<UUID>, reference: Date = .now) {
        self.completedHabitIDs = completedHabitIDs
        if endedAt == nil {
            endedAt = reference
        }
        status = .completed
    }

    func cancel(reference: Date = .now) {
        if endedAt == nil {
            endedAt = reference
        }
        status = .cancelled
    }
}

enum FocusDurationPreset: Int, CaseIterable, Identifiable {
    case ten = 600
    case twentyFive = 1500
    case fortyFive = 2700
    case open = 0

    var id: Int {
        rawValue
    }

    var durationSeconds: Int? {
        rawValue == 0 ? nil : rawValue
    }

    var title: String {
        switch self {
        case .ten:
            return "10"
        case .twentyFive:
            return "25"
        case .fortyFive:
            return "45"
        case .open:
            return "Libre"
        }
    }

    var subtitle: String {
        switch self {
        case .open:
            return "sin límite"
        default:
            return "min"
        }
    }
}

enum FocusTimeFormatter {
    static func string(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}
