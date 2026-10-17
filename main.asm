; This source targets sjasmplus (https://github.com/z00m128/sjasmplus)
; exclusively. Directives used throughout: DB (byte data), DW (word
; data), DM (text strings), ORG (set address), EQU (constant).


        INCLUDE "src/00_system_variables.asm"
        INCLUDE "src/01_restarts_and_tables.asm"
        INCLUDE "src/02_keyboard_routines.asm"
        INCLUDE "src/03_loudspeaker_routines.asm"
        INCLUDE "src/04_cassette_handling_routines.asm"
        INCLUDE "src/05_screen_and_printer_routines.asm"
        INCLUDE "src/06_executive_routines.asm"
        INCLUDE "src/07_basic_line_and_command_interpretation.asm"
        INCLUDE "src/08_expression_evaluation.asm"
        INCLUDE "src/09_arithmetic_routines.asm"
        INCLUDE "src/10_floating_point_calculator.asm"
        INCLUDE "src/11_rtl_glyph.asm"
        INCLUDE "src/12_zx_spectrum_char_set.asm"

; #end                            ; generic cross-assembler directive   ; (sjasmplus: END not required)

; Acknowledgements
; -----------------
; Sean Irvine               for default list of section headings
; Dr. Ian Logan             for labels and functional disassembly.
; Dr. Frank O'Hara          for labels and functional disassembly.
;
; Credits
; -------
; Alex Pallero Gonzales     for corrections.
; Mike Dailly               for comments.
; Alvin Albrecht            for comments.
; Andy Styles               for full relocatability implementation and testing.
; Andrew Owen               for ZASM compatibility and format improvements.

;   For other assemblers you may have to add directives like these near the
;   beginning - see accompanying documentation.
;   ZASM (MacOs) cross-assembler directives. (uncomment by removing ';' )
;   #target rom           ; declare target file format as binary.
;   #code   0,$4000       ; declare code segment.
;   Also see notes at Address Labels 0609 and 1CA5 if your assembler has
;   trouble with expressions.
;
;   Note. The Sinclair Interface 1 ROM written by Dr. Ian Logan and Martin
;   Brennan calls numerous routines in this ROM.
;   Non-standard entry points have a label beginning with X.
