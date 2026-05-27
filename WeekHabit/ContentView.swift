//
//  ContentView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var selectedTab: Int = 0
    @Query(sort: \Plan.endsAt) private var allPlans: [Plan]
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \WeeklyReview.reviewedAt, order: .reverse) private var weeklyReviews: [WeeklyReview]

    @AppStorage("weeklyReviewWeekdayRaw") private var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue
    @AppStorage("weeklyReviewAutoPresent") private var weeklyReviewAutoPresent: Bool = false

    private var planPendingReview: Plan? {
        allPlans.first { $0.needsReview() }
    }

    private var weeklyReviewWeekStart: Date? {
        guard weeklyReviewAutoPresent, planPendingReview == nil else { return nil }
        return WeeklyReviewService.needsReview(
            preferredWeekday: Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday,
            existingReviews: weeklyReviews,
            habits: habits
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(TabItems.today.description, systemImage: TabItems.today.icon)
                }
                .tag(0)

            WeekView()
                .tabItem {
                    Label(TabItems.week.description, systemImage: TabItems.week.icon)
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label(TabItems.insights.description, systemImage: TabItems.insights.icon)
                }
                .tag(2)
        }
        .tint(AppColor.accent)
        .sheet(item: planPendingReviewBinding) { wrapper in
            PlanWrapUpView(plan: wrapper.plan)
        }
        .sheet(item: weeklyReviewBinding) { wrapper in
            WeeklyReviewView(weekStart: wrapper.weekStart)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.bgCanvas)
        }
    }

    // SwiftUI requiere un Binding<Identifiable?> para .sheet(item:)
    private var planPendingReviewBinding: Binding<IdentifiablePlan?> {
        Binding(
            get: { planPendingReview.map { IdentifiablePlan(plan: $0) } },
            set: { _ in }
        )
    }

    private var weeklyReviewBinding: Binding<IdentifiableWeeklyReview?> {
        Binding(
            get: { weeklyReviewWeekStart.map { IdentifiableWeeklyReview(weekStart: $0) } },
            set: { _ in }
        )
    }
}

private struct IdentifiablePlan: Identifiable {
    let plan: Plan
    var id: UUID { plan.id }
}

private struct IdentifiableWeeklyReview: Identifiable {
    let weekStart: Date
    var id: TimeInterval { weekStart.timeIntervalSinceReferenceDate }
}

#Preview {
    ContentView()
}
