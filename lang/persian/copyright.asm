; ============================================================================
; PERSIAN BOOT COPYRIGHT LINE ($01ED-$0204)
; Printed right-to-left; the last character has bit 7 set as terminator.
; ============================================================================
; copyright text: (c) 2026 نسخه فارسی
        DB          $7F ; (c) copyright glyph / message step-over byte
        DB          $20 ; ' ' space separator
        DB          $36 ; '6'
        DB          $32 ; '2'
        DB          $30 ; '0'
        DB          $32 ; '2'
        DB          $20 ; ' ' space
        DB          $65 ; ن
        DB          $50 ; س
        DB          $4A ; خ
        DB          $68 ; ه
        DB          $20 ; ' ' space
        DB          $58 ; ف
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $50 ; س
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
