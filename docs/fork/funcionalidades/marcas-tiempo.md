# marcas-tiempo

Obtener del motor la transcripción con segmentos y sus tiempos de inicio y fin,
no solo el texto plano. Base de subtitulos y diarizacion.

Depende de: [cola-trabajos](cola-trabajos.md).

## Estado

Identificada (2026-10-13). Sin investigar.

## Hechos del código

- `TranscriptionManager::transcribe` devuelve solo `String`.
- El catálogo declara por modelo la capacidad `timestamps` (p. ej.
  `"segment"`), así que algunos motores los producen. Falta ver qué exponen
  transcribe-cpp y transcribe-rs.

## Preguntas abiertas

- Qué modelos devuelven segmentos y con qué granularidad (segmento o palabra).

## Próximo paso

Investigar las APIs de transcribe-cpp y transcribe-rs.
