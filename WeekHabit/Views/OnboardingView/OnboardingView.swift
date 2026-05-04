//
//  OnboardingView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
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
                    .padding(.horizontal, 30)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }

                ZStack {
                    currentScreen
                        .id(step)
                        .transition(screenTransition)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.9), value: step)
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
        case .smallStart:
            OnboardingInsightScreen(
                icon: "leaf.fill",
                title: "No necesitas cambiarlo todo.",
                accentTitle: "Solo empezar pequeño.",
                message: "Un hábito claro reduce la fricción. Cuando el primer paso cabe en tu día, repetirlo se vuelve mucho más fácil.",
                buttonTitle: "Continuar",
                onContinue: goForward
            )
        case .weeklyRhythm:
            OnboardingInsightScreen(
                icon: "calendar",
                title: "Tu semana es el terreno.",
                accentTitle: "Tu ritmo hace el cambio.",
                message: "WeekHabit te ayuda a mirar siete días a la vez: suficiente para avanzar, amable para volver a intentarlo.",
                buttonTitle: "Elegir mi primer hábito",
                onContinue: goForward
            )
        case .notifications:
            OnboardingNotificationsScreen(
                onRequestNotifications: requestNotifications,
                onSkip: goForward
            )
        case .starterHabit:
            OnboardingStarterHabitScreen(
                selectedTemplateID: $selectedTemplate,
                templates: StarterHabitTemplate.all,
                onStartWeek: createSelectedHabitAndFinish,
                onCreateFromScratch: onFinish
            )
        }
    }

    private var screenTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .opacity.combined(with: .move(edge: .trailing))
    }

    private func goForward() {
        guard let nextStep = step.next else { return }
        step = nextStep
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            Task { @MainActor in
                goForward()
            }
        }
    }

    private func createSelectedHabitAndFinish() {
        guard let template = StarterHabitTemplate.all.first(where: { $0.id == selectedTemplate }) else {
            onFinish()
            return
        }

        modelContext.insert(template.makeHabit())
        try? modelContext.save()
        onFinish()
    }
}

#Preview {
    OnboardingView()
}
