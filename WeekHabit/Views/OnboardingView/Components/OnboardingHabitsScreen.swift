//
//  OnboardingHabitsScreen.swift
//  WeekHabit
//

import SwiftData
import SwiftUI

struct OnboardingHabitsScreen: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var plan: Plan

    let onContinue: () -> Void

    @State private var isPlanExpanded = true
    @State private var templateHabitIDs: [String: UUID] = [:]
    @State private var showingCreateHabit = false
    @State private var editingHabit: Habit?

    private var canAddMore: Bool { plan.habits.count < 3 }
    private var isContinueDisabled: Bool { plan.habits.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("Agrega uno o varios hábitos pequeños. Estos serán las acciones que sostienen tu meta cada semana.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    PlanAccordion(
                        plan: plan,
                        isExpanded: isPlanExpanded,
                        onToggle: { isPlanExpanded.toggle() },
                        onHabitTap: { editingHabit = $0 }
                    )

                    suggestionsSection

                    if canAddMore {
                        createHabitButton
                    }
                }
                .padding(.horizontal, AppSpacing.l)
                .padding(.bottom, AppSpacing.s)
            }
            .scrollIndicators(.hidden)

            WHButton(
                title: "Continuar",
                variant: .primary,
                isDisabled: isContinueDisabled,
                action: onContinue
            )
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxl)
        }
        .sheet(isPresented: $showingCreateHabit) {
            CreateHabitView(
                initialPlanIDs: [plan.id],
                requiredPlans: [plan],
                locksPlanSelection: true
            )
        }
        .sheet(item: $editingHabit) { habit in
            CreateHabitView(
                habitToEdit: habit,
                requiredPlans: [plan],
                locksPlanSelection: true
            )
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Sugerencias")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: AppSpacing.s) {
                ForEach(StarterHabitTemplate.all) { template in
                    let isSelected = templateHabitIDs[template.id] != nil
                    let isDisabled = !isSelected && !canAddMore

                    StarterHabitRow(
                        template: template,
                        isSelected: isSelected,
                        onTap: { toggleTemplate(template) }
                    )
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.45 : 1)
                }
            }
        }
    }

    private var createHabitButton: some View {
        Button(action: { showingCreateHabit = true }) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                Text("Crear hábito nuevo")
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppColor.accentMuted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(AppColor.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Agrega hábitos")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("que sostienen tu meta")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }

    private func toggleTemplate(_ template: StarterHabitTemplate) {
        if let habitID = templateHabitIDs[template.id] {
            if let habit = plan.habits.first(where: { $0.id == habitID }) {
                OnboardingSetupService.removeHabit(
                    habit,
                    from: plan,
                    modelContext: modelContext
                )
            }
            templateHabitIDs[template.id] = nil
            return
        }

        guard canAddMore else { return }

        let habit = OnboardingSetupService.addHabit(
            from: template,
            to: plan,
            modelContext: modelContext
        )
        templateHabitIDs[template.id] = habit.id
    }
}

#Preview {
    let plan = Plan(
        title: "Mi semana",
        motivation: "Sentirme con más energía",
        endsAt: AppCalendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    )

    AppBackground {
        OnboardingHabitsScreen(
            plan: plan,
            onContinue: {}
        )
    }
}
