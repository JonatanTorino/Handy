# formatos-media

Formatos de audio y video aceptados: soporte nativo documentado y ffmpeg
opcional para extenderlo (extracción de la pista de audio de videos).

Depende de: [cli-lotes](cli-lotes.md) (decodificador nativo).

## Estado

Requisitos tomados (2026-10-13). Sin diseño detallado.

## Soporte nativo actual (symphonia, según `Cargo.toml` de cli-lotes)

| Contenedor               | Códecs de audio            | Estado                      |
| ------------------------ | -------------------------- | --------------------------- |
| WAV                      | PCM                        | Soportado                   |
| FLAC                     | FLAC                       | Soportado                   |
| OGG                      | Vorbis                     | Soportado (Opus **no**)     |
| MP3                      | MP3                        | Soportado                   |
| MP4 / M4A                | AAC                        | Soportado                   |
| MP4 / MOV / M4V (video)  | AAC                        | Probable, **sin verificar** |
| MKV / WebM, AVI, WMA/ASF | Opus, AC3/E-AC3, WMA, ALAC | No soportado                |

Candidatos baratos a verificar: activar en symphonia los features `mkv`,
`alac` y `adpcm`. Opus (el audio habitual de WebM) no tiene decodificador en
symphonia 0.5: requiere ffmpeg o una biblioteca aparte.

## Requisitos

- Configuración: ruta de ffmpeg, con opción de descarga/instalación asistida.
- Si ffmpeg está configurado, se usa para lo que el decodificador nativo no
  soporte (y para extraer el audio de videos).
- La UI y la documentación muestran qué formatos son nativos y cuáles
  requieren ffmpeg.

## Decisiones

| Fecha      | Decisión                                                     | Motivo                                      |
| ---------- | ------------------------------------------------------------ | ------------------------------------------- |
| 2026-10-13 | Nativo primero; ffmpeg como extensión opcional configurable. | Sin dependencias externas para lo habitual. |

## Preguntas abiertas

- Descarga asistida: ¿`winget install Gyan.FFmpeg` o descarga directa de un
  build? (Licencia: los builds completos de ffmpeg son GPL; descargarlo a
  pedido del usuario evita redistribuirlo dentro del instalador.)
- Videos con varias pistas de audio: ¿la pista por defecto, o elegible?

## Próximo paso

Verificar MP4/MOV de video con el decodificador nativo (puede hacerse con la
CLI de cli-lotes) y decidir la descarga asistida.
