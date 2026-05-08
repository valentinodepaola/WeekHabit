//
//  PlanWrapUpView.swift
//  WeekHabit
//
//  Cierre con narrativa: "Un plan que termina no debe desaparecer en silencio.
//  Debe cerrar un ciclo: mirar avance, conservar lo útil, archivar lo que ya
//  cumplió su función y aprender para la siguiente semana."
//  — IDENTIDAD_MISION.md
//

import SwiftUI
import SwiftData

struct PlanWrapUpView: View {
    let plan: Plan
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// true = mantener, false = archivar.
    @State private var retainHabits: [UUID: Bool] = [:]

    private var progress: Double { plan.progress() }
    private var meetsGoal: Bool { plan.meetsGoal() }

    private var headline: String {
        if meetsGoal { return "Lo lograste" }
        if progress > 0 { return "El plan termina" }
        return "El plan termina"
    }

    private var narrative: String {
        if meetsGoal {
            return "Llegaste a la meta que te pusiste. Lo aprendido se queda contigo, sin importar qué decidas con los hábitos a continuación."
        }
        if progress > 0.5 {
            return "Te quedaste cerca. Eso también es información: hay un ritmo posible, quizá con menos fricción la próxima vez."
        }
        if progress > 0 {
            return "El plan termina sin alcanzar la meta. No es fracaso — es información para ajustar lo que pides la próxima vez."
        }
        return "El plan termina sin marcas registradas. A veces el contexto no acompaña; el siguiente intento empieza desde cero, sin culpa."
    }

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    headerSection
                    progressCard
                    narrativeSection
                    habitsSection
                    actionButton
                }
                .padding(AppSpacing.l)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: meetsGoal ? "checkmark.seal.fill" : "checkmark.seal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(meetsGoal ? AppColor.success : AppColor.textTertiary)
                Text("PLAN COMPLETADO")
                    .font(AppFont.label)
                    .tracking(0.8)
                    .foregroundStyle(AppColor.textTertiary)
            }

            Text(plan.title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)

            if let motivation = plan.motivation, !motivation.isEmpty {
                Text(motivation)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Progress card

    private var progressCard: some View {
        WHCard(variant: .elevated, padding: AppSpacing.l, radius: AppRadius.l) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("COMPLETITUD")
                            .font(AppFont.label)
                            .tracking(0.8)
                            .foregroundStyle(AppColor.textTertiary)

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 36, weight: .regular, design: .serif))
                            .foregroundStyle(meetsGoal ? AppColor.success : AppColor.textPrimary)
                            .monospacedDigit()
                    }

                    Spacer()

                    if meetsGoal {
                        Label("Meta lograda", systemImage: "checkmark.seal.fill")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.success)
                            .padding(.horizontal, AppSpacing.s)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColor.success.opacity(0.14))
                            .clipShape(Capsule())
                    } else {
                        Text("Meta: \(Int(plan.targetCompletionRate * 100))%")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }

                WHProgressBar(
                    progress: progress,
                    progressColor: meetsGoal ? AppColor.success : AppColor.accent,
                    height: 8,
                    goalMarker: plan.targetCompletionRate
                )
            }
        }
    }

    // MARK: - Narrative

    private var narrativeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(headline)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text(narrative)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("¿Qué se mantiene viviendo?")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("Un hábito puede graduarse del plan y seguir contigo, o cumplir su función y archivarse.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, AppSpacing.xs)

            if plan.habits.isEmpty {
                Text("Este plan no tenía hábitos vinculados.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.vertical, AppSpacing.m)
            } else {
                VStack(spacing: AppSpacing.s) {
                    ForEach(plan.habits.sorted(by: { $0.createdAt > $1.createdAt })) { habit in
                        HabitRetentionRow(
                            habit: habit,
                            shouldRetain: retainBinding(for: habit)
                        )
                    }
                }
            }
        }
    }

    private var actionButton: some View {
        WHButton(title: "Confirmar y cerrar plan", variant: .primary, action: confirmWrapUp)
            .padding(.top, AppSpacing.s)
    }

    private func retainBinding(for habit: Habit) -> Binding<Bool> {
        Binding(
            get: { retainHabits[habit.id] ?? true },
            set: { retainHabits[habit.id] = $0 }
        )
    }

    private func confirmWrapUp() {
        for habit in plan.habits {
            let retain = retainHabits[habit.id] ?? true
            if !retain {
                habit.endsAt = AppCalendar.startOfDay(for: .now)
            }
        }
        plan.reviewedAt = .now
        AppHaptics.play(.experimentApplied)
        dismiss()
    }
}

private struct HabitRetentionRow: View {
    let habit: Habit
    @Binding var shouldRetain: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(habit.habitColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(habit.habitColor)
            }
            .opacity(shouldRetain ? 1 : 0.4)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(AppFont.body)
                    .foregroundStyle(shouldRetain ? AppColor.textPrimary : AppColor.textTertiary)
                    .lineLimit(1)

                Text(shouldRetain ? "Se mantiene viviendo" : "Cumplió su función")
                    .font(AppFont.label)
                    .foregroundStyle(shouldRetain ? AppColor.success : AppColor.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $shouldRetain)
                .labelsHidden()
                .tint(AppColor.accent)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .animation(AppMotion.respectful(AppMotion.snap, reduceMotion), value: shouldRetain)
    }
}
