//
//  IdentityReinforcementCopy.swift
//  WeekHabit
//

import Foundation

enum IdentityReinforcementCopy {
    static func milestoneUnitLabel(for habit: Habit) -> String {
        switch habit.direction {
        case .build:
            return "DÍAS SIENDO QUIEN QUIERES SER"
        case .break:
            return "DÍAS SIN QUE TE DEFINA"
        }
    }

    static func milestoneIdentity(for habit: Habit, milestone: HabitMilestone) -> String {
        switch (milestone, habit.direction) {
        case (.week, .build):
            return "Estás empezando a ser alguien que \(habit.title)."
        case (.week, .break):
            return "Estás empezando a soltar \(habit.title)."
        case (.month, .build):
            return "Eres alguien que vuelve a \(habit.title)."
        case (.month, .break):
            return "Eres alguien que dejó \(habit.title)."
        case (.automaticity, .build):
            return "\(habit.title) ya es parte de cómo vives."
        case (.automaticity, .break):
            return "\(habit.title) ya no aparece sin que decidas."
        case (.hundred, .build):
            return "Esto ya no es esfuerzo. Es quién eres."
        case (.hundred, .break):
            return "Ya no te define lo que dejaste atrás."
        case (.year, .build):
            return "Un año siendo esta versión tuya."
        case (.year, .break):
            return "Un año en que elegiste algo distinto, todos los días."
        }
    }

    static func streakHeroCaption(for habit: Habit, currentStreak: Int) -> String {
        guard currentStreak > 0 else { return "DESDE HOY" }

        switch habit.direction {
        case .build:
            return "QUIÉN ESTÁS SIENDO"
        case .break:
            return "DÍAS ELIGIENDO DISTINTO"
        }
    }

    static func streakHeroFlavor(for habit: Habit, currentStreak: Int, bestStreak: Int) -> String {
        switch habit.direction {
        case .build:
            if currentStreak == 0 {
                return "Hoy puedes volver. Un paso pequeño también cuenta."
            }
            if currentStreak == bestStreak {
                return "Cada día así habla más de quién eres."
            }
            return "Estás volviendo. Tu mejor versión llegó a \(bestStreak)."
        case .break:
            if currentStreak == 0 {
                return "Hoy puedes elegir distinto. Sin culpa, sin urgencia."
            }
            if currentStreak == bestStreak {
                return "Cada día así te aleja de lo que ya no quieres."
            }
            return "Sigues eligiendo. Tu mejor tramo fue de \(bestStreak)."
        }
    }

    static func bestStreakFooter(for habit: Habit, currentStreak: Int, bestStreak: Int) -> String {
        guard bestStreak > 0 else { return "todavía sin estrenar" }

        switch habit.direction {
        case .build:
            return currentStreak == bestStreak
                ? "hoy lo estás siendo"
                : "tu mejor versión hasta hoy"
        case .break:
            return currentStreak == bestStreak
                ? "hoy lo sigues eligiendo"
                : "tu mejor tramo eligiendo distinto"
        }
    }

    static func streakBreakdownHeader(for habit: Habit) -> String {
        switch habit.direction {
        case .build:
            return "CÓMO LO ESTÁS SOSTENIENDO"
        case .break:
            return "CÓMO ESTÁS ELIGIENDO"
        }
    }

    static func streakBreakdownTotal(for habit: Habit, totalDays: Int) -> String {
        switch habit.direction {
        case .build:
            return totalDays == 1 ? "1 día sosteniéndolo" : "\(totalDays) días sosteniéndolo"
        case .break:
            return totalDays == 1 ? "1 día eligiendo distinto" : "\(totalDays) días eligiendo distinto"
        }
    }

    static func streakBreakdownStatus(for habit: Habit, breakdown: StreakBreakdown) -> String {
        if !breakdown.hasHistory {
            switch habit.direction {
            case .build:
                return "Todavía no hay días sostenidos para mostrar."
            case .break:
                return "Todavía no hay días eligiendo distinto para mostrar."
            }
        }

        if breakdown.protectedDays == 0 && breakdown.minimumDays == 0 {
            switch habit.direction {
            case .build:
                return "Tu continuidad viene de los días que volviste."
            case .break:
                return "Tu continuidad viene de los días que elegiste distinto."
            }
        }

        if breakdown.minimumDays > 0 && breakdown.protectedDays == 0 {
            return "Las versiones mínimas también sostienen este tramo."
        }

        return "Tu continuidad también incluye mínimos, descansos y comodines."
    }

    static func streakAccessibility(for habit: Habit, streakCount: Int) -> String {
        switch (habit.direction, streakCount) {
        case (.build, 0):
            return "Hoy puedes volver a \(habit.title)."
        case (.build, _):
            return "Eres alguien que vuelve a \(habit.title). \(streakCount) días."
        case (.break, 0):
            return "Hoy puedes elegir distinto con \(habit.title)."
        case (.break, _):
            return "Estás eligiendo distinto con \(habit.title). \(streakCount) días."
        }
    }

    static func longestBannerCaption(for habit: Habit?, allSameStreak: Bool) -> String {
        if allSameStreak { return "TODOS EN RITMO" }

        switch habit?.direction {
        case .break:
            return "ELIGIENDO DISTINTO"
        case .build, .none:
            return "QUIÉN ESTÁS SIENDO"
        }
    }

    static func longestBannerTitle(for habit: Habit?, streakDays: Int, allSameStreak: Bool) -> String {
        let dayWord = streakDays == 1 ? "día" : "días"
        if allSameStreak {
            return "Tus hábitos viven contigo · \(streakDays) \(dayWord)"
        }

        guard let habit else {
            return "\(streakDays) \(dayWord) en ritmo"
        }

        switch habit.direction {
        case .build:
            return "\(habit.title) · \(streakDays) \(dayWord) siendo esa versión"
        case .break:
            return "\(habit.title) · \(streakDays) \(dayWord) eligiendo distinto"
        }
    }
}
