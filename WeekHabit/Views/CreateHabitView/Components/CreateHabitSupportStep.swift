//
//  CreateHabitSupportStep.swift
//  WeekHabit
//
//  Paso 3 — Apoyos: todo opcional. Señal y recordatorio visibles (los apoyos
//  de mayor impacto); el resto colapsado en cards para no abrumar.
//

import SwiftUI
import UserNotifications

struct CreateHabitSupportStep: View {
    @Binding var draft: HabitDraft

    let notificationAuthorizationStatus: UNAuthorizationStatus
    let onRequestNotificationAuthorization: () -> Void
    let showsPlanSection: Bool
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            WHFormSection(
                title: "Señal",
                helper: "Engancharlo a una rutina que ya tienes vale más que la fuerza de voluntad."
            ) {
                TextFieldComponent(
                    titleSection: "Después de…",
                    placeholder: "Ej: Después de servirme el café de la mañana",
                    habitName: $draft.cue,
                    normalTextField: false
                )
            }

            HabitReminderSection(
                isReminderEnabled: $draft.isReminderEnabled,
                reminderTime: $draft.reminderTime,
                authorizationStatus: notificationAuthorizationStatus,
                onRequestAuthorization: onRequestNotificationAuthorization
            )

            WHFormSection(title: "Más opciones") {
                VStack(spacing: AppSpacing.s) {
                    noteCard
                    minimumVersionCard
                    weeklyFreezeCard
                    endDateCard

                    if showsPlanSection {
                        planCard
                    }
                }
            }
        }
    }

    // MARK: - Cards opcionales

    private var noteCard: some View {
        CreateHabitOptionalCard(
            icon: "text.alignleft",
            title: "Nota",
            summary: draft.note.isEmpty ? "Contexto que quieras recordar" : draft.note,
            isInitiallyExpanded: isEditing && !draft.note.isEmpty
        ) {
            TextFieldComponent(
                titleSection: "Nota",
                placeholder: "Antes de dormir, sin celular cerca…",
                habitName: $draft.note,
                normalTextField: false
            )
        }
    }

    private var minimumVersionCard: some View {
        CreateHabitOptionalCard(
            icon: "tortoise.fill",
            title: "Versión mínima",
            summary: draft.minimumViableTitle.isEmpty ? "Para los días difíciles" : draft.minimumViableTitle,
            isInitiallyExpanded: isEditing && !draft.minimumViableTitle.isEmpty
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                TextFieldComponent(
                    titleSection: "Mínima",
                    placeholder: "Ej: Caminar 5 min",
                    habitName: $draft.minimumViableTitle,
                    normalTextField: false
                )

                Text("Cuenta para tu racha aunque no para el conteo de días completos.")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var weeklyFreezeCard: some View {
        CreateHabitOptionalCard(
            icon: "snowflake",
            title: "Comodín semanal",
            summary: draft.allowsWeeklyFreeze ? "Activado" : "Desactivado"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Toggle("Permitir comodín semanal", isOn: $draft.allowsWeeklyFreeze)
                    .font(AppFont.body)
                    .tint(AppColor.accent)

                Text("Protege la racha una vez por semana cuando hay un olvido real.")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var endDateCard: some View {
        CreateHabitOptionalCard(
            icon: "calendar",
            title: "Fecha final",
            summary: draft.hasEndDate
                ? draft.endsAt.formatted(date: .abbreviated, time: .omitted)
                : "Sin fecha — hábito continuo",
            isInitiallyExpanded: isEditing && draft.hasEndDate
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Toggle("Tiene fecha final", isOn: $draft.hasEndDate)
                    .font(AppFont.body)
                    .tint(AppColor.accent)

                if draft.hasEndDate {
                    DatePicker(
                        "Termina",
                        selection: $draft.endsAt,
                        displayedComponents: .date
                    )
                    .font(AppFont.body)
                    .tint(AppColor.accent)
                }
            }
        }
    }

    private var planCard: some View {
        CreateHabitOptionalCard(
            icon: "target",
            title: "Plan",
            summary: planSummary,
            isInitiallyExpanded: isEditing && !draft.selectedPlanIDs.isEmpty
        ) {
            HabitPlansSection(selectedPlans: $draft.selectedPlanIDs)
        }
    }

    private var planSummary: String {
        switch draft.selectedPlanIDs.count {
        case 0: return "Conecta el hábito con una meta"
        case 1: return "1 plan vinculado"
        default: return "\(draft.selectedPlanIDs.count) planes vinculados"
        }
    }
}

#Preview {
    ScrollView {
        CreateHabitSupportStep(
            draft: .constant(HabitDraft()),
            notificationAuthorizationStatus: .notDetermined,
            onRequestNotificationAuthorization: {},
            showsPlanSection: true,
            isEditing: false
        )
        .padding()
    }
    .background(AppColor.bgCanvas)
}
