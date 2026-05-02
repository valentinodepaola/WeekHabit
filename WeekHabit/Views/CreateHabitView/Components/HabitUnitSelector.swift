//
//  HabitUnitSelector.swift
//  WeekHabit
//

import SwiftUI

struct HabitUnitSelector: View {
    @Binding var measurementUnit: HabitMeasurementUnit
    let units: [HabitMeasurementUnit]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(units) { unit in
                Button {
                    measurementUnit = unit
                } label: {
                    Text(unit.displayTitle)
                        .font(AppFont.formSectionText2)
                        .fontWeight(.semibold)
                        .foregroundStyle(measurementUnit == unit ? .white : AppColor.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(measurementUnit == unit ? AppColor.accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
