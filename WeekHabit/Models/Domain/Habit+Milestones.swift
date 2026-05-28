//
//  Habit+Milestones.swift
//  WeekHabit
//
//  Canonical milestone detection for live rewards and silent back-fills.
//

import Foundation

struct MilestoneCopy: Equatable {
    let title: String
    let identity: String
    let symbolName: String
}

enum HabitMilestone: Int, CaseIterable {
    case week = 7
    case month = 30
    case automaticity = 66
    case hundred = 100
    case year = 365

    func copy(for direction: HabitDirection) -> MilestoneCopy {
        switch (self, direction) {
        case (.week, .build):
            return MilestoneCopy(title: "Una semana", identity: "El primer paso real", symbolName: "sparkles")
        case (.week, .break):
            return MilestoneCopy(title: "Una semana", identity: "Empezaste a soltarlo", symbolName: "leaf.fill")
        case (.month, .build):
            return MilestoneCopy(title: "Un mes", identity: "Ya eres alguien que lo hace", symbolName: "calendar.badge.checkmark")
        case (.month, .break):
            return MilestoneCopy(title: "Un mes", identity: "Ya no te define", symbolName: "shield.lefthalf.filled")
        case (.automaticity, .build):
            return MilestoneCopy(title: "66 días", identity: "Esto ya es identidad", symbolName: "seal.fill")
        case (.automaticity, .break):
            return MilestoneCopy(title: "66 días", identity: "Ya no eres quien eras", symbolName: "checkmark.seal.fill")
        case (.hundred, .build):
            return MilestoneCopy(title: "Cien", identity: "Esto es lo que haces", symbolName: "trophy.fill")
        case (.hundred, .break):
            return MilestoneCopy(title: "Cien", identity: "Eres otra persona", symbolName: "medal.fill")
        case (.year, .build):
            return MilestoneCopy(title: "Un año", identity: "Es parte de quién eres", symbolName: "star.circle.fill")
        case (.year, .break):
            return MilestoneCopy(title: "Un año", identity: "Ya es historia", symbolName: "flag.checkered")
        }
    }
}

struct MilestoneCelebrationPayload: Identifiable {
    let habit: Habit
    let milestone: HabitMilestone

    var id: String {
        "\(habit.id.uuidString)-\(milestone.rawValue)"
    }
}

extension Habit {
    var celebratedMilestones: Set<Int> {
        Set(celebratedMilestonesRaw)
    }

    func crossedMilestone(on date: Date) -> HabitMilestone? {
        let streak = currentStreak(reference: date)
        guard streak > 0 else { return nil }

        return HabitMilestone.allCases
            .filter { $0.rawValue <= streak && !celebratedMilestones.contains($0.rawValue) }
            .max { $0.rawValue < $1.rawValue }
    }

    func markMilestoneCelebrated(_ milestone: HabitMilestone) {
        markMilestonesCelebrated(upTo: milestone.rawValue)
    }

    func markCurrentMilestoneSilently(on date: Date) {
        markMilestonesCelebrated(upTo: currentStreak(reference: .now))
    }

    private func markMilestonesCelebrated(upTo streak: Int) {
        let reached = HabitMilestone.allCases
            .map(\.rawValue)
            .filter { $0 <= streak }
        guard !reached.isEmpty else { return }

        let updated = celebratedMilestones.union(reached)
        celebratedMilestonesRaw = updated.sorted()
    }
}
