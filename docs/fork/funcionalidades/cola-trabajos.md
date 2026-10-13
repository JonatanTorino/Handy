# cola-trabajos

Cola persistente de transcripción de archivos, con trabajadores en segundo
plano y registro propio de archivos de entrada y salida. Es la base de
conversion-archivos, perfiles-lote y monitor-carpetas.

Depende de: [cli-lotes](cli-lotes.md) (decodificación, escritura atómica).
Parámetros definidos por: [rendimiento](rendimiento.md).

## Estado

Decisiones iniciales tomadas (2026-10-13). Diseño detallado pendiente de
rendimiento.

## Hechos del código relevantes

- `TranscriptionManager` (dictado) tiene un único motor. Los modelos de
  transcribe-cpp corren en un proceso hijo administrado por `EngineSupervisor`
  (`engine_supervisor/mod.rs`); los ONNX corren dentro del proceso.
- Un trabajador de la cola puede tener su propio `EngineSupervisor` (otro
  proceso hijo con su propio modelo) sin tocar el motor del dictado. Un fallo
  del trabajador no tumba el dictado.
- Dos trabajadores en la misma GPU compiten por ella: más concurrencia no
  implica más velocidad. Se mide en rendimiento.

## Decisiones

| Fecha      | Decisión                                                                                                                        | Motivo                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 2026-10-13 | Resultado en una carpeta de salida elegida (como el script).                                                                    | Igual que el flujo actual del script.                                     |
| 2026-10-13 | Si empieza un dictado: el archivo en curso termina y la cola se pausa.                                                          | El dictado tiene prioridad y no se pierde trabajo hecho.                  |
| 2026-10-13 | El modelo se elige por perfil de lote, no el del dictado.                                                                       | Lotes y dictado tienen necesidades distintas.                             |
| 2026-10-13 | Trabajadores independientes, cada uno con su modelo cargado, aunque sea el mismo modelo.                                        | Aislamiento; reutiliza `EngineSupervisor`. Costo: memoria por trabajador. |
| 2026-10-13 | Registro propio (no el historial estándar): por trabajo, archivo de entrada, archivo de salida, modelo, estado, tiempos, error. | El historial es de upstream y rota entradas.                              |
| 2026-10-13 | Reanudación por archivo: al iniciar, los trabajos "en curso" vuelven a "pendiente".                                             | Retomar a mitad de un archivo no compensa la complejidad.                 |
| 2026-10-13 | El post-procesado con LLM queda fuera de la primera versión.                                                                    | Ver postproceso-llm.                                                      |

## Preguntas abiertas

- Almacenamiento del registro: SQLite propio (archivo separado del de
  historial) o JSON. Propuesta: SQLite, por consultas y escrituras atómicas.
- Concurrencia por defecto (tras rendimiento).
- ¿Hace falta partir audios largos en tramos? (tras rendimiento).
- Política de reintentos ante error (cantidad, y si "modelo no instalado" se
  reintenta o no).

## Próximo paso

Esperar resultados de rendimiento; luego, diseño detallado (estados, tabla,
comandos Tauri, eventos de progreso).
