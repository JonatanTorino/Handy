# rendimiento

Medición de consumo de recursos por modelo, con foco en audios largos, antes
de diseñar cola-trabajos. Depende de: [cli-lotes](cli-lotes.md).

## Estado

Diseño propuesto (2026-10-13). Sin implementar.

## Por qué va primero

- El camino de transcripción de Handy se pensó para dictados cortos. No está
  verificado con 1 h de audio (memoria, tiempo, si algún modelo falla).
- La decodificación carga el audio completo en memoria (f32, 16 kHz):
  1 h ≈ 230 MB, y la CLI lo clona por ejecución.
- Los modelos ONNX (Parakeet, etc.) corren dentro del proceso de Handy; los de
  transcribe-cpp (familia Whisper) corren en un proceso hijo
  (`handy.exe --transcribe-worker`). Hay que medir el **árbol de procesos**.
- El resultado define la concurrencia por defecto de cola-trabajos y si hace
  falta partir audios largos en tramos.

## Diseño propuesto

Script `scripts/benchmark-transcription.ps1`, ejecutado en la máquina Windows
(el entorno cloud no tiene GPU ni modelos):

- Entrada: lista de modelos, lista de audios, repeticiones, concurrencia (1 o 2
  procesos simultáneos).
- Corre la CLI con `--json` y toma `load_ms`, `best_ms`, `rtf`, `audio_secs`,
  `bound_backend` y el texto.
- Muestrea cada 500 ms el árbol de procesos: memoria (working set, pico) y CPU;
  memoria de GPU con el contador de Windows
  `\GPU Process Memory(pid_*)\Dedicated Usage` (a verificar en esta máquina).
- Salida por prueba: `docs/fork/rendimiento/<fecha>-<modelo>.md` (informe
  legible) y `.json` (datos crudos), más el `.txt` transcripto para revisar
  calidad a mano.
- Informe: hardware (CPU, RAM, GPU, driver), modelo y cuantización, backend
  real, duración del audio, tiempo de carga, tiempo de transcripción, RTF,
  picos de RAM y VRAM, errores.

## Decisiones

| Fecha      | Decisión                                    | Motivo                                         |
| ---------- | ------------------------------------------- | ---------------------------------------------- |
| 2026-10-13 | Se mide antes de cualquier otro desarrollo. | Audios largos son el riesgo técnico principal. |
| 2026-10-13 | Un informe guardado por cada prueba.        | Comparar modelos con datos, no impresiones.    |

## Preguntas abiertas

- GPU (NVIDIA, AMD o Intel), RAM y CPU de la máquina.
- Modelos a comparar (ids de `--list-models`).
- Audios de prueba: duraciones (p. ej. 5, 30 y 60+ min), idioma, cantidad de
  participantes. Conviene incluir uno con varios participantes para
  diarizacion.
- ¿Se versionan los informes en el repo o quedan locales?

## Próximo paso

Responder las preguntas abiertas; después, implementar el script.
