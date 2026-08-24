//
//  AppFormatters.swift
//  WeekHabit
//

import Foundation

enum AppFormatters {
    static let esMXLocale = Locale(identifier: "es_MX")

    static func string(from date: Date, format: String) -> String {
        formatter(format: format).string(from: date)
    }

    static func uppercasedString(
        from date: Date,
        format: String,
        foldingDiacritics: Bool = false
    ) -> String {
        var value = string(from: date, format: format)
        if foldingDiacritics {
            value = value.folding(options: .diacriticInsensitive, locale: esMXLocale)
        }
        return value.uppercased(with: esMXLocale)
    }

    static func uppercased(_ value: String) -> String {
        value.uppercased(with: esMXLocale)
    }

    static func lowercased(_ value: String) -> String {
        value.lowercased(with: esMXLocale)
    }

    private static func formatter(format: String) -> DateFormatter {
        let cacheKey = "WeekHabit.AppFormatters.\(format)"
        if let cached = Thread.current.threadDictionary[cacheKey] as? DateFormatter {
            return cached
        }

        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = esMXLocale
        formatter.dateFormat = format
        Thread.current.threadDictionary[cacheKey] = formatter
        return formatter
    }
}
