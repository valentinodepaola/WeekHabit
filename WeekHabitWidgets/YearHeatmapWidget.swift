//
//  YearHeatmapWidget.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

/// "Año de constancia" — solo pantalla de inicio, solo `systemLarge`.
///
/// Muestra un año en una grilla de un cuadro por día, agregando todos los hábitos de día
/// fijo: la opacidad de cada día es la fracción de lo programado ese día que se cumplió.
struct YearHeatmapWidget: Widget {
    private let kind = "YearHeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YearHeatmapProvider()) { entry in
            YearHeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Año de constancia")
        .description("Tu constancia del año, un cuadro por día.")
        .supportedFamilies([.systemLarge])
    }
}

struct YearHeatmapProvider: TimelineProvider {

    func placeholder(in context: Context) -> YearHeatmapEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (YearHeatmapEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<YearHeatmapEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Self.nextRefresh(after: entry.date))))
    }

    private func makeEntry(date: Date = .now) -> YearHeatmapEntry {
        do {
            return YearHeatmapEntry(date: date, content: .snapshot(try WidgetStore.loadYearHeatmap(referenceDate: date)))
        } catch {
            return YearHeatmapEntry(date: date, content: .unavailable)
        }
    }

    /// La grilla solo cambia sola al cruzar la medianoche: ahí entra un día nuevo. Dentro del
    /// mismo día la refresca la app al pasar a segundo plano. Se calcula con `AppCalendar`
    /// para que el corte siga siendo correcto si el usuario cruzó una zona horaria.
    private static func nextRefresh(after date: Date) -> Date {
        let calendar = AppCalendar.current
        let startOfToday = AppCalendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday)
            ?? date.addingTimeInterval(60 * 60)
    }
}
