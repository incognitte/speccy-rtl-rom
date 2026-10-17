        DB          $80             ; initial step-over byte.
        DB          $04             ; Arabic ON
        DB          "QaY", '?'+$80  ; "رفع؟" - last byte has bit 7 set = end of message
        DB          'l', '?'+$80    ; unreachable leftover of the English "scroll?"

