#!/usr/bin/env python3
"""
Generate speech audio from kiran text files using Gemini TTS.

Reference:
https://ai.google.dev/gemini-api/docs/speech-generation

Requirements:
  pip install google-genai
  export GEMINI_API_KEY=your_api_key

Examples:
  # Convert first few kirans from previously exported text files
  python3 scripts/gemini_tts_from_kiran_txt.py \
    --input scripts/tts_output/part1/kiran_1.txt scripts/tts_output/part1/kiran_2.txt

  # Use a glob and custom voice/model
  python3 scripts/gemini_tts_from_kiran_txt.py \
    --glob "scripts/tts_output/part1/kiran_*.txt" \
    --voice Kore \
    --model gemini-2.5-flash-preview-tts \
    --out-dir scripts/tts_audio/part1

  # Dry run (shows what would be processed, no API calls)
  python3 scripts/gemini_tts_from_kiran_txt.py \
    --glob "scripts/tts_output/part1/kiran_*.txt" --dry-run
"""

from __future__ import annotations

import argparse
import glob
import os
import random
import sys
import time
import wave
from pathlib import Path
from typing import Iterable

try:
    from google import genai
    from google.genai import types
except ImportError:
    genai = None
    types = None


MODEL_PRICING_PER_1M = {
    "gemini-2.5-flash-preview-tts": {"input": 0.50, "output": 10.00},
    "gemini-2.5-pro-preview-tts": {"input": 1.00, "output": 20.00},
}


def write_wave_file(filename: Path, pcm: bytes, channels: int = 1, rate: int = 24000, sample_width: int = 2) -> None:
    """Write raw PCM bytes to a .wav file."""
    filename.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(filename), "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(sample_width)
        wf.setframerate(rate)
        wf.writeframes(pcm)


def build_prompt(text: str, style_prompt: str | None) -> str:
    """Build final TTS prompt with optional style directive."""
    cleaned = text.strip()
    if not style_prompt:
        return cleaned

    return (
        f"{style_prompt.strip()}\n\n"
        f"Speak the following text exactly as written in Gujarati:\n"
        f"{cleaned}"
    )


def discover_inputs(explicit_inputs: Iterable[str], glob_pattern: str | None) -> list[Path]:
    paths: list[Path] = []
    for p in explicit_inputs:
        paths.append(Path(p))

    if glob_pattern:
        for p in sorted(glob.glob(glob_pattern)):
            paths.append(Path(p))

    # De-duplicate while preserving order
    seen = set()
    ordered_unique: list[Path] = []
    for p in paths:
        key = str(p.resolve()) if p.exists() else str(p)
        if key in seen:
            continue
        seen.add(key)
        ordered_unique.append(p)

    return ordered_unique


def generate_audio_for_file(
    client: "genai.Client",
    model: str,
    voice: str,
    input_txt: Path,
    output_wav: Path,
    style_prompt: str | None,
) -> None:
    text = input_txt.read_text(encoding="utf-8")
    prompt = build_prompt(text, style_prompt)

    response = client.models.generate_content(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["AUDIO"],
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                        voice_name=voice,
                    )
                )
            ),
        ),
    )

    data = response.candidates[0].content.parts[0].inline_data.data
    write_wave_file(output_wav, data)


def is_retryable_error(exc: Exception) -> bool:
    """Return True for transient API errors where retry usually helps."""
    msg = str(exc).upper()
    retry_markers = [
        "503",
        "UNAVAILABLE",
        "429",
        "RESOURCE_EXHAUSTED",
        "INTERNAL",
        "DEADLINE_EXCEEDED",
        "TIMEOUT",
    ]
    return any(marker in msg for marker in retry_markers)


def generate_audio_with_retry(
    client: "genai.Client",
    models: list[str],
    voice: str,
    input_txt: Path,
    output_wav: Path,
    style_prompt: str | None,
    max_retries: int,
    initial_backoff: float,
    max_backoff: float,
) -> str:
    """
    Try model(s) with retries and exponential backoff.

    Returns the model name that succeeded.
    """
    last_exc: Exception | None = None

    for model in models:
        for attempt in range(max_retries + 1):
            try:
                generate_audio_for_file(
                    client=client,
                    model=model,
                    voice=voice,
                    input_txt=input_txt,
                    output_wav=output_wav,
                    style_prompt=style_prompt,
                )
                return model
            except Exception as exc:
                last_exc = exc
                can_retry = is_retryable_error(exc) and attempt < max_retries
                if not can_retry:
                    break

                # Exponential backoff with small jitter.
                delay = min(initial_backoff * (2 ** attempt), max_backoff)
                delay *= random.uniform(0.8, 1.2)
                print(
                    f"[retry] {input_txt.name} model={model} attempt={attempt + 1}/{max_retries} in {delay:.1f}s due to: {exc}",
                    file=sys.stderr,
                )
                time.sleep(delay)

    if last_exc is None:
        raise RuntimeError("TTS generation failed with unknown error")
    raise last_exc


def prompt_character_count(input_files: list[Path], style_prompt: str | None) -> int:
    total = 0
    for path in input_files:
        text = path.read_text(encoding="utf-8")
        total += len(build_prompt(text, style_prompt))
    return total


def estimate_cost_range(
    prompt_chars: int,
    input_price_per_1m: float,
    output_price_per_1m: float,
    audio_tokens_per_second: float,
    chars_per_second_likely: float,
) -> dict:
    """
    Rough estimator:
    - Input tokens estimated from characters with a small range.
    - Output duration estimated from chars/sec speaking speed.
    - Output tokens estimated from tokens/sec.
    """
    # Rough Gujarati tokenization range (chars per token):
    # min cost = more chars/token, max cost = fewer chars/token.
    chars_per_token_min_cost = 2.0
    chars_per_token_likely = 1.5
    chars_per_token_max_cost = 1.0

    input_tokens_min = prompt_chars / chars_per_token_min_cost
    input_tokens_likely = prompt_chars / chars_per_token_likely
    input_tokens_max = prompt_chars / chars_per_token_max_cost

    # Speaking speed range around likely.
    cps_slow = max(6.0, chars_per_second_likely * 0.8)
    cps_fast = chars_per_second_likely * 1.2

    duration_sec_max = prompt_chars / cps_slow
    duration_sec_likely = prompt_chars / chars_per_second_likely
    duration_sec_min = prompt_chars / cps_fast

    output_tokens_min = duration_sec_min * audio_tokens_per_second
    output_tokens_likely = duration_sec_likely * audio_tokens_per_second
    output_tokens_max = duration_sec_max * audio_tokens_per_second

    input_cost_min = (input_tokens_min / 1_000_000) * input_price_per_1m
    input_cost_likely = (input_tokens_likely / 1_000_000) * input_price_per_1m
    input_cost_max = (input_tokens_max / 1_000_000) * input_price_per_1m

    output_cost_min = (output_tokens_min / 1_000_000) * output_price_per_1m
    output_cost_likely = (output_tokens_likely / 1_000_000) * output_price_per_1m
    output_cost_max = (output_tokens_max / 1_000_000) * output_price_per_1m

    return {
        "input_tokens": (input_tokens_min, input_tokens_likely, input_tokens_max),
        "output_tokens": (output_tokens_min, output_tokens_likely, output_tokens_max),
        "duration_hours": (
            duration_sec_min / 3600,
            duration_sec_likely / 3600,
            duration_sec_max / 3600,
        ),
        "input_cost": (input_cost_min, input_cost_likely, input_cost_max),
        "output_cost": (output_cost_min, output_cost_likely, output_cost_max),
        "total_cost": (
            input_cost_min + output_cost_min,
            input_cost_likely + output_cost_likely,
            input_cost_max + output_cost_max,
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate WAV TTS from kiran TXT files via Gemini API")
    parser.add_argument(
        "--input",
        nargs="*",
        default=[],
        help="One or more input .txt files (e.g., scripts/tts_output/part1/kiran_1.txt)",
    )
    parser.add_argument(
        "--glob",
        default=None,
        help="Glob pattern for input files (e.g., scripts/tts_output/part1/kiran_*.txt)",
    )
    parser.add_argument(
        "--out-dir",
        default="scripts/tts_audio",
        help="Output directory for .wav files",
    )
    parser.add_argument(
        "--model",
        default="gemini-2.5-flash-preview-tts",
        help="Gemini TTS model name",
    )
    parser.add_argument(
        "--fallback-models",
        nargs="*",
        default=["gemini-2.5-pro-preview-tts"],
        help="Optional fallback model(s) if primary model is unavailable",
    )
    parser.add_argument(
        "--voice",
        default="Enceladus",
        help="Prebuilt voice name (e.g., Kore, Puck, Enceladus)",
    )
    parser.add_argument(
        "--style-prompt",
        default="Speak in a clear, devotional, calm Gujarati narration style.",
        help="Optional directing prompt prepended before text",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned input/output files without calling the API",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=5,
        help="Retries per model for transient errors (default: 5)",
    )
    parser.add_argument(
        "--initial-backoff",
        type=float,
        default=2.0,
        help="Initial backoff in seconds (default: 2.0)",
    )
    parser.add_argument(
        "--max-backoff",
        type=float,
        default=30.0,
        help="Max backoff in seconds (default: 30.0)",
    )
    parser.add_argument(
        "--estimate-cost",
        action="store_true",
        help="Print rough generation cost estimate before running",
    )
    parser.add_argument(
        "--estimate-only",
        action="store_true",
        help="Only print rough cost estimate and exit",
    )
    parser.add_argument(
        "--input-price-per-1m",
        type=float,
        default=None,
        help="Override input text token price per 1M tokens",
    )
    parser.add_argument(
        "--output-price-per-1m",
        type=float,
        default=None,
        help="Override output audio token price per 1M tokens",
    )
    parser.add_argument(
        "--audio-tokens-per-second",
        type=float,
        default=25.0,
        help="Estimated audio output tokens per second (default: 25)",
    )
    parser.add_argument(
        "--chars-per-second",
        type=float,
        default=14.0,
        help="Likely speaking speed for duration estimate (default: 14 chars/sec)",
    )

    args = parser.parse_args()

    input_files = discover_inputs(args.input, args.glob)
    if not input_files:
        print("No input files found. Provide --input and/or --glob.", file=sys.stderr)
        return 1

    missing = [p for p in input_files if not p.exists()]
    if missing:
        print("These input files do not exist:", file=sys.stderr)
        for p in missing:
            print(f"  - {p}", file=sys.stderr)
        return 1

    out_dir = Path(args.out_dir)

    models = [args.model] + [m for m in args.fallback_models if m and m != args.model]

    pricing = MODEL_PRICING_PER_1M.get(args.model, {"input": 0.50, "output": 10.00})
    input_price_per_1m = args.input_price_per_1m if args.input_price_per_1m is not None else pricing["input"]
    output_price_per_1m = args.output_price_per_1m if args.output_price_per_1m is not None else pricing["output"]

    print(f"Models: {', '.join(models)}")
    print(f"Voice: {args.voice}")
    print(f"Files: {len(input_files)}")

    for in_file in input_files:
        out_file = out_dir / f"{in_file.stem}.wav"
        print(f"  {in_file} -> {out_file}")

    if args.estimate_cost or args.estimate_only:
        prompt_chars = prompt_character_count(input_files, args.style_prompt)
        est = estimate_cost_range(
            prompt_chars=prompt_chars,
            input_price_per_1m=input_price_per_1m,
            output_price_per_1m=output_price_per_1m,
            audio_tokens_per_second=args.audio_tokens_per_second,
            chars_per_second_likely=args.chars_per_second,
        )

        print("")
        print("Rough cost estimate:")
        print(f"  Prompt characters: {prompt_chars:,}")
        print(f"  Pricing per 1M tokens: input=${input_price_per_1m:.2f}, output=${output_price_per_1m:.2f}")
        print(
            "  Input tokens (min/likely/max): "
            f"{est['input_tokens'][0]:,.0f} / {est['input_tokens'][1]:,.0f} / {est['input_tokens'][2]:,.0f}"
        )
        print(
            "  Output tokens (min/likely/max): "
            f"{est['output_tokens'][0]:,.0f} / {est['output_tokens'][1]:,.0f} / {est['output_tokens'][2]:,.0f}"
        )
        print(
            "  Audio hours (min/likely/max): "
            f"{est['duration_hours'][0]:.2f} / {est['duration_hours'][1]:.2f} / {est['duration_hours'][2]:.2f}"
        )
        print(
            "  Estimated total cost USD (min/likely/max): "
            f"${est['total_cost'][0]:.2f} / ${est['total_cost'][1]:.2f} / ${est['total_cost'][2]:.2f}"
        )

    if args.estimate_only:
        return 0

    if args.dry_run:
        return 0

    if genai is None or types is None:
        print("Missing dependency: google-genai", file=sys.stderr)
        print("Install with: pip install google-genai", file=sys.stderr)
        return 1

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY is not set.", file=sys.stderr)
        print("Set it with: export GEMINI_API_KEY=your_api_key", file=sys.stderr)
        return 1

    client = genai.Client(api_key=api_key)

    failures = 0
    for in_file in input_files:
        out_file = out_dir / f"{in_file.stem}.wav"
        try:
            used_model = generate_audio_with_retry(
                client=client,
                models=models,
                voice=args.voice,
                input_txt=in_file,
                output_wav=out_file,
                style_prompt=args.style_prompt,
                max_retries=args.max_retries,
                initial_backoff=args.initial_backoff,
                max_backoff=args.max_backoff,
            )
            print(f"[ok] {out_file} (model={used_model})")
        except Exception as exc:
            failures += 1
            print(f"[err] {in_file}: {exc}", file=sys.stderr)

    return 0 if failures == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
