//
//  TodayRectangularView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// `accessoryRectangular` — 172 × 76 en la pantalla de bloqueo.
///
/// Tres líneas fijas en los cuatro estados: contexto, titular y detalle. La estructura no
/// cambia entre estados para que el ojo encuentre siempre el dato en el mismo renglón.
/// Monocromático, como toda la pantalla de bloqueo.
struct TodayRectangularView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(TodayWidgetCopy.eyebrow(for: snapshot))
                .font(.system(size: 10, weight: .medium))
                .opacity(0.62)

            HStack(spacing: 4) {
                if let symbolName = snapshot.state.symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(TodayWidgetCopy.headline(for: snapshot))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }

            // Una sola línea: a 76 pt no cabe una cuarta, y un nombre partido a la mitad se
            // lee como un error de la app y no como una lista larga.
            Text(TodayWidgetCopy.detail(for: snapshot))
                .font(.system(size: 12, design: .rounded))
                .opacity(0.68)
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
