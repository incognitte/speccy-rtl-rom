
; key 'H' ب ba (INITIAL form)
        DB          $48
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00010000

; key 'J' ت ta (INITIAL form)
        DB          $4A
        DB          %00000000
        DB          %00000000
        DB          %01010000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'K' ث tha (INITIAL form)
        DB          $4B
        DB          %00000000
        DB          %00100000
        DB          %01010000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'L' ج jim (INITIAL form)
        DB          $4C
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00001000

; key 'M' ح hah (INITIAL form)
        DB          $4D
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'N' خ kha (INITIAL form)
        DB          $4E
        DB          %00000000
        DB          %00000010
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'S' س sin (INITIAL form)
        DB          $53
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00010101
        DB          %11101010
        DB          %00000000
        DB          %00000000

; key 'T' ش shin (INITIAL form)
        DB          $54
        DB          %00000000
        DB          %00000100
        DB          %00001010
        DB          %00000000
        DB          %00010101
        DB          %11101010
        DB          %00000000
        DB          %00000000

; key 'U' ص sad (INITIAL form)
        DB          $55
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00101001
        DB          %11011111
        DB          %00000000
        DB          %00000000

; key 'V' ض dad (INITIAL form)
        DB          $56
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00000110
        DB          %00101001
        DB          %11011111
        DB          %00000000
        DB          %00000000

; key 'Y' ع ain (INITIAL form)
        DB          $59
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00001000
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'Z' غ ghain (INITIAL form)
        DB          $5A
        DB          %00000000
        DB          %00000100
        DB          %00000000
        DB          %00000110
        DB          %00001000
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'a' ف fa (INITIAL form)
        DB          $61
        DB          %00000000
        DB          %00001000
        DB          %00000011
        DB          %00000011
        DB          %00000001
        DB          %11111110
        DB          %00000000
        DB          %00000000

; key 'b' ق qaf (INITIAL form)
        DB          $62
        DB          %00000000
        DB          %00010001
        DB          %00000100
        DB          %00001010
        DB          %00000110
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'c' ك kaf (INITIAL form)
        DB          $63
        DB          %00000000
        DB          %00000100
        DB          %00001000
        DB          %00011110
        DB          %00000001
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'd' ل lam (INITIAL form)
        DB          $64
        DB          %00000000
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %11111110
        DB          %00000000
        DB          %00000000

; key 'e' م mim (INITIAL form)
        DB          $65
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %11111001
        DB          %00000110
        DB          %00000000

; key 'f' ن nun (INITIAL form)
        DB          $66
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'g' ه heh (INITIAL form)
        DB          $67
        DB          %00000000
        DB          %00011000
        DB          %00100100
        DB          %00101110
        DB          %00110010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'i' ي ya (INITIAL form)
        DB          $69
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00101000

; ---- Letters in no table (O P Q R W X h, A-F, I, k) always use the isolated font.
; ---- RTL_PRINT_EXTRA_MSG ($3CF6): boot-splash helper.  Patched call at $1295 (START-NEW, file 06).
; ---- Clears the screen, then prints the ARABIC TITLE LOGO: the message that follows the
; ---- cassette messages in file 04, starting at $09E0 (DE=$09DF is the inverted last byte of the
; ---- previous message, the step-over byte).  Screen result (row/column of the 8x8 cells):
; ----       row 12, col 15 : *        row 13, col 15 : |        row 14, cols 11-19 : عرب | رام
; ----       i.e. "ARAB | RAM"  (key codes "YQH | QGe").
