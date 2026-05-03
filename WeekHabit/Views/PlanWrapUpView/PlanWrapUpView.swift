//
//  PlanWrapUpView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct PlanWrapUpView: View {
    let plan: Plan
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // true = mantener, false = archivar
    @State private var retainHabits: [UUID: Bool] = [:]

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    progressSection
                    habitsSection
                    actionButton
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(plan.displayCategory.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: plan.displayCategory.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(plan.displayCategory.color)
                }

                Spacer()

                Text("Plan finalizado")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .textCase(.uppercase)
            }

            Text(plan.title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.strongText)

            if let motivation = plan.motivation, !motivation.isEmpty {
                Text(motivation)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.subtleText)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let progress = plan.progress()
            let meetsGoal = plan.meetsGoal()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completitud")
                        .font(AppFont.formSectionText)
                        .foregroundStyle(AppColor.mutedText)
                        .textCase(.uppercase)

                    Text("\(Int(progress * 100))%")
                        .font(AppFont.subtitle)
                        .foregroundStyle(meetsGoal ? AppColor.accent : AppColor.strongText)
                }

                Spacer()

                if meetsGoal {
                    Label("Meta lograda", systemImage: "checkmark.seal.fill")
                        .font(AppFont.captionApp)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColor.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.accentSoft)
                        .clipShape(Capsule())
                } else {
                    Text("Meta: \(Int(plan.targetCompletionRate * 100))%")
                        .font(AppFont.captionApp)
                        .foregroundStyle(AppColor.subtleText)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.surfaceMuted)
                        .frame(height: 8)

                    Capsule()
                        .fill(meetsGoal ? AppColor.accent : AppColor.mutedText)
                        .frame(width: geo.size.width * CGFloat(min(progress, 1)), height: 8)

                    Rectangle()
                        .fill(AppColor.mutedText.opacity(0.5))
                        .frame(width: 2, height: 14)
                        .offset(x: geo.size.width * CGFloat(plan.targetCompletionRate) - 1)
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Qué hábitos quieres conservar?")
                .font(AppFont.subtitle2)
                .foregroundStyle(AppColor.strongText)

            Text("Los hábitos que no conserves quedarán archivados.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.subtleText)

            VStack(spacing: 8) {
                ForEach(plan.habits.sorted(by: { $0.createdAt > $1.createdAt })) { habit in
                    HabitRetentionRow(
                        habit: habit,
                        shouldRetain: retainBinding(for: habit)
                    )
                }
            }
        }
    }

    private var actionButton: some View {
        Button(action: confirmWrapUp) {
            Text("Confirmar y cerrar plan")
                .font(AppFont.body2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        }
        .padding(.top, 8)
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
        dismiss()
    }
}

private struct HabitRetentionRow: View {
    let habit: Habit
    @Binding var shouldRetain: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(habit.displayCategory.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.displayCategory.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(habit.displayCategory.color)
            }
            .opacity(shouldRetain ? 1 : 0.4)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(AppFont.body2)
                    .fontWeight(.medium)
                    .foregroundStyle(shouldRetain ? AppColor.strongText : AppColor.subtleText)
                    .lineLimit(1)

                Text(shouldRetain ? "Se mantendrá activo" : "Se archivará")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(shouldRetain ? AppColor.accent : AppColor.subtleText)
            }

            Spacer()

            Toggle("", isOn: $shouldRetain)
                .labelsHidden()
                .tint(AppColor.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .animation(.easeOut(duration: 0.15), value: shouldRetain)
    }
}
