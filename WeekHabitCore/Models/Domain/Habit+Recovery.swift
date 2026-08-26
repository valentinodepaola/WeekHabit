//
//  Habit+Recovery.swift
//  WeekHabit
//

import Foundation

struct RecoveryPromptCandidate: Identifiable, Hashable {
    let habit: Habit
    let date: Date

    var id: String {
        "\(habit.id.uuidString)-\(date.timeIntervalSinceReferenceDate)"
    }

    static func == (lhs: RecoveryPromptCandidate, rhs: RecoveryPromptCandidate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Habit {
    func recoveryPromptCandidate(before reference: Date = .now) -> RecoveryPromptCandidate? {
        let referenceDay = AppCalendar.startOfDay(for: reference)
        guard let yesterday = AppCalendar.current.date(byAdding: .day, value: -1, to: referenceDay) else {
            return nil
        }

        guard isRecoveryPromptCandidate(on: yesterday) else {
            return nil
        }

        return RecoveryPromptCandidate(habit: self, date: yesterday)
    }

    /// Razón guardada para el miss de ese día, si el usuario ya contestó.
    ///
    /// La lista de recuperación la usa para pintar el estado de cada fila en vivo: el roster se
    /// congela al abrir la hoja, pero el estado de cada fila sale del `@Model`.
    func recoveryAnswer(on date: Date) -> HabitFailureReason? {
        entries
            .first { AppCalendar.isSameDay($0.date, date) && $0.kind == .missed }?
            .failureReasonKind
    }

    private func isRecoveryPromptCandidate(on date: Date) -> Bool {
        // `isScheduled(on:)` es verdadero todos los días para las agendas flexibles, así que sin
        // consultar la meta semanal un hábito de 3 veces/semana que ya hizo sus 3 días sería
        // candidato igual. `meetsTodaySectionTarget` es la misma regla con la que Hoy decide no
        // listarlo, y solo se consulta para flexibles: construye un `HabitDayIndex`.
        isLoggable(on: date)
            && !hasAnyEntry(on: date)
            && !isFreezeProtected(on: date)
            && !(isFlexibleSchedule && meetsTodaySectionTarget(on: date))
    }
}

extension Sequence where Element == Habit {
    /// Todos los hábitos que ayer quedaron sin marcar, en el orden del receptor.
    ///
    /// El orden no se toca a propósito: quien llama pasa la misma colección que Hoy lista, así
    /// que la hoja se lee como un espejo de ayer.
    func recoveryPromptCandidates(reference: Date = .now) -> [RecoveryPromptCandidate] {
        compactMap { $0.recoveryPromptCandidate(before: reference) }
    }
}
