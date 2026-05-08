//
//  WHCreationSheet.swift
//  WeekHabit
//
//  Sheet inferior unificada para creación. Reemplaza el Menu dropdown en el
//  botón "+" de TodayView y normaliza la nomenclatura: hábito / plan / foco.
//

import SwiftUI

enum WHCreationOption: Identifiable {
    case habit
    case plan
    case focus

    var id: String {
        switch self {
        case .habit: return "habit"
        case .plan: return "plan"
        case .focus: return "focus"
        }
    }

    var title: String {
        switch self {
        case .habit: return "Nuevo hábito"
        case .plan: return "Nuevo plan"
        case .focus: return "Sesión de foco"
        }
    }

    var subtitle: String {
        switch self {
        case .habit: return "Una acción que se repite con señal y ritmo."
        case .plan: return "Una meta sostenida por hábitos pequeños."
        case .focus: return "Actuar ahora y dejar evidencia confiable."
        }
    }

    var icon: String {
        switch self {
        case .habit: return "leaf"
        case .plan: return "target"
        case .focus: return "timer"
        }
    }
}

struct WHCreationSheet: View {
    var availableOptions: [WHCreationOption] = [.habit, .plan, .focus]
    var onSelect: (WHCreationOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Crear")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text("¿Qué quieres construir?")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
            }

            VStack(spacing: AppSpacing.s) {
                ForEach(availableOptions) { option in
                    optionRow(option)
                }
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgCanvas)
    }

    private func optionRow(_ option: WHCreationOption) -> some View {
        Button {
            onSelect(option)
            dismiss()
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 44, height: 44)
                    .background(AppColor.accentMuted)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(option.subtitle)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.s)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(AppSpacing.m)
            .background(AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
