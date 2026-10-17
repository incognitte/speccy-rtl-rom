; ============================================================================
; PERSIAN REPORT ERROR MESSAGES (0-27)
; Table starts with $80 step-over byte; each message ends with bit 7 set.
; ============================================================================
        DB          $80 ; initial step-over byte
; report 0  OK  =>  آماده
        DB          $41 ; آ
        DB          $64 ; م
        DB          $42 ; ا
        DB          $4B ; د
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; report 1  NEXT without FOR  =>  بدون·برای
        DB          $43 ; ب
        DB          $4B ; د
        DB          $66 ; و
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $42 ; ا
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; report 2  Variable not found  =>  متغیرنیست
        DB          $64 ; م
        DB          $45 ; ت
        DB          $57 ; غ
        DB          $69 ; ی
        DB          $4D ; ر
        DB          $65 ; ن
        DB          $69 ; ی
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; report 3  Subscript wrong  =>  اندیس·غلط
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $4B ; د
        DB          $69 ; ی
        DB          $50 ; س
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 4  Out of memory  =>  حافظه·پر
        DB          $49 ; ح
        DB          $42 ; ا
        DB          $58 ; ف
        DB          $55 ; ظ
        DB          $68 ; ه
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $44 ; پ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; report 5  Out of screen  =>  صفحه·پر
        DB          $52 ; ص
        DB          $58 ; ف
        DB          $49 ; ح
        DB          $68 ; ه
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $44 ; پ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; report 6  Number too big  =>  عددبزرگ
        DB          $56 ; ع
        DB          $4B ; د
        DB          $4B ; د
        DB          $43 ; ب
        DB          $4E ; ز
        DB          $4D ; ر
        DB          $E1 ; گ  (last byte: bit 7 set = end of message)
; report 7  RETURN without GOSUB  =>  بدون·برو
        DB          $43 ; ب
        DB          $4B ; د
        DB          $66 ; و
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; report 8  End of file  =>  پایان·فایل
        DB          $44 ; پ
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $58 ; ف
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $E3 ; ل  (last byte: bit 7 set = end of message)
; report 9  STOP statement  =>  ایست
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; report 10  Invalid argument  =>  نامعتبر
        DB          $65 ; ن
        DB          $42 ; ا
        DB          $64 ; م
        DB          $56 ; ع
        DB          $45 ; ت
        DB          $43 ; ب
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; report 11  Integer out of range  =>  خارج·ازحد
        DB          $4A ; خ
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $47 ; ج
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $42 ; ا
        DB          $4E ; ز
        DB          $49 ; ح
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; report 12  Nonsense in BASIC  =>  خطاساختاری
        DB          $4A ; خ
        DB          $54 ; ط
        DB          $42 ; ا
        DB          $50 ; س
        DB          $42 ; ا
        DB          $4A ; خ
        DB          $45 ; ت
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; report 13  BREAK - CONT repeats  =>  قطع·شده
        DB          $59 ; ق
        DB          $54 ; ط
        DB          $56 ; ع
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $51 ; ش
        DB          $4B ; د
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; report 14  Out of DATA  =>  بدون·داده
        DB          $43 ; ب
        DB          $4B ; د
        DB          $66 ; و
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $4B ; د
        DB          $42 ; ا
        DB          $4B ; د
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; report 15  Invalid file name  =>  اسم·غلط
        DB          $42 ; ا
        DB          $50 ; س
        DB          $64 ; م
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 16  No room for line  =>  جدیدپر
        DB          $47 ; ج
        DB          $4B ; د
        DB          $69 ; ی
        DB          $4B ; د
        DB          $44 ; پ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; report 17  STOP in INPUT  =>  ایست
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; report 18  FOR without NEXT  =>  بدون·بعدی
        DB          $43 ; ب
        DB          $4B ; د
        DB          $66 ; و
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $43 ; ب
        DB          $56 ; ع
        DB          $4B ; د
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; report 19  Invalid I/O device  =>  دستگاه·غلط
        DB          $4B ; د
        DB          $50 ; س
        DB          $45 ; ت
        DB          $61 ; گ
        DB          $42 ; ا
        DB          $68 ; ه
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 20  Invalid colour  =>  رنگ·غلط
        DB          $4D ; ر
        DB          $65 ; ن
        DB          $61 ; گ
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 21  BREAK into program  =>  توقف
        DB          $45 ; ت
        DB          $66 ; و
        DB          $59 ; ق
        DB          $D8 ; ف  (last byte: bit 7 set = end of message)
; report 22  RAMTOP no good  =>  سقف·رم·غلط
        DB          $50 ; س
        DB          $59 ; ق
        DB          $58 ; ف
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $4D ; ر
        DB          $64 ; م
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 23  Statement lost  =>  دستورغلط
        DB          $4B ; د
        DB          $50 ; س
        DB          $45 ; ت
        DB          $66 ; و
        DB          $4D ; ر
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 24  Invalid stream  =>  جریان·غلط
        DB          $47 ; ج
        DB          $4D ; ر
        DB          $69 ; ی
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 25  FN without DEF  =>  بدون·تعریف
        DB          $43 ; ب
        DB          $4B ; د
        DB          $66 ; و
        DB          $65 ; ن
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $45 ; ت
        DB          $56 ; ع
        DB          $4D ; ر
        DB          $69 ; ی
        DB          $D8 ; ف  (last byte: bit 7 set = end of message)
; report 26  Parameter error  =>  مقدارغلط
        DB          $64 ; م
        DB          $59 ; ق
        DB          $4B ; د
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $57 ; غ
        DB          $63 ; ل
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; report 27  Tape loading error  =>  خطانوار
        DB          $4A ; خ
        DB          $54 ; ط
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $66 ; و
        DB          $42 ; ا
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
