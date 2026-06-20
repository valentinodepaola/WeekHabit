import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class LifecycleServiceTests: XCTestCase {
    func testDeletingHabitCascadesEntriesAndFreezes() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(createdAt: date)
        store.insert(habit)
        let entry = TestFactory.entry(.completed, habit: habit, date: date, value: 1)
        let freeze = StreakFreeze(habit: habit, protectedDate: date)
        store.context.insert(entry)
        store.context.insert(freeze)
        try store.save()

        try HabitLifecycleService.delete(habit, modelContext: store.context)

        let habits = try store.context.fetch(FetchDescriptor<Habit>())
        let entries = try store.context.fetch(FetchDescriptor<HabitEntry>())
        let freezes = try store.context.fetch(FetchDescriptor<StreakFreeze>())
        XCTAssertTrue(habits.isEmpty)
        XCTAssertTrue(entries.isEmpty)
        XCTAssertTrue(freezes.isEmpty)
    }

    func testDeletingPlanPreservesHabitsByNullifyingRelationship() throws {
        let store = try TestStore()
        let habit = TestFactory.habit()
        let plan = Plan(title: "Plan", endsAt: TestFactory.date(day: 30))
        store.context.insert(habit)
        store.context.insert(plan)
        plan.habits = [habit]
        try store.save()

        try PlanLifecycleService.delete(plan, modelContext: store.context)

        let habits = try store.context.fetch(FetchDescriptor<Habit>())
        let plans = try store.context.fetch(FetchDescriptor<Plan>())
        XCTAssertEqual(habits.map(\.id), [habit.id])
        XCTAssertTrue(habits.first?.plans.isEmpty == true)
        XCTAssertTrue(plans.isEmpty)
    }

    func testDeletingPlanCascadesMilestones() throws {
        let store = try TestStore()
        let plan = Plan(title: "Plan", endsAt: TestFactory.date(day: 30))
        let milestone = PlanMilestone(
            title: "Milestone",
            targetDate: TestFactory.date(day: 10),
            plan: plan
        )
        store.context.insert(plan)
        store.context.insert(milestone)
        try store.save()

        try PlanLifecycleService.delete(plan, modelContext: store.context)

        let plans = try store.context.fetch(FetchDescriptor<Plan>())
        let milestones = try store.context.fetch(FetchDescriptor<PlanMilestone>())
        XCTAssertTrue(plans.isEmpty)
        XCTAssertTrue(milestones.isEmpty)
    }
}
