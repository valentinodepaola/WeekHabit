import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class OnboardingSetupServiceTests: XCTestCase {

    // MARK: - ensurePlan

    func testEnsurePlanUsesFallbackTitleAndNoMotivationWhenTextIsBlank() throws {
        let store = try TestStore()

        let plan = OnboardingSetupService.ensurePlan(
            goalText: "   ",
            motivationText: "\n ",
            existingPlans: [],
            modelContext: store.context
        )

        XCTAssertEqual(plan.title, OnboardingSetupService.fallbackPlanTitle)
        XCTAssertNil(plan.motivation)
    }

    func testEnsurePlanTrimsTextAndEndsThirtyDaysLaterAtStartOfDay() throws {
        let store = try TestStore()
        let reference = TestFactory.date(day: 3)

        let plan = OnboardingSetupService.ensurePlan(
            goalText: "  Dormir mejor  ",
            motivationText: "  Tener más energía  ",
            existingPlans: [],
            reference: reference,
            modelContext: store.context
        )

        let expectedEndsAt = AppCalendar.startOfDay(for: TestFactory.date(month: 7, day: 3))
        XCTAssertEqual(plan.title, "Dormir mejor")
        XCTAssertEqual(plan.motivation, "Tener más energía")
        XCTAssertEqual(plan.endsAt, expectedEndsAt)
    }

    func testEnsurePlanReusesExistingPlanInsteadOfCreatingASecondOne() throws {
        let store = try TestStore()
        let existingPlan = Plan(title: "Plan viejo", endsAt: TestFactory.date(day: 30))
        store.context.insert(existingPlan)
        try store.save()

        let plan = OnboardingSetupService.ensurePlan(
            goalText: "Plan nuevo",
            motivationText: "Motivación nueva",
            existingPlans: [existingPlan],
            modelContext: store.context
        )
        try OnboardingSetupService.commit(modelContext: store.context)

        let storedPlans = try store.context.fetch(FetchDescriptor<Plan>())
        XCTAssertEqual(plan.id, existingPlan.id)
        XCTAssertEqual(storedPlans.count, 1)
        XCTAssertEqual(storedPlans.first?.title, "Plan nuevo")
        XCTAssertEqual(storedPlans.first?.motivation, "Motivación nueva")
    }

    // MARK: - Hábitos de plantilla

    func testAddHabitLinksTemplateHabitToPlan() throws {
        let store = try TestStore()
        let plan = makePlan(in: store)
        let template = try XCTUnwrap(StarterHabitTemplate.all.first)

        let habit = OnboardingSetupService.addHabit(
            from: template,
            to: plan,
            modelContext: store.context
        )

        XCTAssertEqual(plan.habits.map(\.id), [habit.id])
        XCTAssertEqual(habit.title, template.title)
        XCTAssertEqual(habit.targetDaysPerWeek, template.daysPerWeek)
        XCTAssertEqual(habit.trackingKind, template.trackingKind)
        XCTAssertEqual(habit.scheduleKind, .timesPerWeek)
    }

    func testRemoveHabitUnlinksItFromPlanAndDeletesIt() throws {
        let store = try TestStore()
        let plan = makePlan(in: store)
        let template = try XCTUnwrap(StarterHabitTemplate.all.first)
        let habit = OnboardingSetupService.addHabit(
            from: template,
            to: plan,
            modelContext: store.context
        )
        try OnboardingSetupService.commit(modelContext: store.context)

        OnboardingSetupService.removeHabit(habit, from: plan, modelContext: store.context)
        try OnboardingSetupService.commit(modelContext: store.context)

        let storedHabits = try store.context.fetch(FetchDescriptor<Habit>())
        XCTAssertTrue(plan.habits.isEmpty)
        XCTAssertTrue(storedHabits.isEmpty)
    }

    // MARK: - Guardado diferido

    func testMutationsStayPendingUntilCommit() throws {
        let store = try TestStore()
        let template = try XCTUnwrap(StarterHabitTemplate.all.first)

        let plan = OnboardingSetupService.ensurePlan(
            goalText: "Moverme más",
            motivationText: "",
            existingPlans: [],
            modelContext: store.context
        )
        OnboardingSetupService.addHabit(from: template, to: plan, modelContext: store.context)

        XCTAssertTrue(store.context.hasChanges)

        try OnboardingSetupService.commit(modelContext: store.context)

        XCTAssertFalse(store.context.hasChanges)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Plan>()).count, 1)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Habit>()).count, 1)
    }

    // MARK: - Helpers

    private func makePlan(in store: TestStore) -> Plan {
        let plan = Plan(title: "Mi semana", endsAt: TestFactory.date(day: 30))
        store.context.insert(plan)
        return plan
    }
}
