# WeekHabit

App iOS nativa para construir hábitos con ritmo semanal.

La tesis no es acumular rachas. Es cerrar el ciclo completo —**señal → acción → registro →
revisión → recuperación**— para que una intención se vuelva un sistema repetible, amable y
ajustable. La unidad emocional es la semana: siete días bastan para ver un patrón y son lo
bastante cortos para volver a intentar sin vergüenza.

Cuando un hábito no ocurre, la app no pregunta qué te pasa. Pregunta qué condición hizo
difícil que ocurriera.

<!-- TODO(#23): capturas de Hoy, Semana, Insights y Sesión de ritmo. -->

> **Capturas pendientes.** Van aquí, antes de cualquier texto técnico.

---

## Estado

Funcional y en uso. **No publicada en la App Store.** Desarrollo activo en este repo.

## Stack

Swift 5 · SwiftUI · SwiftData · UserNotifications · iOS 26.4+ · universal iPhone/iPad.

**Cero dependencias externas.** Sin SPM, sin CocoaPods, sin paquetes de terceros: todo está
resuelto con APIs nativas. Un proyecto Xcode único, `WeekHabit.xcodeproj`, con tres targets:
la app `WeekHabit`, la extensión de widget `WeekHabitWidgets` y las pruebas `WeekHabitTests`.
El código que app y widget comparten vive en `WeekHabitCore/`, una carpeta que ambos compilan
—no un paquete— para que nada tenga que volverse `public`.

~28 600 líneas de Swift en 262 archivos.

## Qué hace

- **Hábitos** de tipo check o por cantidad (minutos, páginas, km, vasos, repeticiones o unidad
  propia), con agenda diaria, por días específicos o flexible ("X veces por semana").
- **Hábitos para construir y para dejar.** No son el mismo flujo con distinto texto: los de
  dejar registran recaídas con su detonante, impulsos resistidos y hábito de reemplazo.
- **Registro del día** con progreso, día de descanso y versión mínima para días difíciles.
- **Vista de la semana** con grilla editable, registro retroactivo y consistencia.
- **Rachas honestas**: desglose entre días hechos, descansos intencionales y comodines usados,
  más un comodín semanal que evita que un día perdido borre el progreso.
- **Recuperación de lo que quedó sin marcar ayer**: una sola hoja con todos los pendientes
  del día anterior, contestables uno por uno. Pregunta el motivo en vez de romper la
  identidad que se está construyendo, y contestar siempre es opcional.
- **Planes** que agrupan hábitos bajo una meta con motivación, resultado medible, hitos y
  cierre revisado al terminar.
- **Sesiones de ritmo** con temporizador y secuencia ordenada de hábitos, arrastrable para
  reordenar.
- **Insights de 30 días**: consistencia, confianza del ritmo, mejor día, hora punta, hábito que
  necesita atención, horas pico de impulsos y experimentos de ritmo de 7 días con aplicar,
  mantener o revertir.
- **Revisión semanal** con una decisión por hábito y una reflexión escrita.
- **Recordatorios locales** por día activo, con la motivación del plan como cuerpo.
- **Una hoja de ayuda** en Hoy, que explica las cinco formas de registrar el día que no se
  descubren solas: versión mínima, descanso, comodín, slip e impulso.
- **Widget de pendientes** en la pantalla de bloqueo y en la de inicio, en cuatro tamaños.
  Nace de un problema concreto: la app no se abre porque se olvida, y al abrirla es ver la
  lista lo que empuja a actuar. En vez de traer al usuario, la lista va a donde ya mira.
  Distingue cuatro estados —con pendientes, día cerrado, descanso y sin hábitos— para que un
  día sin nada que hacer no se muestre como un cero que parece un fallo.

## Cómo correrlo

Requisitos: **Xcode 26.4 o superior** (desarrollado con 26.6) y el SDK de **iOS 26.4**. No
hay pasos de instalación de dependencias.

```bash
open WeekHabit.xcodeproj
```

Build de verificación sin firma de código:

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

Suite completa:

```bash
xcodebuild -project WeekHabit.xcodeproj \
  -scheme WeekHabit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Arquitectura

Arquitectura SwiftUI pragmática en cuatro capas: **Views → Feature State (drafts) → Domain
Services → SwiftData Models**. Las vistas leen con `@Query` y conservan navegación, animación
y haptics; los formularios complejos agrupan estado y validación en drafts de tipo valor; toda
mutación pasa por un servicio de dominio; y el cálculo puro vive en extensiones del modelo,
no en el layout.

Se evaluó migrar a Clean Architecture con MVVM y **se descartó con argumentos escritos**:
`@Query` no tiene reemplazo equivalente y mapear las entidades a structs puras costaría el
rendimiento que la carga perezosa de SwiftData hoy regala.

Tres decisiones que vale la pena mirar:

- **Asignar una propiedad de un `@Model` desde una vista también es una escritura**, aunque no
  se nombre `insert`, `delete` ni `save`: SwiftData la persiste por autosave. Auditar solo
  `modelContext.(insert|delete|save)` no alcanza — y encontrar eso costó una escritura
  implícita que el grep original no veía.
- **Schema de SwiftData versionado hasta `SchemaV17`**, con 16 etapas de migración
  encadenadas. Migraciones reales sobre datos de usuario, no borrar y recrear el store.
- **Un índice por día (`HabitDayIndex`) en vez de un caché.** La medición dijo que el problema
  no era recalcular sino escanear: `bestStreak` crecía 9,1× ante una entrada 3× mayor. El
  índice lo dejó en 3,0× y bajó la métrica de 2 478 ms a 8,11 ms.

Detalle completo en **[ARCHITECTURE.md](ARCHITECTURE.md)**.

## Pruebas

**143 casos en 21 suites**, cada uno contra un `ModelContainer` SwiftData en memoria
independiente. Cubren las transacciones de los servicios y las reglas de dominio; las vistas
no se prueban para demostrar reglas de negocio — cuando una regla es difícil de probar sin
renderizar, primero se extrae.

Incluye **`PerformanceBaselineTests`**, que mide cada métrica del dominio sobre dos tamaños de
dataset y reporta el **factor de crecimiento** entre ambos. Medir el factor y no solo el
milisegundo es lo que distingue un problema cuadrático de una constante alta, y es lo que
decidió el diseño del índice por día. Las cuatro mediciones sucesivas, con sus números, están
en **[TESTING.md](TESTING.md)**.

## Documentación

| Documento | Qué contiene |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Capas, reglas de escritura, dominio y estado de pantalla |
| [DOCUMENTATION.md](DOCUMENTATION.md) | Referencia técnica: modelos, servicios, pantallas y flujos |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Tokens, componentes y patrones de interacción |
| [TESTING.md](TESTING.md) | Estrategia de pruebas y mediciones de rendimiento |
| [IDENTIDAD_MISION.md](IDENTIDAD_MISION.md) | La brújula de producto: qué es y qué no es la app |

## Idioma

La UI, el copy y los comentarios están en **español (es_MX)**. Los identificadores de código
están en inglés.

En estados sensibles —fallos, recaídas, descansos, pausas— el copy nunca es punitivo y el
estilo destructivo se reserva para acciones que borran datos de verdad. Lo que el usuario
registra es información útil, no una falta.
