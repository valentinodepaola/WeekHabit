//
//  HabitEntry.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftData
import Foundation

enum HabitEntrySource: String, Codable, CaseIterable {
    case today
    case focusSession
    case manual

    var isTrustedForInsights: Bool {
        switch self {
        case .today, .focusSession:
            return true
        case .manual:
            return false
        }
    }
}

enum EntryKind: String, Codable, CaseIterable {
    case completed
    case skipped
    case minimum
    case missed
    case slip
    case urge
}

enum SlipTrigger: String, Codable, CaseIterable, Identifiable {
    case stress
    case boredom
    case social
    case fatigue
    case craving
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stress:
            return "Estrés"
        case .boredom:
            return "Aburrimiento"
        case .social:
            return "Social"
        case .fatigue:
            return "Cansancio"
        case .craving:
            return "Antojo"
        case .other:
            return "Otro"
        }
    }

    var iconName: String {
        switch self {
        case .stress:
            return "bolt.heart"
        case .boredom:
            return "clock"
        case .social:
            return "person.2"
        case .fatigue:
            return "moon"
        case .craving:
            return "waveform.path.ecg"
        case .other:
            return "ellipsis"
        }
    }
}

enum HabitFailureReason: String, Codable, CaseIterable, Identifiable {
    case tooDifficult
    case forgot
    case badTiming
    case lowEnergy
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tooDifficult:
            return "Demasiado difícil"
        case .forgot:
            return "Se me olvidó"
        case .badTiming:
            return "Mal horario"
        case .lowEnergy:
            return "Sin energía"
        case .other:
            return "Otro"
        }
    }
}

@Model
final class HabitEntry {
    var id: UUID
    /// Normalized to `startOfDay` so range queries are timezone-stable.
    var date: Date
    /// Real timestamp for same-day marks. Retroactive marks keep this nil.
    var completedAt: Date?
    var sourceRaw: String?
    var kindRaw: String?
    var focusSessionID: UUID?
    var completedCount: Int
    var value: Double?
    var failureReason: String?
    var slipTriggerRaw: String?
    var slipContext: String?
    var habit: Habit?

    var source: HabitEntrySource {
        get {
            if let sourceRaw, let source = HabitEntrySource(rawValue: sourceRaw) {
                return source
            }

            return completedAt == nil ? .manual : .today
        }
        set {
            sourceRaw = newValue.rawValue
        }
    }

    var kind: EntryKind {
        get {
            if let kindRaw, let kind = EntryKind(rawValue: kindRaw) {
                return kind
            }

            return .completed
        }
        set {
            kindRaw = newValue.rawValue
        }
    }

    var failureReasonKind: HabitFailureReason? {
        get {
            guard let failureReason else { return nil }
            return HabitFailureReason(rawValue: failureReason)
        }
        set {
            failureReason = newValue?.rawValue
        }
    }

    var slipTrigger: SlipTrigger? {
        get {
            guard let slipTriggerRaw else { return nil }
            return SlipTrigger(rawValue: slipTriggerRaw)
        }
        set {
            slipTriggerRaw = newValue?.rawValue
        }
    }

    var urgeTrigger: SlipTrigger? {
        get { slipTrigger }
        set { slipTrigger = newValue }
    }

    init(
        date: Date,
        completedAt: Date? = nil,
        source: HabitEntrySource = .manual,
        kind: EntryKind = .completed,
        focusSessionID: UUID? = nil,
        completedCount: Int = 1,
        value: Double? = nil,
        failureReason: HabitFailureReason? = nil,
        slipTrigger: SlipTrigger? = nil,
        slipContext: String? = nil,
        habit: Habit
    ) {
        self.id = UUID()
        self.date = AppCalendar.startOfDay(for: date)
        self.completedAt = completedAt
        self.sourceRaw = source.rawValue
        self.kindRaw = kind.rawValue
        self.focusSessionID = focusSessionID
        self.completedCount = completedCount
        self.value = value ?? Double(completedCount)
        self.failureReason = failureReason?.rawValue
        self.slipTriggerRaw = slipTrigger?.rawValue
        self.slipContext = slipContext
        self.habit = habit
    }
}
