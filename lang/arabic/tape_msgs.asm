        DB          $80              ; initial inverted step-over byte (message 0 starts after it)
;
; Cassette message 0  ->  "Start tape, then press any key."
;     ابدا الشريط واضغط مفتاحا    (literal: "begin the tape and press a key")
        DM          "GHOG GdTQiW hGVZW eaJGM"
        DB          'G'+$80
;
; Cassette message 1  ->  "Program:"
;     CR + برمجة :     (the heading printed in the loader line, e.g. "Program: name")
        DB          $0D
        DM          "HQeLI"
        DB          ':'+$80
;
; Cassette message 2  ->  "Number array:"
;     CR + تنطيم رقم :   (literal: "array of number" - spelled with the letter ط)
        DB          $0D
        DM          "JfWie eQbe"
        DB          ':'+$80
;
; Cassette message 3  ->  "Character array:"
;     CR + تنطيم حرف :   (literal: "array of character")
        DB          $0D
        DM          "JfWie MQha"
        DB          ':'+$80
;
; Cassette message 4  ->  "Bytes:"
;     CR + بايتس :     (transliteration of "bytes")
        DB          $0D
        DM          "HGiJS"
        DB          ':'+$80
;
; ----------------------------------------------------------------------------
