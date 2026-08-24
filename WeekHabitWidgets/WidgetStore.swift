//
//  WidgetStore.swift
//  WeekHabitWidgets
//

import Foundation
import SwiftData

/// Lectura de los hábitos desde la extensión.
///
/// El contenedor se abre **sin** `migrationPlan` a propósito: migrar el esquema es
/// responsabilidad exclusiva de la app. Si los dos procesos intentaran migrar la misma base
/// el resultado sería indefinido, así que la extensión solo se asoma a leer lo que la app ya
/// dejó listo. Por eso también puede fallar de forma legítima —el primer arranque tras una
/// actualización, antes de que la app corra— y ese fallo se muestra, no se disfraza de cero.
enum WidgetStore {

    static func loadSnapshot(referenceDate: Date = .now) throws -> TodayWidgetSnapshot {
        let schema = Schema(versionedSchema: SchemaV17.self)
        let container = try ModelContainer(
            for: schema,
            configurations: AppGroupStore.readOnlyConfiguration(schema: schema)
        )

        let context = ModelContext(container)
        // Mismo orden que `TodayView`, para que el widget y la pantalla listen los pendientes
        // igual. Si divergieran, el usuario vería un orden en el bloqueo y otro al entrar.
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let habits = try context.fetch(descriptor)

        return TodayWidgetSnapshot(habits: habits, referenceDate: referenceDate)
    }
}
