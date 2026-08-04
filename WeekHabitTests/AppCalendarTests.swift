import XCTest
@testable import WeekHabit

/// El calendario se cachea por rendimiento. Estas pruebas fijan que cachearlo no cambie
/// lo que devuelve, y que invalidarlo lo reconstruya bien.
@MainActor
final class AppCalendarTests: XCTestCase {

    override func tearDown() {
        AppCalendar.invalidateCache()
        super.tearDown()
    }

    func testCalendarForcesMondayAsFirstWeekday() {
        XCTAssertEqual(AppCalendar.current.firstWeekday, Weekday.monday.rawValue)
        XCTAssertEqual(AppCalendar.current.identifier, .gregorian)
        XCTAssertEqual(AppCalendar.current.timeZone, .current)
    }

    func testRepeatedAccessReturnsTheSameCalendar() {
        let first = AppCalendar.current
        let second = AppCalendar.current

        XCTAssertEqual(first, second)
    }

    func testInvalidatingCacheRebuildsAnEquivalentCalendar() {
        let before = AppCalendar.current

        AppCalendar.invalidateCache()
        let after = AppCalendar.current

        XCTAssertEqual(before, after)
        XCTAssertEqual(after.firstWeekday, Weekday.monday.rawValue)
    }

    /// El caché se invalida por notificación. Acá no se puede observar la invalidación en
    /// sí — un calendario reconstruido es igual al anterior — pero sí que el observador no
    /// rompa ni deje el caché en un estado inválido. El comportamiento real ante un cambio
    /// de zona horaria se verifica a mano; ver `docs/PLAN_MEJORAS.md`.
    func testCalendarStaysUsableAfterInvalidationNotifications() {
        _ = AppCalendar.current

        NotificationCenter.default.post(
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.post(name: .NSSystemTimeZoneDidChange, object: nil)

        XCTAssertEqual(AppCalendar.current.firstWeekday, Weekday.monday.rawValue)
        XCTAssertEqual(AppCalendar.current.timeZone, .current)
    }

    /// El caché no debe alterar el resultado de los helpers que lo usan.
    func testDateHelpersStayConsistentAcrossCacheInvalidation() {
        let date = TestFactory.date(day: 3, hour: 23)

        let startOfDay = AppCalendar.startOfDay(for: date)
        let weekday = AppCalendar.weekday(of: date)
        let weekRange = AppCalendar.weekRange(containing: date)

        AppCalendar.invalidateCache()

        XCTAssertEqual(AppCalendar.startOfDay(for: date), startOfDay)
        XCTAssertEqual(AppCalendar.weekday(of: date), weekday)
        XCTAssertEqual(AppCalendar.weekRange(containing: date), weekRange)
        XCTAssertTrue(AppCalendar.isSameDay(date, startOfDay))
    }
}
