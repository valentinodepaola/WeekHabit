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
