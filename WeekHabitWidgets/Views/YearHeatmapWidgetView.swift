//
//  YearHeatmapWidgetView.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

/// Reparte la entrada del widget del año: grilla real o estado no disponible, y pinta el
/// fondo del contenedor. Es lo único que decide entre las dos ramas.
struct YearHeatmapWidgetView: View {
    let entry: YearHeatmapEntry

    var body: some View {
        content
            .containerBackground(for: .widget) { AppColor.bgElevated }
            .widgetURL(WidgetDeepLink.insights)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .snapshot(let snapshot):
            YearHeatmapLargeView(snapshot: snapshot)
        case .unavailable:
            WidgetUnavailableView()
        }
    }
}
