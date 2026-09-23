# WeekHabit — Documentación del proyecto

Referencia técnica del repo. Para la visión de producto, leer `IDENTIDAD_MISION.md`. Para las
reglas de arquitectura, `ARCHITECTURE.md`. Para tokens y componentes, `DESIGN_SYSTEM.md`.
Para la suite y los números de rendimiento, `TESTING.md`.

## Qué es WeekHabit

App iOS para construir hábitos con ritmo semanal: planear hábitos, registrarlos día a día,
revisar la semana, detectar patrones de consistencia y agrupar hábitos bajo metas.

El enfoque no es solo "marcar tareas", sino entender el ritmo real: qué hábitos se sostienen,
qué días funcionan mejor, qué horarios tienen más evidencia y cuándo conviene ajustar.

**Stack:** Swift 5.0 · SwiftUI · SwiftData · UserNotifications · iOS 26.4+ · iPhone y iPad.

- Proyecto Xcode único: `WeekHabit.xcodeproj`. Sin SPM, CocoaPods ni dependencias externas.
- Target de pruebas `WeekHabitTests` con SwiftData en memoria.
- UI y comentarios en español (es_MX). Identificadores en inglés.
- Persistencia local con schema versionado hasta `SchemaV17`.

## Build y pruebas

```bash
open WeekHabit.xcodeproj
```

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Verificación rápida sin firma de código:

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

Suite completa:

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

No hay configuración de lint.

## Estructura del repo

```text
WeekHabitCore/              Compilado por la app Y por el widget
  Models/
    Entities/               @Model de SwiftData y enums persistidos
    Domain/                 Reglas puras de solo lectura sobre las entidades
    Insights/               Métricas de 30 días, agregados y sugerencias
    Persistence/            SchemaV1…V17, HabitMigrationPlan y AppGroupStore
    Routing/                Value types de navegación (HabitRoute, PlanRoute, WidgetDeepLink)
    Support/                HabitAppearance, Weekday, OnceFlags, copy de identidad
  Extensions/               Los tokens que el widget necesita (color, tipografía, calendario)
  Components/               WHProgressRing
WeekHabit/                  Solo la app
  WeekHabitApp.swift        Entry point, ModelContainer y RootView
  ContentView.swift         Shell de tabs + hojas de cierre de plan y revisión semanal
  Services/                 Frontera de escritura (14 servicios sin estado)
  Views/
    <Feature>View/          Pantalla + su carpeta Components/
    Components/             UI compartida por 2+ features
  Extensions/               Tokens y helpers que solo usa la app (haptics, fondo, teclado)
WeekHabitWidgets/           Extensión de widget
  Views/                    Una vista por familia + copy y muestras
Config/                     Entitlements del App Group e Info.plist de la extensión
WeekHabitTests/             22 suites contra un ModelContainer en memoria
scripts/                    Seed de rendimiento y exportación de iconos
```

El corte no es estético: **lo que está en `WeekHabitCore/` lo compilan los dos targets**, así
que un archivo nuevo ahí llega al widget solo. Es una carpeta y no un paquete, de modo que
cada target la compila dentro de su propio módulo y todo sigue siendo `internal`.

## Arquitectura

Arquitectura SwiftUI pragmática. Las reglas completas y sus excepciones están en
`ARCHITECTURE.md`; esto es el resumen.

```text
Vistas SwiftUI
  @Query para leer · navegación, animación, haptics y coordinación
        |
        v
Estado de feature
  HabitDraft · PlanDraft · TodayViewData · TodayScreenModel
        |
        v
Servicios de dominio
  Mutaciones, transacciones y reconciliación de relaciones
        |
        v
Dominio de solo lectura
  Habit+Scheduling / Completion / Streaks / Freezes / Recovery / Presentation
  HabitDayIndex · Plan+Domain · FocusSession+Domain · HabitExperiment+Domain
        |
        v
SwiftData
  9 entidades · SchemaV17 · HabitMigrationPlan
```

Las tres reglas que más importan al escribir código nuevo:

1. **Las vistas no escriben a `modelContext`.** Toda mutación pasa por un servicio. Asignar
   una propiedad de un `@Model` desde una vista también es una escritura: SwiftData la
   persiste por autosave.
2. **Los errores de persistencia no se silencian** con `try?`. Se muestran, y un formulario
   no hace `dismiss()` tras un save fallido.
3. **Las entradas `.urge` son evidencia independiente.** Cambiar el estado principal de un día
   nunca las borra ni las convierte.

`WeekHabitApp` construye el `ModelContainer` con `Schema(versionedSchema: SchemaV17.self)` y
`HabitMigrationPlan.self`. `RootView` decide entre `OnboardingView` y `ContentView` según
`@AppStorage("hasCompletedAppOnboarding")`, y al iniciar y al volver a foreground refresca los
recordatorios de hábitos y el de revisión semanal.

## Modelos de datos

Nueve entidades `@Model`, todas en `Models/Entities/`.

### `Habit`

Entidad central.

| Campo | Notas |
|---|---|
| `title`, `note`, `cue` | `cue` es la señal "después de X, hago Y" |
| `minimumViableTitle` | Versión mínima para días difíciles |
| `iconNameRaw`, `colorHexRaw` | Con fallback a `legacyArea` y a `HabitAppearance` |
| `trackingKindRaw` | `HabitTrackingKind`: `check` o `quantity` |
| `measurementUnitRaw`, `customUnitName`, `targetValuePerSession` | Solo para `quantity` |
| `scheduleKindRaw` | `HabitScheduleKind`: `daily`, `specificDays`, `timesPerWeek` |
| `targetDaysPerWeek`, `activeDaysOfWeekRaw` | Agenda; `activeDaysOfWeek` expone un `Set<Weekday>` |
| `directionRaw` | `HabitDirection`: `build` o `break` |
| `endsAt`, `pausedUntil` | Fin y pausa temporal |
| `allowsWeeklyFreeze` | Habilita el comodín semanal |
| `isReminderEnabled`, `reminderTime` | Recordatorio local |
| `celebratedMilestonesRaw` | Hitos ya celebrados, para no repetir la celebración |

Relaciones: `entries` y `streakFreezes` en cascade, `replacementHabit` con nullify, `plans`
como inversa de `Plan.habits`.

### `HabitEntry`

Un registro por día. `date` se normaliza a start-of-day en el init.

- `HabitEntrySource`: `today`, `focusSession`, `manual`. Solo las dos primeras son
  `isTrustedForInsights`; las manuales sirven de historia pero no de evidencia de ritmo.
- `EntryKind`: `completed`, `skipped`, `minimum`, `missed`, `slip`, `urge`.
- `SlipTrigger`: `stress`, `boredom`, `social`, `fatigue`, `craving`, `other`.
- `HabitFailureReason`: `tooDifficult`, `forgot`, `badTiming`, `lowEnergy`, `other`.
- Además: `completedAt`, `focusSessionID`, `completedCount`, `value`, `slipContext`.
- `note` sigue en el modelo pero ya no tiene UI: conserva el texto escrito antes de que se
  quitaran las notas de entrada. Ver `HabitEntry.swift`.

### `Plan`

Meta que agrupa hábitos: `title`, `motivation`, `measurableOutcome`, `startedAt`, `endsAt`,
`targetCompletionRate`, `reviewedAt`. Relación nullify con `habits` y cascade con
`milestones`.

### `PlanMilestone`

Hito de un plan: `title`, `targetDate`, `completedAt`.

### `StreakFreeze`

Comodín semanal: `habitID`, `weekStartDate`, `protectedDate`, `usedAt`. Un día perdido por
semana no rompe la racha. `protectedDate` se normaliza a start-of-day.

### `HabitExperiment`

Experimento de ritmo de 7 días. Guarda el ritmo original
(`originalTargetDaysPerWeek`, `originalActiveDaysOfWeekRaw`) y el propuesto
(`experimentTargetDaysPerWeek`, `experimentActiveDaysOfWeekRaw`, `suggestedStartHour`), más
`baselineConsistency` y `HabitExperimentStatus`. Guardar el original es lo que hace posible
revertir.

### `FocusSession`

Sesión de ritmo: `startedAt`, `endedAt`, `durationSeconds`, `selectedHabitIDsRaw`,
`completedHabitIDsRaw` y `FocusSessionStatus`.

### `WeeklyReview` y `WeeklyReviewDecision`

Revisión de una semana (`weekStart`, `reviewedAt`, `reflectionNote`) con una decisión por
hábito en cascade. Cada decisión guarda `habitID`, `habitTitle`, `decisionRaw` y
`weeklyCompletionRatio`; el título se copia a propósito para que la revisión sobreviva al
borrado del hábito.

### Tipos de apoyo

`HabitAppearance` (paleta de iconos y colores), `Weekday`, `OnceFlags` (flags one-shot de
educación just-in-time), `IdentityReinforcementCopy`, `HelpCatalog` (el copy de la pantalla de
ayuda: las cinco formas de registrar el día que no se descubren solas, con su icono y su token de
color; si cambia cómo se marca un día, hay que revisar si alguna fila quedó mintiendo).

## Schema y migraciones

`Models/Persistence/HabitSchema.swift` declara `SchemaV1` … `SchemaV17` y
`HabitMigrationPlan`, con 16 `MigrationStage` lightweight encadenados.

Reglas:

- Un cambio de forma persistida exige un `SchemaV*` nuevo y su `MigrationStage`.
- **No editar schemas viejos** para representar formas nuevas.
- Un campo persistido nuevo también toca inicializadores y llamadores.

## Widgets

La extensión `WeekHabitWidgets` tiene dos widgets. Los dos son de **solo lectura** —muestran y
abren la app, no marcan hábitos—, los dos derivan todo lo que dibujan en un value type de
`WeekHabitCore/` para que `WeekHabitTests` lo alcance (la vista vive en la extensión, fuera del
target de pruebas), y los dos leen la base compartida por el App Group
`group.com.valentino.WeekHabit`: la app es la única que migra el esquema, la extensión abre el
contenedor de solo lectura (`WidgetStore` + `AppGroupStore.readOnlyConfiguration`). Un fallo de
lectura se dibuja con honestidad (`WidgetUnavailableView`: "abre la app"), nunca como un cero
—o una grilla vacía— que se leería como un día impecable. El refresco está centralizado en
`WidgetRefreshService.reloadWidgets()`, que se llama al salir de primer plano y cubre los dos
con `reloadAllTimelines()`; cada timeline además se reconstruye sola a la medianoche siguiente.

### Pendientes de hoy

Muestra lo que falta hoy sin abrir la app, que es el problema que originó la feature: el
usuario se olvida de entrar, y al entrar es cuando ver la lista lo empuja a actuar. En vez de
traerlo, la lista va a donde ya mira.

- **Familias:** `accessoryCircular` y `accessoryRectangular` en la pantalla de bloqueo,
  `systemSmall` y `systemMedium` en la de inicio.
- **Cuatro estados:** con pendientes, día cerrado, descanso y sin hábitos. Son cuatro para que
  un día sin pendientes no se muestre como un cero: descansar es una decisión, no una falla.
- **Datos:** `TodayWidgetSnapshot` deriva todo en una pasada desde los hábitos, reutilizando
  `todayPartition(on:)`. Tocarlo abre la app en Hoy (`WidgetDeepLink.today`).

### Año de constancia

Responde "cómo viene mi constancia" desde el inicio: una grilla anual estilo GitHub, un cuadro
por día, **agregando todos los hábitos de día fijo**. La opacidad de cada día es la fracción de
lo programado ese día que se cumplió.

- **Familia:** solo `systemLarge`, solo pantalla de inicio. El año se parte en dos tiras de 26
  semanas apiladas para que la celda siga siendo legible; sin `ScrollView`.
- **Datos:** `YearHeatmapSnapshot` (`WeekHabitCore/`) construye un `HabitDayIndex` por hábito y
  lo consulta en las 52×7 fechas. Por día produce `scheduledCount`, `completedCount`,
  `intensity` y un `kind`: `.done(level:)` en tres baldes discretos, `.scheduledNothingDone`,
  `.nothingScheduled` y `.outOfRange` (antes del primer hábito o en el futuro). Así "no hice
  nada" nunca se ve igual que "no había nada".
- **Exclusiones:** los hábitos flexibles (`.timesPerWeek`) no entran —darían siete días al
  100% por un registro—; un día protegido por comodín o marcado como descanso sale del
  numerador y del denominador de ese hábito.
- **Layout compartido:** `HeatmapMonthSegment` agrupa las semanas por mes; lo usan este widget
  y el heatmap anual in-app (`LastWeeksHeatmapCard`) para leerse como el mismo objeto.
- Tocarlo abre la app en Insights (`WidgetDeepLink.insights`).

## Lógica de dominio

Puro cálculo de solo lectura sobre las entidades, en `Models/Domain/` y `Models/Insights/`.

| Archivo | Responsabilidad |
|---|---|
| `Habit+Scheduling` | Agenda, pausas, fechas de fin, días registrables, recorrido de semanas |
| `Habit+Completion` | Estado diario, cantidades, progreso semanal, ratios |
| `Habit+Streaks` | Racha actual, de exhibición, mejor racha y desglose honesto |
| `Habit+Freezes` | Protección por comodín y candidatos de la semana |
| `Habit+Recovery` | Candidatos a prompt de recuperación |
| `Habit+Presentation` | Copy derivado, formato de cantidades, matriz del heatmap |
| `HabitDayIndex` | Índice de entradas y comodines por día normalizado |
| `HabitCollection+Today` | Particiones del día y `TodayPartition` |
| `Habit+InsightMetrics` | Métricas de 30 días, confianza, fallos, mejor día/hora |
| `HabitCollection+InsightSnapshot` | Snapshot global, readiness, confianza |
| `HabitCollection+InsightContexts` | Mejor día/hora, hábito de atención, top consistente, urges |
| `HabitCollection+ExperimentSuggestions` | Sugerencias de experimentos y su scoring |
| `HabitExperiment+Domain` | Aplicar, mantener, revertir, cancelar, revisar |
| `FocusSession+Domain` | Progreso del timer, revisión, completado, cancelación |
| `Plan+Domain` | Estado activo/terminado/en revisión, progreso, estado de meta |

Usar `AppCalendar` para todo cálculo de fechas, nunca `Calendar.current` directo.

**`HabitDayIndex` no es opcional en los recorridos largos.** Cualquier función que consulte
muchos días seguidos debe construir el índice una vez y reutilizarlo: llamar a las funciones
de un solo día dentro de un bucle es cuadrático, y fue la causa de un `bestStreak` de 2 478 ms.
Para una consulta aislada sale más barato escanear. Los números están en `TESTING.md`.

## Servicios

Trece servicios en `Services/`, todos `enum` sin estado con métodos `static` que reciben el
`ModelContext`. Son la frontera de escritura de la app.

| Servicio | Responsabilidad |
|---|---|
| `HabitTrackingService` | **Única autoridad del estado diario**: completar, cantidades, versión mínima, descanso, slips, urges, misses de recuperación y comodines |
| `HabitEditorService` | Crear y editar hábitos, apariencia, agenda, reemplazo y planes vinculados |
| `HabitLifecycleService` | Borrado de hábitos |
| `PlanEditorService` | Crear y editar planes, vincular hábitos, reconciliar hitos |
| `PlanLifecycleService` | Borrado y cierre de plan (`completeWrapUp`) |
| `WeeklyReviewEditorService` | Persistir la revisión semanal, sus decisiones y las pausas |
| `WeeklyReviewService` | Calendario de la revisión y su notificación (no persiste) |
| `FocusSessionEditorService` | Iniciar, revisar, completar y cancelar sesiones |
| `HabitExperimentService` | Iniciar, mantener y revertir experimentos |
| `OnboardingSetupService` | Plan inicial y hábitos de plantilla del onboarding |
| `HabitReminderService` | Notificaciones locales por hábito y weekday activo |
| `DailyNoticeService` | Aviso diario Time Sensitive con lo que queda del día (no persiste) |
| `PerformanceSeedService` | **Solo DEBUG.** Crear y borrar el dataset sintético de 5 hábitos × 365 días |

`HabitReminderService` arma el cuerpo del recordatorio con la motivación del plan activo,
si no la nota del hábito, si no un texto de respaldo, y no programa nada para hábitos
terminados.

`DailyNoticeService` agenda el **aviso diario**: "te quedan N hábitos hoy", con hasta dos
nombres. Es opt-in, no depende de ningún hábito y es la única notificación `.timeSensitive`
de la app, así que llega aunque haya un modo de concentración activo. Para que no reclame un
día ya cerrado se agenda como avisos sueltos para los próximos 7 días, no como uno repetido,
y `RootView` los recalcula al entrar y al salir de primer plano. Como registrar solo se puede
desde la app, ese refresco basta para que el conteo sea exacto. Si el usuario no abre la app
en más de 7 días, el aviso deja de llegar. La regla vive en `dailyNoticeOccurrences`
(`HabitCollection+DailyNotice.swift`), con pruebas en `DailyNoticeTests`.

## Pantallas y flujos

### Lanzamiento y onboarding

`WeekHabitApp` → `AppLaunchView` (splash animado en `Views/SplashScreen/`) → `RootView`.

`OnboardingView` es un flujo goal-first de seis pasos (`OnboardingStep`):
`intro → goal → motivation → size → habits → notifications`. Crea el plan inicial y los
hábitos de plantilla a través de `OnboardingSetupService`, y puede pedir permiso de
notificaciones al final. Reducirlo a tres pasos se evaluó y **se descartó** como decisión de
producto.

### Navegación principal

`ContentView` usa un `TabView(selection:)` nativo. Títulos e iconos salen de `TabItems`.

| Tag | Vista | Rol |
|---|---|---|
| 0 | `TodayView` | Registro del día, planes, sesión de ritmo |
| 1 | `WeekView` | Grilla semanal editable |
| 2 | `InsightsView` | Métricas, tendencias y experimentos |

`ContentView` también presenta dos hojas por su cuenta: `PlanWrapUpView` cuando hay un plan
terminado sin revisar, y `WeeklyReviewView` cuando toca la revisión semanal y no hay un cierre
de plan pendiente. No existe una pestaña `HabitsView`.

Mantener sincronizado el orden de los `.tag(0/1/2)` con los casos de `TabItems`.

### `TodayView`

Pantalla de uso diario. Es la referencia del patrón de estado de pantalla: `TodayViewData`
(struct de valor con los datos derivados, construida una vez por render) y `TodayScreenModel`
(clase `@Observable` con rutas, confirmaciones y estado de sección).

- Header con fecha, botón de ayuda y menú de creación (`WHCreationSheet`).
- `DailyProgressCard` con completados, total y pendientes.
- `FocusSessionLauncherCard`.
- Hábitos registrables hoy, agrupados por estado, con swipe para editar o borrar.
- Check con toggle; cantidad con `QuantityLogSheet`.
- Slip con detonante y urge para hábitos de romper.
- Sección de planes con `PlanAccordion`.
- Celebración de hitos.
- Hoja de recuperación con **todos** los hábitos que ayer quedaron sin marcar: la lista abre el
  formulario de razones de cada uno y vuelve a ella con la fila resuelta. Se auto-presenta una
  vez por día natural; mientras queden pendientes, un banner en Hoy la reabre. Contestar es
  opcional: cerrarla no escribe nada.
- Pantalla de ayuda (`TodayHelpSheet`), abierta desde el "?" del header y presentada sola una
  vez, la primera vez que se llega a Hoy. No es un catálogo de funciones: explica las cinco
  formas de registrar el día que no se descubren solas —mínima, descanso, comodín, slip e
  impulso—. Cede el turno al prompt de recuperación: si esa hoja ya está puesta, la ayuda
  espera al próximo arranque en vez de gastarse.
- Navegación a `HabitDetailView`.

### `CreateHabitView`

Formulario full-screen para crear y editar. Estado en `HabitDraft`, persistencia en
`HabitEditorService`. Cubre nombre, nota, señal, apariencia, tipo de seguimiento, unidad y
meta por sesión, agenda, dirección build/break, versión mínima, hábito de reemplazo,
recordatorio y fecha de fin.

### `CreatePlanView` y `PlanFlowView`

Creación y edición de planes con `PlanDraft` y `PlanEditorService`: meta, motivación,
resultado medible, fecha de fin, tasa objetivo, hábitos vinculados e hitos.
`PlanOnboardingView` educa en la primera creación. `PlanDetailView` muestra progreso.

### `PlanWrapUpView`

Cierre de un plan terminado. Delega en `PlanLifecycleService.completeWrapUp`, que archiva los
hábitos elegidos y marca `reviewedAt`. Mientras `reviewedAt` sea `nil`, `ContentView` vuelve a
abrir la hoja.

### `WeekView`

Grilla semanal editable con navegación entre semanas, logging retroactivo (`source: .manual`),
resumen de completados/meta/consistencia y leyenda on-demand desde el botón `?`. Los estados
de celda están agrupados en cuatro familias visuales: hecho, pausa con intención, señal útil
y vacío.

### `InsightsView`

Ventana de 30 días: snapshot global, confianza del ritmo, mejor día y hora punta, hábito más
consistente y hábito que necesita atención, horas pico de impulsos, y experimentos de ritmo de
7 días con aplicar / mantener / revertir.

En DEBUG, al final del scroll hay una card `PerformanceSeedToolsCard` con una sola acción
contextual sobre `PerformanceSeedService`: crear el dataset sintético si no existe, o
borrarlo si ya está. Ambas piden confirmación y reportan en la card cuánto crearon o
borraron. No hay botón de seed en el toolbar.

### `FocusSessionView`

Flujo full-screen con tres fases: `setup` (duración y hábitos), `running` (timer) y `review`
(checklist final). Soporta **secuencia ordenada**: cada hábito es una píldora cuya altura es
proporcional a su tiempo, se toca para ajustar la duración y se arrastra desde una manija para
reordenar. El modelo vive en `FocusSequence`. Al completar la revisión se crean o actualizan
`HabitEntry` con `source: .focusSession`, `completedAt` real y `focusSessionID`.

### `HabitDetailView`

Detalle analítico: experimento activo o pendiente, racha actual y mejor racha, desglose honesto
de la racha (días hechos, descansos intencionales y comodines usados), progreso semanal, dots
de la semana, heatmap de 52 semanas, información de cantidad y edición del hábito.

### `DailyNoticeView`

Se abre desde la campana del header de Hoy. Tiene el mismo flujo de permiso de tres estados que
el recordatorio por hábito (`NotificationPermissionBanner`, compartido), un toggle y la hora.
El selector arranca siempre en 20:00. Si hay datos suficientes (readiness de Insights y al
menos 5 completados confiables en la franja), aparece al lado la franja en que el usuario
suele completar sus hábitos, con un botón para usarla. Si "Notificaciones urgentes" está
apagado en Ajustes, lo dice.

### `WeeklyReviewView`

Revisión de la semana: una decisión por hábito y una reflexión escrita. Persiste con
`WeeklyReviewEditorService`, que evita duplicar la revisión de una semana ya cerrada y pausa
siete días los hábitos marcados. `WeeklyReviewBanner` avisa cuando toca.

## Design system

Reusar tokens y componentes antes de introducir estilos sueltos. El catálogo completo está en
`DESIGN_SYSTEM.md`; la galería viva, en `ComponentsGalleryView`.

- Tokens: `AppColor`, `AppFont`, `AppSpacing`, `AppRadius`, `appElevation`, `AppMotion`,
  `AppHaptics`, `AppBackground`.
- Componentes: `WHCard`, `WHButton`, `WHListRow`, `WHChip`, `WHEmptyState`, `WHProgressRing`,
  `WHProgressBar`, `WHFormSection`, `WHSectionHeader`, `WHConfidenceTag`, `WHDayBadge`,
  `WHCreationSheet`, `WeeklyReviewBanner`, `IconButton`.
- Apariencia de hábito: `HabitAppearance`.
- Fechas y formato: `AppCalendar` y `AppFormatters` (locale `es_MX` centralizado).

Reglas prácticas: envolver pantallas top-level en `AppBackground`; animaciones dentro de
`AppMotion.respectful(_, reduceMotion)`; strings visibles en español; componentes compartidos
en `Views/Components`, locales en `Views/<Feature>View/Components`.

**Copy en estados sensibles.** Miss, slip, break, recuperación y pausa nunca usan lenguaje
punitivo ni estilos destructivos. El rojo destructivo se reserva para acciones que borran
datos de verdad. El registro del usuario es información útil, no una falta.

## Convenciones de persistencia

- Leer con `@Query` desde vistas top-level.
- **Escribir siempre a través de un servicio de dominio**, nunca con `modelContext` desde la
  vista. Incluye asignar propiedades de un `@Model`.
- Una decisión que se toma una sola vez —cierre de plan, prompt de recuperación— guarda de
  inmediato; el autosave no garantiza cuándo.
- Evitar estados principales duplicados por día al registrar cantidades o sesiones.
- Nunca borrar ni convertir `.urge` al cambiar el estado principal del día.
- Conservar las delete rules actuales: hábito cascadea entries y freezes; plan cascadea hitos
  y hace nullify de hábitos; revisión semanal cascadea decisiones.

## Cómo agregar features

### Campo persistido nuevo

1. Agregar la propiedad a la entidad.
2. Crear `SchemaV18` y su `MigrationStage` en `HabitMigrationPlan`.
3. Actualizar inicializadores y llamadores.
4. Si es editable, agregarlo al draft y al editor service correspondiente.
5. Documentarlo aquí.

### Pantalla nueva

1. Crear `Views/<Feature>View/<Feature>View.swift` con su carpeta `Components/`.
2. Envolver en `AppBackground` y usar tokens existentes.
3. Modelar las rutas con enums `Identifiable`; creación y edición van en `fullScreenCover`.
4. Revisar densidad, radios, tipografía y tono de las pantallas vecinas antes de inventar un
   patrón nuevo.

### Métrica o insight nuevo

1. Implementar el cálculo en `Models/Insights/` (`Habit+InsightMetrics` para lo per-hábito,
   `HabitCollection+*` para los agregados).
2. Respetar `isTrustedForInsights`: las marcas `.manual` no son evidencia de ritmo.
3. Si recorre muchos días, construir un `HabitDayIndex` una sola vez.
4. Agregar tests; el ranking de sugerencias decide lo que la app le propone al usuario.

### Mutación nueva

1. Ponerla en el servicio del flujo, no en la vista.
2. Propagar el error en vez de tragarlo con `try?`.
3. Agregar tests con el `ModelContainer` en memoria de `TestSupport.swift`.

### Lógica de fechas, rachas o semanas

Usar `AppCalendar`. Si el cálculo se repite, moverlo a la extensión de dominio que le
corresponde y probarlo ahí.

## Estado de la documentación

Este documento describe el repo con `SchemaV17`, 9 entidades, 13 servicios, navegación de tres
tabs, onboarding de seis pasos, planes con hitos, hábitos de romper con slips y urges,
comodines de racha, recuperación post-fallo, revisión semanal, sesiones de ritmo con secuencia
ordenada y experimentos de 7 días.

El trabajo que sigue abierto vive en los issues del repo. Los planes de refactor ya ejecutados
(`PLAN_SIMPLIFICACION.md`, `REFACTOR_HANDOFF.md`, `docs/PLAN_MEJORAS.md`) se borraron; su
historia vive en git.
