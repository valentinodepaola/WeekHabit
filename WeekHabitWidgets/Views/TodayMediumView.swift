//
//  TodayMediumView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// `systemMedium` — 364 × 170 en la pantalla de inicio.
///
/// La única familia con ancho para **nombrar** los hábitos, que es lo que de verdad empuja a
/// abrir la app: "3 pendientes" informa, "Leer · Correr · Meditar" reclama.
struct TodayMediumView: View {
    let snapshot: TodayWidgetSnapshot

    var body: some View {
        HStack(spacing: AppSpacing.l) {
            centerPiece
            details
        }
    }

    @ViewBuilder
    private var centerPiece: some View {
        if snapshot.state.showsProgressRing {
            WHProgressRing(
                progress: snapshot.progress,
                lineWidth: 9,
                size: 92,
                progressColor: snapshot.state.tint
            ) {
                ringCenter
            }
        } else {
            TodayWidgetGlyph(state: snapshot.state, size: 92)
        }
    }

    @ViewBuilder
    private var ringCenter: some View {
        if let symbolName = snapshot.state.symbolName {
            Image(systemName: symbolName)
                .font(.system(size: 30, weight: .semibold))
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

    @ViewBuilder
    private var details: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(eyebrow)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)

            switch snapshot.state {
            case .pending:
                habitList(snapshot.listedPending, isDone: false)
            case .allDone:
                Text(TodayWidgetCopy.headline(for: snapshot))
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                habitList(snapshot.listedCompleted, isDone: true)
            case .rest, .empty:
                Text(TodayWidgetCopy.headline(for: snapshot))
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                Text(TodayWidgetCopy.longDetail(for: snapshot))
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// El encabezado carga el progreso en los estados que lo tienen, para que la lista de
    /// abajo pueda quedarse solo con los nombres.
    ///
    /// Con pendientes va `progressText` y no `detail`: `detail` son los nombres de los
    /// hábitos, y usarlo acá los imprimía dos veces —una en el encabezado y otra en la lista.
    private var eyebrow: String {
        switch snapshot.state {
        case .pending:
            return "\(TodayWidgetCopy.today) · \(TodayWidgetCopy.progressText(for: snapshot).uppercased())"
        case .allDone:
            return "\(TodayWidgetCopy.today) · \(TodayWidgetCopy.detail(for: snapshot).uppercased())"
        case .rest, .empty:
            return TodayWidgetCopy.eyebrow(for: snapshot)
        }
    }

    @ViewBuilder
    private func habitList(_ rows: [TodayWidgetHabitRow], isDone: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs + 3) {
            ForEach(rows, id: \.title) { row in
                habitRow(row, isDone: isDone)
            }

            if let hidden = TodayWidgetCopy.hiddenPending(for: snapshot), !isDone {
                Text(hidden)
                    .font(AppFont.micro)
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.leading, 22)
            }
        }
    }

    private func habitRow(_ row: TodayWidgetHabitRow, isDone: Bool) -> some View {
        HStack(spacing: AppSpacing.s) {
            marker(for: row, isDone: isDone)
                .frame(width: 14)

            Text(row.title)
                .font(AppFont.callout)
                .foregroundStyle(isDone ? AppColor.textTertiary : AppColor.textPrimary)
                .strikethrough(isDone, color: AppColor.textTertiary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func marker(for row: TodayWidgetHabitRow, isDone: Bool) -> some View {
        if isDone {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.success)
        } else {
            Circle()
                .fill(Color(hex: row.colorHex))
                .frame(width: 8, height: 8)
        }
    }
}

#if DEBUG
import WidgetKit

#Preview("Medium · pendientes", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.samplePending))
}

#Preview("Medium · día cerrado", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleAllDone))
}

#Preview("Medium · descanso", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleRest))
}

#Preview("Medium · sin hábitos", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .snapshot(.sampleEmpty))
}
#endif
