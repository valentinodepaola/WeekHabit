//
//  OnboardingView.swift
//  WeekHabit
//
//  Flujo goal-first: meta → motivación → tamaño mínimo → hábitos → notificaciones.
//  Crea un Plan en vivo al entrar al paso de hábitos y lo guarda al continuar.
//

import SwiftData
import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: OnboardingStep = .intro
    @State private var goalText: String = ""
    @State private var motivationText: String = ""
    @State private var createdPlan: Plan?
    @State private var didRequestPlanCreation = false

    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void = { }) {
        self.onFinish = onFinish
    }

    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                if step.showsProgress {
                    OnboardingProgressView(
                        currentIndex: step.progressIndex,
                        total: OnboardingStep.progressCount
                    )
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.l)
                    .padding(.bottom, AppSpacing.s)
                }

                ZStack {
                    currentScreen
                        .id(step)
                        .transition(screenTransition)
                }
                .animation(
                    AppMotion.respectful(AppMotion.gentle, reduceMotion),
                    value: step
                )
            }
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch step {
        case .intro:
            OnboardingIntroScreen(
                onStart: goForward,
                onSkip: onFinish
            )
        case .goal:
            OnboardingGoalScreen(
                goalText: $goalText,
                onContinue: goForward,
                onSkip: goForward
            )
        case .motivation:
            OnboardingMotivationScreen(
                motivationText: $motivationText,
                onContinue: goForward,
                onSkip: goForward
            )
        case .size:
            OnboardingSizeScreen(
                onContinue: {
                    ensurePlan()
                    goForward()
                }
            )
        case .habits:
            if let createdPlan {
                OnboardingHabitsScreen(
                    plan: createdPlan,
                    onContinue: continueFromHabits
                )
            } else {
                ProgressView()
            }
        case .notifications:
            OnboardingNotificationsScreen(
                onRequestNotifications: requestNotifications,
                onSkip: onFinish
            )
        }
    }

    private var screenTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .opacity.combined(with: .move(edge: .trailing))
    }

    private func goForward() {
        guard let nextStep = step.next else {
            onFinish()
            return
        }
        step = nextStep
    }

    private func ensurePlan() {
        guard createdPlan == nil, !didRequestPlanCreation else { return }
        didRequestPlanCreation = true

        let trimmedGoal = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMotivation = motivationText.trimmingCharacters(in: .whitespacesAndNewlines)

        let endsAt = AppCalendar.startOfDay(
            for: AppCalendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        )
        let plan = Plan(
            title: trimmedGoal.isEmpty ? "Mi semana" : trimmedGoal,
            motivation: trimmedMotivation.isEmpty ? nil : trimmedMotivation,
            endsAt: endsAt
        )
        modelContext.insert(plan)
        createdPlan = plan
    }

    private func continueFromHabits() {
        guard let createdPlan, !createdPlan.habits.isEmpty else { return }

        try? modelContext.save()
        goForward()
    }

    private func requestNotifications() {
        Task {
            await HabitReminderService.requestAuthorization()
            await MainActor.run {
                onFinish()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
