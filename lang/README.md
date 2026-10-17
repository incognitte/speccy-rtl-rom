# `lang/` — Language Data Subsystem

This directory contains localized language assets for the Sinclair ZX Spectrum 48K ROM. Language assets are organized into dedicated subdirectories per language target.

## Structure

```
lang/
├── arabic/
└── persian/
```

## Module Mapping

Every language module provides the exact set of assembly include files expected by the core system under `src/`:

| Include File | Functional Area | Used in Core File |
|:---|:---|:---|
| `keywords.asm` | BASIC keyword token table ($A5-$FF) | `src/01_restarts_and_tables.asm` |
| `copyright.asm` | System boot copyright string | `src/01_restarts_and_tables.asm` |
| `sym_digits.asm` | Symbol shift digits layout | `src/02_keyboard_routines.asm` |
| `tape_msgs.asm` | Tape/cassette I/O status messages | `src/04_cassette_handling_routines.asm` |
| `scroll_msg.asm` | "scroll?" confirmation prompt | `src/05_screen_and_printer_routines.asm` |
| `key_lookup.asm` | ASCII-to-physical keyboard matrix map | `src/06_executive_routines.asm` |
| `cursor_letters.asm` | Mode cursors (K, E, G, L) | `src/06_executive_routines.asm` |
| `flags.asm` | Letter joining and contextual form flags | `src/10_floating_point_calculator.asm` / `src/11_rtl_glyph.asm` |
| `reports.asm` | Runtime error messages (0-27) | `src/11_rtl_glyph.asm` |
| `glyph_digits.asm` | Localized 8x8 digit bitmaps (0-9) | `src/11_rtl_glyph.asm` |
| `glyph_iso_a.asm` | Isolated font table A ($41-$5A) | `src/11_rtl_glyph.asm` |
| `glyph_iso_b.asm` | Isolated font table B ($61-$69) | `src/11_rtl_glyph.asm` |
| `glyph_final.asm` | Contextual Final form glyph records | `src/11_rtl_glyph.asm` |
| `glyph_medial.asm` | Contextual Medial form glyph records | `src/11_rtl_glyph.asm` |
| `glyph_initial.asm` | Contextual Initial form glyph records | `src/11_rtl_glyph.asm` |
