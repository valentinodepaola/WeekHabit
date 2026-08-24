//
//  TodayWidgetSamples.swift
//  WeekHabitWidgets
//

#if DEBUG
import Foundation

/// Los cuatro estados con datos de muestra, para las previews.
///
/// Están acá y no dentro de cada preview para que las cuatro familias dibujen exactamente el
/// mismo día: si cada archivo inventara sus propios números, comparar familias entre sí
/// dejaría de decir nada.
extension TodayWidgetSnapshot {

    static let samplePending = TodayWidgetSnapshot(
        state: .pending,
        pendingCount: 3,
        completedCount: 2,
        activeCount: 5,
        scheduledCount: 5,
        progress: 0.4,
        listedPending: [
            TodayWidgetHabitRow(title: "Leer", colorHex: "#5c89a8"),
            TodayWidgetHabitRow(title: "Correr", colorHex: "#5e8c61"),
            TodayWidgetHabitRow(title: "Meditar", colorHex: "#8b7fb0")
        ],
        tomorrowCount: 5
    )

    static let sampleAllDone = TodayWidgetSnapshot(
        state: .allDone,
        completedCount: 5,
        activeCount: 5,
        scheduledCount: 5,
        progress: 1,
        listedCompleted: [
            TodayWidgetHabitRow(title: "Leer", colorHex: "#5c89a8"),
            TodayWidgetHabitRow(title: "Correr", colorHex: "#5e8c61"),
            TodayWidgetHabitRow(title: "Meditar", colorHex: "#8b7fb0")
        ],
        bestCurrentStreak: 12,
        tomorrowCount: 5
    )

    static let sampleRest = TodayWidgetSnapshot(state: .rest, tomorrowCount: 3)

    static let sampleEmpty = TodayWidgetSnapshot(state: .empty)
}
#endif
