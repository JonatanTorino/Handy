use clap::Parser;
use std::path::PathBuf;

#[derive(Parser, Debug, Clone, Default)]
#[command(name = "handy", about = "Handy - Speech to Text")]
pub struct CliArgs {
    /// Start with the main window hidden
    #[arg(long)]
    pub start_hidden: bool,

    /// Disable the system tray icon
    #[arg(long)]
    pub no_tray: bool,

    /// Toggle transcription on/off (sent to running instance)
    #[arg(long)]
    pub toggle_transcription: bool,

    /// Toggle transcription with post-processing on/off (sent to running instance)
    #[arg(long)]
    pub toggle_post_process: bool,

    /// Cancel the current operation (sent to running instance)
    #[arg(long)]
    pub cancel: bool,

    /// Enable debug mode with verbose logging
    #[arg(long)]
    pub debug: bool,

    /// Transcribe these audio files headlessly and exit (WAV, MP3, M4A/AAC,
    /// FLAC, OGG/Vorbis; any sample rate or channel count). The model is
    /// loaded once for the whole list. Runs the same batch transcription path
    /// as the app — no mic, no VAD, no download (the model must already be
    /// installed). A failed file is reported and the rest still run.
    #[arg(short = 'f', long, value_name = "AUDIO", num_args = 1..)]
    pub transcribe_file: Vec<PathBuf>,

    /// With --transcribe-file: write each transcript as UTF-8 to
    /// `<DIR>/<file stem>.txt` (created if missing). Files are written
    /// atomically, so a crash never leaves a truncated transcript behind.
    #[arg(long, value_name = "DIR", requires = "transcribe_file")]
    pub output_dir: Option<PathBuf>,

    /// Model id to load for --transcribe-file (default: the selected model).
    #[arg(long)]
    pub model: Option<String>,

    /// Hard-select the compute device for --transcribe-file by its registry
    /// index (see --list-devices). Omit to use the persisted accelerator
    /// setting. transcribe-cpp (whisper-family) models only.
    #[arg(long, value_name = "N")]
    pub device_index: Option<usize>,

    /// List the transcribe-cpp compute devices (with indices) and exit.
    #[arg(long)]
    pub list_devices: bool,

    /// List the available models (with ids) and exit. Pass an id to --model.
    /// Honors --json for machine-readable output.
    #[arg(long)]
    pub list_models: bool,

    /// Repeat the transcription N times (best_ms reports the fastest run).
    #[arg(long, value_name = "N")]
    pub repeat: Option<usize>,

    /// Emit --transcribe-file results as JSON, one object per line per file.
    #[arg(long)]
    pub json: bool,
}
