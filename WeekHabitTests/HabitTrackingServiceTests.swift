import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class HabitTrackingServiceTests: XCTestCase {
    func testCompletionReplacesPrimaryStateAndPreservesUrge() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(direction: .break)
        store.insert(habit)
        TestFactory.entry(.skipped, habit: habit, date: date)
        let urge = TestFactory.entry(.urge, habit: habit, date: date)

        let result = HabitTrackingService.setCompleted(
            habit,
            on: date,
            source: .today,
            completedAt: date,
            value: 1,
            focusSessionID: nil,
            modelContext: store.context,
            streakFreezes: []
        )
        try store.save()

        XCTAssertTrue(result.becameCompleted)
        XCTAssertEqual(primaryEntries(for: habit, on: date).map(\.kind), [.completed])
        XCTAssertEqual(urgeEntries(for: habit, on: date).map(\.id), [urge.id])
    }

    func testRestReplacesPrimaryStateAndPreservesUrge() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(direction: .break)
        store.insert(habit)
        TestFactory.entry(.completed, habit: habit, date: date, value: 1)
        let urge = TestFactory.entry(.urge, habit: habit, date: date)

        let didRest = HabitTrackingService.toggleRest(
            for: habit,
            on: date,
            source: .today,
            modelContext: store.context,
            streakFreezes: []
        )
        try store.save()

        XCTAssertTrue(didRest)
        XCTAssertEqual(primaryEntries(for: habit, on: date).map(\.kind), [.skipped])
        XCTAssertEqual(urgeEntries(for: habit, on: date).map(\.id), [urge.id])
    }

    func testQuantityUpsertCollapsesDuplicatePrimaryEntriesAndPreservesUrge() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(tracking: .quantity, targetValue: 10)
        store.insert(habit)
        TestFactory.entry(.completed, habit: habit, date: date, value: 2)
        TestFactory.entry(.minimum, habit: habit, date: date)
        let urge = TestFactory.entry(.urge, habit: habit, date: date)

        let result = HabitTrackingService.upsertQuantity(
            for: habit,
            on: date,
            value: 12,
            source: .today,
            completedAt: date,
            modelContext: store.context,
            streakFreezes: []
        )
        try store.save()

        XCTAssertTrue(result.isCompleted)
        XCTAssertEqual(primaryEntries(for: habit, on: date).count, 1)
        XCTAssertEqual(primaryEntries(for: habit, on: date).first?.value, 12)
        XCTAssertEqual(urgeEntries(for: habit, on: date).map(\.id), [urge.id])
    }

    func testRecoveryMissDoesNotOverwritePrimaryState() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit()
        store.insert(habit)
        let completed = TestFactory.entry(.completed, habit: habit, date: date, value: 1)
        let candidate = RecoveryPromptCandidate(habit: habit, date: date)

        HabitTrackingService.recordRecoveryMiss(
            candidate,
            reason: .forgot,
            modelContext: store.context
        )
        try store.save()

        XCTAssertEqual(primaryEntries(for: habit, on: date).map(\.id), [completed.id])
    }

    /// Contestar es una decisión que se toma una sola vez: no puede quedar a merced del autosave.
    func testCommitRecoveryMissPersistsImmediately() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit()
        store.insert(habit)
        let candidate = RecoveryPromptCandidate(habit: habit, date: date)

        try HabitTrackingService.commitRecoveryMiss(
            candidate,
            reason: .lowEnergy,
            modelContext: store.context
        )

        XCTAssertEqual(primaryEntries(for: habit, on: date).map(\.kind), [.missed])
        XCTAssertEqual(primaryEntries(for: habit, on: date).first?.failureReasonKind, .lowEnergy)
        XCTAssertFalse(store.context.hasChanges)
    }

    /// La hoja contesta varios hábitos seguidos: cada uno pasa por el servicio y ninguno puede
    /// tocar el día de los demás.
    func testAnsweringOneRecoveryCandidateLeavesTheOthersUntouched() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let answered = TestFactory.habit(title: "Leer")
        let untouched = TestFactory.habit(title: "Correr")
        store.insert(answered)
        store.insert(untouched)

        try HabitTrackingService.commitRecoveryMiss(
            RecoveryPromptCandidate(habit: answered, date: date),
            reason: .forgot,
            modelContext: store.context
        )

        XCTAssertEqual(answered.recoveryAnswer(on: date), .forgot)
        XCTAssertNil(untouched.recoveryAnswer(on: date))
        XCTAssertTrue(primaryEntries(for: untouched, on: date).isEmpty)
    }

    func testSlipReplacesPrimaryStateAndPreservesUrge() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit(direction: .break)
        store.insert(habit)
        TestFactory.entry(.completed, habit: habit, date: date, value: 1)
        let urge = TestFactory.entry(.urge, habit: habit, date: date)

        let didCreateSlip = HabitTrackingService.recordSlip(
            for: habit,
            on: date,
            trigger: .stress,
            context: "After work",
            modelContext: store.context,
            streakFreezes: []
        )
        try store.save()

        XCTAssertTrue(didCreateSlip)
        XCTAssertEqual(primaryEntries(for: habit, on: date).map(\.kind), [.slip])
        XCTAssertEqual(primaryEntries(for: habit, on: date).first?.slipTrigger, .stress)
        XCTAssertEqual(urgeEntries(for: habit, on: date).map(\.id), [urge.id])
    }

    func testFocusCompletionStoresSessionMetadataWithoutTouchingUrges() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let sessionID = UUID()
        let habit = TestFactory.habit(direction: .break)
        store.insert(habit)
        let urge = TestFactory.entry(.urge, habit: habit, date: date)

        let result = HabitTrackingService.setCompleted(
            habit,
            on: date,
            source: .focusSession,
            completedAt: date,
            value: 1,
            focusSessionID: sessionID,
            modelContext: store.context,
            streakFreezes: []
        )
        try store.save()

        XCTAssertEqual(result.entry?.source, .focusSession)
        XCTAssertEqual(result.entry?.focusSessionID, sessionID)
        XCTAssertEqual(urgeEntries(for: habit, on: date).map(\.id), [urge.id])
    }

    func testCompletingDayDeletesItsFreeze() throws {
        let store = try TestStore()
        let date = TestFactory.date(day: 3)
        let habit = TestFactory.habit()
        store.insert(habit)
        let freeze = StreakFreeze(habit: habit, protectedDate: date)
        store.context.insert(freeze)
        try store.save()

        _ = HabitTrackingService.setCompleted(
            habit,
            on: date,
            source: .today,
            completedAt: date,
            value: 1,
            focusSessionID: nil,
            modelContext: store.context,
            streakFreezes: [freeze]
        )
        try store.save()

        let freezes = try store.context.fetch(FetchDescriptor<StreakFreeze>())
        XCTAssertTrue(freezes.isEmpty)
    }

    func testApplyingWeeklyFreezeDoesNotDuplicateExistingWeek() throws {
        let store = try TestStore()
        let reference = TestFactory.date(day: 7)
        let missedDay = TestFactory.date(day: 2)
        let habit = TestFactory.habit(createdAt: missedDay)
        store.insert(habit)
        let freeze = StreakFreeze(habit: habit, protectedDate: missedDay)
        store.context.insert(freeze)
        try store.save()

        let inserted = HabitTrackingService.applyWeeklyFreezes(
            to: [habit],
            existing: [freeze],
            reference: reference,
            modelContext: store.context
        )
        try store.save()

        XCTAssertTrue(inserted.isEmpty)
        let freezes = try store.context.fetch(FetchDescriptor<StreakFreeze>())
        XCTAssertEqual(freezes.count, 1)
    }

    func testApplyingWeeklyFreezeReturnsInsertedFreeze() throws {
        let store = try TestStore()
        let reference = TestFactory.date(day: 7)
        let missedDay = TestFactory.date(day: 2)
        let habit = TestFactory.habit(createdAt: missedDay)
        store.insert(habit)
        try store.save()

        let inserted = HabitTrackingService.applyWeeklyFreezes(
            to: [habit],
            existing: [],
            reference: reference,
            modelContext: store.context
        )
        try store.save()

        let freezes = try store.context.fetch(FetchDescriptor<StreakFreeze>())
        XCTAssertEqual(inserted.count, 1)
        XCTAssertEqual(freezes.count, 1)
        XCTAssertEqual(inserted.first?.id, freezes.first?.id)
        XCTAssertTrue(AppCalendar.isSameDay(inserted.first?.protectedDate ?? .distantPast, missedDay))
    }

    private func primaryEntries(for habit: Habit, on date: Date) -> [HabitEntry] {
        habit.entries.filter {
            AppCalendar.isSameDay($0.date, date) && $0.kind != .urge
        }
    }

    private func urgeEntries(for habit: Habit, on date: Date) -> [HabitEntry] {
        habit.entries.filter {
            AppCalendar.isSameDay($0.date, date) && $0.kind == .urge
        }
    }
}
