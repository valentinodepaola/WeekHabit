//
//  AppCalendar.swift
//  WeekHabit
//
//  Single source of truth for date math. Always use this instead of `Calendar.current`
//  directly so that timezone/locale assumptions stay consistent across the app.
//

import Foundation

enum AppCalendar {
    /// Locale-aware calendar with the user's current timezone.
    /// Force Monday as first weekday — the app's week is L–D regardless of locale.
    static var current: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.locale = .current
        cal.firstWeekday = Weekday.monday.rawValue
        return cal
    }

    /// Strip the time component, returning the start of the given day.
    static func startOfDay(for date: Date) -> Date {
        current.startOfDay(for: date)
    }

    /// `Weekday` for the given date.
    static func weekday(of date: Date) -> Weekday {
        let raw = current.component(.weekday, from: date)
        return Weekday(rawValue: raw) ?? .monday
    }

    /// Half-open range `[start, end)` covering the calendar week containing `date`.
    static func weekRange(containing date: Date) -> Range<Date> {
        let cal = current
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start
            ?? cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return start..<end
    }

    /// True iff the two dates fall on the same calendar day.
    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        current.isDate(a, inSameDayAs: b)
    }
}
