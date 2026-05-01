//
//  DayColumn.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
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
        VStack(spacing: 6) {
            Text(dayAbbrev)
                .font(AppFont.formSectionText)
                .foregroundStyle(isToday ? .white : AppColor.mutedText)

            Text(dayNumber)
                .font(AppFont.dayLabel)
                .foregroundStyle(isToday ? .white : AppColor.strongText)
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(isToday ? AppColor.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}
