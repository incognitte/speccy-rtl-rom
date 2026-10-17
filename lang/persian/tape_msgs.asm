; ============================================================================
; PERSIAN CASSETTE (TAPE) MESSAGES
; Messages 0 to 4 with carriage returns and ':' terminator.
; ============================================================================
        DB          $80 ; initial step-over byte (message 0 starts after it)
;
; Cassette message 0  ->  "Start tape, then press any key."
;     نوار را شروع و کلیدی بفشار
        DB          $65 ; ن
        DB          $66 ; و
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $20 ; ' ' space
        DB          $4D ; ر
        DB          $42 ; ا
        DB          $20 ; ' ' space
        DB          $51 ; ش
        DB          $4D ; ر
        DB          $66 ; و
        DB          $56 ; ع
        DB          $20 ; ' ' space
        DB          $66 ; و
        DB          $20 ; ' ' space
        DB          $5A ; ک
        DB          $63 ; ل
        DB          $69 ; ی
        DB          $4B ; د
        DB          $69 ; ی
        DB          $20 ; ' ' space
        DB          $43 ; ب
        DB          $58 ; ف
        DB          $51 ; ش
        DB          $42 ; ا
TAPE_MSG_0_END:
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
;
; Cassette message 1  ->  "Program:"
;     برنامه
        DB          $0D ; carriage return
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $65 ; ن
        DB          $42 ; ا
        DB          $64 ; م
        DB          $68 ; ه
        DB          $BA ; ':' + $80 message terminator
;
; Cassette message 2  ->  "Number array:"
;     آرایه·عددی
        DB          $0D ; carriage return
        DB          $41 ; آ
        DB          $4D ; ر
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $68 ; ه
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $56 ; ع
        DB          $4B ; د
        DB          $4B ; د
        DB          $69 ; ی
        DB          $BA ; ':' + $80 message terminator
;
; Cassette message 3  ->  "Character array:"
;     آرایه·متنی
        DB          $0D ; carriage return
        DB          $41 ; آ
        DB          $4D ; ر
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $68 ; ه
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $64 ; م
        DB          $45 ; ت
        DB          $65 ; ن
        DB          $69 ; ی
        DB          $BA ; ':' + $80 message terminator
;
; Cassette message 4  ->  "Bytes:"
;     بایت
        DB          $0D ; carriage return
        DB          $43 ; ب
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $45 ; ت
TAPE_MSG_4_END:
        DB          $BA ; ':' + $80 message terminator
