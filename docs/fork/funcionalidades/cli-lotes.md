# cli-lotes

Transcripción por lotes desde la línea de comandos. Rama
`feat/batch-file-transcription` (commit `22ee806`).

## Estado

Implementado. Compilado e instalado en Windows (2026-10-11). **Falta probarlo**
y mergearlo a `main`.

## Qué provee (servicios que usan otras funcionalidades)

- `audio_toolkit/audio/decode.rs`: decodifica WAV/MP3/M4A/AAC/FLAC/OGG y
  remuestrea a 16 kHz mono (`decode_audio_file`). Lo usan cola-trabajos y
  formatos-media.
- Escritura atómica del `.txt` (`.tmp` + rename): un corte nunca deja un texto
  truncado que parezca terminado.
- Una carga de modelo para varios archivos; un archivo fallido no corta el lote.
- `--json` con métricas por archivo (`load_ms`, `best_ms`, `rtf`,
  `audio_secs`, `bound_backend`): base de rendimiento.
- `scripts/transcribe-batch.ps1`: flujo de carpeta idempotente. Sus parámetros
  son el punto de partida de perfiles-lote.

## Cómo probarlo (Windows, PowerShell)

`handy.exe` en release es una aplicación de ventana (`main.rs:2`,
`windows_subsystem = "windows"`): su salida solo se ve si se redirige.

```powershell
$handy = "$env:LOCALAPPDATA\Handy\handy.exe"
& $handy --help | Out-Host
& $handy --list-models | Out-Host
& $handy -f C:\pruebas\a.mp3 C:\pruebas\b.m4a --model "<id>" --json | Out-Host
& $handy -f C:\pruebas\a.mp3 --model "<id>" --output-dir C:\pruebas\txt | Out-Host
pwsh -File .\scripts\transcribe-batch.ps1 -SourceDir C:\pruebas\entrada -Model "<id>" -SingleProcess
```

El script **mueve los originales** a `originales\` y su etapa 1 requiere
ffmpeg (`-Stage Transcribe` la saltea). Probar con copias.

## Decisiones

| Fecha      | Decisión                                                       | Motivo                            |
| ---------- | -------------------------------------------------------------- | --------------------------------- |
| 2026-10-13 | Se mergea a `main` antes de empezar las demás funcionalidades. | Casi todas usan su decodificador. |

## Preguntas abiertas

- Resultado de la prueba en Windows (CLI y script).

## Próximo paso

Probar con los comandos de arriba; si funciona, squash merge a `main`.
