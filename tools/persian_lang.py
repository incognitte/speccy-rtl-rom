"""Shared rules for the Persian language data (no Excel, no emulator).

Used by tools/genlang.py, tools/genflags.py and tools/persian_editor.py.

  * text rules: normalisation, ZWNJ cleanup, right-to-left storage, byte length, validation
  * ROM encoding of a stored text (letters -> codes, mirrored brackets, ZWNJ = $00)
  * the glyph .asm files (isolated, digits, initial/medial/final records): parse and render
    in the same readable comment style as lang/arabic/glyph_*.asm
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from typing import Any

# Letter codes the engine can shape: $41-$5A and $61-$6B ($5B-$60 hold engine hooks, $6C+ are Latin).
ROM_LETTER_CODES = tuple(range(0x41, 0x5B)) + tuple(range(0x61, 0x6C))
ZWNJ = "\u200c"
ZWNJ_TOKEN = "<ZWNJ>"
TEXT_PUNCTUATION = frozenset("$#<>=/:.,?-;[()")
ALLOWED_PUNCTUATION = TEXT_PUNCTUATION
BIDI_MARKS = frozenset(
    chr(code) for code in (0x061C, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068, 0x2069)
)
TRANSLATION = str.maketrans(
    {
        "ي": "ی",
        "ى": "ی",
        "ك": "ک",
        "،": ",",
        "؛": ";",
        "؟": "?",
        "π": "[",
        **{chr(code): str(code - 0x0660) for code in range(0x0660, 0x066A)},
        **{chr(code): str(code - 0x06F0) for code in range(0x06F0, 0x06FA)},
    }
)
FORWARD_JOINING_LETTERS = frozenset("ب پ ت ث ج چ ح خ س ش ص ض ط ظ ع غ ف ق ک گ ل م ن ه ی".split())

LETTER_NAMES = {
    "آ": "alef-madda", "ا": "alef", "ب": "be", "پ": "pe", "ت": "te", "ث": "se", "ج": "jim", "چ": "che",
    "ح": "hah", "خ": "khe", "د": "dal", "ذ": "zal", "ر": "re", "ز": "ze", "ژ": "zhe", "س": "sin",
    "ش": "shin", "ص": "sad", "ض": "zad", "ط": "tah", "ظ": "zah", "ع": "ain", "غ": "ghain", "ف": "fe",
    "ق": "qaf", "ک": "kaf", "گ": "gaf", "لا": "lam-alef", "ل": "lam", "م": "mim", "ن": "nun",
    "و": "vav", "ؤ": "vav-hamze", "ه": "heh", "ی": "ye",
}
FORM_LABEL = {"init": "INITIAL", "med": "MEDIAL", "fin": "FINAL"}


def letter_name(entry: dict) -> str:
    """Latin name of a letter for comments: letters.json 'name' wins, then the built-in table."""
    return entry.get("name") or LETTER_NAMES.get(entry["letter"], "")


def persian_digit(n: int) -> str:
    return chr(0x06F0 + n)


# ---------------------------------------------------------------------------------------
# text rules
# ---------------------------------------------------------------------------------------
def normalize_text(value: Any) -> str:
    if value is None:
        return ""
    text = unicodedata.normalize("NFC", str(value).translate(TRANSLATION))
    text = "".join(char for char in text if char not in BIDI_MARKS)
    return text.replace(ZWNJ, ZWNJ_TOKEN)


def remove_redundant_zwnj(text: str, letter_tokens: list[str]) -> tuple[str, int, bool]:
    """Drop ZWNJ that do nothing. Returns (text, number dropped, whether two words got glued)."""
    kept: list[str] = []
    dropped = 0
    glued_words = False
    index = 0
    while index < len(text):
        if text[index] != ZWNJ:
            kept.append(text[index])
            index += 1
            continue
        run_end = index + 1
        while run_end < len(text) and text[run_end] == ZWNJ:
            run_end += 1
        prefix = "".join(kept)
        previous = next((letter for letter in letter_tokens if prefix.endswith(letter)), None)
        following = text[run_end:]
        next_letter = next((letter for letter in letter_tokens if following.startswith(letter)), None)
        useful = previous in FORWARD_JOINING_LETTERS and next_letter is not None
        if useful:
            kept.append(ZWNJ)
        dropped += run_end - index - int(useful)
        if not useful and previous is not None and next_letter is not None:
            glued_words = True
        index = run_end
    return "".join(kept), dropped, glued_words


def rtl_storage_text(text: str) -> str:
    """Logical text <-> stored text: digit runs reversed, brackets mirrored (its own inverse)."""
    text = re.sub(r"[0-9]+", lambda match: match.group(0)[::-1], text)
    return text.translate(str.maketrans({"(": ")", ")": "("}))


def encoded_text_length(text: str, letter_tokens: list[str]) -> int:
    ordered = sorted(letter_tokens, key=len, reverse=True)
    byte_length = 0
    index = 0
    while index < len(text):
        letter = next((c for c in ordered if text.startswith(c, index)), None)
        index += len(letter) if letter is not None else 1
        byte_length += 1
    return byte_length


def invalid_characters(text: str, letter_tokens: list[str]) -> list[str]:
    ordered = sorted(letter_tokens, key=len, reverse=True)
    invalid: list[str] = []
    index = 0
    while index < len(text):
        if text[index] == ZWNJ:
            index += 1
            continue
        letter = next((c for c in ordered if text.startswith(c, index)), None)
        if letter is not None:
            index += len(letter)
            continue
        char = text[index]
        if char not in " 0123456789" and char not in TEXT_PUNCTUATION:
            invalid.append(char)
        index += 1
    return invalid


def text_record(
    value: Any,
    letter_tokens: list[str],
    *,
    maximum: int | None = None,
    strip_scroll_question: bool = False,
    enforce_maximum: bool = True,
    cursor_letter_only: bool = False,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    """Turn what the human typed into the stored fields of a text.json entry, plus the problems found."""
    normalized = normalize_text(value).replace(ZWNJ_TOKEN, ZWNJ)
    stripped_scroll_question = False
    if strip_scroll_question and normalized.endswith(("?", "؟")):
        normalized = normalized[:-1]
        stripped_scroll_question = True
    text, dropped, glued_words = remove_redundant_zwnj(normalized, letter_tokens)
    text = rtl_storage_text(text)
    byte_length = encoded_text_length(text, letter_tokens)
    record: dict[str, Any] = {
        "text": text.replace(ZWNJ, ZWNJ_TOKEN),
        "byte_length": byte_length,
        "zwnj_count": text.count(ZWNJ),
        "max_bytes": maximum,
    }
    if stripped_scroll_question:
        record["automatic_trailing_question_stripped"] = True
    issues: list[dict[str, Any]] = []
    if value is None or not str(value).strip():
        issues.append({"category": "empty_text"})
    invalid = invalid_characters(text, letter_tokens)
    if cursor_letter_only and text not in letter_tokens:
        issues.append({"category": "cursor_letter_not_included", "characters": [text] if text else []})
    elif invalid:
        issues.append({"category": "characters_not_allowed", "characters": list(dict.fromkeys(invalid))})
    if dropped:
        issues.append({"category": "redundant_zwnj_dropped", "count": dropped})
    if glued_words:
        issues.append({"category": "adjacent_words_after_zwnj_cleanup"})
    if enforce_maximum and maximum is not None and byte_length > maximum:
        issues.append({"category": "over_limit", "actual_bytes": byte_length, "limit_bytes": maximum, "over_by": byte_length - maximum})
    return record, issues


def to_logical(stored: str) -> str:
    """Stored text.json text -> what the human types (ZWNJ as the real character)."""
    return rtl_storage_text(stored.replace(ZWNJ_TOKEN, ZWNJ))


def flag_byte(bits: dict[str, bool]) -> int:
    return (
        (0x80 if bits["b7_joins_forward"] else 0)
        | (0x40 if bits["b6_no_initial"] else 0)
        | (0x20 if bits["b5_no_medial"] else 0)
        | (0x10 if bits["b4_no_final"] else 0)
        | 0x0F
    )


def encode(text: str, code_by_letter: dict[str, int]) -> list[tuple[int, str]]:
    """Stored text -> [(ROM byte, readable piece)]. ZWNJ token = $00, brackets map to $29/$28."""
    ordered = sorted(code_by_letter, key=len, reverse=True)
    result: list[tuple[int, str]] = []
    position = 0
    while position < len(text):
        if text.startswith(ZWNJ_TOKEN, position):
            result.append((0, ZWNJ_TOKEN))
            position += len(ZWNJ_TOKEN)
            continue
        matched = next((letter for letter in ordered if text.startswith(letter, position)), None)
        if matched is not None:
            result.append((code_by_letter[matched], matched))
            position += len(matched)
            continue
        character = text[position]
        if ord(character) > 0x7F:
            raise ValueError(f"no Persian letter code for {character!r}")
        value = {"(": 0x29, ")": 0x28}.get(character, ord(character))
        result.append((value, character))
        position += 1
    return result


def byte_comment(value: int, piece: str, last: bool = False) -> str:
    """Comment for one stored byte: the letter (or what the byte draws) and why it is special."""
    if piece == ZWNJ_TOKEN:
        text = "ZWNJ (zero-width non-joiner, takes no cell)"
    elif piece == " ":
        text = "' ' space"
    elif len(piece) == 1 and ord(piece) < 0x80:
        drawn = chr(value & 0x7F)
        text = f"'{drawn}'" + (" (mirrored bracket)" if piece in "()" else "")
    else:
        text = piece
    return text + ("  (last byte: bit 7 set = end of message)" if last else "")


def db_line(value: int, comment: str = "") -> str:
    return f"        DB          ${value:02X}" + (f" ; {comment}" if comment else "")


def message_lines(text: str, code_by_letter: dict[str, int]) -> list[str]:
    """One DB per byte with the letter as comment; the last byte gets bit 7 set."""
    encoded = encode(text, code_by_letter)
    if not encoded:
        raise ValueError("empty message")
    lines = [db_line(v, byte_comment(v, p)) for v, p in encoded[:-1]]
    value, piece = encoded[-1]
    lines.append(db_line(value | 0x80, byte_comment(value, piece, last=True)))
    return lines


# ---------------------------------------------------------------------------------------
# glyph .asm files: parse (keeping human content) and render (readable comments)
# ---------------------------------------------------------------------------------------
BIN_RE = re.compile(r"^(\s*DB\s+)%([01]{8})(.*)$", re.IGNORECASE)
KEY_RE = re.compile(r"^\s*DB\s+\$([0-9A-Fa-f]{2})(?:\s|,|;|$)", re.IGNORECASE)
AUTO_HEAD = re.compile(r"^\s*;\s*((key\s+)?'[^']*'|digit\b)")
AUTO_ROW = re.compile(r"^;\s*(\S+\s+(ISO|INITIAL|MEDIAL|FINAL)|digit\s*\d+)\s*$")


@dataclass
class GlyphBlock:
    code: int  # letter code, or the digit 0-9
    rows: list[int]
    row_notes: list[str] = field(default_factory=lambda: [""] * 8)
    extras: list[str] = field(default_factory=list)  # human comments that are not the generated header


@dataclass
class GlyphFile:
    kind: str  # iso, digit, init, med, fin
    header: list[str]
    blocks: list[GlyphBlock]
    tail: list[str]

    @staticmethod
    def parse(kind: str, text: str, codes: list[int] | None = None) -> "GlyphFile":
        lines = text.split("\n")
        bin_idx = [i for i, line in enumerate(lines) if BIN_RE.match(line)]
        if len(bin_idx) % 8:
            raise ValueError(f"{len(bin_idx)} bitmap rows is not a multiple of 8")
        groups = [bin_idx[k : k + 8] for k in range(0, len(bin_idx), 8)]
        if kind in FORM_LABEL:
            starts = [i for i, line in enumerate(lines) if KEY_RE.match(line)]
            if len(starts) != len(groups) or any(g[0] != s + 1 for g, s in zip(groups, starts)):
                raise ValueError("every record must be one $KEY line followed by 8 bitmap rows")
            block_codes = [int(KEY_RE.match(lines[s]).group(1), 16) for s in starts]
        else:
            if codes is None or len(codes) != len(groups):
                raise ValueError(f"expected {len(codes) if codes is not None else '?'} glyphs, found {len(groups)}")
            starts = [g[0] for g in groups]
            block_codes = list(codes)
        header: list[str] = []
        blocks: list[GlyphBlock] = []
        previous_end = -1
        for k, (group, start, code) in enumerate(zip(groups, starts, block_codes)):
            region = lines[previous_end + 1 : start]
            comment_index = len(region) - 1 if region and region[-1].strip().startswith(";") else None
            leading = region[:comment_index] if comment_index is not None else region
            extras: list[str] = []
            if comment_index is not None and not AUTO_HEAD.match(region[comment_index]):
                extras.append(region[comment_index])
            if k == 0:
                header = list(leading)
                while header and not header[-1].strip():
                    header.pop()
            else:
                extras = [line for line in leading if line.strip().startswith(";")] + extras
            rows = [int(BIN_RE.match(lines[i]).group(2), 2) for i in group]
            notes = []
            for i in group:
                note = BIN_RE.match(lines[i]).group(3).strip()
                notes.append("" if (not note or AUTO_ROW.match(note)) else note)
            blocks.append(GlyphBlock(code, rows, notes, extras))
            previous_end = group[-1]
        tail = lines[previous_end + 1 :] if blocks else []
        if not blocks:
            header = list(lines)
        return GlyphFile(kind, header, blocks, tail if blocks else [])

    def render(self, describe) -> str:
        """describe(code) -> (letter, name) for comments; ignored for digits."""
        out = list(self.header)
        for block in self.blocks:
            out.append("")
            out += block.extras
            out.append(glyph_comment(self.kind, block.code, *(describe(block.code) if self.kind != "digit" else ("", ""))))
            if self.kind in FORM_LABEL:
                out.append(f"        DB          ${block.code:02X}")
            for row, note in zip(block.rows, block.row_notes):
                out.append(f"        DB          %{row:08b}" + (f" {note}" if note else ""))
        out += self.tail if self.blocks else [""]
        return "\n".join(out)


def glyph_comment(kind: str, code: int, letter: str, name: str) -> str:
    """Same wording as lang/arabic: "; 'A' ء hamza", "; key 'H' ب ba (MEDIAL form)", "; '2' ٢"."""
    if kind == "digit":
        return f"; '{code}' {persian_digit(code)}"
    key = chr(code)
    label = f"{letter} {name}".rstrip()
    if kind == "iso":
        return f"; '{key}' {label}"
    return f"; key '{key}' {label} ({FORM_LABEL[kind]} form)"


# (kind, first code, last code) of every hand-owned glyph file
GLYPH_FILES = {
    "glyph_digits.asm": ("digit", None, None),
    "glyph_iso_a.asm": ("iso", 0x41, 0x5A),
    "glyph_iso_b.asm": ("iso", 0x61, 0x6B),
    "glyph_initial.asm": ("init", None, None),
    "glyph_medial.asm": ("med", None, None),
    "glyph_final.asm": ("fin", None, None),
}


def load_glyph_files(lang_dir, included_codes: list[int]) -> dict[str, GlyphFile]:
    files: dict[str, GlyphFile] = {}
    for name, (kind, low, high) in GLYPH_FILES.items():
        codes = list(range(10)) if kind == "digit" else [c for c in sorted(included_codes) if low <= c <= high] if kind == "iso" else None
        try:
            files[name] = GlyphFile.parse(kind, (lang_dir / name).read_text(encoding="utf-8"), codes)
        except (ValueError, OSError) as error:
            raise ValueError(f"{name}: {error}") from error
    return files


def refresh_glyph_comments(lang_dir, letters: list[dict]) -> list[str]:
    """Rewrite only the comment lines of the glyph files (bitmaps and human notes are kept).
    Returns the names of the files that changed."""
    included = [e for e in letters if e.get("include", True)]
    by_code = {e["code"]: e for e in included}
    files = load_glyph_files(lang_dir, [e["code"] for e in included])
    changed = []
    for name, glyph_file in files.items():
        text = glyph_file.render(lambda code: (by_code[code]["letter"], letter_name(by_code[code])))
        text = text if text.endswith("\n") else text + "\n"
        path = lang_dir / name
        if path.read_text(encoding="utf-8") != text:
            path.write_text(text, encoding="utf-8")
            changed.append(name)
    return changed
