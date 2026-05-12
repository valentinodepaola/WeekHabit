//
//  WeekGridCell.swift
//  WeekHabit
//

import SwiftUI

struct WeekGridCell: View {
    enum State: Equatable {
        case completed
        /// Marca registrada retroactivamente (todos los entries del día son `.manual`).
        case completedRetro
        case skipped
        case frozen
        case missed
        case slip
        case partial
        /// Misma idea para cantidades parciales registradas retroactivamente.
        case partialRetro
        case pending
        case inactive
        case future
    }

    let state: State
    let habitColor: Color
    let onTap: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack {
                shape

                switch state {
                case .completed:
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: state)
                case .completedRetro:
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                case .skipped:
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(habitColor)
                case .frozen:
                    Image(systemName: "shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(habitColor)
                case .missed:
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textTertiary)
                case .slip:
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.warning)
                case .partial:
                    Circle()
                        .fill(habitColor)
                        .frame(width: 8, height: 8)
                case .partialRetro:
                    Circle()
                        .strokeBorder(habitColor, lineWidth: 1.5)
                        .frame(width: 9, height: 9)
                case .inactive:
                    Text("·")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                case .pending, .future:
                    EmptyView()
                }
            }
            .frame(width: WeekGridLayout.cellSize, height: WeekGridLayout.cellSize)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        }
        .buttonStyle(WeekGridCellButtonStyle())
        .disabled(state == .inactive || state == .future)
        .contextMenu {
            if state != .inactive && state != .future {
                Button {
                    onSkip()
                } label: {
                    Label(state == .skipped ? "Quitar descanso" : "Descanso intencional", systemImage: "pause.circle")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var shape: some View {
        switch state {
        case .completed:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor)
        case .completedRetro:
            // Sólido más tenue + ring interior blanco para indicar marca retroactiva.
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s - 3)
                        .strokeBorder(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .padding(3)
                }
        case .skipped:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor.opacity(0.45), style: StrokeStyle(lineWidth: 1.3, dash: [3, 2]))
                }
        case .frozen:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(AppColor.info.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(AppColor.info.opacity(0.5), lineWidth: 1.2)
                }
        case .missed:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(AppColor.textTertiary.opacity(0.28), lineWidth: 1)
                }
        case .slip:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(AppColor.warning.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(AppColor.warning.opacity(0.42), lineWidth: 1.2)
                }
        case .partial:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor.opacity(0.36), lineWidth: 1)
                }
        case .partialRetro:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2.5, 2]))
                }
        case .pending:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor.opacity(0.22), lineWidth: 1)
                }
        case .inactive:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(AppColor.bgSunken.opacity(0.6))
        case .future:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(AppColor.bgSunken.opacity(0.3))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(AppColor.divider, lineWidth: 1)
                }
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .completed: return "Completado"
        case .completedRetro: return "Completado, registrado más tarde"
        case .skipped: return "Descanso intencional"
        case .frozen: return "Comodín de racha usado"
        case .missed: return "Fallo registrado"
        case .slip: return "Slip registrado"
        case .partial: return "Avance parcial"
        case .partialRetro: return "Avance parcial, registrado más tarde"
        case .pending: return "Pendiente"
        case .inactive: return "Día inactivo"
        case .future: return "Día futuro"
        }
    }
}

private struct WeekGridCellButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(AppMotion.respectful(AppMotion.snap, reduceMotion), value: configuration.isPressed)
    }
}
