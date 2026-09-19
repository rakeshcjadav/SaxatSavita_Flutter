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
}


def _clean(text: str) -> str:
    text = unescape(strip_html(text or ""))
    return re.sub(r"\s+", " ", text).strip()


def _split_heading(item: str) -> tuple[str, str]:
    raw = _clean(item)
    if ":" in raw:
        head, body = raw.split(":", 1)
        return head.strip(" ."), body.strip()
    return "\u0ab8\u0abe\u0ab0", raw


def _clauses(text: str, minimum: int = 16, maximum: int = 110) -> list[str]:
    text = _clean(text)
    parts = re.split(r"[।.?!;]+|(?<=\s)—\s+", text)
    out: list[str] = []
    for part in parts:
        part = part.strip(" ,-")
        if minimum <= len(part) <= maximum:
            out.append(part)
        elif len(part) > maximum:
            for chunk in re.split(r",\s+", part):
                chunk = chunk.strip()
                if minimum <= len(chunk) <= maximum:
                    out.append(chunk)
    return out


def _unique(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        key = re.sub(r"\s+", "", item)
        if len(key) < 4 or key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


def _pick(values: list[str], exclude: set[str], count: int, salt: str) -> list[str]:
    if not values:
        return []
    start = int(hashlib.sha1(salt.encode("utf-8")).hexdigest()[:8], 16)
    chosen: list[str] = []
    for offset in range(len(values) * 2):
        item = values[(start + offset) * 7 % len(values)]
        if item in exclude or item in chosen:
            continue
        chosen.append(item)
        if len(chosen) >= count:
            break
    return chosen


def _question(prompt, correct, distractors, explanation, hint, salt):
    correct = _clean(correct)
    options = _unique([correct, *(_clean(item) for item in distractors)])
    extras = [item for item in options if item != correct][:3]
    if not correct or len(extras) < 3:
        return None
    ordered = [correct, *extras]
    shift = int(hashlib.sha1(salt.encode("utf-8")).hexdigest()[:2], 16) % 4
    rotated = ordered[shift:] + ordered[:shift]
    return {
        "prompt": prompt,
        "options": rotated,
        "correctIndex": rotated.index(correct),
        "explanation": explanation or correct,
        "sourceHint": hint,
    }


def load_catalog():
    people = load_haribhakt_index()
    sources = []
    pools = {key: [] for key in (
        "places", "dates", "titles", "hosts", "readers", "mentioned",
        "locations", "summary", "morals", "sentences", "questions",
    )}
    for part, index, path in iter_kirans():
        meta = kiran_meta(path)
        payload = source_payload(part, index, meta["data"], people.get(index))
        locations = (meta["data"].get("meta") or {}).get("locations") or []
        payload["locations"] = [_clean(item) for item in locations if _clean(item)]
        payload["sentences"] = _clauses(payload.get("text") or "")
        payload["summary_pairs"] = [_split_heading(item) for item in (payload.get("summary") or [])]
        payload["moral_clauses"] = _clauses(payload.get("moral") or "")
        sources.append(payload)
        if payload.get("place"):
            pools["places"].append(_clean(payload["place"]))
        if payload.get("date"):
            pools["dates"].append(_clean(payload["date"]))
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
            "\u0a86 \u0a95\u0aa5\u0abe \u0a95\u0acd\u0aaf\u0abe\u0a82 \u0ab5\u0a82\u0a9a\u0abe\u0a88?",
            place, _pick(pools["places"], {place}, 6, salt + "place"),
            place, "\u0ab8\u0acd\u0aa5\u0ab3", salt + "place",
        ))
    date = _clean(source.get("date") or "")
    if date:
        add(_question(
            "\u0a86 \u0a95\u0aa5\u0abe\u0aa8\u0acb \u0ab8\u0aae\u0aaf \u0a95\u0aaf\u0acb \u0a9b\u0ac7?",
            date, _pick(pools["dates"], {date}, 6, salt + "date"),
            date, "\u0ab8\u0aae\u0aaf", salt + "date",
        ))
    title = _clean(source.get("title") or "")
    if title:
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0ac1\u0a82 \u0ab6\u0ac0\u0ab0\u0acd\u0ab7\u0a95 \u0ab6\u0ac1\u0a82 \u0a9b\u0ac7?",
            title, _pick(pools["titles"], {title}, 6, salt + "title"),
            title, "\u0ab6\u0ac0\u0ab0\u0acd\u0ab7\u0a95", salt + "title",
        ))
    for i, host in enumerate(_unique(source.get("hosts") or [])):
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0abe \u0aaf\u0a9c\u0aae\u0abe\u0aa8 \u0a95\u0acb\u0aa3 \u0ab9\u0aa4\u0abe?",
            host, _pick(pools["hosts"] + pools["readers"], {host}, 6, f"{salt}host{i}"),
            host, "\u0aaf\u0a9c\u0aae\u0abe\u0aa8", f"{salt}host{i}",
        ))
    for i, reader in enumerate(_unique(source.get("readers") or [])):
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0ab5\u0abe\u0a9a\u0aa8 \u0a95\u0acb\u0aa3\u0ac7 \u0a95\u0ab0\u0acd\u0aaf\u0ac1\u0a82?",
            reader, _pick(pools["readers"] + pools["hosts"], {reader}, 6, f"{salt}reader{i}"),
            reader, "\u0ab5\u0abe\u0a9a\u0a95", f"{salt}reader{i}",
        ))
    for i, location in enumerate(source.get("locations") or []):
        add(_question(
            "\u0a86 \u0a95\u0aa5\u0abe \u0a95\u0aaf\u0abe \u0ab8\u0acd\u0aa5\u0ab3\u0ac7 \u0aa5\u0a88?",
            location, _pick(pools["locations"] + pools["places"], {location}, 6, f"{salt}loc{i}"),
            location, "\u0ab8\u0acd\u0aa5\u0abe\u0aa8", f"{salt}loc{i}",
        ))
    for i, recorded in enumerate(source.get("recordedQuestions") or []):
        asker = _clean(recorded.get("askers") or "")
        text = _clean(recorded.get("text") or "")
        if asker:
            label = text or "\u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8"
            add(_question(
                f"\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u00ab{label}\u00bb \u0a95\u0acb\u0aa3\u0ac7 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0acb?",
                asker,
                _pick(pools["hosts"] + pools["readers"] + pools["mentioned"], {asker}, 6, f"{salt}ask{i}"),
                asker, "\u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8\u0a95\u0ab0\u0acd\u0aa4\u0abe", f"{salt}ask{i}",
            ))
        if text:
            add(_question(
                f"\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0ab9\u0ab0\u0abf\u0aad\u0a95\u0acd\u0aa4\u0ac7 \u0ab6\u0ac1\u0a82 \u0aaa\u0ac2\u0a9b\u0acd\u0aaf\u0ac1\u0a82? ({i + 1})",
                text, _pick(pools["questions"] + pools["sentences"], {text}, 6, f"{salt}qtext{i}"),
                text, "\u0aaa\u0acd\u0ab0\u0ab6\u0acd\u0aa8", f"{salt}qtext{i}",
            ))
    for i, (heading, body) in enumerate(source.get("summary_pairs") or []):
        if not body:
            continue
        add(_question(
            f"\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0abe \u0ab8\u0abe\u0ab0\u0aae\u0abe\u0a82 \u00ab{heading}\u00bb \u0ab5\u0abf\u0ab7\u0ac7 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82?",
            body, _pick(pools["summary"] + pools["morals"], {body}, 6, f"{salt}sum{i}"),
            body, heading or "\u0ab8\u0abe\u0ab0", f"{salt}sum{i}",
        ))
    moral = _clean(source.get("moral") or "")
    moral_options = source.get("moral_clauses") or []
    if moral:
        correct = moral if len(moral) <= 110 else (moral_options[0] if moral_options else moral[:110])
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0acb \u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7 \u0ab6\u0ac1\u0a82 \u0a9b\u0ac7?",
            correct, _pick(pools["morals"] + pools["summary"], {correct}, 6, salt + "moral"),
            moral, "\u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7", salt + "moral",
        ))
    for i, clause in enumerate(moral_options):
        add(_question(
            f"\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aa8\u0abe \u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7\u0aae\u0abe\u0a82 \u0ab6\u0ac1\u0a82 \u0a95\u0ab9\u0acd\u0aaf\u0ac1\u0a82 \u0a9b\u0ac7? ({i + 1})",
            clause, _pick(pools["morals"] + pools["summary"], {clause}, 6, f"{salt}mcl{i}"),
            clause, "\u0aa8\u0ac0\u0aa4\u0abf\u0aac\u0acb\u0aa7", f"{salt}mcl{i}",
        ))
    for i, sentence in enumerate(source.get("sentences") or []):
        add(_question(
            f"\u0aa8\u0ac0\u0a9a\u0ac7\u0aa8\u0abe\u0aae\u0abe\u0a82\u0aa5\u0ac0 \u0a95\u0aaf\u0ac1\u0a82 \u0ab5\u0abe\u0a95\u0acd\u0aaf \u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0a9b\u0ac7? ({i + 1})",
            sentence, _pick(pools["sentences"], {sentence}, 8, f"{salt}sent{i}"),
            sentence, "\u0aae\u0ac2\u0ab3 \u0ab5\u0abe\u0aa4", f"{salt}sent{i}",
        ))
        if len(questions) >= target:
            break
    for i, name in enumerate(_unique(source.get("mentioned") or [])):
        add(_question(
            "\u0a86 \u0a95\u0abf\u0ab0\u0aa3\u0aae\u0abe\u0a82 \u0a95\u0acb\u0aa8\u0ac1\u0a82 \u0aa8\u0abe\u0aae \u0a86\u0ab5\u0ac7 \u0a9b\u0ac7?",
            name, _pick(pools["mentioned"] + pools["hosts"], {name}, 6, f"{salt}men{i}"),
            name, "\u0aa8\u0abe\u0aae", f"{salt}men{i}",
        ))
    return questions[:target]
