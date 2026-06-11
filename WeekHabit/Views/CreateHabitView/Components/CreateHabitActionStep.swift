//
//  CreateHabitActionStep.swift
//  WeekHabit
//
//  Paso 1 — Acción: tipo (construir/dejar), nombre, apariencia y,
//  para hábitos a dejar, el reemplazo.
//

import SwiftUI

struct CreateHabitActionStep: View {
    @Binding var draft: HabitDraft
    let replacementCandidates: [Habit]
    let autoFocusName: Bool

    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            WHFormSection(
                title: "Tipo de hábito",
                helper: "¿Construir algo nuevo o dejar algo que no te sirve?"
            ) {
                HStack(spacing: AppSpacing.s) {
                    HabitOptionButton(
                        title: "Construir",
                        subtitle: "Hacerlo regularmente",
                        icon: "plus.circle.fill",
                        isSelected: draft.direction == .build
                    ) {
                        draft.direction = .build
                    }

                    HabitOptionButton(
                        title: "Dejar",
                        subtitle: "Hacerlo cada vez menos",
                        icon: "xmark.circle.fill",
                        isSelected: draft.direction == .`break`
                    ) {
                        draft.direction = .`break`
                    }
                }
            }

            WHFormSection(
                title: "La acción",
                helper: "Concreta y pequeña: que quepa incluso en un mal día."
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    TextField(namePlaceholder, text: $draft.name)
                        .font(AppFont.body)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .padding()
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

                    HabitAppearancePicker(
                        selectedIconName: $draft.iconName,
                        selectedColorHex: $draft.colorHex
                    )
                }
            }

            if draft.direction == .`break` {
                HabitReplacementSection(
                    availableHabits: replacementCandidates,
                    mode: $draft.replacementMode,
                    selectedHabitID: $draft.replacementHabitID,
                    newHabitName: $draft.newReplacementHabitName,
                    newHabitCue: $draft.newReplacementHabitCue
                )
            }
        }
        .task {
            guard autoFocusName, draft.name.isEmpty else { return }
            // Espera a que termine la transición del cover antes de levantar el teclado.
            try? await Task.sleep(for: .milliseconds(450))
            isNameFocused = true
        }
    }

    private var namePlaceholder: String {
        draft.direction == .build
            ? "Ej: Leer 10 minutos"
            : "Ej: Revisar el celular en la cama"
    }
}

#Preview {
    ScrollView {
        CreateHabitActionStep(
            draft: .constant(HabitDraft()),
            replacementCandidates: [],
            autoFocusName: false
        )
        .padding()
    }
    .background(AppColor.bgCanvas)
}
