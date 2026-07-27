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

Última validación conocida (2026-07-27): **71 tests passed** en
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
- `OnboardingSetupService`, agregado en la Fase 1 de `docs/PLAN_MEJORAS.md`:
  - título de respaldo y motivación nula cuando el texto viene vacío;
  - normalización de espacios y fecha de fin a 30 días en start-of-day;
  - reutilización del plan existente en vez de crear un segundo;
  - alta y baja de hábitos de plantilla ligados al plan;
  - guardado diferido: las mutaciones quedan pendientes hasta `commit`.
- `HabitTrackingService.commitRecoveryMiss`: aplica la versión mínima y persiste.
- `PerformanceBaselineTests`, agregado en la Fase 2 de `docs/PLAN_MEJORAS.md`. Ver abajo.

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

La decisión que salió de estos números está en `docs/PLAN_MEJORAS.md`.

### Cómo volver a medirlos

Los `print` solo se ven corriendo desde Xcode. Desde consola, cada medición queda además
como attachment dentro del `.xcresult`:

```bash
R=$(ls -td ~/Library/Developer/Xcode/DerivedData/WeekHabit-*/Logs/Test/*.xcresult | head -1)
xcrun xcresulttool export attachments --path "$R" --output-path /tmp/perf
cat /tmp/perf/*.txt
```

Los techos de `Ceiling` están en ~5× lo medido y son **provisionales**: 5× de una línea base
mala no protege mucho. Hay que apretarlos cuando se implemente el índice por día.

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

## Estado histórico de fases 2, 3 y 4

La fase 2 agregó el target, fixtures en memoria y 13 pruebas de regresión. La fase 3
dividió el dominio monolítico de `Habit` por responsabilidad. La fase 4 extrajo
`PlanDraft` y `PlanEditorService`, y elevó la suite a 16 pruebas. La suite completa compila
y pasa en iOS Simulator.
