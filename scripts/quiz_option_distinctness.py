"""Lexical distinctness for Gujarati and English quiz choices.

Mirrors lib/quiz/quiz_option_distinctness.dart. Distractors sampled from
other kiran lines are rejected when they paraphrase the correct answer or
each other. A single swapped content word (including a different year or
tithi number) stays distinct. ZWJ/ZWNJ are ignored.
"""

from __future__ import annotations

import re
import unicodedata

_SUFFIXES = (
    "માંથી",
    "વાળું",
    "વાળો",
    "વાળી",
    "વાળા",
    "નું",
    "નો",
    "ના",
    "ની",
    "ને",
    "માં",
    "થી",
)

_STOPWORDS = {
    "અને", "તો", "ન", "નહીં", "નથી", "એ", "છે", "છો", "છું",
    "નું", "નો", "ના", "ની", "ને", "માં", "થી", "પણ", "જ", "એટલે",
    "શું", "કે", "તે", "તેઓ", "આ", "એક", "બે", "વિષે", "અંગે",
    "થાય", "થયો", "થઈ", "થયું", "થયા", "થયે", "થશે", "થતું", "થતી", "થતા",
    "હોય", "હતા", "હતી", "હતો", "તોય", "તોપણ", "વિના", "સાથે", "પર", "માટે",
    "કરવો", "કરે", "કહ્યું", "કહેવાય", "એવો", "એવી", "એવું",
    "જેવો", "જેવી", "જેવું", "તેવો", "તેવી", "તેમ", "ય", "જો",
    "ત્યારે", "પછી", "પહેલાં", "બંને", "કોઈ", "કોણ", "તેને", "તેમાં",
    "એમ", "આમ", "ત્યાં", "અહીં", "જેમ", "એટલામાં", "જાય", "આવે",
    "the", "a", "an", "of", "and", "or", "to", "in", "is", "are", "was",
    "be", "it", "that", "this", "for", "with", "on", "as", "by", "at", "from",
}

_HYPHENS = re.compile(r"[-–—_+|/]+")
_PUNCTUATION = re.compile(r"""[.,;:!?…"'“”‘’()\[\]{}<>«»\\@#$%^&*=~`।]+""")
_WHITESPACE = re.compile(r"\s+")
_DIGITS = re.compile(r"^[0-9૦-૯]+$")
_FORMAT = {0x200B, 0x200C, 0x200D, 0xFEFF, 0x00AD}


def options_too_similar(a: str, b: str) -> bool:
    left = _normalize(a)
    right = _normalize(b)
    if not left or not right:
        return left == right
    if left == right:
        return True
    compact_left = left.replace(" ", "")
    compact_right = right.replace(" ", "")
    if compact_left == compact_right:
        return True

    left_tokens = _tokens(left)
    right_tokens = _tokens(right)
    if not left_tokens or not right_tokens:
        return _compact_contained(compact_left, compact_right)

    shared, only_left, only_right = _align(left_tokens, right_tokens)
    if len(only_left) == 1 and len(only_right) == 1 and shared:
        return False
    if shared and not only_left and not only_right:
        return True

    shorter_count = min(len(left_tokens), len(right_tokens))
    shorter_only = only_left if len(left_tokens) <= len(right_tokens) else only_right
    if shorter_count >= 2 and not shorter_only:
        return True

    inter = len(shared)
    union = inter + len(only_left) + len(only_right)
    if inter >= 2 and union and inter / union >= 0.62:
        return True
    if inter >= 2 and shorter_count >= 3 and inter / shorter_count >= 0.8:
        return True
    if _compact_contained(compact_left, compact_right):
        return True
    if _shares_phrase(left_tokens, right_tokens, shorter_count):
        return True
    return _dice(compact_left, compact_right) >= 0.72


def option_set_is_distinct(options: list[str]) -> bool:
    if len(options) != 4:
        return False
    if any(not str(option).strip() for option in options):
        return False
    for i, left in enumerate(options):
        for right in options[i + 1 :]:
            if options_too_similar(left, right):
                return False
    return True


def _compact_contained(left: str, right: str) -> bool:
    shorter, longer = (left, right) if len(left) <= len(right) else (right, left)
    if len(shorter) < 12 or shorter not in longer:
        return False
    return len(shorter) / len(longer) >= 0.62


def _shares_phrase(left: list[str], right: list[str], shorter_count: int) -> bool:
    if shorter_count == 0:
        return False
    for length, min_fraction, min_chars in ((4, 0.0, 0), (3, 0.5, 0), (2, 0.67, 8)):
        common = set(_phrases(left, length)) & set(_phrases(right, length))
        if not common:
            continue
        longest = max(common, key=lambda phrase: len(phrase.replace(" ", "")))
        chars = len(longest.replace(" ", ""))
        fraction = length / shorter_count
        if length >= 4:
            return True
        if length == 3 and fraction >= min_fraction:
            return True
        if length == 2 and fraction >= min_fraction and chars >= min_chars:
            return True
    return False


def _phrases(tokens: list[str], length: int) -> list[str]:
    return [
        " ".join(tokens[i : i + length])
        for i in range(len(tokens) - length + 1)
    ]


def _dice(left: str, right: str) -> float:
    if len(left) < 18 or len(right) < 18:
        return 0
    left_grams = _grams(left)
    right_grams = _grams(right)
    if not left_grams or not right_grams:
        return 0
    shared = len(left_grams & right_grams)
    return 2 * shared / (len(left_grams) + len(right_grams))


def _grams(text: str) -> set[str]:
    return {text[i : i + 3] for i in range(len(text) - 2)} if len(text) >= 3 else set()


def _align(left: list[str], right: list[str]) -> tuple[list[str], list[str], list[str]]:
    used = [False] * len(right)
    shared: list[str] = []
    only_left: list[str] = []
    for token in left:
        found = next(
            (i for i, other in enumerate(right) if not used[i] and _same_token(token, other)),
            None,
        )
        if found is None:
            only_left.append(token)
        else:
            used[found] = True
            shared.append(token)
    only_right = [token for i, token in enumerate(right) if not used[i]]
    return shared, only_left, only_right


def _same_token(a: str, b: str) -> bool:
    if a == b:
        return True
    # ૨૦૩૧ and ૨૦૩૨ differ by one digit; that is a different year, not a spelling.
    if _DIGITS.match(a) or _DIGITS.match(b):
        return False
    if abs(len(a) - len(b)) > 1 or min(len(a), len(b)) < 4:
        return False
    if len(a) == len(b):
        diffs = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
        return len(diffs) == 1 and diffs[0] > 0
    shorter, longer = (a, b) if len(a) < len(b) else (b, a)
    return longer.startswith(shorter)


def _normalize(text: str) -> str:
    chars = []
    for char in unicodedata.normalize("NFKC", text or ""):
        if ord(char) in _FORMAT:
            continue
        chars.append(" " if char == "\u00a0" else char)
    normalized = "".join(chars).lower()
    normalized = _HYPHENS.sub(" ", normalized)
    normalized = _PUNCTUATION.sub(" ", normalized)
    return _WHITESPACE.sub(" ", normalized).strip()


def _tokens(normalized: str) -> list[str]:
    tokens: list[str] = []
    for raw in normalized.split(" "):
        if not raw:
            continue
        token = _stem(raw)
        if not token or token in _STOPWORDS:
            continue
        if len(token) < 2 and not _DIGITS.match(token):
            continue
        tokens.append(token)
    return tokens


def _stem(token: str) -> str:
    for suffix in _SUFFIXES:
        if token.endswith(suffix) and len(token) - len(suffix) >= 3:
            return token[: -len(suffix)]
    return token
