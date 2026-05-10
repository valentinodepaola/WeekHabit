# WeekHabit — Documentación del proyecto

## ¿Qué es WeekHabit?

WeekHabit es una app iOS para construir hábitos con ritmo semanal. La app ayuda al usuario a planear hábitos, registrarlos día a día, revisar su semana, detectar patrones de consistencia y trabajar metas agrupadas en planes.

El enfoque principal no es solo “marcar tareas”, sino ayudar a entender el ritmo real: qué hábitos se sostienen, qué días funcionan mejor, qué horarios tienen más evidencia y cuándo conviene ajustar una meta.

**Stack:** Swift 5.0 · SwiftUI · SwiftData · UserNotifications · iOS 26.4+ · Universal (iPhone + iPad)

**Estado del proyecto:**

- Proyecto Xcode único: `WeekHabit.xcodeproj`
- Sin dependencias externas: no SPM, CocoaPods ni paquetes de terceros
- Sin test target actualmente
- UI y comentarios en español
- Persistencia local con SwiftData y schema versionado hasta `SchemaV7`

## Features actuales

- Onboarding inicial conectado al primer lanzamiento con selección opcional de hábito inicial.
- Crear, editar y borrar hábitos desde `TodayView`.
- Hábitos tipo check: hecho / no hecho.
- Hábitos tipo cantidad: minutos, páginas, kilómetros, vasos, repeticiones o unidad personalizada futura.
- Programación diaria, por días específicos o por veces por semana.
- Fecha opcional de fin para archivar hábitos automáticamente después de cierto día.
- Recordatorios locales por hábito usando `UserNotifications`, programados en sus días activos.
- Asociación de hábitos a planes.
- Crear, editar y borrar planes desde la pantalla de Hoy.
- Planes con motivación, fecha de fin, meta de completitud y hábitos asociados.
- Revisión automática de planes terminados mediante `PlanWrapUpView`.
- Vista Hoy con progreso diario, hábitos activos, planes, edición/borrado y sesión de enfoque.
- Vista Semana con grilla editable, navegación por semanas, resumen y logging retroactivo.
- Insights de 30 días con consistencia, confianza, tendencias, mejores días/horas y sugerencias.
- Experimentos de ritmo de 7 días sugeridos desde Insights, con mantener/revertir.
- Detalle de hábito con racha, desglose honesto de racha, progreso semanal, dots, heatmap y estado de experimento.
- Sesiones de enfoque con timer, selección de hábitos, revisión final y persistencia de `FocusSession`.
- Separación entre marcas confiables para Insights (`today`, `focusSession`) y marcas manuales retroactivas (`manual`).

## Build y ejecución

```bash
# Abrir en Xcode
open WeekHabit.xcodeproj

# Build para simulador
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Verificación rápida sin firma de código
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

No hay target de pruebas ni configuración de lint por ahora.

## Arquitectura

El proyecto usa un patrón **Model-View** natural para SwiftUI + SwiftData.

```text
Vistas SwiftUI
  @Query para leer
  @Environment(\.modelContext) para escribir
        |
        v
Lógica de dominio
  Habit+Domain
  Habit+Insights
  HabitExperiment+Domain
  FocusSession+Domain
  Plan+Domain
        |
        v
Persistencia SwiftData
  Habit
  HabitEntry
  HabitExperiment
  FocusSession
  Plan
  HabitSchema / HabitMigrationPlan
```

No existe capa ViewModel, repositorio ni servicio de datos. Las vistas top-level consultan con `@Query`, originan mutaciones con `modelContext`, y delegan cálculos reutilizables a extensiones de dominio.

`WeekHabitApp.swift` crea el `ModelContainer` usando:

```swift
Schema(versionedSchema: SchemaV7.self)
HabitMigrationPlan.self
```

`RootView` decide si mostrar `OnboardingView` o `ContentView` según `@AppStorage("hasCompletedAppOnboarding")`. También refresca recordatorios al iniciar y cuando la app vuelve a estar activa.

## Modelos de datos

### `Habit`

Entidad principal para un hábito.

Campos importantes:

| Campo | Descripción |
|---|---|
| `title`, `note`, `cue` | Nombre, nota y señal contextual del hábito |
| `iconNameRaw`, `colorHexRaw` | Apariencia persistida |
| `targetDaysPerWeek` | Meta semanal normalizada |
| `activeDaysOfWeekRaw` | Días activos como raw values de `Weekday` |
| `trackingKindRaw` | Tipo de tracking: check o cantidad |
| `measurementUnitRaw` | Unidad para hábitos cuantificables |
| `customUnitName` | Nombre de unidad personalizada, reservado para uso futuro |
| `targetValuePerSession` | Cantidad requerida por sesión para considerar completado |
| `scheduleKindRaw` | Programación: diario, días específicos o veces por semana |
| `endsAt` | Fecha opcional de fin; después de ese día ya no se puede registrar |
| `isReminderEnabled`, `reminderTime` | Configuración de recordatorio local |
| `entries` | Registros de completitud con delete rule `.cascade` |
| `plans` | Planes asociados al hábito |

Propiedades computadas relevantes:

- `activeDaysOfWeek`: versión tipada de `activeDaysOfWeekRaw`.
- `iconName`, `colorHex`, `habitColor`: apariencia con fallback.
- `trackingKind`: `HabitTrackingKind`.
- `measurementUnit`: `HabitMeasurementUnit`.
- `scheduleKind`: `HabitScheduleKind`.

Tipos relacionados:

- `HabitTrackingKind`: `.check`, `.quantity`
- `HabitMeasurementUnit`: `.none`, `.minutes`, `.pages`, `.kilometers`, `.glasses`, `.repetitions`, `.custom`
- `HabitScheduleKind`: `.daily`, `.specificDays`, `.timesPerWeek`

### `HabitEntry`

Registro de avance para un hábito en un día.

| Campo | Descripción |
|---|---|
| `date` | Día normalizado con `AppCalendar.startOfDay` |
| `completedAt` | Timestamp real cuando la marca sucede en tiempo real; `nil` para retroactivas |
| `sourceRaw` | Origen persistido de la marca |
| `kindRaw` | Tipo de entrada: completado, descanso intencional o fallo recuperado |
| `focusSessionID` | ID de la sesión de enfoque que originó la marca, si aplica |
| `completedCount` | Conteo entero histórico/compatibilidad |
| `value` | Valor real para hábitos cuantificables |
| `failureReason` | Razón opcional de fallo post-prompt para entradas `.missed` |
| `habit` | Relación inversa |

Fuentes:

| Fuente | Uso | Confiable para Insights |
|---|---|---|
| `.today` | Registro desde Hoy | Sí |
| `.focusSession` | Registro desde una sesión de enfoque | Sí |
| `.manual` | Registro retroactivo desde Semana | No |

Tipos de entrada:

| Tipo | Uso |
|---|---|
| `.completed` | El hábito se completó o avanzó en un día |
| `.skipped` | Descanso intencional; preserva racha y no cuenta como fallo |
| `.missed` | Fallo reconocido desde el prompt de recuperación; puede tener `failureReason` |

Razones de fallo (`HabitFailureReason`): `.tooDifficult`, `.forgot`, `.badTiming`, `.lowEnergy`, `.other`.

### `Plan`

Agrupa hábitos alrededor de un objetivo temporal.

| Campo | Descripción |
|---|---|
| `title` | Nombre del plan |
| `motivation` | Texto motivacional usado también como cuerpo de recordatorios cuando aplica |
| `startedAt` | Inicio del plan |
| `endsAt` | Fin del plan |
| `targetCompletionRate` | Meta de completitud agregada |
| `reviewedAt` | Fecha en que el usuario cerró/revisó el plan |
| `habits` | Hábitos asociados |

`Plan+Domain` calcula si el plan está activo, terminado, pendiente de revisión, días restantes, progreso agregado y si alcanzó la meta.

### `HabitExperiment`

Persistencia de una prueba de ritmo de 7 días sugerida por Insights.

Guarda el estado original del hábito, el estado experimental, la hora sugerida opcional, consistencia base y estado de resolución.

Estados:

- `.active`
- `.kept`
- `.reverted`
- `.cancelled`

### `FocusSession`

Representa una sesión de enfoque.

Estados:

- `.running`
- `.reviewing`
- `.completed`
- `.cancelled`

Guarda inicio, fin, duración opcional, hábitos seleccionados y hábitos completados durante la revisión.

### `HabitAppearance`

Define la paleta curada de SF Symbols y colores disponibles para hábitos. También conserva fallback para categorías legacy mediante `LegacyHabitArea`.

### `Weekday`

Enum con raw values compatibles con `Calendar`: domingo = 1, lunes = 2, etc.

Usar `Weekday.ordered` para mostrar L-D.

## Schema y migraciones

`HabitSchema.swift` declara:

```text
SchemaV1: Habit, HabitEntry
SchemaV2: + HabitExperiment
SchemaV3: + FocusSession
SchemaV4: cambios aditivos en modelos existentes
SchemaV5: + Plan
SchemaV6: cambios aditivos
SchemaV7: cambios aditivos
SchemaV8: + StreakFreeze
SchemaV9: + HabitEntry.failureReason y EntryKind.missed
```

`HabitMigrationPlan` registra migraciones lightweight de V1 a V9.

Regla importante: no editar schemas antiguos para cambios de forma persistida. Crear el siguiente `SchemaV*`, incluir los modelos vigentes y agregar el `MigrationStage` correspondiente.

## Lógica de dominio

### `Habit+Domain`

Contiene la lógica reusable de hábitos:

- `isFinished(reference:)`
- `isLoggable(on:)`
- `isScheduled(on:)`
- `isActive(on:)`
- `isCompleted(on:)`
- `totalValue(on:)`
- `completedWeekdays(reference:)`
- `completedDaysThisWeek(reference:)`
- `weekProgress(reference:)`
- `currentStreak(reference:)`
- `currentStreakBreakdown(reference:)`
- `displayStreak(reference:)`
- `bestStreak(reference:)`
- `completionMatrix(weeks:reference:)`
- `completedDaysSince(_:reference:)`
- `expectedDaysSince(_:reference:)`
- `completionRatio(since:reference:)`

También expone textos derivados como:

- `targetPerSessionText`
- `scheduleSummaryText`
- `unitDisplayText`
- `isFlexibleSchedule`

### `Habit+Insights`

Calcula métricas de 30 días, confianza, tendencias y sugerencias de ritmo.

Conceptos principales:

- `HabitCompletionStats`
- `GlobalInsightSnapshot`
- `InsightReadiness`
- `RhythmConfidence`
- `HabitInsightSummary`
- `WeekdayPerformance`
- `HourWindow`
- `RhythmExperimentSuggestion`
- `RankedRhythmSuggestion`
- `HabitInsightContext`
- `ContextualHourInsight`
- `ContextualWeekdayInsight`

Los cálculos que intentan representar ritmo real deben usar solo marcas con `entry.source.isTrustedForInsights`.
Las entradas `.missed` alimentan razones de fallo y recomendaciones, pero no cuentan como completitud ni como descanso.

### `HabitExperiment+Domain`

Gestiona el ciclo de vida de pruebas de ritmo:

- detectar activo o pendiente de revisión
- aplicar cambios al hábito
- conservar resultado
- revertir al plan original
- cancelar
- calcular consistencia durante el experimento

### `FocusSession+Domain`

Gestiona timer, progreso, transición a revisión, completado y cancelación de sesiones.

También define:

- `FocusDurationPreset`: 10, 25, 45 minutos y libre
- `FocusTimeFormatter`: formato del timer

### `Plan+Domain`

Calcula estado y progreso de planes:

- `isActive(reference:)`
- `isFinished(reference:)`
- `needsReview(reference:)`
- `daysRemaining(reference:)`
- `progress(reference:)`
- `meetsGoal(reference:)`
- `daysRemainingText`

## Pantallas y flujos

### Lanzamiento y onboarding

`WeekHabitApp` muestra `AppLaunchView`, luego `RootView`.

`RootView`:

- muestra `OnboardingView` si el usuario no terminó onboarding;
- muestra `ContentView` si ya lo terminó;
- refresca recordatorios al iniciar y al volver a foreground.

`OnboardingView` tiene pasos de introducción, insights, permiso de notificaciones y selección de hábito inicial. Si el usuario elige una plantilla, se crea un `Habit` desde `StarterHabitTemplate`.

### Navegación principal

`ContentView` usa un `ZStack` con `selectedTab` y `CustomTabBar`.

Tabs actuales:

| Índice | Vista | Descripción |
|---|---|---|
| 0 | `TodayView` | Hoy, hábitos, planes, creación/edición, sesión de enfoque |
| 1 | `WeekView` | Grilla semanal editable |
| 2 | `InsightsView` | Métricas, tendencias y experimentos |

`ContentView` también presenta `PlanWrapUpView` cuando encuentra un plan terminado con `reviewedAt == nil`.

No existe una pestaña separada `HabitsView` en la versión actual.

### `TodayView`

Pantalla principal de uso diario.

Funciones:

- Header con fecha actual y menú de creación.
- Crear hábito o crear plan.
- Estado vacío para crear un hábito activo hoy.
- `DailyProgressCard` con completados, total y pendientes.
- `FocusSessionLauncherCard`.
- Lista de hábitos loggeables hoy.
- Swipe en hábitos para editar o borrar.
- Logging de hábitos check con toggle.
- Logging de hábitos por cantidad mediante `QuantityLogSheet`.
- Sección de planes con `PlanAccordion`.
- Swipe en planes para editar o eliminar.
- Navegación a `HabitDetailView`.

### `CreateHabitView`

Formulario full-screen para crear o editar hábitos.

Incluye:

- nombre, nota y cue;
- apariencia;
- tipo de tracking;
- unidad y meta por sesión para cantidades;
- programación diaria, por días específicos o veces por semana;
- fecha de fin opcional;
- recordatorio local;
- selección de planes activos.

Al guardar:

- normaliza schedule y fecha de fin;
- cancela experimento activo si se editó manualmente el hábito;
- actualiza asociaciones con planes;
- refresca el recordatorio del hábito.

### `CreatePlanView` y `PlanFlowView`

`PlanFlowView` muestra `PlanOnboardingView` la primera vez que el usuario crea un plan. Después abre directamente `CreatePlanView`.

`CreatePlanView` permite:

- crear o editar plan;
- capturar nombre y motivación;
- elegir fecha de fin;
- definir meta de completitud;
- seleccionar hábitos asociados.

### `PlanWrapUpView`

Se presenta como sheet cuando un plan terminó y todavía no fue revisado.

Muestra:

- título y motivación;
- completitud del plan;
- si alcanzó la meta;
- lista de hábitos para conservar o archivar.

Los hábitos no conservados reciben `endsAt = hoy`. El plan queda marcado con `reviewedAt`.

### `WeekView`

Vista semanal de todos los hábitos visibles en la semana.

Funciones:

- navegación por semanas;
- tira de días L-D;
- grilla por hábito;
- tap en hábito para abrir detalle;
- logging manual retroactivo;
- logging por cantidad con `QuantityLogSheet`;
- resumen de completados, meta total y consistencia.

Las marcas creadas desde Semana usan `source: .manual` y `completedAt: nil`, por diseño no cuentan como evidencia confiable para Insights.

### `InsightsView`

Pantalla de análisis de hábitos.

Incluye:

- consistencia global;
- tendencia contra periodo anterior;
- confianza del ritmo;
- contexto de datos insuficientes cuando aplica;
- revisión de experimentos vencidos;
- sugerencias de experimento de ritmo;
- experimentos activos;
- hábito más consistente;
- hábito que necesita atención;
- mejor día;
- hora punta;
- edición del hábito sugerido.

### `FocusSessionView`

Flujo full-screen iniciado desde Hoy.

Fases:

| Fase | Descripción |
|---|---|
| `setup` | Elegir duración y hábitos |
| `running` | Timer activo y hábitos seleccionados |
| `review` | Checklist final de hábitos completados |

Al completar la revisión se crean o actualizan `HabitEntry` con `source: .focusSession`, `completedAt` real y `focusSessionID`.

### `HabitDetailView`

Detalle analítico de un hábito.

Muestra:

- estado de experimento activo o pendiente;
- racha actual y mejor racha;
- desglose de racha actual por días hechos, descansos intencionales y comodines usados;
- progreso semanal;
- dots de la semana actual;
- heatmap de las últimas 10 semanas;
- información de cantidad cuando el hábito es cuantificable;
- edición del hábito.

## Servicios

### `HabitReminderService`

Servicio para recordatorios locales.

Responsabilidades:

- leer autorización de notificaciones;
- programar recordatorios por hábito y por weekday activo;
- cancelar recordatorios por hábito;
- refrescar todos los recordatorios;
- usar motivación de planes activos como cuerpo del recordatorio cuando exista;
- usar nota del hábito como fallback;
- evitar programar recordatorios para hábitos terminados.

## Design system

Usar estos helpers antes de introducir estilos sueltos:

- `AppBackground`: fondo top-level claro/oscuro.
- `AppColor`: tokens de color.
- `AppFont`: tokens tipográficos.
- `AppRadius`: escala de radios.
- `IconButton`: botón compartido para acciones compactas.
- `HabitAppearance`: paleta de iconos y colores de hábitos.

Reglas prácticas:

- Envolver pantallas top-level con `AppBackground`.
- Usar `AppCalendar` para fechas.
- Evitar `Calendar.current` directo salvo casos donde sea deliberado y revisado.
- Mantener strings visibles en español.
- Mantener identificadores en inglés si siguen el estilo actual.
- Componentes compartidos en `Views/Components`.
- Componentes locales en `Views/<Feature>View/Components`.

## Convenciones de persistencia

- Leer con `@Query`.
- Escribir con `@Environment(\.modelContext)` desde la vista que origina la acción.
- SwiftData persiste automáticamente en los flujos principales; solo llamar `save()` cuando sea necesario.
- Evitar duplicados por día al registrar cantidades o sesiones.
- Si un cálculo se repite, moverlo a una extensión de dominio.
- Si un cambio toca datos persistidos, actualizar schema, migraciones, inicializadores y documentación.

## Cómo agregar features

### Nuevo campo persistido

1. Crear el siguiente `SchemaV*`.
2. Incluir todos los modelos actuales.
3. Agregarlo a `HabitMigrationPlan.schemas`.
4. Agregar `MigrationStage`.
5. Actualizar `init`, callers, previews y docs.
6. No modificar schemas antiguos para representar la nueva forma.

### Nueva pantalla

1. Crear `Views/<NombreView>/<NombreView>.swift`.
2. Crear `Components/` si hay piezas locales.
3. Usar `AppBackground`.
4. Si es tab, actualizar `ContentView` y `CustomTabBar`.
5. Si es modal, seguir el patrón de `fullScreenCover`.
6. Si es push, usar `NavigationStack` / `navigationDestination` desde la vista dueña.

### Nueva métrica o insight

1. Implementar cálculo en `Habit+Insights`.
2. Definir un tipo pequeño si la UI necesita varios valores.
3. Decidir explícitamente si usa marcas confiables o todas las marcas.
4. Crear componente visual en `Views/InsightsView/Components`.
5. Mantener mutaciones de experimentos en la vista dueña.

### Nueva lógica de fechas, rachas o semanas

1. Agregar método en `Habit+Domain`, `Plan+Domain` o helper adecuado.
2. Usar `AppCalendar`.
3. Mantener el método puro cuando sea posible.
4. Evitar duplicar filtros de `entries` dentro de varias vistas.

## Estado de documentación

Esta documentación describe la versión actual del repo con `SchemaV9`, navegación de 3 tabs, onboarding conectado, planes, recordatorios, hábitos cuantificables y recuperación post-fallo.
