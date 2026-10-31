#!/usr/bin/env python3
"""Derive Persian glyph flags from the hand-owned glyph record tables."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    import persian_lang as pl
except ImportError:  # imported as tools.<module>
    from tools import persian_lang as pl

ROOT = Path(__file__).resolve().parent.parent
LANG = ROOT / "lang" / "persian"
LETTERS_PATH = ROOT / "fixtures" / "persian" / "letters.json"
TABLES = {
    "final": LANG / "glyph_final.asm",
    "medial": LANG / "glyph_medial.asm",
    "initial": LANG / "glyph_initial.asm",
}
DB_RE = re.compile(r"^\s*DB\s+\$([0-9A-Fa-f]{2})(?:\s|,|;|$)")


def load_records(path: Path, included: set[int]) -> list[int]:
    db_lines = [line for line in path.read_text(encoding="utf-8").splitlines() if re.match(r"^\s*DB\b", line, re.IGNORECASE)]
    if len(db_lines) % 9:
        raise ValueError(f"{path.name}: {len(db_lines)} DB lines is not a multiple of 9")
    keys = []
    for offset in range(0, len(db_lines), 9):
        match = DB_RE.match(db_lines[offset])
        if match is None:
            raise ValueError(f"{path.name}: record at DB line {offset + 1} has no $XX key")
        keys.append(int(match.group(1), 16))
    invalid = [code for code in keys if code not in pl.ROM_LETTER_CODES]
    if invalid:
        raise ValueError(f"{path.name}: non-letter record key(s): {', '.join(f'${c:02X}' for c in invalid)}")
    unknown = [code for code in keys if code not in included]
    if unknown:
        raise ValueError(f"{path.name}: record key(s) without a letter in letters.json: {', '.join(f'${c:02X}' for c in unknown)}")
    if len(keys) != len(set(keys)):
        raise ValueError(f"{path.name}: duplicate record key")
    return keys


def main() -> int:
    letters = json.loads(LETTERS_PATH.read_text(encoding="utf-8"))["letters"]
    included = {item["code"]: item for item in letters if item.get("include", True)}
    records = {form: set(load_records(path, set(included))) for form, path in TABLES.items()}
    flag_bytes = []
    lines = [
        "; ============================================================================",
        "; PERSIAN GLYPH FLAGS TABLE ($34BC-$34E6, 43 bytes)",
        "; Flags for codes $41-$6B describing forward joining and available forms.",
        "; Bit 7: 1 = joins forward (0 = no fwd join)",
        "; Bit 6: 0 = has INITIAL form in table (1 = no initial form)",
        "; Bit 5: 0 = has MEDIAL form in table (1 = no medial form)",
        "; Bit 4: 0 = has FINAL form in table (1 = no final form)",
        "; Low nibble is $F.",
        "; ============================================================================",
    ]
    for code in range(0x41, 0x6C):
        entry = included.get(code)
        if entry is None:
            value = 0x7F
            desc = f"'{chr(code)}' (not a letter, unused): no fwd join; forms: isolated"
        else:
            value = (
                (0x80 if entry["joins_forward"] else 0)
                | (0 if code in records["initial"] else 0x40)
                | (0 if code in records["medial"] else 0x20)
                | (0 if code in records["final"] else 0x10)
                | 0x0F
            )
            expected = int(entry["flag_hex"], 16)
            if value != expected:
                raise ValueError(
                    f"letter {entry['letter']} code ${code:02X}: derived flag ${value:02X}, "
                    f"letters.json says ${expected:02X} (run the editor and save, or fix flag_hex)"
                )
            avail = ["isolated"] + [name for name, form in (("initial", "initial"), ("medial", "medial"), ("final", "final")) if code in records[form]]
            fwd = "joins fwd" if entry["joins_forward"] else "no fwd join"
            desc = f"'{chr(code)}' {entry['letter']} {pl.letter_name(entry)}: {fwd}; forms: {', '.join(avail)}"
        flag_bytes.append(value)
        lines.append(f"        DB          ${value:02X} ; {desc}")
    if len(flag_bytes) != 43:
        raise ValueError(f"flag table must be 43 bytes, got {len(flag_bytes)}")
    (LANG / "flags.asm").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Flag cross-check passed for {len(included)} letters; table is 43 bytes.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as error:
        raise SystemExit(f"genflags: {error}")
