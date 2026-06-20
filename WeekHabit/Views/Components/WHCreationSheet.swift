//
//  WHCreationSheet.swift
//  WeekHabit
//
//  Sheet inferior unificada para creación. Reemplaza el Menu dropdown en el
//  botón "+" de TodayView y normaliza la nomenclatura: hábito / plan / foco.
//

import SwiftUI

enum WHCreationOption: Identifiable, CaseIterable, Equatable {
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
        case .habit: return "Una acción pequeña para repetir desde hoy."
        case .plan: return "Una meta sostenida por varios hábitos."
        case .focus: return "Una sesión para actuar ahora."
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
    var focusDisabledReason: String?
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

            VStack(spacing: AppSpacing.m) {
                if availableOptions.contains(.habit) {
                    optionRow(.habit, isPrimary: true)
                }

                VStack(spacing: AppSpacing.s) {
                    ForEach(secondaryOptions) { option in
                        optionRow(
                            option,
                            isPrimary: false,
                            disabledReason: disabledReason(for: option)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgCanvas)
    }

    private var secondaryOptions: [WHCreationOption] {
        availableOptions.filter { $0 != .habit }
    }

    private func disabledReason(for option: WHCreationOption) -> String? {
        switch option {
        case .focus:
            return focusDisabledReason
        case .habit, .plan:
            return nil
        }
    }

    private func optionRow(
        _ option: WHCreationOption,
        isPrimary: Bool,
        disabledReason: String? = nil
    ) -> some View {
        let isEnabled = disabledReason == nil

        return Button {
            guard isEnabled else { return }
            onSelect(option)
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                Image(systemName: option.icon)
                    .font(.system(size: isPrimary ? 21 : 18, weight: .semibold))
                    .foregroundStyle(iconColor(isPrimary: isPrimary, isEnabled: isEnabled))
                    .frame(width: isPrimary ? 52 : 44, height: isPrimary ? 52 : 44)
                    .background(iconBackground(isPrimary: isPrimary, isEnabled: isEnabled))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(option.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textTertiary)

                    Text(disabledReason ?? option.subtitle)
                        .font(AppFont.callout)
                        .foregroundStyle(isEnabled ? AppColor.textSecondary : AppColor.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.s)

                if isEnabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isPrimary ? AppColor.accent : AppColor.textTertiary)
                } else {
                    Image(systemName: "lock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
            .padding(isPrimary ? AppSpacing.l : AppSpacing.m)
            .background(rowBackground(isPrimary: isPrimary, isEnabled: isEnabled))
            .clipShape(RoundedRectangle(cornerRadius: isPrimary ? AppRadius.l : AppRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: isPrimary ? AppRadius.l : AppRadius.m, style: .continuous)
                    .strokeBorder(rowBorder(isPrimary: isPrimary, isEnabled: isEnabled), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.72)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel(for: option, disabledReason: disabledReason))
    }

    private func iconColor(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return AppColor.textTertiary }
        return isPrimary ? .white : AppColor.accent
    }

    private func iconBackground(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return AppColor.bgSunken }
        return isPrimary ? AppColor.accent : AppColor.accentMuted
    }

    private func rowBackground(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return AppColor.bgElevated.opacity(0.72) }
        return isPrimary ? AppColor.accentMuted.opacity(0.55) : AppColor.bgElevated
    }

    private func rowBorder(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return AppColor.divider.opacity(0.7) }
        return isPrimary ? AppColor.accent.opacity(0.28) : AppColor.divider
    }

    private func accessibilityLabel(for option: WHCreationOption, disabledReason: String?) -> String {
        guard let disabledReason else { return option.title }
        return "\(option.title), no disponible. \(disabledReason)"
    }
}
