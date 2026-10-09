<#
.SYNOPSIS
    Transcribe por lotes una carpeta de audios con Handy, de forma idempotente.

.DESCRIPTION
    Etapa 1 - Conversion (requiere ffmpeg):
        Cada audio de -SourceDir se convierte a WAV 16 kHz mono en -WavDir y
        el original se MUEVE a -ArchiveDir. Lo que ya se movio no se vuelve a
        convertir. Si una corrida anterior se corto despues de convertir pero
        antes de mover, solo se mueve el original.

    Etapa 2 - Transcripcion:
        Cada WAV de -WavDir se transcribe a <TextDir>\<modelo>\<nombre>.txt
        (UTF-8). Si ese .txt ya existe, el WAV se saltea (salvo -Force). Los
        WAV NO se mueven: se pueden transcribir de nuevo con otro modelo y
        cada modelo tiene su propia carpeta de textos.

    Idioma, palabras personalizadas y traduccion salen de la configuracion de
    la app Handy (no del script): si los cambias, usa -Force para regenerar.

    El script NO usa ni interrumpe la app abierta: lanza su propio proceso de
    Handy, que carga el modelo otra vez en memoria.

.PARAMETER Model
    Id del modelo, tal cual lo muestra: handy.exe --list-models

.PARAMETER SourceDir
    Bandeja de entrada con los audios originales.

.PARAMETER WorkDir
    Carpeta base para wav\, originales\ y transcripciones\. Por defecto, la
    carpeta que contiene a -SourceDir.

.PARAMETER Stage
    All (por defecto), Convert (solo etapa 1) o Transcribe (solo etapa 2).

.PARAMETER Force
    Transcribe aunque el .txt ya exista (lo reemplaza).

.PARAMETER SingleProcess
    Transcribe todos los pendientes en un solo proceso, cargando el modelo una
    vez por cada -BatchSize archivos. Requiere un Handy compilado desde este
    fork (acepta varios archivos en --transcribe-file y tiene --output-dir).

.EXAMPLE
    .\transcribe-batch.ps1 -SourceDir D:\audios\entrada -Model "handy-computer/whisper-large-v3-gguf/whisper-large-v3-Q5_K_M.gguf"

.EXAMPLE
    .\transcribe-batch.ps1 -SourceDir D:\audios\entrada -Model "handy-computer/canary-180m-flash-gguf/canary-180m-flash-Q8_0.gguf" -Stage Transcribe -Force

.NOTES
    Codigos de salida: 0 todo OK, 1 hubo al menos un archivo con error, 2 error
    de configuracion (rutas, modelo inexistente o no instalado, ffmpeg).
    El archivo es ASCII a proposito: Windows PowerShell 5.1 lee los .ps1 sin
    BOM como ANSI y romperia los acentos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Model,

    [Parameter(Mandatory = $true)]
    [string] $SourceDir,

    [string] $WorkDir,
    [string] $WavDir,
    [string] $ArchiveDir,
    [string] $TextDir,

    [string] $HandyPath = (Join-Path $env:LOCALAPPDATA 'Handy\handy.exe'),
    [string] $FfmpegPath = 'ffmpeg',

    [string[]] $Extensions = @(
        '.mp3', '.m4a', '.wav', '.ogg', '.opus', '.flac', '.aac', '.wma',
        '.amr', '.3gp', '.mp4', '.webm', '.mkv', '.mov'
    ),

    [ValidateSet('All', 'Convert', 'Transcribe')]
    [string] $Stage = 'All',

    [switch] $Force,
    [switch] $SingleProcess,

    [ValidateRange(1, 500)]
    [int] $BatchSize = 25
)

Set-StrictMode -Version Latest

function Fail([string] $Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 2
}

function Write-TextAtomic([string] $Path, [string] $Text) {
    # Escribir a .tmp y renombrar: un corte a mitad nunca deja un .txt
    # truncado que la proxima corrida tomaria como "ya transcripto".
    $tmp = "$Path.tmp"
    [System.IO.File]::WriteAllText($tmp, $Text, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

# --- Rutas -------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    Fail "No existe la carpeta de origen: $SourceDir"
}
$SourceDir = (Resolve-Path -LiteralPath $SourceDir).ProviderPath
if (-not $WorkDir) { $WorkDir = Split-Path -Parent $SourceDir }
if (-not $WavDir) { $WavDir = Join-Path $WorkDir 'wav' }
if (-not $ArchiveDir) { $ArchiveDir = Join-Path $WorkDir 'originales' }
if (-not $TextDir) { $TextDir = Join-Path $WorkDir 'transcripciones' }

# Los ids pueden traer "/" (handy-computer/whisper-.../...gguf): no son
# validos en un nombre de carpeta.
$modelFolder = $Model -replace '[\\/:*?"<>|]', '_'
$OutDir = Join-Path $TextDir $modelFolder
$tmpWavDir = Join-Path $WavDir '.tmp'

foreach ($dir in @($WavDir, $ArchiveDir, $tmpWavDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

if (-not (Test-Path -LiteralPath $HandyPath -PathType Leaf)) {
    Fail "No se encontro Handy en $HandyPath (usa -HandyPath)"
}

# Handy escribe UTF-8 por stdout; sin esto PowerShell lo lee con la pagina de
# codigos de la consola y rompe acentos y enies del texto transcripto.
$previousEncoding = $null
try {
    $previousEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
    # Sin consola (p. ej. lanzado por otro proceso): no hay nada que ajustar.
}

$converted = 0; $recovered = 0; $convertFailed = 0; $convertSkipped = 0
$transcribed = 0; $alreadyDone = 0; $transcribeFailed = 0

try {
    # --- Etapa 1: conversion -------------------------------------------------
    if ($Stage -in 'All', 'Convert') {
        $sources = @(Get-ChildItem -LiteralPath $SourceDir -File |
                Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() } |
                Sort-Object Name)

        if ($sources.Count -gt 0 -and -not (Get-Command $FfmpegPath -ErrorAction SilentlyContinue)) {
            Fail "No se encontro ffmpeg ($FfmpegPath). Instalalo con: winget install Gyan.FFmpeg"
        }

        # Nombre base -> archivo ya archivado. Las tablas hash de PowerShell
        # ignoran mayusculas, igual que el sistema de archivos de Windows.
        $archived = @{}
        Get-ChildItem -LiteralPath $ArchiveDir -File | ForEach-Object { $archived[$_.BaseName] = $_.Name }
        $seen = @{}

        foreach ($src in $sources) {
            $base = $src.BaseName
            $wavPath = Join-Path $WavDir "$base.wav"

            if ($seen.ContainsKey($base)) {
                Write-Warning "$($src.Name): mismo nombre que $($seen[$base]) en esta corrida. Renombralo; queda en la bandeja."
                $convertSkipped++; continue
            }
            $seen[$base] = $src.Name

            if ($archived.ContainsKey($base)) {
                Write-Warning "$($src.Name): ya hay un original archivado con ese nombre ($($archived[$base])). Renombralo; queda en la bandeja."
                $convertSkipped++; continue
            }

            if (Test-Path -LiteralPath $wavPath) {
                # Corrida anterior cortada entre convertir y archivar.
                Write-Host "[convertir] $($src.Name): el WAV ya existe, solo se archiva el original"
                $recovered++
            } else {
                Write-Host "[convertir] $($src.Name)"
                $tmpWav = Join-Path $tmpWavDir "$base.wav"
                & $FfmpegPath -nostdin -hide_banner -loglevel error -y -i $src.FullName -vn -ac 1 -ar 16000 -c:a pcm_s16le $tmpWav
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmpWav)) {
                    Write-Warning "$($src.Name): ffmpeg fallo (codigo $LASTEXITCODE); queda en la bandeja."
                    Remove-Item -LiteralPath $tmpWav -ErrorAction SilentlyContinue
                    $convertFailed++; continue
                }
                Move-Item -LiteralPath $tmpWav -Destination $wavPath
                $converted++
            }

            Move-Item -LiteralPath $src.FullName -Destination (Join-Path $ArchiveDir $src.Name)
            $archived[$base] = $src.Name
        }
    }

    # --- Etapa 2: transcripcion ----------------------------------------------
    if ($Stage -in 'All', 'Transcribe') {
        $wavs = @(Get-ChildItem -LiteralPath $WavDir -File |
                Where-Object { $_.Extension -eq '.wav' } |
                Sort-Object Name)
        $pending = @($wavs | Where-Object {
                $Force -or -not (Test-Path -LiteralPath (Join-Path $OutDir "$($_.BaseName).txt"))
            })
        $alreadyDone = $wavs.Count - $pending.Count

        if ($pending.Count -gt 0) {
            # Validar el modelo antes de procesar: un id mal escrito crearia
            # una carpeta de textos vacia y fallaria archivo por archivo.
            $modelsJson = & $HandyPath --list-models --json 2>$null | Out-String
            $models = @()
            try { $models = @($modelsJson | ConvertFrom-Json) } catch { }
            $info = $models | Where-Object { $_.id -eq $Model } | Select-Object -First 1
            if (-not $info) {
                Fail "El modelo '$Model' no existe. Lista los ids con: & '$HandyPath' --list-models | Out-String"
            }
            if (-not $info.is_downloaded) {
                Fail "El modelo '$Model' no esta descargado. Bajalo desde la app (Settings > Models)."
            }
            New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
        }

        Write-Host "[transcribir] modelo: $Model"
        Write-Host "[transcribir] pendientes: $($pending.Count) | ya transcriptos: $alreadyDone"

        if ($SingleProcess) {
            for ($i = 0; $i -lt $pending.Count; $i += $BatchSize) {
                $last = [Math]::Min($i + $BatchSize, $pending.Count) - 1
                $chunk = @($pending[$i..$last] | ForEach-Object { $_.FullName })
                $handyArgs = @('--model', $Model, '--output-dir', $OutDir, '--json', '-f') + $chunk
                $reported = 0
                & $HandyPath @handyArgs 2>$null | ForEach-Object {
                    if (-not $_.StartsWith('{')) { return }
                    $r = $_ | ConvertFrom-Json
                    $reported++
                    $name = Split-Path -Leaf $r.file
                    if ($r.PSObject.Properties['error']) {
                        Write-Warning "${name}: $($r.error)"
                        $script:transcribeFailed++
                    } else {
                        Write-Host ("[transcribir] {0}: {1:N0}s de audio en {2:N1}s" -f $name, $r.audio_secs, ($r.best_ms / 1000))
                        $script:transcribed++
                    }
                }
                if ($reported -lt $chunk.Count) {
                    # El proceso murio antes de reportar todo el lote.
                    Write-Warning "Handy termino con codigo $LASTEXITCODE sin reportar $($chunk.Count - $reported) archivo(s)."
                    $transcribeFailed += $chunk.Count - $reported
                }
            }
        } else {
            foreach ($wav in $pending) {
                Write-Host "[transcribir] $($wav.Name)"
                $lines = @(& $HandyPath -f $wav.FullName --model $Model --json 2>$null)
                $code = $LASTEXITCODE
                $jsonLine = $lines | Where-Object { "$_".StartsWith('{') } | Select-Object -Last 1
                if ($code -ne 0 -or -not $jsonLine) {
                    Write-Warning "$($wav.Name): Handy fallo (codigo $code). Para ver el detalle: & '$HandyPath' -f '$($wav.FullName)' --model '$Model' 2>&1 | Out-String"
                    $transcribeFailed++; continue
                }
                $r = $jsonLine | ConvertFrom-Json
                Write-TextAtomic -Path (Join-Path $OutDir "$($wav.BaseName).txt") -Text $r.text
                Write-Host ("               {0:N0}s de audio, carga {1:N1}s, transcripcion {2:N1}s" -f $r.audio_secs, ($r.load_ms / 1000), ($r.best_ms / 1000))
                $transcribed++
            }
        }
    }
} finally {
    if ($previousEncoding) {
        try { [Console]::OutputEncoding = $previousEncoding } catch { }
    }
}

Write-Host ''
Write-Host '=== Resumen ==='
if ($Stage -in 'All', 'Convert') {
    Write-Host "Convertidos: $converted | Recuperados: $recovered | Omitidos (nombre repetido): $convertSkipped | Fallidos: $convertFailed"
}
if ($Stage -in 'All', 'Transcribe') {
    Write-Host "Transcriptos: $transcribed | Ya existian: $alreadyDone | Fallidos: $transcribeFailed"
    Write-Host "Textos en: $OutDir"
}

if ($convertFailed -gt 0 -or $transcribeFailed -gt 0) { exit 1 }
exit 0
