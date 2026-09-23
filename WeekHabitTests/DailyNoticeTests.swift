import XCTest
@testable import WeekHabit

/// El aviso diario vale lo que vale su regla de silencio: si reclama un día ya cerrado, el
/// usuario lo apaga. Por eso toda la decisión vive en `dailyNoticeOccurrences` y se prueba acá,
/// sin `UNUserNotificationCenter`.
///
/// Las fechas usan junio de 2026, cuyo día 1 cae lunes: los días 1 a 7 son una semana completa.
@MainActor
final class DailyNoticeTests: XCTestCase {

    private func namedHabit(_ title: String, activeDays: Set<Weekday>? = nil) -> Habit {
        let habit = TestFactory.habit(
            schedule: activeDays == nil ? .daily : .specificDays,
            activeDays: activeDays
        )
        habit.title = title
        return habit
    }

    // MARK: - Cuándo se calla

    func testClosedDayProducesNoNoticeForToday() {
        let morning = TestFactory.date(day: 3, hour: 9)
        let habit = namedHabit("Leer")
        TestFactory.entry(.completed, habit: habit, date: morning, value: 1)

        let occurrences = [habit].dailyNoticeOccurrences(hour: 20, minute: 0, days: 1, reference: morning)

        XCTAssertTrue(occurrences.isEmpty)
    }

    func testRestedDayProducesNoNotice() {
        let morning = TestFactory.date(day: 3, hour: 9)
        let habit = namedHabit("Leer")
        TestFactory.entry(.skipped, habit: habit, date: morning)

        XCTAssertTrue([habit].dailyNoticeOccurrences(hour: 20, minute: 0, days: 1, reference: morning).isEmpty)
    }

    func testDayWithNothingScheduledProducesNoNotice() {
        // El 3 de junio de 2026 es miércoles.
        let wednesday = TestFactory.date(day: 3, hour: 9)
        let mondayOnly = namedHabit("Correr", activeDays: [.monday])

        XCTAssertTrue([mondayOnly].dailyNoticeOccurrences(hour: 20, minute: 0, days: 1, reference: wednesday).isEmpty)
    }

    func testNoHabitsProducesNoNotice() {
        let morning = TestFactory.date(day: 3, hour: 9)
        XCTAssertTrue([Habit]().dailyNoticeOccurrences(hour: 20, minute: 0, reference: morning).isEmpty)
    }

    func testTodayIsSkippedOnceTheHourHasPassed() {
        let night = TestFactory.date(day: 3, hour: 22)
        let habit = namedHabit("Leer")

        let occurrences = [habit].dailyNoticeOccurrences(hour: 20, minute: 0, days: 2, reference: night)

        XCTAssertEqual(occurrences.count, 1)
        XCTAssertTrue(AppCalendar.isSameDay(occurrences[0].day, TestFactory.date(day: 4)))
    }

    func testTodayIsIncludedWhileTheHourIsAhead() {
        let morning = TestFactory.date(day: 3, hour: 9)
        let habit = namedHabit("Leer")

        let occurrences = [habit].dailyNoticeOccurrences(hour: 20, minute: 30, days: 1, reference: morning)

        XCTAssertEqual(occurrences.count, 1)
        let components = AppCalendar.current.dateComponents([.day, .hour, .minute], from: occurrences[0].fireDate)
        XCTAssertEqual(components.day, 3)
        XCTAssertEqual(components.hour, 20)
        XCTAssertEqual(components.minute, 30)
    }

    func testWindowCoversSevenDaysByDefault() {
        let morning = TestFactory.date(day: 3, hour: 9)
        let habit = namedHabit("Leer")

        let occurrences = [habit].dailyNoticeOccurrences(hour: 20, minute: 0, reference: morning)

        XCTAssertEqual(occurrences.count, DailyNotice.windowDays)
        XCTAssertEqual(
            occurrences.map { AppCalendar.current.component(.day, from: $0.day) },
            Array(3...9)
        )
    }

    func testFlexibleHabitWithWeeklyTargetMetIsNotPending() {
        // Meta de 2 días por semana, ya cumplida el lunes y el martes.
        let wednesday = TestFactory.date(day: 3, hour: 9)
        let flexible = TestFactory.habit(schedule: .timesPerWeek, targetDaysPerWeek: 2)
        flexible.title = "Nadar"
        TestFactory.entry(.completed, habit: flexible, date: TestFactory.date(day: 1), value: 1)
        TestFactory.entry(.completed, habit: flexible, date: TestFactory.date(day: 2), value: 1)

        XCTAssertTrue([flexible].dailyNoticeOccurrences(hour: 20, minute: 0, days: 1, reference: wednesday).isEmpty)
    }

    func testFinishedHabitIsNotPending() {
        let morning = TestFactory.date(day: 10, hour: 9)
        let finished = namedHabit("Leer")
        finished.endsAt = TestFactory.date(day: 5)

        XCTAssertTrue([finished].dailyNoticeOccurrences(hour: 20, minute: 0, reference: morning).isEmpty)
    }

    func testOnlyPendingHabitsAreCounted() {
        let morning = TestFactory.date(day: 3, hour: 9)
        let done = namedHabit("Leer")
        TestFactory.entry(.completed, habit: done, date: morning, value: 1)
        let pendingA = namedHabit("Caminar")
        let pendingB = namedHabit("Meditar")

        let occurrence = [done, pendingA, pendingB]
            .dailyNoticeOccurrences(hour: 20, minute: 0, days: 1, reference: morning)
            .first

        XCTAssertEqual(occurrence?.title, "Te quedan 2 hábitos hoy")
        XCTAssertEqual(occurrence?.body, "Caminar y Meditar")
    }

    // MARK: - Copy

    func testTitleIsSingularForOneHabit() {
        XCTAssertEqual(DailyNotice.title(pendingCount: 1), "Te queda 1 hábito hoy")
        XCTAssertEqual(DailyNotice.title(pendingCount: 3), "Te quedan 3 hábitos hoy")
    }

    func testBodyListsUpToTwoNamesAndSummarizesTheRest() {
        XCTAssertEqual(DailyNotice.body(pendingTitles: ["Leer"]), "Leer")
        XCTAssertEqual(DailyNotice.body(pendingTitles: ["Leer", "Caminar"]), "Leer y Caminar")
        XCTAssertEqual(
            DailyNotice.body(pendingTitles: ["Leer", "Caminar", "Meditar", "Orar"]),
            "Leer, Caminar y 2 más"
        )
    }

    func testSuggestionCopyUsesSingularArticleForOneOClock() {
        XCTAssertEqual(
            DailyNotice.suggestionActionTitle(for: HourWindow(startHour: 21, count: 8)),
            "Usar las 21:00"
        )
        XCTAssertEqual(
            DailyNotice.suggestionText(for: HourWindow(startHour: 0, count: 8)),
            "Los últimos 30 días sueles completar tus hábitos entre las 0:00 y la 1:00."
        )
    }

    // MARK: - Sugerencia de hora

    func testSuggestionNeedsEnoughHistory() {
        // Tres días de historia no alcanzan el mínimo de `InsightReadiness`.
        let reference = TestFactory.date(day: 4, hour: 12)
        let habit = namedHabit("Leer")
        habit.createdAt = TestFactory.date(day: 1)
        for day in 1...3 {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: day, hour: 21), value: 1)
        }

        XCTAssertNil([habit].dailyNoticeSuggestedWindow(reference: reference))
    }

    func testSuggestionNeedsEnoughCompletionsInThePeakHour() {
        let reference = TestFactory.date(day: 20, hour: 12)
        let habit = namedHabit("Leer")
        for day in [2, 5] {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: day, hour: 21), value: 1)
        }

        XCTAssertNil([habit].dailyNoticeSuggestedWindow(reference: reference))
    }

    func testSuggestionReturnsThePeakHourWithEnoughData() {
        let reference = TestFactory.date(day: 20, hour: 12)
        let habit = namedHabit("Leer")
        for day in 2...(1 + DailyNotice.suggestionMinimumCount) {
            TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: day, hour: 21), value: 1)
        }
        TestFactory.entry(.completed, habit: habit, date: TestFactory.date(day: 15, hour: 8), value: 1)

        XCTAssertEqual([habit].dailyNoticeSuggestedWindow(reference: reference)?.startHour, 21)
    }

    func testSuggestionIgnoresBreakHabits() {
        let reference = TestFactory.date(day: 20, hour: 12)
        let breakHabit = TestFactory.habit(direction: .break)
        for day in 2...10 {
            TestFactory.entry(.completed, habit: breakHabit, date: TestFactory.date(day: day, hour: 23), value: 1)
        }

        XCTAssertNil([breakHabit].dailyNoticeSuggestedWindow(reference: reference))
    }
}
