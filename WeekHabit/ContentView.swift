//
//  ContentView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var selectedTab: Int = 0
    @Query(sort: \Plan.endsAt) private var allPlans: [Plan]

    private var planPendingReview: Plan? {
        allPlans.first { $0.needsReview() }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: TodayView()
                case 1: HabitsView()
                case 2: WeekView()
                case 3: InsightsView()
                default: HabitsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(item: planPendingReviewBinding) { wrapper in
            PlanWrapUpView(plan: wrapper.plan)
        }
    }

    // SwiftUI requiere un Binding<Identifiable?> para .sheet(item:)
    private var planPendingReviewBinding: Binding<IdentifiablePlan?> {
        Binding(
            get: { planPendingReview.map { IdentifiablePlan(plan: $0) } },
            set: { _ in }
        )
    }
}

private struct IdentifiablePlan: Identifiable {
    let plan: Plan
    var id: UUID { plan.id }
}

#Preview {
    ContentView()
}
