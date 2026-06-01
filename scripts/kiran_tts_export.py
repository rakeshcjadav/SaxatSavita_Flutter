#!/usr/bin/env python3
"""
kiran_tts_export.py

Reads kiran JSON files from assets/book/saxatsavita/<part>/kiran_<n>.json,
strips HTML, applies the same Gujarati TTS normalisation used in
KiranTtsController.normalizeForTts(), and writes each kiran as a plain-text
file ready for TTS ingestion.

Usage:
    # Export the first 5 kirans of part 1 (default):
    python3 scripts/kiran_tts_export.py

    # Export kirans 1-3 from parts 1 and 2:
    python3 scripts/kiran_tts_export.py --parts 1 2 --kirans 1 2 3

    # Export ALL kirans across ALL parts:
    python3 scripts/kiran_tts_export.py --all

Output is written to:   scripts/tts_output/<part>/kiran_<n>.txt
"""

import argparse
import json
import re
import html as html_stdlib
from pathlib import Path

# ── Gujarati numeral helpers ──────────────────────────────────────────────────

# Map Gujarati digit characters (U+0AE6–U+0AEF) to int.
# Also map two common letter-digit lookalikes found in manuscript text:
#   ર  (U+0AB0, ra) → 2
#   પ  (U+0AAA, pa) → 5  (only in mid-word numeric context)
_GUJ_DIGIT = {chr(0x0AE6 + i): i for i in range(10)}
_GUJ_DIGIT['\u0AB0'] = 2   # ર lookalike
_GUJ_DIGIT['\u0AAA'] = 5   # પ lookalike


def parse_gujarati_int(s: str) -> int:
    """Convert a string of Gujarati (or ASCII) digits to int."""
    result = 0
    for ch in s:
        d = _GUJ_DIGIT.get(ch) if ch in _GUJ_DIGIT else (int(ch) if ch.isdigit() else None)
        if d is not None:
            result = result * 10 + d
    return result


_ONES = [
    '', 'એક', 'બે', 'ત્રણ', 'ચાર', 'પાંચ', 'છ', 'સાત', 'આઠ', 'નવ',
    'દસ', 'અગિયાર', 'બાર', 'તેર', 'ચૌદ', 'પંદર', 'સોળ', 'સત્તર', 'અઢાર',
    'ઓગણીસ', 'વીસ', 'એકવીસ', 'બાવીસ', 'તેવીસ', 'ચોવીસ', 'પચ્ચીસ',
    'છવ્વીસ', 'સત્તાવીસ', 'અઠ્ઠાવીસ', 'ઓગણત્રીસ', 'ત્રીસ', 'એકત્રીસ',
    'બત્રીસ', 'તેત્રીસ', 'ચોત્રીસ', 'પાંત્રીસ', 'છત્રીસ', 'સાડત્રીસ',
    'અડત્રીસ', 'ઓગણચાળીસ', 'ચાળીસ', 'એકતાળીસ', 'બેતાળીસ', 'તેતાળીસ',
    'ચુમ્માળીસ', 'પિસ્તાળીસ', 'છેતાળીસ', 'સુડતાળીસ', 'અડતાળીસ',
    'ઓગણપચાસ', 'પચાસ', 'એકાવન', 'બાવન', 'ત્રેપન', 'ચોપન', 'પંચાવન',
    'છપ્પન', 'સત્તાવન', 'અઠ્ઠાવન', 'ઓગણસાઠ', 'સાઠ', 'એકસઠ', 'બાસઠ',
    'ત્રેસઠ', 'ચોસઠ', 'પાંસઠ', 'છાસઠ', 'સડસઠ', 'અડસઠ', 'ઓગણસિત્તેર',
    'સિત્તેર', 'એકોત્તેર', 'બોત્તેર', 'તોત્તેર', 'ચુમ્મોત્તેર',
    'પંચોત્તેર', 'છોત્તેર', 'સત્ત્યોત્તેર', 'અઠ્ઠ્યોત્તેર', 'ઓગણએંસી',
    'એંસી', 'એક્યાસી', 'બ્યાસી', 'ત્ર્યાસી', 'ચોર્યાસી', 'પંચ્યાસી',
    'છ્યાસી', 'સત્યાસી', 'અઠ્ઠ્યાસી', 'નેવ્યાસી', 'નેવું',
    'એકાણું', 'બાણું', 'ત્રાણું', 'ચોર્યાણું', 'પંચાણું', 'છ્યાણું',
    'સત્તાણું', 'અઠ્ઠ્યાણું', 'નવ્વાણું', 'સો',
]

_ORDINALS = {
    1: 'પ્રથમ', 2: 'બીજું', 3: 'ત્રીજું', 4: 'ચોથું', 5: 'પાંચમું',
    6: 'છઠ્ઠું', 7: 'સાતમું', 8: 'આઠમું', 9: 'નવમું', 10: 'દસમું',
    11: 'અગિયારમું', 12: 'બારમું', 13: 'તેરમું', 14: 'ચૌદમું', 15: 'પંદરમું',
}

_MONTHS = {
    1: 'જાન્યુઆરી', 2: 'ફેબ્રુઆરી', 3: 'માર્ચ', 4: 'એપ્રિલ',
    5: 'મે', 6: 'જૂન', 7: 'જુલાઈ', 8: 'ઓગસ્ટ',
    9: 'સપ્ટેમ્બર', 10: 'ઓક્ટોબર', 11: 'નવેમ્બર', 12: 'ડિસેમ્બર',
}

_TITHI = {
    1: 'એકમ', 2: 'બીજ', 3: 'ત્રીજ', 4: 'ચોથ', 5: 'પાંચમ',
    6: 'છઠ', 7: 'સાતમ', 8: 'આઠમ', 9: 'નોમ', 10: 'દસમ',
    11: 'અગિયારસ', 12: 'બારસ', 13: 'તેરસ', 14: 'ચૌદસ', 15: 'પૂનમ',
}

_VACHANAMRUT_LOCATIONS = {
    'પ્રથમ': 'ગઢડા પ્રથમ',    'પ્રથમનું': 'ગઢડા પ્રથમ',
    'મધ્ય': 'ગઢડા મધ્ય',      'મધ્યનું': 'ગઢડા મધ્ય',
    'અંત્ય': 'ગઢડા અંત્ય',    'અંત્યનું': 'ગઢડા અંત્ય',
    'છેલ્લા': 'ગઢડા અંત્ય',   'છેલ્લાનું': 'ગઢડા અંત્ય',
    'સારંગપુર': 'સારંગપુર',    'સારંગપુરનું': 'સારંગપુર',
    'કારિયાણી': 'કારિયાણી',   'કારિયાણીનું': 'કારિયાણી',
    'લોયા': 'લોયા',            'લોયાનું': 'લોયા',
    'પંચાળા': 'પંચાળા',        'પંચાળાનું': 'પંચાળા',
    'વરતાલ': 'વરતાલ',          'વરતાલનું': 'વરતાલ',
    'અમદાવાદ': 'અમદાવાદ',      'અમદાવાદનું': 'અમદાવાદ',
}


def number_to_gujarati(n: int) -> str:
    if n <= 0:
        return ''
    if n < len(_ONES):
        return _ONES[n]
    if n < 200:
        return ('એકસો ' + _ONES[n - 100]).strip()
    return str(n)


def ordinal_gujarati(n: int) -> str:
    if n in _ORDINALS:
        return _ORDINALS[n]
    return number_to_gujarati(n) + 'મું'


def year_to_gujarati(yy: int) -> str:
    """2-digit year: 0-30 → 21st century, 31-99 → 20th century."""
    if 0 <= yy <= 30:
        return 'બે હજાર' if yy == 0 else f'બે હજાર {number_to_gujarati(yy)}'
    return f'ઓગણીસો {number_to_gujarati(yy)}'


def full_year_to_gujarati(yr: int) -> str:
    """4-digit year to Gujarati spoken form."""
    if 2000 <= yr < 2100:
        r = yr - 2000
        return 'બે હજાર' if r == 0 else f'બે હજાર {number_to_gujarati(r)}'
    hundreds = yr // 100
    remainder = yr % 100
    h = number_to_gujarati(hundreds)
    r = number_to_gujarati(remainder)
    return f'{h}સો' if not r else f'{h}સો {r}'


# ── Regex patterns (compiled once) ───────────────────────────────────────────

# Gujarati Unicode ranges used in patterns:
#   \u0A80-\u0AFF  full Gujarati block
#   \u0AE6-\u0AEF  Gujarati digits ૦-૯
#   \u0AB0         ર (lookalike for 2)
#   \u0AAA         પ (lookalike for 5)

# Optional whitespace: (મધ્યનું ૧૩) and compact (મધ્યનું૧૩)
_RE_VACHANAMRUT = re.compile(
    r'\(([\u0A80-\u0AFF]+?)\s*([\u0AE6-\u0AEF\u0AB0\u0AAA\d]{1,3})\)'
)
_RE_TITHI = re.compile(
    r'(સુદ|સુદિ|વદ|વદિ)[-\u2010\s]+([\u0AE6-\u0AEF\u0AB0\u0AAA\d]{1,2})'
)
_RE_SAMVAT = re.compile(
    r'(સંવત)\s+([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AB0\u0AAA]{2,3})'
)
_RE_DATE = re.compile(
    r'([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})'
    r'-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{1,2})'
    r'-([\u0AE6-\u0AEF\d\u0AB0\u0AAA]{2,4})'
)
_RE_YEAR4 = re.compile(
    r'(?<!\S)([\u0AE6-\u0AEF\u0AB0][\u0AE6-\u0AEF\u0AAA\u0AB0]{3})(?!\S)'
)
_RE_ENTITIES = re.compile(r'&[a-zA-Z0-9#]+;')
_RE_SPACES = re.compile(r'[ \t]+')
_RE_NEWLINES = re.compile(r'\n+')
# Sentence split: after danda/danda variants, ?, ! or period before space+non-digit
_RE_SENTENCE_SPLIT = re.compile(r'(?<=[।?!])|(?<=\.(?=\s+\D))')


# ── Core normalisation ────────────────────────────────────────────────────────

def normalize_for_tts(text: str) -> str:
    """Port of KiranTtsController.normalizeForTts() in Dart."""
    t = text

    # 1. Vachanamrut parenthetical references: (લોયા ૬) → વચનામૃત લોયા નું છઠ્ઠું
    def _vachanamrut_replace(m: re.Match) -> str:
        word = m.group(1)
        loc = _VACHANAMRUT_LOCATIONS.get(word)
        if loc is None:
            return m.group(0)
        n = parse_gujarati_int(m.group(2))
        return f'વચનામૃત {loc} નું {ordinal_gujarati(n)}.'

    t = _RE_VACHANAMRUT.sub(_vachanamrut_replace, t)

    # 2. Expand common abbreviations
    t = re.sub(r'પૂ\.', 'પૂજ્ય', t)
    t = re.sub(r'ગુ\.', 'ગુણાતીતાનંદ', t)
    t = re.sub(r'તા\.', 'તારીખ', t)
    t = re.sub(r'સં\.', 'સંવત', t)
    t = t.replace('સંવત\u200c', 'સંવત')   # virama + ZWJ
    t = re.sub(r'ઈ\.સ\.', 'ઈસ્વી સન', t)
    t = re.sub(r'વ\.', 'વર્ષ', t)

    # 3. Tithi names
    def _tithi_replace(m: re.Match) -> str:
        n = parse_gujarati_int(m.group(2))
        name = _TITHI.get(n) or number_to_gujarati(n)
        return f'{m.group(1)} {name}'

    t = _RE_TITHI.sub(_tithi_replace, t)

    # 4. Samvat year
    def _samvat_replace(m: re.Match) -> str:
        yr = parse_gujarati_int(m.group(2))
        return f'{m.group(1)} {full_year_to_gujarati(yr)}'

    t = _RE_SAMVAT.sub(_samvat_replace, t)

    # 5. Date pattern DD-MM-YY or DD-MM-YYYY
    def _date_replace(m: re.Match) -> str:
        day = parse_gujarati_int(m.group(1))
        month = parse_gujarati_int(m.group(2))
        raw_year = parse_gujarati_int(m.group(3))
        month_name = _MONTHS.get(month) or number_to_gujarati(month)
        day_word = number_to_gujarati(day)
        year_word = (
            year_to_gujarati(raw_year)
            if len(m.group(3)) <= 2
            else full_year_to_gujarati(raw_year)
        )
        return f'{day_word}, {month_name}, {year_word}'

    t = _RE_DATE.sub(_date_replace, t)

    # 6. Standalone 4-digit Gujarati year surrounded by whitespace
    def _year4_replace(m: re.Match) -> str:
        yr = parse_gujarati_int(m.group(1))
        return full_year_to_gujarati(yr)

    t = _RE_YEAR4.sub(_year4_replace, t)

    return t


# ── HTML stripping & sentence splitting ──────────────────────────────────────

def strip_html(html: str) -> str:
    """
    Convert kiran HTML content to clean plain text, mirroring
    KiranTtsController.prepareChunks().
    """
    # Block-level tags → newlines
    t = re.sub(r'</p>', '\n', html, flags=re.IGNORECASE)
    t = re.sub(r'</header>', '\n', t, flags=re.IGNORECASE)
    t = re.sub(r'<br\s*/?>', '\n', t, flags=re.IGNORECASE)

    # Strip all remaining tags (including <a href="dict:…"> glossary links)
    t = re.sub(r'<[^>]*>', '', t)

    # Decode HTML entities
    t = t.replace('&nbsp;', ' ')
    t = t.replace('&zwj;', '')
    t = t.replace('&zwnj;', '')
    t = t.replace('&shy;', '')
    t = t.replace('&#x200B;', '')
    t = t.replace('&#8203;', '')
    t = t.replace('&#160;', ' ')
    t = html_stdlib.unescape(t)            # handles &amp; &lt; &gt; &quot; etc.
    t = _RE_ENTITIES.sub('', t)           # remove any remaining numeric entities
    t = _RE_SPACES.sub(' ', t)            # collapse spaces/tabs
    return t.strip()


def prepare_tts_chunks(html: str) -> list[str]:
    """Strip HTML, normalise, then split into sentence-level chunks."""
    plain = strip_html(html)
    normalised = normalize_for_tts(plain)
    sentences: list[str] = []
    for paragraph in _RE_NEWLINES.split(normalised):
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        parts = _RE_SENTENCE_SPLIT.split(paragraph)
        for part in parts:
            s = part.strip()
            if s:
                sentences.append(s)
    return sentences


# ── JSON loading & text extraction ───────────────────────────────────────────

def load_kiran(part: int, index: int, assets_root: Path) -> dict:
    path = assets_root / f'part{part}' / f'kiran_{index}.json'
    with path.open(encoding='utf-8') as f:
        return json.load(f)


def get_kiran_html(data: dict) -> str:
    """Return the HTML content string from a kiran JSON (matches getKiranContent in Dart)."""
    main = data.get('main', data)
    lang = main.get('language', '')
    # The app uses Gujarat (gu) or English content key; fall back to 'content'
    if lang == 'en':
        return main.get('content_en', main.get('content', ''))
    return main.get('content', '')


def get_kiran_title(data: dict) -> str:
    main = data.get('main', data)
    return (
        main.get('title', '')
        or data.get('title', '')
    ).strip()


def get_kiran_number(data: dict) -> str:
    main = data.get('main', data)
    return str(main.get('number', '')).strip()


def get_kiran_footer(data: dict) -> str:
    main = data.get('main', data)
    return str(main.get('footer', '')).strip()


# ── Export ────────────────────────────────────────────────────────────────────

def export_kiran(part: int, index: int, assets_root: Path, out_root: Path) -> Path:
    data = load_kiran(part, index, assets_root)
    html = get_kiran_html(data)
    if not html:
        raise ValueError(f'No HTML content in part{part}/kiran_{index}.json')

    chunks = prepare_tts_chunks(html)
    title = get_kiran_title(data)
    number = get_kiran_number(data)
    footer = get_kiran_footer(data)
    footer_text = normalize_for_tts(strip_html(footer)) if footer else ''

    book_title = 'સાક્ષાત્ સવિતા'
    part_text = f'ભાગ {number_to_gujarati(part)}'

    out_dir = out_root / f'part{part}'
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'kiran_{index}.txt'

    with out_path.open('w', encoding='utf-8') as f:
        f.write(f'{book_title}\n')
        f.write(f'{part_text}\n')

        if number:
            f.write(f'કિરણ {number}\n')
        if title:
            f.write(f'{title}\n')
        if title or number:
            f.write('\n')

        f.write(f'સ્વામિનારાયણ હરે, સ્વામિનારાયણ હરે\n')

        f.write('\n'.join(chunks))
        f.write('\n\n')

        if footer_text:
            f.write(f'{footer_text}\n\n')

        f.write('શ્રી સહજાનંદસ્વામી મહારાજની જય\n')

    return out_path


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    repo_root = Path(__file__).resolve().parent.parent
    assets_root = repo_root / 'assets' / 'book' / 'saxatsavita'
    out_root = repo_root / 'scripts' / 'tts_output'

    parser = argparse.ArgumentParser(description='Export kiran content as TTS-ready text files.')
    parser.add_argument('--parts', nargs='+', type=int, default=[1],
                        help='Part numbers to export (default: 1)')
    parser.add_argument('--kirans', nargs='+', type=int,
                        help='Specific kiran indices to export (default: first 5)')
    parser.add_argument('--all', action='store_true',
                        help='Export all kirans across all specified parts')
    args = parser.parse_args()

    for part in args.parts:
        part_dir = assets_root / f'part{part}'
        if not part_dir.exists():
            print(f'[skip] part{part} not found at {part_dir}')
            continue

        if args.all:
            # Discover all kiran_<n>.json files, sorted numerically
            indices = sorted(
                int(p.stem.split('_')[1])
                for p in part_dir.glob('kiran_*.json')
            )
        elif args.kirans:
            indices = args.kirans
        else:
            indices = list(range(1, 6))   # default: kirans 1-5

        for idx in indices:
            try:
                out_path = export_kiran(part, idx, assets_root, out_root)
                print(f'[ok]   part{part}/kiran_{idx} → {out_path.relative_to(repo_root)}')
            except FileNotFoundError:
                print(f'[skip] part{part}/kiran_{idx}.json not found')
            except Exception as e:
                print(f'[err]  part{part}/kiran_{idx}: {e}')


if __name__ == '__main__':
    main()
