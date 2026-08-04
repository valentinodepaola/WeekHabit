# Arquitectura de WeekHabit

WeekHabit usa una arquitectura SwiftUI pragmática. Las vistas pueden leer datos con
`@Query`, pero las reglas de escritura reutilizables no deben implementarse directamente
en cada pantalla.

## Capas

```text
Views
  Renderizan estado, coordinan navegación y disparan acciones.
        |
        v
Feature State
  Drafts y estado local de flujos complejos.
        |
        v
Domain Services
  Mutaciones y reglas reutilizables.
        |
        v
SwiftData Models
  Entidades persistidas y cálculos de dominio de solo lectura.
```

## Reglas

- Las vistas top-level pueden usar `@Query` para lectura reactiva.
- Una mutación usada por más de una feature debe vivir en un servicio de dominio.
- Los efectos visuales, haptics y navegación permanecen en la vista.
- Los formularios complejos agrupan sus campos y validación en un `Draft`.
- Los errores de persistencia no deben silenciarse con `try?`.
- **Asignar una propiedad de un `@Model` desde una vista también es una escritura**, aunque
  no se nombre `insert`, `delete` ni `save`: SwiftData la persiste por autosave. Cuenta como
  mutación y va a un servicio. Auditar solo `modelContext.(insert|delete|save)` no alcanza.
- Una decisión que se toma **una sola vez** —cierre de plan, prompt de recuperación— guarda
  de inmediato. El autosave no da garantía de cuándo, y estos flujos no tienen una segunda
  oportunidad natural de reescribirse.
- Las entradas `.urge` son evidencia independiente. Cambiar el estado principal de un
  día no debe eliminarlas ni convertirlas.
- Los datos derivados de un render se calculan **una sola vez**, no en propiedades
  computadas que se invocan entre sí. Ver "Estado de pantalla" más abajo.

## Tracking

`HabitTrackingService` es la única autoridad para cambiar el estado diario de un hábito:

- completar o desmarcar;
- registrar cantidades;
- marcar versión mínima;
- descansar;
- registrar o deshacer slips;
- registrar urges;
- registrar misses de recuperación;
- aplicar y retirar streak freezes.

`TodayView`, `WeekView` y `FocusSessionView` deben delegar estas operaciones al servicio
y conservar únicamente las decisiones de presentación.

## Formularios

`HabitDraft` y `PlanDraft` contienen el estado editable, validación y normalización de sus
formularios. `HabitEditorService` y `PlanEditorService` crean o actualizan las entidades y
relaciones. Las vistas coordinan permisos, errores, recordatorios y navegación, pero no
implementan las transacciones de SwiftData.

## Estado de pantalla

`TodayView` es la referencia del patrón, introducido en la Fase 3 de `docs/PLAN_MEJORAS.md`
como prueba de concepto. **Todavía no se replicó en las otras vistas**; hacerlo es una
decisión abierta.

Son dos tipos con responsabilidades distintas, y se pueden adoptar por separado:

- **`TodayViewData`** — struct de valor con todos los datos derivados del render, construida
  una sola vez en `body` desde los resultados de `@Query`. Antes eran nueve propiedades
  computadas que se invocaban entre sí, y el resultado eran ~15 pasadas por render.
- **`TodayScreenModel`** — clase `@Observable` con las rutas, las confirmaciones y el estado
  de sección, sostenida por un solo `@State`. Reemplaza a 13 `@State` sueltos con reglas
  implícitas entre ellos.

La vista conserva `@Query` y `@Environment(\.modelContext)`, y sigue delegando las mutaciones
a los servicios. No hay repositorios, use cases ni DTOs: el descarte de Clean Architecture
está argumentado en `docs/PLAN_MEJORAS.md`.

Lo que este patrón habilita, además de la claridad: **el estado de coordinación se vuelve
testeable**. Las secuencias de presentación diferida vivían dentro de la `View` y por eso no
se probaban; ahora sí (`TodayScreenModelTests`).

Cuando una vista se parta en varios archivos, sus miembros pasan de `private` a `internal`:
`private` en Swift no cruza archivos. Es aceptable dentro del módulo de la app.

## Próximas extracciones

- Las vistas ya no escriben a `modelContext`. Onboarding delega en `OnboardingSetupService`
  y el prompt de recuperación en `HabitTrackingService.commitRecoveryMiss`.
- El cierre de plan delega en `PlanLifecycleService.completeWrapUp`. Era la última escritura
  implícita —asignaba `endsAt` y `reviewedAt` sin pasar por `modelContext`— y por eso no la
  detectaba la auditoría original. Detalle en `docs/PLAN_MEJORAS.md`.
- El plan detallado de las fases 5 y 6 está en `REFACTOR_HANDOFF.md`. Lo que sigue está en
  `docs/PLAN_MEJORAS.md`.

## Dominio de hábitos

La lógica de solo lectura de `Habit` se organiza por responsabilidad:

- `Habit+Scheduling`: calendario, pausas, fechas y días registrables.
- `Habit+Completion`: estados diarios, cantidades y progreso.
- `Habit+Streaks`: rachas y su desglose.
- `Habit+Freezes`: protección y candidatos de comodín semanal.
- `Habit+Recovery`: candidatos para prompts de recuperación.
- `Habit+Presentation`: copy derivado y matriz visual.

La fase 3 eliminó el archivo monolítico `Habit+Domain.swift` sin cambiar sus APIs ni
comportamiento observable.

### Consultas por día

`HabitDayIndex` agrupa las entradas y comodines de un hábito por día normalizado, y baja cada
consulta de O(entradas) a O(1). **Cualquier recorrido que consulte muchos días seguidos debe
construirlo una vez y reutilizarlo**, no llamar a las funciones de un solo día en bucle: ese
patrón es cuadrático y fue el causante de un `bestStreak` de 2 478 ms.

Para una consulta aislada, seguir usando la API de `Habit`: construir un índice para una sola
búsqueda sale más caro que escanear.

Cuando varias funciones necesitan compartir el índice, la forma preferida es un tipo nuevo
que lo construya y derive todo de él —como `TodayPartition` en `HabitCollection+Today`— con
una sobrecarga `…(on:index:)` para la regla que se reutiliza. Las firmas existentes no se
tocan.

## Pruebas

`WeekHabitTests` valida servicios y reglas de dominio usando un `ModelContainer` SwiftData
en memoria independiente por prueba. La cobertura inicial fija los contratos de tracking,
scheduling, streaks, freezes y recovery descritos en `TESTING.md`.

Las vistas no se prueban para demostrar reglas de negocio. Cuando una regla es difícil de
probar sin renderizar una vista, debe extraerse primero a dominio o a un servicio.

Las fases 2, 3 y 4 de arquitectura están protegidas por 16 pruebas de regresión que pasan
en iOS Simulator.
