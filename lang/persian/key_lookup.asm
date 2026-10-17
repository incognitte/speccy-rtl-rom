; ============================================================================
; ASCII-INDEXED PHYSICAL KEY LOOKUP TABLE ($41-$7A)
; Maps ASCII characters to Persian key codes: capitals = Caps Shift + key, lowercase = plain key.
; ============================================================================
        DB          $3F ; 'A' Caps Shift + A   -> unmapped
        DB          $3F ; 'B' Caps Shift + B   -> unmapped
        DB          $4F ; 'C' Caps Shift + C   -> 'O' ژ zhe
        DB          $3F ; 'D' Caps Shift + D   -> unmapped
        DB          $5D ; 'E' Caps Shift + E   -> ']' exponent marker (the E key)
        DB          $3F ; 'F' Caps Shift + F   -> unmapped
        DB          $62 ; 'G' Caps Shift + G   -> 'b' لا lam-alef
        DB          $41 ; 'H' Caps Shift + H   -> 'A' آ alef-madda
        DB          $3F ; 'I' Caps Shift + I   -> unmapped
        DB          $3F ; 'J' Caps Shift + J   -> unmapped
        DB          $5A ; 'K' Caps Shift + K   -> 'Z' ک kaf
        DB          $61 ; 'L' Caps Shift + L   -> 'a' گ gaf
        DB          $67 ; 'M' Caps Shift + M   -> 'g' ؤ vav-hamze
        DB          $66 ; 'N' Caps Shift + N   -> 'f' و vav
        DB          $47 ; 'O' Caps Shift + O   -> 'G' ج jim
        DB          $48 ; 'P' Caps Shift + P   -> 'H' چ che
        DB          $3F ; 'Q' Caps Shift + Q   -> unmapped
        DB          $3F ; 'R' Caps Shift + R   -> unmapped
        DB          $3F ; 'S' Caps Shift + S   -> unmapped
        DB          $3F ; 'T' Caps Shift + T   -> unmapped
        DB          $3F ; 'U' Caps Shift + U   -> unmapped
        DB          $3F ; 'V' Caps Shift + V   -> unmapped
        DB          $3F ; 'W' Caps Shift + W   -> unmapped
        DB          $3F ; 'X' Caps Shift + X   -> unmapped
        DB          $3F ; 'Y' Caps Shift + Y   -> unmapped
        DB          $3F ; 'Z' Caps Shift + Z   -> unmapped
        DB          $3F ; '[' (no key)         -> unmapped
        DB          $3F ; '\' (no key)         -> unmapped
        DB          $3F ; ']' (no key)         -> unmapped
        DB          $3F ; '^' (no key)         -> unmapped
        DB          $3F ; '_' (no key)         -> unmapped
        DB          $3F ; '`' (no key)         -> unmapped
        DB          $51 ; 'a' key A plain      -> 'Q' ش shin
        DB          $4C ; 'b' key B plain      -> 'L' ذ zal
        DB          $4E ; 'c' key C plain      -> 'N' ز ze
        DB          $69 ; 'd' key D plain      -> 'i' ی ye
        DB          $46 ; 'e' key E plain      -> 'F' ث se
        DB          $43 ; 'f' key F plain      -> 'C' ب be
        DB          $63 ; 'g' key G plain      -> 'c' ل lam
        DB          $42 ; 'h' key H plain      -> 'B' ا alef
        DB          $68 ; 'i' key I plain      -> 'h' ه heh
        DB          $45 ; 'j' key J plain      -> 'E' ت te
        DB          $65 ; 'k' key K plain      -> 'e' ن nun
        DB          $64 ; 'l' key L plain      -> 'd' م mim
        DB          $44 ; 'm' key M plain      -> 'D' پ pe
        DB          $4B ; 'n' key N plain      -> 'K' د dal
        DB          $4A ; 'o' key O plain      -> 'J' خ khe
        DB          $49 ; 'p' key P plain      -> 'I' ح hah
        DB          $53 ; 'q' key Q plain      -> 'S' ض zad
        DB          $59 ; 'r' key R plain      -> 'Y' ق qaf
        DB          $50 ; 's' key S plain      -> 'P' س sin
        DB          $58 ; 't' key T plain      -> 'X' ف fe
        DB          $56 ; 'u' key U plain      -> 'V' ع ain
        DB          $4D ; 'v' key V plain      -> 'M' ر re
        DB          $52 ; 'w' key W plain      -> 'R' ص sad
        DB          $54 ; 'x' key X plain      -> 'T' ط tah
        DB          $57 ; 'y' key Y plain      -> 'W' غ ghain
        DB          $55 ; 'z' key Z plain      -> 'U' ظ zah
