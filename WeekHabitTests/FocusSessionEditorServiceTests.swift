import SwiftData
import XCTest
@testable import WeekHabit

@MainActor
final class FocusSessionEditorServiceTests: XCTestCase {
    func testStartPersistsSelectedHabitsDurationAndStartDate() throws {
        let store = try TestStore()
        let habitA = UUID()
        let habitB = UUID()
        let startedAt = TestFactory.date(day: 4, hour: 9)

        let session = try FocusSessionEditorService.start(
            selectedHabitIDs: [habitA, habitB],
            durationSeconds: 1_500,
            startedAt: startedAt,
            modelContext: store.context
        )

        let sessions = try store.context.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.id), [session.id])
        XCTAssertEqual(session.selectedHabitIDs, [habitA, habitB])
        XCTAssertEqual(session.durationSeconds, 1_500)
        XCTAssertEqual(session.startedAt, startedAt)
        XCTAssertEqual(session.status, .running)
    }

    func testStartPersistsOpenSessionWithoutDuration() throws {
        let store = try TestStore()

        let session = try FocusSessionEditorService.start(
            selectedHabitIDs: [UUID()],
            durationSeconds: nil,
            startedAt: TestFactory.date(day: 4),
            modelContext: store.context
        )

        XCTAssertNil(session.durationSeconds)
        XCTAssertNil(session.remainingSeconds(reference: TestFactory.date(day: 4, hour: 1)))
    }
}
