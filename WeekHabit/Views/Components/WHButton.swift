//
//  WHButton.swift
//  WeekHabit
//
//  Botón unificado del sistema. Variantes: primary, secondary, ghost, destructive.
//  Destructive sólo en confirmaciones — nunca en estados del usuario.
//

import SwiftUI

enum WHButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive
}

enum WHButtonSize {
    case regular
    case compact
}

struct WHButton: View {
    let title: String
    var icon: String? = nil
    var variant: WHButtonVariant = .primary
    var size: WHButtonSize = .regular
    var fullWidth: Bool = true
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                }
                Text(title)
                    .font(textFont)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundFill)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(borderOverlay)
        }
        .buttonStyle(WHPressableButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var textFont: Font {
        size == .compact ? AppFont.label : AppFont.bodyEmphasis
    }

    private var iconSize: CGFloat {
        size == .compact ? 13 : 15
    }

    private var horizontalPadding: CGFloat {
        size == .compact ? AppSpacing.m : AppSpacing.l
    }

    private var verticalPadding: CGFloat {
        size == .compact ? AppSpacing.s : AppSpacing.m
    }

    @ViewBuilder
    private var backgroundFill: some View {
        switch variant {
        case .primary:
            AppColor.accent
        case .secondary:
            AppColor.bgElevated
        case .ghost:
            Color.clear
        case .destructive:
            AppColor.destructiveAction
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return Color.white
        case .secondary:
            return AppColor.textPrimary
        case .ghost:
            return AppColor.accent
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

private struct WHPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppMotion.respectful(AppMotion.snap, reduceMotion), value: configuration.isPressed)
    }
}
