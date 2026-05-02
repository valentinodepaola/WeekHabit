//
//  WeekdaySelectionComponent.swift
//  WeekHabit
//

import SwiftUI

struct WeekdaySelectionComponent: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Weekday.ordered) { day in
                Button {
                    toggle(day)
                } label: {
                    Text(day.oneLetterName)
                        .font(AppFont.dayLabel)
                        .foregroundStyle(selectedDays.contains(day) ? .white : AppColor.mutedText)
                        .frame(width: 45, height: 45)
                        .background(selectedDays.contains(day) ? AppColor.accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.shortName)
            }
        }
    }

    private func toggle(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
