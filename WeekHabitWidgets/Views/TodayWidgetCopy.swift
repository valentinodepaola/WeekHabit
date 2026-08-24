//
//  TodayWidgetCopy.swift
//  WeekHabitWidgets
//

import Foundation

/// Todo el texto del widget, en un solo lugar.
///
/// Está centralizado por la misma razón que `HelpCatalog`: cuatro familias dibujan los mismos
/// estados con distinto espacio, y si cada vista escribiera su propia frase, el mismo día se
/// describiría de cuatro maneras distintas según dónde lo mirara el usuario.
///
/// Regla de tono heredada de `CLAUDE.md`: nada de reproche. Un día sin cerrar se cuenta, no
/// se juzga, y el descanso se nombra como lo que es —una decisión— y no como un vacío.
enum TodayWidgetCopy {

    // MARK: - Encabezado

    static let today = "HOY"
    static let brand = "WEEKHABIT"

    static func eyebrow(for snapshot: TodayWidgetSnapshot) -> String {
        switch snapshot.state {
        case .pending, .allDone, .rest: return today
        case .empty: return brand
        }
    }

    // MARK: - Titular

    static func headline(for snapshot: TodayWidgetSnapshot) -> String {
        switch snapshot.state {
        case .pending:
            return pendingCount(snapshot.pendingCount)
        case .allDone:
            return "Día cerrado"
        case .rest:
            return snapshot.restedEverythingScheduled ? "Todo en descanso" : "Hoy toca descansar"
        case .empty:
            return "Tu primer hábito"
        }
    }

    // MARK: - Detalle

    /// Segunda línea, con el espacio de `accessoryRectangular` y `systemSmall`.
    static func detail(for snapshot: TodayWidgetSnapshot) -> String {
        switch snapshot.state {
        case .pending:
            return compactPendingList(for: snapshot)
        case .allDone:
            return closedDayDetail(for: snapshot)
        case .rest:
            return restDetail(for: snapshot)
        case .empty:
            return "Toca para crearlo"
        }
    }

    /// Versión larga, para `systemMedium`, que sí tiene ancho para una frase completa.
    static func longDetail(for snapshot: TodayWidgetSnapshot) -> String {
        switch snapshot.state {
        case .rest:
            return [restReason(for: snapshot), restDetail(for: snapshot)].joined(separator: " ")
        case .empty:
            return "Toca para crearlo y verlo aquí cada día."
        case .pending, .allDone:
            return detail(for: snapshot)
        }
    }

    // MARK: - Piezas

    static func progressText(for snapshot: TodayWidgetSnapshot) -> String {
        "\(snapshot.completedCount) de \(snapshot.activeCount) hechos"
    }

    /// Etiqueta bajo la cifra del anillo. Aclara que el número es lo que queda y no lo hecho.
    static let remainingLabel = "FALTAN"

    /// Pendientes que no entraron en la lista. `nil` cuando cupieron todos.
    static func hiddenPending(for snapshot: TodayWidgetSnapshot) -> String? {
        guard snapshot.hiddenPendingCount > 0 else { return nil }
        return snapshot.hiddenPendingCount == 1 ? "y 1 más" : "y \(snapshot.hiddenPendingCount) más"
    }

    static let unavailableHeadline = "Abre WeekHabit"
    static let unavailableDetail = "Para poner al día lo que ves aquí"

    // MARK: - Privados

    /// Cuántos caracteres entran en la tercera línea de `accessoryRectangular`.
    ///
    /// A 172 pt de ancho y 12 pt de tipo entran unos 30; se deja margen porque el ancho real
    /// cambia con el tamaño de pantalla y con el tipo de letra accesible.
    private static let rectangularBudget = 26

    /// El qué lo decide `pendingSummary` —qué nombres caben—; el cómo se lee, esta capa.
    private static func compactPendingList(for snapshot: TodayWidgetSnapshot) -> String {
        snapshot
            .pendingSummary(budget: rectangularBudget, separatorWidth: separatorText.count)
            .joined(separator: separatorText)
    }

    private static let separatorText = " · "

    private static func pendingCount(_ count: Int) -> String {
        count == 1 ? "1 pendiente" : "\(count) pendientes"
    }

    /// La racha se nombra como "mejor racha" y no como "racha" a secas porque es la más larga
    /// **entre los hábitos de hoy**, no una racha de días cerrados. Llamarla sólo "racha"
    /// invitaría a leer un número que la app no calcula.
    private static func closedDayDetail(for snapshot: TodayWidgetSnapshot) -> String {
        let progress = "\(snapshot.completedCount) de \(snapshot.activeCount)"
        guard snapshot.bestCurrentStreak > 0 else { return progress }
        return "\(progress) · mejor racha \(snapshot.bestCurrentStreak)"
    }

    private static func restReason(for snapshot: TodayWidgetSnapshot) -> String {
        snapshot.restedEverythingScheduled
            ? "Marcaste como descanso todo lo de hoy."
            : "No hay hábitos programados."
    }

    private static func restDetail(for snapshot: TodayWidgetSnapshot) -> String {
        switch snapshot.tomorrowCount {
        case 0: return "Mañana tampoco hay nada."
        case 1: return "Mañana te espera 1."
        default: return "Mañana te esperan \(snapshot.tomorrowCount)."
        }
    }
}
