# Plan de simplificación: complejidad acumulada y densidad conceptual

Este documento ataca los dos riesgos estructurales de WeekHabit:

- **Complejidad acumulada** (Parte A): la paga el mantenimiento. Vistas god-file,
  escrituras directas pendientes, lógica de producto sin tests.
- **Densidad conceptual** (Parte B): la paga el usuario nuevo. Demasiados conceptos
  expuestos antes de tener contexto para entenderlos.

Cada fase es ejecutable en una sesión independiente. Leer también
`REFACTOR_HANDOFF.md`, `ARCHITECTURE.md` y `TESTING.md` antes de empezar una fase.

Comando de build de referencia:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

## Estado actual — 2026-06-16

- **A1 está terminado** para el alcance acordado. Onboarding queda como excepción
  intencional porque se decidió conservar el onboarding de 6 pasos y no tocarlo.
- **A3 está implementado**: `HabitCollection+Insights.swift` fue partido en tres
  archivos y se agregaron tests de métricas/ranking de Insights.
- Última validación conocida: build verde, suite verde con **43 tests passed**,
  `git diff --check` limpio.
- **Siguiente paso recomendado:** A2, partir `TodayView`.
- Para continuar desde otra conversación, leer primero `REFACTOR_HANDOFF.md`; tiene el
  detalle de commits, archivos, comandos y pendientes.

---

## Parte B primero en un punto: B1 reduce el alcance de A1

El onboarding actual crea un plan con goal/motivation (pantallas `goal`,
`motivation`, `size`). La fase 5A del handoff propone `OnboardingSetupService`
justamente para esas escrituras. Si B1 elimina esas pantallas del onboarding,
**5A se reduce a la mitad**. Por eso el orden recomendado intercala las partes.

---

## Parte A — Complejidad acumulada

### A1. Cerrar la fase 5 del REFACTOR_HANDOFF

La especificación completa ya existe en `REFACTOR_HANDOFF.md` (subfases 5A–5F:
servicios, tests requeridos y criterios de aceptación). No se duplica aquí.

Estado auditado (2026-06-10): siguen las **mismas 10 escrituras directas en 7
vistas** que al cierre de la fase 4:

```bash
rg -n "modelContext\.(insert|delete|save)|try\? modelContext" WeekHabit/Views -g '*.swift'
```

Archivos: `OnboardingView`, `OnboardingHabitsScreen`, `FocusSessionView`,
`InsightsView`, `TodayView`, `EntryNoteSheet`, `WeeklyReviewView`.

Ajustes al orden del handoff:

1. **Ejecutar B1 antes de 5A** (ver arriba): el onboarding sin plan deja a 5A
   solo con la creación de hábitos starter.
2. Resto igual: Weekly Review → Focus → Experimentos → Borrados → Notas.

**Hecho cuando:** el comando de auditoría devuelve cero (o solo excepciones
documentadas), build verde y suite verde tras cada subfase.

### A2. Partir `TodayView` (1.183 líneas → ~400)

`TodayView.swift` concentra: 5 `@Query`, 12 `@State`, ~25 propiedades derivadas,
routing, construcción de strings y orquestación de milestones/notas diferidas.
Plan de extracción en 4 movimientos, cada uno compilable por separado:

1. **Colecciones derivadas → dominio puro** (lo más valioso, hazlo primero).
   Crear `Models/Domain/HabitCollection+Today.swift` con extensión sobre
   `[Habit]`: `loggableToday(on:)`, `pending(on:)`, `completed(on:)`,
   `skipped(on:)`, `slipped(on:)`, `dailyProgress(on:)`, conteos de mañana.
   Son reglas de negocio que hoy viven en la vista (`TodayView.swift:70-129`).
   Testearlas (ver tests abajo). La vista queda con llamadas de una línea.

2. **Textos derivados → presentación**. `completionMetadata(for:)` (~48 líneas),
   `slipMetadata(for:)` (~27) y `weeklyFreezeMessage` son copy derivado del
   modelo → mover a `Models/Domain/Habit+Presentation.swift` (ya existe para
   esto) como `todayCompletionMetadata(reference:)` etc.

3. **Secciones → componentes**. Siguiendo el patrón de carpetas existente:
   - `TodayHeaderSection.swift` (header + progreso diario)
   - `TodayPlansSection.swift` (plansSection + planRow + binding de `expandedPlans`)
   - `TodayHabitListSection.swift` (sectionHeader + listas por estado + namespace)
   El contenedor conserva: queries, routing, alerts, orquestación de milestone
   cover y nota diferida (es coordinación de presentación, le pertenece).

4. **Routing → archivo propio**. `TodayCoverRoute`/`TodaySheetRoute` +
   `routeCover`/`routeSheet` → `Components/TodayRouting.swift` (mismo patrón
   que ya usa WeekView con sus enums privados, pero en archivo separado).

Tests nuevos (`WeekHabitTests/TodayCollectionsTests.swift`):
- clasificación pending/completed/skipped/slipped excluyente y completa;
- `dailyProgress` con 0 hábitos, todos completados, y pausados;
- hábito con `endsAt` hoy aparece/desaparece correctamente.

**Hecho cuando:** `TodayView.swift` < ~450 líneas, sin funciones que construyan
strings de copy, y las colecciones derivadas tienen tests.

### A3. Insights: tests del ranking y partición del archivo

El ranking de sugerencias decide qué le propone la app al usuario y hoy no
tiene ningún test. Es la lógica más fácil de romper en silencio.

1. **Partir `HabitCollection+Insights.swift`** (552 líneas) con el mismo patrón
   de la fase 3 (APIs públicas intactas, solo mover):
   - `HabitCollection+InsightSnapshot.swift` — snapshot global, readiness, confianza
   - `HabitCollection+InsightContexts.swift` — mejor día/hora, atención, top consistente, urges
   - `HabitCollection+ExperimentSuggestions.swift` — sugerencias + scoring

2. **Tests** (`InsightMetricsTests.swift` y `ExperimentSuggestionTests.swift`,
   usando el `ModelContainer` en memoria de `TestSupport.swift`):
   - Readiness: < 5 días no listo; ventana provisional (5–21); progreso.
   - Snapshot: ventanas de 30 días correctas en los bordes; delta; 12 buckets
     de tendencia; conteo de `minimumDays`.
   - Confianza: umbrales high/learning/low; marcas `.manual` no cuentan como
     confiables; `.focusSession` sí.
   - Sugerencias: excluye hábitos con experimento activo; ratio < 55% produce
     propuesta de reducir días; hora con señal confiable produce fix-hour;
     orden por score estable y determinista; sin datos suficientes → vacío.
   - `attentionHabit`: prioriza menor consistencia / sin racha; failure types.
   - `urgePeakHourInsight`: nil con < 3 urges; ventana de pico correcta.

**Hecho cuando:** la suite cubre cada rama del scoring y los tres archivos
nuevos compilan sin cambios de API.

### A4. Rendimiento: medir antes, cachear después

Patrón actual: todas las métricas son computed properties sobre `@Query`
(`InsightsView.swift:23-64`), recalculadas en cada render.

1. **Medir primero.** Script de seed para desarrollo (5 hábitos × 365 días de
   entries) + Time Profiler en Insights y Week. Sin medición, no optimizar.
2. **Si duele:** mover las métricas pesadas a `@State` recalculado en
   `.task(id: signature)` donde `signature` combina conteo de entries + día
   actual — el mismo patrón de invalidación que ya usa
   `todayHabitSectionSignature` en TodayView.
3. **Centralizar formatters:** crear `Extensions/AppFormatters.swift`. Los
   `DateFormatter` con `es_MX` hardcodeado están repetidos en WeekView,
   TodayView, InsightDateHelpers y más. Un solo punto = una sola decisión de
   locale el día que importe.

### A5. Higiene de tokens (oportunística, sin fase propia)

- Ejecutar el backlog visual de Insights ya documentado (hardcodes → tokens,
  64pt del hero → token en `AppFont`, modifier `.insightCard()` para el
  boilerplate repetido 9×).
- No introducir usos nuevos de aliases legacy (`AppFont.body2`,
  `AppRadius.medium`…); migrar al token nuevo cada vez que se toque un archivo.

---

## Parte B — Densidad conceptual

### B0. El mapa de niveles (la regla que gobierna todo lo demás)

| Nivel | Cuándo se expone | Conceptos |
|---|---|---|
| 0 — Día uno | Siempre visible | Hábito, marcar check, Hoy, la semana |
| 1 — Primera semana | En el formulario, visible | Cantidad, agenda específica/flexible, recordatorio, señal |
| 2 — Cuando sucede | Just-in-time, nunca antes | Descanso, comodín, versión mínima, recovery |
| 3 — Madurez | Cuando el usuario lo busca | Planes e hitos, experimentos, foco, weekly review, hábitos break (urges/slips) |

**Regla de diseño:** ningún concepto de nivel ≥ 2 se explica de forma
anticipada. Se explica la primera vez que ocurre, en el lugar donde ocurre.
(El warmup de Insights y el paso 3 opcional del formulario ya cumplen esto;
esta parte lo convierte en norma.)

### B1. Onboarding: de 6 pasos a 3

Actual: `intro → goal → motivation → size → habits → notifications`
(`OnboardingStep.swift`). Goal/motivation/size son conceptos de **Plan**
(nivel 3) presentados a alguien que aún no marcó su primer hábito.

Propuesta: `intro → habits → notifications`.

- Eliminar los cases `goal`, `motivation`, `size` de `OnboardingStep` y sus
  pantallas (`OnboardingGoalScreen`, `OnboardingMotivationScreen`,
  `OnboardingSizeScreen`).
- El onboarding **deja de crear un plan**: goal y motivation ya se piden en
  `PlanFlowView`/`CreatePlanView`, su lugar natural. `PlanOnboardingView`
  (primera creación de plan) ya existe para educar ahí.
- La intención de "size" (empezar pequeño) se conserva como copy en la
  pantalla de starter habits, no como pantalla propia.
- Conservar: skip, starter habits, permiso de notificaciones al final.
- Tocar: `OnboardingStep.swift`, `OnboardingView.swift`,
  `OnboardingHabitDraft.swift` (quitar plan), borrar 3 pantallas.

**Hecho cuando:** un usuario nuevo llega a Today con un hábito creado en
menos de 60 segundos, y el onboarding no inserta ningún `Plan`.

### B2. Week: 13 estados de celda → 4 familias visuales + leyenda

No tocar el dominio ni el sistema de confianza (retro/trusted). Solo la
gramática visual y su explicación:

1. **Documentar 4 familias** y alinear las celdas a ellas en `WeekGridCell`:
   - *Hecho* (completed, completedRetro, minimum, partial, partialRetro):
     siempre relleno del color del hábito; retro = trazo punteado; minimum =
     opacidad reducida; partial = punto. Variaciones de una misma familia.
   - *Pausa con intención* (skipped, frozen): tonos calmos, borde punteado/escudo.
   - *Señal útil* (missed, slip, urge): nunca rojo destructivo (regla existente).
   - *Vacío* (pending, inactive, future): neutros.
2. **Leyenda on-demand**: botón `?` discreto en el header de Week →
   `WeekLegendSheet.swift` que renderiza cada `WeekGridCell.State` real (reusar
   el componente) con nombre y una línea de descripción. Detent `.medium`.
3. Añadir los estados a `ComponentsGalleryView` si aún no están.

**Hecho cuando:** cualquier celda puede entenderse sin salir de la pantalla y
la gramática (relleno=hecho, punteado=retro, etc.) está escrita en un comentario
de `WeekGridCell`.

### B3. Educación just-in-time (nivel 2 del mapa)

Mecanismo común primero: `Support/OnceFlags.swift` — un tipo pequeño sobre
`AppStorage` (`hasSeenFreezeExplainer`, `hasSeenBreakIntro`, …) para no regar
flags por la app.

1. **Comodín**: la primera vez que `applyWeeklyFreezes` protege un día, mostrar
   una card descartable en Today: "Tu comodín protegió el martes" + una línea
   de qué es. Hook: los servicios de freeze ya saben cuándo se aplica uno;
   exponer el evento a la vista.
2. **Versión mínima**: `Habit+Recovery.swift` ya detecta candidatos a prompt de
   recuperación. Ampliar el prompt: ofrecer crear la versión mínima con un tap
   (pre-llenar `minimumViableTitle` con sugerencia editable), en vez de esperar
   a que el usuario descubra el campo en el formulario.
3. **Hábitos break**: al elegir "Dejar" en el paso 1 del wizard, una sola frase
   introductoria (qué cambia: registrar impulsos y resistencias). El primer
   botón de urge en Today lleva tooltip de una vez.

**Hecho cuando:** ninguna explicación de comodín/versión mínima/urges aparece
antes de su primer uso, y cada una aparece exactamente una vez.

### B4. Menú de creación: jerarquía, no menú plano

`WHCreationSheet` ofrece Hábito/Plan/Foco con el mismo peso. Ajuste ligero:
Hábito como opción primaria; Plan y Foco con subtítulo de una línea que diga
qué son; Foco deshabilitado (con razón visible) cuando no hay hábitos para hoy.
Sin gating duro — solo jerarquía visual.

---

## Orden de ejecución recomendado

| # | Fase | Por qué en este orden |
|---|---|---|
| 1 | **B1** Onboarding mínimo | Reduce el alcance de 5A; es la mejora de usuario más barata |
| 2 | **A1** Fase 5 completa | Cierra la arquitectura; 5A ya simplificado por B1 |
| 3 | **A3** Tests + partición de Insights | Red de seguridad antes de seguir moviendo código |
| 4 | **A2** Partir TodayView | El god-file, ya con servicios y tests detrás |
| 5 | **B2 + B3** Leyenda Week + just-in-time | Producto puro, sin dependencias de código pendiente |
| 6 | **A4 / A5 / B4** | Según dolor medido y oportunidad |

## Verificación global (al final de cada fase)

```bash
git diff --check
# build (comando al inicio del documento)
# suite completa:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project WeekHabit.xcodeproj -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
# auditoría de escrituras en vistas (debe tender a cero):
rg -n "modelContext\.(insert|delete|save)|try\? modelContext" WeekHabit/Views -g '*.swift'
```

Manual, una vez por parte:
- **A:** flujo completo crear→marcar→borrar hábito; review semanal; experimento
  start/keep/revert sin regresiones.
- **B:** onboarding nuevo usuario < 60 s; leyenda de Week responde "¿qué es esta
  celda?"; el explainer de comodín aparece una sola vez y en el momento correcto.
