;;; @file 12_zx_spectrum_char_set.asm
;;; @brief Standard Sinclair 8x8 character set, CHR$ 32-127 ($3D00-$3FFF)

; -------------------------------
; THE 'ZX SPECTRUM CHARACTER SET'
; -------------------------------

        ASSERT  $ <= $3D00
        IF      $ < $3D00
        DS      $3D00-$, $FF
        ENDIF
        ORG     $3D00


;; char-set

; $20 - Character: ' '          CHR$(32)
;;; @data
;;; @brief Standard character set bitmaps, CHR$ 32-127 ($3D00-$3FFF).
;;;
;;; 96 glyphs of 8 bytes each (one byte per pixel row, leftmost pixel = bit 7),
;;; starting with SPACE at $3D00. The region is fixed: it is addressed through
;;; the CHARS system variable (CHARS = $3D00 - 256).
;;; @address $3D00
L3D00:
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000

; $21 - Character: '!'          CHR$(33)

        DB          %00000000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000
        DB          %00010000
        DB          %00000000

; $22 - Character: '"'          CHR$(34)

        DB          %00000000
        DB          %00100100
        DB          %00100100
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000

; $23 - Character: '#'          CHR$(35)

        DB          %00000000
        DB          %00100100
        DB          %01111110
        DB          %00100100
        DB          %00100100
        DB          %01111110
        DB          %00100100
        DB          %00000000

; $24 - Character: '$'          CHR$(36)

        DB          %00000000
        DB          %00001000
        DB          %00111110
        DB          %00101000
        DB          %00111110
        DB          %00001010
        DB          %00111110
        DB          %00001000

; $25 - Character: '%'          CHR$(37)

        DB          %00000000
        DB          %01100010
        DB          %01100100
        DB          %00001000
        DB          %00010000
        DB          %00100110
        DB          %01000110
        DB          %00000000

; $26 - Character: '&'          CHR$(38)

        DB          %00000000
        DB          %00010000
        DB          %00101000
        DB          %00010000
        DB          %00101010
        DB          %01000100
        DB          %00111010
        DB          %00000000

; $27 - Character: '''          CHR$(39)

        DB          %00000000
        DB          %00001000
        DB          %00010000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000

;==========================================================================
; *** RIGHT-TO-LEFT PUNCTUATION MIRRORING (font table, $3D00-$4000) ***
;==========================================================================
;   Starting here, several punctuation glyphs in the STANDARD, STATIC
;   font table have been edited directly (unlike letters, which are
;   substituted dynamically -- see $145D). This is a separate, second
;   mechanism, and a very clean, high-confidence finding:
;
;     '(' (code 40) and ')' (code 41)  -- bitmaps SWAPPED with each
;                                          other (each now draws the
;                                          other's original shape)
;     '<' (code 60) and '>' (code 62)  -- bitmaps SWAPPED (mirror pair)
;     ';' (code 59)                    -- individual rows horizontally
;                                          mirrored
;     ',' (44) and '.' (46)            -- minor shape tweaks
;     '?' (code 63)                    -- horizontally mirrored curve
;     '[' (91) and ']' (93)            -- replaced with two NEW, custom
;                                          symbols unrelated to brackets
;                                          (not identified -- possibly a
;                                          split ligature or an Arabic-
;                                          specific punctuation mark)
;
;   Digit and A-Z/a-z bitmaps in THIS STATIC TABLE are all UNCHANGED
;   (confirmed by direct comparison). Letters get their Arabic shapes
;   from the dynamic substitution at $145D (confirmed on real hardware).
;   Digits are ALSO confirmed on real hardware to render as Persian/
;   Arabic-Indic numerals despite this static table being untouched for
;   codes '0'-'9' -- so digit substitution happens through some other,
;   not-yet-located mechanism (see the correction note at $145D above).
;   It is not a simple static font swap, since these bytes are provably
;   identical to the original ROM.
;
;   Swapping the pixel shapes of direction-sensitive punctuation like
;   parentheses and angle brackets -- while leaving the underlying
;   character CODE and its meaning in BASIC syntax untouched -- is
;   exactly what you need to make these symbols look visually correct
;   when the surrounding text flows right-to-left, and lines up with
;   the $0DF4 column-formula change documented above. Together, these
;   two findings make right-to-left rendering a near-certainty rather
;   than just a hypothesis.
;==========================================================================

; $28 - Character: '('          CHR$(40)

        DB          %00000000
        DB          %00100000        ; row 1 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00010000        ; row 2 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00010000        ; row 3 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00010000        ; row 4 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00010000        ; row 5 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00100000        ; row 6 of character $28 ('(')  bitmap, mirrored for RTL display
        DB          %00000000

; $29 - Character: ')'          CHR$(41)

        DB          %00000000
        DB          %00000100        ; row 1 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 2 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 3 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 4 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 5 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00000100        ; row 6 of character $29 (')')  bitmap, mirrored for RTL display
        DB          %00000000

; $2A - Character: '*'          CHR$(42)

        DB          %00000000
        DB          %00000000
        DB          %00010100
        DB          %00001000
        DB          %00111110
        DB          %00001000
        DB          %00010100
        DB          %00000000

; $2B - Character: '+'          CHR$(43)

        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00001000
        DB          %00111110
        DB          %00001000
        DB          %00001000
        DB          %00000000

; $2C - Character: ','          CHR$(44)

        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00001000
        DB          %00000100        ; row 7 of character $2C (',')  bitmap, mirrored for RTL display

; $2D - Character: '-'          CHR$(45)

        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00111110
        DB          %00000000
        DB          %00000000
        DB          %00000000

; $2E - Character: '.'          CHR$(46)

        DB          %00000000
        DB          %00000000
        DB          %00000100        ; row 2 of character $2E ('.')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 3 of character $2E ('.')  bitmap, mirrored for RTL display
        DB          %00001100        ; row 4 of character $2E ('.')  bitmap, mirrored for RTL display
        DB          %00001100        ; row 5 of character $2E ('.')  bitmap, mirrored for RTL display
        DB          %00000000        ; row 6 of character $2E ('.')  bitmap, mirrored for RTL display
        DB          %00000000

; $2F - Character: '/'          CHR$(47)

        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000100
        DB          %00001000
        DB          %00010000
        DB          %00100000
        DB          %00000000

; $30 - Character: '0'          CHR$(48)

        DB          %00000000
        DB          %00111100
        DB          %01000110
        DB          %01001010
        DB          %01010010
        DB          %01100010
        DB          %00111100
        DB          %00000000

; $31 - Character: '1'          CHR$(49)

        DB          %00000000
        DB          %00011000
        DB          %00101000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00111110
        DB          %00000000

; $32 - Character: '2'          CHR$(50)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %00000010
        DB          %00111100
        DB          %01000000
        DB          %01111110
        DB          %00000000

; $33 - Character: '3'          CHR$(51)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %00001100
        DB          %00000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $34 - Character: '4'          CHR$(52)

        DB          %00000000
        DB          %00001000
        DB          %00011000
        DB          %00101000
        DB          %01001000
        DB          %01111110
        DB          %00001000
        DB          %00000000

; $35 - Character: '5'          CHR$(53)

        DB          %00000000
        DB          %01111110
        DB          %01000000
        DB          %01111100
        DB          %00000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $36 - Character: '6'          CHR$(54)

        DB          %00000000
        DB          %00111100
        DB          %01000000
        DB          %01111100
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $37 - Character: '7'          CHR$(55)

        DB          %00000000
        DB          %01111110
        DB          %00000010
        DB          %00000100
        DB          %00001000
        DB          %00010000
        DB          %00010000
        DB          %00000000

; $38 - Character: '8'          CHR$(56)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %00111100
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $39 - Character: '9'          CHR$(57)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000010
        DB          %00111110
        DB          %00000010
        DB          %00111100
        DB          %00000000

; $3A - Character: ':'          CHR$(58)

        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00010000
        DB          %00000000
        DB          %00000000
        DB          %00010000
        DB          %00000000

; $3B - Character: ';'          CHR$(59)

        DB          %00000000
        DB          %00000000
        DB          %00001000        ; row 2 of character $3B (';')  bitmap, mirrored for RTL display
        DB          %00000000
        DB          %00000000
        DB          %00001000        ; row 5 of character $3B (';')  bitmap, mirrored for RTL display
        DB          %00001000        ; row 6 of character $3B (';')  bitmap, mirrored for RTL display
        DB          %00000100        ; row 7 of character $3B (';')  bitmap, mirrored for RTL display

; $3C - Character: '<'          CHR$(60)

        DB          %00000000
        DB          %00000000
        DB          %00010000        ; row 2 of character $3C ('<')  bitmap, mirrored for RTL display
        DB          %00001000
        DB          %00000100        ; row 4 of character $3C ('<')  bitmap, mirrored for RTL display
        DB          %00001000
        DB          %00010000        ; row 6 of character $3C ('<')  bitmap, mirrored for RTL display
        DB          %00000000

; $3D - Character: '='          CHR$(61)

        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00111110
        DB          %00000000
        DB          %00111110
        DB          %00000000
        DB          %00000000

; $3E - Character: '>'          CHR$(62)

        DB          %00000000
        DB          %00000000
        DB          %00000100        ; row 2 of character $3E ('>')  bitmap, mirrored for RTL display
        DB          %00001000
        DB          %00010000        ; row 4 of character $3E ('>')  bitmap, mirrored for RTL display
        DB          %00001000
        DB          %00000100        ; row 6 of character $3E ('>')  bitmap, mirrored for RTL display
        DB          %00000000

; $3F - Character: '?'          CHR$(63)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %00100000        ; row 3 of character $3F ('?')  bitmap, mirrored for RTL display
        DB          %00010000        ; row 4 of character $3F ('?')  bitmap, mirrored for RTL display
        DB          %00000000
        DB          %00010000        ; row 6 of character $3F ('?')  bitmap, mirrored for RTL display
        DB          %00000000

; $40 - Character: '@'          CHR$(64)

        DB          %00000000
        DB          %00111100
        DB          %01001010
        DB          %01010110
        DB          %01011110
        DB          %01000000
        DB          %00111100
        DB          %00000000

; $41 - Character: 'A'          CHR$(65)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000010
        DB          %01111110
        DB          %01000010
        DB          %01000010
        DB          %00000000

; $42 - Character: 'B'          CHR$(66)

        DB          %00000000
        DB          %01111100
        DB          %01000010
        DB          %01111100
        DB          %01000010
        DB          %01000010
        DB          %01111100
        DB          %00000000

; $43 - Character: 'C'          CHR$(67)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000000
        DB          %01000000
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $44 - Character: 'D'          CHR$(68)

        DB          %00000000
        DB          %01111000
        DB          %01000100
        DB          %01000010
        DB          %01000010
        DB          %01000100
        DB          %01111000
        DB          %00000000

; $45 - Character: 'E'          CHR$(69)

        DB          %00000000
        DB          %01111110
        DB          %01000000
        DB          %01111100
        DB          %01000000
        DB          %01000000
        DB          %01111110
        DB          %00000000

; $46 - Character: 'F'          CHR$(70)

        DB          %00000000
        DB          %01111110
        DB          %01000000
        DB          %01111100
        DB          %01000000
        DB          %01000000
        DB          %01000000
        DB          %00000000

; $47 - Character: 'G'          CHR$(71)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000000
        DB          %01001110
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $48 - Character: 'H'          CHR$(72)

        DB          %00000000
        DB          %01000010
        DB          %01000010
        DB          %01111110
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00000000

; $49 - Character: 'I'          CHR$(73)

        DB          %00000000
        DB          %00111110
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00111110
        DB          %00000000

; $4A - Character: 'J'          CHR$(74)

        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %00000010
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $4B - Character: 'K'          CHR$(75)

        DB          %00000000
        DB          %01000100
        DB          %01001000
        DB          %01110000
        DB          %01001000
        DB          %01000100
        DB          %01000010
        DB          %00000000

; $4C - Character: 'L'          CHR$(76)

        DB          %00000000
        DB          %01000000
        DB          %01000000
        DB          %01000000
        DB          %01000000
        DB          %01000000
        DB          %01111110
        DB          %00000000

; $4D - Character: 'M'          CHR$(77)

        DB          %00000000
        DB          %01000010
        DB          %01100110
        DB          %01011010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00000000

; $4E - Character: 'N'          CHR$(78)

        DB          %00000000
        DB          %01000010
        DB          %01100010
        DB          %01010010
        DB          %01001010
        DB          %01000110
        DB          %01000010
        DB          %00000000

; $4F - Character: 'O'          CHR$(79)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $50 - Character: 'P'          CHR$(80)

        DB          %00000000
        DB          %01111100
        DB          %01000010
        DB          %01000010
        DB          %01111100
        DB          %01000000
        DB          %01000000
        DB          %00000000

; $51 - Character: 'Q'          CHR$(81)

        DB          %00000000
        DB          %00111100
        DB          %01000010
        DB          %01000010
        DB          %01010010
        DB          %01001010
        DB          %00111100
        DB          %00000000

; $52 - Character: 'R'          CHR$(82)

        DB          %00000000
        DB          %01111100
        DB          %01000010
        DB          %01000010
        DB          %01111100
        DB          %01000100
        DB          %01000010
        DB          %00000000

; $53 - Character: 'S'          CHR$(83)

        DB          %00000000
        DB          %00111100
        DB          %01000000
        DB          %00111100
        DB          %00000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $54 - Character: 'T'          CHR$(84)

        DB          %00000000
        DB          %11111110
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000

; $55 - Character: 'U'          CHR$(85)

        DB          %00000000
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; $56 - Character: 'V'          CHR$(86)

        DB          %00000000
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00100100
        DB          %00011000
        DB          %00000000

; $57 - Character: 'W'          CHR$(87)

        DB          %00000000
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %01011010
        DB          %00100100
        DB          %00000000

; $58 - Character: 'X'          CHR$(88)

        DB          %00000000
        DB          %01000010
        DB          %00100100
        DB          %00011000
        DB          %00011000
        DB          %00100100
        DB          %01000010
        DB          %00000000

; $59 - Character: 'Y'          CHR$(89)

        DB          %00000000
        DB          %10000010
        DB          %01000100
        DB          %00101000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000

; $5A - Character: 'Z'          CHR$(90)

        DB          %00000000
        DB          %01111110
        DB          %00000100
        DB          %00001000
        DB          %00010000
        DB          %00100000
        DB          %01111110
        DB          %00000000

; $5B - Character: '['          CHR$(91)

        DB          %00000000
        DB          %00000000        ; row 1 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %00000010        ; row 2 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %00111100        ; row 3 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %01010100        ; row 4 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %00010100        ; row 5 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %00010100        ; row 6 of character $5B ('[')  bitmap, mirrored for RTL display
        DB          %00000000

; $5C - Character: '\'          CHR$(92)

        DB          %00000000
        DB          %00000000
        DB          %01000000
        DB          %00100000
        DB          %00010000
        DB          %00001000
        DB          %00000100
        DB          %00000000

; $5D - Character: ']'          CHR$(93)

        DB          %00000000
        DB          %00111100        ; row 1 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %01000000        ; row 2 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %01111000        ; row 3 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %01000000        ; row 4 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %01000000        ; row 5 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %00111100        ; row 6 of character $5D (']')  bitmap, mirrored for RTL display
        DB          %00000000

; $5E - Character: '^'          CHR$(94)

        DB          %00000000
        DB          %00010000
        DB          %00111000
        DB          %01010100
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000

; $5F - Character: '_'          CHR$(95)

        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %11111111

; $60 - Character: 'ukp'        CHR$(96)

        DB          %00000000
        DB          %00011100
        DB          %00100010
        DB          %01111000
        DB          %00100000
        DB          %00100000
        DB          %01111110
        DB          %00000000

; $61 - Character: 'a'          CHR$(97)

        DB          %00000000
        DB          %00000000
        DB          %00111000
        DB          %00000100
        DB          %00111100
        DB          %01000100
        DB          %00111100
        DB          %00000000

; $62 - Character: 'b'          CHR$(98)

        DB          %00000000
        DB          %00100000
        DB          %00100000
        DB          %00111100
        DB          %00100010
        DB          %00100010
        DB          %00111100
        DB          %00000000

; $63 - Character: 'c'          CHR$(99)

        DB          %00000000
        DB          %00000000
        DB          %00011100
        DB          %00100000
        DB          %00100000
        DB          %00100000
        DB          %00011100
        DB          %00000000

; $64 - Character: 'd'          CHR$(100)

        DB          %00000000
        DB          %00000100
        DB          %00000100
        DB          %00111100
        DB          %01000100
        DB          %01000100
        DB          %00111100
        DB          %00000000

; $65 - Character: 'e'          CHR$(101)

        DB          %00000000
        DB          %00000000
        DB          %00111000
        DB          %01000100
        DB          %01111000
        DB          %01000000
        DB          %00111100
        DB          %00000000

; $66 - Character: 'f'          CHR$(102)

        DB          %00000000
        DB          %00001100
        DB          %00010000
        DB          %00011000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000

; $67 - Character: 'g'          CHR$(103)

        DB          %00000000
        DB          %00000000
        DB          %00111100
        DB          %01000100
        DB          %01000100
        DB          %00111100
        DB          %00000100
        DB          %00111000

; $68 - Character: 'h'          CHR$(104)

        DB          %00000000
        DB          %01000000
        DB          %01000000
        DB          %01111000
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %00000000

; $69 - Character: 'i'          CHR$(105)

        DB          %00000000
        DB          %00010000
        DB          %00000000
        DB          %00110000
        DB          %00010000
        DB          %00010000
        DB          %00111000
        DB          %00000000

; $6A - Character: 'j'          CHR$(106)

        DB          %00000000
        DB          %00000100
        DB          %00000000
        DB          %00000100
        DB          %00000100
        DB          %00000100
        DB          %00100100
        DB          %00011000

; $6B - Character: 'k'          CHR$(107)

        DB          %00000000
        DB          %00100000
        DB          %00101000
        DB          %00110000
        DB          %00110000
        DB          %00101000
        DB          %00100100
        DB          %00000000

; $6C - Character: 'l'          CHR$(108)

        DB          %00000000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00001100
        DB          %00000000

; $6D - Character: 'm'          CHR$(109)

        DB          %00000000
        DB          %00000000
        DB          %01101000
        DB          %01010100
        DB          %01010100
        DB          %01010100
        DB          %01010100
        DB          %00000000

; $6E - Character: 'n'          CHR$(110)

        DB          %00000000
        DB          %00000000
        DB          %01111000
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %00000000

; $6F - Character: 'o'          CHR$(111)

        DB          %00000000
        DB          %00000000
        DB          %00111000
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %00111000
        DB          %00000000

; $70 - Character: 'p'          CHR$(112)

        DB          %00000000
        DB          %00000000
        DB          %01111000
        DB          %01000100
        DB          %01000100
        DB          %01111000
        DB          %01000000
        DB          %01000000

; $71 - Character: 'q'          CHR$(113)

        DB          %00000000
        DB          %00000000
        DB          %00111100
        DB          %01000100
        DB          %01000100
        DB          %00111100
        DB          %00000100
        DB          %00000110

; $72 - Character: 'r'          CHR$(114)

        DB          %00000000
        DB          %00000000
        DB          %00011100
        DB          %00100000
        DB          %00100000
        DB          %00100000
        DB          %00100000
        DB          %00000000

; $73 - Character: 's'          CHR$(115)

        DB          %00000000
        DB          %00000000
        DB          %00111000
        DB          %01000000
        DB          %00111000
        DB          %00000100
        DB          %01111000
        DB          %00000000

; $74 - Character: 't'          CHR$(116)

        DB          %00000000
        DB          %00010000
        DB          %00111000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00001100
        DB          %00000000

; $75 - Character: 'u'          CHR$(117)

        DB          %00000000
        DB          %00000000
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %00111000
        DB          %00000000

; $76 - Character: 'v'          CHR$(118)

        DB          %00000000
        DB          %00000000
        DB          %01000100
        DB          %01000100
        DB          %00101000
        DB          %00101000
        DB          %00010000
        DB          %00000000

; $77 - Character: 'w'          CHR$(119)

        DB          %00000000
        DB          %00000000
        DB          %01000100
        DB          %01010100
        DB          %01010100
        DB          %01010100
        DB          %00101000
        DB          %00000000

; $78 - Character: 'x'          CHR$(120)

        DB          %00000000
        DB          %00000000
        DB          %01000100
        DB          %00101000
        DB          %00010000
        DB          %00101000
        DB          %01000100
        DB          %00000000

; $79 - Character: 'y'          CHR$(121)

        DB          %00000000
        DB          %00000000
        DB          %01000100
        DB          %01000100
        DB          %01000100
        DB          %00111100
        DB          %00000100
        DB          %00111000

; $7A - Character: 'z'          CHR$(122)

        DB          %00000000
        DB          %00000000
        DB          %01111100
        DB          %00001000
        DB          %00010000
        DB          %00100000
        DB          %01111100
        DB          %00000000

; $7B - Character: '{'          CHR$(123)

        DB          %00000000
        DB          %00001110
        DB          %00001000
        DB          %00110000
        DB          %00001000
        DB          %00001000
        DB          %00001110
        DB          %00000000

; $7C - Character: '|'          CHR$(124)

        DB          %00000000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00000000

; $7D - Character: '}'          CHR$(125)

        DB          %00000000
        DB          %01110000
        DB          %00010000
        DB          %00001100
        DB          %00010000
        DB          %00010000
        DB          %01110000
        DB          %00000000

; $7E - Character: '~'          CHR$(126)

        DB          %00000000
        DB          %00010100
        DB          %00101000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000

; $7F - Character: '(c)'        CHR$(127)

        DB          %00111100
        DB          %01000010
        DB          %10011001
        DB          %10100001
        DB          %10100001
        DB          %10011001
        DB          %01000010
        DB          %00111100
