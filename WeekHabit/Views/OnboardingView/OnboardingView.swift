//
//  OnboardingView.swift
//  WeekHabit
//
//  Reducido a 3 pasos: intro → primer hábito → recordatorios.
//  La filosofía vive en el lenguaje de toda la app, no en pantallas didácticas.
//

import SwiftData
import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: OnboardingStep = .intro
    @State private var selectedTemplate: StarterHabitTemplate.ID = StarterHabitTemplate.defaultID

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
        case .starterHabit:
            OnboardingStarterHabitScreen(
                selectedTemplateID: $selectedTemplate,
                templates: StarterHabitTemplate.all,
                onContinue: createSelectedHabitAndContinue,
                onCreateFromScratch: onFinish
            )
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

    private func requestNotifications() {
        Task {
            await HabitReminderService.requestAuthorization()
            await MainActor.run {
                onFinish()
            }
        }
    }

    private func createSelectedHabitAndContinue() {
        guard let template = StarterHabitTemplate.all.first(where: { $0.id == selectedTemplate }) else {
            goForward()
            return
        }

        modelContext.insert(template.makeHabit())
        try? modelContext.save()
        goForward()
    }
}

#Preview {
    OnboardingView()
}
