import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class PlanEditorServiceTests: XCTestCase {
    func testDraftNormalizesTextDatesAndBlankMilestones() {
        let endDate = TestFactory.date(day: 20, hour: 18)
        let milestoneDate = TestFactory.date(day: 10, hour: 18)
        var draft = PlanDraft(reference: TestFactory.date(day: 1))
        draft.name = "  Run a 5K  "
        draft.motivation = "  More energy  "
        draft.measurableOutcome = "   "
        draft.endsAt = endDate
        draft.milestones = [
            MilestoneDraft(title: "  First 2K  ", targetDate: milestoneDate),
            MilestoneDraft(title: "   ", targetDate: milestoneDate)
        ]

        XCTAssertEqual(draft.normalizedName, "Run a 5K")
        XCTAssertEqual(draft.normalizedMotivation, "More energy")
        XCTAssertNil(draft.normalizedMeasurableOutcome)
        XCTAssertEqual(draft.normalizedEndsAt, AppCalendar.startOfDay(for: endDate))
        XCTAssertEqual(draft.normalizedMilestones.count, 1)
        XCTAssertEqual(draft.normalizedMilestones.first?.title, "First 2K")
        XCTAssertEqual(
            draft.normalizedMilestones.first?.targetDate,
            AppCalendar.startOfDay(for: milestoneDate)
        )
    }

    func testCreatePlanPersistsNormalizedFieldsHabitsAndMilestones() throws {
        let store = try TestStore()
        let selectedHabit = TestFactory.habit()
        let unselectedHabit = TestFactory.habit()
        store.context.insert(selectedHabit)
        store.context.insert(unselectedHabit)

        var draft = PlanDraft(reference: TestFactory.date(day: 1))
        draft.name = "  Run a 5K  "
        draft.motivation = "  More energy  "
        draft.measurableOutcome = "  Finish under 30 minutes  "
        draft.endsAt = TestFactory.date(day: 30, hour: 18)
        draft.targetCompletionRate = 0.9
        draft.selectedHabitIDs = [selectedHabit.id]
        draft.milestones = [
            MilestoneDraft(title: "  First 2K  ", targetDate: TestFactory.date(day: 10, hour: 18)),
            MilestoneDraft(title: "   ", targetDate: TestFactory.date(day: 20))
        ]

        let plan = try PlanEditorService.save(
            draft: draft,
            editing: nil,
            allHabits: [selectedHabit, unselectedHabit],
            modelContext: store.context
        )

        XCTAssertEqual(plan.title, "Run a 5K")
        XCTAssertEqual(plan.motivation, "More energy")
        XCTAssertEqual(plan.measurableOutcome, "Finish under 30 minutes")
        XCTAssertEqual(plan.targetCompletionRate, 0.9)
        XCTAssertEqual(plan.habits.map(\.id), [selectedHabit.id])

        let milestones = try store.context.fetch(FetchDescriptor<PlanMilestone>())
        XCTAssertEqual(milestones.count, 1)
        XCTAssertEqual(milestones.first?.title, "First 2K")
        XCTAssertEqual(
            milestones.first?.targetDate,
            AppCalendar.startOfDay(for: TestFactory.date(day: 10))
        )
    }

    func testEditPlanReconcilesMilestonesAndPreservesExistingCompletion() throws {
        let store = try TestStore()
        let oldHabit = TestFactory.habit()
        let newHabit = TestFactory.habit()
        let plan = Plan(title: "Old", endsAt: TestFactory.date(day: 20))
        store.context.insert(oldHabit)
        store.context.insert(newHabit)
        store.context.insert(plan)
        plan.habits = [oldHabit]

        let kept = PlanMilestone(title: "Keep", targetDate: TestFactory.date(day: 5), plan: plan)
        kept.completedAt = TestFactory.date(day: 6)
        let removed = PlanMilestone(title: "Remove", targetDate: TestFactory.date(day: 8), plan: plan)
        store.context.insert(kept)
        store.context.insert(removed)
        try store.save()

        var draft = PlanDraft(plan: plan)
        draft.name = "Updated"
        draft.selectedHabitIDs = [newHabit.id]
        draft.milestones = [
            MilestoneDraft(id: kept.id, title: "  Kept updated  ", targetDate: TestFactory.date(day: 7)),
            MilestoneDraft(title: "New", targetDate: TestFactory.date(day: 12))
        ]

        let savedPlan = try PlanEditorService.save(
            draft: draft,
            editing: plan,
            allHabits: [oldHabit, newHabit],
            modelContext: store.context
        )

        XCTAssertEqual(savedPlan.title, "Updated")
        XCTAssertEqual(savedPlan.habits.map(\.id), [newHabit.id])

        let milestones = try store.context.fetch(FetchDescriptor<PlanMilestone>())
        XCTAssertEqual(milestones.count, 2)
        XCTAssertFalse(milestones.contains { $0.id == removed.id })
        XCTAssertEqual(milestones.first { $0.id == kept.id }?.title, "Kept updated")
        XCTAssertEqual(milestones.first { $0.id == kept.id }?.completedAt, kept.completedAt)
        XCTAssertTrue(milestones.contains { $0.title == "New" })
    }
}
