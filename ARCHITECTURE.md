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

`TodayView` es la referencia del patrón, introducido como prueba de concepto en la Fase 3 del
plan de mejoras. **Todavía no se replicó en las otras vistas**; decidirlo es un issue abierto
del repo.

Son dos tipos con responsabilidades distintas, y se pueden adoptar por separado:

- **`TodayViewData`** — struct de valor con todos los datos derivados del render, construida
  una sola vez en `body` desde los resultados de `@Query`. Antes eran nueve propiedades
  computadas que se invocaban entre sí, y el resultado eran ~15 pasadas por render.
- **`TodayScreenModel`** — clase `@Observable` con las rutas, las confirmaciones y el estado
  de sección, sostenida por un solo `@State`. Reemplaza a 13 `@State` sueltos con reglas
  implícitas entre ellos.

La vista conserva `@Query` y `@Environment(\.modelContext)`, y sigue delegando las mutaciones
a los servicios. No hay repositorios, use cases ni DTOs: el descarte de Clean Architecture
está argumentado más abajo.

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
  detectaba una auditoría que solo buscaba `insert`, `delete` y `save`. De ahí sale la regla
  de escritura implícita de más arriba.
- Lo que sigue abierto vive en los issues del repo. Los planes de refactor ya ejecutados
  (`PLAN_SIMPLIFICACION.md`, `REFACTOR_HANDOFF.md`, `docs/PLAN_MEJORAS.md`) se borraron; su
  historia vive en git.

## Por qué no Clean Architecture + MVVM

> **⚠️ Decisión reabierta — esta sección ya no describe el rumbo de la app.**
>
> La app está migrando a Clean Architecture + MVVM. Lo que sigue es el análisis que la
> descartó en su momento, y se conserva porque explica los riesgos reales que la migración
> tiene que resolver —sobre todo la incompatibilidad de `@Query`, que sigue siendo el punto
> más delicado—. Lo que cambió: ese análisis pesó rendimiento, `@Query` y falta de tests,
> pero nunca pesó el costo de comprensión de quien mantiene la app, que es lo que reabrió
> la decisión.
>
> El plan de implementación, las convenciones y las dos compuertas viven en el issue #27 y
> sus subissues. Esta sección se reemplaza por el ADR nuevo al cerrar la fase F10 (#38).

Se evaluó migrar la app a Clean Architecture con MVVM y **se descartó por costo/beneficio**.
El dato que decidió: **48 archivos de vista referencian `Habit` directamente** y 12 usan
`@Query`. Clean Architecture prohíbe exactamente eso.

Las cuatro razones concretas:

1. **`@Query` es incompatible y no tiene reemplazo equivalente.** Es un property wrapper que
   solo funciona dentro de una `View` y devuelve clases `@Model`. Renunciar a él significa
   fetch manual más observar `ModelContext.didSave` por `NotificationCenter` y refrescar a
   mano: más código, menos preciso, y reintroduce bugs de "la vista no se actualizó" que hoy
   no existen.
2. **Mapear las entidades `@Model` a structs puras cuesta rendimiento.** `Habit` tiene
   relación con carga perezosa a `HabitEntry`. Hoy `Habit+Streaks` y el heatmap recorren
   entradas bajo demanda; con mappers a DTO habría que materializar el grafo completo en cada
   lectura.
3. **`@Observable` + SwiftData todavía tiene aristas.** Mutar un `@Model` desde un ViewModel
   no siempre propaga la invalidación como lo hace `@Query`.
4. **No hay red de seguridad donde más se tocaría.** La suite protege servicios y dominio; las
   vistas explícitamente no se testean. Sería reescribir ~17 000 líneas sin tests que avisen
   de regresiones.

Estimación de la migración completa: **4–7 semanas**, con riesgo alto de regresión y una app
peor integrada con SwiftUI que la actual.

La app ya tiene la mayor parte del beneficio que buscaba esa migración: dominio puro separado
por responsabilidad en `Models/Domain/`, servicios sin estado como frontera de escritura,
drafts como capa de estado de feature, y errores de persistencia que no se silencian.

**Esta decisión está tomada.** Reabrirla exige evidencia nueva, no preferencia de estilo.

## Riesgo conocido: invalidación de `AppCalendar` por zona horaria

`AppCalendar.current` está cacheado. Antes se reconstruía en cada acceso, así que un cambio de
zona horaria se reflejaba solo; ahora la corrección depende de que llegue la notificación de
invalidación.

**Verificado:** el observador se registra, se suscribe a las dos notificaciones, y publicarlas
a mano no rompe ni deja el caché en mal estado
(`AppCalendarTests.testCalendarStaysUsableAfterInvalidationNotifications`).

**No verificado:** que iOS efectivamente publique `.NSSystemTimeZoneDidChange` y que la app
muestre los días nuevos, con la app abierta y el usuario cruzando zonas horarias. No se pudo
comprobar porque el simulador hereda la zona horaria del Mac anfitrión y cambiarla ahí requiere
privilegios de administrador.

Formas de cerrarlo, si llega a importar: probarlo a mano en un dispositivo real, o validar en
cada acceso que el `timeZone` del calendario cacheado siga coincidiendo con `TimeZone.current`
—una comparación barata al lado de construir el calendario, que vuelve la corrección
independiente de la notificación—. Se descartó al planear para no pagar una búsqueda por
acceso; a la luz de que el cacheo solo dio un 7 %, ese ahorro vale menos de lo que parecía.

**Detalle relacionado:** `HabitEntry.date` y `StreakFreeze.protectedDate` se normalizan a
start-of-day en sus inits y nada los muta después, así que comparar `Date` directo es correcto
—salvo si el usuario cruzó zonas horarias entre que se escribió la entrada y se la consulta—.
Por eso `HabitDayIndex` **renormaliza cada entrada al construirse**, con el calendario vigente.

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

Las reglas de arquitectura están protegidas por la suite completa, que pasa en iOS
Simulator. El conteo vigente y la cobertura por área están en `TESTING.md`.
