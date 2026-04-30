# WeekHabit — Documentación del proyecto

## Tabla de contenidos

1. [¿Qué es WeekHabit?](#qué-es-weekhabit)
2. [Build y ejecución](#build-y-ejecución)
3. [Arquitectura](#arquitectura)
4. [Modelos de datos](#modelos-de-datos)
5. [Lógica de dominio](#lógica-de-dominio)
6. [Pantallas](#pantallas)
7. [Navegación](#navegación)
8. [Design system](#design-system)
9. [Convenciones](#convenciones)
10. [Cómo agregar features](#cómo-agregar-features)

---

## ¿Qué es WeekHabit?

WeekHabit es una app iOS de tracking de hábitos semanales. El usuario crea hábitos, define en qué días de la semana quiere realizarlos y cuántos días por semana es su meta, y marca cada día si lo completó o no. La app calcula rachas, progreso semanal y visualiza la historia de compleción en un heatmap.

**Stack:** Swift 5.0 · SwiftUI · SwiftData · iOS 26.4+ · Universal (iPhone + iPad)

**Características actuales:**
- Crear, editar y eliminar hábitos con categoría, nota y días activos personalizados
- Marcar / desmarcar compleción diaria con toggle
- Racha actual y racha récord por hábito
- Heatmap de las últimas 10 semanas
- Banner de racha más alta en la pantalla de hoy

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
│         Habit+Domain.swift (extensiones)    │
│  isCompleted · currentStreak · bestStreak   │
│  completedWeekdays · completionMatrix · … │
└───────────────────────┬─────────────────────┘
                        │ opera sobre
┌───────────────────────▼─────────────────────┐
│              PERSISTENCIA                   │
│    SwiftData @Model: Habit, HabitEntry      │
│    Schema versionado en HabitSchema.swift   │
└─────────────────────────────────────────────┘
```

**Por qué MV y no MVVM/TCA:**

| Razón | Detalle |
|---|---|
| `@Query` no vive en ViewModels | SwiftData requiere que `@Query` esté dentro de una `View`; envolverlo en un ViewModel duplica trabajo sin beneficio |
| Sin async ni múltiples fuentes | No hay red, ni cache, ni autenticación; no hay nada que orquestar |
| Lógica separada en extensiones | `Habit+Domain.swift` encapsula todo el cómputo puro, testeable sin mocks |
| Tamaño apropiado | 4 pantallas activas, 1 desarrollador; TCA/Clean Architecture añadirían 3–5× más archivos sin valor |

---

## Modelos de datos

### `Habit` — `WeekHabit/Models/Habit.swift`

Entidad principal. Representa un hábito del usuario.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `title` | `String` | Nombre del hábito |
| `note` | `String?` | Nota opcional |
| `category` | `HabitCategory?` | Categoría (opcional por compatibilidad de schema) |
| `targetDaysPerWeek` | `Int` | Meta de días por semana |
| `activeDaysOfWeekRaw` | `[Int]` | Días activos persistidos como rawValues de `Weekday`. **No usar directamente** |
| `createdAt` | `Date` | Fecha de creación |
| `entries` | `[HabitEntry]` | Registros de compleción (cascade delete) |

**Propiedades computadas:**

| Propiedad | Tipo | Descripción |
|---|---|---|
| `activeDaysOfWeek` | `Set<Weekday>` | Vista tipada de `activeDaysOfWeekRaw`. Siempre leer/escribir los días activos aquí |
| `displayCategory` | `HabitCategory` | Categoría con fallback a `.health` si es `nil` |

---

### `HabitEntry` — `WeekHabit/Models/HabitEntry.swift`

Un registro de compleción por día. Se crea al marcar un hábito y se elimina al desmarcarlo.

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `UUID` | Identificador único |
| `date` | `Date` | Día de compleción, normalizado a `startOfDay` en el `init` |
| `completedCount` | `Int` | Siempre 1 por ahora; reservado para hábitos cuantificables |
| `habit` | `Habit?` | Referencia inversa al hábito |

> **Importante:** La normalización de `date` a `startOfDay` garantiza que las consultas por rango funcionen correctamente en cualquier zona horaria.

---

### `HabitCategory` — `WeekHabit/Models/HabitCategory.swift`

Enum `Codable` que clasifica los hábitos. El `rawValue` (`String`) se persiste en SwiftData.

| Caso | Display | Ícono | Color |
|---|---|---|---|
| `.health` | Salud | `heart.fill` | Verde oliva |
| `.work` | Trabajo | `briefcase.fill` | Violeta |
| `.personal` | Mente | `person.fill` | Ámbar |
| `.learning` | Lectura | `book.fill` | Azul acero |

---

### `Weekday` — `WeekHabit/Models/WeekDay.swift`

Enum con `rawValue: Int` alineado a `Calendar` (domingo = 1, lunes = 2 … sábado = 7).

```swift
Weekday.ordered  // [.monday, .tuesday, …, .sunday] — orden visual L–D
```

Propiedades: `shortName` ("Lun"), `oneLetterName` ("L"), `displayName` ("Lunes"), `id`.

---

### Schema y migraciones — `WeekHabit/Models/HabitSchema.swift`

```
SchemaV1 (actual)
├── Habit
└── HabitEntry

HabitMigrationPlan
└── stages: []  ← sin migraciones todavía
```

**Al cambiar la forma de un modelo:** no editar `SchemaV1`. Crear `SchemaV2` y añadir un `MigrationStage` en `HabitMigrationPlan`. Ver cabecera del archivo para instrucciones paso a paso.

---

## Lógica de dominio

Todo el cómputo puro vive en `WeekHabit/Models/Habit+Domain.swift` como extensiones del modelo. Las vistas solo llaman estos métodos; no duplican la lógica.

### Métodos sobre `Habit`

| Método | Retorna | Descripción |
|---|---|---|
| `isActive(on:)` | `Bool` | ¿El hábito está programado para ese día de la semana? |
| `isCompleted(on:)` | `Bool` | ¿Existe al menos un `HabitEntry` ese día calendario? |
| `completedWeekdays(reference:)` | `Set<Weekday>` | Días de la semana actual con al menos una compleción |
| `completedDaysThisWeek(reference:)` | `Int` | Días distintos completados en la semana de `reference` |
| `weekProgress(reference:)` | `Double` (0…1) | Fracción de la meta semanal completada |
| `currentStreak(reference:)` | `Int` | Racha actual hacia atrás; días inactivos no la rompen |
| `displayStreak(reference:)` | `Int` | Racha ajustada: si hoy es activo y no completado, muestra la racha de ayer |
| `bestStreak(reference:)` | `Int` | Mejor racha histórica desde la creación del hábito |
| `completionMatrix(weeks:reference:)` | `[[CellState]]` | Matriz semanas × 7 días con estado de cada celda para el heatmap |

### Métodos sobre colecciones `[Habit]`

| Método | Retorna | Descripción |
|---|---|---|
| `topStreakHabit(reference:)` | `(habit, streak)?` | Hábito con la racha actual más alta de la colección |
| `allShareSameCurrentStreak(reference:)` | `Bool` | `true` si ≥2 hábitos comparten la misma racha positiva |

### `CellState` — estado de celda del heatmap

```swift
enum CellState {
    case completed  // Activo y completado
    case missed     // Activo y no completado
    case inactive   // No programado ese día
    case future     // Día no llegado aún, o anterior a la creación
}
```

### `Array<CellState>`

| Método | Retorna | Descripción |
|---|---|---|
| `completionRatio(target:)` | `Double` (0…1) | Fracción de celdas completadas vs. meta semanal |

---

## Pantallas

### Tab 0 — Hoy (`TodayView`)
**Archivo:** `WeekHabit/Views/TodayView/TodayView.swift`

Muestra los hábitos activos para el día de hoy y el progreso diario.

- `DailyProgressCard` — anillo de progreso + conteo completados/total
- `TodayHabitComponent` — ítem con toggle de compleción
- `LongestStreakBanner` — banner con la racha más alta de todos los hábitos

**Mutaciones:** crea / elimina `HabitEntry` en `modelContext` al hacer toggle.

---

### Tab 1 — Hábitos (`HabitsView`)
**Archivo:** `WeekHabit/Views/HabitsView/HabitsView.swift`

Lista completa de hábitos con CRUD.

- Swipe izquierdo → borrar (con alert de confirmación) / editar
- Tap en card → navega a `HabitDetailView`
- Botón `+` → abre `CreateHabitView` para crear
- Estado vacío → `EmptyStateView` con CTA de creación

---

### Tab 2 — Semana (`WeekView`)
**Archivo:** `WeekHabit/Views/WeekView.swift`

Pantalla stub. Sin implementar.

---

### Tab 3 — Insights (`InsightsView`)
**Archivo:** `WeekHabit/Views/InsightsView.swift`

Pantalla stub. Sin implementar.

---

### Modal — Crear / Editar Hábito (`CreateHabitView`)
**Archivo:** `WeekHabit/Views/CreateHabitView/CreateHabitView.swift`

Formulario con validación para crear un hábito nuevo o editar uno existente.

- Recibe `habitToEdit: Habit?` — si no es `nil`, opera en modo edición
- El `init` pre-rellena los `@State` locales con los valores del hábito a editar
- `isSaveDisabled` bloquea Guardar hasta que nombre, meta y días estén completos y consistentes
- `onChange(of: daysPerWeek)` llama a `trimSelectedDays(to:)` para sincronizar la selección de días con la meta

**Componentes del formulario:**

| Componente | Propósito |
|---|---|
| `TextFieldComponent` | Campo de texto single o multiline con label |
| `ButtonCategoryComponent` | Grilla de selección de categoría |
| `WeekGoalComponent` | Spinner +/– para días por semana |
| `ActiveDaysComponent` | Grilla de 7 botones para seleccionar días activos |

---

### Push — Detalle de Hábito (`HabitDetailView`)
**Archivo:** `WeekHabit/Views/HabitDetailView/HabitDetailView.swift`

Panel de analytics de un hábito individual.

| Componente | Dato que muestra |
|---|---|
| `CurrentStreakHeroCard` | Racha actual + racha récord con mensaje motivacional |
| `StatTileView` (×2) | "Esta semana" (completados/meta) y "Mejor racha" |
| `WeekDotsCard` | Estado de los 7 días de la semana actual (dots) |
| `LastWeeksHeatmapCard` | Heatmap 10 semanas × 7 días con intensidad por compleción |

---

### Onboarding (`OnboardingView`)
**Archivo:** `WeekHabit/Views/OnboardingView/OnboardingView.swift`

Pantalla stub de bienvenida con `RippleLogoView` animado. Sin implementar.

---

## Navegación

```
ContentView (ZStack + selectedTab)
├── [0] TodayView
├── [1] HabitsView (NavigationStack)
│       ├── → HabitDetailView (navigationDestination)
│       │       └── CreateHabitView (fullScreenCover — editar)
│       ├── CreateHabitView (fullScreenCover — crear)
│       └── Alert de borrado
├── [2] WeekView (stub)
└── [3] InsightsView (stub)
```

**Patrón de tab bar:** `ZStack` manual con `switch selectedTab`, en lugar de `TabView` nativo, para poder usar `CustomTabBar` con diseño propio.

**Regla:** el orden del `switch` en `ContentView` debe mantenerse sincronizado con el array `tabs` de `CustomTabBar`.

---

## Design system

### Colores — `AppColor`
**Archivo:** `WeekHabit/Extensions/AppColor.swift`

| Token | Uso |
|---|---|
| `accent` | Naranja tierra — acción principal, rachas, CTAs |
| `accentSoft` | Versión suave del acento, fondos decorativos |
| `strongText` | Texto de máximo contraste (títulos, valores) |
| `mutedText` | Texto secundario (labels, subtítulos) |
| `subtleText` | Texto terciario (metadatos, placeholders) |
| `surface` | Blanco — fondo de cards |
| `surfaceMuted` | Crema suave — secciones secundarias |
| `bgLight` | Fondo principal en modo claro |
| `bgDark` | Fondo principal en modo oscuro |
| `editAction` | Azul — botón editar en swipe actions |
| `destructiveAction` | Rojo — botón borrar en swipe actions |

Los colores de categoría (verde, violeta, ámbar, azul) viven en `HabitCategory.color`, no aquí.

---

### Tipografía — `AppFont`
**Archivo:** `WeekHabit/Extensions/AppFont.swift`

| Token | Tamaño | Peso | Diseño | Uso |
|---|---|---|---|---|
| `title1` | 38 | Regular | Serif | Títulos de máxima jerarquía |
| `title` | 34 | Regular | Serif | Encabezados de pantalla |
| `subtitle` | 28 | Regular | Serif | Cards hero y secciones destacadas |
| `subtitle2` | 20 | Bold | Sans | Encabezados de sección con fuerte contraste |
| `subtitle3` | 20 | Semibold | Serif | Variante cálida de subtitle2 |
| `body` | 17 | Regular | Sans | Cuerpo principal |
| `body2` | 16 | Regular | Sans | Títulos de hábito en listas |
| `captionApp` | 14 | Regular | Sans | Fechas, labels secundarios |
| `formSectionText` | 13 | Bold | Sans | Encabezados de sección de formulario |
| `formSectionText2` | 12 | Regular | Sans | Metadatos en tarjetas |
| `tabBarText` | 10.5 | Regular | Sans | Labels de tab bar |
| `dayLabel` | 16 | Semibold | Sans | Labels de días en selectores |

---

### Radios de esquina — `AppRadius`
**Archivo:** `WeekHabit/Extensions/AppRadius.swift`

| Token | Valor | Uso |
|---|---|---|
| `small` | 10 pt | Chips de día, toggles compactos |
| `medium` | 12 pt | Cards, badges, campos de texto |
| `large` | 14 pt | Botones CTA principales |
| `pill` | 15 pt | Contenedores pill, controles redondeados |

---

### Fondo — `AppBackground`
**Archivo:** `WeekHabit/Extensions/AppBackground.swift`

Wrapper `ViewBuilder` que aplica el color de fondo correcto en claro/oscuro. Envuelve cada pantalla top-level:

```swift
AppBackground {
    // contenido de la pantalla
}
```

---

### Calendario — `AppCalendar`
**Archivo:** `WeekHabit/Extensions/AppCalendar.swift`

Fuente única de verdad para toda la matemática de fechas. Siempre usar esta en lugar de `Calendar.current` directamente.

| Método | Descripción |
|---|---|
| `current` | Calendario gregoriano con timezone actual y primer día lunes |
| `startOfDay(for:)` | Inicio del día (00:00:00) para la fecha dada |
| `weekday(of:)` | `Weekday` para la fecha dada |
| `weekRange(containing:)` | Rango `[inicio, fin)` de la semana que contiene la fecha |
| `isSameDay(_:_:)` | `true` si las dos fechas son el mismo día calendario |

---

## Convenciones

### Idioma
- **Strings de UI y comentarios de código:** en español
- **Nombres de tipos e identificadores:** en inglés (el codebase ya los mezcla, p. ej. `WeekGoalComponent`, `targetDaysPerWeek`)

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
- Colores → siempre `AppColor.*`, nunca `Color(hex:)` inline
- Fuentes → siempre `AppFont.*`, nunca `Font.system(...)` inline en views
- Radios → siempre `AppRadius.*` para valores compartidos
- Fondo → siempre `AppBackground { }` en vistas top-level

### Persistencia
- Leer → `@Query` en vistas
- Escribir → `@Environment(\.modelContext)` en la vista que origina la acción
- No hay repositorios ni servicios de datos; las mutaciones son directas e inline
- `modelContext.save()` no es necesario; SwiftData persiste automáticamente

### Lógica de dominio
- Toda función pura sobre `Habit` o colecciones de `Habit` va en `Habit+Domain.swift`
- Las vistas pueden tener computed properties de **presentación** (formatear strings, calcular colores)
- Las vistas **no** deben filtrar `entries`, calcular rachas ni computar ratios desde cero

---

## Cómo agregar features

### Nuevo campo en `Habit`

Si el campo es un tipo nuevo o renombrado (cambio de schema):

1. Declarar `SchemaV2` en `HabitSchema.swift` con los modelos actualizados
2. Añadir un `MigrationStage` en `HabitMigrationPlan.stages`
3. Actualizar `Habit.init` y todos sus callers
4. Nunca editar `SchemaV1`

Si el campo es aditivo (opcional con valor por defecto), SwiftData puede manejarlo sin migración explícita — pero igual se recomienda SchemaV2 para tener trazabilidad.

---

### Nueva pantalla

1. Crear carpeta `Views/<NombreView>/`
2. Crear `<NombreView>.swift` con la pantalla principal
3. Crear subcarpeta `Components/` para componentes locales
4. Si es una pestaña nueva: añadir caso al `switch` en `ContentView` y al array `tabs` en `CustomTabBar`
5. Si es un push o modal: usar `navigationDestination` o `fullScreenCover` desde la vista que la presenta

---

### Nueva categoría de hábito

1. Agregar caso al enum `HabitCategory` en `HabitCategory.swift`
2. Implementar `title`, `displayTitle`, `icon` y `color` para el nuevo caso
3. Actualizar `allCases` si es necesario (el compilador marcará los `switch` incompletos)

---

### Nueva lógica de dominio

1. Agregar método como extensión de `Habit` o `Array<Habit>` en `Habit+Domain.swift`
2. Mantener los métodos como funciones puras (sin efectos secundarios)
3. Usar `AppCalendar` para cualquier matemática de fechas; nunca `Calendar.current` directamente

---

### Sincronización CloudKit (futuro)

SwiftData soporta sync con CloudKit nativamente. Solo requiere cambiar `ModelConfiguration`:

```swift
// En WeekHabitApp.swift
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
```

No requiere cambios arquitectónicos.

---

*Generado el 30 de abril de 2026.*
