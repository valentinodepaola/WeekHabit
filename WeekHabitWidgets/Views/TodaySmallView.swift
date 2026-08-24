//
//  TodaySmallView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// `systemSmall` — 170 × 170 en la pantalla de inicio.
///
/// Una sola cifra manda. El anillo es el mismo `WHProgressRing` que usa la app, para que el
/// progreso del día se dibuje igual dentro y fuera.
struct TodaySmallView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        VStack(spacing: AppSpacing.s) {
            Text(TodayWidgetCopy.eyebrow(for: snapshot))
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            centerPiece

            Text(bottomText)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var centerPiece: some View {
        if snapshot.state.showsProgressRing {
            WHProgressRing(
                progress: snapshot.progress,
                lineWidth: 8,
                size: 76,
                progressColor: snapshot.state.tint
            ) {
                ringCenter
            }
        } else {
            TodayWidgetGlyph(state: snapshot.state, size: 76)
        }
    }

    @ViewBuilder
    private var ringCenter: some View {
        if let symbolName = snapshot.state.symbolName {
            Image(systemName: symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(snapshot.state.tint)
        } else {
            VStack(spacing: 0) {
                Text("\(snapshot.pendingCount)")
                    .font(AppFont.dataMetric)
                    .foregroundStyle(AppColor.textPrimary)
                Text(TodayWidgetCopy.remainingLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
    }

    /// En `systemSmall` la racha se omite aunque exista: abreviarla a "racha 12" invitaría a
    /// leerla como días cerrados seguidos, que no es lo que la app calcula. Se dice completa
    /// en las familias que tienen ancho para decirla bien.
    private var bottomText: String {
        switch snapshot.state {
        case .pending: return TodayWidgetCopy.progressText(for: snapshot)
        case .allDone: return TodayWidgetCopy.headline(for: snapshot)
        case .rest, .empty: return TodayWidgetCopy.headline(for: snapshot)
        }
    }
}

#if DEBUG
import WidgetKit

#Preview("Small · pendientes", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.samplePending))
}

#Preview("Small · día cerrado", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleAllDone))
}

#Preview("Small · descanso", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleRest))
}

#Preview("Small · sin hábitos", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleEmpty))
}
#endif
