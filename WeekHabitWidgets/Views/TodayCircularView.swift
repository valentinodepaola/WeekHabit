//
//  TodayCircularView.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

/// `accessoryCircular` — 72 × 72 en la pantalla de bloqueo.
///
/// Usa el `Gauge` del sistema y no `WHProgressRing`. En el bloqueo iOS aplica su propio
/// tratamiento de vibrancy y el tinte que el usuario haya elegido, y un anillo dibujado a
/// mano pelea contra eso: en la primera prueba en dispositivo el riel desaparecía y el arco
/// a cero se reducía a un punto suelto que parecía un error de render. El `Gauge` es el
/// componente que el sistema usa en sus propios widgets, así que resuelve contraste y tinte
/// por nosotros y queda a la par del clima o la batería.
///
/// El precio es perder el grosor y el centro a medida, y que el anillo ya no sea idéntico al
/// de la app. En el bloqueo eso no era nuestro de todas formas.
struct TodayCircularView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        if snapshot.state.showsProgressRing {
            gauge
        } else {
            glyph
        }
    }

    // MARK: - Con progreso

    /// Sin etiqueta bajo la cifra.
    ///
    /// La ranura inferior del `Gauge` la dimensiona el sistema y resultó demasiado angosta
    /// para "FALTAN": primero la cortó a "FALT…", y al encogerla hasta caber quedó ilegible.
    /// Una palabra que hay que descifrar aclara menos que ninguna, así que se quita. El arco
    /// da el contexto y la cifra es el dato.
    ///
    /// En `systemSmall` y `systemMedium` la etiqueta sí se conserva: ahí el centro es nuestro
    /// y hay espacio para que se lea.
    private var gauge: some View {
        Gauge(value: snapshot.progress) {
            EmptyView()
        } currentValueLabel: {
            centerLabel
        }
        .gaugeStyle(.accessoryCircular)
    }

    @ViewBuilder
    private var centerLabel: some View {
        if let symbolName = snapshot.state.symbolName {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
        } else {
            Text("\(snapshot.pendingCount)")
        }
    }

    // MARK: - Sin progreso

    /// Descanso y "sin hábitos" no dibujan medidor: no hay nada que medir, y un medidor
    /// vacío se lee como un cero, que a su vez se lee como una falla.
    private var glyph: some View {
        ZStack {
            AccessoryWidgetBackground()

            if let symbolName = snapshot.state.symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 26, weight: .semibold))
            }
        }
    }
}

#if DEBUG
#Preview("Circular · pendientes", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.samplePending))
}

#Preview("Circular · día cerrado", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleAllDone))
}

#Preview("Circular · descanso", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleRest))
}

#Preview("Circular · sin hábitos", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleEmpty))
}
#endif
