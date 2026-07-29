#!/usr/bin/env bash
# trim-to-transient.sh — turn a raw generation into a shippable UI sound.
#
# ElevenLabs cannot generate below 0.5s, and what comes back is padded
# with silence and a room tail. This finds the first onset, cuts from
# just before it, normalises, and writes mono 44.1kHz mp3 (SKILL.md §3).
#
#   ./trim-to-transient.sh candidate.mp3 public/sfx/click.mp3 0.06
#
# Args: <input> <output> [duration-seconds, default 0.12]
# Diagnostics to stderr; the output path to stdout.

set -euo pipefail

IN="${1:-}"
OUT="${2:-}"
DUR="${3:-0.12}"

if [[ -z "$IN" || -z "$OUT" ]]; then
  echo "usage: trim-to-transient.sh <input> <output> [duration-seconds]" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found — install it (brew install ffmpeg)" >&2
  exit 1
fi

if [[ ! -f "$IN" ]]; then
  echo "not found: $IN" >&2
  exit 1
fi

# Where does the audio actually start?
#
# Two ways to answer, and the cheap one is wrong often enough to
# matter. silencedetect reports silences below a fixed dB threshold;
# a generated clip frequently opens with 30-60ms of room tone that
# is quiet but not "silent", so silencedetect skips it and reports
# the first real gap instead — which is *after* the transient you
# want. Cutting there throws away the sound and keeps the decay.
#
# The reliable answer is relative to the clip's own peak: the onset
# is the first sample above 8% of it. That needs to decode the file,
# so it falls back to silencedetect if node is unavailable.
if command -v node >/dev/null 2>&1; then
  RAW="$(mktemp -t trimonset)"
  trap 'rm -f "$RAW"' EXIT
  ffmpeg -v error -y -i "$IN" -ac 1 -ar 44100 -f f32le "$RAW"
  ONSET="$(node -e '
    const fs = require("fs");
    const b = fs.readFileSync(process.argv[1]);
    const d = new Float32Array(b.buffer, b.byteOffset, b.length / 4);
    let peak = 0;
    for (let i = 0; i < d.length; i++) peak = Math.max(peak, Math.abs(d[i]));
    let onset = 0;
    for (let i = 0; i < d.length; i++) {
      if (Math.abs(d[i]) > peak * 0.08) { onset = i; break; }
    }
    process.stdout.write((onset / 44100).toFixed(4));
  ' "$RAW")"
  echo "onset ${ONSET}s (8% of peak)" >&2
else
  SILENCE="$(ffmpeg -hide_banner -i "$IN" -af "silencedetect=noise=-45dB:d=0.02" -f null - 2>&1 || true)"
  FIRST_START="$(echo "$SILENCE" | awk '/silence_start/ {print $5; exit}')"
  FIRST_END="$(echo "$SILENCE" | awk '/silence_end/ {print $5; exit}')"
  if [[ -z "${FIRST_START:-}" ]] || awk -v s="${FIRST_START:-1}" 'BEGIN { exit !(s > 0.01) }'; then
    ONSET=0
  else
    ONSET="${FIRST_END:-0}"
  fi
  echo "no node; silencedetect says ${ONSET}s (may miss a quiet head)" >&2
fi

# Back up 4ms so the attack itself is never clipped. Clipping the
# attack is what makes a click sound like a thud.
START="$(awk -v o="$ONSET" 'BEGIN { s = o - 0.004; if (s < 0) s = 0; printf "%.4f", s }')"
FADE="$(awk -v d="$DUR" 'BEGIN { printf "%.4f", (d > 0.02 ? d - 0.012 : d / 2) }')"

mkdir -p "$(dirname "$OUT")"

# Fade only at the tail: a fade-in would soften the transient, which
# is the entire sound. Compress lightly and limit so short clips reach
# a usable level without clipping.
ffmpeg -v error -y -ss "$START" -t "$DUR" -i "$IN" \
  -af "afade=t=out:st=${FADE}:d=0.012,acompressor=threshold=-24dB:ratio=3:attack=1:release=80:makeup=4,alimiter=limit=0.95" \
  -ac 1 -ar 44100 -b:a 96k "$OUT"

BYTES="$(wc -c < "$OUT" | tr -d ' ')"
echo "onset ${ONSET}s · cut from ${START}s · ${DUR}s · ${BYTES} bytes" >&2
echo "$OUT"
