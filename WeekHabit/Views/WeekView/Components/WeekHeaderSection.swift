//
//  WeekHeaderSection.swift
//  WeekHabit
//

import SwiftUI

struct WeekHeaderSection: View {
    var monthYearLabel: String
    var weekNumber: Int
    @Binding var weekOffset: Int
    @Binding var isEditing: Bool
    /// Cada cambio hace rebotar "Editar": lo dispara un toque en la cuadrícula en modo lectura.
    var editNudge: Int = 0
    var onShowLegend: (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isViewingOtherWeek: Bool { weekOffset != 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.m) {
                Text(monthYearLabel)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Spacer(minLength: 0)

                // "Hoy" y "Editar" viven en la fila del mes para no quitarle espacio al
                // título. "Editar" queda fijo en la orilla y "Hoy" siempre ocupa su lugar
                // (solo se desvanece), así nada salta al cambiar de semana.
                HStack(spacing: AppSpacing.s) {
                    Button("Hoy") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset = 0
                        }
                    }
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.accentMuted, in: Capsule())
                    .opacity(isViewingOtherWeek ? 1 : 0)
                    .allowsHitTesting(isViewingOtherWeek)
                    .accessibilityHidden(!isViewingOtherWeek)

                    editButton
                }
            }

            HStack(spacing: AppSpacing.m) {
                // Una sola línea: en pantallas angostas se encoge un poco antes de partirse.
                Text("Semana \(weekNumber)")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)

                Spacer(minLength: 0)

                HStack(spacing: AppSpacing.s) {
                    if let onShowLegend {
                        WHCircleButton(systemName: "questionmark") {
                            onShowLegend()
                        }
                        .accessibilityLabel("Ver leyenda de la semana")
                    }

                    WHCircleButton(systemName: "chevron.left") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset -= 1
                        }
                    }

                    WHCircleButton(systemName: "chevron.right") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset += 1
                        }
                    }
                    .disabled(weekOffset >= 0)

                    if let onCreate {
                        Button(action: onCreate) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(AppColor.accent)
                                .clipShape(Circle())
                                .appElevation(.low)
                        }
                        .accessibilityLabel("Nuevo")
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.l)
    }

    private var editButton: some View {
        Button {
            withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                isEditing.toggle()
            }
            AppHaptics.play(.selection)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 11, weight: .bold))
                Text(isEditing ? "Listo" : "Editar")
            }
            .font(AppFont.label)
            // Sobre el acento, el fondo de la pantalla da contraste en claro y en oscuro.
            .foregroundStyle(isEditing ? AppColor.bgCanvas : AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.xs)
            .background(isEditing ? AppColor.accent : AppColor.bgElevated, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isEditing ? Color.clear : AppColor.divider, lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .phaseAnimator([1.0, 1.12], trigger: editNudge) { content, scale in
            content.scaleEffect(reduceMotion ? 1 : scale)
        } animation: { _ in
            AppMotion.snap
        }
        .accessibilityLabel(isEditing ? "Terminar edición" : "Editar registros")
        .accessibilityAddTraits(isEditing ? .isSelected : [])
    }
}

#Preview("Semana actual") {
    @Previewable @State var weekOffset = 0
    @Previewable @State var isEditing = false

    WeekHeaderSection(
        monthYearLabel: AppFormatters.uppercasedString(from: .now, format: "MMMM yyyy", foldingDiacritics: true),
        weekNumber: AppCalendar.current.component(.weekOfYear, from: .now),
        weekOffset: $weekOffset,
        isEditing: $isEditing,
        onShowLegend: {},
        onCreate: {}
    )
    .background(AppColor.bgCanvas)
}

#Preview("Otra semana, editando") {
    @Previewable @State var weekOffset = -2
    @Previewable @State var isEditing = true

    WeekHeaderSection(
        monthYearLabel: AppFormatters.uppercasedString(from: .now, format: "MMMM yyyy", foldingDiacritics: true),
        weekNumber: AppCalendar.current.component(.weekOfYear, from: .now) - 2,
        weekOffset: $weekOffset,
        isEditing: $isEditing,
        onShowLegend: {},
        onCreate: {}
    )
    .background(AppColor.bgCanvas)
}
