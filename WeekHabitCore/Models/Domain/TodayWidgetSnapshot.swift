//
//  TodayWidgetSnapshot.swift
//  WeekHabit
//

import Foundation

/// Los cuatro estados que el widget sabe dibujar.
///
/// Son cuatro y no dos porque un día sin pendientes puede significar cosas muy distintas, y
/// mostrarlas todas como un cero convierte una decisión del usuario —descansar— en algo que
/// parece una falla.
enum TodayWidgetState: String, Equatable {
    /// Quedan hábitos por registrar hoy.
    case pending
    /// No queda nada pendiente: el día está cerrado.
    case allDone
    /// Hoy no hay nada que registrar, sea porque no había hábitos programados o porque los
    /// programados se marcaron como descanso.
    case rest
    /// Todavía no existe ningún hábito. El widget puede estar instalado antes que los datos.
    case empty
}

/// Un hábito tal como lo lista el widget: solo lo que se dibuja, sin arrastrar el `Habit`.
///
/// El color viaja como hex y no como `Color` para que el tipo siga siendo de dominio puro y
/// la conversión ocurra en la vista, donde ya vive `Color(hex:)`.
struct TodayWidgetHabitRow: Equatable {
    let title: String
    let colorHex: String
}

/// Todo lo que el widget muestra, derivado **una sola vez** a partir de los hábitos.
///
/// Es el mismo patrón que `TodayViewData`, y por la misma razón: si la derivación vive dentro
/// de la vista, se recalcula suelta y no se puede probar. Acá además hay un motivo extra —
/// la vista vive en la extensión, donde no llega el target de pruebas. Manteniendo el cálculo
/// en un value type del módulo de modelos, `WeekHabitTests` sí lo alcanza.
struct TodayWidgetSnapshot: Equatable {

    /// Cuántos nombres de hábito caben en `systemMedium`, que es la única familia con espacio
    /// para nombrarlos. El resto se resume en `hiddenPendingCount`.
    static let maxListedHabits = 3

    let state: TodayWidgetState
    let pendingCount: Int
    let completedCount: Int
    /// Hábitos de hoy que cuentan para el progreso: los programados menos los descansados.
    let activeCount: Int
    /// Hábitos programados para hoy, descansados incluidos.
    let scheduledCount: Int
    let progress: Double
    /// Los primeros pendientes, en el mismo orden en que los muestra Hoy.
    let listedPending: [TodayWidgetHabitRow]
    /// Pendientes que no entraron en `listedPending`.
    let hiddenPendingCount: Int
    /// Los primeros completados, para que el día cerrado pueda mostrar **qué** se logró en
    /// vez de limitarse a decir que no queda nada. Solo `systemMedium` tiene espacio para
    /// dibujarlos, pero derivarlos acá cuesta lo mismo que contarlos.
    let listedCompleted: [TodayWidgetHabitRow]
    /// Mejor racha viva entre los hábitos de hoy.
    ///
    /// Solo se calcula cuando el día está cerrado, que es el único estado que la muestra:
    /// recorrer rachas construye un `HabitDayIndex` por hábito y camina hacia atrás hasta
    /// que la racha se corta, y el presupuesto de un widget no da para pagar eso sin usarlo.
    let bestCurrentStreak: Int
    /// Hábitos programados para mañana, para poder cerrar el estado de descanso con algo
    /// hacia adelante en vez de con un vacío.
    let tomorrowCount: Int

    init(habits: [Habit], referenceDate: Date = .now) {
        let scheduled = habits.loggableToday(on: referenceDate)
        let partition = scheduled.todayPartition(on: referenceDate)

        self.scheduledCount = scheduled.count
        self.activeCount = partition.activeCount
        self.completedCount = partition.completedCount
        self.pendingCount = partition.pending.count
        self.progress = partition.progress

        let listed = partition.pending.prefix(Self.maxListedHabits)
        self.listedPending = listed.map {
            TodayWidgetHabitRow(title: $0.title, colorHex: $0.colorHex)
        }
        self.hiddenPendingCount = partition.pending.count - listed.count

        self.listedCompleted = partition.completed
            .prefix(Self.maxListedHabits)
            .map { TodayWidgetHabitRow(title: $0.title, colorHex: $0.colorHex) }

        let tomorrow = AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate)
            ?? referenceDate
        self.tomorrowCount = habits.loggableToday(on: tomorrow).count

        let state = Self.resolveState(
            hasAnyHabit: !habits.isEmpty,
            activeCount: partition.activeCount,
            pendingCount: partition.pending.count
        )
        self.state = state

        self.bestCurrentStreak = state == .allDone
            ? scheduled.map { $0.displayStreak(reference: referenceDate) }.max() ?? 0
            : 0
    }

    /// Construcción directa, sin pasar por los hábitos.
    ///
    /// La usan el marcador de posición del widget y sus previews, que necesitan los cuatro
    /// estados sin levantar una base de SwiftData. El `init` principal sigue siendo el único
    /// que deriva un estado real.
    init(
        state: TodayWidgetState,
        pendingCount: Int = 0,
        completedCount: Int = 0,
        activeCount: Int = 0,
        scheduledCount: Int = 0,
        progress: Double = 0,
        listedPending: [TodayWidgetHabitRow] = [],
        hiddenPendingCount: Int = 0,
        listedCompleted: [TodayWidgetHabitRow] = [],
        bestCurrentStreak: Int = 0,
        tomorrowCount: Int = 0
    ) {
        self.state = state
        self.pendingCount = pendingCount
        self.completedCount = completedCount
        self.activeCount = activeCount
        self.scheduledCount = scheduledCount
        self.progress = progress
        self.listedPending = listedPending
        self.hiddenPendingCount = hiddenPendingCount
        self.listedCompleted = listedCompleted
        self.bestCurrentStreak = bestCurrentStreak
        self.tomorrowCount = tomorrowCount
    }

    /// Estado vacío para el marcador de posición del widget, antes de que haya datos.
    static let placeholder = TodayWidgetSnapshot(habits: [], referenceDate: .now)

    /// En descanso, distingue "no había nada programado" de "estaba programado y se
    /// descansó". El widget lo necesita para no afirmar en el detalle algo que es falso.
    var restedEverythingScheduled: Bool {
        state == .rest && scheduledCount > 0
    }

    /// Los pendientes que caben en una línea, cortados **por nombre completo**, más un
    /// "+N" final cuando quedó algo fuera.
    ///
    /// Vive acá y no en la vista por dos razones. Una: en la primera prueba en dispositivo la
    /// lista se cortó a media palabra —"Diario Whoop · Orar · Lav…"— y una palabra partida se
    /// lee como un error de la app, no como una lista larga; es una regla que merece prueba.
    /// Dos: las vistas del widget viven en la extensión, donde el target de pruebas no llega.
    ///
    /// El presupuesto va en caracteres porque acá no se puede medir texto. Siempre entra al
    /// menos un nombre, aunque se pase: mejor un nombre recortado por el sistema que ninguno.
    func pendingSummary(budget: Int, separatorWidth: Int = 3) -> [String] {
        var shown: [String] = []
        var used = 0

        for row in listedPending {
            let separator = shown.isEmpty ? 0 : separatorWidth
            guard shown.isEmpty || used + separator + row.title.count <= budget else { break }
            shown.append(row.title)
            used += separator + row.title.count
        }

        let hidden = pendingCount - shown.count
        return hidden > 0 ? shown + ["+\(hidden)"] : shown
    }

    private static func resolveState(
        hasAnyHabit: Bool,
        activeCount: Int,
        pendingCount: Int
    ) -> TodayWidgetState {
        guard hasAnyHabit else { return .empty }

        // `activeCount` ya descuenta los descansos, así que este guard cubre los dos caminos
        // al descanso con una sola condición: que no hubiera nada programado, y que todo lo
        // programado se haya marcado como tal.
        guard activeCount > 0 else { return .rest }

        return pendingCount == 0 ? .allDone : .pending
    }
}
