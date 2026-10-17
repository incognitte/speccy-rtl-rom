; ============================================================================
; PERSIAN GLYPH TABLE (FINAL FORM)
; 9-byte records: 1-byte letter code key followed by 8-byte font bitmap.
; ============================================================================

; key 'A' آ alef-madda (FINAL form)
        DB          $41
        DB          %00111110
        DB          %00100000
        DB          %00001000
        DB          %00001000
        DB          %00000111
        DB          %00000000
        DB          %00000000
        DB          %00000000

; key 'B' ا alef (FINAL form)
        DB          $42
        DB          %00000000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00000111
        DB          %00000000
        DB          %00000000
        DB          %00000000

; key 'V' ع ain (FINAL form)
        DB          $56
        DB          %00000000
        DB          %00000000
        DB          %00111100
        DB          %00011100
        DB          %00100011
        DB          %01000000
        DB          %01000001
        DB          %00111110

; key 'W' غ ghain (FINAL form)
        DB          $57
        DB          %00000000
        DB          %10000000
        DB          %00111100
        DB          %00011100
        DB          %00100011
        DB          %01000000
        DB          %01000001
        DB          %00111110

; key 'i' ی ye (FINAL form)
        DB          $69
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %01000001
        DB          %10000010
        DB          %10000001
        DB          %01111110
