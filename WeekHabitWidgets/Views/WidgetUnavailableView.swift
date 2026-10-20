//
//  WidgetUnavailableView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// Estado honesto cuando no se pudo leer la base compartida.
///
/// No se dibuja un cero, ni un anillo vacío, ni una grilla en blanco: cualquiera de las tres
/// se vería igual que un día —o un año— impecable. Se dice que falta abrir la app, que es lo
/// único que resuelve el problema. Lo comparten los dos widgets.
struct WidgetUnavailableView: View {
    var isAccessory: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(WidgetUnavailableCopy.headline)
                .font(isAccessory ? .system(size: 15, weight: .semibold, design: .rounded) : AppFont.bodyEmphasis)
                .foregroundStyle(isAccessory ? Color.primary : AppColor.textPrimary)

            Text(WidgetUnavailableCopy.detail)
                .font(isAccessory ? .system(size: 11, design: .rounded) : AppFont.callout)
                .foregroundStyle(isAccessory ? Color.primary.opacity(0.68) : AppColor.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Texto del estado no disponible, en un solo lugar como el resto del copy del widget.
enum WidgetUnavailableCopy {
    static let headline = "Abre WeekHabit"
    static let detail = "Para poner al día lo que ves aquí"
}

#if DEBUG
import WidgetKit

// Se previsualiza a través de cada widget y no suelta: el fondo, el alineado y la variante
// `isAccessory` los pone el despachador de cada uno, y es eso lo que hay que ver.

#Preview("Circular · no disponible", as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .unavailable)
}

#Preview("Rectangular · no disponible", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .unavailable)
}

#Preview("Small · no disponible", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .unavailable)
}

#Preview("Medium · no disponible", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, content: .unavailable)
}

#Preview("Large · no disponible", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .unavailable)
}
#endif
