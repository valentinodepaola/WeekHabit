//
//  TodayUrgeExplainer.swift
//  WeekHabit
//
//  Explica qué es un impulso la primera vez que hay un hábito a dejar en pendientes. Va
//  fuera del grupo, arriba de él, para no romper el ritmo de las filas ni deslizarse con ellas.
//

import SwiftUI

struct TodayUrgeExplainer: View {
    let color: Color
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.s) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text("Registra un impulso cuando aparezcan ganas de hacerlo. Eso ayuda a encontrar patrones sin contarlo como slip.")
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ocultar explicación de impulso")
        }
        .padding(AppSpacing.s)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(color.opacity(0.20), lineWidth: 1)
        }
    }
}
