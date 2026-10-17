        DB          $06              ; comma: to column 16
        DB          '*'              ; row 12 (after scrolling): top ornament of the logo
        DB          $06, $06         ; comma: wrap to the next line, comma: column 16 again
        DB          '|'              ; row 13: second ornament
        DB          $17, $0C, $00    ; TAB 12: already past it, so wrap to the next line, column 12
        DM          "YQH | QGe"      ; row 14: عرب | رام  =  "ARAB | RAM"
        DB          $16, $0C         ; AT 12, (column follows)
        DB          $88              ; column 8 with bit 7 set = end of message (control byte)

