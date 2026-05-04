//
//  RhythmExperimentCard.swift
//  WeekHabit
//

import SwiftUI

struct RhythmExperimentCard: View {
    let suggestions: [RankedRhythmSuggestion]
    let onStart: (RhythmExperimentSuggestion) -> Void

    private var primarySuggestion: RankedRhythmSuggestion? {
        suggestions.first
    }

    private var secondarySuggestions: [RankedRhythmSuggestion] {
        Array(suggestions.dropFirst().prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.accent)

                Text("PRUEBAS DE 7 DÍAS")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1.3)
            }

            if let primarySuggestion {
                suggestionContent(primarySuggestion, isPrimary: true)

                if !secondarySuggestions.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(secondarySuggestions) { rankedSuggestion in
                            suggestionContent(rankedSuggestion, isPrimary: false)
                        }
                    }
                    .padding(.top, 2)
                }
            } else {
                Text("Aún necesito una señal concreta para proponerte una prueba con sentido.")
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

    private func suggestionContent(_ rankedSuggestion: RankedRhythmSuggestion, isPrimary: Bool) -> some View {
        let suggestion = rankedSuggestion.suggestion

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(suggestion.title)
                        .font(isPrimary ? AppFont.subtitle3 : AppFont.body2)
                        .fontWeight(isPrimary ? .regular : .semibold)
                        .foregroundStyle(AppColor.strongText)

                    Spacer(minLength: 8)

                    Text("\(Int((rankedSuggestion.priorityScore * 100).rounded()))")
                        .font(AppFont.captionApp)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.accent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(suggestion.message)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Label(suggestion.reason, systemImage: "lightbulb")
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text(rankedSuggestion.priorityReason)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
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
                    .padding(.vertical, isPrimary ? 12 : 10)
                    .background(isPrimary ? AppColor.accent : AppColor.accent.opacity(0.12))
                    .foregroundStyle(isPrimary ? .white : AppColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(isPrimary ? 0 : 12)
        .background {
            if !isPrimary {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColor.bgLight.opacity(0.72))
            }
        }
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
