//
//  RhythmExperimentCard.swift
//  WeekHabit
//
//  "Un insight bueno no dice 'eres inconsistente'. Dice 'este patrón sugiere
//  una prueba concreta'." — IDENTIDAD_MISION.md
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
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(AppFont.iconMedium)
                    .foregroundStyle(AppColor.info)

                Text("ESTOS PATRONES SUGIEREN UNA PRUEBA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            if let primarySuggestion {
                suggestionContent(primarySuggestion, isPrimary: true)

                if !secondarySuggestions.isEmpty {
                    VStack(spacing: AppSpacing.s) {
                        ForEach(secondarySuggestions) { rankedSuggestion in
                            suggestionContent(rankedSuggestion, isPrimary: false)
                        }
                    }
                    .padding(.top, AppSpacing.xxs)
                }
            } else {
                Text("Aún necesito una señal concreta para proponerte una prueba con sentido. Sigue marcando.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insightCard()
    }

    private func suggestionContent(_ rankedSuggestion: RankedRhythmSuggestion, isPrimary: Bool) -> some View {
        let suggestion = rankedSuggestion.suggestion

        return VStack(alignment: .leading, spacing: AppSpacing.s) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                    Text(suggestion.title)
                        .font(isPrimary ? AppFont.headline : AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer(minLength: AppSpacing.s)

                    Text("\(Int((rankedSuggestion.priorityScore * 100).rounded()))")
                        .font(AppFont.label)
                        .monospacedDigit()
                        .foregroundStyle(AppColor.info)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.info.opacity(0.14))
                        .clipShape(Capsule())
                }

                Text(suggestion.message)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(suggestion.reason, systemImage: "lightbulb")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.info)
                    .fixedSize(horizontal: false, vertical: true)

                Text(rankedSuggestion.priorityReason)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
            }

            HStack(spacing: AppSpacing.s) {
                RhythmChip(text: suggestion.daySummary, icon: "calendar")
                if let hourText = suggestion.hourText {
                    RhythmChip(text: hourText, icon: "clock")
                }
            }

            WHButton(
                title: "Probar 7 días",
                icon: "play.fill",
                variant: isPrimary ? .primary : .secondary,
                size: isPrimary ? .regular : .compact,
                fullWidth: true
            ) {
                onStart(suggestion)
            }
        }
        .padding(isPrimary ? 0 : AppSpacing.m)
        .background {
            if !isPrimary {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppColor.bgSunken.opacity(0.7))
            }
        }
    }
}

private struct RhythmChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(AppFont.label)
            .foregroundStyle(AppColor.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.s)
            .background(AppColor.bgSunken)
            .clipShape(Capsule())
    }
}
