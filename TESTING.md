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

## Estado de fases 2, 3 y 4

La fase 2 agregó el target, fixtures en memoria y 13 pruebas de regresión. La fase 3
dividió el dominio monolítico de `Habit` por responsabilidad. La fase 4 extrajo
`PlanDraft` y `PlanEditorService` y elevó la suite a 16 pruebas. La suite completa compila
y pasa en iOS Simulator.
