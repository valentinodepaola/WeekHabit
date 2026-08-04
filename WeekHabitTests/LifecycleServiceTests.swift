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

    // MARK: - Cierre de plan

    private func makeFinishedPlan(with habits: [Habit], in store: TestStore) throws -> Plan {
        let plan = Plan(title: "Plan", endsAt: TestFactory.date(day: 10))
        store.context.insert(plan)
        for habit in habits { store.context.insert(habit) }
        plan.habits = habits
        try store.save()
        return plan
    }

    func testCompleteWrapUpArchivesOnlyTheGivenHabitsAndMarksThePlanReviewed() throws {
        let store = try TestStore()
        let archived = TestFactory.habit()
        let retained = TestFactory.habit()
        let plan = try makeFinishedPlan(with: [archived, retained], in: store)
        let reference = TestFactory.date(day: 20)

        try PlanLifecycleService.completeWrapUp(
            plan,
            archiving: [archived],
            reference: reference,
            modelContext: store.context
        )

        XCTAssertEqual(archived.endsAt, AppCalendar.startOfDay(for: reference))
        XCTAssertNil(retained.endsAt, "conservar un hábito no debe ponerle fecha de fin")
        XCTAssertEqual(plan.reviewedAt, reference)
    }

    /// Es la garantía que motivó mover esto a un servicio: `reviewedAt == nil` es la
    /// condición con la que `ContentView` reabre la hoja de cierre, así que no puede
    /// quedar dependiendo del autosave.
    func testCompleteWrapUpPersistsImmediately() throws {
        let store = try TestStore()
        let archived = TestFactory.habit()
        let plan = try makeFinishedPlan(with: [archived], in: store)

        try PlanLifecycleService.completeWrapUp(
            plan,
            archiving: [archived],
            reference: TestFactory.date(day: 20),
            modelContext: store.context
        )

        XCTAssertFalse(store.context.hasChanges, "el cierre debe quedar escrito, no pendiente")
    }

    /// Archivar fija `endsAt` a hoy: el hábito sigue siendo registrable hoy y deja de serlo
    /// mañana. Es el comportamiento que ya tenía la vista.
    func testArchivedHabitStaysLoggableTodayAndStopsTomorrow() throws {
        let store = try TestStore()
        let archived = TestFactory.habit()
        let plan = try makeFinishedPlan(with: [archived], in: store)
        let today = TestFactory.date(day: 20)
        let tomorrow = TestFactory.date(day: 21)

        try PlanLifecycleService.completeWrapUp(
            plan,
            archiving: [archived],
            reference: today,
            modelContext: store.context
        )

        XCTAssertTrue(archived.isLoggable(on: today))
        XCTAssertFalse(archived.isLoggable(on: tomorrow))
    }

    func testCompleteWrapUpWithoutArchivedHabitsOnlyMarksThePlanReviewed() throws {
        let store = try TestStore()
        let retained = TestFactory.habit()
        let plan = try makeFinishedPlan(with: [retained], in: store)
        let reference = TestFactory.date(day: 20)

        try PlanLifecycleService.completeWrapUp(
            plan,
            archiving: [],
            reference: reference,
            modelContext: store.context
        )

        XCTAssertNil(retained.endsAt)
        XCTAssertEqual(plan.reviewedAt, reference)
        XCTAssertFalse(plan.needsReview(reference: reference))
    }
}
