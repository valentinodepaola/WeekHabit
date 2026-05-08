//
//  WHConfidenceTag.swift
//  WeekHabit
//
//  Etiqueta de confianza para Insights. Honesta sobre la cantidad de evidencia.
//  Copy alineado con IDENTIDAD_MISION.md ("la señal todavía se está formando").
//

import SwiftUI

enum WHConfidence {
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .low: return "Confianza baja"
        case .medium: return "Confianza media"
        case .high: return "Confianza alta"
        }
    }

    var dotColor: Color {
        switch self {
        case .low: return AppColor.warning
        case .medium: return AppColor.info
        case .high: return AppColor.success
        }
    }
}

struct WHConfidenceTag: View {
    let confidence: WHConfidence

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(confidence.dotColor)
                .frame(width: 6, height: 6)
            Text(confidence.label)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.xs)
        .background(confidence.dotColor.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(confidence.dotColor.opacity(0.25), lineWidth: 1)
        )
    }
}
