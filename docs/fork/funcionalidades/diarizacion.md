# diarizacion

Marcar cada línea de la transcripción con su participante y permitir asignar
nombres a los participantes.

Depende de: [marcas-tiempo](marcas-tiempo.md).

## Estado

Última en el orden de trabajo (decidido 2026-10-13). Requiere una prueba de
concepto antes de comprometer un diseño.

## Hallazgos

- El catálogo incluye `MOSS-Transcribe-Diarize`, pero solo para inglés y
  chino: no sirve para español.
- `catalog/mod.rs` tiene un test que excluye a propósito los modelos de
  arquitectura `sortformer` ("producen segmentos de hablante, no texto"). Eso
  sugiere que transcribe-cpp los soporta; **no verificado**.
- Alternativa: sherpa-onnx (segmentación pyannote + embeddings de hablante, en
  ONNX).
- Piezas necesarias: segmentos con tiempos (marcas-tiempo), modelo de
  diarización, alineación de segmentos con hablantes, UI para nombrar
  participantes, formato de salida.

## Decisiones

| Fecha      | Decisión          | Motivo                        |
| ---------- | ----------------- | ----------------------------- |
| 2026-10-13 | Se hace al final. | Es la más incierta y difícil. |

## Próximo paso

Prueba de concepto con un audio de varios participantes (idealmente el mismo
usado en rendimiento).
