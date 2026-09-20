#!/usr/bin/env python3
"""Build grounded Gujarati MCQs from kiran JSON. No external model."""

from __future__ import annotations

import hashlib
import re
from html import unescape

from kiran_quiz_bank import (
    iter_kirans,
    kiran_meta,
    load_haribhakt_index,
    source_payload,
    strip_html,
)

PLACEHOLDERS = {
    "places": ["\u0aaa\u0ac0\u0aaa\u0ab2\u0abe\u0aa3\u0abe", "\u0aae\u0abe\u0aa3\u0abe\u0ab5\u0aa6\u0ab0", "\u0a9c\u0ac2\u0aa8\u0abe\u0a97\u0aa2", "\u0ab5\u0a82\u0aa5\u0ab2\u0ac0", "\u0a97\u0aa2\u0aa1\u0abe", "\u0ab5\u0aa1\u0aa4\u0abe\u0ab2"],
    "names": ["\u0ab8\u0acd\u0ab5\u0abe\u0aae\u0ac0", "\u0ab9\u0ab0\u0abf\u0aad\u0a95\u0acd\u0aa4", "\u0ab8\u0a82\u0aa4", "\u0aaf\u0a9c\u0aae\u0abe\u0aa8", "\u0ab5\u0abe\u0a9a\u0a95", "\u0aae\u0ab9\u0abe\u0ab0\u0abe\u0a9c"],
    "titles": ["\u0aac\u0acd\u0ab0\u0ab9\u0acd\u0aae\u0ab0\u0ac2\u0aaa \u0aa5\u0ab5\u0abe\u0aa8\u0ac1\u0a82", "\u0aa7\u0ab0\u0acd\u0aae\u0aa8\u0abf\u0ab7\u0acd\u0aa0\u0abe\u0aa8\u0ac1\u0a82", "\u0ab8\u0aa4\u0acd\u0ab8\u0a82\u0a97\u0aa8\u0ac1\u0a82", "\u0ab5\u0ac8\u0ab0\u0abe\u0a97\u0acd\u0aaf\u0aa8\u0ac1\u0a82"],
    "samvats": ["\u0ab8\u0a82\u0ab5\u0aa4\u0acd  \u0ae8\u0ae6\u0ae9\u0ae7", "\u0ab8\u0a82\u0ab5\u0aa4\u0acd  \u0ae8\u0ae6\u0ae9\u0ae8", "\u0ab8\u0a82\u0ab5\u0aa4\u0acd  \u0ae8\u0ae6\u0ae9\u0ae9", "\u0ab8\u0a82\u0ab5\u0aa4\u0acd  \u0ae8\u0ae6\u0ae9\u0aea"],
    "tithis": ["\u0a9c\u0ac7\u0aa0 \u0ab8\u0ac1\u0aa6\u0abf-\u0aef", "\u0ab5\u0ac8\u0ab6\u0abe\u0a96 \u0ab8\u0ac1\u0aa6\u0abf-\u0ae7\u0ae6", "\u0ab6\u0acd\u0ab0\u0abe\u0ab5\u0aa3 \u0ab5\u0aa6\u0abf-\u0ae7", "\u0aad\u0abe\u0aa6\u0ab0\u0ab5\u0abe \u0ab8\u0ac1\u0aa6\u0abf-\u0aeb"],
    "weekdays": ["\u0ab0\u0ab5\u0abf\u0ab5\u0abe\u0ab0", "\u0ab8\u0acb\u0aae\u0ab5\u0abe\u0ab0", "\u0aae\u0a82\u0a97\u0ab3\u0ab5\u0abe\u0ab0", "\u0aac\u0ac1\u0aa7\u0ab5\u0abe\u0ab0", "\u0a97\u0ac1\u0ab0\u0ac1\u0ab5\u0abe\u0ab0", "\u0ab6\u0ac1\u0a95\u0acd\u0ab0\u0ab5\u0abe\u0ab0", "\u0ab6\u0aa8\u0abf\u0ab5\u0abe\u0ab0"],
}

GU_DIGITS = str.maketrans("0123456789", "\u0ae6\u0ae7\u0ae8\u0ae9\u0aea\u0aeb\u0aec\u0aed\u0aee\u0aef")
SAMVAT_RE = re.compile(r"\u0ab8\u0a82\u0ab5\u0aa4\u0acd[\u0acd\u200c]*\s*([\u0ae6-\u0aef0-9]{4})")
TITHI_RE = re.compile(
    r"((?:\u0a95\u0abe\u0ab0\u0aa4\u0a95|\u0a95\u0abe\u0ab0\u0acd\u0aa4\u0abf\u0a95|\u0aae\u0abe\u0a97\u0ab6\u0ab0|\u0aaa\u0acb\u0ab7|\u0aae\u0ab9\u0abe|\u0aab\u0abe\u0a97\u0aa3|\u0a9a\u0ac8\u0aa4\u0acd\u0ab0|\u0ab5\u0ac8\u0ab6\u0abe\u0a96|\u0a9c\u0ac7\u0aa0|"
    r"\u0a85\u0ab7\u0abe\u0aa2|\u0ab6\u0acd\u0ab0\u0abe\u0ab5\u0aa3|\u0aa6\u0acd\u0ab5\u0abf\u0aa4\u0ac0\u0aaf\s+\u0ab6\u0acd\u0ab0\u0abe\u0ab5\u0aa3|\u0aad\u0abe\u0aa6\u0ab0\u0ab5\u0abe|\u0a86\u0ab8\u0acb)"
    r"[^\s,]*\s+(?:\u0ab8\u0ac1\u0aa6\u0abf|\u0ab5\u0aa6\u0abf)[^\s,]*)"
)
WEEKDAY_RE = re.compile(r"(\u0ab0\u0ab5\u0abf\u0ab5\u0abe\u0ab0|\u0ab8\u0acb\u0aae\u0ab5\u0abe\u0ab0|\u0aae\u0a82\u0a97\u0ab3\u0ab5\u0abe\u0ab0|\u0aac\u0ac1\u0aa7\u0ab5\u0abe\u0ab0|\u0a97\u0ac1\u0ab0\u0ac1\u0ab5\u0abe\u0ab0|\u0ab6\u0ac1\u0a95\u0acd\u0ab0\u0ab5\u0abe\u0ab0|\u0ab6\u0aa8\u0abf\u0ab5\u0abe\u0ab0)")
TIME_RE = re.compile(r"(\u0aaa\u0acd\u0ab0\u0abe\u0aa4\u0a83\u0a95\u0abe\u0ab3|\u0ab8\u0abe\u0a82\u0a9c(?:\u0aa8\u0acb \u0a95\u0aa5\u0abe)?|\u0aac\u0aaa\u0acb\u0ab0(?:\u0aa8\u0ac0 \u0a95\u0aa5\u0abe| \u0aaa\u0a9b\u0ac0)?)")

OPTION_LIMIT = 78
PROMPT_LIMIT = 96


def _gu_num(n: int) -> str:
    return str(n).translate(GU_DIGITS)


def _clean(text: str) -> str:
    text = unescape(strip_html(text or ""))
    text = text.replace("\u00a0", " ").replace("\u200c", "")
    text = text.replace("\u00ab", "").replace("\u00bb", "").replace("\u201c", "").replace("\u201d", "")
    text = re.sub(r"\s+", " ", text).strip(" \t-\u2013\u2014")
    return text.strip(" .")


def _clip(text: str, limit: int = OPTION_LIMIT) -> str:
    text = _clean(text)
    if len(text) <= limit:
        return text
    cut = text[:limit]
    for sep in ("\u0964", ".", ";", "\u2014", ",", " "):
        at = cut.rfind(sep)
        if at >= max(18, limit // 3):
            return cut[:at].strip(" ,;.\u2014")
    return cut.rstrip()


def _split_heading(item: str) -> tuple[str, str]:
    raw = unescape(strip_html(item or ""))
    raw = re.sub(r"\s+", " ", raw).strip()
    if ":" in raw:
        head, body = raw.split(":", 1)
        return _clean(head), _clean(body)
    return "\u0ab8\u0abe\u0ab0", _clean(raw)


def _unique(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        key = re.sub(r"\s+", "", item)
        if len(key) < 3 or key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


def _clauses(text: str, minimum: int = 18, maximum: int = 86) -> list[str]:
    text = _clean(text)
    parts = re.split(r"[\u0964.?!;]+|(?<=\s)\u2014\s+", text)
    out: list[str] = []
    for part in parts:
        part = _clip(part.strip(" ,-"), maximum)
        if minimum <= len(part) <= maximum:
            out.append(part)
    return _unique(out)


def _parse_date(date: str) -> dict[str, str]:
    raw = _clean(date)
    parts: dict[str, str] = {}
    samvat = SAMVAT_RE.search(raw)
    if samvat:
        year = samvat.group(1).translate(GU_DIGITS)
        parts["samvat"] = f"\u0ab8\u0a82\u0ab5\u0aa4\u0acd {year}"
    tithi = TITHI_RE.search(raw)
    if tithi:
        parts["tithi"] = _clean(tithi.group(1))
    weekday = WEEKDAY_RE.search(raw)
    if weekday:
        parts["weekday"] = weekday.group(1)
    time = TIME_RE.search(raw)
    if time:
        parts["time"] = _clean(time.group(1))
    return parts


def _pick(values: list[str], exclude: set[str], count: int, salt: str) -> list[str]:
    if not values:
        return []
    start = int(hashlib.sha1(salt.encode("utf-8")).hexdigest()[:8], 16)
    chosen: list[str] = []
    for offset in range(len(values) * 3):
        item = values[(start + offset) * 7 % len(values)]
        if item in exclude or item in chosen:
            continue
        chosen.append(item)
        if len(chosen) >= count:
            break
    return chosen


def _near_length(values: list[str], target: str, exclude: set[str], count: int, salt: str) -> list[str]:
    want = len(target)
    similar = [item for item in values if abs(len(item) - want) <= 28]
    pool = similar if len(similar) >= count else values
    return _pick(pool, exclude | {target}, count, salt)


def _question(prompt, correct, distractors, explanation, hint, salt):
    prompt = _clip(_clean(prompt), PROMPT_LIMIT)
    correct = _clip(correct)
    extras = _unique(_clip(item) for item in distractors if _clip(item) != correct)[:3]
    if not prompt or not correct or len(extras) < 3:
        return None
    ordered = [correct, *extras]
    shift = int(hashlib.sha1(salt.encode("utf-8")).hexdigest()[:2], 16) % 4
    rotated = ordered[shift:] + ordered[:shift]
    return {
        "prompt": prompt,
        "options": rotated,
        "correctIndex": rotated.index(correct),
        "explanation": _clean(explanation) or correct,
        "sourceHint": _clean(hint),
    }


def load_catalog():
    people = load_haribhakt_index()
    sources = []
    pools = {key: [] for key in (
        "places", "dates", "titles", "hosts", "readers", "mentioned",
        "locations", "summary", "morals", "sentences", "questions",
        "samvats", "tithis", "weekdays", "times",
    )}
    for part, index, path in iter_kirans():
        meta = kiran_meta(path)
        payload = source_payload(part, index, meta["data"], people.get(index))
        locations = (meta["data"].get("meta") or {}).get("locations") or []
        payload["locations"] = [_clean(item) for item in locations if _clean(item)]
        payload["sentences"] = _clauses(payload.get("text") or "")
        payload["summary_pairs"] = [_split_heading(item) for item in (payload.get("summary") or [])]
        payload["moral_clauses"] = _clauses(payload.get("moral") or "")
        payload["date_parts"] = _parse_date(payload.get("date") or "")
        sources.append(payload)
        if payload.get("place"):
            pools["places"].append(_clean(payload["place"]))
        if payload.get("date"):
            pools["dates"].append(_clean(payload["date"]))
        parts = payload["date_parts"]
        if parts.get("samvat"):
            pools["samvats"].append(parts["samvat"])
        if parts.get("tithi"):
            pools["tithis"].append(parts["tithi"])
        if parts.get("weekday"):
            pools["weekdays"].append(parts["weekday"])
        if parts.get("time"):
            pools["times"].append(parts["time"])
        if payload.get("title"):
            pools["titles"].append(_clean(payload["title"]))
        pools["hosts"].extend(_clean(item) for item in payload.get("hosts") or [])
        pools["readers"].extend(_clean(item) for item in payload.get("readers") or [])
        pools["mentioned"].extend(_clean(item) for item in payload.get("mentioned") or [])
        pools["locations"].extend(payload["locations"])
        pools["summary"].extend(body for _, body in payload["summary_pairs"] if body)
        pools["morals"].extend(payload["moral_clauses"])
        pools["sentences"].extend(payload["sentences"])
        pools["questions"].extend(
            _clean(item.get("text") or "") for item in payload.get("recordedQuestions") or []
        )
    for key, values in list(pools.items()):
        cleaned = _unique(values)
        fallback = PLACEHOLDERS.get(key, PLACEHOLDERS["titles"])
        if len(cleaned) < 8:
            cleaned = _unique(cleaned + fallback)
        pools[key] = cleaned
    return sources, pools


def build_questions(source, pools, target):
    part = source["part"]
    index = source["kiranIndex"]
    questions = []
    prompts = set()
    salt = f"{part}_{index}"

    def add(item):
        if not item or len(questions) >= target:
            return
        if item["prompt"] in prompts:
            return
        prompts.add(item["prompt"])
        questions.append(item)

    place = _clean(source.get("place") or "")
    if place:
        add(_question(
            "\u0a86 \u0ab8\u0aa4\u0acd\u0ab8\u0a82\u0a97 \u0a95\u0acd\u0aaf\u0abe\u0a82 \u0aa5\u0aaf\u0acb?",
            place, _near_length(pools["places"], place, {place}, 6, salt + "place"),
            f"\u0a86 \u0a95\u0aa5\u0abe {place}\u0aae\u0abe\u0a82 \u0ab5\u0a82\u0a9a\u0abe\u0a88.",
            "\u0ab8\u0acd\u0aa5\u0ab3", salt + "place",
        ))

    date_parts = source.get("date_parts") or _parse_date(source.get("date") or "")
    if date_parts.get("samvat"):
        year = date_parts["samvat"]
        add(_question(
            "\u0a86 \u0a95\u0aa5\u0abe \u0a95\u0aaf\u0abe \u0ab8\u0a82\u0ab5\u0aa4\u0aae\u0abe\u0a82 \u0aa5\u0a88?",
            year, _pick(pools["samvats"], {year}, 6, salt + "samvat"),
            source.get("date") or year, "\u0ab8\u0a82\u0ab5\u0aa4", salt + "samvat",
        ))
    if date_parts.get("tithi"):
        tithi = date_parts["tithi"]
        add(_question(
            "\u0a86 \u0a95\u0aa5\u0abe\u0aa8\u0ac0 \u0aa4\u0abf\u0aa5\u0abf \u0a95\u0a88 \u0a9b\u0ac7?",
            tithi, _pick(pools["tithis"], {tithi}, 6, salt + "tithi"),
            source.get("date") or tithi, "\u0aa4\u0abf\u0aa5\u0abf", salt + "tithi",
        ))
    if date_parts.get("weekday"):
        weekday = date_parts["weekday"]
        add(_question(
            "\u0a86 \u0a95\u0aa5\u0abe \u0a95\u0aaf\u0abe \u0ab5\u0abe\u0ab0\u0ac7 \u0aa5\u0a88?",
            weekday, _pick(pools["weekdays"], {weekday}, 6, salt + "weekday"),
            source.get("date") or weekday, "\u0ab5\u0abe\u0ab0", salt + "weekday",
        ))

    title = _clean(source.get("title") or "")
    if title:
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3 \u0ab6\u0ac7\u0aa8\u0abe \u0ab5\u0abf\u0ab7\u0ac7 \u0a9b\u0ac7?",
            title, _near_length(pools["titles"], title, {title}, 6, salt + "title"),
            f"\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0ac1\u0a82 \u0ab6\u0ac0\u0ab0\u0acd\u0ab7\u0a95: {title}.",
            "\u0ab6\u0ac0\u0ab0\u0acd\u0ab7\u0a95", salt + "title",
        ))

    host_prompts = [
        "\u0a86 \u0a95\u0aa5\u0abe\u0aa8\u0abe \u0aaf\u0a9c\u0aae\u0abe\u0aa8 \u0a95\u0acb\u0aa3 \u0ab9\u0aa4\u0abe?",
        "\u0a86 \u0ab8\u0aa4\u0acd\u0ab8\u0a82\u0a97\u0aa8\u0abe \u0aaf\u0a9c\u0aae\u0abe\u0aa8 \u0a95\u0acb\u0aa3 \u0ab9\u0aa4\u0abe?",
    ]
    for i, host in enumerate(_unique(source.get("hosts") or [])[:2]):
        add(_question(
            host_prompts[i % len(host_prompts)],
            host, _pick(pools["hosts"] + pools["readers"], {host}, 6, f"{salt}host{i}"),
            f"\u0aaf\u0a9c\u0aae\u0abe\u0aa8 {host} \u0ab9\u0aa4\u0abe.",
            "\u0aaf\u0a9c\u0aae\u0abe\u0aa8", f"{salt}host{i}",
        ))

    reader_prompts = [
        "\u0a86 \u0a95\u0aa5\u0abe \u0a95\u0acb\u0aa3\u0ac7 \u0ab5\u0abe\u0a82\u0a9a\u0ac0?",
        "\u0ab5\u0abe\u0a9a\u0aa8 \u0a95\u0acb\u0aa3\u0ac7 \u0a95\u0ab0\u0acd\u0aaf\u0ac1\u0a82?",
    ]
    for i, reader in enumerate(_unique(source.get("readers") or [])[:2]):
        add(_question(
            reader_prompts[i % len(reader_prompts)],
            reader, _pick(pools["readers"] + pools["hosts"], {reader}, 6, f"{salt}reader{i}"),
            f"\u0ab5\u0abe\u0a9a\u0aa8 {reader}\u0a8f \u0a95\u0ab0\u0acd\u0aaf\u0ac1\u0a82.",
            "\u0ab5\u0abe\u0a9a\u0a95", f"{salt}reader{i}",
        ))

    for i, location in enumerate(source.get("locations") or []):
        if place and place in location:
            continue
        add(_question(
            "\u0a86 \u0ab5\u0abe\u0aa4 \u0a95\u0aaf\u0abe \u0ab8\u0acd\u0aa5\u0ab3\u0ac7 \u0aa5\u0a88?",
            location,
            _near_length(pools["locations"] + pools["places"], location, {location}, 6, f"{salt}loc{i}"),
            f"\u0ab8\u0acd\u0aa5\u0ab3: {location}.",
            "\u0ab8\u0acd\u0aa5\u0abe\u0aa8", f"{salt}loc{i}",
        ))

    for i, recorded in enumerate(source.get("recordedQuestions") or []):
        asker = _clean(recorded.get("askers") or "")
        text = _clean(recorded.get("text") or "")
        short = _clip(text, 56)
        if asker:
            prompt = (
                f"{short} \u2014 \u0a86 \u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8 \u0a95\u0acb\u0aa3\u0ac7 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0acb?"
                if short else
                "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8 \u0a95\u0acb\u0aa3\u0ac7 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0acb?"
            )
            add(_question(
                prompt, asker,
                _pick(pools["hosts"] + pools["readers"] + pools["mentioned"], {asker}, 6, f"{salt}ask{i}"),
                f"{asker}\u0a8f \u0a86 \u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0acb.",
                "\u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8\u0a95\u0ab0\u0acd\u0aa4\u0abe", f"{salt}ask{i}",
            ))
        if text:
            who = (
                f"{asker}\u0a8f \u0ab6\u0ac1\u0a82 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0ac1\u0a82?"
                if asker else
                "\u0ab9\u0ab0\u0abf\u0aad\u0a95\u0acd\u0aa4\u0ac7 \u0ab6\u0ac1\u0a82 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0ac1\u0a82?"
            )
            add(_question(
                who, text,
                _near_length(pools["questions"] + pools["sentences"], text, {text}, 6, f"{salt}qtext{i}"),
                text, "\u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8", f"{salt}qtext{i}",
            ))

    for heading, body in source.get("summary_pairs") or []:
        if not body:
            continue
        topic = heading if heading and heading != "\u0ab8\u0abe\u0ab0" else "\u0ab8\u0abe\u0ab0"
        add(_question(
            f"{topic} \u0ab5\u0abf\u0ab7\u0ac7 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82?",
            body,
            _near_length(pools["summary"] + pools["morals"], body, {body}, 6, f"{salt}sum{topic}"),
            body, topic, f"{salt}sum{topic}",
        ))

    moral = _clean(source.get("moral") or "")
    moral_options = source.get("moral_clauses") or []
    if moral:
        correct = moral if len(moral) <= OPTION_LIMIT else (moral_options[0] if moral_options else _clip(moral))
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0acb \u0aae\u0ac1\u0a96\u0acd\u0aaf \u0aac\u0acb\u0aa7 \u0ab6\u0ac1\u0a82 \u0a9b\u0ac7?",
            correct,
            _near_length(pools["morals"] + pools["summary"], correct, {correct}, 6, salt + "moral"),
            moral, "\u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7", salt + "moral",
        ))
    moral_prompts = [
        "\u0a86 \u0aac\u0acb\u0aa7\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a86\u0ab5\u0ac7 \u0a9b\u0ac7?",
        "\u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7\u0aae\u0abe\u0a82 \u0aac\u0ac0\u0a9c\u0ac1\u0a82 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82?",
        "\u0a86 \u0a89\u0aaa\u0aa6\u0ac7\u0ab6\u0aa8\u0acb \u0aac\u0ac0\u0a9c\u0acb \u0a85\u0ab0\u0acd\u0aa5 \u0ab6\u0ac1\u0a82 \u0a9b\u0ac7?",
    ]
    for i, clause in enumerate(moral_options[:3]):
        add(_question(
            moral_prompts[i % len(moral_prompts)],
            clause,
            _near_length(pools["morals"] + pools["summary"], clause, {clause}, 6, f"{salt}mcl{i}"),
            clause, "\u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7", f"{salt}mcl{i}",
        ))

    name_prompts = [
        "\u0a86 \u0a95\u0aa5\u0abe\u0aae\u0abe\u0a82 \u0a95\u0acb\u0aa8\u0ac1\u0a82 \u0aa8\u0abe\u0aae \u0a86\u0ab5\u0ac7 \u0a9b\u0ac7?",
        "\u0a86 \u0ab5\u0abe\u0aa4\u0aae\u0abe\u0a82 \u0a95\u0acb\u0aa8\u0acb \u0a89\u0ab2\u0acd\u0ab2\u0ac7\u0a96 \u0a9b\u0ac7?",
    ]
    for i, name in enumerate(_unique(source.get("mentioned") or [])[:2]):
        add(_question(
            name_prompts[i % len(name_prompts)],
            name, _pick(pools["mentioned"] + pools["hosts"], {name}, 6, f"{salt}men{i}"),
            f"{name}\u0aa8\u0ac1\u0a82 \u0aa8\u0abe\u0aae \u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0a86\u0ab5\u0ac7 \u0a9b\u0ac7.",
            "\u0aa8\u0abe\u0aae", f"{salt}men{i}",
        ))

    sentence_prompts = [
        "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0a95\u0a88 \u0ab5\u0abe\u0aa4 \u0ab8\u0abe\u0a9a\u0ac0 \u0a9b\u0ac7?",
        "\u0aae\u0ac2\u0ab3 \u0ab5\u0abe\u0aa4\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82 \u0a9b\u0ac7?",
        "\u0ab8\u0aad\u0abe\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0ac7\u0ab5\u0abe\u0aaf\u0ac1\u0a82?",
        "\u0aa8\u0ac0\u0a9a\u0ac7\u0aa8\u0abe\u0aae\u0abe\u0a82\u0aa5\u0ac0 \u0ab6\u0ac1\u0a82 \u0ab8\u0abe\u0a9a\u0ac1\u0a82 \u0a9b\u0ac7?",
        "\u0a86 \u0a89\u0aaa\u0aa6\u0ac7\u0ab6\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a86\u0ab5\u0ac7 \u0a9b\u0ac7?",
        "\u0aad\u0a97\u0ab5\u0abe\u0aa8\u0aa8\u0ac0 \u0ab5\u0abe\u0aa4\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82?",
        "\u0a86 \u0a95\u0aa5\u0abe\u0aae\u0abe\u0a82 \u0a95\u0aaf\u0ac1\u0a82 \u0a95\u0ab9\u0ac7\u0ab5\u0abe\u0aaf\u0ac1\u0a82?",
        "\u0aae\u0ac2\u0ab3 \u0a89\u0aaa\u0aa6\u0ac7\u0ab6\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a9b\u0ac7?",
    ]
    for i, sentence in enumerate(source.get("sentences") or []):
        stem = sentence_prompts[i % len(sentence_prompts)]
        prompt = stem if stem not in prompts else f"{stem} \u00b7 {_gu_num(i + 1)}"
        add(_question(
            prompt, sentence,
            _near_length(pools["sentences"], sentence, {sentence}, 8, f"{salt}sent{i}"),
            sentence, "\u0aae\u0ac2\u0ab3 \u0ab5\u0abe\u0aa4", f"{salt}sent{i}",
        ))
        if len(questions) >= target:
            break
    return questions[:target]
