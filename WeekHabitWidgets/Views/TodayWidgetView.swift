//
//  TodayWidgetView.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

/// Reparte la entrada a la vista de su familia y pinta el fondo del contenedor.
///
/// Es lo único que sabe de `WidgetFamily`: cada vista de familia recibe ya el snapshot y no
/// vuelve a preguntar dónde está dibujando.
struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: TodayWidgetEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    AppColor.bgElevated
                }
            }
            .widgetURL(WidgetDeepLink.today)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .snapshot(let snapshot):
            familyView(snapshot)
        case .unavailable:
            TodayUnavailableView(isAccessory: isAccessory)
        }
    }

    @ViewBuilder
    private func familyView(_ snapshot: TodayWidgetSnapshot) -> some View {
        switch family {
        case .accessoryCircular:
            TodayCircularView(snapshot: snapshot)
        case .accessoryRectangular:
            TodayRectangularView(snapshot: snapshot)
        case .systemMedium:
            TodayMediumView(snapshot: snapshot)
        default:
            TodaySmallView(snapshot: snapshot)
        }
    }

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular
    }
}

/// Estado honesto cuando no se pudo leer la base compartida.
///
/// No se dibuja un cero ni un anillo vacío: eso se vería igual que un día impecable. Se dice
/// que falta abrir la app, que es lo único que resuelve el problema.
struct TodayUnavailableView: View {
    let isAccessory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(TodayWidgetCopy.unavailableHeadline)
                .font(isAccessory ? .system(size: 15, weight: .semibold, design: .rounded) : AppFont.bodyEmphasis)
                .foregroundStyle(isAccessory ? Color.primary : AppColor.textPrimary)

            Text(TodayWidgetCopy.unavailableDetail)
                .font(isAccessory ? .system(size: 11, design: .rounded) : AppFont.callout)
                .foregroundStyle(isAccessory ? Color.primary.opacity(0.68) : AppColor.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
