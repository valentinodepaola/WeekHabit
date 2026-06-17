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

    @AppStorage(OnceFlag.hasSeenBreakIntro.rawValue) private var hasSeenBreakIntro = false
    @State private var showsBreakIntro = false
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
                        if !hasSeenBreakIntro {
                            showsBreakIntro = true
                            hasSeenBreakIntro = true
                        }
                    }
                }

                if showsBreakIntro && draft.direction == .`break` {
                    breakIntroCard
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

    private var breakIntroCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.s) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.warning)
                .frame(width: 28, height: 28)
                .background(AppColor.warning.opacity(0.12))
                .clipShape(Circle())

            Text("En hábitos de dejar podrás registrar impulsos y slips para entender el patrón sin juzgarlo.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.warning.opacity(0.22), lineWidth: 1)
        }
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
