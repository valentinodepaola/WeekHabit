//
//  TodayWidget.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

struct TodayWidget: Widget {
    private let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Pendientes de hoy")
        .description("Lo que te falta hoy, sin abrir la app.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall,
            .systemMedium
        ])
    }
}

struct TodayWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodayWidgetEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Self.nextRefresh(after: entry.date))))
    }

    private func makeEntry(date: Date = .now) -> TodayWidgetEntry {
        do {
            return TodayWidgetEntry(date: date, content: .snapshot(try WidgetStore.loadSnapshot(referenceDate: date)))
        } catch {
            return TodayWidgetEntry(date: date, content: .unavailable)
        }
    }

    /// El widget se reconstruye solo al cambiar el día.
    ///
    /// Dentro del mismo día lo refresca la app al pasar a segundo plano, así que acá alcanza
    /// con cubrir el único cambio que ocurre sin que nadie toque nada: la medianoche. Se
    /// calcula con `AppCalendar` y no con `Calendar.current` para que el corte siga siendo
    /// correcto si el usuario cruzó una zona horaria.
    private static func nextRefresh(after date: Date) -> Date {
        let calendar = AppCalendar.current
        let startOfToday = AppCalendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday)
            ?? date.addingTimeInterval(60 * 60)
    }
}
