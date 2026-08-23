//
//  TodayHelpSheet.swift
//  WeekHabit
//
//  Vista tonta sobre `HelpCatalog`: aquí no vive ni una frase de copy.
//  Calcada de `WeekLegendSheet`, con el color de cada fila tomado del token que ese estado ya
//  usa en el resto de la app —descanso en `info` como en el estado vacío de Hoy, slip en
//  `warning` e impulso en `accent` como en la cuadrícula de Semana—.
//

import SwiftUI

struct TodayHelpSheet: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header

                VStack(spacing: AppSpacing.s) {
                    ForEach(HelpCatalog.topics) { topic in
                        topicRow(topic)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            // Más aire arriba que en el resto de hojas: el indicador de arrastre se come el
            // espacio y el título quedaba pegado al borde.
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.bgCanvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(HelpCatalog.title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text(HelpCatalog.subtitle)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func topicRow(_ topic: HelpTopic) -> some View {
        let tint = color(for: topic.tint)

        return HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: topic.icon)
                .font(AppFont.iconSmall)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(topic.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(topic.detail)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func color(for tint: HelpTopicTint) -> Color {
        switch tint {
        case .accent: return AppColor.accent
        case .success: return AppColor.success
        case .warning: return AppColor.warning
        case .info: return AppColor.info
        }
    }
}

#Preview("Light") {
    TodayHelpSheet()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TodayHelpSheet()
        .preferredColorScheme(.dark)
}
