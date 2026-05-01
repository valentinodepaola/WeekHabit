//
//  InsightConfidenceCard.swift
//  WeekHabit
//

import SwiftUI

struct InsightConfidenceCard: View {
    let confidence: RhythmConfidence

    private var icon: String {
        switch confidence.level {
        case .high:
            return "checkmark.seal.fill"
        case .learning:
            return "waveform.path.ecg"
        case .low:
            return "hourglass"
        }
    }

    private var color: Color {
        switch confidence.level {
        case .high:
            return Color(hex: "#6f9a64")
        case .learning:
            return AppColor.editAction
        case .low:
            return AppColor.accent
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CONFIANZA DEL RITMO")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1)

                Text(confidence.title)
                    .font(AppFont.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.strongText)

                Text(confidence.detail)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
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
    .background(AppColor.bgLight)
}
