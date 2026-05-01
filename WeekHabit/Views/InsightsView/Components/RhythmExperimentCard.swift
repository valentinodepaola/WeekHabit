//
//  RhythmExperimentCard.swift
//  WeekHabit
//

import SwiftUI

struct RhythmExperimentCard: View {
    let suggestion: RhythmExperimentSuggestion?
    let onStart: (RhythmExperimentSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.accent)

                Text("PRUEBA DE 7 DÍAS")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1.3)
            }

            if let suggestion {
                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.title)
                        .font(AppFont.subtitle3)
                        .foregroundStyle(AppColor.strongText)

                    Text(suggestion.message)
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(suggestion.reason, systemImage: "lightbulb")
                        .font(AppFont.captionApp)
                        .foregroundStyle(AppColor.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    RhythmChip(text: suggestion.daySummary, icon: "calendar")

                    if let hourText = suggestion.hourText {
                        RhythmChip(text: hourText, icon: "clock")
                    }
                }

                Button {
                    onStart(suggestion)
                } label: {
                    Text("Probar 7 días")
                        .font(AppFont.body2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColor.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Text("Aún necesito algunas marcas más para proponerte una prueba con sentido.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}

private struct RhythmChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(AppFont.formSectionText2)
            .foregroundStyle(AppColor.mutedText)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppColor.bgLight)
            .clipShape(Capsule())
    }
}
