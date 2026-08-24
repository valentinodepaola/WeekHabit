//
//  TodayRectangularView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// `accessoryRectangular` — 172 × 76 en la pantalla de bloqueo.
///
/// Tres líneas fijas en los cuatro estados: contexto, titular y detalle. La estructura no
/// cambia entre estados para que el ojo encuentre siempre el dato en el mismo renglón.
///
/// El color lo pone el sistema, pero la **jerarquía** sí es nuestra: `.widgetAccentable()`
/// parte el widget en dos grupos, y solo el marcado toma el tinte que el usuario eligió para
/// su bloqueo. Se marca únicamente el encabezado, para que el titular y los nombres se queden
/// en el grupo de máximo contraste. Sin marcar nada, los tres renglones caían en el mismo
/// grupo y salían del mismo color lavado, que fue lo que se vio en la primera prueba.
struct TodayRectangularView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(TodayWidgetCopy.eyebrow(for: snapshot))
                .font(.system(size: 10, weight: .medium))
                .widgetAccentable()

            HStack(spacing: 4) {
                if let symbolName = snapshot.state.symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(TodayWidgetCopy.headline(for: snapshot))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }

            // Una sola línea: a 76 pt no cabe una cuarta. `compactPendingList` ya recorta por
            // nombre completo, así que este `lineLimit` es un cinturón, no el mecanismo.
            Text(TodayWidgetCopy.detail(for: snapshot))
                .font(.system(size: 12, design: .rounded))
                .opacity(0.78)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
import WidgetKit

#Preview("Rectangular · pendientes", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.samplePending))
}

#Preview("Rectangular · día cerrado", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleAllDone))
}

#Preview("Rectangular · descanso", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleRest))
}

#Preview("Rectangular · sin hábitos", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleEmpty))
}
#endif
