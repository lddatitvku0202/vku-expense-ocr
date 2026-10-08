"""Helpers for generating docs/REGEX_TABLE.md from the Dart sources."""
import re
import unicodedata
from pathlib import Path

# Repository root: tool/regex_table/ -> two levels up.
ROOT = Path(__file__).resolve().parents[2]
PARSER = (ROOT / "lib/services/receipt_parser.dart").read_text(encoding="utf-8")
NORMALIZER = (ROOT / "lib/core/text_normalizer.dart").read_text(encoding="utf-8")
KEYWORDS = (ROOT / "lib/services/receipt_keywords.dart").read_text(encoding="utf-8")


def dart_regex(source: str, name: str) -> str:
    """Concatenated string literal(s) passed to RegExp(...) for symbol `name`."""
    start = source.index(f"RegExp {name} = RegExp(")
    body = source[start + len(f"RegExp {name} = RegExp("):]
    parts = []
    pos = 0
    lit = re.compile(r"\s*(r?)'((?:[^'\\]|\\.)*)'")
    while True:
        m = lit.match(body, pos)
        if not m:
            break
        parts.append(m.group(2))
        pos = m.end()
    if not parts:
        raise ValueError(name)
    return "".join(parts)


def dart_list(name: str) -> list[str]:
    start = KEYWORDS.index(f"const {name} = [")
    end = KEYWORDS.index("];", start)
    return re.findall(r"'([^']*)'", KEYWORDS[start:end])


def remove_diacritics(text: str) -> str:
    for a, b in (("đ", "d"), ("Đ", "D"), ("ð", "d"), ("Ð", "D")):
        text = text.replace(a, b)
    nfd = unicodedata.normalize("NFD", text)
    return "".join(c for c in nfd if not unicodedata.combining(c))


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", remove_diacritics(text).lower()).strip()


FOLD = {"0": "o", "1": "i", "l": "i", "|": "i"}


def ocr_key(text: str) -> str:
    return "".join(FOLD.get(c, c) for c in normalize(text))


def to_python(pattern: str) -> str:
    """Dart and Python agree on everything used here except \\uXXXX."""
    return re.sub(r"\\u([0-9A-Fa-f]{4})", lambda m: chr(int(m.group(1), 16)), pattern)


def keyword_regex(words: list[str], left: str) -> str:
    folded = sorted((ocr_key(w) for w in words), key=len, reverse=True)
    body = "|".join(re.escape(w) for w in folded)
    return f"(?<!{left})(?:{body})(?![a-z0-9])"


PREP = {
    "raw": lambda s: s,
    "norm": normalize,
    "key": ocr_key,
}


def check(entry: dict) -> None:
    pattern = entry.get("python") or to_python(entry["regex"])
    prep = PREP[entry.get("prep", "raw")]
    for sample in entry.get("match", []):
        if not re.search(pattern, prep(sample)):
            raise AssertionError(f"{entry['id']}: should match {sample!r}")
    for sample in entry.get("no_match", []):
        if re.search(pattern, prep(sample)):
            raise AssertionError(f"{entry['id']}: should NOT match {sample!r}")
