//
//  WeekGridCell.swift
//  WeekHabit
//

import SwiftUI

struct WeekGridCell: View {
    enum State: Equatable, CaseIterable {
        case completed
        /// Marca registrada retroactivamente (todos los entries del día son `.manual`).
        case completedRetro
        case minimum
        case skipped
        case frozen
        case missed
        case slip
        case urge
        case partial
        /// Misma idea para cantidades parciales registradas retroactivamente.
        case partialRetro
        case pending
        case inactive
        case future

        var legendTitle: String {
            switch self {
            case .completed: return "Completado"
            case .completedRetro: return "Completado retroactivo"
            case .minimum: return "Versión mínima"
            case .skipped: return "Descanso"
            case .frozen: return "Comodín"
            case .missed: return "Sin marcar"
            case .slip: return "Slip"
            case .urge: return "Impulso"
            case .partial: return "Parcial"
            case .partialRetro: return "Parcial retroactivo"
            case .pending: return "Pendiente"
            case .inactive: return "Inactivo"
            case .future: return "Futuro"
            }
        }

        var legendDescription: String {
            switch self {
            case .completed: return "Cuenta como avance completo."
            case .completedRetro: return "Se marcó después del día original."
            case .minimum: return "Cuenta como mantener la racha en pequeño."
            case .skipped: return "Pausa elegida sin tratarla como fallo."
            case .frozen: return "Un comodín protegió la racha."
            case .missed: return "El día cerró sin evidencia suficiente."
            case .slip: return "Se registró una caída o repetición."
            case .urge: return "Hubo impulso, aunque no necesariamente slip."
            case .partial: return "Hay avance, pero no llegó a la meta."
            case .partialRetro: return "Avance parcial registrado después."
            case .pending: return "Todavía se puede marcar."
            case .inactive: return "El hábito no tocaba ese día."
            case .future: return "Día que aún no llega."
            }
        }

        var visualFamily: WeekGridCellFamily {
            switch self {
            case .completed, .completedRetro, .minimum, .partial, .partialRetro:
                return .done
            case .skipped, .frozen:
                return .intentionalPause
            case .missed, .slip, .urge:
                return .usefulSignal
            case .pending, .inactive, .future:
                return .empty
            }
        }
    }

    let state: State
    let habitColor: Color
    var isInteractive: Bool = true
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
                case .minimum:
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
                case .urge:
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(habitColor)
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
        .disabled(isInteractive && (state == .inactive || state == .future))
        .allowsHitTesting(isInteractive)
        .contextMenu {
            if isInteractive && state != .inactive && state != .future {
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
        // Gramática visual de Week:
        // Hecho = color del hábito; Pausa con intención = tono calmo/punteado;
        // Señal útil = alerta suave sin rojo destructivo; Vacío = neutros.
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
        case .minimum:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor, lineWidth: 1.2)
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
        case .urge:
            RoundedRectangle(cornerRadius: AppRadius.s)
                .fill(habitColor.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s)
                        .strokeBorder(habitColor.opacity(0.38), lineWidth: 1.1)
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
        case .minimum: return "Versión mínima"
        case .skipped: return "Descanso intencional"
        case .frozen: return "Comodín de racha usado"
        case .missed: return "Fallo registrado"
        case .slip: return "Slip registrado"
        case .urge: return "Impulso registrado"
        case .partial: return "Avance parcial"
        case .partialRetro: return "Avance parcial, registrado más tarde"
        case .pending: return "Pendiente"
        case .inactive: return "Día inactivo"
        case .future: return "Día futuro"
        }
    }
}

enum WeekGridCellFamily: CaseIterable, Identifiable {
    case done
    case intentionalPause
    case usefulSignal
    case empty

    var id: String { title }

    var title: String {
        switch self {
        case .done: return "Hecho"
        case .intentionalPause: return "Pausa con intención"
        case .usefulSignal: return "Señal útil"
        case .empty: return "Vacío"
        }
    }

    var description: String {
        switch self {
        case .done: return "Relleno o punto del color del hábito: hubo avance."
        case .intentionalPause: return "Pausa válida, sin leerla como fracaso."
        case .usefulSignal: return "Datos para aprender del patrón, no castigos."
        case .empty: return "Días pendientes, inactivos o futuros."
        }
    }

    var states: [WeekGridCell.State] {
        WeekGridCell.State.allCases.filter { $0.visualFamily == self }
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
