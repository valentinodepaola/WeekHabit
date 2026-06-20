//
//  PlanDraft.swift
//  WeekHabit
//

import Foundation

struct PlanDraft {
    var name: String
    var motivation: String
    var measurableOutcome: String
    var endsAt: Date
    var targetCompletionRate: Double
    var selectedHabitIDs: Set<UUID>
    var milestones: [MilestoneDraft]

    init(plan: Plan? = nil, reference: Date = .now) {
        self.name = plan?.title ?? ""
        self.motivation = plan?.motivation ?? ""
        self.measurableOutcome = plan?.measurableOutcome ?? ""
        self.endsAt = plan?.endsAt ?? Self.defaultEndDate(reference: reference)
        self.targetCompletionRate = plan?.targetCompletionRate ?? 0.8
        self.selectedHabitIDs = Set(plan?.habits.map(\.id) ?? [])
        self.milestones = (plan?.milestones ?? [])
            .sorted { $0.targetDate < $1.targetDate }
            .map {
                MilestoneDraft(
                    id: $0.id,
                    title: $0.title,
                    targetDate: $0.targetDate
                )
            }
    }

    var isSaveDisabled: Bool {
        normalizedName.isEmpty
    }

    var normalizedName: String {
        Self.trimmed(name)
    }

    var normalizedMotivation: String? {
        Self.optionalTrimmed(motivation)
    }

    var normalizedMeasurableOutcome: String? {
        Self.optionalTrimmed(measurableOutcome)
    }

    var normalizedEndsAt: Date {
        AppCalendar.startOfDay(for: endsAt)
    }

    var normalizedMilestones: [MilestoneDraft] {
        milestones.compactMap { milestone in
            let title = Self.trimmed(milestone.title)
            guard !title.isEmpty else { return nil }
            return MilestoneDraft(
                id: milestone.id,
                title: title,
                targetDate: AppCalendar.startOfDay(for: milestone.targetDate)
            )
        }
    }

    private static func defaultEndDate(reference: Date) -> Date {
        AppCalendar.current.date(byAdding: .day, value: 30, to: reference) ?? reference
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func optionalTrimmed(_ value: String) -> String? {
        let value = trimmed(value)
        return value.isEmpty ? nil : value
    }
}
