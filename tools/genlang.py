#!/usr/bin/env python3
"""Generate the Persian language includes from fixtures/persian/*.json.

The JSON files are edited with `make edit-persian` (tools/persian_editor.py); there is no other
source. The glyph_*.asm files are hand-owned: this tool only seeds them once (or on --reseed-glyphs).
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

try:
    import persian_lang as pl
except ImportError:  # imported as tools.<module>
    from tools import persian_lang as pl

ROOT = Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "fixtures" / "persian"
OUTPUT = ROOT / "lang" / "persian"
GLYPHS = FIXTURES / "glyphs"
FORMS = ("fin", "med", "init")
FORM_FILE = {"fin": "glyph_final.asm", "med": "glyph_medial.asm", "init": "glyph_initial.asm"}
GENERATED_GLYPHS = ("glyph_digits.asm", "glyph_iso_a.asm", "glyph_iso_b.asm", *FORM_FILE.values())
CURSOR_NAMES = {"K": "keyword", "E": "extended", "G": "graphics", "L": "letter"}
BANNER = "; " + "=" * 76


def load_json(path: Path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def db_line(value: int, comment: str = "") -> str:
    return pl.db_line(value, comment)


def banner(*lines: str) -> list[str]:
    return [BANNER, *(f"; {line}" for line in lines), BANNER]


def show(entry: dict) -> str:
    """The Persian text as the human reads it (ZWNJ shown as a dot)."""
    return pl.to_logical(entry.get("text", "")).replace(pl.ZWNJ, "·")


def meaning(entry: dict, prefix: str = "   - ") -> str:
    return f"{prefix}{entry['meaning']}" if entry.get("meaning") else ""


def letters_by_code(letters: list[dict]) -> dict[int, dict]:
    return {e["code"]: e for e in letters if e.get("include", True)}


def write_text_includes() -> None:
    letters = load_json(FIXTURES / "letters.json")["letters"]
    code_by_letter = {e["letter"]: e["code"] for e in letters if e.get("include", True)}
    by_code = letters_by_code(letters)
    data = load_json(FIXTURES / "text.json")
    outputs: dict[str, list[str]] = {}

    keywords = banner(
        "PERSIAN BASIC KEYWORDS TABLE ($A5-$FF)",
        "Dummy entry precedes $A5 token (RND) as the step-over byte.",
        "Stored in RTL print order with bit 7 set on each keyword's last byte.",
    ) + [db_line(0xBF, "dummy keyword step-over byte (precedes RND)")]
    entries = sorted(data["keywords"], key=lambda item: int(item["token"], 16))
    if [int(entry["token"], 16) for entry in entries] != list(range(0xA5, 0x100)):
        raise ValueError("keywords must contain tokens $A5-$FF exactly once")
    for entry in entries:
        token = int(entry["token"], 16)
        keywords.append(f"; ${entry['token']} ({token})  {entry.get('english', ''):<10}{show(entry)}{meaning(entry)}")
        keywords.extend(_message(entry, code_by_letter, f"keyword ${entry['token']}"))
    outputs["keywords.asm"] = keywords

    copyright_entry = next(e for e in data["other"] if e["item"] == "Copyright text")
    copyright_lines = banner(
        "PERSIAN BOOT COPYRIGHT LINE ($01ED-$0204)",
        "Printed right-to-left; the last character has bit 7 set as terminator.",
    ) + [
        f"; copyright text: (c) {show(copyright_entry)}{meaning(copyright_entry)}",
        db_line(0x7F, "(c) copyright glyph / message step-over byte"),
        db_line(0x20, "' ' space separator"),
    ]
    copyright_lines.extend(_message(copyright_entry, code_by_letter, "copyright"))
    outputs["copyright.asm"] = copyright_lines

    tape_entries = [e for e in data["other"] if e["item"].startswith("Tape message ")]
    if len(tape_entries) != 5:
        raise ValueError(f"expected 5 tape messages, got {len(tape_entries)}")
    tape = banner("PERSIAN CASSETTE (TAPE) MESSAGES", "Messages 0 to 4 with carriage returns and ':' terminator.")
    tape.append(db_line(0x80, "initial step-over byte (message 0 starts after it)"))
    for index, entry in enumerate(tape_entries):
        encoded = pl.encode(entry["text"], code_by_letter)
        if not encoded:
            raise ValueError(f"tape message {index}: empty message")
        tape.append(";")
        tape.append(f"; Cassette message {index}  ->  \"{entry.get('english', '')}\"")
        tape.append(f";     {show(entry)}" + (f"   (literal: \"{entry['meaning']}\")" if entry.get("meaning") else ""))
        if index == 0:
            tape.extend(db_line(v, pl.byte_comment(v, p)) for v, p in encoded[:-1])
            tape.append("TAPE_MSG_0_END:")
            value, piece = encoded[-1]
            tape.append(db_line(value | 0x80, pl.byte_comment(value, piece, last=True)))
            continue
        tape.append(db_line(0x0D, "carriage return"))
        tape.extend(db_line(v, pl.byte_comment(v, p)) for v, p in encoded)
        if index == 4:
            tape.append("TAPE_MSG_4_END:")
        tape.append(db_line(ord(":") | 0x80, "':' + $80 message terminator"))
    outputs["tape_msgs.asm"] = tape

    scroll_entry = next(e for e in data["other"] if e["item"] == "Scroll prompt")
    encoded = pl.encode(scroll_entry["text"], code_by_letter)
    if len(encoded) + 3 != 8:
        raise ValueError(f"scroll prompt must occupy exactly 8 bytes, got {len(encoded) + 3}")
    scroll = banner(
        "PERSIAN SCROLL PROMPT",
        "Control code $04 (Persian / RTL ON) followed by the prompt text and '?' + $80 terminator.",
    ) + [
        f"; scroll prompt \"{show(scroll_entry)}?\"  ->  \"{scroll_entry.get('english', 'scroll?')}\"{meaning(scroll_entry)}",
        db_line(0x80, "initial step-over byte"),
        db_line(0x04, "Persian ON (RTL ON)"),
    ]
    scroll.extend(db_line(v, pl.byte_comment(v, p)) for v, p in encoded)
    scroll.append(db_line(ord("?") | 0x80, "'?' + $80: last byte has bit 7 set = end of message"))
    outputs["scroll_msg.asm"] = scroll

    reports = banner(
        "PERSIAN REPORT ERROR MESSAGES (0-27)",
        "Table starts with $80 step-over byte; each message ends with bit 7 set.",
    ) + [db_line(0x80, "initial step-over byte")]
    if len(data["reports"]) != 28:
        raise ValueError(f"expected 28 reports, got {len(data['reports'])}")
    for entry in data["reports"]:
        reports.append(f"; report {entry.get('code', '')}  {entry.get('english', '')}  =>  {show(entry)}{meaning(entry)}")
        reports.extend(_message(entry, code_by_letter, f"report {entry.get('code', '')}"))
    outputs["reports.asm"] = reports

    keys = load_json(FIXTURES / "key_layout.json")["entries"]
    if len(keys) != 58:
        raise ValueError(f"expected 58 key lookup entries, got {len(keys)}")
    key_lines = banner(
        "ASCII-INDEXED PHYSICAL KEY LOOKUP TABLE ($41-$7A)",
        "Maps ASCII characters to Persian key codes: capitals = Caps Shift + key, lowercase = plain key.",
    )
    for entry in keys:
        ch = entry["ascii"]
        code = int(entry["code_hex"], 16)
        slot = f"Caps Shift + {ch}" if ch.isupper() else f"key {ch.upper()} plain" if ch.islower() else "(no key)"
        if code == 0x3F:
            result = "unmapped"
        elif code == 0x5D:
            result = "']' exponent marker (the E key)"
        else:
            letter = by_code.get(code, {})
            result = f"'{chr(code)}' {entry.get('arabic') or ''} {pl.letter_name(letter) if letter else ''}".rstrip()
        key_lines.append(db_line(code, f"'{ch}' {slot:<16} -> {result}"))
    outputs["key_lookup.asm"] = key_lines

    cursors = {entry["mode"]: entry for entry in data["cursor_letters"]}
    if set(cursors) != {"K", "E", "G", "L"}:
        raise ValueError("cursor_letters must provide K, E, G, and L")
    cursor_lines = banner("PERSIAN CURSOR LETTERS TABLE", "Single-byte letter codes for BASIC editor modes in K, E, G, L order.")
    for mode in ("K", "E", "G", "L"):
        encoded = pl.encode(cursors[mode]["text"], code_by_letter)
        if len(encoded) != 1:
            raise ValueError(f"cursor letter {mode} must encode to one byte")
        cursor_lines.append(db_line(encoded[0][0], f"mode {mode} ({CURSOR_NAMES[mode]} cursor): {encoded[0][1]}"))
    outputs["cursor_letters.asm"] = cursor_lines

    for filename, lines in outputs.items():
        (OUTPUT / filename).write_text("\n".join(lines) + "\n", encoding="utf-8")
    source = (ROOT / "lang" / "arabic" / "sym_digits.asm").read_text(encoding="utf-8")
    (OUTPUT / "sym_digits.asm").write_text(source, encoding="utf-8")


def _message(entry: dict, code_by_letter: dict[str, int], context: str) -> list[str]:
    try:
        return pl.message_lines(entry["text"], code_by_letter)
    except ValueError as error:
        raise ValueError(f"{context}: {error}") from error


# ---- one-time seeding of the hand-owned glyph files (--reseed-glyphs) ---------------------
def read_bitmap(path: Path) -> list[int]:
    rows = [line.strip() for line in path.read_text(encoding="ascii").splitlines() if line.strip()]
    if len(rows) != 8 or any(len(row) != 8 or set(row) - {".", "#"} for row in rows):
        raise ValueError(f"{path.relative_to(ROOT)} must contain exactly eight 8x8 #/. rows")
    return [int(row.replace("#", "1").replace(".", "0"), 2) for row in rows]


def make_hand_owned_glyphs() -> dict[str, str]:
    letters = [e for e in load_json(FIXTURES / "letters.json")["letters"] if e.get("include", True)]
    by_code = letters_by_code(letters)

    def describe(code: int):
        return by_code[code]["letter"], pl.letter_name(by_code[code])

    def header(title: str, extra: str = "") -> list[str]:
        return banner(title, *( [extra] if extra else []),
                      "HAND-OWNED bitmaps: edit here or with `make edit-persian`; tools only refresh the comments.")

    files: dict[str, str] = {}
    digits = pl.GlyphFile("digit", header("PERSIAN DIGIT FONT: 10 Persian digits (0-9)"),
                          [pl.GlyphBlock(d, read_bitmap(GLYPHS / f"digit_{d}.txt")) for d in range(10)], [""])
    files["glyph_digits.asm"] = digits.render(describe)
    for filename, low, high, title in (
        ("glyph_iso_a.asm", 0x41, 0x5A, "PERSIAN ISOLATED FONT A ($41-$5A)"),
        ("glyph_iso_b.asm", 0x61, 0x6B, "PERSIAN ISOLATED FONT B ($61-$6B)"),
    ):
        blocks = [pl.GlyphBlock(e["code"], read_bitmap(GLYPHS / f"{e['code']:02X}_iso.txt")) for e in letters if low <= e["code"] <= high]
        files[filename] = pl.GlyphFile("iso", header(title), blocks, [""]).render(describe)
    for form in FORMS:
        blocks = [pl.GlyphBlock(e["code"], read_bitmap(GLYPHS / f"{e['code']:02X}_{form}.txt")) for e in letters if form in e.get("forms", [])]
        title = f"PERSIAN GLYPH TABLE ({pl.FORM_LABEL[form]} FORM)"
        files[FORM_FILE[form]] = pl.GlyphFile(form, header(title, "9-byte records: 1-byte letter code key followed by 8-byte font bitmap."), blocks, [""]).render(describe)
    return files


def seed_glyphs(reseed: bool) -> None:
    existing = [name for name in GENERATED_GLYPHS if (OUTPUT / name).exists()]
    if existing and not reseed:
        if len(existing) == len(GENERATED_GLYPHS):
            return
        raise ValueError("partial hand-owned glyph set exists; refusing to overwrite any glyph file")
    glyphs = make_hand_owned_glyphs()
    if reseed:
        for name in existing:
            backup = OUTPUT / f"{name}.bak"
            if backup.exists():
                raise ValueError(f"refusing to overwrite existing backup {backup.relative_to(ROOT)}")
            shutil.copy2(OUTPUT / name, backup)
    for name, text in glyphs.items():
        (OUTPUT / name).write_text(text + "\n" if not text.endswith("\n") else text, encoding="utf-8")


def write_readme() -> None:
    content = """# Persian language files

Edit everything with `make edit-persian` (tools/persian_editor.py). The JSON files in
`fixtures/persian/` are the only source of the texts, letters and keyboard.

Generated by `make genlang` / `make genflags` (do not edit by hand):
`keywords`, `reports`, `copyright`, `tape_msgs`, `scroll_msg`, `key_lookup`, `cursor_letters`, `flags`.

The `glyph_*.asm` files are hand-owned: the bitmaps are yours. The editor rewrites only their
comment lines. `tools/genlang.py --reseed-glyphs` rebuilds them from `fixtures/persian/glyphs/`
(a `.bak` copy is made first).
"""
    (OUTPUT / "README.md").write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reseed-glyphs", action="store_true")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    write_text_includes()
    seed_glyphs(args.reseed_glyphs)
    refreshed = pl.refresh_glyph_comments(OUTPUT, load_json(FIXTURES / "letters.json")["letters"])
    write_readme()
    print("Generated Persian text includes; hand-owned glyph bitmaps preserved"
          + (f" (comments refreshed in {len(refreshed)} glyph file(s))." if refreshed else "."))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
