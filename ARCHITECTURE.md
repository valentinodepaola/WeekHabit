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
- Las entradas `.urge` son evidencia independiente. Cambiar el estado principal de un
  día no debe eliminarlas ni convertirlas.

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

`HabitDraft` contiene el estado editable, validación y normalización de
`CreateHabitView`. `HabitEditorService` crea o actualiza las entidades y relaciones.
La vista coordina permisos, errores, recordatorios y navegación, pero ya no mantiene cada
campo como un estado independiente ni implementa la transacción de SwiftData.

## Próximas extracciones

- Aplicar un draft equivalente a `CreatePlanView`.

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

## Pruebas

`WeekHabitTests` valida servicios y reglas de dominio usando un `ModelContainer` SwiftData
en memoria independiente por prueba. La cobertura inicial fija los contratos de tracking,
scheduling, streaks, freezes y recovery descritos en `TESTING.md`.

Las vistas no se prueban para demostrar reglas de negocio. Cuando una regla es difícil de
probar sin renderizar una vista, debe extraerse primero a dominio o a un servicio.

Las fases 2 y 3 de arquitectura están protegidas por 13 pruebas de regresión que pasan en
iOS Simulator.
