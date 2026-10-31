#!/usr/bin/env python3
"""Interactive Tk GUI editor for the Persian ROM language data.

Start it with:
    make edit-persian
or:
    python3 tools/persian_editor.py
(--check validates without a GUI, exits 1 on errors)

Edits:
  * fixtures/persian/text.json        reports, keywords, tape, copyright, scroll prompt, cursor letters
  * fixtures/persian/letters.json     joining flag per letter, flag/forms metadata
  * fixtures/persian/key_layout.json  physical key -> Persian letter
  * lang/persian/glyph_*.asm          hand-owned 8x8 bitmaps (comments refreshed, bitmaps preserved)
The generated includes (keywords.asm, reports.asm, flags.asm, ...) are produced by `make genflags`
(tools/genlang.py + tools/genflags.py), which this editor can run.
No emulator is ever run.
"""

from __future__ import annotations

import argparse
import copy
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import threading
from dataclasses import dataclass
from pathlib import Path

try:
    from tools.glyph_geometry import JOIN_ROW
except ImportError:
    from glyph_geometry import JOIN_ROW

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
try:
    import persian_lang as pl
except ImportError as error:  # pragma: no cover
    sys.exit(f"persian_editor: {error}")

ZWNJ = pl.ZWNJ
ZWNJ_TOKEN = pl.ZWNJ_TOKEN
FORMS = ("init", "med", "fin")
FORM_NAME = {"iso": "ISOLATED", "init": "INITIAL", "med": "MEDIAL", "fin": "FINAL", "digit": "DIGIT"}
FORM_FILE = {"init": "glyph_initial.asm", "med": "glyph_medial.asm", "fin": "glyph_final.asm"}
SHARED_TOTAL = 989
DIGIT_BYTES = 80
MARKER_BYTES = 1
REPORT_SOFT_TARGET = 244
SCROLL_TEXT_BYTES = 5
DIGIT_RUN = re.compile(r"[0-9]+")
MIRROR = {"(": ")", ")": "("}
GROUPS = ("reports", "keywords", "tape", "copyright", "scroll", "cursor")


class ProjectError(Exception):
    pass


@dataclass
class Issue:
    level: str  # E error, W warning, I info
    where: str
    msg: str


to_logical = pl.to_logical


def dump_json(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, indent=2) + "\n"


def hamming(a: list, b: list) -> int:
    return sum(bin(x ^ y).count("1") for x, y in zip(a, b))


# --------------------------------------------------------------------------------------
# Project model: headless logic for validation, calculations, budgets, and files.
# --------------------------------------------------------------------------------------
class Project:
    def __init__(self, root: Path):
        self.root = root
        self.fix = root / "fixtures" / "persian"
        self.lang = root / "lang" / "persian"
        for path in (self.fix / "letters.json", self.fix / "text.json", self.fix / "key_layout.json", self.lang):
            if not path.exists():
                raise ProjectError(f"missing {path} (run from the repository root or pass --root)")
        self.letters_doc = json.loads((self.fix / "letters.json").read_text(encoding="utf-8"))
        self.text = json.loads((self.fix / "text.json").read_text(encoding="utf-8"))
        self.keys_doc = json.loads((self.fix / "key_layout.json").read_text(encoding="utf-8"))
        self.d8 = "بله"
        decisions = self.fix / "decisions.json"
        if decisions.exists():
            for item in json.loads(decisions.read_text(encoding="utf-8")).get("decisions", []):
                if item.get("id") == "D8":
                    self.d8 = item.get("answer", self.d8)
        self._baseline = {
            "fixtures/persian/text.json": dump_json(self.text),
            "fixtures/persian/letters.json": dump_json(self.letters_doc),
            "fixtures/persian/key_layout.json": dump_json(self.keys_doc),
        }
        try:
            self.files = pl.load_glyph_files(self.lang, self.included_codes())
        except ValueError as error:
            raise ProjectError(str(error)) from error
        for name in self.files:
            self._baseline[f"lang/persian/{name}"] = (self.lang / name).read_text(encoding="utf-8")
        self.iso: dict[int, list] = {
            block.code: block.rows for name in ("glyph_iso_a.asm", "glyph_iso_b.asm") for block in self.files[name].blocks
        }
        self.digits: list[list] = [block.rows for block in self.files["glyph_digits.asm"].blocks]
        self.keyboard = self._keyboard_from_doc()
        self._version = 0
        self._dirty_version = -1
        self._dirty_value = False
        self.legacy_removed = self._drop_legacy_cells()
        self.refresh_letter_meta()
        self.refresh_totals()

    def _drop_legacy_cells(self) -> int:
        """Entries used to carry a workbook cell name ("4_Reports!E4"). Nothing reads it any more."""
        removed = 0
        for group in GROUPS:
            for entry in self.entries(group):
                if "cell" in entry:
                    del entry["cell"]
                    removed += 1
        return removed

    # ---- letters ---------------------------------------------------------------------
    @property
    def letters(self) -> list[dict]:
        return self.letters_doc["letters"]

    def included(self) -> list[dict]:
        return sorted((e for e in self.letters if e.get("include", True)), key=lambda e: e["code"])

    def included_codes(self) -> list[int]:
        return [e["code"] for e in self.included()]

    def letter_by_code(self, code: int) -> dict | None:
        return next((e for e in self.included() if e["code"] == code), None)

    def letter_tokens(self) -> list[str]:
        return sorted({e["letter"] for e in self.included()}, key=len, reverse=True)

    def code_by_letter(self) -> dict[str, int]:
        return {e["letter"]: e["code"] for e in self.included()}

    def touch(self) -> None:
        self._version += 1

    # ---- glyph files -----------------------------------------------------------------
    @property
    def tables(self) -> dict[str, list]:
        return {f: self.table(f) for f in FORMS}

    def table(self, form: str) -> list:
        return self.files[FORM_FILE[form]].blocks

    def rec(self, form: str, code: int):
        return next((r for r in self.table(form) if r.code == code), None)

    def fallback_rows(self, form: str, code: int) -> list:
        """Glyph the engine draws when `form` has no record (MEDIAL -> INITIAL -> ISOLATED)."""
        if form == "med":
            init = self.rec("init", code)
            return init.rows if init else self.iso[code]
        return self.iso[code]

    def glyph(self, code: int, form: str) -> list:
        if form == "iso":
            return self.iso[code]
        record = self.rec(form, code)
        return record.rows if record else self.fallback_rows(form, code)

    def get_rows(self, kind: str, code: int) -> list | None:
        if kind == "iso":
            return self.iso[code]
        if kind == "digit":
            return self.digits[code]
        record = self.rec(kind, code)
        return record.rows if record else None

    def create_record(self, form: str, code: int) -> list:
        blocks = self.table(form)
        position = next((i for i, r in enumerate(blocks) if r.code > code), len(blocks))
        blocks.insert(position, pl.GlyphBlock(code, list(self.fallback_rows(form, code))))
        self.refresh_letter_meta()
        self.touch()
        return blocks[position].rows

    def delete_record(self, form: str, code: int) -> None:
        blocks = self.table(form)
        blocks[:] = [r for r in blocks if r.code != code]
        self.refresh_letter_meta()
        self.touch()

    def render_glyph_files(self) -> dict[str, str]:
        by_code = {e["code"]: e for e in self.included()}

        def describe(code: int):
            return by_code[code]["letter"], pl.letter_name(by_code[code])

        out = {}
        for name, glyph_file in self.files.items():
            text = glyph_file.render(describe)
            out[name] = text if text.endswith("\n") else text + "\n"
        return out

    # ---- letter metadata (kept consistent with genflags.py's cross-check) ---------------
    def refresh_letter_meta(self) -> None:
        for entry in self.letters:
            code = entry["code"]
            has = {f: self.rec(f, code) is not None for f in FORMS}
            joins = bool(entry["joins_forward"])
            bits = {
                "b7_joins_forward": joins,
                "b6_no_initial": not has["init"],
                "b5_no_medial": not has["med"],
                "b4_no_final": not has["fin"],
            }
            forms = ["iso"] + [f for f in FORMS if has[f]]
            fallbacks: dict[str, str] = {}
            if bits["b6_no_initial"] and joins:
                fallbacks["init"] = "iso"
            if bits["b5_no_medial"] and joins:
                fallbacks["med"] = "init" if self.d8 == "بله" and has["init"] else "iso"
            if bits["b4_no_final"]:
                fallbacks["fin"] = "iso"
            entry["flag_hex"] = f"{pl.flag_byte(bits):02X}"
            entry["flag_bits"] = bits
            entry["forms"] = forms
            entry["form_fallbacks"] = fallbacks

    def flag_of(self, code: int) -> int:
        entry = self.letter_by_code(code)
        return int(entry["flag_hex"], 16) if entry else 0x7F

    # ---- texts ---------------------------------------------------------------------------
    def entries(self, group: str) -> list[dict]:
        other = self.text["other"]
        if group in ("keywords", "reports"):
            return self.text[group]
        if group == "tape":
            return [e for e in other if e["item"].startswith("Tape message ")]
        if group == "copyright":
            return [e for e in other if e["item"] == "Copyright text"]
        if group == "scroll":
            return [e for e in other if e["item"] == "Scroll prompt"]
        if group == "cursor":
            return sorted(self.text["cursor_letters"], key=lambda e: "KEGL".index(e["mode"]))
        raise KeyError(group)

    @staticmethod
    def label(group: str, e: dict) -> str:
        if group == "keywords":
            return f"${e['token']}  {e['english']}"
        if group == "reports":
            return f"Report {e['code']}"
        if group == "cursor":
            return f"Cursor letter, mode {e['mode']}"
        return e["item"]

    @staticmethod
    def english(group: str, e: dict) -> str:
        if group == "cursor":
            return {"K": "keyword mode", "E": "extended mode", "G": "graphics mode", "L": "letter mode"}[e["mode"]]
        return e.get("english", "")

    def params(self, group: str, e: dict) -> dict:
        if group == "cursor":
            return {"maximum": int(e.get("max_bytes") or 1), "cursor_letter_only": True}
        if group == "tape":
            return {"maximum": e.get("max_bytes"), "enforce_maximum": False}
        if group == "copyright":
            return {"maximum": e.get("max_bytes")}
        if group == "scroll":
            return {"maximum": e.get("max_bytes"), "strip_scroll_question": True}
        return {"maximum": None}

    def encode_entry(self, group: str, e: dict, logical: str) -> tuple[dict, list[Issue], str | None]:
        record, raw = pl.text_record(logical, self.letter_tokens(), **self.params(group, e))
        issues = self.translate_issues(group, e, raw, record)
        return record, issues, None

    def translate_issues(self, group: str, e: dict, raw: list[dict], record: dict) -> list[Issue]:
        where = self.label(group, e)
        out: list[Issue] = []
        for item in raw:
            cat = item["category"]
            if cat == "empty_text":
                out.append(Issue("E", where, "empty text (genlang refuses an empty message)"))
            elif cat == "characters_not_allowed":
                out.append(Issue("E", where, "characters not in the Persian ROM set: " + " ".join(item["characters"])))
            elif cat == "cursor_letter_not_included":
                out.append(Issue("E", where, "a cursor letter must be exactly one included Persian letter"))
            elif cat == "over_limit":
                out.append(Issue("E", where, f"{item['actual_bytes']} bytes, limit {item['limit_bytes']} (over by {item['over_by']})"))
            elif cat == "redundant_zwnj_dropped":
                out.append(Issue("I", where, f"{item['count']} redundant ZWNJ dropped (they did nothing there)"))
            elif cat == "adjacent_words_after_zwnj_cleanup":
                out.append(Issue("W", where, "ZWNJ cleanup glued two words together: a real space is needed (+1 byte)"))
        text = record["text"]
        if group == "keywords" and (text.startswith(ZWNJ_TOKEN) or text.endswith(ZWNJ_TOKEN)):
            out.append(Issue("E", where, "a keyword must not start or end with ZWNJ (trailing-space logic reads the last byte)"))
        if group == "tape" and e["item"] == "Tape message 0" and record["zwnj_count"]:
            out.append(Issue("W", where, "ZWNJ in tape message 0: a word space is probably needed instead"))
        if group == "scroll" and record["byte_length"] != SCROLL_TEXT_BYTES:
            out.append(Issue("E", where, f"scroll text must be exactly {SCROLL_TEXT_BYTES} bytes (prompt block is a fixed 8 bytes), now {record['byte_length']}; pad with spaces"))
        if group == "keywords" and " " in text:
            out.append(Issue("I", where, f"{text.count(' ')} space(s) cost one byte each in the keyword budget"))
        return out

    def apply_text(self, group: str, e: dict, logical: str, meaning: str | None = None) -> list[Issue]:
        record, issues, _ = self.encode_entry(group, e, logical)
        if meaning is not None:
            if meaning.strip():
                e["meaning"] = meaning.strip()
            else:
                e.pop("meaning", None)
        for key in ("text", "byte_length", "zwnj_count", "max_bytes"):
            e[key] = record[key]
        e.pop("automatic_trailing_question_stripped", None)
        if record.get("automatic_trailing_question_stripped"):
            e["automatic_trailing_question_stripped"] = True
        self.refresh_totals()
        self.touch()
        return issues

    def entry_issues(self, group: str, e: dict) -> list[Issue]:
        return self.encode_entry(group, e, to_logical(e["text"]))[1]

    def stored_bytes(self, e: dict) -> list[int] | None:
        try:
            return [v for v, _ in pl.encode(e["text"], self.code_by_letter())]
        except ValueError:
            return None

    def preview_bytes(self, record: dict) -> list[int] | None:
        try:
            return [v for v, _ in pl.encode(record["text"], self.code_by_letter())]
        except ValueError:
            return None

    # ---- budget --------------------------------------------------------------------------
    def stats(self) -> dict:
        codes = self.included_codes()
        iso_bytes = 8 * (max(codes) - 0x41 + 1) if codes else 0
        records = sum(len(self.table(f)) for f in FORMS)
        reports = sum(e["byte_length"] for e in self.text["reports"])
        keywords = sum(e["byte_length"] for e in self.text["keywords"])
        tape_entries = self.entries("tape")
        tape = sum(e["byte_length"] for e in tape_entries)
        tape_budget = sum(int(e.get("max_bytes") or 0) for e in tape_entries)
        used = iso_bytes + DIGIT_BYTES + 9 * records + MARKER_BYTES + reports
        copyright_entry = self.entries("copyright")[0]
        return {
            "iso_bytes": iso_bytes, "records": records, "reports": reports,
            "reports_budget": SHARED_TOTAL - iso_bytes - DIGIT_BYTES - 9 * records - MARKER_BYTES,
            "keywords": keywords, "keywords_budget": int(self.text["totals"]["keywords"]["budget_bytes"]),
            "tape": tape, "tape_budget": tape_budget, "free": SHARED_TOTAL - used,
            "copyright": len(copyright_entry["text"]), "copyright_budget": int(copyright_entry.get("max_bytes") or 22),
        }

    def refresh_totals(self) -> None:
        s = self.stats()
        totals = self.text.setdefault("totals", {})
        totals.setdefault("keywords", {})["used_bytes"] = s["keywords"]
        totals["keywords"]["budget_bytes"] = s["keywords_budget"]
        totals.setdefault("reports", {}).update({"used_bytes": s["reports"], "budget_bytes": s["reports_budget"], "soft_target_bytes": REPORT_SOFT_TARGET})
        totals.setdefault("tape_messages", {}).update({"used_bytes": s["tape"], "budget_bytes": s["tape_budget"]})
        totals.setdefault("copyright", {}).update({"characters": s["copyright"], "budget_characters": s["copyright_budget"]})

    # ---- keyboard ------------------------------------------------------------------------
    def _keyboard_from_doc(self) -> list[dict]:
        by_ascii = {e["ascii"]: e for e in self.keys_doc["entries"]}
        keyboard = []
        for key in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            def letter_of(entry):
                return entry["arabic"] if entry and entry.get("arabic") and not entry.get("unmapped") else ""
            keyboard.append({"key": key, "unshifted": letter_of(by_ascii.get(key.lower())), "caps_shift": letter_of(by_ascii.get(key))})
        return keyboard

    def build_key_entries(self) -> list[dict]:
        """key_layout.json entries from the keyboard screen (58 slots, capitals = Caps Shift + key)."""
        code_by_letter = self.code_by_letter()
        by_key = {e["key"]: e for e in self.keyboard}
        letters = self.included()
        entries = []
        for ascii_code in range(ord("A"), ord("z") + 1):
            ch = chr(ascii_code)
            if "A" <= ch <= "Z":
                letter = by_key.get(ch, {}).get("caps_shift", "")
                code = 0x5D if ch == "E" else code_by_letter.get(letter, 0x3F)
            elif "a" <= ch <= "z":
                letter = by_key.get(ch.upper(), {}).get("unshifted", "")
                code = code_by_letter.get(letter, 0x3F)
            else:
                code = 0x3F
            entries.append({
                "ascii": ch, "ascii_hex": f"{ascii_code:02X}",
                "key_code": chr(code) if code != 0x3F else "?", "code_hex": f"{code:02X}",
                "arabic": next((e["letter"] for e in letters if e["code"] == code), None), "unmapped": code == 0x3F,
            })
        return entries

    def keyboard_assign(self, key: str, slot: str, letter: str) -> str | None:
        """Assign (or clear with '') a letter. A letter can be typed once: it is moved. Returns a note."""
        note = None
        if letter:
            for item in self.keyboard:
                for field in ("unshifted", "caps_shift"):
                    if item[field] == letter and not (item["key"] == key and field == slot):
                        item[field] = ""
                        note = f"moved from key {item['key']} ({'Caps Shift' if field == 'caps_shift' else 'plain'})"
        next(i for i in self.keyboard if i["key"] == key)[slot] = letter
        self.keys_doc["entries"] = self.build_key_entries()
        self.touch()
        return note

    # ---- letters -------------------------------------------------------------------------
    def toggle_joins(self, code: int) -> None:
        entry = self.letter_by_code(code)
        entry["joins_forward"] = not entry["joins_forward"]
        self.refresh_letter_meta()
        self.touch()

    def free_letter_codes(self) -> list[int]:
        used = set(self.included_codes())
        return [c for c in (0x6A, 0x6B) if c not in used]

    def add_letter(self, char: str, joins: bool, name: str = "") -> int:
        code = self.free_letter_codes()[0]
        rank = max(e["rank"] for e in self.letters) + 1
        entry = {"rank": rank, "letter": char, "joins_forward": joins, "include": True, "code": code,
                 "flag_hex": "7F", "flag_bits": {}, "forms": ["iso"], "form_fallbacks": {}}
        if name:
            entry["name"] = name
        self.letters.append(entry)
        block = pl.GlyphBlock(code, [0] * 8)
        self.files["glyph_iso_b.asm"].blocks.append(block)
        self.iso[code] = block.rows
        self.keys_doc["entries"] = self.build_key_entries()
        self.refresh_letter_meta()
        self.refresh_totals()
        self.touch()
        return code

    # ---- shaping preview (approximation of RTL_GLYPH_SUBSTITUTE / L1510, see STATIC_FACTS) ----
    def shape(self, stored: list[int]) -> list:
        """Cells in PRINT order (first = rightmost). Glyph = 8 rows, str = plain character."""
        letters = set(self.included_codes())
        cells: list = []
        prev_joined = False
        force_initial = False
        for i, byte in enumerate(stored):
            if byte == 0:
                force_initial, prev_joined = True, False
                continue
            if byte in letters:
                following = stored[i + 1] if i + 1 < len(stored) else None
                joins = bool(self.flag_of(byte) & 0x80) and following in letters
                bit2, bit1 = (not joins), prev_joined
                if force_initial:
                    bit2 = bit1 = False
                    force_initial = False
                form = "init" if (not bit2 and not bit1) else "med" if not bit2 else "iso" if not bit1 else "fin"
                cells.append(self.glyph(byte, form))
                prev_joined = joins
                continue
            force_initial = False
            prev_joined = False
            if 0x30 <= byte <= 0x39:
                cells.append(self.digits[byte - 0x30])
            elif byte == 0x20:
                cells.append(" ")
            else:
                cells.append(chr(byte & 0x7F) if 0x20 < (byte & 0x7F) < 0x7F else "?")
        return cells

    # ---- notes and validation ------------------------------------------------------------
    def glyph_notes(self, kind: str, code: int) -> list[Issue]:
        rows = self.get_rows(kind, code)
        out: list[Issue] = []
        if rows is None:
            return out
        where = f"{FORM_NAME[kind]} ${code:02X}" if kind != "digit" else f"digit {code}"
        if not any(rows):
            out.append(Issue("W", where, "glyph is completely empty"))
        if kind in FORMS:
            letter = self.letter_by_code(code)
            fallback = self.fallback_rows(kind, code)
            diff = hamming(rows, fallback)
            fb_name = "INITIAL" if kind == "med" and self.rec("init", code) else "ISOLATED"
            if diff == 0:
                out.append(Issue("E", where, f"identical to its fallback ({fb_name}): wastes 9 bytes and fails test T2.16: delete this record (d)"))
            elif diff <= 3:
                out.append(Issue("I", where, f"differs from {fb_name} by only {diff} px: merge candidate (STATIC_FACTS F8, needs human approval)"))
            if letter and kind in ("init", "med") and not letter["joins_forward"]:
                out.append(Issue("W", where, "letter does not join forward: this form is only reachable through CHR$ 0-3 overrides"))
            if kind == "init" and not rows[JOIN_ROW] & 0x80:
                out.append(Issue("W", where, f"INITIAL should touch the left edge (x=0) on row y={JOIN_ROW} to join the next letter"))
            if kind == "med" and not (rows[JOIN_ROW] & 0x80 and rows[JOIN_ROW] & 0x01):
                out.append(Issue("W", where, f"MEDIAL should touch both edges (x=0 and x=7) on row y={JOIN_ROW}"))
            if kind == "fin" and not rows[JOIN_ROW] & 0x01:
                out.append(Issue("W", where, f"FINAL should touch the right edge (x=7) on row y={JOIN_ROW}"))
        if kind != "digit" and any(rows):
            stray = 0
            for y in range(8):
                for x in range(8):
                    if rows[y] & (0x80 >> x):
                        near = any(
                            0 <= y + dy < 8 and 0 <= x + dx < 8 and (dy or dx) and rows[y + dy] & (0x80 >> (x + dx))
                            for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                        )
                        stray += not near
            if stray:
                out.append(Issue("I", where, f"{stray} isolated pixel(s): fine for dots, otherwise stray ink"))
        return out

    def validate(self) -> list[Issue]:
        issues: list[Issue] = []
        s = self.stats()
        if len(self.included()) > 37:
            issues.append(Issue("E", "letters", "more than 37 letters: the engine only has 37 letter codes"))
        if s["free"] < 0:
            issues.append(Issue("E", "shared block", f"{-s['free']} byte(s) over the {SHARED_TOTAL}-byte block ($3923-$3CFF): shorten reports or delete glyph records"))
        elif s["free"] < 9:
            issues.append(Issue("W", "shared block", f"only {s['free']} byte(s) free: not enough for one more 9-byte glyph record"))
        if s["reports"] > s["reports_budget"]:
            issues.append(Issue("E", "reports", f"{s['reports']} bytes, budget {s['reports_budget']} (over by {s['reports'] - s['reports_budget']})"))
        elif s["reports"] > REPORT_SOFT_TARGET:
            issues.append(Issue("W", "reports", f"{s['reports']} bytes, above the soft target {REPORT_SOFT_TARGET}"))
        if s["keywords"] > s["keywords_budget"]:
            issues.append(Issue("E", "keywords", f"{s['keywords']} bytes, budget {s['keywords_budget']} (over by {s['keywords'] - s['keywords_budget']})"))
        if s["tape"] > s["tape_budget"]:
            issues.append(Issue("E", "tape messages", f"{s['tape']} bytes, budget {s['tape_budget']}"))
        for group in GROUPS:
            for e in self.entries(group):
                issues += [i for i in self.entry_issues(group, e) if i.level != "I"]
        for form in FORMS:
            for record in self.table(form):
                if self.letter_by_code(record.code) is None:
                    issues.append(Issue("E", FORM_NAME[form], f"record key ${record.code:02X} is not an included letter"))
                    continue
                issues += [i for i in self.glyph_notes(form, record.code) if i.level in "EW" or i.level == "I" and "merge" in i.msg]
        for code in self.included_codes():
            issues += [i for i in self.glyph_notes("iso", code) if i.level in "EW"]
        counts: dict[str, int] = {e["letter"]: 0 for e in self.included()}
        for item in self.keyboard:
            for field in ("unshifted", "caps_shift"):
                if item[field] in counts:
                    counts[item[field]] += 1
                elif item[field]:
                    issues.append(Issue("E", "keyboard", f"key {item['key']} assigns {item[field]!r}, which is not an included letter"))
        for letter, n in counts.items():
            if n != 1:
                issues.append(Issue("E", "keyboard", f"letter {letter} must be typeable exactly once, found {n}"))
        if len(self.keys_doc["entries"]) != 58:
            issues.append(Issue("E", "keyboard", "key lookup must have 58 entries"))
        return issues

    # ---- save ----------------------------------------------------------------------------
    def snapshot(self) -> dict[str, str]:
        files = {
            "fixtures/persian/text.json": dump_json(self.text),
            "fixtures/persian/letters.json": dump_json(self.letters_doc),
            "fixtures/persian/key_layout.json": dump_json(self.keys_doc),
        }
        for name, text in self.render_glyph_files().items():
            files[f"lang/persian/{name}"] = text
        return files

    @property
    def dirty(self) -> bool:
        if self._dirty_version != self._version:
            self.refresh_letter_meta()
            self._dirty_value = self.snapshot() != self._baseline
            self._dirty_version = self._version
        return self._dirty_value

    def save(self) -> list[str]:
        self.refresh_letter_meta()
        self.refresh_totals()
        now = self.snapshot()
        changed = [name for name, text in now.items() if text != self._baseline.get(name)]
        if not changed:
            return []
        backup = self.root / "build" / "editor_backups" / datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup.mkdir(parents=True, exist_ok=True)
        for name in changed:
            source = self.root / name
            if source.exists():
                (backup / name.replace("/", "__")).write_bytes(source.read_bytes())
        for name in changed:
            (self.root / name).write_text(now[name], encoding="utf-8")
        self._baseline = now
        self._dirty_version = -1
        return changed



def check(root: Path) -> int:
    try:
        proj = Project(root)
    except ProjectError as error:
        print(f"E [project] {error}", file=sys.stderr)
        return 1
    s = proj.stats()
    print(f"shared free {s['free']} B | reports {s['reports']}/{s['reports_budget']} | "
          f"keywords {s['keywords']}/{s['keywords_budget']} | tape {s['tape']}/{s['tape_budget']}")
    issues = proj.validate()
    for item in issues:
        print(f"{item.level} [{item.where}] {item.msg}")
    errors = sum(1 for i in issues if i.level == "E")
    warnings = sum(1 for i in issues if i.level == "W")
    print(f"{errors} error(s), {warnings} warning(s)")
    return 1 if errors else 0


# --------------------------------------------------------------------------------------
# Tkinter GUI
# --------------------------------------------------------------------------------------
def launch_gui(root: Path):
    import tkinter as tk
    from tkinter import ttk, messagebox, font

    app_root = tk.Tk()
    app_root.title("Sinclair ZX Spectrum 48K - Persian ROM Editor")
    app_root.geometry("1120x760")
    app_root.minsize(920, 620)

    try:
        app_root.iconphoto(False, tk.PhotoImage(width=16, height=16))
    except Exception:
        pass

    try:
        proj = Project(root)
    except ProjectError as err:
        messagebox.showerror("Error Loading Project", str(err))
        sys.exit(1)

    # Styles
    style = ttk.Style()
    available_themes = style.theme_names()
    if "clam" in available_themes:
        style.theme_use("clam")

    # Font definitions
    persian_font = ("DejaVu Sans", 13)
    code_font = ("Courier", 10)
    bold_font = ("DejaVu Sans", 10, "bold")

    class App:
        def __init__(self, master: tk.Tk, project: Project):
            self.master = master
            self.proj = project
            self.undo_stack: list[list[int]] = []
            self.clipboard_glyph: list[int] | None = None

            self.setup_ui()
            self.refresh_all_views()
            self.bind_shortcuts()

        def setup_ui(self):
            # Top Toolbar
            top_bar = ttk.Frame(self.master, padding=(8, 6, 8, 6))
            top_bar.pack(side=tk.TOP, fill=tk.X)

            self.btn_save = ttk.Button(top_bar, text="💾 Save (Ctrl+S)", command=self.on_save)
            self.btn_save.pack(side=tk.LEFT, padx=4)

            self.btn_genflags = ttk.Button(top_bar, text="⚙️ Refresh Includes (genflags)", command=self.on_genflags)
            self.btn_genflags.pack(side=tk.LEFT, padx=4)

            self.btn_build = ttk.Button(top_bar, text="🔨 Build ROM (make persian)", command=self.on_build_rom)
            self.btn_build.pack(side=tk.LEFT, padx=4)

            self.dirty_label = tk.Label(top_bar, text="[Saved]", fg="#28a745", font=bold_font)
            self.dirty_label.pack(side=tk.LEFT, padx=8)

            # Quick budget pills in top bar
            self.budget_frame = ttk.Frame(top_bar)
            self.budget_frame.pack(side=tk.RIGHT, padx=4)

            self.pill_free = tk.Label(self.budget_frame, text="Shared Free: 84 B", bg="#e8f5e9", fg="#2e7d32", padx=6, pady=2, relief=tk.RIDGE)
            self.pill_free.pack(side=tk.LEFT, padx=2)

            self.pill_rep = tk.Label(self.budget_frame, text="Reports: 217/301", bg="#f5f5f5", fg="#333333", padx=6, pady=2, relief=tk.RIDGE)
            self.pill_rep.pack(side=tk.LEFT, padx=2)

            self.pill_kw = tk.Label(self.budget_frame, text="Keywords: 342/343", bg="#f5f5f5", fg="#333333", padx=6, pady=2, relief=tk.RIDGE)
            self.pill_kw.pack(side=tk.LEFT, padx=2)

            # Notebook Tabs
            self.nb = ttk.Notebook(self.master)
            self.nb.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            self.tab_kw = ttk.Frame(self.nb)
            self.tab_rep = ttk.Frame(self.nb)
            self.tab_tape = ttk.Frame(self.nb)
            self.tab_boot = ttk.Frame(self.nb)
            self.tab_glyph = ttk.Frame(self.nb)
            self.tab_keyb = ttk.Frame(self.nb)
            self.tab_letters = ttk.Frame(self.nb)
            self.tab_valid = ttk.Frame(self.nb)
            self.tab_log = ttk.Frame(self.nb)

            self.nb.add(self.tab_kw, text="Keywords")
            self.nb.add(self.tab_rep, text="Reports")
            self.nb.add(self.tab_tape, text="Tape Messages")
            self.nb.add(self.tab_boot, text="Boot & Prompt")
            self.nb.add(self.tab_glyph, text="Glyphs Editor")
            self.nb.add(self.tab_keyb, text="Keyboard")
            self.nb.add(self.tab_letters, text="Letters")
            self.nb.add(self.tab_valid, text="Budget & Check")
            self.nb.add(self.tab_log, text="Build & Log")

            # Setup Individual Tab UIs
            self.setup_keywords_tab()
            self.setup_reports_tab()
            self.setup_tape_tab()
            self.setup_boot_tab()
            self.setup_glyphs_tab()
            self.setup_keyboard_tab()
            self.setup_letters_tab()
            self.setup_validation_tab()
            self.setup_log_tab()

            # Bottom Status Bar
            status_bar = ttk.Frame(self.master, padding=(6, 3, 6, 3), relief=tk.SUNKEN)
            status_bar.pack(side=tk.BOTTOM, fill=tk.X)

            self.status_msg = ttk.Label(status_bar, text="Ready")
            self.status_msg.pack(side=tk.LEFT)

            self.status_issues = tk.Label(status_bar, text="0 Errors, 0 Warnings", fg="#28a745")
            self.status_issues.pack(side=tk.RIGHT)

        def bind_shortcuts(self):
            self.master.bind("<Control-s>", lambda e: self.on_save())
            self.master.bind("<Control-S>", lambda e: self.on_save())

        def set_status(self, text: str, is_error: bool = False):
            self.status_msg.config(text=text)

        def update_header_stats(self):
            s = self.proj.stats()
            dirty = self.proj.dirty
            self.dirty_label.config(
                text="[Modified ●]" if dirty else "[Saved]",
                fg="#e65100" if dirty else "#28a745"
            )

            free_color = "#2e7d32" if s["free"] >= 0 else "#c62828"
            free_bg = "#e8f5e9" if s["free"] >= 0 else "#ffebee"
            self.pill_free.config(text=f"Shared Free: {s['free']} B", fg=free_color, bg=free_bg)
            self.pill_rep.config(text=f"Reports: {s['reports']}/{s['reports_budget']}")
            self.pill_kw.config(text=f"Keywords: {s['keywords']}/{s['keywords_budget']}")

            issues = self.proj.validate()
            errs = sum(1 for i in issues if i.level == "E")
            warns = sum(1 for i in issues if i.level == "W")
            infos = sum(1 for i in issues if i.level == "I")

            if errs > 0:
                self.status_issues.config(text=f"❌ {errs} Error(s), {warns} Warning(s)", fg="#c62828")
            elif warns > 0:
                self.status_issues.config(text=f"⚠️ {warns} Warning(s), {infos} Info", fg="#f57c00")
            else:
                self.status_issues.config(text=f"✅ Clean ({infos} Info)", fg="#2e7d32")

        # -----------------------------------------------------------------------------
        # Canvas Preview Helpers
        # -----------------------------------------------------------------------------
        def draw_shaped_preview(self, canvas: tk.Canvas, stored_bytes: list[int] | None):
            canvas.delete("all")
            if not stored_bytes:
                canvas.config(width=220, height=28)
                canvas.create_text(110, 14, text="(preview unavailable)", fill="#999999", font=("Courier", 9))
                return
            cells = self.proj.shape(stored_bytes)
            scale = 2
            ordered = list(reversed(cells))
            total_w = len(ordered) * 8 * scale
            total_h = 8 * scale
            canvas.config(width=max(total_w + 12, 220), height=total_h + 8)
            canvas.create_rectangle(0, 0, max(total_w + 12, 220), total_h + 8, fill="#ffffff", outline="#dddddd")

            for col_idx, cell in enumerate(ordered):
                cx = 6 + col_idx * 8 * scale
                if isinstance(cell, list):
                    for y in range(8):
                        byte = cell[y]
                        for x in range(8):
                            if byte & (0x80 >> x):
                                px = cx + x * scale
                                py = 4 + y * scale
                                canvas.create_rectangle(px, py, px + scale, py + scale, fill="#000000", outline="")
                elif isinstance(cell, str) and cell != " ":
                    canvas.create_text(cx + 4 * scale, 4 + 4 * scale, text=cell, font=("Courier", 8), fill="#000000")

        # -----------------------------------------------------------------------------
        # TAB 1: Keywords
        # -----------------------------------------------------------------------------
        def setup_keywords_tab(self):
            paned = ttk.PanedWindow(self.tab_kw, orient=tk.HORIZONTAL)
            paned.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            # Left side: list & filter
            left = ttk.Frame(paned)
            paned.add(left, weight=1)

            search_bar = ttk.Frame(left)
            search_bar.pack(fill=tk.X, pady=2)
            ttk.Label(search_bar, text="Filter:").pack(side=tk.LEFT, padx=2)
            self.kw_filter = ttk.Entry(search_bar)
            self.kw_filter.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=2)
            self.kw_filter.bind("<KeyRelease>", lambda e: self.filter_keywords())

            cols = ("token", "english", "persian", "bytes")
            self.kw_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.kw_tree.heading("token", text="Token")
            self.kw_tree.heading("english", text="English Keyword")
            self.kw_tree.heading("persian", text="Persian Text")
            self.kw_tree.heading("bytes", text="Bytes")
            self.kw_tree.column("token", width=65, anchor="center")
            self.kw_tree.column("english", width=120)
            self.kw_tree.column("persian", width=140, anchor="e")
            self.kw_tree.column("bytes", width=55, anchor="center")

            sb = ttk.Scrollbar(left, orient=tk.VERTICAL, command=self.kw_tree.yview)
            self.kw_tree.configure(yscrollcommand=sb.set)
            self.kw_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)
            self.kw_tree.bind("<<TreeviewSelect>>", self.on_kw_select)

            # Right side: Detail Editor
            right = ttk.LabelFrame(paned, text="Keyword Details & Edit", padding=10)
            paned.add(right, weight=2)

            self.kw_lbl_token = ttk.Label(right, text="Token: -", font=bold_font)
            self.kw_lbl_token.pack(anchor="w", pady=2)

            lbl_frame = ttk.Frame(right)
            lbl_frame.pack(fill=tk.X, pady=4)
            ttk.Label(lbl_frame, text="Persian Text (RTL):").pack(side=tk.LEFT)
            btn_zwnj = ttk.Button(lbl_frame, text="+ Insert ZWNJ (نیم‌فاصله)", command=lambda: self.insert_zwnj(self.kw_ent_text))
            btn_zwnj.pack(side=tk.RIGHT)

            self.kw_ent_text = ttk.Entry(right, font=persian_font, justify="right")
            self.kw_ent_text.pack(fill=tk.X, pady=2)
            self.kw_ent_text.bind("<KeyRelease>", self.on_kw_text_edit)
            self.kw_ent_text.bind("<Control-w>", lambda e: self.insert_zwnj(self.kw_ent_text))

            ttk.Label(right, text="English Meaning (comment):").pack(anchor="w", pady=(6, 2))
            self.kw_ent_meaning = ttk.Entry(right)
            self.kw_ent_meaning.pack(fill=tk.X, pady=2)
            self.kw_ent_meaning.bind("<KeyRelease>", self.on_kw_meaning_edit)

            self.kw_lbl_bytes = ttk.Label(right, text="ROM Bytes: -", font=code_font)
            self.kw_lbl_bytes.pack(anchor="w", pady=4)

            self.kw_lbl_size = ttk.Label(right, text="Size: -")
            self.kw_lbl_size.pack(anchor="w", pady=2)

            self.kw_lbl_issues = tk.Label(right, text="", fg="#c62828", wraplength=400, justify="left")
            self.kw_lbl_issues.pack(anchor="w", pady=2)

            ttk.Label(right, text="ROM Preview (approximation of engine shaped bitmaps):").pack(anchor="w", pady=(8, 2))
            self.kw_canvas = tk.Canvas(right, bg="#ffffff", height=30, relief=tk.SUNKEN, bd=1)
            self.kw_canvas.pack(fill=tk.X, pady=4)

            btn_box = ttk.Frame(right)
            btn_box.pack(fill=tk.X, pady=8)
            ttk.Button(btn_box, text="▲ Previous", command=lambda: self.navigate_tree(self.kw_tree, -1)).pack(side=tk.LEFT, padx=4)
            ttk.Button(btn_box, text="▼ Next", command=lambda: self.navigate_tree(self.kw_tree, 1)).pack(side=tk.LEFT, padx=4)

        def populate_keywords(self):
            entries = self.proj.entries("keywords")
            filter_text = self.kw_filter.get().strip().lower()
            selected = self.kw_tree.selection()
            selected_id = selected[0] if selected else None

            self.kw_tree.delete(*self.kw_tree.get_children())
            for idx, e in enumerate(entries):
                token = f"${e['token']}"
                eng = e.get("english", "")
                per = to_logical(e.get("text", ""))
                length = f"{e.get('byte_length', 0)}"
                if filter_text and filter_text not in eng.lower() and filter_text not in per.lower() and filter_text not in token.lower():
                    continue
                item_id = self.kw_tree.insert("", tk.END, iid=str(idx), values=(token, eng, per, length))
                if selected_id == str(idx):
                    self.kw_tree.selection_set(item_id)

            if not self.kw_tree.selection() and self.kw_tree.get_children():
                self.kw_tree.selection_set(self.kw_tree.get_children()[0])

        def filter_keywords(self):
            self.populate_keywords()

        def on_kw_select(self, event=None):
            sel = self.kw_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("keywords")[idx]
            token = int(e["token"], 16)
            self.kw_lbl_token.config(text=f"Token ${e['token']} ({token}) - English: {e.get('english', '')}")

            self.kw_ent_text.delete(0, tk.END)
            self.kw_ent_text.insert(0, to_logical(e["text"]))

            self.kw_ent_meaning.delete(0, tk.END)
            self.kw_ent_meaning.insert(0, e.get("meaning", ""))

            self.update_kw_preview(e)

        def update_kw_preview(self, e: dict):
            stored = self.proj.stored_bytes(e)
            if stored:
                shown = list(stored)
                shown[-1] |= 0x80
                bytes_str = " ".join(f"{b:02X}" for b in shown)
            else:
                bytes_str = "(none)"
            self.kw_lbl_bytes.config(text=f"ROM Bytes: {bytes_str}")

            s = self.proj.stats()
            self.kw_lbl_size.config(text=f"Length: {e.get('byte_length', 0)} byte(s) | Keywords total: {s['keywords']}/{s['keywords_budget']}")

            issues = self.proj.entry_issues("keywords", e)
            if issues:
                txt = "\n".join(f"{i.level}: {i.msg}" for i in issues)
                self.kw_lbl_issues.config(text=txt)
            else:
                self.kw_lbl_issues.config(text="")

            self.draw_shaped_preview(self.kw_canvas, stored)

        def on_kw_text_edit(self, event=None):
            sel = self.kw_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("keywords")[idx]
            new_text = self.kw_ent_text.get()
            self.proj.apply_text("keywords", e, new_text)

            self.kw_tree.item(str(idx), values=(f"${e['token']}", e.get("english", ""), to_logical(e["text"]), f"{e.get('byte_length', 0)}"))
            self.update_kw_preview(e)
            self.update_header_stats()

        def on_kw_meaning_edit(self, event=None):
            sel = self.kw_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("keywords")[idx]
            meaning = self.kw_ent_meaning.get().strip()
            if meaning:
                e["meaning"] = meaning
            else:
                e.pop("meaning", None)
            self.proj.touch()
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 2: Reports
        # -----------------------------------------------------------------------------
        def setup_reports_tab(self):
            paned = ttk.PanedWindow(self.tab_rep, orient=tk.HORIZONTAL)
            paned.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            left = ttk.Frame(paned)
            paned.add(left, weight=1)

            search_bar = ttk.Frame(left)
            search_bar.pack(fill=tk.X, pady=2)
            ttk.Label(search_bar, text="Filter:").pack(side=tk.LEFT, padx=2)
            self.rep_filter = ttk.Entry(search_bar)
            self.rep_filter.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=2)
            self.rep_filter.bind("<KeyRelease>", lambda e: self.populate_reports())

            cols = ("code", "english", "persian", "bytes")
            self.rep_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.rep_tree.heading("code", text="Code")
            self.rep_tree.heading("english", text="English Report")
            self.rep_tree.heading("persian", text="Persian Text")
            self.rep_tree.heading("bytes", text="Bytes / Limit")
            self.rep_tree.column("code", width=55, anchor="center")
            self.rep_tree.column("english", width=140)
            self.rep_tree.column("persian", width=140, anchor="e")
            self.rep_tree.column("bytes", width=80, anchor="center")

            sb = ttk.Scrollbar(left, orient=tk.VERTICAL, command=self.rep_tree.yview)
            self.rep_tree.configure(yscrollcommand=sb.set)
            self.rep_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)
            self.rep_tree.bind("<<TreeviewSelect>>", self.on_rep_select)

            right = ttk.LabelFrame(paned, text="Report Details & Edit", padding=10)
            paned.add(right, weight=2)

            self.rep_lbl_header = ttk.Label(right, text="Report: -", font=bold_font)
            self.rep_lbl_header.pack(anchor="w", pady=2)

            lbl_frame = ttk.Frame(right)
            lbl_frame.pack(fill=tk.X, pady=4)
            ttk.Label(lbl_frame, text="Persian Text (RTL):").pack(side=tk.LEFT)
            btn_zwnj = ttk.Button(lbl_frame, text="+ Insert ZWNJ (نیم‌فاصله)", command=lambda: self.insert_zwnj(self.rep_ent_text))
            btn_zwnj.pack(side=tk.RIGHT)

            self.rep_ent_text = ttk.Entry(right, font=persian_font, justify="right")
            self.rep_ent_text.pack(fill=tk.X, pady=2)
            self.rep_ent_text.bind("<KeyRelease>", self.on_rep_text_edit)
            self.rep_ent_text.bind("<Control-w>", lambda e: self.insert_zwnj(self.rep_ent_text))

            ttk.Label(right, text="English Meaning (comment):").pack(anchor="w", pady=(6, 2))
            self.rep_ent_meaning = ttk.Entry(right)
            self.rep_ent_meaning.pack(fill=tk.X, pady=2)
            self.rep_ent_meaning.bind("<KeyRelease>", self.on_rep_meaning_edit)

            self.rep_lbl_bytes = ttk.Label(right, text="ROM Bytes: -", font=code_font)
            self.rep_lbl_bytes.pack(anchor="w", pady=4)

            self.rep_lbl_size = ttk.Label(right, text="Size: -")
            self.rep_lbl_size.pack(anchor="w", pady=2)

            self.rep_lbl_issues = tk.Label(right, text="", fg="#c62828", wraplength=400, justify="left")
            self.rep_lbl_issues.pack(anchor="w", pady=2)

            ttk.Label(right, text="ROM Preview:").pack(anchor="w", pady=(8, 2))
            self.rep_canvas = tk.Canvas(right, bg="#ffffff", height=30, relief=tk.SUNKEN, bd=1)
            self.rep_canvas.pack(fill=tk.X, pady=4)

            btn_box = ttk.Frame(right)
            btn_box.pack(fill=tk.X, pady=8)
            ttk.Button(btn_box, text="▲ Previous", command=lambda: self.navigate_tree(self.rep_tree, -1)).pack(side=tk.LEFT, padx=4)
            ttk.Button(btn_box, text="▼ Next", command=lambda: self.navigate_tree(self.rep_tree, 1)).pack(side=tk.LEFT, padx=4)

        def populate_reports(self):
            entries = self.proj.entries("reports")
            filter_text = self.rep_filter.get().strip().lower()
            selected = self.rep_tree.selection()
            selected_id = selected[0] if selected else None

            self.rep_tree.delete(*self.rep_tree.get_children())
            for idx, e in enumerate(entries):
                code = f"${e['code']}"
                eng = e.get("english", "")
                per = to_logical(e.get("text", ""))
                max_b = e.get("max_bytes")
                length = f"{e.get('byte_length', 0)}" + (f" / {max_b}" if max_b else "")
                if filter_text and filter_text not in eng.lower() and filter_text not in per.lower() and filter_text not in code.lower():
                    continue
                item_id = self.rep_tree.insert("", tk.END, iid=str(idx), values=(code, eng, per, length))
                if selected_id == str(idx):
                    self.rep_tree.selection_set(item_id)

            if not self.rep_tree.selection() and self.rep_tree.get_children():
                self.rep_tree.selection_set(self.rep_tree.get_children()[0])

        def on_rep_select(self, event=None):
            sel = self.rep_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("reports")[idx]
            self.rep_lbl_header.config(text=f"Report ${e['code']} - English: {e.get('english', '')}")

            self.rep_ent_text.delete(0, tk.END)
            self.rep_ent_text.insert(0, to_logical(e["text"]))

            self.rep_ent_meaning.delete(0, tk.END)
            self.rep_ent_meaning.insert(0, e.get("meaning", ""))

            self.update_rep_preview(e)

        def update_rep_preview(self, e: dict):
            stored = self.proj.stored_bytes(e)
            if stored:
                shown = list(stored)
                shown[-1] |= 0x80
                bytes_str = " ".join(f"{b:02X}" for b in shown)
            else:
                bytes_str = "(none)"
            self.rep_lbl_bytes.config(text=f"ROM Bytes: {bytes_str}")

            s = self.proj.stats()
            max_b = e.get("max_bytes")
            limit_str = f" / limit {max_b}" if max_b else ""
            self.rep_lbl_size.config(text=f"Length: {e.get('byte_length', 0)}{limit_str} bytes | Reports total: {s['reports']}/{s['reports_budget']} (soft {REPORT_SOFT_TARGET})")

            issues = self.proj.entry_issues("reports", e)
            if issues:
                txt = "\n".join(f"{i.level}: {i.msg}" for i in issues)
                self.rep_lbl_issues.config(text=txt)
            else:
                self.rep_lbl_issues.config(text="")

            self.draw_shaped_preview(self.rep_canvas, stored)

        def on_rep_text_edit(self, event=None):
            sel = self.rep_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("reports")[idx]
            new_text = self.rep_ent_text.get()
            self.proj.apply_text("reports", e, new_text)

            max_b = e.get("max_bytes")
            length = f"{e.get('byte_length', 0)}" + (f" / {max_b}" if max_b else "")
            self.rep_tree.item(str(idx), values=(f"${e['code']}", e.get("english", ""), to_logical(e["text"]), length))
            self.update_rep_preview(e)
            self.update_header_stats()

        def on_rep_meaning_edit(self, event=None):
            sel = self.rep_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("reports")[idx]
            meaning = self.rep_ent_meaning.get().strip()
            if meaning:
                e["meaning"] = meaning
            else:
                e.pop("meaning", None)
            self.proj.touch()
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 3: Tape Messages
        # -----------------------------------------------------------------------------
        def setup_tape_tab(self):
            paned = ttk.PanedWindow(self.tab_tape, orient=tk.HORIZONTAL)
            paned.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            left = ttk.Frame(paned)
            paned.add(left, weight=1)

            cols = ("item", "persian", "bytes")
            self.tape_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.tape_tree.heading("item", text="Message")
            self.tape_tree.heading("persian", text="Persian Text")
            self.tape_tree.heading("bytes", text="Bytes / Limit")
            self.tape_tree.column("item", width=120)
            self.tape_tree.column("persian", width=140, anchor="e")
            self.tape_tree.column("bytes", width=90, anchor="center")
            self.tape_tree.pack(fill=tk.BOTH, expand=True)
            self.tape_tree.bind("<<TreeviewSelect>>", self.on_tape_select)

            right = ttk.LabelFrame(paned, text="Tape Message Details", padding=10)
            paned.add(right, weight=2)

            self.tape_lbl_title = ttk.Label(right, text="Tape Message: -", font=bold_font)
            self.tape_lbl_title.pack(anchor="w", pady=2)

            lbl_frame = ttk.Frame(right)
            lbl_frame.pack(fill=tk.X, pady=4)
            ttk.Label(lbl_frame, text="Persian Text:").pack(side=tk.LEFT)
            btn_zwnj = ttk.Button(lbl_frame, text="+ Insert ZWNJ (نیم‌فاصله)", command=lambda: self.insert_zwnj(self.tape_ent_text))
            btn_zwnj.pack(side=tk.RIGHT)

            self.tape_ent_text = ttk.Entry(right, font=persian_font, justify="right")
            self.tape_ent_text.pack(fill=tk.X, pady=2)
            self.tape_ent_text.bind("<KeyRelease>", self.on_tape_text_edit)
            self.tape_ent_text.bind("<Control-w>", lambda e: self.insert_zwnj(self.tape_ent_text))

            self.tape_lbl_bytes = ttk.Label(right, text="ROM Bytes: -", font=code_font)
            self.tape_lbl_bytes.pack(anchor="w", pady=4)

            self.tape_lbl_size = ttk.Label(right, text="Size: -")
            self.tape_lbl_size.pack(anchor="w", pady=2)

            self.tape_lbl_issues = tk.Label(right, text="", fg="#c62828", wraplength=400, justify="left")
            self.tape_lbl_issues.pack(anchor="w", pady=2)

            ttk.Label(right, text="ROM Preview:").pack(anchor="w", pady=(8, 2))
            self.tape_canvas = tk.Canvas(right, bg="#ffffff", height=30, relief=tk.SUNKEN, bd=1)
            self.tape_canvas.pack(fill=tk.X, pady=4)

        def populate_tape(self):
            entries = self.proj.entries("tape")
            self.tape_tree.delete(*self.tape_tree.get_children())
            for idx, e in enumerate(entries):
                max_b = e.get("max_bytes", "")
                self.tape_tree.insert("", tk.END, iid=str(idx), values=(e.get("item", ""), to_logical(e["text"]), f"{e.get('byte_length', 0)} / {max_b}"))
            if self.tape_tree.get_children():
                self.tape_tree.selection_set(self.tape_tree.get_children()[0])

        def on_tape_select(self, event=None):
            sel = self.tape_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("tape")[idx]
            self.tape_lbl_title.config(text=f"{e.get('item', '')} - {e.get('english', '')}")
            self.tape_ent_text.delete(0, tk.END)
            self.tape_ent_text.insert(0, to_logical(e["text"]))
            self.update_tape_preview(e)

        def update_tape_preview(self, e: dict):
            stored = self.proj.stored_bytes(e)
            bytes_str = " ".join(f"{b:02X}" for b in (stored or []))
            self.tape_lbl_bytes.config(text=f"ROM Bytes: {bytes_str}")

            s = self.proj.stats()
            self.tape_lbl_size.config(text=f"Length: {e.get('byte_length', 0)} / {e.get('max_bytes', '')} bytes | Tape total: {s['tape']}/{s['tape_budget']}")

            issues = self.proj.entry_issues("tape", e)
            if issues:
                txt = "\n".join(f"{i.level}: {i.msg}" for i in issues)
                self.tape_lbl_issues.config(text=txt)
            else:
                self.tape_lbl_issues.config(text="")

            self.draw_shaped_preview(self.tape_canvas, stored)

        def on_tape_text_edit(self, event=None):
            sel = self.tape_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            e = self.proj.entries("tape")[idx]
            new_text = self.tape_ent_text.get()
            self.proj.apply_text("tape", e, new_text)

            self.tape_tree.item(str(idx), values=(e.get("item", ""), to_logical(e["text"]), f"{e.get('byte_length', 0)} / {e.get('max_bytes', '')}"))
            self.update_tape_preview(e)
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 4: Boot Copyright, Scroll Prompt, Cursor Letters
        # -----------------------------------------------------------------------------
        def setup_boot_tab(self):
            container = ttk.Frame(self.tab_boot, padding=12)
            container.pack(fill=tk.BOTH, expand=True)

            # Copyright
            f_cp = ttk.LabelFrame(container, text="Boot Copyright Line ($01ED-$0204)", padding=10)
            f_cp.pack(fill=tk.X, pady=6)

            cp_bar = ttk.Frame(f_cp)
            cp_bar.pack(fill=tk.X, pady=2)
            ttk.Label(cp_bar, text="Persian Copyright Text (RTL):").pack(side=tk.LEFT)
            btn_cp_zwnj = ttk.Button(cp_bar, text="+ Insert ZWNJ", command=lambda: self.insert_zwnj(self.cp_ent_text))
            btn_cp_zwnj.pack(side=tk.RIGHT)

            self.cp_ent_text = ttk.Entry(f_cp, font=persian_font, justify="right")
            self.cp_ent_text.pack(fill=tk.X, pady=2)
            self.cp_ent_text.bind("<KeyRelease>", self.on_cp_edit)

            self.cp_lbl_stats = ttk.Label(f_cp, text="Length: - / 22 characters")
            self.cp_lbl_stats.pack(anchor="w", pady=2)

            self.cp_canvas = tk.Canvas(f_cp, bg="#ffffff", height=30, relief=tk.SUNKEN, bd=1)
            self.cp_canvas.pack(fill=tk.X, pady=4)

            # Scroll Prompt
            f_sc = ttk.LabelFrame(container, text="Scroll Prompt Text (Scroll? prompt)", padding=10)
            f_sc.pack(fill=tk.X, pady=6)

            sc_bar = ttk.Frame(f_sc)
            sc_bar.pack(fill=tk.X, pady=2)
            ttk.Label(sc_bar, text="Scroll Prompt Text (must be exactly 5 bytes):").pack(side=tk.LEFT)
            btn_sc_zwnj = ttk.Button(sc_bar, text="+ Insert ZWNJ", command=lambda: self.insert_zwnj(self.sc_ent_text))
            btn_sc_zwnj.pack(side=tk.RIGHT)

            self.sc_ent_text = ttk.Entry(f_sc, font=persian_font, justify="right")
            self.sc_ent_text.pack(fill=tk.X, pady=2)
            self.sc_ent_text.bind("<KeyRelease>", self.on_sc_edit)

            self.sc_lbl_stats = ttk.Label(f_sc, text="Length: - / 5 bytes")
            self.sc_lbl_stats.pack(anchor="w", pady=2)

            self.sc_canvas = tk.Canvas(f_sc, bg="#ffffff", height=30, relief=tk.SUNKEN, bd=1)
            self.sc_canvas.pack(fill=tk.X, pady=4)

            # Cursor Letters
            f_cur = ttk.LabelFrame(container, text="Cursor Letters (Single Persian letter for BASIC editor modes)", padding=10)
            f_cur.pack(fill=tk.X, pady=6)

            self.cur_entries: dict[str, ttk.Entry] = {}
            for mode, desc in [("K", "Keyword cursor (K)"), ("E", "Extended cursor (E)"), ("G", "Graphics cursor (G)"), ("L", "Letter cursor (L)")]:
                row = ttk.Frame(f_cur)
                row.pack(fill=tk.X, pady=2)
                ttk.Label(row, text=f"Mode {mode} - {desc}:", width=32).pack(side=tk.LEFT)
                ent = ttk.Entry(row, font=persian_font, width=6, justify="center")
                ent.pack(side=tk.LEFT, padx=4)
                ent.bind("<KeyRelease>", lambda e, m=mode: self.on_cursor_edit(m))
                self.cur_entries[mode] = ent

        def populate_boot(self):
            # Copyright
            cp_entry = next((e for e in self.proj.entries("copyright")), None)
            if cp_entry:
                self.cp_ent_text.delete(0, tk.END)
                self.cp_ent_text.insert(0, to_logical(cp_entry["text"]))
                self.update_cp_preview(cp_entry)

            # Scroll
            sc_entry = next((e for e in self.proj.entries("scroll")), None)
            if sc_entry:
                self.sc_ent_text.delete(0, tk.END)
                self.sc_ent_text.insert(0, to_logical(sc_entry["text"]))
                self.update_sc_preview(sc_entry)

            # Cursor
            for e in self.proj.entries("cursor"):
                mode = e["mode"]
                if mode in self.cur_entries:
                    self.cur_entries[mode].delete(0, tk.END)
                    self.cur_entries[mode].insert(0, to_logical(e["text"]))

        def update_cp_preview(self, e: dict):
            s = self.proj.stats()
            self.cp_lbl_stats.config(text=f"Length: {e.get('byte_length', 0)} / {s['copyright_budget']} characters")
            stored = self.proj.stored_bytes(e)
            self.draw_shaped_preview(self.cp_canvas, stored)

        def on_cp_edit(self, event=None):
            cp_entry = next((e for e in self.proj.entries("copyright")), None)
            if not cp_entry:
                return
            new_text = self.cp_ent_text.get()
            self.proj.apply_text("copyright", cp_entry, new_text)
            self.update_cp_preview(cp_entry)
            self.update_header_stats()

        def update_sc_preview(self, e: dict):
            self.sc_lbl_stats.config(text=f"Length: {e.get('byte_length', 0)} / 5 bytes")
            stored = self.proj.stored_bytes(e)
            self.draw_shaped_preview(self.sc_canvas, stored)

        def on_sc_edit(self, event=None):
            sc_entry = next((e for e in self.proj.entries("scroll")), None)
            if not sc_entry:
                return
            new_text = self.sc_ent_text.get()
            self.proj.apply_text("scroll", sc_entry, new_text)
            self.update_sc_preview(sc_entry)
            self.update_header_stats()

        def on_cursor_edit(self, mode: str):
            cur_entry = next((e for e in self.proj.entries("cursor") if e["mode"] == mode), None)
            if not cur_entry:
                return
            new_letter = self.cur_entries[mode].get().strip()
            self.proj.apply_text("cursor", cur_entry, new_letter)
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 5: Glyphs Editor (8x8 interactive bitmap grid)
        # -----------------------------------------------------------------------------
        def setup_glyphs_tab(self):
            main_split = ttk.PanedWindow(self.tab_glyph, orient=tk.HORIZONTAL)
            main_split.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            # Left side: selection list & category
            left = ttk.Frame(main_split)
            main_split.add(left, weight=1)

            cat_frame = ttk.LabelFrame(left, text="Glyph Table Category", padding=6)
            cat_frame.pack(fill=tk.X, pady=2)

            self.glyph_cat = tk.StringVar(value="iso")
            for cat, title in [("iso", "Isolated"), ("init", "Initial"), ("med", "Medial"), ("fin", "Final"), ("digit", "Digits")]:
                r = ttk.Radiobutton(cat_frame, text=title, value=cat, variable=self.glyph_cat, command=self.on_glyph_cat_change)
                r.pack(side=tk.LEFT, padx=3)

            cols = ("code", "char", "status")
            self.glyph_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.glyph_tree.heading("code", text="Code")
            self.glyph_tree.heading("char", text="Char / Name")
            self.glyph_tree.heading("status", text="Record")
            self.glyph_tree.column("code", width=60, anchor="center")
            self.glyph_tree.column("char", width=120)
            self.glyph_tree.column("status", width=90, anchor="center")

            sb = ttk.Scrollbar(left, orient=tk.VERTICAL, command=self.glyph_tree.yview)
            self.glyph_tree.configure(yscrollcommand=sb.set)
            self.glyph_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)
            self.glyph_tree.bind("<<TreeviewSelect>>", self.on_glyph_select)

            # Right side: Interactive 8x8 Editor
            right = ttk.LabelFrame(main_split, text="8x8 Pixel Grid Editor", padding=10)
            main_split.add(right, weight=3)

            top_info = ttk.Frame(right)
            top_info.pack(fill=tk.X, pady=2)
            self.glyph_lbl_info = ttk.Label(top_info, text="Selected: -", font=bold_font)
            self.glyph_lbl_info.pack(side=tk.LEFT)

            self.glyph_btn_record = ttk.Button(top_info, text="Add Form Record (+9 B)", command=self.on_toggle_record)
            self.glyph_btn_record.pack(side=tk.RIGHT)

            editor_split = ttk.Frame(right)
            editor_split.pack(fill=tk.BOTH, expand=True, pady=6)

            # Pixel Canvas (32x32 per pixel = 256x256)
            canvas_box = ttk.Frame(editor_split)
            canvas_box.pack(side=tk.LEFT, padx=8)

            self.px_scale = 32
            w = 8 * self.px_scale
            h = 8 * self.px_scale
            self.px_canvas = tk.Canvas(canvas_box, width=w, height=h, bg="#f0f0f0", bd=2, relief=tk.SUNKEN)
            self.px_canvas.pack()
            self.px_canvas.bind("<Button-1>", self.on_canvas_click)
            self.px_canvas.bind("<B1-Motion>", self.on_canvas_drag)

            ttk.Label(canvas_box, text="Row 4 (red dashed line) is the baseline join level.", font=("DejaVu Sans", 9), foreground="#666666").pack(pady=4)

            # Center/Right controls & Byte matrix
            ctrl_box = ttk.Frame(editor_split)
            ctrl_box.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=8)

            ttk.Label(ctrl_box, text="Bitmap Bytes:", font=bold_font).pack(anchor="w")
            self.glyph_lbl_rows = ttk.Label(ctrl_box, text="", font=code_font)
            self.glyph_lbl_rows.pack(anchor="w", pady=4)

            btn_grid = ttk.Frame(ctrl_box)
            btn_grid.pack(fill=tk.X, pady=4)

            ttk.Button(btn_grid, text="Clear", width=8, command=self.on_glyph_clear).grid(row=0, column=0, padx=2, pady=2)
            ttk.Button(btn_grid, text="Invert", width=8, command=self.on_glyph_invert).grid(row=0, column=1, padx=2, pady=2)
            ttk.Button(btn_grid, text="Mirror", width=8, command=self.on_glyph_mirror).grid(row=0, column=2, padx=2, pady=2)
            ttk.Button(btn_grid, text="Undo", width=8, command=self.on_glyph_undo).grid(row=0, column=3, padx=2, pady=2)

            ttk.Button(btn_grid, text="Shift ←", width=8, command=lambda: self.on_glyph_shift(-1, 0)).grid(row=1, column=0, padx=2, pady=2)
            ttk.Button(btn_grid, text="Shift →", width=8, command=lambda: self.on_glyph_shift(1, 0)).grid(row=1, column=1, padx=2, pady=2)
            ttk.Button(btn_grid, text="Shift ↑", width=8, command=lambda: self.on_glyph_shift(0, -1)).grid(row=1, column=2, padx=2, pady=2)
            ttk.Button(btn_grid, text="Shift ↓", width=8, command=lambda: self.on_glyph_shift(0, 1)).grid(row=1, column=3, padx=2, pady=2)

            ttk.Button(btn_grid, text="Copy", width=8, command=self.on_glyph_copy).grid(row=2, column=0, padx=2, pady=2)
            ttk.Button(btn_grid, text="Paste", width=8, command=self.on_glyph_paste).grid(row=2, column=1, padx=2, pady=2)
            ttk.Button(btn_grid, text="Fallback", width=8, command=self.on_glyph_fallback).grid(row=2, column=2, padx=2, pady=2)

            # Previews of all forms
            prev_frame = ttk.LabelFrame(ctrl_box, text="Forms & Cursive Preview", padding=6)
            prev_frame.pack(fill=tk.X, pady=8)

            self.forms_canvas = tk.Canvas(prev_frame, width=280, height=40, bg="#ffffff", relief=tk.SUNKEN, bd=1)
            self.forms_canvas.pack(fill=tk.X, pady=2)

            self.word_canvas = tk.Canvas(prev_frame, width=280, height=30, bg="#ffffff", relief=tk.SUNKEN, bd=1)
            self.word_canvas.pack(fill=tk.X, pady=2)

            self.glyph_lbl_notes = tk.Label(ctrl_box, text="", fg="#e65100", wraplength=350, justify="left")
            self.glyph_lbl_notes.pack(anchor="w", pady=4)

        def on_glyph_cat_change(self):
            self.populate_glyphs()

        def populate_glyphs(self):
            cat = self.glyph_cat.get()
            selected = self.glyph_tree.selection()
            selected_id = selected[0] if selected else None

            self.glyph_tree.delete(*self.glyph_tree.get_children())
            if cat == "digit":
                for d in range(10):
                    item_id = self.glyph_tree.insert("", tk.END, iid=str(d), values=(f"{d}", f"Digit {d}", "Built-in"))
                    if selected_id == str(d):
                        self.glyph_tree.selection_set(item_id)
            else:
                for e in self.proj.included():
                    code = e["code"]
                    char = f"{e['letter']} ({e.get('name', '')})"
                    if cat == "iso":
                        status = "Present"
                    else:
                        has_rec = self.proj.rec(cat, code) is not None
                        status = "Custom Record" if has_rec else "Fallback"
                    item_id = self.glyph_tree.insert("", tk.END, iid=str(code), values=(f"${code:02X}", char, status))
                    if selected_id == str(code):
                        self.glyph_tree.selection_set(item_id)

            if not self.glyph_tree.selection() and self.glyph_tree.get_children():
                self.glyph_tree.selection_set(self.glyph_tree.get_children()[0])

        def current_glyph_info(self) -> tuple[str, int] | None:
            sel = self.glyph_tree.selection()
            if not sel:
                return None
            cat = self.glyph_cat.get()
            code = int(sel[0])
            return cat, code

        def on_glyph_select(self, event=None):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            self.undo_stack.clear()

            if cat == "digit":
                self.glyph_lbl_info.config(text=f"Digit {code}")
                self.glyph_btn_record.pack_forget()
            else:
                letter = self.proj.letter_by_code(code)
                char = letter["letter"] if letter else ""
                name = letter.get("name", "") if letter else ""
                flag = self.proj.flag_of(code)
                self.glyph_lbl_info.config(text=f"{FORM_NAME[cat]} ${code:02X} '{char}' ({name}) - Flag ${flag:02X}")

                if cat in FORMS:
                    self.glyph_btn_record.pack(side=tk.RIGHT)
                    has_rec = self.proj.rec(cat, code) is not None
                    if has_rec:
                        self.glyph_btn_record.config(text="Delete Record (-9 B)")
                    else:
                        self.glyph_btn_record.config(text="Create Record (+9 B)")
                else:
                    self.glyph_btn_record.pack_forget()

            self.redraw_pixel_editor()

        def redraw_pixel_editor(self):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            rows = self.proj.get_rows(cat, code)
            if rows is None:
                rows = self.proj.fallback_rows(cat, code)

            scale = self.px_scale
            self.px_canvas.delete("all")

            for y in range(8):
                byte = rows[y]
                for x in range(8):
                    ink = bool(byte & (0x80 >> x))
                    x0 = x * scale
                    y0 = y * scale
                    fill = "#1a1a1a" if ink else "#f8f9fa"
                    self.px_canvas.create_rectangle(x0, y0, x0 + scale, y0 + scale, fill=fill, outline="#dddddd", width=1)

            # Draw join row guideline at JOIN_ROW = 4
            jy = (JOIN_ROW + 1) * scale
            self.px_canvas.create_line(0, jy, 8 * scale, jy, fill="#e63946", width=2, dash=(4, 2))

            # Update byte rows text
            lines = [f"y{y}: %{rows[y]:08b}  ${rows[y]:02X}" for y in range(8)]
            self.glyph_lbl_rows.config(text="\n".join(lines))

            # Update forms preview & notes
            self.update_glyph_previews(cat, code)

        def update_glyph_previews(self, cat: str, code: int):
            self.forms_canvas.delete("all")
            self.word_canvas.delete("all")
            if cat == "digit":
                return

            # Draw forms: ISO, INIT, MED, FIN
            scale = 2
            forms_list = [("ISO", "iso"), ("INIT", "init"), ("MED", "med"), ("FIN", "fin")]
            for idx, (label, f) in enumerate(forms_list):
                x_base = 12 + idx * 64
                self.forms_canvas.create_text(x_base + 8, 8, text=label, font=("Courier", 8, "bold"))
                f_rows = self.proj.glyph(code, f)
                for y in range(8):
                    byte = f_rows[y]
                    for x in range(8):
                        if byte & (0x80 >> x):
                            px = x_base + x * scale
                            py = 18 + y * scale
                            self.forms_canvas.create_rectangle(px, py, px + scale, py + scale, fill="#000000", outline="")

            # In a word preview
            letter = self.proj.letter_by_code(code)
            if letter:
                joins = letter.get("joins_forward", False)
                count = 4 if joins else 1
                word_stored = [code] * count
                self.draw_shaped_preview(self.word_canvas, word_stored)

            notes = self.proj.glyph_notes(cat, code)
            if notes:
                self.glyph_lbl_notes.config(text="\n".join(f"{n.level}: {n.msg}" for n in notes))
            else:
                self.glyph_lbl_notes.config(text="")

        def push_undo(self, rows: list[int]):
            self.undo_stack.append(list(rows))
            if len(self.undo_stack) > 50:
                self.undo_stack.pop(0)

        def on_canvas_click(self, event):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            rows = self.ensure_editable_rows(cat, code)
            x = event.x // self.px_scale
            y = event.y // self.px_scale
            if 0 <= x < 8 and 0 <= y < 8:
                self.push_undo(rows)
                rows[y] ^= (0x80 >> x)
                self.proj.touch()
                self.redraw_pixel_editor()
                self.update_header_stats()

        def on_canvas_drag(self, event):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            rows = self.ensure_editable_rows(cat, code)
            x = event.x // self.px_scale
            y = event.y // self.px_scale
            if 0 <= x < 8 and 0 <= y < 8:
                mask = (0x80 >> x)
                if not (rows[y] & mask):
                    self.push_undo(rows)
                    rows[y] |= mask
                    self.proj.touch()
                    self.redraw_pixel_editor()
                    self.update_header_stats()

        def ensure_editable_rows(self, cat: str, code: int) -> list[int]:
            rows = self.proj.get_rows(cat, code)
            if rows is None and cat in FORMS:
                rows = self.proj.create_record(cat, code)
                self.populate_glyphs()
            return rows

        def on_toggle_record(self):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            if cat not in FORMS:
                return
            has_rec = self.proj.rec(cat, code) is not None
            if has_rec:
                if messagebox.askyesno("Delete Record", f"Delete {FORM_NAME[cat]} record for this letter? Saves 9 bytes of shared block."):
                    self.proj.delete_record(cat, code)
                    self.populate_glyphs()
                    self.on_glyph_select()
                    self.update_header_stats()
            else:
                self.proj.create_record(cat, code)
                self.populate_glyphs()
                self.on_glyph_select()
                self.update_header_stats()

        def on_glyph_clear(self):
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            self.push_undo(rows)
            for y in range(8):
                rows[y] = 0
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_invert(self):
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            self.push_undo(rows)
            for y in range(8):
                rows[y] ^= 0xFF
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_mirror(self):
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            self.push_undo(rows)
            for y in range(8):
                b = rows[y]
                rev = 0
                for bit in range(8):
                    if b & (1 << bit):
                        rev |= (1 << (7 - bit))
                rows[y] = rev
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_shift(self, dx: int, dy: int):
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            self.push_undo(rows)
            new_rows = [0] * 8
            for y in range(8):
                ny = y + dy
                if 0 <= ny < 8:
                    byte = rows[y]
                    if dx > 0:
                        new_rows[ny] = (byte >> dx) & 0xFF
                    elif dx < 0:
                        new_rows[ny] = (byte << (-dx)) & 0xFF
                    else:
                        new_rows[ny] = byte
            for y in range(8):
                rows[y] = new_rows[y]
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_undo(self):
            if not self.undo_stack:
                return
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            prev = self.undo_stack.pop()
            for y in range(8):
                rows[y] = prev[y]
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_copy(self):
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.proj.get_rows(*info) or self.proj.fallback_rows(*info)
            self.clipboard_glyph = list(rows)
            self.set_status("Glyph copied to clipboard")

        def on_glyph_paste(self):
            if not self.clipboard_glyph:
                return
            info = self.current_glyph_info()
            if not info:
                return
            rows = self.ensure_editable_rows(*info)
            self.push_undo(rows)
            for y in range(8):
                rows[y] = self.clipboard_glyph[y]
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        def on_glyph_fallback(self):
            info = self.current_glyph_info()
            if not info:
                return
            cat, code = info
            fb = self.proj.fallback_rows(cat, code)
            rows = self.ensure_editable_rows(cat, code)
            self.push_undo(rows)
            for y in range(8):
                rows[y] = fb[y]
            self.proj.touch()
            self.redraw_pixel_editor()
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 6: Keyboard Layout
        # -----------------------------------------------------------------------------
        def setup_keyboard_tab(self):
            paned = ttk.PanedWindow(self.tab_keyb, orient=tk.HORIZONTAL)
            paned.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            left = ttk.Frame(paned)
            paned.add(left, weight=2)

            cols = ("key", "unshifted", "caps_shift")
            self.kb_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.kb_tree.heading("key", text="Physical Key")
            self.kb_tree.heading("unshifted", text="Plain (Unshifted)")
            self.kb_tree.heading("caps_shift", text="Caps Shift + Key")
            self.kb_tree.column("key", width=80, anchor="center")
            self.kb_tree.column("unshifted", width=120, anchor="center")
            self.kb_tree.column("caps_shift", width=140, anchor="center")

            sb = ttk.Scrollbar(left, orient=tk.VERTICAL, command=self.kb_tree.yview)
            self.kb_tree.configure(yscrollcommand=sb.set)
            self.kb_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)
            self.kb_tree.bind("<<TreeviewSelect>>", self.on_kb_select)

            right = ttk.LabelFrame(paned, text="Keyboard Assignment", padding=10)
            paned.add(right, weight=1)

            self.kb_lbl_sel = ttk.Label(right, text="Selected Key: -", font=bold_font)
            self.kb_lbl_sel.pack(anchor="w", pady=4)

            self.kb_field_var = tk.StringVar(value="unshifted")
            r1 = ttk.Radiobutton(right, text="Plain Key (Unshifted)", value="unshifted", variable=self.kb_field_var)
            r1.pack(anchor="w", pady=2)
            r2 = ttk.Radiobutton(right, text="Caps Shift + Key", value="caps_shift", variable=self.kb_field_var)
            r2.pack(anchor="w", pady=2)

            ttk.Label(right, text="Persian Letter to Assign:").pack(anchor="w", pady=(8, 2))
            self.kb_ent_letter = ttk.Entry(right, font=persian_font, width=6, justify="center")
            self.kb_ent_letter.pack(anchor="w", pady=2)

            btn_box = ttk.Frame(right)
            btn_box.pack(fill=tk.X, pady=8)
            ttk.Button(btn_box, text="Assign", command=self.on_kb_assign).pack(side=tk.LEFT, padx=4)
            ttk.Button(btn_box, text="Clear", command=self.on_kb_clear).pack(side=tk.LEFT, padx=4)

            sep = ttk.Separator(right, orient=tk.HORIZONTAL)
            sep.pack(fill=tk.X, pady=8)

            ttk.Label(right, text="Keyboard Coverage Analysis:", font=bold_font).pack(anchor="w", pady=2)
            self.kb_lbl_missing = tk.Label(right, text="", wraplength=250, justify="left", fg="#c62828")
            self.kb_lbl_missing.pack(anchor="w", pady=2)
            self.kb_lbl_dup = tk.Label(right, text="", wraplength=250, justify="left", fg="#f57c00")
            self.kb_lbl_dup.pack(anchor="w", pady=2)

        def populate_keyboard(self):
            selected = self.kb_tree.selection()
            selected_id = selected[0] if selected else None
            self.kb_tree.delete(*self.kb_tree.get_children())
            for idx, item in enumerate(self.proj.keyboard):
                k = item["key"]
                un = item["unshifted"] or "-"
                cs = "(exponent $5D)" if k == "E" else (item["caps_shift"] or "-")
                item_id = self.kb_tree.insert("", tk.END, iid=str(idx), values=(k, un, cs))
                if selected_id == str(idx):
                    self.kb_tree.selection_set(item_id)
            if not self.kb_tree.selection() and self.kb_tree.get_children():
                self.kb_tree.selection_set(self.kb_tree.get_children()[0])
            self.update_keyboard_analysis()

        def update_keyboard_analysis(self):
            counts = {e["letter"]: 0 for e in self.proj.included()}
            for item in self.proj.keyboard:
                for f in ("unshifted", "caps_shift"):
                    letter = item[f]
                    if letter and letter in counts:
                        counts[letter] += 1
            missing = [l for l, n in counts.items() if n == 0]
            dup = [l for l, n in counts.items() if n > 1]
            if missing:
                self.kb_lbl_missing.config(text=f"⚠️ Untyped Letters ({len(missing)}):\n" + " ".join(missing))
            else:
                self.kb_lbl_missing.config(text="✅ All letters assigned to keyboard", fg="#2e7d32")

            if dup:
                self.kb_lbl_dup.config(text=f"⚠️ Duplicate Keys ({len(dup)}):\n" + " ".join(dup))
            else:
                self.kb_lbl_dup.config(text="✅ No duplicate keys", fg="#2e7d32")

        def on_kb_select(self, event=None):
            sel = self.kb_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            item = self.proj.keyboard[idx]
            self.kb_lbl_sel.config(text=f"Selected Key: '{item['key']}'")
            field = self.kb_field_var.get()
            val = item[field] or ""
            self.kb_ent_letter.delete(0, tk.END)
            self.kb_ent_letter.insert(0, val)

        def on_kb_assign(self):
            sel = self.kb_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            item = self.proj.keyboard[idx]
            field = self.kb_field_var.get()
            if item["key"] == "E" and field == "caps_shift":
                messagebox.showwarning("Reserved Key", "Caps Shift + E is reserved for the exponent marker ($5D).")
                return
            letter = pl.normalize_text(self.kb_ent_letter.get()).strip()
            if letter and letter not in self.proj.code_by_letter():
                messagebox.showerror("Invalid Letter", f"'{letter}' is not an included Persian letter.")
                return
            note = self.proj.keyboard_assign(item["key"], field, letter)
            if note:
                self.set_status(f"Letter assigned ({note})")
            self.populate_keyboard()
            self.update_header_stats()

        def on_kb_clear(self):
            sel = self.kb_tree.selection()
            if not sel:
                return
            idx = int(sel[0])
            item = self.proj.keyboard[idx]
            field = self.kb_field_var.get()
            if item["key"] == "E" and field == "caps_shift":
                return
            self.proj.keyboard_assign(item["key"], field, "")
            self.populate_keyboard()
            self.update_header_stats()

        # -----------------------------------------------------------------------------
        # TAB 7: Letters & Joining
        # -----------------------------------------------------------------------------
        def setup_letters_tab(self):
            paned = ttk.PanedWindow(self.tab_letters, orient=tk.HORIZONTAL)
            paned.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

            left = ttk.Frame(paned)
            paned.add(left, weight=2)

            cols = ("code", "letter", "rank", "joins", "flag", "forms")
            self.let_tree = ttk.Treeview(left, columns=cols, show="headings", selectmode="browse")
            self.let_tree.heading("code", text="Code")
            self.let_tree.heading("letter", text="Letter")
            self.let_tree.heading("rank", text="Rank")
            self.let_tree.heading("joins", text="Joins Forward")
            self.let_tree.heading("flag", text="Flag")
            self.let_tree.heading("forms", text="Included Forms")
            self.let_tree.column("code", width=60, anchor="center")
            self.let_tree.column("letter", width=70, anchor="center")
            self.let_tree.column("rank", width=50, anchor="center")
            self.let_tree.column("joins", width=100, anchor="center")
            self.let_tree.column("flag", width=60, anchor="center")
            self.let_tree.column("forms", width=140)

            sb = ttk.Scrollbar(left, orient=tk.VERTICAL, command=self.let_tree.yview)
            self.let_tree.configure(yscrollcommand=sb.set)
            self.let_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)
            self.let_tree.bind("<<TreeviewSelect>>", self.on_let_select)

            right = ttk.LabelFrame(paned, text="Letter Properties", padding=10)
            paned.add(right, weight=1)

            self.let_lbl_char = ttk.Label(right, text="Selected: -", font=("DejaVu Sans", 14, "bold"))
            self.let_lbl_char.pack(anchor="w", pady=4)

            self.let_btn_toggle_join = ttk.Button(right, text="Toggle Joins Forward", command=self.on_toggle_join)
            self.let_btn_toggle_join.pack(anchor="w", pady=6)

            ttk.Label(right, text="Flags are derived automatically by genflags;\nonly 'joins forward' is user-controlled.", font=("DejaVu Sans", 9), foreground="#666666").pack(anchor="w", pady=4)

            sep = ttk.Separator(right, orient=tk.HORIZONTAL)
            sep.pack(fill=tk.X, pady=12)

            ttk.Label(right, text="Add New Letter Slot:", font=bold_font).pack(anchor="w", pady=2)
            self.let_lbl_free = ttk.Label(right, text="Free Slots: -")
            self.let_lbl_free.pack(anchor="w", pady=2)

            self.let_btn_add = ttk.Button(right, text="➕ Add New Letter", command=self.on_add_letter_dialog)
            self.let_btn_add.pack(anchor="w", pady=6)

        def populate_letters(self):
            selected = self.let_tree.selection()
            selected_id = selected[0] if selected else None
            self.let_tree.delete(*self.let_tree.get_children())
            for idx, e in enumerate(self.proj.included()):
                code_str = f"${e['code']:02X}"
                letter_str = e["letter"]
                rank_str = f"{e.get('rank', idx + 1)}"
                joins_str = "Yes" if e.get("joins_forward") else "No"
                flag_str = f"${e.get('flag_hex', '00')}"
                forms_str = " ".join(e.get("forms", []))
                item_id = self.let_tree.insert("", tk.END, iid=str(e["code"]), values=(code_str, letter_str, rank_str, joins_str, flag_str, forms_str))
                if selected_id == str(e["code"]):
                    self.let_tree.selection_set(item_id)

            free = self.proj.free_letter_codes()
            free_str = ", ".join(f"${c:02X}" for c in free) if free else "none"
            self.let_lbl_free.config(text=f"Free slots ({len(free)}): {free_str}")
            self.let_btn_add.config(state=tk.NORMAL if free else tk.DISABLED)

            if not self.let_tree.selection() and self.let_tree.get_children():
                self.let_tree.selection_set(self.let_tree.get_children()[0])

        def on_let_select(self, event=None):
            sel = self.let_tree.selection()
            if not sel:
                return
            code = int(sel[0])
            letter = self.proj.letter_by_code(code)
            if not letter:
                return
            char = letter["letter"]
            name = letter.get("name", "")
            joins = "Yes" if letter.get("joins_forward") else "No"
            self.let_lbl_char.config(text=f"${code:02X} '{char}' ({name})\nJoins forward: {joins}")

        def on_toggle_join(self):
            sel = self.let_tree.selection()
            if not sel:
                return
            code = int(sel[0])
            self.proj.toggle_joins(code)
            self.populate_letters()
            self.on_let_select()
            self.update_header_stats()

        def on_add_letter_dialog(self):
            free = self.proj.free_letter_codes()
            if not free:
                messagebox.showerror("Error", "All ROM letter slots are in use.")
                return
            dialog = tk.Toplevel(self.master)
            dialog.title("Add New Persian Letter")
            dialog.geometry("380x240")
            dialog.transient(self.master)
            dialog.grab_set()

            ttk.Label(dialog, text=f"Target Slot: ${free[0]:02X}", font=bold_font).pack(anchor="w", padx=16, pady=6)

            ttk.Label(dialog, text="Persian Character:").pack(anchor="w", padx=16, pady=2)
            ent_char = ttk.Entry(dialog, font=persian_font, width=6, justify="center")
            ent_char.pack(anchor="w", padx=16, pady=2)

            var_joins = tk.BooleanVar(value=True)
            ttk.Checkbutton(dialog, text="Joins the NEXT letter (joins_forward)", variable=var_joins).pack(anchor="w", padx=16, pady=4)

            ttk.Label(dialog, text="Latin Name (comment, e.g. 'pe'):").pack(anchor="w", padx=16, pady=2)
            ent_name = ttk.Entry(dialog)
            ent_name.pack(fill=tk.X, padx=16, pady=2)

            def do_add():
                char = pl.normalize_text(ent_char.get()).strip()
                if not char or len(char) > 2 or all(ord(c) < 0x80 for c in char) or char in self.proj.code_by_letter():
                    messagebox.showerror("Error", "Need one new non-ASCII Persian letter not already included.")
                    return
                name = ent_name.get().strip()
                code = self.proj.add_letter(char, var_joins.get(), name)
                dialog.destroy()
                self.populate_letters()
                self.populate_glyphs()
                self.update_header_stats()
                messagebox.showinfo("Letter Added", f"Added '{char}' as slot ${code:02X}. Be sure to draw its bitmap and assign a key!")

            ttk.Button(dialog, text="Add Letter", command=do_add).pack(pady=12)

        # -----------------------------------------------------------------------------
        # TAB 8: Validation & Budget
        # -----------------------------------------------------------------------------
        def setup_validation_tab(self):
            container = ttk.Frame(self.tab_valid, padding=10)
            container.pack(fill=tk.BOTH, expand=True)

            # Budget Cards
            card_box = ttk.LabelFrame(container, text="ROM Budget Allocation", padding=8)
            card_box.pack(fill=tk.X, pady=4)

            self.val_lbl_shared = ttk.Label(card_box, text="Shared Block: -", font=bold_font)
            self.val_lbl_shared.pack(anchor="w", pady=2)

            self.val_lbl_reports = ttk.Label(card_box, text="Reports Budget: -")
            self.val_lbl_reports.pack(anchor="w", pady=1)

            self.val_lbl_keywords = ttk.Label(card_box, text="Keywords Budget: -")
            self.val_lbl_keywords.pack(anchor="w", pady=1)

            self.val_lbl_tape = ttk.Label(card_box, text="Tape Messages Budget: -")
            self.val_lbl_tape.pack(anchor="w", pady=1)

            self.val_lbl_cp = ttk.Label(card_box, text="Copyright Budget: -")
            self.val_lbl_cp.pack(anchor="w", pady=1)

            # Validation Issues List
            issue_box = ttk.LabelFrame(container, text="Validation Checks & Issues", padding=8)
            issue_box.pack(fill=tk.BOTH, expand=True, pady=6)

            filter_row = ttk.Frame(issue_box)
            filter_row.pack(fill=tk.X, pady=2)
            ttk.Label(filter_row, text="Filter:").pack(side=tk.LEFT, padx=4)
            self.issue_filter_var = tk.StringVar(value="ALL")
            for lvl in ("ALL", "E", "W", "I"):
                ttk.Radiobutton(filter_row, text=lvl, value=lvl, variable=self.issue_filter_var, command=self.populate_validation).pack(side=tk.LEFT, padx=4)

            cols = ("level", "where", "msg")
            self.val_tree = ttk.Treeview(issue_box, columns=cols, show="headings")
            self.val_tree.heading("level", text="Level")
            self.val_tree.heading("where", text="Location")
            self.val_tree.heading("msg", text="Issue Description")
            self.val_tree.column("level", width=50, anchor="center")
            self.val_tree.column("where", width=180)
            self.val_tree.column("msg", width=500)

            sb = ttk.Scrollbar(issue_box, orient=tk.VERTICAL, command=self.val_tree.yview)
            self.val_tree.configure(yscrollcommand=sb.set)
            self.val_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            sb.pack(side=tk.RIGHT, fill=tk.Y)

        def populate_validation(self):
            s = self.proj.stats()
            self.val_lbl_shared.config(
                text=f"Shared Block: {s['free']} B free of {SHARED_TOTAL} B "
                     f"(isolated font {s['iso_bytes']} B + digits {DIGIT_BYTES} B + {s['records']} records × 9 B + 1 + reports {s['reports']} B)"
            )
            self.val_lbl_reports.config(text=f"Reports: {s['reports']} / {s['reports_budget']} B (soft target {REPORT_SOFT_TARGET} B)")
            self.val_lbl_keywords.config(text=f"Keywords: {s['keywords']} / {s['keywords_budget']} B")
            self.val_lbl_tape.config(text=f"Tape Messages: {s['tape']} / {s['tape_budget']} B")
            self.val_lbl_cp.config(text=f"Copyright: {s['copyright']} / {s['copyright_budget']} characters")

            lvl_filter = self.issue_filter_var.get()
            self.val_tree.delete(*self.val_tree.get_children())
            issues = self.proj.validate()
            for idx, i in enumerate(issues):
                if lvl_filter != "ALL" and i.level != lvl_filter:
                    continue
                self.val_tree.insert("", tk.END, iid=str(idx), values=(i.level, i.where, i.msg))

        # -----------------------------------------------------------------------------
        # TAB 9: Build & Log Output
        # -----------------------------------------------------------------------------
        def setup_log_tab(self):
            top_row = ttk.Frame(self.tab_log, padding=6)
            top_row.pack(fill=tk.X)

            ttk.Button(top_row, text="Run `make genflags`", command=self.on_genflags).pack(side=tk.LEFT, padx=4)
            ttk.Button(top_row, text="Run `make check-persian`", command=self.on_check_cli).pack(side=tk.LEFT, padx=4)
            ttk.Button(top_row, text="Run `make persian`", command=self.on_build_rom).pack(side=tk.LEFT, padx=4)
            ttk.Button(top_row, text="Clear Log", command=self.on_clear_log).pack(side=tk.RIGHT, padx=4)

            self.log_text = tk.Text(self.tab_log, bg="#1e1e1e", fg="#d4d4d4", font=("Courier", 10), insertbackground="white")
            self.log_text.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        def log_append(self, text: str):
            self.log_text.insert(tk.END, text + "\n")
            self.log_text.see(tk.END)

        def on_clear_log(self):
            self.log_text.delete("1.0", tk.END)

        def run_shell_command(self, cmd: list[str]):
            self.nb.select(self.tab_log)
            self.log_append(f"\n$ {' '.join(cmd)}")

            def worker():
                try:
                    proc = subprocess.Popen(
                        cmd,
                        cwd=str(self.proj.root),
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                        bufsize=1,
                    )
                    for line in proc.stdout:
                        self.master.after(0, self.log_append, line.rstrip())
                    proc.wait()
                    code = proc.returncode
                    self.master.after(0, self.log_append, f"[Process exited with code {code}]")
                except Exception as err:
                    self.master.after(0, self.log_append, f"Execution failed: {err}")

            threading.Thread(target=worker, daemon=True).start()

        # -----------------------------------------------------------------------------
        # Actions & Menus
        # -----------------------------------------------------------------------------
        def insert_zwnj(self, entry: ttk.Entry):
            entry.insert(tk.INSERT, ZWNJ)
            entry.event_generate("<KeyRelease>")

        def navigate_tree(self, tree: ttk.Treeview, delta: int):
            sel = tree.selection()
            if not sel:
                return
            items = tree.get_children()
            try:
                curr_idx = items.index(sel[0])
            except ValueError:
                return
            target_idx = curr_idx + delta
            if 0 <= target_idx < len(items):
                tree.selection_set(items[target_idx])
                tree.see(items[target_idx])

        def on_save(self):
            changed = self.proj.save()
            self.update_header_stats()
            if not changed:
                self.set_status("Nothing to save (no changes).")
                messagebox.showinfo("Save", "No changes detected.")
                return
            msg = f"Saved {len(changed)} file(s):\n" + "\n".join(f"• {c}" for c in changed)
            self.set_status(f"Saved {len(changed)} file(s).")
            if messagebox.askyesno("Save Complete", f"{msg}\n\nRun `make genflags` now to refresh the .asm files?"):
                self.on_genflags()

        def on_genflags(self):
            self.run_shell_command(["make", "genflags"])

        def on_check_cli(self):
            self.run_shell_command(["make", "check-persian"])

        def on_build_rom(self):
            self.run_shell_command(["make", "persian"])

        def refresh_all_views(self):
            self.populate_keywords()
            self.populate_reports()
            self.populate_tape()
            self.populate_boot()
            self.populate_glyphs()
            self.populate_keyboard()
            self.populate_letters()
            self.populate_validation()
            self.update_header_stats()

    app = App(app_root, proj)
    app_root.mainloop()


def main() -> int:
    parser = argparse.ArgumentParser(description="Sinclair ZX Spectrum 48K Persian ROM Editor")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent, help="repository root")
    parser.add_argument("--check", action="store_true", help="validate language data headless and exit")
    args = parser.parse_args()

    if args.check:
        return check(args.root)

    launch_gui(args.root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
