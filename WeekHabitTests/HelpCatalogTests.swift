import XCTest
@testable import WeekHabit

/// `HelpCatalog` es copy, no dominio, pero es copy con estructura: la vista depende de que los
/// ids sean únicos, y el alcance de la pantalla —cinco formas de registrar el día, no un
/// catálogo de funciones— es una decisión de producto que conviene dejar fijada.
final class HelpCatalogTests: XCTestCase {

    func testTopicIdentifiersAreUnique() {
        let ids = HelpCatalog.topics.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "el `ForEach` de la hoja depende de ids únicos")
    }

    /// Si esta lista crece, la pantalla dejó de ser lo que se decidió que fuera.
    func testTheScreenCoversOnlyTheFiveWaysOfLoggingADay() {
        XCTAssertEqual(
            HelpCatalog.topics.map(\.id),
            ["minimum", "rest", "wildcard", "slip", "urge"]
        )
    }

    func testEveryTextIsPresent() {
        XCTAssertFalse(isBlank(HelpCatalog.title))
        XCTAssertFalse(isBlank(HelpCatalog.subtitle))

        for topic in HelpCatalog.topics {
            XCTAssertFalse(isBlank(topic.title), "fila \(topic.id) sin título")
            XCTAssertFalse(isBlank(topic.detail), "fila \(topic.id) sin descripción")
            XCTAssertFalse(isBlank(topic.icon), "fila \(topic.id) sin icono")
        }
    }

    func testTopicTitlesReadAsLabelsAndNotAsSentences() {
        for topic in HelpCatalog.topics {
            XCTAssertFalse(topic.title.hasSuffix("."), "el título de \(topic.id) termina en punto")
        }
    }

    /// El issue original prometía cosas que la app no hace: activar el comodín a mano y reanudar
    /// una pausa a mano. Si el copy vuelve a prometerlas, esto falla.
    func testCopyDoesNotPromiseThingsTheAppDoesNotDo() {
        let forbidden = ["activar el comodín", "reanudar la pausa"]
        let corpus = HelpCatalog.topics
            .map { "\($0.title) \($0.detail)" }
            .joined(separator: " ")
            .lowercased()

        for phrase in forbidden {
            XCTAssertFalse(corpus.contains(phrase), "el copy menciona «\(phrase)», que la app no ofrece")
        }
    }

    private func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
