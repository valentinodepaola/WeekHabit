//
//  HabitMeasurementSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitMeasurementSection: View {
    @Binding var trackingKind: HabitTrackingKind
    @Binding var measurementUnit: HabitMeasurementUnit
    @Binding var targetValueText: String

    private let quantityUnits: [HabitMeasurementUnit] = [
        .minutes,
        .pages,
        .kilometers,
        .glasses,
        .repetitions
    ]

    var body: some View {
        CreateHabitFormSection(
            title: "Medición",
            helper: "Lo cuantificable es más fácil de observar y ajustar."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HabitTrackingSelector(trackingKind: $trackingKind)

                if trackingKind == .quantity {
                    HabitUnitSelector(
                        measurementUnit: $measurementUnit,
                        units: quantityUnits
                    )
                    HabitTargetValueField(
                        targetValueText: $targetValueText,
                        unitLabel: measurementUnit.shortTitle
                    )
                }
            }
        }
    }
}
