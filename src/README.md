# `src/` — Z80 ROM Core Source Files

This directory contains the reassembled and modularized Z80 assembly source files of the Sinclair ZX Spectrum 48K ROM, adapted for RTL / bi-directional text and font rendering.

## Architecture & Layout

The project modularizes the monolithic 16 KB ($0000-$3FFF) Spectrum ROM following standard firmware / RTOS component breakdown:

| Module File | Address Range | Functional Description |
|:---|:---|:---|
| `00_system_variables.asm` | `$5C00+` / equates | System variable definitions and memory allocations |
| `01_restarts_and_tables.asm` | `$0000-$028D` | RST restart vectors, interrupt routine, character table, token table, copyright |
| `02_keyboard_routines.asm` | `$028E-$03B4` | Keyboard scanning, debouncing, symbol lookup |
| `03_loudspeaker_routines.asm` | `$03B5-$04BF` | Beeper / sound generator routines (`BEEPER`) |
| `04_cassette_handling_routines.asm` | `$04C0-$09F3` | Tape loading, saving, header handling, cassette messages |
| `05_screen_and_printer_routines.asm` | `$09F4-$111C` | Screen output, scrolling (`SCRL_MSSG`), line printing, printer handling |
| `06_executive_routines.asm` | `$111D-$1B9E` | Main executive loop, command processor, cursor handling, key lookup |
| `07_basic_line_and_command_interpretation.asm` | `$1B9F-$24FB` | BASIC syntax checking, line parsing, statement execution |
| `08_expression_evaluation.asm` | `$24FC-$2D27` | Expression parser, syntax tables, operator precedence |
| `09_arithmetic_routines.asm` | `$2D28-$32C4` | Binary / BCD arithmetic, integer operations |
| `10_floating_point_calculator.asm` | `$32C5-$3863` | Floating-point calculator routines and table |
| `11_rtl_glyph.asm` | `$3864-$3D00` | RTL glyph engine, contextual letter shaping, glyph lookup tables, font bitmaps |
| `12_zx_spectrum_char_set.asm` | `$3D00-$3FFF` | Standard Sinclair 8x8 Latin font and graphic character set |

## Language Subsystem Integration

All language-dependent data (keywords, error reports, copyright strings, cassette prompts, key mappings, cursor shapes, and font glyphs) are isolated in `lang/<language>/` and conditionally included:
```assembly
IFDEF LANG_PERSIAN
INCLUDE "lang/persian/<data>.asm"
ELSE
INCLUDE "lang/arabic/<data>.asm"
ENDIF
```

## Compilation

The core modules are assembled through the top-level driver [`main.asm`](../main.asm) using `sjasmplus`.
