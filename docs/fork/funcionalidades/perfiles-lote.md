# perfiles-lote

Configuraciones de lote guardables (equivalente a los parámetros de
`scripts/transcribe-batch.ps1`), usables desde la UI y por monitor-carpetas.

Depende de: [conversion-archivos](conversion-archivos.md).

## Estado

Idea inicial (2026-10-11). Sin diseño.

## Parámetros del script y su destino

| Parámetro del script      | En el perfil                                           |
| ------------------------- | ------------------------------------------------------ |
| `Model`                   | Sí: modelo del perfil                                  |
| `SourceDir`               | Sí: carpeta de entrada (la usa monitor-carpetas)       |
| `TextDir`                 | Sí: carpeta de salida                                  |
| `Extensions`              | Sí: filtro de extensiones                              |
| `Force`                   | Sí: política si la salida ya existe                    |
| `ArchiveDir`              | Va a accion-original (opcional)                        |
| `WavDir`, `Stage`         | No: el decodificador nativo no necesita WAV intermedio |
| `BatchSize`               | No: dentro de la app el modelo queda cargado           |
| `HandyPath`, `FfmpegPath` | No: ffmpeg es configuración global (formatos-media)    |

## Decisiones

| Fecha      | Decisión                                                          | Motivo             |
| ---------- | ----------------------------------------------------------------- | ------------------ |
| 2026-10-13 | El modelo se define en el perfil.                                 | Ver cola-trabajos. |
| 2026-10-13 | Palabras personalizadas: diccionario global único, no por perfil. | Simplicidad.       |

## Preguntas abiertas

- Idioma: ¿por perfil o el global de la app? (Hoy es global; por perfil
  obliga a pasarlo como parámetro del trabajo.)

## Próximo paso

Esperar conversion-archivos.
