//
//  InsightModels.swift
//  WeekHabit
//

import Foundation

struct HabitCompletionStats {
    let completed: Int
    let scheduled: Int

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return min(1, Double(completed) / Double(scheduled))
    }

    var percentage: Int {
        Int((ratio * 100).rounded())
    }
}

struct GlobalInsightSnapshot {
    let current: HabitCompletionStats
    let previous: HabitCompletionStats
    let trend: [Double]

    var deltaPercentagePoints: Int {
        Int(((current.ratio - previous.ratio) * 100).rounded())
    }
}

struct InsightReadiness {
    static let defaultRequiredDays = 5
    static let defaultStableDays = 21

    let elapsedDays: Int
    let requiredDays: Int
    let stableDays: Int

    var isReady: Bool {
        elapsedDays >= requiredDays
    }

    var isStable: Bool {
        elapsedDays >= stableDays
    }

    var isProvisional: Bool {
        isReady && !isStable
    }

    var remainingDays: Int {
        max(0, requiredDays - elapsedDays)
    }

    var remainingStableDays: Int {
        max(0, stableDays - elapsedDays)
    }

    var progress: Double {
        guard requiredDays > 0 else { return 1 }
        return min(1, Double(elapsedDays) / Double(requiredDays))
    }
}

enum RhythmConfidenceLevel {
    case high
    case learning
    case low
}

struct RhythmConfidence {
    let trustedMarks: Int
    let totalMarks: Int
    let focusSessionMarks: Int

    var ratio: Double {
        guard totalMarks > 0 else { return 0 }
        return Double(trustedMarks) / Double(totalMarks)
    }

    var level: RhythmConfidenceLevel {
        guard totalMarks > 0 else { return .low }

        switch ratio {
        case 0.75...:
            return .high
        case 0.35..<0.75:
            return .learning
        default:
            return .low
        }
    }

    var title: String {
        switch level {
        case .high:
            return "Alta confianza"
        case .learning:
            return "Aún aprendiendo"
        case .low:
            return "Pocas marcas reales"
        }
    }

    var detail: String {
        guard totalMarks > 0 else {
            return "Inicia una sesión o marca desde Hoy para que Insights lea tu ritmo real."
        }

        if focusSessionMarks > 0 {
            return "\(trustedMarks) de \(totalMarks) marcas son en momento real · \(focusSessionMarks) desde sesiones."
        }

        return "\(trustedMarks) de \(totalMarks) marcas son en momento real."
    }
}

struct HabitInsightSummary: Identifiable {
    let habit: Habit
    let stats: HabitCompletionStats
    let detail: String
    var failureType: AttentionFailureType? = nil
    var recommendation: String? = nil

    var id: UUID {
        habit.id
    }
}

enum AttentionFailureType {
    case notDone
    case manualOnly
    case knownReason(HabitFailureReason)

    var title: String {
        switch self {
        case .notDone:
            return "No lo hizo"
        case .manualOnly:
            return "Lo hizo manual"
        case .knownReason(let reason):
            return reason.title
        }
    }
}

struct DominantFailureReason {
    let reason: HabitFailureReason
    let count: Int
    let total: Int

    var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
}

struct WeekdayPerformance: Identifiable {
    let weekday: Weekday
    let completed: Int
    let scheduled: Int

    var id: Int {
        weekday.rawValue
    }

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }
}

struct HourWindow: Identifiable, Equatable {
    let startHour: Int
    let count: Int

    var id: Int {
        startHour
    }

    var endHour: Int {
        (startHour + 1) % 24
    }

    var displayText: String {
        "\(startHour):00 – \(endHour):00"
    }
}

struct RhythmExperimentSuggestion: Identifiable {
    let habit: Habit
    let title: String
    let message: String
    let reason: String
    let targetDaysPerWeek: Int
    let activeDays: Set<Weekday>
    let suggestedStartHour: Int?
    let baselineConsistency: Double

    var id: UUID {
        habit.id
    }

    var daySummary: String {
        let days = Weekday.ordered
            .filter { activeDays.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")

        return "\(targetDaysPerWeek)d/sem · \(days)"
    }

    var hourText: String? {
        guard let suggestedStartHour else { return nil }
        return HourWindow(startHour: suggestedStartHour, count: 0).displayText
    }
}

struct RankedRhythmSuggestion: Identifiable {
    let suggestion: RhythmExperimentSuggestion
    let priorityScore: Double
    let priorityReason: String

    var id: UUID {
        suggestion.id
    }
}

struct HabitInsightContext: Identifiable {
    let habit: Habit
    let count: Int

    var id: UUID {
        habit.id
    }
}

struct ContextualHourInsight: Identifiable {
    let window: HourWindow
    let habits: [HabitInsightContext]

    var id: Int {
        window.id
    }

    var contextText: String {
        habitContextText(prefix: "aplica a")
    }

    private func habitContextText(prefix: String) -> String {
        let names = habits.map { $0.habit.title }
        switch names.count {
        case 0:
            return "basada en \(window.count) marcas reales"
        case 1:
            return "\(prefix) \(names[0])"
        case 2:
            return "\(prefix) \(names.joined(separator: " y "))"
        default:
            return "\(prefix) \(names.count) hábitos, sobre todo \(names.prefix(2).joined(separator: " y "))"
        }
    }
}

struct ContextualWeekdayInsight: Identifiable {
    let performance: WeekdayPerformance
    let habits: [HabitInsightContext]

    var id: Int {
        performance.id
    }

    var contextText: String {
        let names = habits.map { $0.habit.title }
        switch names.count {
        case 0:
            return "\(Int((performance.ratio * 100).rounded()))% de cumplimiento promedio"
        case 1:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destaca \(names[0])"
        case 2:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destacan \(names.joined(separator: " y "))"
        default:
            return "\(Int((performance.ratio * 100).rounded()))% promedio · destacan \(names.prefix(2).joined(separator: " y "))"
        }
    }
}
