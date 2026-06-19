//
//  InsightConfidenceCard.swift
//  WeekHabit
//

import SwiftUI

struct InsightConfidenceCard: View {
    let confidence: RhythmConfidence

    private var icon: String {
        switch confidence.level {
        case .high: return "checkmark.seal.fill"
        case .learning: return "waveform.path.ecg"
        case .low: return "hourglass"
        }
    }

    private var color: Color {
        switch confidence.level {
        case .high: return AppColor.success
        case .learning: return AppColor.info
        case .low: return AppColor.warning
        }
    }

    private var equivalentTag: WHConfidence {
        switch confidence.level {
        case .high: return .high
        case .learning: return .medium
        case .low: return .low
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                Image(systemName: icon)
                    .font(AppFont.iconMedium)
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.s) {
                    Text("CONFIANZA DEL RITMO")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                    WHConfidenceTag(confidence: equivalentTag)
                }

                Text(confidence.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)

                Text(confidence.detail)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .insightCard()
    }
}

#Preview {
    InsightConfidenceCard(
        confidence: RhythmConfidence(
            trustedMarks: 12,
            totalMarks: 16,
            focusSessionMarks: 4
        )
    )
    .padding()
    .background(AppColor.bgCanvas)
}
