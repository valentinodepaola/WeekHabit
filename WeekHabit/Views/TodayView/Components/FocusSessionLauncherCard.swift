//
//  FocusSessionLauncherCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusSessionLauncherCard: View {
    let remainingCount: Int
    let onStart: () -> Void

    private var detail: String {
        if remainingCount == 0 {
            return "Puedes usar una sesión para registrar hábitos hechos en tiempo real."
        }

        if remainingCount == 1 {
            return "Enfócate en 1 hábito y deja una marca más confiable para Insights."
        }

        return "Enfócate en \(remainingCount) hábitos y deja marcas más confiables para Insights."
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColor.accent.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión de ritmo")
                    .font(AppFont.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.strongText)

                Text(detail)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                onStart()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}
