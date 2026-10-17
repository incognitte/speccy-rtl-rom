; ============================================================================
; PERSIAN SCROLL PROMPT
; Control code $04 (Persian / RTL ON) followed by the prompt text and '?' + $80 terminator.
; ============================================================================
; scroll prompt "ادامه?"  ->  "scroll?"
        DB          $80 ; initial step-over byte
        DB          $04 ; Persian ON (RTL ON)
        DB          $42 ; ا
        DB          $4B ; د
        DB          $42 ; ا
        DB          $64 ; م
        DB          $68 ; ه
        DB          $BF ; '?' + $80: last byte has bit 7 set = end of message
