//
//  FocusSequence.swift
//  WeekHabit
//
//  Modelo efímero del modo secuencia del Modo Enfoque. Vive solo durante la
//  sesión activa (no se persiste). Cada ítem referencia un hábito por id y
//  guarda el tiempo asignado; el total de la sesión es la suma de los ítems.
//  La lógica de estados es pura para poder probarse sin SwiftData.
//

import Foundation

/// Un hábito dentro de la secuencia, con su tiempo asignado.
struct FocusSequenceItem: Identifiable, Equatable {
    /// Coincide con el `id` del `Habit`.
    let id: UUID
    var seconds: Int
}

/// Estado de un paso del stepper durante la sesión, derivado del tiempo real.
enum FocusStepState: Equatable {
    case pending
    /// En curso: `fraction` (0...1) es el avance dentro del bloque del hábito.
    case inProgress(fraction: Double)
    case done
}

enum FocusSequence {
    /// Tiempo base con el que nace cada hábito (10 min).
    static let baseSeconds = 600
    /// Límites y paso del ajuste por hábito.
    static let minSeconds = 300        // 5 min
    static let maxSeconds = 3600       // 60 min
    static let stepSeconds = 300       // 5 min

    static func totalSeconds(_ items: [FocusSequenceItem]) -> Int {
        items.reduce(0) { $0 + $1.seconds }
    }

    /// Ajusta los segundos de un ítem al paso y dentro de los límites.
    static func clampedSeconds(_ seconds: Int) -> Int {
        let snapped = (Double(seconds) / Double(stepSeconds)).rounded() * Double(stepSeconds)
        return Swift.min(maxSeconds, Swift.max(minSeconds, Int(snapped)))
    }

    /// Estado de cada ítem (en orden) según los segundos transcurridos.
    static func states(items: [FocusSequenceItem], elapsed: Int) -> [FocusStepState] {
        var blockStart = 0
        return items.map { item in
            let blockEnd = blockStart + item.seconds
            defer { blockStart = blockEnd }

            if elapsed >= blockEnd {
                return .done
            }
            if elapsed >= blockStart {
                guard item.seconds > 0 else { return .done }
                let fraction = Double(elapsed - blockStart) / Double(item.seconds)
                return .inProgress(fraction: Swift.min(1, Swift.max(0, fraction)))
            }
            return .pending
        }
    }

    /// Índice del hábito en curso según el tiempo transcurrido, si lo hay.
    static func currentIndex(items: [FocusSequenceItem], elapsed: Int) -> Int? {
        states(items: items, elapsed: elapsed).firstIndex {
            if case .inProgress = $0 { return true }
            return false
        }
    }

    /// Reconcilia la secuencia con el conjunto seleccionado conservando orden y
    /// tiempos de los que siguen presentes, y agregando los nuevos al final.
    static func reconcile(
        items: [FocusSequenceItem],
        selectedIDs: Set<UUID>,
        appendingOrder: [UUID]
    ) -> [FocusSequenceItem] {
        var result = items.filter { selectedIDs.contains($0.id) }
        let existing = Set(result.map(\.id))
        for id in appendingOrder where selectedIDs.contains(id) && !existing.contains(id) {
            result.append(FocusSequenceItem(id: id, seconds: baseSeconds))
        }
        return result
    }
}
