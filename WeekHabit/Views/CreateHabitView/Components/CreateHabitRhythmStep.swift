//
//  CreateHabitRhythmStep.swift
//  WeekHabit
//
//  Paso 2 — Ritmo: qué días de la semana y cómo se registra cada sesión.
//

import SwiftUI

struct CreateHabitRhythmStep: View {
    @Binding var draft: HabitDraft

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let quantityUnits: [HabitMeasurementUnit] = [
        .minutes,
        .pages,
        .kilometers,
        .glasses,
        .repetitions
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            WHFormSection(
                title: "¿Qué días?",
                helper: "La semana es la unidad. Empieza con menos días de los que crees."
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    HabitScheduleSelector(
                        scheduleKind: $draft.scheduleKind,
                        selectedActiveDays: $draft.activeDays,
                        showFlexible: draft.direction != .`break`
                    )

                    if draft.scheduleKind == .specificDays {
                        WeekdaySelectionComponent(selectedDays: $draft.activeDays)
                    } else if draft.scheduleKind == .timesPerWeek {
                        TimesPerWeekComponent(timesPerWeek: $draft.timesPerWeek)
                    }
                }
                .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: draft.scheduleKind)
            }

            WHFormSection(
                title: "¿Cómo lo registras?",
                helper: trackingHelper
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    HabitTrackingSelector(trackingKind: $draft.trackingKind)

                    if draft.trackingKind == .quantity {
                        HabitUnitSelector(
                            measurementUnit: $draft.measurementUnit,
                            units: quantityUnits
                        )
                        HabitTargetValueField(
                            targetValueText: $draft.targetValueText,
                            unitLabel: draft.measurementUnit.shortTitle
                        )
                    }
                }
                .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: draft.trackingKind)
            }
        }
    }

    private var trackingHelper: String {
        draft.trackingKind == .check
            ? "Un toque al día y listo."
            : "Registra cuánto hiciste; se completa al llegar a la meta."
    }
}

#Preview {
    ScrollView {
        CreateHabitRhythmStep(draft: .constant(HabitDraft()))
            .padding()
    }
    .background(AppColor.bgCanvas)
}
