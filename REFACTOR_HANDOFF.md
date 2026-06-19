# Handoff del refactor arquitectónico

Este documento permite continuar el refactor en una conversación nueva sin depender del
historial anterior. Antes de editar, leer también `ARCHITECTURE.md`, `TESTING.md` y
`DOCUMENTATION.md`.

## Objetivo

Reducir lógica de negocio y persistencia dentro de vistas SwiftUI, manteniendo una
arquitectura pragmática:

```text
Views
  Presentación, navegación, animación, haptics y coordinación
        |
        v
Feature State
  Drafts y estado editable de formularios
        |
        v
Domain Services
  Mutaciones, transacciones y reconciliación de relaciones
        |
        v
SwiftData Models
  Entidades persistidas y cálculos puros de solo lectura
```

Las vistas top-level pueden conservar `@Query` y pasar `ModelContext` a servicios. La meta
no es eliminar SwiftData de SwiftUI, sino evitar que las vistas implementen reglas de
persistencia.

## Actualización de estado — 2026-06-17

Este bloque resume el estado real después de avanzar el plan de simplificación
(`PLAN_SIMPLIFICACION.md`). Sirve como punto de partida para una conversación nueva.

### Decisiones de producto tomadas

- **No tocar onboarding por ahora.** El plan proponía B1 (pasar de 6 pasos a 3), pero el
  onboarding de 6 pasos se conserva por decisión explícita. Por eso las escrituras directas
  que quedan en onboarding son una excepción documentada, no un descuido.
- **A2 está implementado.** El commit anterior (`ea43836 "Implementamos A2 y actualizamos
  handoff"`) en realidad cerró A3 (Insights); el nombre quedó como error de naming.
- El siguiente paso recomendado es **A4** (medir rendimiento antes de cachear) o **A5**
  (higiene de tokens oportunística).

### A1 completado con excepción documentada

La fase A1 / fase 5 del handoff quedó implementada para todos los flujos acordados excepto
onboarding. Commits de referencia:

- `54b4507` — Weekly Review.
- `03016cf` — Today deletes.
- `611101c` — Focus Session.
- `6a23863` — EntryNoteSheet.
- `895187d` — InsightsView / start experiment.
- `7cb010d` — keep/revert experiment.

Servicios agregados o usados por A1:

- `WeeklyReviewEditorService`
- `HabitLifecycleService`
- `PlanLifecycleService`
- `FocusSessionEditorService`
- `EntryNoteService`
- `HabitExperimentService`

Tests agregados por A1:

- `WeeklyReviewEditorServiceTests`
- `LifecycleServiceTests`
- `FocusSessionEditorServiceTests`
- `EntryNoteServiceTests`
- `HabitExperimentServiceTests`

Auditoría esperada después de A1:

```bash
rg -n "modelContext\.(insert|delete|save)|try\? modelContext" WeekHabit/Views -g '*.swift'
```

Debe devolver únicamente las excepciones de onboarding:

- `WeekHabit/Views/OnboardingView/OnboardingView.swift`
- `WeekHabit/Views/OnboardingView/Components/OnboardingHabitsScreen.swift`

También se movieron `HabitExperiment.keep` y `HabitExperiment.revert` fuera de
`InsightsView` y `WeeklyReviewView`, hacia `HabitExperimentService`.

### A3 implementado, pendiente de commit

A3 se implementó después de A1 y actualmente puede estar como worktree sin commit si esta
sección aparece antes de cerrar la fase. Cambios esperados:

- Se eliminó `WeekHabit/Models/Insights/HabitCollection+Insights.swift`.
- Se partió en:
  - `WeekHabit/Models/Insights/HabitCollection+InsightSnapshot.swift`
  - `WeekHabit/Models/Insights/HabitCollection+InsightContexts.swift`
  - `WeekHabit/Models/Insights/HabitCollection+ExperimentSuggestions.swift`
- Se agregaron:
  - `WeekHabitTests/InsightMetricsTests.swift`
  - `WeekHabitTests/ExperimentSuggestionTests.swift`

Cobertura agregada:

- Readiness: warmup, provisional y stable.
- Snapshot global: ventanas de 30 días, delta, 12 trend buckets y `minimumDays`.
- Confianza: niveles high/learning/low, marcas manuales no confiables y focus sessions.
- `attentionHabit`: priorización por baja consistencia y failure types.
- `urgePeakHourInsight`: mínimo de 3 urges y contexto por hábito.
- Sugerencias de experimentos: sin datos, exclusión de hábitos activos, reducción de días,
  hora fija y orden por prioridad.

Última validación conocida para A3:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  -derivedDataPath /private/tmp/WeekHabit_DerivedData \
  build CODE_SIGNING_ALLOWED=NO

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /private/tmp/WeekHabit_DerivedData \
  test
```

Resultado: build verde, suite verde con **43 tests passed**, `git diff --check` limpio.

### A2 implementado

`TodayView.swift` pasó de **1.206 → 692 líneas** (-43%). El objetivo "~450" del plan no se
alcanzó al pie de la letra; lo que queda son ~280 líneas de acciones de coordinación
(toggle/persist/milestone/delete) que viven legítimamente en la vista. Si en el futuro
se quiere reducir más, el siguiente candidato es extraer un `TodayMilestoneCoordinator`
con la lógica de `presentLiveMilestoneIfNeeded` + `presentDeferredNoteIfNeeded` +
`scheduleDeferredNotePresentation` (~70 líneas).

Archivos nuevos:

- `WeekHabit/Models/Domain/HabitCollection+Today.swift` — `loggableToday`, `pendingToday`,
  `completedToday`, `skippedToday`, `slippedToday`, `dailyProgress`, freezes de la semana,
  y `Habit.meetsTodaySectionTarget(on:)`.
- `WeekHabit/Views/TodayView/Components/TodayHeaderSection.swift`
- `WeekHabit/Views/TodayView/Components/TodayHabitListSection.swift`
- `WeekHabit/Views/TodayView/Components/TodayPlansSection.swift`
- `WeekHabit/Views/TodayView/Components/TodayRouting.swift` — enums `TodayCoverRoute`,
  `TodaySheetRoute`, `TodayDeleteFailure` y view modifiers `todayListRow` /
  `todayHabitSectionMotion`.
- `WeekHabitTests/TodayCollectionsTests.swift` — 10 tests.

Archivos modificados:

- `Habit+Presentation.swift` — `todayCompletionMetadata(reference:)`,
  `todaySlipMetadata(reference:)`, y `[StreakFreeze].todayBannerMessage()`.
- `TodayView.swift` — usa los nuevos componentes y dominio.

Cobertura nueva en `TodayCollectionsTests`:

- `loggableToday` filtra schedule, `endsAt` pasado y respeta el día final.
- Pending/Completed/Skipped/Slipped son mutuamente excluyentes y cubren todo `todayHabits`.
- `completedToday` incluye marcas de versión mínima.
- Hábitos flexibles que cumplen meta semanal cuentan como completados todo el resto de la
  semana.
- `dailyProgress` con 0/1/parcial, ignorando descansos del cálculo del denominador.

Última validación: build verde, suite verde con **53 tests passed**, `git diff --check`
limpio. Auditoría sigue devolviendo solo las 4 excepciones de onboarding.

### B2 implementado

- Week tiene una leyenda on-demand desde el botón `?` del header.
- `WeekGridCell.State` quedó agrupado en 4 familias visuales: hecho, pausa con intención,
  señal útil y vacío.
- La galería interna muestra todos los estados del grid semanal.

### B3 implementado

- Se agregó `OnceFlag` para centralizar flags de educación one-shot.
- El explainer de comodín aparece en Today solo hasta que se descarta.
- El prompt de recuperación puede crear una versión mínima editable en un tap.
- Al elegir "Dejar" en el formulario aparece una frase introductoria una sola vez.
- El primer botón de impulso en Today muestra una ayuda inline descartable.
- `HabitTrackingService.applyWeeklyFreezes` ahora devuelve los comodines insertados y
  tiene cobertura de tests.

Última validación: build verde, suite verde con **54 tests passed**, `git diff --check`
limpio.

### B4 implementado

- `WHCreationSheet` jerarquiza **Nuevo hábito** como acción principal.
- **Nuevo plan** y **Sesión de foco** quedan como opciones secundarias.
- Foco se deshabilita con razón visible cuando no hay hábitos disponibles para hoy.
- Today y Week calculan los hábitos disponibles para foco y pasan solo la razón al sheet.
- La acción de foco conserva un guard para no abrir una sesión vacía.

Última validación: build verde, `git diff --check` limpio. Validación manual del usuario:
funcionó bien.

### A4 implementado

- Se agregó `PerformanceSeedService` en DEBUG para generar un dataset reproducible de
  **5 hábitos × 365 días** con completados, mínimos, descansos, misses, slips y urges.
- Se agregó `scripts/seed_performance_data.sh` para pedir el seed en un simulador:

```bash
APP_PATH=/ruta/a/WeekHabit.app scripts/seed_performance_data.sh
```

  `APP_PATH` es opcional si la app ya está instalada. El script marca el onboarding como
  completado y activa `debugSeedPerformanceDataOnLaunch`; `ContentView` ejecuta el seed
  una vez y apaga el flag.
- `InsightsView` tiene un botón DEBUG de `speedometer` para disparar el mismo seed a mano.
- Se agregó `AppPerformance.measure` para loguear tiempos DEBUG de métricas calientes en
  Insights y Week. En release solo ejecuta el bloque sin logging.
- Se agregó `AppFormatters` y se centralizó el locale `es_MX` y los `DateFormatter`
  repetidos.
- No se cachearon métricas todavía: A4 pedía medir antes de cachear. Con el seed y los
  logs ya existe la base para correr Time Profiler y decidir si hace falta un cache
  `@State` por firma.

Última validación: build verde, suite verde, `git diff --check` limpio. La auditoría de
escrituras directas sigue devolviendo solo las excepciones de onboarding.

### A5 implementado

- Se agregó `View.insightCard(...)` para centralizar padding, fondo, radio y elevación de
  las cards de Insights.
- `InsightsHeroCard`, `InsightSummaryCard`, `InsightConfidenceCard`,
  `RhythmExperimentCard`, `ExperimentReviewCard`, `UrgePeakHoursCard`, `ActiveExperimentCard`,
  `warmupCard` y `emptyState` usan el modifier compartido.
- Se agregaron tokens tipográficos en `AppFont`:
  - `insightHeroMetric`
  - `dataMetric`
  - `iconSmall`
  - `iconMedium`
  - `iconLarge`
  - `iconXL`
- El hero de Insights dejó de usar `Font.system(size: 64...)` directo.
- Se migraron tamaños de iconos, radios/espaciados de barras y chips de Insights a tokens
  existentes o nuevos.
- Se eliminaron los `.tracking(...)` locales de Insights.
- No se introdujeron usos nuevos de aliases legacy.

Última validación: build verde, suite verde, `git diff --check` limpio. La auditoría de
escrituras directas sigue devolviendo solo las excepciones de onboarding.

### Pendiente del plan

- **B1**: onboarding mínimo queda descartado/no tocar por ahora.

## Estado completado

### Fase 1: escrituras compartidas y formularios de hábitos

- `HabitTrackingService` centraliza estados diarios, cantidades, descansos, slips,
  urges, misses y freezes.
- `HabitDraft` agrupa estado, validación y normalización de `CreateHabitView`.
- `HabitEditorService` crea y edita hábitos y relaciones.
- `TodayView`, `WeekView` y `FocusSessionView` delegan tracking compartido.
- `.urge` se trata como evidencia independiente y nunca se elimina al cambiar el estado
  principal del día.

### Fase 2: infraestructura de pruebas

- Existe el target `WeekHabitTests`.
- Cada prueba usa un `ModelContainer` SwiftData en memoria.
- La suite cubre tracking, scheduling, streaks, freezes y recovery.

### Fase 3: división del dominio de hábitos

El antiguo `Habit+Domain.swift` fue separado en:

- `Habit+Scheduling.swift`
- `Habit+Completion.swift`
- `Habit+Streaks.swift`
- `Habit+Freezes.swift`
- `Habit+Recovery.swift`
- `Habit+Presentation.swift`

Las APIs públicas se conservaron.

### Fase 4: formulario y persistencia de planes

- `PlanDraft` agrupa estado, validación y normalización de `CreatePlanView`.
- `PlanEditorService` crea/edita planes, vincula hábitos y reconcilia hitos.
- `CreatePlanView` ya no implementa escrituras SwiftData directas.
- La suite actual contiene 16 pruebas.

## Estado de Git y del worktree

No asumir que el worktree está limpio y nunca descartar cambios existentes. Al iniciar:

```bash
git status --short
git diff --check
git log --oneline -5
```

Commits de referencia visibles al cerrar esta conversación:

- `b1c521c`: implementación de fases 1 y 2.
- `51602d9`: implementación de fase 3.
- `0c54f52`: implementación de fase 4.

El worktree contiene los cambios de documentación de este handoff. Revisar siempre el
estado real antes de continuar y trabajar sobre él; no usar `git reset --hard` ni
`git checkout --`.

## Fase 5: extraer mutaciones restantes de las vistas

### Meta

Eliminar reglas de persistencia y `try? modelContext.save()` restantes de las vistas.
Después de esta fase, una búsqueda de escrituras directas debería estar vacía o contener
solo excepciones explícitamente documentadas.

Comando de auditoría:

```bash
rg -n "modelContext\.(insert|delete|save)|try\? modelContext" WeekHabit/Views -g '*.swift'
```

Al finalizar la fase 4, esta búsqueda encontraba 10 escrituras en seis flujos.

### 5A. Onboarding

Archivos actuales:

- `WeekHabit/Views/OnboardingView/OnboardingView.swift`
- `WeekHabit/Views/OnboardingView/Components/OnboardingHabitsScreen.swift`
- `WeekHabit/Views/OnboardingView/OnboardingHabitDraft.swift`

Problemas:

- `ensurePlan()` crea o modifica un plan directamente.
- `continueFromHabits()` usa `try? modelContext.save()`.
- `toggleTemplate(_:)` inserta y elimina hábitos y modifica relaciones.
- Un error de guardado no se muestra y el flujo podría avanzar sin persistir.

Implementación recomendada:

- Crear `OnboardingSetupService`.
- `preparePlan(goal:motivation:existingPlans:modelContext:)` debe devolver el plan
  existente actualizado o uno nuevo insertado.
- `addHabit(from:to:modelContext:)` y `removeHabit(_:from:modelContext:)` deben manejar
  inserción, borrado y relación con el plan.
- `save(modelContext:) throws` debe reemplazar el `try?`.
- La vista debe conservar navegación, selección visual y mensajes de error.

Pruebas requeridas:

- Reutiliza el primer plan existente en vez de crear duplicado.
- Normaliza título y motivación; usa `"Mi semana"` como fallback.
- Agregar template vincula exactamente un hábito al plan.
- Quitar template elimina el hábito creado y lo desvincula.
- Guardar persiste plan y hábitos.

Criterio de aceptación:

- Cero llamadas `insert`, `delete`, `save` o `try?` en las dos vistas de onboarding.

### 5B. Borrado de hábitos y planes

Archivo actual:

- `WeekHabit/Views/TodayView/TodayView.swift`

Problemas:

- `deleteSelectedHabit()` y `deleteSelectedPlan()` borran directamente.
- El borrado del hábito también coordina la cancelación de recordatorios.

Implementación recomendada:

- Crear `HabitLifecycleService.delete(_:modelContext:) throws`.
- Crear `PlanLifecycleService.delete(_:modelContext:) throws`.
- El servicio de hábito persiste el borrado; la vista conserva animación y ejecuta
  `HabitReminderService.cancelReminder` después de un borrado exitoso.
- Mostrar error si falla el guardado.

Pruebas requeridas:

- Borrar hábito elimina entradas y freezes por las reglas cascade existentes.
- Borrar plan conserva hábitos por la relación `.nullify`.
- Un plan borrado elimina sus hitos por cascade.

Criterio de aceptación:

- `TodayView` no llama directamente a `modelContext.delete`.

### 5C. Revisión semanal

Archivo actual:

- `WeekHabit/Views/WeeklyReviewView/WeeklyReviewView.swift`

Problemas:

- `confirmReview()` construye y persiste `WeeklyReview` y decisiones.
- La vista calcula qué hábitos pausar y modifica `pausedUntil`.
- `WeeklyReviewService` actualmente solo gestiona calendario y notificaciones; no debe
  mezclarse silenciosamente con persistencia sin renombrarlo.

Implementación recomendada:

- Crear `WeeklyReviewEditorService`.
- Definir un input pequeño, por ejemplo:

```swift
struct WeeklyReviewInput {
    let weekStart: Date
    let weekEnd: Date
    let reflectionNote: String
    let decisions: [UUID: WeeklyReviewDecisionKind]
}
```

- `save(input:habits:existingReviews:reference:modelContext:) throws` debe:
  - evitar duplicar una revisión de la misma semana;
  - normalizar la nota;
  - crear decisiones con sus ratios;
  - pausar por siete días los hábitos con decisión `.pause`;
  - insertar y guardar la revisión;
  - devolver IDs pausados para que la vista coordine recordatorios.
- Mantener haptics, dismiss y notificaciones en la vista.

Pruebas requeridas:

- No crea duplicados para una semana existente.
- Persiste una decisión por hábito.
- Calcula y persiste ratios.
- Pausa únicamente hábitos marcados `.pause`.
- Normaliza nota vacía a `nil`.

Criterio de aceptación:

- `WeeklyReviewView` no inserta modelos ni implementa la transacción.

### 5D. Experimentos de Insights

Archivo actual:

- `WeekHabit/Views/InsightsView/InsightsView.swift`

Problemas:

- `startExperiment(_:)` crea, aplica e inserta un experimento.
- `keep` y `revert` mutan modelos desde la vista, aunque la regla vive parcialmente en
  `HabitExperiment+Domain`.

Implementación recomendada:

- Crear `HabitExperimentService`.
- Métodos sugeridos:
  - `start(suggestion:existingExperiments:reference:modelContext:) throws`
  - `keep(_:reference:modelContext:) throws`
  - `revert(_:habit:reference:modelContext:) throws`
- El servicio debe evitar experimentos activos duplicados y guardar los cambios.
- La vista conserva animación y haptics.

Pruebas requeridas:

- No crea un segundo experimento activo para el mismo hábito.
- `start` guarda estado original y aplica el ritmo experimental.
- `keep` conserva el ritmo y resuelve el experimento.
- `revert` restaura el ritmo original y resuelve el experimento.

Criterio de aceptación:

- `InsightsView` no crea ni inserta `HabitExperiment`.

### 5E. Sesiones de enfoque

Archivo actual:

- `WeekHabit/Views/FocusSessionView/FocusSessionView.swift`

Problemas:

- `startSession()` inserta `FocusSession`.
- Finalizar, cancelar y completar mutan la sesión desde la vista.
- El tracking de hábitos ya delega a `HabitTrackingService`, por lo que no debe duplicarse.

Implementación recomendada:

- Crear `FocusSessionService`.
- Métodos sugeridos:
  - `start(selectedHabitIDs:durationSeconds:reference:modelContext:) throws -> FocusSession`
  - `finishForReview(_:reference:modelContext:) throws`
  - `complete(_:completedHabitIDs:reference:modelContext:) throws`
  - `cancel(_:reference:modelContext:) throws`
- No mover al servicio animaciones, milestone covers ni haptics.
- Mantener `HabitTrackingService` como autoridad del estado diario.

Pruebas requeridas:

- Inicia sesión con estado `.running`.
- Finalizar para revisión define `endedAt` y estado `.reviewing`.
- Completar guarda IDs y estado `.completed`.
- Cancelar define estado `.cancelled`.

Criterio de aceptación:

- `FocusSessionView` no inserta ni persiste sesiones directamente.

### 5F. Notas de entradas

Archivo actual:

- `WeekHabit/Views/TodayView/Components/EntryNoteSheet.swift`

Problema:

- `commit()` modifica `entry.note` y usa `try? modelContext.save()`.

Implementación recomendada:

- Añadir `updateNote` a `HabitTrackingService` o crear un servicio pequeño de entradas.
- Normalizar texto vacío a `nil`, evitar saves si no cambió y propagar errores.
- La sheet debe mostrar el error o delegarlo a su vista dueña.

Pruebas requeridas:

- Texto con espacios se normaliza.
- Texto vacío elimina la nota.
- El mismo valor no realiza cambios observables.

Criterio de aceptación:

- No quedan `try? modelContext.save()` en vistas.

### Orden recomendado para fase 5

1. Onboarding, porque contiene un error silenciado y varias relaciones.
2. Weekly Review, por ser la transacción restante con más reglas.
3. Focus Session.
4. Experimentos.
5. Borrados.
6. Notas.

Después de cada subfase:

```bash
git diff --check
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -configuration Debug \
  -destination 'id=54B251A8-DB14-46B3-AAB2-67B327981678' \
  -derivedDataPath /private/tmp/WeekHabitRefactorDerivedData \
  test CODE_SIGNING_ALLOWED=NO
```

El UUID del simulador puede cambiar. Consultar dispositivos disponibles con:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl list devices available
```

## Fase 6: auditoría final, cobertura y cierre

### Meta

Confirmar que la arquitectura resultante es consistente, legible y protegida antes de
considerar terminado el refactor.

### 6A. Auditoría de mutaciones

La búsqueda de `modelContext.insert/delete/save` no detecta todas las mutaciones. También
auditar asignaciones directas a modelos desde vistas:

```bash
rg -n "@Environment\(\\\.modelContext\)|modelContext" WeekHabit/Views -g '*.swift'
rg -n "\.(pausedUntil|endsAt|reviewedAt|note|status|habits|plans|milestones)\s*=" WeekHabit/Views -g '*.swift'
```

Clasificar cada resultado:

- presentación/coordinación válida;
- llamada a servicio válida;
- regla de negocio que todavía debe extraerse;
- excepción documentada.

No perseguir un objetivo artificial de cero `@Environment(\.modelContext)`: las vistas
pueden necesitar pasarlo a servicios. Sí perseguir cero transacciones implementadas en
layout code.

### 6B. Auditoría de errores

- Buscar `try?` y revisar cada caso.
- Los `try?` de animaciones o sleeps pueden ser válidos.
- Los `try?` de persistencia y notificaciones importantes deben manejarse o documentarse.
- Confirmar que formularios no hacen dismiss después de un save fallido.

Comando:

```bash
rg -n "try\?" WeekHabit -g '*.swift'
```

### 6C. Cobertura adicional

Objetivo recomendado: 25-30 pruebas enfocadas en reglas, no en cantidad arbitraria.

Agregar pruebas para:

- `HabitEditorService`: creación, edición, relaciones, reemplazos y recordatorios.
- Servicios extraídos en fase 5.
- `Plan+Domain`: progreso, finalización y review.
- Migraciones o al menos creación del `SchemaV17` en memoria.
- Bugs descubiertos durante QA.

No comenzar por snapshots o UI tests amplios. Primero proteger transacciones y dominio.

### 6D. Auditoría de vistas grandes

Medir:

```bash
find WeekHabit/Views -name '*.swift' -print0 | xargs -0 wc -l | sort -nr | head -20
```

Revisar especialmente vistas de más de 500 líneas. Extraer solo cuando exista una
responsabilidad clara:

- componentes visuales reutilizables o locales;
- routers y estado de presentación;
- coordinadores de efectos secundarios;
- cálculos que pertenezcan al dominio.

Evitar fragmentar vistas pequeñas solo para reducir líneas.

### 6E. QA manual

Probar en simulador:

1. Onboarding completo, incluyendo agregar/quitar templates.
2. Crear y editar hábito check y cantidad.
3. Crear y editar plan con hábitos e hitos.
4. Completar, descansar, mínimo, slip y urge.
5. Editar semana retroactivamente.
6. Iniciar, finalizar, cancelar y guardar sesión de enfoque.
7. Iniciar, mantener y revertir experimento.
8. Completar revisión semanal y pausar un hábito.
9. Borrar hábito y plan.
10. Cerrar y volver a abrir la app para verificar persistencia.

### 6F. Documentación y cierre

Actualizar:

- `ARCHITECTURE.md`: arquitectura final y excepciones.
- `DOCUMENTATION.md`: servicios y flujos actuales.
- `TESTING.md`: cobertura final y comando estable.
- `CLAUDE.md`: instrucciones correctas para futuros cambios.

Registrar métricas finales:

- número de escrituras directas en vistas;
- número de `try?` de persistencia;
- número de pruebas;
- vistas principales antes/después;
- build y suite final.

Criterios de terminación:

- No hay `try? modelContext.save()` en vistas.
- Las transacciones complejas viven en servicios.
- Las reglas de dominio están cubiertas por pruebas.
- `git diff --check` limpio.
- `build-for-testing` exitoso.
- Suite completa exitosa.
- QA manual de los flujos críticos realizado.

## Riesgos y decisiones que deben conservarse

- No borrar ni convertir entradas `.urge` al cambiar el estado principal diario.
- No editar schemas antiguos; cualquier cambio persistido requiere un nuevo `SchemaV*` y
  migración.
- No mover navegación, animaciones, haptics o presentación a servicios.
- No crear un repositorio genérico de SwiftData: los servicios deben reflejar flujos y
  lenguaje del dominio.
- No revertir cambios preexistentes del usuario.
- Conservar las relaciones y delete rules actuales:
  - hábito elimina entries y freezes por cascade;
  - plan elimina milestones por cascade;
  - borrar plan no debe borrar hábitos.

## Prompt sugerido para la próxima conversación

```text
Continúa el refactor arquitectónico de WeekHabit desde REFACTOR_HANDOFF.md.
Lee primero ARCHITECTURE.md, TESTING.md, DOCUMENTATION.md y el estado del git worktree.
Implementa la fase 5 completa por subfases, documentando y ejecutando la suite después
de cada extracción. No reviertas cambios existentes y conserva el comportamiento actual.
```
