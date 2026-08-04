# Plan de mejoras: lo que queda después del refactor

Este plan es el sucesor de `PLAN_SIMPLIFICACION.md`, que quedó cerrado con las fases
A1–A5 y B2–B4 implementadas. Cada fase de acá es ejecutable en una sesión independiente.
Leer también `ARCHITECTURE.md`, `TESTING.md` y `REFACTOR_HANDOFF.md` antes de empezar una
fase.

Comando de build de referencia:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

Comando de tests:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Estado actual — 2026-07-28

- **Fase 1 implementada.** Ya no quedan escrituras directas a `modelContext` en `Views/`.
  Se agregó `OnboardingSetupService` y `HabitTrackingService.commitRecoveryMiss`, y los
  errores de guardado se muestran en una alerta en vez de tragarse o mandarse a `print`.
  Validación: **70 tests passed** en `iPhone 17 Pro` y recorrido manual del onboarding
  completo en simulador limpio, con persistencia confirmada tras reiniciar la app.
- Corrección respecto a `REFACTOR_HANDOFF.md`: ese documento todavía lista **A4 como
  siguiente paso recomendado**, pero A4 ya está implementado según
  `PLAN_SIMPLIFICACION.md` y se verifica en el código (`AppPerformance.measure` en 13
  puntos de Insights/Week, `PerformanceSeedService`, `scripts/seed_performance_data.sh`).
  Lo que quedó pendiente de A4 es **ejecutar la medición y decidir si cachear**, no
  construir el instrumental. La Fase 2 de este plan cierra eso.
- **Fase 2 implementada.** La medición existe y dio un veredicto claro: **cachear no
  alcanza, hay que indexar las entradas por día.** `bestStreak` crece 9,1× ante una entrada
  3× mayor, y el snapshot de Insights cuesta 1 610 ms con 15 hábitos. Los números están en
  `TESTING.md`.
- **Fase 2.5 implementada.** Se cacheó `AppCalendar.current`, que se reconstruía en cada
  acceso. Dio solo **~7 %** y no movió los factores de crecimiento: el cuello de botella no
  era construir el `Calendar` sino `Calendar.isDate(_:inSameDayAs:)` en sí. Se conserva
  porque es gratis y seguro, pero **el índice por día sigue haciendo falta**. Validación:
  **77 tests passed**, sin fallos.
- **Índice por día implementado.** `HabitDayIndex` baja cada consulta por día de
  O(entradas) a O(1). `bestStreak` pasó de 2 478 ms a **8,11 ms** y, más importante, dejó de
  crecer 9,0× para crecer 3,0×: el problema cuadrático quedó resuelto. Insights bajó 12× y
  las sugerencias 53×. Se incluyó el cinturón de `AppCalendar` que quedaba de la Fase 2.5.
  Validación: **81 tests passed**, con pruebas de equivalencia día por día.
- **Fase 3 implementada.** `TodayView` pasó de 740 líneas y 13 `@State` a 204 líneas y 1, con
  los datos derivados calculados una vez por render en vez de ~15. La decisión abierta sobre
  compartir índices se cerró con un tipo nuevo (`TodayPartition`) y **sin tocar ninguna firma
  existente**: las colecciones de Today bajaron de 47,66 a **7,97 ms**. Validación: **103
  tests passed** y recorrido manual completo en simulador.
- **Siguiente paso recomendado:** decidir si el patrón de la Fase 3 se replica en `WeekView`,
  `FocusSessionView`, `WeeklyReviewView` e `InsightsView`. Era explícitamente la pregunta que
  la prueba de concepto tenía que responder. Ver "Qué dejó la prueba de concepto" más abajo.
- **Pendiente aparte, sin empezar:** blindar el seed de rendimiento. Ver la sección
  "Pendiente aparte" más abajo. No bloquea ninguna fase.

---

## Por qué este plan y no Clean Architecture + MVVM

Se evaluó migrar la app a Clean Architecture con MVVM y se descartó por costo/beneficio.
Los números del repo al momento de decidir:

| Capa | Líneas | Archivos |
|---|---|---|
| `Views/` | 16 994 | 155 |
| `Models/` | 3 856 | 33 |
| `Services/` | 1 381 | 12 |
| `WeekHabitTests/` | 1 516 | 13 |

Y el dato que decide: **48 archivos de vista referencian `Habit` directamente** y 12 usan
`@Query`. Clean Architecture prohíbe exactamente eso.

Las cuatro razones concretas del descarte:

1. **`@Query` es incompatible y no tiene reemplazo equivalente.** Es un property wrapper
   que solo funciona dentro de una `View` y devuelve clases `@Model`. Renunciar a él
   significa fetch manual más observar `ModelContext.didSave` por `NotificationCenter` y
   refrescar a mano: más código, menos preciso, y reintroduce bugs de "la vista no se
   actualizó" que hoy no existen.
2. **Mapear las 9 entidades `@Model` a structs puras cuesta rendimiento.** `Habit` tiene
   relación con carga perezosa a `HabitEntry`. Hoy `Habit+Streaks` y el heatmap recorren
   entradas bajo demanda; con mappers a DTO habría que materializar el grafo completo en
   cada lectura.
3. **`@Observable` + SwiftData todavía tiene aristas.** Mutar un `@Model` desde un
   ViewModel no siempre propaga la invalidación como lo hace `@Query`.
4. **No hay red de seguridad donde más se tocaría.** Las 13 suites protegen servicios y
   dominio; las vistas explícitamente no se testean (decisión de `ARCHITECTURE.md`). Sería
   reescribir ~17k líneas sin tests que avisen de regresiones.

Estimación de la migración completa: **4–7 semanas** de trabajo dedicado, con riesgo alto
de regresión y una app peor integrada con SwiftUI que la actual.

La app ya tiene la mayor parte del beneficio que buscaba esa migración: dominio puro
separado por responsabilidad en `Models/Domain/`, 12 servicios sin estado como frontera de
escritura, drafts como capa de estado de feature, y errores de persistencia que no se
silencian. Lo que falta de verdad es lo que sigue.

## Decisiones tomadas

- **Alcance de MVVM:** solo `TodayView` como prueba de concepto (Fase 3). Si el patrón
  convence, se replica después en `WeekView`, `FocusSessionView`, `WeeklyReviewView` e
  `InsightsView`. No antes.
- **Medición de rendimiento:** tests automatizados con `XCTest.measure()` sobre el dataset
  del seed, no una corrida manual de Time Profiler. Reproducible, comparable y corre en la
  suite.
- **El onboarding de 6 pasos se conserva.** B1 sigue descartado. La Fase 1 solo extrae las
  escrituras a un servicio; no toca el flujo ni las pantallas.

---

## Fase 1 — Cerrar las escrituras directas a `modelContext`

**Por qué primero:** es la más barata, cierra la última excepción documentada de A1, y deja
`TodayView` limpio antes de que la Fase 3 lo reescriba.

Quedan 5 escrituras directas en vistas:

| Archivo | Línea | Qué hace |
|---|---|---|
| `Views/OnboardingView/OnboardingView.swift` | 136, 143 | `insert(plan)` + `try? modelContext.save()` |
| `Views/OnboardingView/Components/OnboardingHabitsScreen.swift` | 147, 156 | `delete(habit)` / `insert(habit)` al alternar plantillas |
| `Views/TodayView/TodayView.swift` | 675 | `try modelContext.save()` con el error impreso a consola |

Trabajo:

1. Crear `Services/OnboardingSetupService.swift` siguiendo el patrón de los editores
   existentes (`enum` con métodos `static`, `throws`, recibe `ModelContext`). Cubre: crear
   o actualizar el plan inicial (`ensurePlan`), agregar/quitar un hábito de plantilla
   (`toggleTemplate`) y confirmar el paso de hábitos. Reutilizar
   `OnboardingHabitDraft.makeHabit()`, que ya existe.
2. Reemplazar las 4 escrituras de onboarding por llamadas al servicio y **mostrar el
   error** en vez de tragarlo con `try?` — mismo tratamiento que `TodayDeleteFailure`.
3. `TodayView:673-679`: `saveRecoveryPromptState()` imprime el error con `print`.
   Propagarlo a `deleteFailure` (o un `TodayFailure` genérico) para respetar la regla de
   `ARCHITECTURE.md` de no silenciar fallos de persistencia.
4. Tests nuevos en `WeekHabitTests/OnboardingSetupServiceTests.swift`, usando
   `LifecycleServiceTests` como referencia.

**Hecho cuando:** este grep no devuelve nada y la suite pasa en verde.

```bash
grep -rn --include='*.swift' 'modelContext\.\(insert\|delete\|save\)' WeekHabit/Views
```

> **Ese criterio resultó incompleto.** Ver "Escritura implícita en `PlanWrapUpView`" al
> final: el grep solo ve escrituras **explícitas**, y una mutación puede persistir sin
> nombrar `insert`, `delete` ni `save`.

**Costo estimado:** medio día.

### Implementada — 2026-07-27

- `Services/OnboardingSetupService.swift`: `ensurePlan`, `addHabit`, `removeHabit` y
  `commit`. Solo `commit` lanza, porque `insert` y `delete` no pueden fallar; el guardado
  sigue siendo diferido, como hoy.
- `HabitTrackingService.commitRecoveryMiss(_:reason:minimumTitle:modelContext:)`: envuelve
  al `recordRecoveryMiss` existente, aplica la versión mínima y guarda. `recordRecoveryMiss`
  quedó intacto.
- `TodayDeleteFailure` se generalizó a `TodayFailure` con constructores `.deleting(_:)` y
  `.saving(_:)`, para que el título de la alerta corresponda a la operación.
- Tests: `OnboardingSetupServiceTests` (6) y
  `HabitTrackingServiceTests.testCommitRecoveryMissAppliesMinimumTitleAndPersists`.

**Quirk conocido, no arreglado:** el guardado no es estrictamente "solo al final". Si el
usuario abre `CreateHabitView` desde el paso de hábitos, `HabitEditorService.save()`
descarga el contexto entero y de paso persiste el plan pendiente. Es el comportamiento
previo y se conservó tal cual.

---

## Fase 2 — Línea base de rendimiento medida

**Por qué antes de la Fase 3:** `TodayView` recalcula `habits.loggableToday(on:)` unas **15
veces por render** (ver Fase 3). La Fase 3 arregla exactamente eso. Sin un número previo no
se puede demostrar la mejora ni detectar una regresión.

Trabajo:

1. Crear `WeekHabitTests/PerformanceBaselineTests.swift` con un helper que siembre el
   dataset pesado en el `ModelContainer` en memoria. Extraer la generación de datos de
   `PerformanceSeedService` a algo reutilizable por el test, o replicar su forma
   (5 hábitos × 365 días de entries) en `TestSupport.swift`.
2. Medir con `XCTest.measure()` las rutas que hoy tienen `AppPerformance.measure`:
   - snapshot y sugerencias de Insights (`HabitCollection+InsightSnapshot`,
     `HabitCollection+ExperimentSuggestions`);
   - agregados de Week (`visibleHabits`, `totalGoal`, `completedThisWeek`, day pulse);
   - streaks y matriz del heatmap (`Habit+Streaks`, `Habit+Presentation`);
   - colecciones de Today (`HabitCollection+Today`), que es la entrada de la Fase 3.
3. Registrar los números en `TESTING.md` como línea base, con fecha.
4. **Decidir con el dato, no antes.** Si algo excede el presupuesto de un frame (~16 ms),
   aplicar el patrón que ya prescribe A4: mover la métrica a `@State` recalculado en
   `.task(id: signature)`, con el mismo estilo de invalidación que
   `todayHabitSectionSignature`. Si nada duele, documentarlo y **no cachear** — es un
   resultado válido y cierra la pregunta que A4 dejó abierta.

**Hecho cuando:** los tests corren en verde con números registrados en `TESTING.md`, y
existe una decisión explícita y escrita de cachear o no cachear.

**Costo estimado:** 1–2 días.

### Implementada — 2026-07-27

`WeekHabitTests/PerformanceBaselineTests.swift` mide 9 métricas sobre dos tamaños de dataset
y reporta el factor de crecimiento. El dataset lo genera `TestHistoryFactory` en
`TestSupport.swift`. Los números completos están en `TESTING.md`.

**Resultado: cachear no alcanza. El arreglo es indexar las entradas por día.**

Las dos evidencias:

1. **`bestStreak` crece 9,1× ante una entrada 3× mayor** — 294 ms con 365 días de historial,
   **2 665 ms con 1 095**. Eso es cuadrático, y confirma la hipótesis: cada consulta por día
   escanea linealmente todas las entradas del hábito.
2. **Las métricas de colección crecen proporcional pero parten de un absoluto inaceptable.**
   El snapshot de Insights cuesta **1 610 ms** con 15 hábitos y las sugerencias de
   experimentos **2 524 ms**. Son ~108 ms *por hábito*, y ese costo por hábito es el mismo
   escaneo día × entradas.

Por eso cachear no resuelve: guardar el resultado de un cálculo de 1,6 s sigue costando 1,6 s
en el primer render y en cada invalidación — y en `TodayView` se invalida con cada hábito que
el usuario marca.

**Arreglo pendiente (fase propia, no incluida acá):** construir una vez por hábito un
`[Date: [HabitEntry]]` con las entradas agrupadas por día normalizado, y que
`Habit+Completion` consulte ese índice en vez de escanear. Eso lleva
`entries.contains { isSameDay(...) }` de O(entradas) a O(1), y `bestStreak` de
O(días × entradas) a O(días). Cachear encima queda opcional y probablemente innecesario.

Los techos de `Ceiling` quedaron en ~5× lo medido y son **provisionales**: 5× de una línea
base mala no protege gran cosa. Apretarlos cuando el índice esté implementado.

**Costo en la suite:** los dos tests agregan ~50 s. La suite completa pasó de ~23 s a ~68 s.
Si molesta, la palanca es bajar `iterations` o sacarlos del test plan por defecto.

---

## Fase 3 — `TodayView` con estado observable (prueba de concepto)

`TodayView.swift` son 738 líneas con 5 `@Query`, 3 `@AppStorage`, **14 `@State`** y ~20
métodos de acción. La partición de A2 ya extrajo los componentes visuales; lo que queda es
estado de coordinación y datos derivados mezclados con el layout.

Dos problemas concretos, no estéticos:

- **Estado de navegación disperso.** 14 `@State` sueltos (`coverRoute`, `sheetRoute`,
  `milestoneCover`, `deferredNoteEntry`, `selectedHabit`, `habitToDelete`,
  `showDeleteHabitAlert`, `planToDelete`, `showDeletePlanAlert`, `deleteFailure`,
  `expandedPlans`, `detailPlan`, `latestFreezeExplainerMessage`,
  `didShowRecoveryPromptThisSession`) con reglas implícitas entre ellos: por ejemplo
  `scheduleDeferredNotePresentation` reintenta hasta 6 veces esperando que `sheetRoute` se
  libere, y hay `DispatchQueue.main.asyncAfter` de 0.25 / 0.32 / 0.55 / 0.6 / 1.75 s
  coordinando presentaciones.
- **Recálculo redundante.** `todayHabits` (línea 63) es computed, y lo invocan
  `pendingHabits`, `completedHabits`, `skippedHabits`, `slippedHabits`, `weeklyFreezes`,
  `completedTodayCount`, `activeTodayCount`, `dailyProgress` y `focusCandidateHabits`.
  Encima `todayHabitSectionSignature` (línea 234) vuelve a invocar cinco de ellos. Total:
  ~15 pasadas de `loggableToday` por render.

Trabajo:

1. **`TodayScreenModel`** — clase `@Observable` (Observation framework, nativo, iOS 17+)
   sostenida con un solo `@State`. Contiene únicamente estado de presentación y navegación:
   rutas, flags de alerta, planes expandidos, explainer de comodín y flag de recovery.
   Reutiliza los tipos que ya existen en `TodayRouting.swift` (`TodayCoverRoute`,
   `TodaySheetRoute`, `TodayDeleteFailure`). Absorbe también la secuencia diferida de
   milestone → nota, que hoy es un reintento temporizado frágil.
2. **`TodayViewData`** — struct de valor construida **una sola vez** por render desde los
   resultados de `@Query`, con todas las colecciones y contadores derivados. Elimina las
   ~15 pasadas. Al ser value type es testeable directo en `TodayCollectionsTests`.
3. **La vista conserva `@Query` y `@Environment(\.modelContext)`** y sigue delegando las
   mutaciones a `HabitTrackingService`, `HabitLifecycleService` y `PlanLifecycleService`.
   No se crean repositorios, ni use cases, ni DTOs. No se toca el patrón de datos.
4. Tests de `TodayViewData` en `TodayCollectionsTests`, y volver a correr los tests de la
   Fase 2 para confirmar la mejora en las colecciones de Today.

**Explícitamente fuera de alcance:** las otras cuatro vistas gordas. El patrón se replica
solo si esta fase convence.

**Hecho cuando:** `TodayView.swift` queda por debajo de ~350 líneas, los 14 `@State` son 1,
el número de la Fase 2 para colecciones de Today mejora, y no hay regresión funcional en el
simulador.

**Costo estimado:** 3–5 días.

### Implementada — 2026-07-28

Los tres criterios se cumplieron: **204 líneas**, **1 `@State`**, y las colecciones de Today
de 47,66 a **7,97 ms**.

Cuatro piezas:

- **`Models/Domain/HabitCollection+Today.swift`: `TodayPartition`.** Construye un solo
  `HabitDayIndex` por hábito y deriva de él las cuatro secciones y los tres contadores.
  Resuelve la decisión abierta **sin tocar ninguna firma existente**: se agregaron las
  sobrecargas `meetsTodaySectionTarget(on:index:)` y `completedDaysThisWeek(reference:index:)`,
  y las funciones públicas de antes ahora delegan en ellas. Las siete funciones sueltas
  siguen siendo la forma correcta de responder una pregunta aislada.
- **`Views/TodayView/TodayViewData.swift`.** Value type con todos los derivados del render.
  Reemplaza las nueve propiedades computadas que se llamaban entre sí.
- **`Views/TodayView/TodayScreenModel.swift`.** Clase `@Observable` con las rutas, las
  confirmaciones y el estado de sección.
- **Partición del archivo.** `TodayViewActions.swift` (mutaciones) y
  `Components/TodayRouteViews.swift` (ruteo y enlaces de acción), sobre los `MARK` que ya
  existían.

**Dos simplificaciones de comportamiento, no solo de forma:**

- **La secuencia hito → nota dejó de ser un reintento temporizado.** Antes
  `scheduleDeferredNotePresentation` consultaba `sheetRoute` hasta seis veces cada 0,4 s y,
  si no lo lograba, **descartaba la nota en silencio**. Ahora la nota queda en cola en el
  modelo y la consumen los `onDismiss` del cover y del sheet, que es cuando la pantalla
  realmente se liberó. Verificado en simulador de punta a punta con `[Perf] Sin redes tarde`.
- **Las alertas de borrado perdieron su `Bool`.** `habitToDelete` + `showDeleteHabitAlert`
  eran dos estados para una sola condición; ahora la alerta se abre desde un binding derivado
  del opcional y no pueden desincronizarse.

**Costo del split en encapsulamiento:** al mover las extensiones a otros archivos hubo que
pasar de `private` a `internal` los miembros de `TodayView`, porque `private` en Swift no
cruza archivos. Es el precio de la partición y queda acotado al módulo de la app.

### Qué dejó la prueba de concepto

El patrón se comportó como se esperaba, y aparecieron dos cosas que el plan no había
anticipado:

1. **Testabilidad.** `TodayViewData` y `TodayScreenModel` sumaron 22 tests sobre lógica que
   antes vivía dentro de una `View` y por lo tanto no se testeaba. La secuencia hito → nota,
   el punto más frágil de la pantalla, hoy tiene cobertura determinista.
2. **La partición del dominio y la del estado son separables.** `TodayPartition` es útil por
   sí solo, sin `@Observable`. Si el patrón no se replicara, esa parte igual conviene.

**La decisión sobre las otras cuatro vistas sigue abierta y es lo que toca resolver.** El
costo por vista no es uniforme: `TodayView` era la más cargada, y en varias de las otras el
problema puede ser solo el recálculo y no el estado disperso. Conviene medir antes de asumir
que hace falta el paquete completo.

---

## Fase 2.5 — Cachear el `Calendar`

Fase corta abierta al planear el índice por día, cuando se encontró que
`AppCalendar.current` era una propiedad computada que construía un `Calendar` nuevo en cada
acceso — incluyendo `TimeZone.current` y `Locale.current` — y que hay 222 llamadas a
`AppCalendar` en el código. Un `bestStreak` sobre 1 095 días construía del orden de 400 000
calendarios.

Se hizo primero justamente para saber si el índice seguía siendo necesario.

### Implementada — 2026-07-27

`AppCalendar.current` ahora lee de un caché protegido por `OSAllocatedUnfairLock`, que se
descarta al recibir `NSLocale.currentLocaleDidChangeNotification` o
`.NSSystemTimeZoneDidChange`. Así los límites de día siguen siendo correctos si el usuario
viaja con la app abierta. `invalidateCache()` quedó `internal` para darle al caché una
costura verificable. Ningún call site cambió.

### Resultado: la hipótesis era incorrecta, y el índice sigue haciendo falta

La mejora fue de solo **~7 %** parejo en todas las métricas, y los factores de crecimiento
no se movieron: `bestStreak` sigue en 9,0×. La tabla comparativa completa está en
`TESTING.md`.

Construir el `Calendar` no era el cuello de botella. El costo real está **dentro** de
`Calendar.isDate(_:inSameDayAs:)`, que descompone ambas fechas en componentes bajo la zona
horaria vigente: del orden de 6 µs por llamada, y `bestStreak` la invoca unas 400 000 veces.

**Corolario para el índice:** no alcanza con reducir la cantidad de llamadas a `isSameDay`.
Hay que **dejar de llamarla**. El índice tiene que agrupar las entradas por fecha ya
normalizada y comparar `Date` directo, que es una comparación de dos enteros.

Eso vuelve al índice más valioso de lo que parecía, no menos: ataca el orden cuadrático y el
costo por comparación a la vez.

### Riesgo abierto: la invalidación por zona horaria no está verificada de punta a punta

Antes del cacheo, `current` se reconstruía en cada acceso, así que un cambio de zona horaria
se reflejaba solo. Ahora la corrección depende de que llegue la notificación.

Lo que sí está verificado: el observador se registra, se suscribe a las dos notificaciones,
y publicarlas a mano no rompe ni deja el caché en mal estado
(`AppCalendarTests.testCalendarStaysUsableAfterInvalidationNotifications`).

Lo que **no** está verificado: que iOS efectivamente publique
`.NSSystemTimeZoneDidChange` y que la app muestre los días nuevos, con la app abierta y el
usuario cruzando zonas horarias. No se pudo comprobar porque el simulador no expone "Fecha y
hora" en Configuración — hereda la zona horaria del Mac anfitrión — y cambiarla en el
anfitrión requiere privilegios de administrador.

Formas de cerrarlo, si preocupa:

- probarlo a mano en un dispositivo real, cambiando la zona horaria con la app abierta;
- o agregar un cinturón además de los tirantes: validar en cada acceso que el `timeZone` del
  calendario cacheado siga coincidiendo con `TimeZone.current`. Es una comparación barata
  comparada con construir el calendario, y vuelve la corrección independiente de la
  notificación. Se descartó al planear para no pagar una búsqueda por acceso, pero a la luz
  de que el cacheo solo dio un 7 %, ese ahorro vale menos de lo que parecía.

### Lo que queda del cacheo

Se conserva: es un 7 % gratis, seguro y ya probado. Pero **no es la solución**, y los techos
de `Ceiling` no se apretaron porque los números casi no se movieron.

**Detalle de diseño a tener en cuenta al implementar el índice:** `HabitEntry.date` y
`StreakFreeze.protectedDate` se normalizan a start-of-day en sus inits y nada los muta
después, así que comparar `Date` directo es correcto — salvo si el usuario cruzó zonas
horarias entre que se escribió la entrada y se la consulta. Por eso el índice debe
**renormalizar cada entrada al construirse**, con el calendario vigente: es O(entradas) una
sola vez, y queda correcto ante cambios de zona horaria.

## Índice por día — el arreglo que justificaron las mediciones

### Implementado — 2026-07-27

`Models/Domain/HabitDayIndex.swift`: agrupa entradas y comodines de un hábito por día
normalizado. Se construye al entrar a cada función que recorre muchos días y baja cada
consulta de O(entradas) a O(1).

Dos detalles del diseño:

- **Renormaliza cada fecha al construirse**, con el calendario vigente capturado una sola
  vez. Es lo que lo hace correcto si el usuario cruzó zonas horarias: comparar las fechas
  guardadas directamente habría sido igual de rápido pero habría dejado días históricos
  vacíos.
- **Ninguna firma pública cambió.** Las consultas de un solo día que usan las vistas siguen
  igual; construir un índice para una sola búsqueda saldría más caro que escanear.

Convertidas: `currentStreak`, `currentStreakBreakdown`, `bestStreak`, `completedDaysSince`,
`expectedDaysSince`, `completedWeekdays`, `completedDaysThisWeek`, `completionMatrix`,
`completionStats`, `weekdayPerformance`, `trustedMinimumDays`, `attentionFailureType`,
`daysSinceLastCompletion`, `weeklyFreezeCandidate`.

También se agregó el cinturón pendiente de la Fase 2.5: `AppCalendar.current` ahora valida
en cada acceso que el `timeZone` cacheado siga coincidiendo con `TimeZone.current`. Eso
cierra el riesgo que había quedado sin verificar, y su costo dejó de importar porque los
recorridos calientes ahora capturan el calendario una vez.

### Resultado

| Métrica | Antes | Después | Mejora | Factor antes | Factor después |
|---|---:|---:|---:|---:|---:|
| `bestStreak` | 2 478 ms | **8,11 ms** | **306×** | **9,0×** | **3,0×** |
| `completionMatrix` | 194 ms | **1,89 ms** | **103×** | 3,1× | 1,9× |
| Sugerencias de experimentos | 2 294 ms | **43,67 ms** | **53×** | 3,0× | 3,0× |
| Insights snapshot | 1 494 ms | **125,89 ms** | **12×** | 3,0× | 3,0× |
| Agregados de Week | 102 ms | 56,72 ms | 1,8× | 2,9× | 3,0× |
| Colecciones de Today | 48,53 ms | 47,66 ms | — | 2,9× | 3,0× |

El criterio de éxito se cumplió: **`bestStreak` dejó de crecer 9,0× y pasa a crecer 3,0×**.
El problema cuadrático está resuelto, no disimulado. La suite completa bajó de ~64 s a ~28 s.

Validación: **81 tests passed**, incluidas las pruebas de equivalencia día por día en
`HabitDayIndexTests`, más recorrido manual en simulador sobre el dataset de 1 488 entradas —
detalle de hábito con racha, mejor racha, desglose y heatmap, e Insights completo.

### Lo que quedó abierto, y cómo se cerró

**Las colecciones de Today siguen en ~48 ms**, tal como se había previsto. Cada partición
hace una sola consulta por hábito, así que un índice por función no ayuda. Bajarlo exige
compartir un índice entre las cuatro particiones de `HabitCollection+Today`.

Lo mismo aplica, en menor medida, al snapshot de Insights: 126 ms con 15 hábitos siguen
siendo ~8 frames. Compartir un índice por hábito entre las métricas de colección lo bajaría
más.

**Resuelto en la Fase 3, y la premisa de la pregunta era falsa.** Se preguntaba si valía
"ensuciar firmas del dominio"; no hizo falta ensuciar ninguna. Un tipo nuevo
(`TodayPartition`) más dos sobrecargas que reciben el índice alcanzaron para bajar Today de
47,66 a 7,97 ms dejando intactas las siete funciones existentes.

**Insights sigue pendiente**: 137 ms con 15 hábitos. La misma técnica aplica y ahora está
probada, pero no se hizo — la Fase 3 era prueba de concepto sobre `TodayView`.

## Escritura implícita en `PlanWrapUpView` — el cabo que dejó la Fase 1

### Encontrado y corregido — 2026-07-29

Detectado al auditar si quedaba algo pendiente después de la Fase 3. `PlanWrapUpView.confirmWrapUp()`
archivaba los hábitos del plan y lo marcaba como revisado **desde la vista**, sin servicio,
sin `save()` y sin manejo de error:

```swift
for habit in plan.habits where !retain { habit.endsAt = AppCalendar.startOfDay(for: .now) }
plan.reviewedAt = .now
```

**Por qué el grep de la Fase 1 no lo vio:** ese grep busca `modelContext.insert|delete|save`,
y acá no se llama a ninguno. Se asignan propiedades de un `@Model`, que SwiftData rastrea de
forma implícita y persiste por autosave. La auditoría estaba construida alrededor de
escrituras **explícitas**; esta es implícita.

**Por qué importaba más que un autosave cualquiera:** el modo de falla se realimenta.
`reviewedAt == nil` es exactamente la condición con la que `ContentView` decide mostrar la
hoja de cierre. Si la escritura no aterrizaba, el usuario volvía a cerrar el mismo plan — y
como `endsAt` y `reviewedAt` son escrituras independientes, podía quedar viendo hábitos que
ya había archivado. Es una decisión que se toma **una sola vez** por plan, sin segunda
oportunidad natural de reescribirse. Es el mismo razonamiento que ya estaba escrito en
`HabitTrackingService.commitRecoveryMiss`, de la Fase 1.

**Arreglo:**

- `PlanLifecycleService.completeWrapUp(_:archiving:reference:modelContext:)`, que hace las
  dos escrituras y guarda en la misma transacción.
- La vista muestra el error en una alerta y **no se cierra** si falla, siguiendo el patrón
  `<Feature>SaveFailure` que ya usan `CreateHabitView`, `WeeklyReviewView` y `FocusSessionView`.
- Se cancelan los recordatorios de los hábitos archivados. Antes no se hacía: archivar fija
  `endsAt` a hoy, así que el hábito **sigue** cumpliendo `shouldScheduleReminder` durante el
  resto del día y su recordatorio seguía vivo hasta el próximo refresco de `RootView` — o
  para siempre, si el usuario no volvía a abrir la app.
- 4 tests en `LifecycleServiceTests`, incluido uno que asierta `hasChanges == false`.

**Barrido del resto de `Views/`** con un patrón más amplio que el original:

```bash
grep -rnE '\b(habit|plan|entry|experiment|session|review)[A-Za-z]*\.[a-zA-Z]+ = ' \
  WeekHabit/Views --include='*.swift' | grep -vE 'Draft\.swift|self\.|== '
```

Los únicos resultados restantes están dentro de bloques `#Preview`, que no persisten nada.
Los `Draft` quedan excluidos a propósito: asignar sus propios campos es el patrón previsto.

## Pendiente aparte — Blindar el seed de rendimiento

No es una fase del plan: es un arreglo chico e independiente, detectado el 2026-07-27
usando la app. Se puede hacer en cualquier momento.

### Qué pasó

Estando en Insights con datos reales, un toque en el ícono `speedometer` de la barra
superior ([InsightsView.swift:159](../WeekHabit/Views/InsightsView/InsightsView.swift))
disparó `PerformanceSeedService` y la app se congeló. Números exactos, leídos del store del
simulador:

| | |
|---|---|
| Hábitos `[Perf]` insertados | 5 |
| Entradas insertadas | **1 480** |
| Datos reales que había | 2 hábitos, 8 entradas |

Las 1 480 inserciones ocurren en una sola transacción síncrona en el hilo principal, seguidas
de un `save()`. De ahí el congelamiento.

### Lo que NO es un problema

El seed **no puede llegar a producción**. Verificado empíricamente, no solo leyendo los
`#if DEBUG`: se compiló en Release y se buscaron los rastros en el binario.

| String | Debug | Release |
|---|---|---|
| `[Perf]` | sí | no |
| `speedometer` | sí | no |
| `Crear datos de performance` | sí | no |
| `No se pudo borrar` (control) | sí | sí |

El control aparece en ambos, así que la extracción funciona; el seed simplemente no existe
en Release. Nota para reproducirlo: en Debug el código vive en `WeekHabit.debug.dylib`, no
en el binario principal, así que hay que correr `strings` sobre el dylib.

### Lo que SÍ es un problema

1. **No hay forma de deshacerlo.** No existe ningún camino en el código que borre los
   hábitos `[Perf]`. La única salida es borrarlos a mano o reinstalar la app.
2. **No pide confirmación.** Un toque, 1 480 filas, irreversible.
3. **Está en el toolbar principal de una pantalla real**, fácil de picar sin querer. Si
   alguna vez se corre un build Debug desde Xcode en un dispositivo con datos reales, mete
   1 480 entradas sintéticas entre ellos y ensucia Insights.

### Arreglo propuesto

- Confirmación previa que diga cuántos hábitos y entradas va a crear.
- Método `PerformanceSeedService.removeSeed(modelContext:)` que borre los hábitos con
  prefijo `[Perf]` — el borrado de `Habit` ya cascadea entradas y freezes, así que alcanza
  con borrar los 5 hábitos — más su botón en la UI.
- Sacar el botón del toolbar principal a un lugar menos accidental.

Archivos: `WeekHabit/Services/PerformanceSeedService.swift`,
`WeekHabit/Views/InsightsView/InsightsView.swift` (toolbar en 157-168, función en 354-370),
`WeekHabit/ContentView.swift` (seed en arranque por `AppStorage`, líneas 67-71 y 89-107).

### Relación con la Fase 2

La lentitud posterior al seed no fue solo la inserción: es exactamente lo que la Fase 2
quiere medir. Insights recalcula todas sus métricas en cada render sin caché, y con ~1 488
entradas se nota. Este incidente es evidencia de que la medición de la Fase 2 vale la pena.

## Archivos

Nuevos:

- `Services/OnboardingSetupService.swift`
- `Models/Domain/HabitDayIndex.swift`
- `Views/TodayView/TodayScreenModel.swift`
- `Views/TodayView/TodayViewData.swift`
- `Views/TodayView/TodayViewActions.swift`
- `Views/TodayView/Components/TodayRouteViews.swift`
- `WeekHabitTests/OnboardingSetupServiceTests.swift`
- `WeekHabitTests/PerformanceBaselineTests.swift`
- `WeekHabitTests/HabitDayIndexTests.swift`
- `WeekHabitTests/TodayViewDataTests.swift`
- `WeekHabitTests/TodayScreenModelTests.swift`

Modificados:

- `Views/TodayView/TodayView.swift`
- `Models/Domain/HabitCollection+Today.swift`, `Models/Domain/Habit+Completion.swift`
- `Views/OnboardingView/OnboardingView.swift`
- `Views/OnboardingView/Components/OnboardingHabitsScreen.swift`
- `WeekHabitTests/TodayCollectionsTests.swift`, `WeekHabitTests/TestSupport.swift`
- `TESTING.md`, `ARCHITECTURE.md`, `REFACTOR_HANDOFF.md`

Reutilizar sin modificar:

- `HabitTrackingService`, `HabitLifecycleService`, `PlanLifecycleService`
- `HabitCollection+Today`, `TodayRouting.swift`, `OnboardingHabitDraft`
- `AppPerformance`, `PerformanceSeedService`, `scripts/seed_performance_data.sh`

## Verificación

Al cierre de cada fase se corre la suite completa con el comando de tests de arriba.

- **Fase 1:** la suite pasa (43 tests + los nuevos) y el grep de escrituras directas en
  `Views/` sale vacío.
- **Fase 2:** los tests de rendimiento reportan números y quedan escritos en `TESTING.md`.
- **Fase 3:** además de la suite, verificación manual en simulador de los flujos de Today —
  completar hábito, cantidad, descanso, slip, urge, milestone + nota diferida, recovery
  prompt, borrar hábito y plan, expandir planes.

Actualizar el bloque "Estado actual" de este documento y `ARCHITECTURE.md` al terminar cada
fase, siguiendo la convención de bloques con fecha que ya usan los otros docs.

## Fuera de alcance

- Clean Architecture: repositorios, use cases, entidades de dominio duplicadas, mappers.
- Sustituir `@Query` por fetch manual.
- B1 (onboarding de 6 → 3 pasos): decisión de producto ya tomada, no tocar.
- Migrar las otras cuatro vistas gordas a `@Observable` antes de evaluar la Fase 3.
