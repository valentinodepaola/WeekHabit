//
//  WidgetRefreshService.swift
//  WeekHabit
//

import Foundation
import WidgetKit

/// Le avisa al widget que sus datos cambiaron.
///
/// Se llama desde un solo lugar —cuando la escena deja de estar activa— y no desde cada
/// mutación. Son dos razones:
///
/// 1. Los puntos de escritura son muchos (`HabitTrackingService`, `HabitEditorService`,
///    `HabitLifecycleService`, el onboarding, los planes) y basta olvidar uno para que el
///    widget muestre un número viejo sin que nada falle.
/// 2. El widget solo importa cuando la app **no** está en primer plano. Salir de `.active` es
///    el momento exacto en que el dato pasa a ser visible fuera de la app.
enum WidgetRefreshService {
    static func reloadTodayWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
