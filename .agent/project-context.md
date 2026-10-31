# Project Context

## Architecture & Stack
- **speccy-rtl-rom**: ZX Spectrum 48K Right-to-Left ROM repo building Arabic and Persian ROMs using `sjasmplus`.
- **Persian Language Pipeline**:
  - `fixtures/persian/`: JSON sources for `text.json`, `letters.json`, `key_layout.json`, `decisions.json`.
  - `lang/persian/glyph_*.asm`: Hand-owned 8x8 bitmap tables.
  - `tools/genlang.py`: Generates `keywords.asm`, `reports.asm`, `tape_msgs.asm`, `copyright.asm`, `scroll_msg.asm`, `key_lookup.asm`, `cursor_letters.asm`, `sym_digits.asm`.
  - `tools/genflags.py`: Derives `flags.asm` from glyph tables and letters metadata.
  - `tools/persian_editor.py`: Tkinter GUI editor for all language, glyph, and keyboard data. Includes `--check` CLI flag for automated validation.
  - Shared block ($3923-$3CFF) limit is 989 bytes; font records and reports share this space.

## System Lessons Learned
- Curses / terminal emulators struggle with bidirectional RTL text and Arabic/Persian cursive joining. Tkinter natively uses host font rendering (HarfBuzz/Pango) allowing standard right-to-left typing and display.
- Stored text represents digits in RTL order and ZWNJ as `<ZWNJ>` token ($00 in ROM).
