//
//  PlanFlowView.swift
//  WeekHabit
//

import SwiftUI

struct PlanFlowView: View {
    @AppStorage("hasSeenPlanOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showForm: Bool = false

    var body: some View {
        if showForm || hasSeenOnboarding {
            CreatePlanView()
        } else {
            PlanOnboardingView {
                hasSeenOnboarding = true
                showForm = true
            }
        }
    }
}

#Preview {
    PlanFlowView()
}
