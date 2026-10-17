        DB          $7F             ; (c)  copyright glyph
        DM          " GhJhQGe ceHihJ"   ; ' ' + اوتورام ('AutoRAM') + ' ' + كمبيوت...
        DB          'Q'+$80        ; ...ر  (end of message)  -> كمبيوتر ('computer')

; ----------------------------------------------------------------------------
; $01FE: ENTRY FOR CONTROL CODES 0-3 (form override).  Jumped to from
; RTL_NEW_CTRL_HANDLER (file 11).  A = control code 0-3.
;   ADD A,A       A = 2*code  (0,2,4,6)
;   LD DE,$154C   one-shot output routine = the handler at $154C (file 06)
;   JP $0A7B      store A in TVDATA ($5C0E) and install DE as the output
;                 routine for exactly the NEXT character, which will then be
;                 printed with a forced letter form: 0 initial, 1 medial,
;                 2 isolated, 3 final.
; ----------------------------------------------------------------------------
