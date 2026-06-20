//
//  CreateHabitOptionalCard.swift
//  WeekHabit
//
//  Card colapsable para opciones avanzadas del paso 3. Cerrada muestra un
//  resumen del valor actual; abierta expone el control completo.
//

import SwiftUI

struct CreateHabitOptionalCard<Content: View>: View {
    let icon: String
    let title: String
    let summary: String
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        icon: String,
        title: String,
        summary: String,
        isInitiallyExpanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.summary = summary
        self.content = content
        _isExpanded = State(initialValue: isInitiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.m) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 32, height: 32)
                        .background(AppColor.accentMuted.opacity(0.5))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFont.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)

                        Text(summary)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(AppSpacing.m)
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title). \(summary)")
            .accessibilityAddTraits(isExpanded ? [.isSelected] : [])
            .accessibilityHint(isExpanded ? "Toca para contraer" : "Toca para expandir")

            if isExpanded {
                content()
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.bottom, AppSpacing.m)
            }
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}

#Preview {
    VStack(spacing: AppSpacing.s) {
        CreateHabitOptionalCard(
            icon: "text.alignleft",
            title: "Nota",
            summary: "Contexto para ti"
        ) {
            Text("Contenido expandido")
        }

        CreateHabitOptionalCard(
            icon: "snowflake",
            title: "Comodín semanal",
            summary: "Activado",
            isInitiallyExpanded: true
        ) {
            Toggle("Permitir comodín semanal", isOn: .constant(true))
        }
    }
    .padding()
    .background(AppColor.bgCanvas)
}
