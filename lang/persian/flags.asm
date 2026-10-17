; ============================================================================
; PERSIAN GLYPH FLAGS TABLE ($34BC-$34E6, 43 bytes)
; Flags for codes $41-$6B describing forward joining and available forms.
; Bit 7: 1 = joins forward (0 = no fwd join)
; Bit 6: 0 = has INITIAL form in table (1 = no initial form)
; Bit 5: 0 = has MEDIAL form in table (1 = no medial form)
; Bit 4: 0 = has FINAL form in table (1 = no final form)
; Low nibble is $F.
; ============================================================================
        DB          $6F ; 'A' آ alef-madda: no fwd join; forms: isolated, final
        DB          $6F ; 'B' ا alef: no fwd join; forms: isolated, final
        DB          $BF ; 'C' ب be: joins fwd; forms: isolated, initial
        DB          $BF ; 'D' پ pe: joins fwd; forms: isolated, initial
        DB          $BF ; 'E' ت te: joins fwd; forms: isolated, initial
        DB          $BF ; 'F' ث se: joins fwd; forms: isolated, initial
        DB          $BF ; 'G' ج jim: joins fwd; forms: isolated, initial
        DB          $BF ; 'H' چ che: joins fwd; forms: isolated, initial
        DB          $BF ; 'I' ح hah: joins fwd; forms: isolated, initial
        DB          $BF ; 'J' خ khe: joins fwd; forms: isolated, initial
        DB          $7F ; 'K' د dal: no fwd join; forms: isolated
        DB          $7F ; 'L' ذ zal: no fwd join; forms: isolated
        DB          $7F ; 'M' ر re: no fwd join; forms: isolated
        DB          $7F ; 'N' ز ze: no fwd join; forms: isolated
        DB          $7F ; 'O' ژ zhe: no fwd join; forms: isolated
        DB          $BF ; 'P' س sin: joins fwd; forms: isolated, initial
        DB          $BF ; 'Q' ش shin: joins fwd; forms: isolated, initial
        DB          $BF ; 'R' ص sad: joins fwd; forms: isolated, initial
        DB          $BF ; 'S' ض zad: joins fwd; forms: isolated, initial
        DB          $FF ; 'T' ط tah: joins fwd; forms: isolated
        DB          $FF ; 'U' ظ zah: joins fwd; forms: isolated
        DB          $8F ; 'V' ع ain: joins fwd; forms: isolated, initial, medial, final
        DB          $8F ; 'W' غ ghain: joins fwd; forms: isolated, initial, medial, final
        DB          $BF ; 'X' ف fe: joins fwd; forms: isolated, initial
        DB          $BF ; 'Y' ق qaf: joins fwd; forms: isolated, initial
        DB          $BF ; 'Z' ک kaf: joins fwd; forms: isolated, initial
        DB          $7F ; '[' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; '\' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; ']' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; '^' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; '_' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; '`' (not a letter, unused): no fwd join; forms: isolated
        DB          $BF ; 'a' گ gaf: joins fwd; forms: isolated, initial
        DB          $7F ; 'b' لا lam-alef: no fwd join; forms: isolated
        DB          $BF ; 'c' ل lam: joins fwd; forms: isolated, initial
        DB          $BF ; 'd' م mim: joins fwd; forms: isolated, initial
        DB          $BF ; 'e' ن nun: joins fwd; forms: isolated, initial
        DB          $7F ; 'f' و vav: no fwd join; forms: isolated
        DB          $7F ; 'g' ؤ vav-hamze: no fwd join; forms: isolated
        DB          $9F ; 'h' ه heh: joins fwd; forms: isolated, initial, medial
        DB          $AF ; 'i' ی ye: joins fwd; forms: isolated, initial, final
        DB          $7F ; 'j' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F ; 'k' (not a letter, unused): no fwd join; forms: isolated
