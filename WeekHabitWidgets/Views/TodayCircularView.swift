//
//  TodayCircularView.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

/// `accessoryCircular` — 72 × 72 en la pantalla de bloqueo.
///
/// Monocromático: el sistema tiñe la vista completa, así que acá no se usa ningún token de
/// color. Todo se resuelve con opacidades sobre el color heredado.
struct TodayCircularView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if snapshot.state.showsProgressRing {
                ring
            } else {
                dashedRing
            }

            center
        }
    }

    private var ring: some View {
        Circle()
            .trim(from: 0, to: max(0.001, snapshot.progress))
            .stroke(.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .padding(6)
            .background(Circle().stroke(.primary.opacity(0.25), lineWidth: 5).padding(6))
    }

    private var dashedRing: some View {
        Circle()
            .stroke(
                .primary.opacity(0.3),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [3, 9])
            )
            .padding(6)
    }

    @ViewBuilder
    private var center: some View {
        if let symbolName = snapshot.state.symbolName {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .semibold))
        } else {
            VStack(spacing: 0) {
                Text("\(snapshot.pendingCount)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text(TodayWidgetCopy.remainingLabel)
                    .font(.system(size: 8, weight: .medium))
                    .opacity(0.7)
            }
        }
    }
}

#if DEBUG
import WidgetKit

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
