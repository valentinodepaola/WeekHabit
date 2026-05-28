# WeekHabit · Design System

Referencia viva del sistema visual y de interacción de WeekHabit. Pensado para que cualquier feature nuevo se sienta nativo a la app sin reinventar primitivas. Cuando dudes, primero busca un token o componente existente; sólo agrega uno nuevo cuando ninguno encaje.

> **Voz del producto**: lounge cálido, modo oscuro prioritario, papel manila en claro. Nunca punitivo en estados sensibles (miss, slip, descanso, pausa). Idioma de UI: español (es_MX).

---

## 1. Filosofía visual

- **Modo oscuro primero, modo claro derivado en simetría.** Los tokens se declaran con `adaptive(light:, dark:)` en [AppColor.swift](WeekHabit/Extensions/AppColor.swift).
- **Voz dual tipográfica.** Serif (New York) para títulos y hero — voz contemplativa. Sans rounded (SF Rounded) para cuerpo — voz operativa cálida. Sans default para etiquetas — voz técnica sobria.
- **Jerarquía por fondo, no por sombra.** En oscuro, la profundidad se construye con `bgCanvas / bgElevated / bgSunken`. La sombra apenas existe. En claro, sombras cálidas suaves.
- **Color de hábito (`habitColor`) gobierna el componente.** Cuando una pantalla muestra un solo hábito, su color se aplica a marcadores, bordes y acentos locales. El `AppColor.accent` (terracotta) es la voz general de la app.
- **Densidad calmada.** Padding generoso (`AppSpacing.l = 16` lateral; `AppSpacing.xl = 24` entre secciones). Las cards prefieren `radius: AppRadius.l = 20`.

---

## 2. Paleta de colores

Todos los colores son **adaptativos** (cambian según `userInterfaceStyle`). Nunca uses hex hardcoded fuera de [HabitAppearance.swift](WeekHabit/Models/Support/HabitAppearance.swift) (paleta de selección de hábito).

### 2.1 Fondos · estructura

| Token | Light | Dark | Uso |
|---|---|---|---|
| `AppColor.bgCanvas` | `#f5efe3` | `#101113` | Fondo principal de pantalla. Siempre vía `AppBackground { … }`. |
| `AppColor.bgElevated` | `#fffaf0` | `#1a1c20` | Cards principales (default `WHCard`), filas, sheets. |
| `AppColor.bgSunken` | `#ebe3d3` | `#0a0b0d` | Inputs, áreas que reciben contenido, contenedor de la cuadrícula semanal. |
| `AppColor.divider` | `#e5dccb` | `#2a2d33` | Bordes 1pt entre superficies del mismo nivel. |

### 2.2 Texto

| Token | Light | Dark | Uso |
|---|---|---|---|
| `AppColor.textPrimary` | `#2a1f15` | `#f0eee9` | Títulos, body principal, valores. |
| `AppColor.textSecondary` | `#6b5d4a` | `#bcae97` | Captions, subtítulos, metadata. |
| `AppColor.textTertiary` | `#9c8e7c` | `#7d7263` | Eyebrow labels, helpers, conteos auxiliares. |

### 2.3 Acento (terracotta)

| Token | Light | Dark | Uso |
|---|---|---|---|
| `AppColor.accent` | `#b54d2d` | `#e4784f` | Botón primary, FAB "+", iconografía activa, tab seleccionado, tint del NavigationStack. |
| `AppColor.accentMuted` | `#f3d9cf` | `#3a201a` | Fondo de chip seleccionado, badge circular de icono accent, tab seleccionado. |
| `AppColor.accentSubtle` | `#e6c2b3` | `#4d2b22` | Pressed/hover. |

### 2.4 Semánticos (tierra, no Material)

| Token | Light | Dark | Significado |
|---|---|---|---|
| `AppColor.success` | `#5d8a4a` | `#7fa869` | Cierres, rachas confirmadas, mejor día, "completados". |
| `AppColor.warning` | `#a8762e` | `#d9a35b` | Slip, baja confianza, flame de racha, llamado de atención cálido (nunca destructivo). |
| `AppColor.info` | `#6b5e8e` | `#9c8fb8` | Insights, experimentos, comodines (freeze), descansos. |
| `AppColor.infoMuted` | `#eae4f4` | `#30293b` | Fondo del badge `info` (icon-circle del empty state de Today). |

### 2.5 Acciones de fila (swipe)

| Token | Light | Dark | Uso |
|---|---|---|---|
| `AppColor.editAction` | `#5c89a8` | `#7ba4c4` | Acción "Editar" en `swipeActions`. |
| `AppColor.destructiveAction` | `#b54a40` | `#d56158` | Acción "Borrar" / Alert destructivo. Sólo en confirmaciones reales. |

### 2.6 Aliases legacy

Existen shims (`strongText`, `mutedText`, `surface`, `accentSoft`, etc.) en [AppColor.swift](WeekHabit/Extensions/AppColor.swift:60). **No agregues nuevos usos**: deuda técnica a migrar. Nuevo código usa los tokens semánticos.

### 2.7 Paleta de hábito (selectable)

`HabitAppearance.colorHexes` en [HabitAppearance.swift](WeekHabit/Models/Support/HabitAppearance.swift:169) — 24 colores cálidos/tierra elegibles por el usuario para personalizar cada hábito. Acceso via `habit.habitColor`. Los componentes que renderizan un hábito específico (`TodayHabitComponent`, `WeekGridRow`, `HabitDetailView` hero) usan este color, no `AppColor.accent`.

---

## 3. Tipografía — `AppFont`

Escala disciplinada de **8 niveles** (ver [AppFont.swift](WeekHabit/Extensions/AppFont.swift)). Toda tipografía nueva referencia un token.

| Token | Size · Weight · Design | Uso |
|---|---|---|
| `AppFont.display` | 40 · regular · **serif** | Pantallas hito, milestone celebration, cierres semanales. |
| `AppFont.title` | 30 · regular · **serif** | Hero de pantalla ("Hoy", "Tu ritmo", "Editar hábito"). |
| `AppFont.headline` | 22 · medium · **serif** | Sección principal, título de empty state, sectionHeader. |
| `AppFont.body` | 17 · regular · **rounded** | Cuerpo principal. |
| `AppFont.bodyEmphasis` | 17 · semibold · **rounded** | Énfasis (título de card, fila, valor de StatTile). |
| `AppFont.callout` | 15 · regular · **rounded** | Captions de card, subtítulos. |
| `AppFont.label` | 13 · medium · sans | Etiquetas de formulario, helpers, metadata. Eyebrow labels en mayúsculas + `tracking(0.6–1.2)`. |
| `AppFont.micro` | 11 · medium · sans | Tabs, badges, número de racha. |

### Patrones tipográficos recurrentes

- **Eyebrow label** (sobre títulos hero): `AppFont.label`, `textCase(.uppercase)` o `.uppercased(with: es_MX)`, `tracking(0.6–1.2)`, color `textTertiary`. Ejemplo: `"ÚLTIMOS 30 DÍAS"`, `"HOY"`, `"MAÑANA"`.
- **Headline italic + accent.** Empty states usan un fragmento en italic con color accent dentro del headline: `Text("Hoy toca ") + Text("descansar").italic().foregroundColor(.accent)`.
- **Números** siempre con `.monospacedDigit()`. Cuando cambien, agregar `.contentTransition(.numericText())`.

> Hay aliases legacy (`title1`, `subtitle`, `body2`, `formSectionText`…) — no usar en código nuevo.

---

## 4. Espaciado — `AppSpacing`

Escala 4pt en [AppSpacing.swift](WeekHabit/Extensions/AppSpacing.swift). **Toda dimensión** de padding, gap o margin va por un token.

| Token | pt | Uso típico |
|---|---|---|
| `xxs` | 2 | Micro-ajustes (gap dentro de un VStack de título+subtítulo). |
| `xs` | 4 | Icono ↔ texto adyacente. |
| `s` | 8 | Gap interno de chips, separación de elementos próximos, listRowSpacing. |
| `m` | 12 | Gap entre elementos de una card, padding compacto. |
| `l` | 16 | **Padding lateral estándar de pantalla**, gap entre cards, padding interno de `WHCard`. |
| `xl` | 24 | Separación entre secciones, padding vertical de empty states. |
| `xxl` | 32 | Separación de bloques mayores, scroll bottom margin. |
| `xxxl` | 48 | Hero a contenido. |
| `huge` | 64 | Respiración narrativa. |

**Regla práctica:** los `ScrollView` y `List` siempre `.padding(.horizontal, AppSpacing.l)`. Las cards principales aplican padding interno `AppSpacing.l`.

---

## 5. Radios — `AppRadius`

[AppRadius.swift](WeekHabit/Extensions/AppRadius.swift). Toda esquina redondeada referencia un token.

| Token | pt | Uso |
|---|---|---|
| `xs` | 6 | Chips internos pequeños. |
| `s` | 10 | Badges, toggles de día, celdas de la semana (`WeekGridCell`), toggle de completado en `TodayHabitComponent`. |
| `m` | 14 | Inputs, cards pequeñas, banners (review banner, freeze banner). |
| `l` | 20 | **Cards principales** (default de `WHCard`), filas de hábito, plan accordion, StatTile. |
| `xl` | 28 | Sheets, hero containers, TabBar. |
| `capsule` | 999 | Pills, chips, progress markers. |

Siempre con `style: .continuous`. Patrón: `RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)`.

---

## 6. Elevación — `appElevation`

Modificador en [AppElevation.swift](WeekHabit/Extensions/AppElevation.swift). Tres niveles:

| Nivel | Light shadow | Dark shadow | Uso |
|---|---|---|---|
| `.low` | radius 4, y 1, α 0.06 | radius 4, y 1, α 0.18 | Cards regulares, filas, tiles, FAB "+". |
| `.medium` | radius 12, y 4, α 0.10 | radius 12, y 4, α 0.28 | TabBar, plan accordion expandido. |
| `.high` | radius 24, y 10, α 0.16 | radius 24, y 10, α 0.40 | Modal hero, milestone celebration. |

Aplicar con `.appElevation(.low)`. **Nunca** uses `.shadow(...)` directo.

---

## 7. Motion — `AppMotion`

[AppMotion.swift](WeekHabit/Extensions/AppMotion.swift). Cinco curvas. Todas respetan Reduce Motion vía `AppMotion.respectful(_, reduceMotion)`.

| Curva | Spring | Cuándo |
|---|---|---|
| `.snap` | response 0.28, damping 0.85 | Micro-toggles, swipes cortos, press feedback. |
| `.smooth` | response 0.45, damping 0.85 | Default para transiciones de estado, tab switch. |
| `.gentle` | response 0.65, damping 0.9 | Sheets, expansiones grandes, reorganización de listas (Today sections). |
| `.celebration` | response 0.5, damping 0.6 | Cierre de hábito, microcelebración (rebote leve). |
| `.linearOut` | easeOut 0.18 | Fades cortos. |

**Patrón obligatorio** cuando animes desde cualquier View con acceso al ambiente:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
…
withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) { … }
```

Para `SymbolEffect`s nativos preferimos `.symbolEffect(.bounce, value:)` y `.symbolEffect(.pulse, value:)` — usados en toggle de Today y celdas de la semana.

---

## 8. Háptica — `AppHaptics`

[AppHaptics.swift](WeekHabit/Extensions/AppHaptics.swift). Wrapper centralizado. **Los haptics se reservan para cierres con peso emocional. Nunca para navegación.**

Eventos clave: `.habitCompleted`, `.dayClosed`, `.focusClosed`, `.milestoneReached` (impact heavy + success), `.urgeAvoided` (impact medium + success), `.quantityLogged / .quantityCompleted`, `.slipLogged` (warning, sin tono punitivo), `.experimentApplied`, `.selection`.

Pattern: `AppHaptics.play(.habitCompleted)`.

---

## 9. Fondo de pantalla — `AppBackground`

Toda pantalla top-level se envuelve en:

```swift
AppBackground {
    ScrollView { … }   // o List, o VStack
}
```

[AppBackground.swift](WeekHabit/Extensions/AppBackground.swift) aplica `AppColor.bgCanvas` con `ignoresSafeArea`. **Nunca** pintes el fondo a mano.

---

## 10. Componentes UI reutilizables

Todos viven en [Views/Components/](WeekHabit/Views/Components/). Hay una galería en vivo: [ComponentsGalleryView.swift](WeekHabit/Views/Components/ComponentsGalleryView.swift) — úsala como `#Preview` para validar visualmente en oscuro/claro. **No está cableada al shell**, es referencia interna.

### 10.1 `WHButton`

[WHButton.swift](WeekHabit/Views/Components/WHButton.swift). Botón unificado.

```swift
WHButton(title: "Guardar", variant: .primary, action: { … })
WHButton(title: "Secondary", icon: "plus", variant: .secondary, action: { … })
WHButton(title: "Compact", size: .compact, fullWidth: false, action: { … })
```

- Variantes: `.primary` (fondo accent), `.secondary` (bgElevated + border divider), `.ghost` (transparente, texto accent), `.destructive` (sólo confirmaciones).
- Tamaños: `.regular` (padding l/m) y `.compact` (padding m/s, font `label`).
- Press style: scale 0.97 con `AppMotion.snap`.

### 10.2 `WHCard`

[WHCard.swift](WeekHabit/Views/Components/WHCard.swift). Contenedor unificado.

```swift
WHCard(variant: .elevated, padding: AppSpacing.l, radius: AppRadius.l) { … }
```

- `.flat` → `bgCanvas`, sin sombra. Agrupa sin destacar.
- `.elevated` (default) → `bgElevated` + `appElevation(.low)`. Cards principales.
- `.sunken` → `bgSunken`. Inputs.

### 10.3 `WHListRow`

[WHListRow.swift](WeekHabit/Views/Components/WHListRow.swift). Fila estandarizada con `leading` y `trailing` genéricos. Hay inits convenientes para omitir leading/trailing.

```swift
WHListRow(
    title: "Leer 10 min",
    subtitle: "después de cenar",
    leading: { iconBadge() },
    trailing: { Image(systemName: "circle") },
    onTap: { … }
)
```

### 10.4 `WHChip`

[WHChip.swift](WeekHabit/Views/Components/WHChip.swift). Capsule pequeña para selectores/filtros. Estados `idle / selected / disabled`. Selected = `accentMuted` + `accent` text.

### 10.5 `WHEmptyState`

[WHEmptyState.swift](WeekHabit/Views/Components/WHEmptyState.swift). Empty state genérico:

```swift
WHEmptyState(
    icon: "leaf",
    title: "Hoy toca descansar",
    message: "…",
    primaryAction: WHEmptyStateAction(label: "Crear un hábito") { … }
)
```

Icon badge = círculo 88×88 con fondo `accentMuted`, icono `36pt light` `accent`. Hay variantes pintadas a mano (`TodayEmptyStateView`, `WeekEmptyStateCard`) cuando el empty necesita arte específico — sigue la misma anatomía: badge circular + headline serif (con fragmento italic accent) + callout + acción.

### 10.6 `WHProgressRing`

[WHProgressRing.swift](WeekHabit/Views/Components/WHProgressRing.swift). Anillo de progreso con `center` ViewBuilder. Track `divider`, progress `accent` (o color de hábito). Tamaño y `lineWidth` configurables. Default 96pt, lineWidth 10.

### 10.7 `WHProgressBar`

[WHProgressBar.swift](WeekHabit/Views/Components/WHProgressBar.swift). Capsule con fill animada. Soporta `goalMarker` (0..1) opcional como línea vertical sutil.

### 10.8 `WHFormSection`

[WHFormSection.swift](WeekHabit/Views/Components/WHFormSection.swift). Bloque de formulario: title en mayúsculas + control + helper opcional. **Patrón estándar** para CreateHabitView/CreatePlanView.

### 10.9 `WHSectionHeader`

[WHSectionHeader.swift](WeekHabit/Views/Components/WHSectionHeader.swift). Título serif headline + subtítulo opcional + acción inline opcional (link en color accent, font `label`).

### 10.10 `WHConfidenceTag`

[WHConfidenceTag.swift](WeekHabit/Views/Components/WHConfidenceTag.swift). Tag honesta para insights: dot + texto en capsule pintada con opacity del color semántico. `.low → warning`, `.medium → info`, `.high → success`.

### 10.11 `WHDayBadge`

[WHDayBadge.swift](WeekHabit/Views/Components/WHDayBadge.swift). Badge circular con letra inicial. Estados: `isSelected` (fondo accent), `isToday` (ring accent), `isCompleted` (ring success + fondo success 15%).

### 10.12 `WHCreationSheet`

[WHCreationSheet.swift](WeekHabit/Views/Components/WHCreationSheet.swift). Sheet inferior de creación con 3 opciones: hábito / plan / foco. Se invoca desde el botón "+" del header (Today, Week). Detents: `.height(380)` y `.medium`.

### 10.13 `WeeklyReviewBanner`

[WeeklyReviewBanner.swift](WeekHabit/Views/Components/WeeklyReviewBanner.swift). Banner CTA tinted accent (8%) con border accent 22% — patrón para llamados a acción semanal/contextuales no destructivos.

### 10.14 `CustomTabBar` / `TabBarItem`

[CustomTabBar.swift](WeekHabit/Views/Components/CustomTabBar.swift) — **referencia visual**. El shell actual ([ContentView.swift](WeekHabit/ContentView.swift)) usa el `TabView` nativo de SwiftUI con `.tint(AppColor.accent)`. `CustomTabBar` queda disponible si se reactiva un shell custom; conviene mantener su API alineada (`TabItems` enum, `selectedTab` Binding).

### 10.15 `IconButton` (legacy)

[IconButton.swift](WeekHabit/Views/Components/IconButton.swift). FAB circular o pill ancha — usado en `HabitDetailView` topBar. **Para nuevos botones usa `WHButton`**; este componente queda por compatibilidad.

### 10.16 Componentes específicos de feature

Cuando un componente sólo aplica a un feature, vive bajo `Views/<Feature>View/Components/`. Catálogo destacado:

| Feature | Componente | Notas |
|---|---|---|
| Today | `DailyProgressCard`, `PlanAccordion`, `TodayHabitComponent`, `FocusSessionLauncherCard`, `LongestStreakBanner`, `QuantityLogSheet`, `SlipLogSheet`, `UrgeLogSheet`, `RecoveryPromptView`, `ReplacementPromptView`, `EntryNoteSheet` | Fila accordion con barra accent 4pt en `leading`, ring 86pt en progreso diario. |
| Week | `WeekGridCell`, `WeekGridRow`, `WeekHeaderSection`, `DayColumn`, `StatTile`, `WeekGridLayout` | Celda 34pt con 12 estados visuales distintos. Layout en `WeekGridLayout` enum. |
| HabitDetail | `CurrentStreakHeroCard`, `StreakBreakdownCard`, `StatTileView`, `WeekDotsCard`, `LastWeeksHeatmapCard`, `EntryHistoryCard`, `SlipTimelineCard`, `HabitExperimentStatusCard` | Hero color = `habit.habitColor`. |
| Insights | `InsightsHeroCard`, `InsightConfidenceCard`, `InsightSummaryCard`, `RhythmExperimentCard`, `ActiveExperimentCard`, `ExperimentReviewCard`, `UrgePeakHoursCard`, `InsightProvisionalBadge`, `InsightsTrendBars` | Todas son cards con `bgElevated` + `appElevation(.low)`. |
| CreateHabit | 30+ subcomponentes, todos envueltos en `CreateHabitFormSection` (wrapper de `WHFormSection`). | Orden conductual: Dirección → Acción → Señal → Medición → Ritmo → Final → Recordatorio → Plan. |

---

## 11. Estructura de pantallas

Estructura canónica en [CLAUDE.md](CLAUDE.md):

```text
Views/
  <Feature>View/
    <Feature>View.swift
    Components/
      <ComponentName>.swift
  Components/
    SharedComponent.swift   ← Sólo si lo usan 2+ features
```

Cada pantalla top-level sigue este esqueleto:

```swift
struct FeatureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]

    @State private var sheetRoute: FeatureSheetRoute?
    @State private var coverRoute: FeatureCoverRoute?

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView { /* o List */
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        header
                        content
                    }
                    .padding(.horizontal, AppSpacing.l)
                    .padding(.top, AppSpacing.l)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationDestination(item: $selectedHabit) { HabitDetailView(habit: $0) }
            .fullScreenCover(item: $coverRoute) { routeCover($0) }
            .sheet(item: $sheetRoute) { routeSheet($0) }
        }
    }
}
```

---

## 12. Navegación

- **Shell:** `TabView` nativo en [ContentView.swift](WeekHabit/ContentView.swift) con tres tabs sincronizados con `TabItems` enum en [CustomTabBar.swift](WeekHabit/Views/Components/CustomTabBar.swift): `Hoy / Semana / Insights`. Tint global = `AppColor.accent`. **Mantén el orden sincronizado** entre `ContentView` y `TabItems`.
- **Detalle:** se navega con `NavigationStack` + `navigationDestination(item:)`. `HabitDetailView` oculta la nav bar nativa (`.toolbar(.hidden, for: .navigationBar)`) y dibuja su propio top bar con `IconButton` (chevron / pencil).
- **Creación / edición:** **siempre `fullScreenCover`** (no sheet). Las rutas se modelan con enums `Identifiable` privadas (`TodayCoverRoute`, `WeekCoverRoute`, `HabitRoute`, `PlanRoute`). Esto evita modal-on-modal flaky.
- **Acciones de captura (logs, prompts, menús):** `sheet` con `presentationDetents` específicos, `presentationDragIndicator(.visible)`, `presentationBackground(AppColor.bgCanvas)`. Detents típicos: `.height(310)` (quantity), `.height(380)` (creation menu), `.height(420)` (urge), `.height(560)` (slip), `.height(570)` (recovery prompt).
- **Sheets que se encadenan:** cierra el primero (`sheetRoute = nil`) y abre el siguiente dentro de un `DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)`. Patrón usado en `handleCreationSelection`.

---

## 13. Patrones UX recurrentes

### 13.1 Header de pantalla

Layout consistente en Today, Week, Insights, CreateHabit:

1. **Eyebrow** (`AppFont.label` mayúsculas, `textTertiary`, `tracking(0.6–1.2)`) — fecha actual, "ÚLTIMOS 30 DÍAS", "MAÑANA", "MES YYYY".
2. **Title** (`AppFont.title` serif, `textPrimary`) — "Hoy", "Tu ritmo", "Semana N".
3. **Acción a la derecha**, opcional: FAB "+" circular 42pt (`AppColor.accent`, foreground white, `appElevation(.low)`).

### 13.2 Empty states

Tres niveles según contexto:

1. **Pantalla vacía sin nada que mostrar** (Today sin hábitos hoy, Week sin hábitos): card grande con icon-badge circular (~96pt), headline serif con fragmento italic accent, callout, acción primaria. Ejemplos: `TodayEmptyStateView`, `WeekEmptyStateCard`.
2. **Empty inline dentro de una pantalla con contenido** (Insights sin habits): card `bgElevated` + `appElevation(.low)` + icono `28pt semibold`, headline + callout, sin CTA.
3. **`WHEmptyState` genérico** cuando el patrón es estándar.

**Copy guideline:** los empties no son punitivos. "El descanso también construye semana", "La cuadrícula se irá llenando…", "Aún no hay ritmo que leer".

### 13.3 Swipe actions (`List`)

Patrón triple en filas (Today, Week, plan rows):

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button { … } label: { Label("Hoy descanso", systemImage: "pause.circle") }
        .tint(habit.habitColor)

    Button(role: .destructive) { … } label: { Label("Borrar", systemImage: "trash") }
        .tint(AppColor.destructiveAction)

    Button { … } label: { Label("Editar", systemImage: "pencil") }
        .tint(AppColor.editAction)
}
```

- Reglas: nunca `allowsFullSwipe: true` para destructivos. Borrar siempre confirma con `alert`. Editar usa `AppColor.editAction`. El descanso usa el color del propio hábito (no warning).
- Sustituye una acción por su inversa cuando ya está aplicada ("Quitar descanso", "Deshacer slip").

### 13.4 Confirmaciones destructivas

```swift
.alert("¿Borrar hábito?", isPresented: $showDelete) {
    Button("Cancelar", role: .cancel) { … }
    Button("Borrar", role: .destructive) { … }
} message: {
    Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
}
```

### 13.5 Filas / cards con identidad de hábito

Patrón estándar en `TodayHabitComponent`, `WeekGridRow`, `PlanAccordion`:

- Fondo: `AppColor.bgElevated`.
- Radio: `AppRadius.l` (`continuous`).
- Border 1pt: `divider` o `habit.habitColor.opacity(0.14–0.38)` según estado.
- Iconografía del hábito: `Circle().fill(habitColor.opacity(0.14–0.18))` 38–46pt, icono semibold `habitColor`.
- Elevation: `.low`.
- **Acento vertical** opcional (plan accordion, week row): `Rectangle().fill(habitColor).frame(width: 4)` como overlay leading.

### 13.6 Toggle de completado (`TodayHabitComponent`)

- Square 34pt con `RoundedRectangle(cornerRadius: AppRadius.s)`.
- Llenado `habit.habitColor` al completar; `opacity(0.55)` para versión mínima; `opacity(0.10)` para skipped.
- Press feedback: scale 0.92 vía `DragGesture(minimumDistance: 0)` (no `ButtonStyle` porque convive con `Menu` de versión mínima).
- Símbolo: `checkmark` (build) / `xmark` (break) / `pause.circle.fill` (skipped) con `.symbolEffect(.bounce, value:)`.

### 13.7 Estados visuales del Week grid

`WeekGridCell` tiene **12 estados** ([WeekGridCell.swift](WeekHabit/Views/WeekView/Components/WeekGridCell.swift)) — usa siempre el enum existente antes de inventar uno nuevo:

`completed · completedRetro · minimum · skipped · frozen · missed · slip · urge · partial · partialRetro · pending · inactive · future`

Convenciones: fill sólido = marca confiable. Border discontinuo (`dash`) = retroactivo o descanso. Opacidad baja del color de hábito (~0.10) = pending/missed. Strokes son ~1–1.3pt.

### 13.8 Métricas / StatTile

[StatTile (Week)](WeekHabit/Views/WeekView/Components/StatTitle.swift) y [StatTileView (Detail)](WeekHabit/Views/HabitDetailView/Components/StatTileView.swift) — icon-badge circular 30pt + valor `bodyEmphasis` + caption `label`. Estado vacío usa "—" con todo en `textTertiary`. Apliquen `contentTransition(.numericText())` al valor.

### 13.9 Pills / chips de estado contextual

- **Pill semántica neutra** (sólo lectura): `Capsule()` con `color.opacity(0.10–0.14)` de fondo y border `color.opacity(0.22–0.42)`, foreground `color`. Patrón usado por action pills de break ("Tuve el impulso", "Registrar slip"), `WeekProgressPill`, `WeeklyReviewBanner`.
- **Chip seleccionable**: `WHChip`.

### 13.10 Animaciones de lista (Today sections)

Cuando un hábito cambia de sección (pendiente → completado → slip), se usa `matchedGeometryEffect` con namespace por sección y `transition(.asymmetric(...))` envuelto en `AppMotion.gentle`. Ver `todayHabitSectionMotion` en [TodayView.swift:1264](WeekHabit/Views/TodayView/TodayView.swift). Cuando agregues una sección nueva, replica el mismo patrón con el namespace existente.

### 13.11 Formularios

`CreateHabitView` y `CreatePlanView` son la referencia. Reglas:

- Local `@State` por campo, `init(...)` que hidrata desde la entidad en modo edición.
- Computed `isSaveDisabled` con todas las reglas.
- Normalizar (`trim`, valores numéricos) **antes** de guardar.
- Insert/update directo con `modelContext`, sin servicio intermedio.
- `dismiss()` al terminar.
- Refrescar side effects explícitos (ej. `HabitReminderService.refreshReminder(for:)`).
- Top bar con `CreateHabitTopBar` (Cancelar text-button + `WHButton` compact "Guardar").
- Cada bloque del form envuelto en `CreateHabitFormSection` / `WHFormSection`.

### 13.12 Onboarding

[OnboardingView.swift](WeekHabit/Views/OnboardingView/OnboardingView.swift) — flujo goal-first con steps (`OnboardingStep` enum). Progress en top vía `OnboardingProgressView`. Transición entre pantallas: `.opacity.combined(with: .move(edge: .trailing))` con `AppMotion.gentle`. Respeta Reduce Motion (cambia a `.opacity` solo).

### 13.13 Habit appearance picker

Selector de icono/color de hábito vive en [HabitAppearancePicker.swift](WeekHabit/Views/CreateHabitView/Components/HabitAppearancePicker.swift) — grid agrupada por categoría (`HabitIconGroup`) + paleta de 24 colores. Reusa este picker antes de inventar uno nuevo si necesitas color o icono de hábito.

---

## 14. Iconografía (SF Symbols)

- Toda la iconografía usa **SF Symbols**. No hay assets bitmap.
- Tamaños canónicos: 10–11 (micro, dentro de pills), 12–14 (acciones inline, swipe), 15–18 (badges de fila), 18–22 (header de card), 26–36 (empty state badges).
- Peso: `semibold` para acciones, `medium` para badges grandes, `light` para empty state hero (36pt light).
- **Colores temáticos** (consistentes en toda la app):
  - `target` → planes
  - `leaf` → hábitos build / descanso
  - `timer` → focus session
  - `flame.fill` → racha
  - `shield.fill` → comodín (freeze)
  - `pause.circle.fill` → descanso intencional
  - `arrow.counterclockwise` → slip
  - `waveform.path.ecg` → urge / impulso
  - `calendar.badge.checkmark` → revisión semanal
  - `sun.max` / `moon.stars` → mañana / descanso nocturno
  - `chart.line.uptrend.xyaxis` → insights vacíos
  - `arrow.turn.down.right` → cue / señal (precede el texto del cue)

---

## 15. Localización y copy

- Strings UI y comentarios en español; identificadores y tipos en inglés.
- Locale `es_MX` para `DateFormatter` y casos de mayúscula con diacríticos. Ejemplo: `.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_MX")).uppercased(...)`.
- **Tono**: cálido, observador, no punitivo. "Te falta uno", "El descanso también construye semana", "La señal todavía se está formando" (confianza baja), "Día cerrado", "Hubo un slip. Registrarlo también cuenta".
- Verbos en imperativo amable para CTAs: "Crear", "Guardar", "Editar", "Empezar". Para destructivos: "Borrar" (no "Eliminar").
- Mayúsculas en eyebrow labels: usa `.uppercased(with: Locale(identifier: "es_MX"))` o `textCase(.uppercase)`.

---

## 16. Calendario y fechas

- **Nunca uses `Calendar.current` directamente.** Usa `AppCalendar` en [AppCalendar.swift](WeekHabit/Extensions/AppCalendar.swift): `AppCalendar.current`, `AppCalendar.startOfDay(for:)`, `AppCalendar.isSameDay(_, _)`, `AppCalendar.weekday(of:)`, `AppCalendar.weekRange(containing:)`.
- Semana empieza según `AppCalendar` (no asumas lunes).
- Para mostrar día corto: `Weekday.shortName.uppercased(with: es_MX)` (DayColumn pattern).

---

## 17. Checklist al agregar UI nueva

Antes de hacer commit, valida:

1. ¿Estoy reusando `WHCard / WHButton / WHListRow / WHFormSection / WHEmptyState` antes de pintar primitivas?
2. ¿Todos los colores son tokens `AppColor.*` (sin hex), todas las fuentes `AppFont.*`, todos los espaciados `AppSpacing.*`, todos los radios `AppRadius.*`?
3. ¿La pantalla top-level está envuelta en `AppBackground`?
4. ¿Cards con `appElevation(.low)` (no `.shadow` directo)?
5. ¿Animaciones envueltas en `AppMotion.respectful(_, reduceMotion)`?
6. ¿Háptica solo en cierres con peso emocional?
7. ¿Cambios de estado animan con `matchedGeometryEffect` cuando hay reorganización de listas?
8. ¿Form sigue el patrón de `CreateHabitView` (state local + `isSaveDisabled` + trim + insert directo)?
9. ¿Sheets usan `presentationDetents`, `presentationDragIndicator(.visible)`, `presentationBackground(AppColor.bgCanvas)`?
10. ¿Swipe actions con destructive sin full-swipe + alerta de confirmación?
11. ¿Estados sensibles (miss / slip / break / pause) usan copy neutral y color `warning` / `info`, no `destructiveAction`?
12. ¿Strings nuevas en español es_MX, eyebrow labels en mayúsculas con `tracking`?
13. ¿`AppCalendar` en vez de `Calendar.current`?
14. Validé visualmente en `#Preview` **light y dark** (`preferredColorScheme(.light/.dark)`).
15. La galería ([ComponentsGalleryView](WeekHabit/Views/Components/ComponentsGalleryView.swift)) sigue mostrando todo bien si el cambio toca un componente WH*.
