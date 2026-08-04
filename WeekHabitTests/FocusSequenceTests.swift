import XCTest
@testable import WeekHabit

final class FocusSequenceTests: XCTestCase {
    private let a = UUID()
    private let b = UUID()
    private let c = UUID()

    private func items() -> [FocusSequenceItem] {
        [
            FocusSequenceItem(id: a, seconds: 600),   // 0...600
            FocusSequenceItem(id: b, seconds: 300),   // 600...900
            FocusSequenceItem(id: c, seconds: 600)    // 900...1500
        ]
    }

    func testTotalSecondsIsSum() {
        XCTAssertEqual(FocusSequence.totalSeconds(items()), 1_500)
        XCTAssertEqual(FocusSequence.totalSeconds([]), 0)
    }

    func testClampedSecondsSnapsAndBounds() {
        // Snap al paso (300s).
        XCTAssertEqual(FocusSequence.clampedSeconds(740), 600)
        XCTAssertEqual(FocusSequence.clampedSeconds(760), 900)
        // Límite inferior y superior.
        XCTAssertEqual(FocusSequence.clampedSeconds(0), FocusSequence.minSeconds)
        XCTAssertEqual(FocusSequence.clampedSeconds(10_000), FocusSequence.maxSeconds)
    }

    func testStatesAtStartAllButFirstPending() {
        let states = FocusSequence.states(items: items(), elapsed: 0)
        guard case .inProgress(let fraction) = states[0] else {
            return XCTFail("El primero debe estar en curso")
        }
        XCTAssertEqual(fraction, 0, accuracy: 0.0001)
        XCTAssertEqual(states[1], .pending)
        XCTAssertEqual(states[2], .pending)
    }

    func testStatesMidSecondBlock() {
        // 750s: primero listo, segundo a mitad (150/300), tercero pendiente.
        let states = FocusSequence.states(items: items(), elapsed: 750)
        XCTAssertEqual(states[0], .done)
        guard case .inProgress(let fraction) = states[1] else {
            return XCTFail("El segundo debe estar en curso")
        }
        XCTAssertEqual(fraction, 0.5, accuracy: 0.0001)
        XCTAssertEqual(states[2], .pending)
    }

    func testStatesAtAndBeyondTotalAllDone() {
        XCTAssertEqual(FocusSequence.states(items: items(), elapsed: 1_500), [.done, .done, .done])
        XCTAssertEqual(FocusSequence.states(items: items(), elapsed: 9_999), [.done, .done, .done])
    }

    func testCurrentIndex() {
        XCTAssertEqual(FocusSequence.currentIndex(items: items(), elapsed: 0), 0)
        XCTAssertEqual(FocusSequence.currentIndex(items: items(), elapsed: 750), 1)
        XCTAssertNil(FocusSequence.currentIndex(items: items(), elapsed: 1_500))
    }

    func testReconcilePreservesOrderAndTimesAndAppendsNew() {
        var current = [
            FocusSequenceItem(id: a, seconds: 1_200),
            FocusSequenceItem(id: b, seconds: 300)
        ]
        // Quita b, conserva a (con su tiempo), agrega c al final.
        current = FocusSequence.reconcile(
            items: current,
            selectedIDs: [a, c],
            appendingOrder: [a, b, c]
        )
        XCTAssertEqual(current.map(\.id), [a, c])
        XCTAssertEqual(current[0].seconds, 1_200)
        XCTAssertEqual(current[1].seconds, FocusSequence.baseSeconds)
    }
}
