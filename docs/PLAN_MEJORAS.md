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

## Estado actual — 2026-07-27

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
- **Siguiente paso recomendado:** Fase 2.
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

---

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
- `Views/TodayView/TodayScreenModel.swift`
- `Views/TodayView/TodayViewData.swift`
- `WeekHabitTests/OnboardingSetupServiceTests.swift`
- `WeekHabitTests/PerformanceBaselineTests.swift`

Modificados:

- `Views/TodayView/TodayView.swift`
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
