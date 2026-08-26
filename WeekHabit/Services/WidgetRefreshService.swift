//
//  WidgetRefreshService.swift
//  WeekHabit
//

import Foundation
import WidgetKit

/// Le avisa a los widgets que sus datos cambiaron.
///
/// Se llama desde un solo lugar —cuando la escena deja de estar activa— y no desde cada
/// mutación. Son dos razones:
///
/// 1. Los puntos de escritura son muchos (`HabitTrackingService`, `HabitEditorService`,
///    `HabitLifecycleService`, el onboarding, los planes) y basta olvidar uno para que un
///    widget muestre un número viejo sin que nada falle.
/// 2. Los widgets solo importan cuando la app **no** está en primer plano. Salir de `.active`
///    es el momento exacto en que el dato pasa a ser visible fuera de la app.
///
/// `reloadAllTimelines()` cubre los dos widgets (Pendientes de hoy y Año de constancia) de una
/// sola llamada; un widget nuevo hereda el refresco sin tocar esto.
enum WidgetRefreshService {
    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
