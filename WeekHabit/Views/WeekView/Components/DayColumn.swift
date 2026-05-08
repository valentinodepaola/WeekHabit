//
//  DayColumn.swift
//  WeekHabit
//

import SwiftUI

struct DayColumn: View {
    let date: Date
    let isToday: Bool

    private var dayAbbrev: String {
        AppCalendar.weekday(of: date)
            .shortName
            .uppercased(with: Locale(identifier: "es_MX"))
    }

    private var dayNumber: String {
        String(AppCalendar.current.component(.day, from: date))
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(dayAbbrev)
                .font(AppFont.label)
                .foregroundStyle(isToday ? .white : AppColor.textSecondary)

            Text(dayNumber)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(isToday ? .white : AppColor.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(isToday ? AppColor.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m))
    }
}
