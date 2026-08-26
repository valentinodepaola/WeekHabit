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
            WidgetUnavailableView(isAccessory: isAccessory)
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
