# WeekHabit — Documentación del proyecto

## Tabla de contenidos

1. [¿Qué es WeekHabit?](#qué-es-weekhabit)
2. [Build y ejecución](#build-y-ejecución)
3. [Arquitectura](#arquitectura)
4. [Modelos de datos](#modelos-de-datos)
5. [Lógica de dominio](#lógica-de-dominio)
6. [Pantallas y flujos](#pantallas-y-flujos)
7. [Navegación](#navegación)
8. [Design system](#design-system)
9. [Convenciones](#convenciones)
10. [Cómo agregar features](#cómo-agregar-features)

---

## ¿Qué es WeekHabit?

WeekHabit es una app iOS de tracking de hábitos semanales. El usuario crea hábitos, define en qué días quiere realizarlos, marca completados día a día y revisa su ritmo mediante semana, rachas, heatmaps, sesiones de enfoque e insights de consistencia.

**Stack:** Swift 5.0 · SwiftUI · SwiftData · iOS 26.4+ · Universal (iPhone + iPad)

**Características actuales:**
- Crear, editar y eliminar hábitos con icono, color, nota, meta semanal y días activos personalizados
- Marcar/desmarcar hábitos desde Hoy y desde Semana
- Distinguir marcas reales (`today` y `focusSession`) de marcas manuales retroactivas para Insights
- Racha actual, racha visible y mejor racha por hábito
- Vista semanal con grilla editable, navegación por semanas pasadas y resumen de consistencia
- Detalle de hábito con racha, progreso semanal, dots y heatmap de las últimas 10 semanas
- Sesiones de ritmo/enfoque con timer, selección de hábitos, revisión final y persistencia de `FocusSession`
- Insights de 30 días con consistencia global, confianza del ritmo, hora punta, mejor día, hábito más consistente y hábito que necesita atención
- Experimentos de ritmo de 7 días sugeridos por Insights, con opción de conservar o revertir el ajuste
- Onboarding visual inicial preparado, todavía no conectado al flujo principal

---

## Build y ejecución

```bash
# Abrir en Xcode
open WeekHabit.xcodeproj

# Build para simulador (requiere Xcode instalado)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project WeekHabit.xcodeproj \
             -scheme WeekHabit \
             -destination 'platform=iOS Simulator,name=iPhone 16' \
             build

# Verificación rápida de sintaxis (sin firma de código)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project WeekHabit.xcodeproj \
             -scheme WeekHabit \
             -destination 'generic/platform=iOS Simulator' \
             -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

No hay dependencias externas (sin SPM, sin CocoaPods). No existe test target actualmente.

---

## Arquitectura

El proyecto usa **MV (Model-View)**, el patrón nativo de Apple para SwiftUI + SwiftData.

```
┌─────────────────────────────────────────────┐
│                   VISTAS                    │
│  @Query → lee datos   modelContext → escribe│
└───────────────────────┬─────────────────────┘
                        │ llaman métodos de
┌───────────────────────▼─────────────────────┐
│               LÓGICA DE DOMINIO             │
│ Habit+Domain · Habit+Insights ·             │
│ HabitExperiment+Domain · FocusSession+Domain│
└───────────────────────┬─────────────────────┘
                        │ opera sobre
┌───────────────────────▼─────────────────────┐
│              PERSISTENCIA                   │
│ SwiftData @Model: Habit, HabitEntry,        │
│ HabitExperiment, FocusSession               │
│ Schema versionado en HabitSchema.swift      │
└─────────────────────────────────────────────┘
```

**Por qué MV y no MVVM/TCA:**

| Razón | Detalle |
|---|---|
| `@Query` vive en vistas | SwiftData está optimizado para consultar desde `View`; envolver cada query en un ViewModel duplicaría estado |
| Mutaciones locales | La app no tiene red, autenticación ni múltiples fuentes externas que coordinar |
| Dominio separado | El cómputo puro está en extensiones de modelos y secuencias, no mezclado en el layout |
| Tamaño apropiado | La app sigue siendo un proyecto SwiftUI pequeño/mediano; una arquitectura más pesada añadiría archivos sin resolver un problema real |

`WeekHabitApp.swift` crea un `ModelContainer` con `Schema(versionedSchema: SchemaV3.self)` y `HabitMigrationPlan.self`. Toda pantalla top-level lee con `@Query` y escribe con `@Environment(\.modelContext)`.

---

## Modelos de datos

### `Habit` — `WeekHabit/Models/Habit.swift`

Entidad principal. Representa un hábito del usuario.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `title` | `String` | Nombre del hábito |
| `note` | `String?` | Nota opcional |
| `cue` | `String?` | Señal contextual opcional para habit stacking |
| `iconNameRaw` | `String?` | SF Symbol persistido para la apariencia del hábito |
| `colorHexRaw` | `String?` | Color HEX persistido para la apariencia del hábito |
| `targetDaysPerWeek` | `Int` | Meta de días por semana |
| `activeDaysOfWeekRaw` | `[Int]` | Días activos persistidos como raw values de `Weekday`. No usar directamente |
| `createdAt` | `Date` | Fecha de creación |
| `entries` | `[HabitEntry]` | Registros de compleción con delete rule `.cascade` |

**Propiedades computadas:**

| Propiedad | Tipo | Descripción |
|---|---|---|
| `activeDaysOfWeek` | `Set<Weekday>` | Vista tipada de `activeDaysOfWeekRaw`; siempre leer/escribir los días activos aquí |
| `iconName` | `String` | Ícono con fallback al default de `HabitAppearance` |
| `colorHex` | `String` | Color HEX con fallback al default de `HabitAppearance` |
| `habitColor` | `Color` | Color SwiftUI derivado de `colorHex` |

---

### `HabitEntry` — `WeekHabit/Models/HabitEntry.swift`

Un registro de compleción por día. El `date` se normaliza a `startOfDay`, mientras que `completedAt` conserva el timestamp real cuando la marca ocurre en tiempo real.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `date` | `Date` | Día de compleción normalizado a inicio del día |
| `completedAt` | `Date?` | Momento real de compleción; `nil` para marcas manuales/retroactivas |
| `sourceRaw` | `String?` | Raw value persistido del origen de la marca |
| `focusSessionID` | `UUID?` | Sesión de foco que originó la marca, si aplica |
| `completedCount` | `Int` | Siempre 1 por ahora; reservado para hábitos cuantificables |
| `habit` | `Habit?` | Referencia inversa al hábito |

`source` expone `HabitEntrySource` y hace fallback para datos antiguos: si `sourceRaw` no existe, una marca con `completedAt == nil` se interpreta como `.manual`; con `completedAt` se interpreta como `.today`.

| `HabitEntrySource` | Uso | ¿Cuenta como marca confiable para Insights? |
|---|---|---|
| `.today` | Toggle desde `TodayView` | Sí |
| `.focusSession` | Resultado de una `FocusSession` | Sí |
| `.manual` | Marca manual desde `WeekView` o retroactiva | No |

---

### `HabitExperiment` — `WeekHabit/Models/HabitExperiment.swift`

Persistencia de una prueba de ritmo de 7 días sugerida por Insights. Guarda el plan original del hábito, el plan experimental y el estado de resolución.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `habitID` | `UUID` | ID del hábito afectado |
| `habitTitle` | `String` | Título capturado para mostrar aunque el hábito cambie |
| `originalTargetDaysPerWeek` | `Int` | Meta original antes de aplicar la prueba |
| `originalActiveDaysOfWeekRaw` | `[Int]` | Días originales persistidos como raw values |
| `experimentTargetDaysPerWeek` | `Int` | Meta semanal durante la prueba |
| `experimentActiveDaysOfWeekRaw` | `[Int]` | Días activos durante la prueba |
| `suggestedStartHour` | `Int?` | Hora sugerida por Insights, si existe |
| `baselineConsistency` | `Double` | Consistencia antes de iniciar la prueba |
| `startedAt` | `Date` | Inicio normalizado a inicio del día |
| `endsAt` | `Date` | Fin de la prueba, 7 días después |
| `resolvedAt` | `Date?` | Fecha de resolución |
| `statusRaw` | `String` | Raw value de `HabitExperimentStatus` |

`HabitExperimentStatus`: `.active`, `.kept`, `.reverted`, `.cancelled`.

---

### `FocusSession` — `WeekHabit/Models/FocusSession.swift`

Persistencia de una sesión de ritmo/enfoque. Se crea al iniciar una sesión, pasa a revisión al terminar el timer y queda completada o cancelada.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `startedAt` | `Date` | Inicio real de la sesión |
| `endedAt` | `Date?` | Fin real o cancelación |
| `durationSeconds` | `Int?` | Duración fija; `nil` para sesión libre |
| `selectedHabitIDsRaw` | `[String]` | IDs seleccionados persistidos como strings |
| `completedHabitIDsRaw` | `[String]` | IDs completados durante la revisión |
| `statusRaw` | `String` | Raw value de `FocusSessionStatus` |

`FocusSessionStatus`: `.running`, `.reviewing`, `.completed`, `.cancelled`.

---

### `HabitAppearance` — `WeekHabit/Models/HabitAppearance.swift`

Define la paleta curada de íconos SF Symbols y colores HEX disponibles para personalizar hábitos.

---

### `Weekday` — `WeekHabit/Models/WeekDay.swift`

Enum con `rawValue: Int` alineado a `Calendar` (domingo = 1, lunes = 2 … sábado = 7).

```swift
Weekday.ordered  // [.monday, .tuesday, …, .sunday] — orden visual L-D
```

Propiedades: `shortName` ("Lun"), `oneLetterName` ("L"), `displayName` ("Lunes"), `id`.

---

### Schema y migraciones — `WeekHabit/Models/HabitSchema.swift`

```
SchemaV1
├── Habit
└── HabitEntry

SchemaV2
├── Habit
├── HabitEntry
└── HabitExperiment

SchemaV3 (actual)
├── Habit
├── HabitEntry
├── HabitExperiment
└── FocusSession

HabitMigrationPlan
├── lightweight SchemaV1 → SchemaV2
└── lightweight SchemaV2 → SchemaV3
```

**Al cambiar la forma persistida de un modelo:** no editar schemas existentes. Crear `SchemaV4` (o la siguiente versión), agregarlo a `schemas` y añadir un `MigrationStage` en `HabitMigrationPlan`.

---

## Lógica de dominio

La lógica pura vive en extensiones bajo `WeekHabit/Models/`. Las vistas pueden preparar presentación, pero no deben recalcular rachas, consistencia o matrices desde cero.

### `Habit+Domain.swift`

| Método | Retorna | Descripción |
|---|---|---|
| `isActive(on:)` | `Bool` | ¿El hábito está programado para ese día? |
| `isCompleted(on:)` | `Bool` | ¿Existe al menos un `HabitEntry` ese día calendario? |
| `completedWeekdays(reference:)` | `Set<Weekday>` | Días de la semana actual con al menos una compleción |
| `completedDaysThisWeek(reference:)` | `Int` | Días distintos completados en la semana de `reference` |
| `weekProgress(reference:)` | `Double` | Fracción 0…1 de la meta semanal completada |
| `currentStreak(reference:)` | `Int` | Racha hacia atrás; días inactivos no rompen la racha |
| `displayStreak(reference:)` | `Int` | Racha visible ajustada para no castigar hoy antes de completarlo |
| `bestStreak(reference:)` | `Int` | Mejor racha histórica desde la creación |
| `completionMatrix(weeks:reference:)` | `[[CellState]]` | Matriz semanas × 7 días para heatmap |

**Colecciones de hábitos:**

| Método | Retorna | Descripción |
|---|---|---|
| `topStreakHabit(reference:)` | `(habit, streak)?` | Hábito con la racha actual positiva más alta |
| `allShareSameCurrentStreak(reference:)` | `Bool` | `true` si dos o más hábitos comparten la misma racha positiva |

`CellState`: `.completed`, `.missed`, `.inactive`, `.future`.

---

### `Habit+Insights.swift`

Calcula métricas de los últimos 30 días y recomendaciones de ritmo.

| Tipo / método | Propósito |
|---|---|
| `HabitCompletionStats` | Conteo `completed/scheduled`, `ratio` y `percentage` |
| `GlobalInsightSnapshot` | Consistencia actual, periodo anterior, delta y tendencia |
| `RhythmConfidence` | Nivel de confianza según marcas reales vs. totales |
| `HabitInsightSummary` | Resumen de un hábito para tarjetas de Insights |
| `WeekdayPerformance` | Rendimiento por día de la semana |
| `HourWindow` | Ventana horaria para hora punta o sugerida |
| `RhythmExperimentSuggestion` | Propuesta de prueba de 7 días |
| `completionStats(lastDays:reference:)` | Consistencia de un hábito |
| `weekdayPerformance(lastDays:reference:)` | Rendimiento por weekday de un hábito |
| `peakHour(lastDays:reference:)` | Hora más frecuente de marcas confiables |
| `daysSinceLastCompletion(reference:)` | Días desde la última marca confiable |
| `isTrustedCompleted(on:)` | Compleción basada solo en sources confiables |
| `globalInsightSnapshot(reference:)` | Snapshot global de todos los hábitos |
| `topConsistentHabit(reference:)` | Hábito más consistente |
| `rhythmConfidence(reference:)` | Confianza global del ritmo |
| `attentionHabit(reference:)` | Hábito con menor ritmo o racha visible en cero |
| `bestWeekday(reference:)` | Mejor weekday global |
| `peakHour(reference:)` | Hora punta global |
| `rhythmExperimentSuggestion(...)` | Sugerencia de experimento, excluyendo hábitos con experimento activo |

Insights usa `source.isTrustedForInsights`; por eso las marcas manuales de Semana no inflan el ritmo real.

---

### `HabitExperiment+Domain.swift`

| Método / propiedad | Descripción |
|---|---|
| `isActive(reference:)` | Activo y antes de `endsAt` |
| `needsReview(reference:)` | Activo pero ya vencido |
| `isResolved` | Estado distinto de `.active` |
| `suggestedHourText` | Texto de la hora sugerida |
| `daySummary` | Resumen `Xd/sem · días` |
| `daysRemaining(reference:)` | Días restantes de la prueba |
| `apply(to:)` | Aplica meta/días experimentales al hábito |
| `keep(reference:)` | Conserva el experimento y marca `.kept` |
| `revert(on:reference:)` | Restaura meta/días originales y marca `.reverted` |
| `cancel(reference:)` | Cancela el experimento |
| `currentConsistency(for:reference:)` | Consistencia durante la prueba |

También existen helpers de secuencia para encontrar el experimento activo de un hábito y obtener IDs con experimento activo o pendiente de revisión.

---

### `FocusSession+Domain.swift`

| Método / tipo | Descripción |
|---|---|
| `elapsedSeconds(reference:)` | Segundos transcurridos desde inicio |
| `remainingSeconds(reference:)` | Segundos restantes si la sesión tiene duración fija |
| `progress(reference:)` | Progreso 0…1 de sesiones con duración |
| `finishForReview(reference:)` | Cambia de `.running` a `.reviewing` |
| `complete(completedHabitIDs:reference:)` | Guarda resultados y marca `.completed` |
| `cancel(reference:)` | Marca `.cancelled` |
| `FocusDurationPreset` | Presets: 10, 25, 45 minutos y libre |
| `FocusTimeFormatter` | Formato `m:ss` para el timer |

---

## Pantallas y flujos

### Tab 0 — Hoy (`TodayView`)
**Archivo:** `WeekHabit/Views/TodayView/TodayView.swift`

Muestra los hábitos activos para el día actual.

- Header con fecha actual en español
- `DailyProgressCard` con anillo, completados/total y pendientes
- `FocusSessionLauncherCard` para abrir una sesión de ritmo con los hábitos de hoy
- `TodayHabitComponent` por hábito, con estado de experimento activo si existe
- `LongestStreakBanner` con la racha positiva más alta
- Estado vacío con CTA para crear un hábito activo hoy

**Mutaciones:** el toggle crea `HabitEntry(date: referenceDate, completedAt: .now, source: .today, habit: habit)` o elimina las entradas del día.

---

### Modal — Sesión de ritmo (`FocusSessionView`)
**Archivo:** `WeekHabit/Views/FocusSessionView/FocusSessionView.swift`

Flujo full-screen presentado desde Hoy. Tiene tres fases internas:

| Fase | Descripción |
|---|---|
| `setup` | Selección de duración y hábitos. Por defecto preselecciona hábitos de hoy incompletos |
| `running` | Timer activo, progreso opcional y lista de hábitos seleccionados |
| `review` | Checklist final para marcar qué hábitos se completaron durante la sesión |

Al iniciar se inserta un `FocusSession`. Al terminar pasa a `.reviewing`. Al guardar, crea o actualiza `HabitEntry` con `source: .focusSession`, `completedAt` y `focusSessionID`, elimina duplicados del mismo día y marca la sesión como `.completed`.

Componentes principales:

| Componente | Propósito |
|---|---|
| `FocusDurationPicker` | Presets 10/25/45/libre |
| `FocusHabitPicker` | Selección de hábitos |
| `FocusTimerCard` | Timer, progreso y botón terminar |
| `FocusSelectedHabitsCard` | Lista durante la sesión |
| `FocusReviewChecklist` | Checklist de resultados |

---

### Tab 1 — Hábitos (`HabitsView`)
**Archivo:** `WeekHabit/Views/HabitsView/HabitsView.swift`

Lista completa de hábitos con navegación y CRUD.

- Header con botón `+` para abrir `CreateHabitView`
- `HabitCard` por hábito, con apariencia personalizada, meta, racha actual y dots de la semana
- Tap en card → `HabitDetailView`
- Swipe trailing → borrar con confirmación o editar en full-screen
- Estado vacío → `EmptyStateView` con CTA de creación

---

### Tab 2 — Semana (`WeekView`)
**Archivo:** `WeekHabit/Views/WeekView/WeekView.swift`

Vista semanal implementada como grilla editable.

- `WeekHeaderSection` muestra mes/año, número de semana y navegación a semanas anteriores
- La flecha derecha queda deshabilitada en la semana actual; botón "Hoy" vuelve al offset 0
- `DayColumn` muestra la tira L-D de la semana
- `WeekGridRow` muestra cada hábito con progreso semanal, completados/meta y celdas por día
- `WeekGridCell` permite marcar/desmarcar días activos no futuros
- Tap en el nombre del hábito → `HabitDetailView`
- Resumen inferior: completados, meta total y consistencia
- Estado vacío → `WeekEmptyStateCard`

**Mutaciones:** el toggle desde Semana usa `source: .manual` y `completedAt: nil`; por diseño no cuenta como marca confiable para Insights.

---

### Tab 3 — Insights (`InsightsView`)
**Archivo:** `WeekHabit/Views/InsightsView/InsightsView.swift`

Pantalla de análisis de los últimos 30 días.

- `InsightsHeroCard` — consistencia global, delta contra los 30 días anteriores y tendencia en barras
- `InsightConfidenceCard` — confianza del ritmo según marcas confiables vs. totales
- `ExperimentReviewCard` — aparece cuando una prueba activa ya terminó
- `RhythmExperimentCard` — propone una prueba de 7 días cuando hay datos suficientes
- `ActiveExperimentCard` — lista pruebas activas y días restantes
- `InsightSummaryCard` — hábito más consistente, hábito que necesita atención, mejor día y hora punta
- CTA "Editar" en el hábito que necesita atención → `CreateHabitView`
- Estado vacío si no hay hábitos

**Mutaciones:** iniciar una prueba crea un `HabitExperiment`, aplica inmediatamente la meta/días sugeridos al hábito y excluye ese hábito de nuevas sugerencias. Al revisar, `keep` conserva los cambios y `revert` restaura el plan original.

---

### Modal — Crear / Editar Hábito (`CreateHabitView`)
**Archivo:** `WeekHabit/Views/CreateHabitView/CreateHabitView.swift`

Formulario full-screen para crear un hábito nuevo o editar uno existente.

- Recibe `habitToEdit: Habit?`; si no es `nil`, opera en modo edición
- También puede recibir `initialDaysPerWeek` e `initialActiveDays` para flujos como "crear hábito para hoy"
- El `init` pre-rellena los `@State` locales
- `isSaveDisabled` bloquea guardar si falta nombre, meta o si días seleccionados no coincide con meta
- Incluye campo opcional `Después de...` para guardar el cue visible en Today y Detalle
- `onChange(of: daysPerWeek)` llama a `trimSelectedDays(to:)`
- Al editar un hábito con experimento activo, el experimento se cancela antes de guardar cambios manuales

Componentes:

| Componente | Propósito |
|---|---|
| `TextFieldComponent` | Campo single-line o multiline |
| `HabitAppearancePicker` | Selección curada de ícono y color |
| `WeekGoalComponent` | Stepper visual +/- para días por semana |
| `ActiveDaysComponent` | Grilla de 7 botones para días activos |
| `IconComponent` | Ícono SF Symbol con color del hábito |

---

### Push — Detalle de Hábito (`HabitDetailView`)
**Archivo:** `WeekHabit/Views/HabitDetailView/HabitDetailView.swift`

Panel de analytics de un hábito individual.

| Componente | Dato que muestra |
|---|---|
| `HabitExperimentStatusCard` | Estado de una prueba activa o lista para revisar |
| `CurrentStreakHeroCard` | Racha actual, mejor racha y mensaje motivacional |
| `StatTileView` | Progreso semanal y mejor racha |
| `WeekDotsCard` | Estado de los 7 días de la semana actual |
| `LastWeeksHeatmapCard` | Heatmap 10 semanas × 7 días |

El top bar oculta la navegación nativa y usa `IconButton` para volver y editar.

---

### Onboarding (`OnboardingView`)
**Archivo:** `WeekHabit/Views/OnboardingView/OnboardingView.swift`

Pantalla visual de bienvenida con `RippleLogoView`, copy inicial y botones de entrada. Actualmente existe como vista aislada/preview y no está conectada desde `ContentView`.

---

## Navegación

```
ContentView (ZStack + selectedTab)
├── [0] TodayView
│       ├── CreateHabitView (fullScreenCover — crear con día actual)
│       └── FocusSessionView (fullScreenCover)
├── [1] HabitsView (NavigationStack)
│       ├── HabitDetailView (navigationDestination)
│       │       └── CreateHabitView (fullScreenCover — editar)
│       ├── CreateHabitView (fullScreenCover — crear)
│       ├── CreateHabitView (fullScreenCover — editar)
│       └── Alert de borrado
├── [2] WeekView (NavigationStack)
│       └── HabitDetailView (navigationDestination)
└── [3] InsightsView (NavigationStack)
        └── CreateHabitView (fullScreenCover — editar hábito sugerido)
```

**Patrón de tab bar:** `ZStack` manual con `switch selectedTab`, en lugar de `TabView` nativo, para usar `CustomTabBar` con diseño propio.

**Regla:** el orden del `switch` en `ContentView` debe mantenerse sincronizado con `tabs` en `CustomTabBar`.

---

## Design system

### Colores — `AppColor`
**Archivo:** `WeekHabit/Extensions/AppColor.swift`

| Token | Uso |
|---|---|
| `accent` | Naranja tierra — acción principal, rachas, CTAs |
| `accentSoft` | Versión suave/adaptativa del acento |
| `strongText` | Texto de máximo contraste |
| `mutedText` | Texto secundario |
| `subtleText` | Texto terciario, metadatos, placeholders |
| `surface` | Fondo de cards |
| `surfaceMuted` | Superficie secundaria |
| `bgLight` | Fondo principal claro |
| `bgDark` | Fondo principal oscuro |
| `lowPurple` | Fondo suave para estados/insights |
| `highPurple` | Violeta para estados/insights |
| `editAction` | Azul — acción editar |
| `destructiveAction` | Rojo — acción destructiva |

La paleta curada de apariencia de hábitos vive en `HabitAppearance`.

---

### Tipografía — `AppFont`
**Archivo:** `WeekHabit/Extensions/AppFont.swift`

| Token | Tamaño | Peso | Diseño | Uso |
|---|---|---|---|---|
| `title1` | 38 | Regular | Serif | Títulos de máxima jerarquía |
| `title` | 34 | Regular | Serif | Encabezados de pantalla |
| `subtitle` | 28 | Regular | Serif | Cards hero y valores destacados |
| `subtitle2` | 20 | Bold | Sans | Encabezados de sección |
| `subtitle3` | 20 | Semibold | Serif | Encabezados cálidos de cards |
| `body` | 17 | Regular | Sans | Cuerpo principal |
| `body2` | 16 | Regular | Sans | Títulos de hábito y texto frecuente |
| `captionApp` | 14 | Regular | Sans | Fechas, labels secundarios |
| `formSectionText` | 13 | Bold | Sans | Encabezados de formulario/sección |
| `formSectionText2` | 12 | Regular | Sans | Metadatos en tarjetas |
| `tabBarText` | 10.5 | Regular | Sans | Labels de tab bar |
| `dayLabel` | 16 | Semibold | Sans | Labels de días |

---

### Radios de esquina — `AppRadius`
**Archivo:** `WeekHabit/Extensions/AppRadius.swift`

| Token | Valor | Uso |
|---|---|---|
| `small` | 10 pt | Chips, celdas y toggles compactos |
| `medium` | 12 pt | Cards, badges, campos de texto |
| `large` | 14 pt | CTAs y cards destacadas |
| `pill` | 15 pt | Contenedores tipo pill |

Algunos componentes usan radios locales mayores cuando el diseño lo requiere (`DailyProgressCard`, `InsightsHeroCard`, `FocusTimerCard`).

---

### Fondo — `AppBackground`
**Archivo:** `WeekHabit/Extensions/AppBackground.swift`

Wrapper que aplica el fondo correcto en claro/oscuro. Cada pantalla top-level debe envolver su contenido así:

```swift
AppBackground {
    // contenido de pantalla
}
```

---

### Calendario — `AppCalendar`
**Archivo:** `WeekHabit/Extensions/AppCalendar.swift`

Fuente única de verdad para matemática de fechas. Siempre usar esta API en vez de `Calendar.current` directo.

| Método | Descripción |
|---|---|
| `current` | Calendario gregoriano, timezone actual, primer día lunes |
| `startOfDay(for:)` | Inicio del día para una fecha |
| `weekday(of:)` | `Weekday` para una fecha |
| `weekRange(containing:)` | Rango `[inicio, fin)` de la semana |
| `isSameDay(_:_:)` | Mismo día calendario |

---

## Convenciones

### Idioma

- **Strings de UI y comentarios de código:** en español
- **Nombres de tipos e identificadores:** en inglés, siguiendo el código existente (`WeekGoalComponent`, `targetDaysPerWeek`)

### Estructura de carpetas

```
Views/
├── <Feature>View/
│   ├── <Feature>View.swift       ← pantalla principal
│   └── Components/
│       └── <ComponentName>.swift ← componentes locales a esa feature
└── Components/                   ← componentes cross-feature
```

Seguir este patrón al agregar nuevas pantallas.

### Design system

- Colores → usar `AppColor.*`; agregar tokens nuevos en `AppColor`
- Apariencia de hábitos → colores e íconos disponibles viven en `HabitAppearance`
- Fuentes → usar `AppFont.*` para texto de UI
- Radios → usar `AppRadius.*` si el radio es compartido
- Fondo → usar `AppBackground { }` en vistas top-level
- Botones compartidos → usar `IconButton` cuando sea botón circular/pill de la marca

### Persistencia

- Leer → `@Query` en vistas
- Escribir → `@Environment(\.modelContext)` en la vista que origina la acción
- No hay repositorios ni servicios de datos
- `modelContext.save()` no se llama en los flujos actuales; SwiftData persiste automáticamente
- Evitar duplicados por día cuando se marque desde sesiones; `FocusSessionView.markCompleted` ya consolida entradas del mismo día

### Lógica de dominio

- Funciones puras de hábitos/insights → `Habit+Domain.swift` o `Habit+Insights.swift`
- Funciones de experimentos → `HabitExperiment+Domain.swift`
- Funciones de sesiones → `FocusSession+Domain.swift`
- Usar `AppCalendar` para fechas
- No duplicar filtros de `entries`, rachas, ratios o confianza dentro de views

### Fuentes de marcas

- Desde Hoy: `source: .today`, `completedAt: .now`, confiable para Insights
- Desde Focus Session: `source: .focusSession`, `completedAt` real, `focusSessionID`, confiable para Insights
- Desde Semana: `source: .manual`, `completedAt: nil`, útil para historial pero no confiable para Insights

---

## Cómo agregar features

### Nuevo campo persistido

1. Crear el siguiente `SchemaV*` en `HabitSchema.swift`
2. Incluir todos los modelos actuales más el cambio nuevo
3. Agregar el nuevo schema a `HabitMigrationPlan.schemas`
4. Añadir un `MigrationStage` adecuado en `HabitMigrationPlan.stages`
5. Actualizar inicializadores, previews y callers
6. No editar `SchemaV1`, `SchemaV2` ni `SchemaV3` en lugar de versionar

Si el cambio es aditivo, opcional o con default, probablemente basta una migración lightweight; si se renombran o transforman datos, usar migración custom.

---

### Nueva pantalla

1. Crear `Views/<NombreView>/<NombreView>.swift`
2. Crear `Views/<NombreView>/Components/` para componentes locales
3. Envolver con `AppBackground`
4. Si es tab: actualizar `ContentView` y `CustomTabBar.tabs`
5. Si es push: usar `NavigationStack`/`navigationDestination` desde la vista dueña
6. Si es modal: usar `fullScreenCover`, siguiendo `CreateHabitView` y `FocusSessionView`

---

### Nueva opción de apariencia de hábito

1. Agregar el SF Symbol a `HabitAppearance.iconNames` o el HEX a `HabitAppearance.colorHexes`
2. Revisar `HabitAppearancePicker` y previews si la opción requiere tratamiento visual especial

---

### Nueva métrica o insight

1. Agregar el cálculo a `Habit+Insights.swift`
2. Usar solo marcas confiables si representa ritmo real (`entry.source.isTrustedForInsights`)
3. Exponer un tipo pequeño si la vista necesita varios valores
4. Crear el componente visual en `Views/InsightsView/Components/`
5. Mantener la mutación de experimentos en `InsightsView`, no dentro del componente

---

### Nueva lógica de racha, semana o calendario

1. Agregar método en `Habit+Domain.swift` o una extensión de colección
2. Mantener la función pura y sin efectos secundarios
3. Usar `AppCalendar`
4. Si alimenta UI repetida, devolver datos ya listos para presentar en vez de duplicar transformación en varias views

---

### Sincronización CloudKit (futuro)

SwiftData soporta sync con CloudKit nativamente. El cambio principal sería configurar `ModelConfiguration`:

```swift
// En WeekHabitApp.swift
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
```

Antes de activar sync, revisar compatibilidad de relaciones, migraciones y estrategia de conflictos.

---

*Actualizado el 1 de mayo de 2026.*
