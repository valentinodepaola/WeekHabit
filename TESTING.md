# Estrategia de pruebas

El target `WeekHabitTests` ejecuta pruebas unitarias contra la app con un
`ModelContainer` SwiftData en memoria. Cada prueba crea su propio contenedor para evitar
estado compartido y no toca la base local del usuario.

## Ejecutar

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Estado actual de la suite

Última validación conocida (2026-08-22): **107 tests passed** en 18 suites, sobre
`platform=iOS Simulator,name=iPhone 17 Pro`, sin fallos.

Además de la cobertura inicial, la suite ya cubre:

- Servicios de persistencia extraídos en A1:
  - `WeeklyReviewEditorService`
  - `HabitLifecycleService`
  - `PlanLifecycleService`
  - `FocusSessionEditorService`
  - `EntryNoteService`
  - `HabitExperimentService`
- Métricas y ranking de Insights agregados en A3:
  - readiness;
  - snapshot global;
  - confianza high/learning/low;
  - `attentionHabit`;
  - `urgePeakHourInsight`;
  - sugerencias de experimentos y orden por prioridad.
- `OnboardingSetupService`, agregado en la Fase 1 del plan de mejoras:
  - título de respaldo y motivación nula cuando el texto viene vacío;
  - normalización de espacios y fecha de fin a 30 días en start-of-day;
  - reutilización del plan existente en vez de crear un segundo;
  - alta y baja de hábitos de plantilla ligados al plan;
  - guardado diferido: las mutaciones quedan pendientes hasta `commit`.
- `HabitTrackingService.commitRecoveryMiss`: aplica la versión mínima y persiste.
- `PerformanceBaselineTests`, agregado en la Fase 2 del plan de mejoras. Ver abajo.
- `AppCalendarTests`, agregado en la Fase 2.5: el calendario se cachea, y estas pruebas
  fijan que cachearlo no cambie lo que devuelven `startOfDay`, `weekday`, `weekRange` ni
  `isSameDay`, y que invalidar el caché lo reconstruya bien.
- `HabitDayIndexTests`: pruebas de **equivalencia** del índice por día. Recorren día por día
  un historial completo y comparan cada predicado del índice contra su equivalente en
  `Habit`. Son la red que protege ese refactor: si el índice difiere en un solo día, fallan.
- `TodayViewDataTests` y `TodayScreenModelTests`, agregados en la Fase 3. Son cobertura que
  **antes no podía existir**: ese código vivía dentro de `TodayView` como propiedades
  computadas y `@State`, y las vistas no se testean por decisión de `ARCHITECTURE.md`.
  - `TodayViewDataTests`: particiones y contadores del día, exclusión de descansos y slips
    de los candidatos a sesión de enfoque conservando el orden, y estabilidad de la firma
    de sección.
  - `TodayScreenModelTests`: la secuencia hito → nota diferida, que antes era un reintento
    temporizado que descartaba la nota en silencio si no lograba presentarla en seis
    intentos. También el prompt de recuperación una vez por sesión y las confirmaciones de
    borrado derivadas de su opcional.
- `FocusSequenceTests`: el modelo de la secuencia ordenada de la Sesión de ritmo. El total es
  la suma de los bloques; `clampedSeconds` hace snap al paso de 300 s y respeta los límites;
  los estados por bloque (pendiente / en curso / hecho) y el índice actual son correctos al
  inicio, a mitad del segundo bloque y pasado el total; y `reconcile` conserva orden y tiempos
  ya asignados al agregar hábitos nuevos.
- `TodayCollectionsTests` suma pruebas de **equivalencia** de `todayPartition(on:)` contra
  las siete funciones sueltas que reemplaza, incluido el caso de agenda flexible y el
  solapamiento de descanso con slip.
- `LifecycleServiceTests` cubre `PlanLifecycleService.completeWrapUp`: qué hábitos se
  archivan y cuáles no, que el plan quede marcado como revisado, y que **el cierre quede
  escrito y no pendiente** (`hasChanges == false`). Esa última es la que importa: mientras
  `reviewedAt` sea nil, `ContentView` vuelve a abrir la hoja de cierre.

## Línea base de rendimiento

`PerformanceBaselineTests` mide cada métrica del dominio sobre dos tamaños de dataset y
reporta el factor de crecimiento entre ambos. El dataset lo genera `TestHistoryFactory` en
`TestSupport.swift`, con la misma forma que `PerformanceSeedService` pero parametrizado.

Medición del **2026-07-27**, iPhone 17 Pro simulador, promedio de 3 corridas descartando el
calentamiento:

### Métricas de colección — escalan con la cantidad de hábitos

| Métrica | 5 hábitos | 15 hábitos | Factor |
|---|---:|---:|---:|
| Insights snapshot | 541,37 ms | **1 610,30 ms** | 3,0× |
| Sugerencias de experimentos | 818,64 ms | **2 524,21 ms** | 3,1× |
| Agregados de Week | 37,68 ms | 108,60 ms | 2,9× |
| Colecciones de Today | 17,55 ms | 52,05 ms | 3,0× |
| Insights readiness + confianza | 0,77 ms | 2,22 ms | 2,9× |
| Insights de urges | 0,60 ms | 1,79 ms | 3,0× |

### Métricas por hábito — escalan con el largo del historial

| Métrica | 365 días | 1 095 días | Factor |
|---|---:|---:|---:|
| `bestStreak` | 294,19 ms | **2 665,18 ms** | **9,1×** |
| `completionMatrix` (10 semanas) | 64,22 ms | 201,57 ms | 3,1× |
| `currentStreakBreakdown` | 1,33 ms | 6,83 ms | 5,1× |

### Cómo leer los números

Un factor de 3× frente a una entrada 3× mayor es crecimiento proporcional. `bestStreak` da
**9,1×**, o sea cuadrático: es la confirmación de que `Habit+Completion` resuelve cada
consulta por día escaneando linealmente todas las entradas del hábito.

`currentStreakBreakdown` crece 5,1× pero queda en 6,83 ms porque corta en el primer día roto
y escanea pocos días. `bestStreak` recorre todo el rango, y por eso paga el costo completo.

La decisión que salió de estos números fue indexar las entradas por día en vez de cachear;
el resultado está en la tercera medición.

## Segunda medición — con el `Calendar` cacheado

Misma máquina y mismo método, después de cachear `AppCalendar.current` (Fase 2.5). La
comparación es contra la tabla de arriba, columna del tamaño grande:

| Métrica | Antes | Después | Cambio |
|---|---:|---:|---:|
| Insights snapshot | 1 610,30 ms | 1 494,30 ms | −7,2 % |
| Sugerencias de experimentos | 2 524,21 ms | 2 293,79 ms | −9,1 % |
| Agregados de Week | 108,60 ms | 101,84 ms | −6,2 % |
| Colecciones de Today | 52,05 ms | 48,53 ms | −6,8 % |
| `bestStreak` | 2 665,18 ms | 2 478,11 ms | −7,0 % |
| `completionMatrix` | 201,57 ms | 194,24 ms | −3,6 % |
| `currentStreakBreakdown` | 6,83 ms | 6,31 ms | −7,6 % |

Los factores de crecimiento no se movieron: `bestStreak` sigue en 9,0×.

**Lo que enseña este resultado:** construir el `Calendar` no era el cuello de botella. El
costo real está dentro de `Calendar.isDate(_:inSameDayAs:)`, que tiene que descomponer
ambas fechas en componentes bajo la zona horaria vigente — del orden de 6 µs por llamada, y
`bestStreak` la invoca unas 400 000 veces.

El corolario para el índice por día es directo: **no alcanza con hacer menos llamadas a
`isSameDay`, hay que dejar de llamarla**. El índice tiene que agrupar por fecha ya
normalizada y comparar `Date` directo.

## Tercera medición — con el índice por día

Después de introducir `HabitDayIndex` y usarlo en los recorridos por día del dominio. La
comparación es contra la segunda medición:

| Métrica | Antes | Después | Mejora | Factor antes | Factor después |
|---|---:|---:|---:|---:|---:|
| `bestStreak` | 2 478,11 ms | **8,11 ms** | **306×** | **9,0×** | **3,0×** |
| `completionMatrix` | 194,24 ms | **1,89 ms** | **103×** | 3,1× | 1,9× |
| Sugerencias de experimentos | 2 293,79 ms | **43,67 ms** | **53×** | 3,0× | 3,0× |
| Insights snapshot | 1 494,30 ms | **125,89 ms** | **12×** | 3,0× | 3,0× |
| `currentStreakBreakdown` | 6,31 ms | 1,42 ms | 4,4× | 5,1× | 3,0× |
| Agregados de Week | 101,84 ms | 56,72 ms | 1,8× | 2,9× | 3,0× |
| Colecciones de Today | 48,53 ms | 47,66 ms | — | 2,9× | 3,0× |

La suite completa pasó de ~64 s a ~28 s.

### Lo importante no es solo el absoluto

**`bestStreak` pasó de crecer 9,0× a crecer 3,0×** ante una entrada 3× mayor. Eso es lo que
importa: el costo dejó de ser cuadrático y pasó a ser proporcional. El problema no quedó
disimulado por una constante más chica, quedó resuelto.

`completionMatrix` incluso baja a 1,9× porque su ventana está acotada a 70 días: ahora que
consultar un día es O(1), agrandar el historial casi no la afecta.

### Lo que no mejoró, y por qué

**Las colecciones de Today siguen en ~48 ms.** Estaba previsto: cada partición
(`pendingToday`, `completedToday`, `skippedToday`, `slippedToday`) hace **una sola** consulta
por hábito, así que construir un índice por función cuesta más o menos lo mismo que escanear.
Bajarlo exige compartir un índice entre las cuatro particiones. La Fase 3 lo hizo; ver la
cuarta medición.

## Cuarta medición — con el índice compartido entre particiones (Fase 3)

`todayPartition(on:)` construye un solo `HabitDayIndex` por hábito y deriva de él las cuatro
secciones y los tres contadores. La comparación es contra la tercera medición:

| Métrica | Antes | Después | Mejora |
|---|---:|---:|---:|
| Colecciones de Today | 47,66 ms | **7,97 ms** | **6,0×** |
| Insights snapshot | 125,89 ms | 137,48 ms | — |
| Agregados de Week | 56,72 ms | 62,90 ms | — |
| `bestStreak` | 8,11 ms | 8,84 ms | — |

Solo cambió la métrica que la Fase 3 tocó; el resto se mueve dentro del ruido de medición
entre corridas. El techo de `Ceiling.todayCollections` bajó de 250 ms a **40 ms**.

**Este número mide una sola pasada.** La ganancia real en la app es mayor: `TodayView`
recalculaba las particiones unas 15 veces por render, porque `todayHabits` era una propiedad
computada que invocaban nueve derivados más la firma de animación. Ahora `TodayViewData` se
construye una vez por render.

Lo mismo que se hizo acá bajaría el snapshot de Insights, que sigue en ~137 ms con 15
hábitos: sus métricas de colección también consultan hábito por hábito sin compartir índice.
Queda anotado como candidato, no hecho.

### Cómo volver a medirlos

Los `print` solo se ven corriendo desde Xcode. Desde consola, cada medición queda además
como attachment dentro del `.xcresult`:

```bash
R=$(ls -td ~/Library/Developer/Xcode/DerivedData/WeekHabit-*/Logs/Test/*.xcresult | head -1)
xcrun xcresulttool export attachments --path "$R" --output-path /tmp/perf
cat /tmp/perf/*.txt
```

Los techos de `Ceiling` están en ~5× de la tercera medición. A diferencia de la primera
versión, ahora sí protegen: el margen cubre la varianza entre máquinas, pero cualquier
regresión que devuelva un escaneo por día al dominio los rompe por orden de magnitud.

## Cobertura inicial

### Mutaciones de tracking

- Solo existe un estado principal por hábito y día.
- `.urge` se conserva al completar, descansar o actualizar cantidad.
- Slips y completitud desde sesión de enfoque conservan urges y metadata.
- Actualizar cantidades elimina estados principales duplicados.
- Un miss de recuperación no sobrescribe un estado existente.
- Completar un día elimina el freeze correspondiente.
- Aplicar freezes semanales no duplica uno ya existente.

### Dominio

- Scheduling por días específicos.
- El mínimo sostiene la racha sin contar como completado.
- El descanso sostiene la racha sin incrementarla.
- Un `.urge` no bloquea el prompt de recuperación.
- Los hábitos flexibles evalúan recuperación sobre semanas cerradas.

### Editor de planes

- El draft normaliza textos, fechas e hitos vacíos.
- Crear un plan persiste campos, hábitos vinculados e hitos normalizados.
- Editar un plan reconcilia hitos sin perder la completitud de los existentes.

## Convenciones

- Las fechas de prueba son fijas; no usar `.now` salvo que la regla bajo prueba dependa
  explícitamente del reloj.
- Las reglas de escritura se prueban a través de servicios de dominio.
- Los cálculos de solo lectura se prueban directamente sobre modelos.
- Cada bug corregido en tracking, scheduling, streaks, freezes o recovery debe incluir
  una prueba de regresión.

## Cómo creció la suite

| Momento | Tests |
|---|---:|
| Fase 2 del refactor — target, fixtures en memoria y regresiones iniciales | 13 |
| Fase 4 — `PlanDraft` y `PlanEditorService` | 16 |
| A1 — servicios de persistencia extraídos | 43 |
| A2 — colecciones de Today | 53 |
| Fase 1 del plan de mejoras — `OnboardingSetupService` | 70 |
| Índice por día — `HabitDayIndex` y sus pruebas de equivalencia | 81 |
| Fase 3 — `TodayViewData` y `TodayScreenModel` | 103 |
| Secuencia arrastrable de la Sesión de ritmo | 107 |

El detalle de qué cerró cada fase vive en el historial de git.
