//
//  ActiveDaysComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//

import SwiftUI

struct ActiveDaysComponent: View {
    
    @Binding var selectedDays: Set<Weekday>
    let targetDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                Text("Días activos")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .textCase(.uppercase)

                Text("·")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.accent)
            }
            
            HStack(spacing: 7) {
                ForEach(Weekday.ordered) { day in
                    dayButton(for: day)
                }
            }
        }
    }
    
    private func dayButton(for day: Weekday) -> some View {
        let isSelected = selectedDays.contains(day)
        
        return Button {
            toggle(day)
        } label: {
            Text(day.oneLetterName)
                .font(AppFont.dayLabel)
                .foregroundStyle(isSelected ? .white : AppColor.mutedText)
                .frame(width: 45, height: 45)
                .background(isSelected ? AppColor.accent : AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.shortName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private func toggle(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            return
        }
        
        guard targetDays > 0, selectedDays.count < targetDays else { return }
        selectedDays.insert(day)
    }
}

#Preview {
    ActiveDaysComponent(
        selectedDays: .constant([.monday, .wednesday, .friday, .sunday]),
        targetDays: 4
    )
}
