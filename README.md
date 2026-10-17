# Speccy RTL ROM

Right-to-left ROM images for the Sinclair ZX Spectrum 48K, built from annotated Z80 assembly source.

- **Arabic**: a reverse-engineered, labelled source tree of the ArabRAM Arabic ROM.
- **Persian**: a Persian-language ROM built on the same right-to-left engine, with Persian letters, keywords, error reports and digits.

Both ROMs are 16384 bytes and are produced from the same source tree.

## Branches

| Branch | Content |
|---|---|
| `rtl` | Builds both the Persian and the Arabic ROM (this branch). |
| `arabrom` | The original reverse-engineered Arabic ROM source only. |

## Requirements

- Linux or macOS with `make`, `git` and a C++ compiler (`g++` or `clang++`)
- Internet access on the first build

You do not need to install an assembler. If `sjasmplus` is not found in your `PATH`, the Makefile downloads and builds it automatically into `.sjasmplus/`.

## Build

```
make persian
make arabic
```

Output:

| Command | ROM image |
|---|---|
| `make persian` | `build/48k_PERSIAN.ROM` |
| `make arabic` | `build/48k_ARABIC.ROM` |

Other targets:

```
make clean       # remove build/
make distclean   # also remove the downloaded assembler
```

## Running

Load the resulting `.ROM` file as the 48K ROM in any ZX Spectrum emulator that allows a custom ROM, or burn it to a 16K EPROM for real hardware.

## Source layout

| Path | Content |
|---|---|
| `main.asm` | Assembly entry point; includes everything in `src/` |
| `src/` | The ROM source, split into numbered files |
| `lang/arabic/` | Arabic text, glyph and keyboard data |
| `lang/persian/` | Persian text, glyph and keyboard data |

The source files are commented; start with `main.asm` and the files in `src/`.
