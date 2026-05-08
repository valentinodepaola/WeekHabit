//
//  PlanScheduleSection.swift
//  WeekHabit
//
//  Sección "Hasta cuándo": fecha + meta de completitud agrupadas.
//

import SwiftUI

struct PlanScheduleSection: View {
    @Binding var endsAt: Date
    @Binding var targetCompletionRate: Double

    private var minimumDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: AppCalendar.startOfDay(for: .now)) ?? .now
    }

    private var percentText: String {
        "\(Int(targetCompletionRate * 100))%"
    }

    var body: some View {
        WHFormSection(
            title: "Hasta cuándo",
            helper: "Una semana es poco; un año, muy lejos. Entre 4 y 12 semanas suele funcionar."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HStack {
                    Text("Termina el")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $endsAt,
                        in: minimumDate...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(AppColor.accent)
                }
                .padding(AppSpacing.m)
                .background(AppColor.bgSunken)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.s) {
                    HStack {
                        Text("Meta de completitud")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text(percentText)
                            .font(AppFont.bodyEmphasis)
                            .foregroundStyle(AppColor.accent)
                            .monospacedDigit()
                    }

                    Slider(value: $targetCompletionRate, in: 0.5...1.0, step: 0.05)
                        .tint(AppColor.accent)

                    HStack {
                        Text("50%")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                        Spacer()
                        Text("100%")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }
                .padding(AppSpacing.m)
                .background(AppColor.bgSunken)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            }
        }
    }
}
