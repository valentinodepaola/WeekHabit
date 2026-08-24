//
//  InsightDateHelpers.swift
//  WeekHabit
//

import Foundation

extension Set where Element == Weekday {
    var weekdayListText: String {
        let names = Weekday.ordered
            .filter { contains($0) }
            .map { AppFormatters.lowercased($0.displayName) }

        switch names.count {
        case 0:
            return "tus días activos"
        case 1:
            return names[0]
        case 2:
            return names.joined(separator: " y ")
        default:
            return names.dropLast().joined(separator: ", ") + " y " + (names.last ?? "")
        }
    }
}

func insightDateRange(days: Int, reference: Date) -> ClosedRange<Date> {
    let end = AppCalendar.startOfDay(for: reference)
    let start = AppCalendar.current.date(byAdding: .day, value: -(days - 1), to: end) ?? end
    return start...end
}

func insightDays(from start: Date, to end: Date) -> [Date] {
    let startDay = AppCalendar.startOfDay(for: start)
    let endDay = AppCalendar.startOfDay(for: end)
    guard startDay <= endDay else { return [] }

    let dayCount = AppCalendar.current.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    return (0...dayCount).compactMap { offset in
        AppCalendar.current.date(byAdding: .day, value: offset, to: startDay)
    }
}
