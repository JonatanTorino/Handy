use anyhow::{anyhow, Context, Result};
use log::warn;
use std::fs::File;
use std::path::Path;
use std::time::Duration;
use symphonia::core::audio::SampleBuffer;
use symphonia::core::codecs::{DecoderOptions, CODEC_TYPE_NULL};
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

use super::FrameResampler;
use crate::audio_toolkit::constants::WHISPER_SAMPLE_RATE;

/// Decode an audio file (WAV of any rate/channels/bit depth, MP3, M4A/AAC,
/// FLAC, OGG/Vorbis) into the 16 kHz mono f32 samples the engines expect.
///
/// Multichannel audio is downmixed by averaging. Opus (WhatsApp voice notes)
/// is not supported by symphonia; convert those with ffmpeg first.
pub fn decode_audio_file<P: AsRef<Path>>(path: P) -> Result<Vec<f32>> {
    let path = path.as_ref();
    let file = File::open(path).with_context(|| format!("cannot open {}", path.display()))?;
    let mss = MediaSourceStream::new(Box::new(file), Default::default());

    let mut hint = Hint::new();
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        hint.with_extension(ext);
    }

    let probed = symphonia::default::get_probe()
        .format(
            &hint,
            mss,
            &FormatOptions::default(),
            &MetadataOptions::default(),
        )
        .map_err(|e| anyhow!("unsupported or unreadable audio format: {}", e))?;
    let mut format = probed.format;

    let track = format
        .tracks()
        .iter()
        .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
        .ok_or_else(|| anyhow!("no audio track found"))?;
    let track_id = track.id;
    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &DecoderOptions::default())
        .map_err(|e| anyhow!("unsupported audio codec: {}", e))?;

    let mut mono: Vec<f32> = Vec::new();
    let mut sample_rate: Option<u32> = None;
    let mut buf: Option<SampleBuffer<f32>> = None;

    loop {
        let packet = match format.next_packet() {
            Ok(packet) => packet,
            Err(SymphoniaError::IoError(e)) if e.kind() == std::io::ErrorKind::UnexpectedEof => {
                break
            }
            Err(e) => return Err(anyhow!("failed to read audio packet: {}", e)),
        };
        if packet.track_id() != track_id {
            continue;
        }

        let decoded = match decoder.decode(&packet) {
            Ok(decoded) => decoded,
            // A corrupt frame shouldn't sink the whole file; skip it.
            Err(SymphoniaError::DecodeError(e)) => {
                warn!("Skipping undecodable audio frame: {}", e);
                continue;
            }
            Err(e) => return Err(anyhow!("failed to decode audio: {}", e)),
        };

        let spec = *decoded.spec();
        match sample_rate {
            None => sample_rate = Some(spec.rate),
            Some(rate) if rate != spec.rate => {
                return Err(anyhow!(
                    "sample rate changes mid-stream ({} Hz -> {} Hz)",
                    rate,
                    spec.rate
                ));
            }
            Some(_) => {}
        }

        let needed = decoded.capacity() as u64;
        if buf.as_ref().is_none_or(|b| b.capacity() < needed as usize) {
            buf = Some(SampleBuffer::<f32>::new(needed, spec));
        }
        let buf = buf.as_mut().expect("sample buffer allocated above");
        buf.copy_interleaved_ref(decoded);

        let channels = spec.channels.count().max(1);
        mono.extend(
            buf.samples()
                .chunks_exact(channels)
                .map(|frame| frame.iter().sum::<f32>() / channels as f32),
        );
    }

    let Some(in_hz) = sample_rate else {
        return Err(anyhow!("file contains no audio"));
    };

    Ok(resample_to_whisper_rate(&mono, in_hz as usize))
}

fn resample_to_whisper_rate(samples: &[f32], in_hz: usize) -> Vec<f32> {
    let out_hz = WHISPER_SAMPLE_RATE as usize;
    if in_hz == out_hz || samples.is_empty() {
        return samples.to_vec();
    }

    let expected = (samples.len() as u64 * out_hz as u64 / in_hz as u64) as usize;
    let mut out = Vec::with_capacity(expected + out_hz / 10);
    let mut resampler = FrameResampler::new(in_hz, out_hz, Duration::from_millis(30));
    resampler.push(samples, |frame| out.extend_from_slice(frame));
    resampler.finish(|frame| out.extend_from_slice(frame));
    // finish() zero-pads the last frame; drop the padding.
    out.truncate(expected);
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use hound::{SampleFormat, WavSpec, WavWriter};

    fn write_wav(path: &Path, rate: u32, channels: u16, frames: usize) {
        let spec = WavSpec {
            channels,
            sample_rate: rate,
            bits_per_sample: 16,
            sample_format: SampleFormat::Int,
        };
        let mut writer = WavWriter::create(path, spec).unwrap();
        for i in 0..frames {
            let v = ((i as f32 * 0.05).sin() * 8000.0) as i16;
            for _ in 0..channels {
                writer.write_sample(v).unwrap();
            }
        }
        writer.finalize().unwrap();
    }

    #[test]
    fn decodes_16k_mono_wav_unchanged_in_length() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("a.wav");
        write_wav(&path, 16_000, 1, 16_000);
        let samples = decode_audio_file(&path).unwrap();
        assert_eq!(samples.len(), 16_000);
    }

    #[test]
    fn downmixes_and_resamples_44k_stereo_wav() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("b.wav");
        write_wav(&path, 44_100, 2, 44_100 * 2);
        let samples = decode_audio_file(&path).unwrap();
        assert_eq!(samples.len(), 32_000);
        assert!(samples.iter().any(|s| s.abs() > 0.1));
    }

    #[test]
    fn rejects_non_audio_file() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("c.mp3");
        std::fs::write(&path, b"definitely not audio").unwrap();
        assert!(decode_audio_file(&path).is_err());
    }
}
