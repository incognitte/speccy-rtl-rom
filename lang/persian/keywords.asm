; ============================================================================
; PERSIAN BASIC KEYWORDS TABLE ($A5-$FF)
; Dummy entry precedes $A5 token (RND) as the step-over byte.
; Stored in RTL print order with bit 7 set on each keyword's last byte.
; ============================================================================
        DB          $BF ; dummy keyword step-over byte (precedes RND)
; $A5 (165)  RND       تصادفی
        DB          $45 ; ت
        DB          $52 ; ص
        DB          $42 ; ا
        DB          $4B ; د
        DB          $58 ; ف
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; $A6 (166)  INKEY$    کلید$
        DB          $5A ; ک
        DB          $63 ; ل
        DB          $69 ; ی
        DB          $4B ; د
        DB          $A4 ; '$'  (last byte: bit 7 set = end of message)
; $A7 (167)  PI        [
        DB          $DB ; '['  (last byte: bit 7 set = end of message)
; $A8 (168)  FN        تابع
        DB          $45 ; ت
        DB          $42 ; ا
        DB          $43 ; ب
        DB          $D6 ; ع  (last byte: bit 7 set = end of message)
; $A9 (169)  POINT     نقطه
        DB          $65 ; ن
        DB          $59 ; ق
        DB          $54 ; ط
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $AA (170)  SCREEN$   متن$
        DB          $64 ; م
        DB          $45 ; ت
        DB          $65 ; ن
        DB          $A4 ; '$'  (last byte: bit 7 set = end of message)
; $AB (171)  ATTR      رنگ
        DB          $4D ; ر
        DB          $65 ; ن
        DB          $E1 ; گ  (last byte: bit 7 set = end of message)
; $AC (172)  AT        در
        DB          $4B ; د
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $AD (173)  TAB       فاصله
        DB          $58 ; ف
        DB          $42 ; ا
        DB          $52 ; ص
        DB          $63 ; ل
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $AE (174)  VAL$      نشانه$
        DB          $65 ; ن
        DB          $51 ; ش
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $68 ; ه
        DB          $A4 ; '$'  (last byte: bit 7 set = end of message)
; $AF (175)  CODE      کد
        DB          $5A ; ک
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $B0 (176)  VAL       عدد
        DB          $56 ; ع
        DB          $4B ; د
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $B1 (177)  LEN       طول
        DB          $54 ; ط
        DB          $66 ; و
        DB          $E3 ; ل  (last byte: bit 7 set = end of message)
; $B2 (178)  SIN       سین
        DB          $50 ; س
        DB          $69 ; ی
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B3 (179)  COS       کسین
        DB          $5A ; ک
        DB          $50 ; س
        DB          $69 ; ی
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B4 (180)  TAN       تان
        DB          $45 ; ت
        DB          $42 ; ا
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B5 (181)  ASN       آسین
        DB          $41 ; آ
        DB          $50 ; س
        DB          $69 ; ی
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B6 (182)  ACS       آرکسین
        DB          $41 ; آ
        DB          $4D ; ر
        DB          $5A ; ک
        DB          $50 ; س
        DB          $69 ; ی
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B7 (183)  ATN       آتان
        DB          $41 ; آ
        DB          $45 ; ت
        DB          $42 ; ا
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $B8 (184)  LN        لگاریتم
        DB          $63 ; ل
        DB          $61 ; گ
        DB          $42 ; ا
        DB          $4D ; ر
        DB          $69 ; ی
        DB          $45 ; ت
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $B9 (185)  EXP       توان
        DB          $45 ; ت
        DB          $66 ; و
        DB          $42 ; ا
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $BA (186)  INT       کف
        DB          $5A ; ک
        DB          $D8 ; ف  (last byte: bit 7 set = end of message)
; $BB (187)  SQR       جذر
        DB          $47 ; ج
        DB          $4C ; ذ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $BC (188)  SGN       علامت
        DB          $56 ; ع
        DB          $62 ; لا
        DB          $64 ; م
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $BD (189)  ABS       مطلق
        DB          $64 ; م
        DB          $54 ; ط
        DB          $63 ; ل
        DB          $D9 ; ق  (last byte: bit 7 set = end of message)
; $BE (190)  PEEK      بیاب
        DB          $43 ; ب
        DB          $69 ; ی
        DB          $42 ; ا
        DB          $C3 ; ب  (last byte: bit 7 set = end of message)
; $BF (191)  IN        ورودی
        DB          $66 ; و
        DB          $4D ; ر
        DB          $66 ; و
        DB          $4B ; د
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; $C0 (192)  USR       اجرا
        DB          $42 ; ا
        DB          $47 ; ج
        DB          $4D ; ر
        DB          $C2 ; ا  (last byte: bit 7 set = end of message)
; $C1 (193)  STR$      رشته$
        DB          $4D ; ر
        DB          $51 ; ش
        DB          $45 ; ت
        DB          $68 ; ه
        DB          $A4 ; '$'  (last byte: bit 7 set = end of message)
; $C2 (194)  CHR$      حرف$
        DB          $49 ; ح
        DB          $4D ; ر
        DB          $58 ; ف
        DB          $A4 ; '$'  (last byte: bit 7 set = end of message)
; $C3 (195)  NOT       نقض
        DB          $65 ; ن
        DB          $59 ; ق
        DB          $D3 ; ض  (last byte: bit 7 set = end of message)
; $C4 (196)  BIN       دودو
        DB          $4B ; د
        DB          $66 ; و
        DB          $4B ; د
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; $C5 (197)  OR        یا
        DB          $69 ; ی
        DB          $C2 ; ا  (last byte: bit 7 set = end of message)
; $C6 (198)  AND       و
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; $C7 (199)  <=        <=
        DB          $3C ; '<'
        DB          $BD ; '='  (last byte: bit 7 set = end of message)
; $C8 (200)  >=        >=
        DB          $3E ; '>'
        DB          $BD ; '='  (last byte: bit 7 set = end of message)
; $C9 (201)  <>        <>
        DB          $3C ; '<'
        DB          $BE ; '>'  (last byte: bit 7 set = end of message)
; $CA (202)  LINE      خط
        DB          $4A ; خ
        DB          $D4 ; ط  (last byte: bit 7 set = end of message)
; $CB (203)  THEN      سپس
        DB          $50 ; س
        DB          $44 ; پ
        DB          $D0 ; س  (last byte: bit 7 set = end of message)
; $CC (204)  TO        تا
        DB          $45 ; ت
        DB          $C2 ; ا  (last byte: bit 7 set = end of message)
; $CD (205)  STEP      گام
        DB          $61 ; گ
        DB          $42 ; ا
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $CE (206)  DEF FN    تعریف
        DB          $45 ; ت
        DB          $56 ; ع
        DB          $4D ; ر
        DB          $69 ; ی
        DB          $D8 ; ف  (last byte: bit 7 set = end of message)
; $CF (207)  CAT       فهرست
        DB          $58 ; ف
        DB          $68 ; ه
        DB          $4D ; ر
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $D0 (208)  FORMAT    فرمت
        DB          $58 ; ف
        DB          $4D ; ر
        DB          $64 ; م
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $D1 (209)  MOVE      جابجا
        DB          $47 ; ج
        DB          $42 ; ا
        DB          $43 ; ب
        DB          $47 ; ج
        DB          $C2 ; ا  (last byte: bit 7 set = end of message)
; $D2 (210)  ERASE     حذف
        DB          $49 ; ح
        DB          $4C ; ذ
        DB          $D8 ; ف  (last byte: bit 7 set = end of message)
; $D3 (211)  OPEN #    باز#
        DB          $43 ; ب
        DB          $42 ; ا
        DB          $4E ; ز
        DB          $A3 ; '#'  (last byte: bit 7 set = end of message)
; $D4 (212)  CLOSE #   بسته#
        DB          $43 ; ب
        DB          $50 ; س
        DB          $45 ; ت
        DB          $68 ; ه
        DB          $A3 ; '#'  (last byte: bit 7 set = end of message)
; $D5 (213)  MERGE     ادغام
        DB          $42 ; ا
        DB          $4B ; د
        DB          $57 ; غ
        DB          $42 ; ا
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $D6 (214)  VERIFY    تایید
        DB          $45 ; ت
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $69 ; ی
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $D7 (215)  BEEP      بوق
        DB          $43 ; ب
        DB          $66 ; و
        DB          $D9 ; ق  (last byte: bit 7 set = end of message)
; $D8 (216)  CIRCLE    دایره
        DB          $4B ; د
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $4D ; ر
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $D9 (217)  INK       قلم
        DB          $59 ; ق
        DB          $63 ; ل
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $DA (218)  PAPER     برگ
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $E1 ; گ  (last byte: bit 7 set = end of message)
; $DB (219)  FLASH     چشمک
        DB          $48 ; چ
        DB          $51 ; ش
        DB          $64 ; م
        DB          $DA ; ک  (last byte: bit 7 set = end of message)
; $DC (220)  BRIGHT    روشن
        DB          $4D ; ر
        DB          $66 ; و
        DB          $51 ; ش
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $DD (221)  INVERSE   معکوس
        DB          $64 ; م
        DB          $56 ; ع
        DB          $5A ; ک
        DB          $66 ; و
        DB          $D0 ; س  (last byte: bit 7 set = end of message)
; $DE (222)  OVER      رو
        DB          $4D ; ر
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; $DF (223)  OUT       خروج
        DB          $4A ; خ
        DB          $4D ; ر
        DB          $66 ; و
        DB          $C7 ; ج  (last byte: bit 7 set = end of message)
; $E0 (224)  LPRINT    چاپگر
        DB          $48 ; چ
        DB          $42 ; ا
        DB          $44 ; پ
        DB          $61 ; گ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $E1 (225)  LLIST     لیست·چ
        DB          $63 ; ل
        DB          $69 ; ی
        DB          $50 ; س
        DB          $45 ; ت
        DB          $00 ; ZWNJ (zero-width non-joiner, takes no cell)
        DB          $C8 ; چ  (last byte: bit 7 set = end of message)
; $E2 (226)  STOP      ایست
        DB          $42 ; ا
        DB          $69 ; ی
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $E3 (227)  READ      بخوان
        DB          $43 ; ب
        DB          $4A ; خ
        DB          $66 ; و
        DB          $42 ; ا
        DB          $E5 ; ن  (last byte: bit 7 set = end of message)
; $E4 (228)  DATA      داده
        DB          $4B ; د
        DB          $42 ; ا
        DB          $4B ; د
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $E5 (229)  RESTORE   نوسازی
        DB          $65 ; ن
        DB          $66 ; و
        DB          $50 ; س
        DB          $42 ; ا
        DB          $4E ; ز
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; $E6 (230)  NEW       نو
        DB          $65 ; ن
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; $E7 (231)  BORDER    قاب
        DB          $59 ; ق
        DB          $42 ; ا
        DB          $C3 ; ب  (last byte: bit 7 set = end of message)
; $E8 (232)  CONTINUE  ادامه
        DB          $42 ; ا
        DB          $4B ; د
        DB          $42 ; ا
        DB          $64 ; م
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $E9 (233)  DIM       بعد
        DB          $43 ; ب
        DB          $56 ; ع
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $EA (234)  REM       یاد
        DB          $69 ; ی
        DB          $42 ; ا
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $EB (235)  FOR       برای
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $42 ; ا
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; $EC (236)  GO TO     برو
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $E6 ; و  (last byte: bit 7 set = end of message)
; $ED (237)  GO SUB    زیر
        DB          $4E ; ز
        DB          $69 ; ی
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $EE (238)  INPUT     ورود
        DB          $66 ; و
        DB          $4D ; ر
        DB          $66 ; و
        DB          $CB ; د  (last byte: bit 7 set = end of message)
; $EF (239)  LOAD      بار
        DB          $43 ; ب
        DB          $42 ; ا
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $F0 (240)  LIST      لیست
        DB          $63 ; ل
        DB          $69 ; ی
        DB          $50 ; س
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $F1 (241)  LET       فرض
        DB          $58 ; ف
        DB          $4D ; ر
        DB          $D3 ; ض  (last byte: bit 7 set = end of message)
; $F2 (242)  PAUSE     مکث
        DB          $64 ; م
        DB          $5A ; ک
        DB          $C6 ; ث  (last byte: bit 7 set = end of message)
; $F3 (243)  NEXT      بعدی
        DB          $43 ; ب
        DB          $56 ; ع
        DB          $4B ; د
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
; $F4 (244)  POKE      ثبت
        DB          $46 ; ث
        DB          $43 ; ب
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $F5 (245)  PRINT     چاپ
        DB          $48 ; چ
        DB          $42 ; ا
        DB          $C4 ; پ  (last byte: bit 7 set = end of message)
; $F6 (246)  PLOT      رسم
        DB          $4D ; ر
        DB          $50 ; س
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $F7 (247)  RUN       اجرا
        DB          $42 ; ا
        DB          $47 ; ج
        DB          $4D ; ر
        DB          $C2 ; ا  (last byte: bit 7 set = end of message)
; $F8 (248)  SAVE      ذخیره
        DB          $4C ; ذ
        DB          $4A ; خ
        DB          $69 ; ی
        DB          $4D ; ر
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $F9 (249)  RANDOMIZE شانس
        DB          $51 ; ش
        DB          $42 ; ا
        DB          $65 ; ن
        DB          $D0 ; س  (last byte: bit 7 set = end of message)
; $FA (250)  IF        اگر
        DB          $42 ; ا
        DB          $61 ; گ
        DB          $CD ; ر  (last byte: bit 7 set = end of message)
; $FB (251)  CLS       پاکساز
        DB          $44 ; پ
        DB          $42 ; ا
        DB          $5A ; ک
        DB          $50 ; س
        DB          $42 ; ا
        DB          $CE ; ز  (last byte: bit 7 set = end of message)
; $FC (252)  DRAW      رسم
        DB          $4D ; ر
        DB          $50 ; س
        DB          $E4 ; م  (last byte: bit 7 set = end of message)
; $FD (253)  CLEAR     تخلیه
        DB          $45 ; ت
        DB          $4A ; خ
        DB          $63 ; ل
        DB          $69 ; ی
        DB          $E8 ; ه  (last byte: bit 7 set = end of message)
; $FE (254)  RETURN    برگشت
        DB          $43 ; ب
        DB          $4D ; ر
        DB          $61 ; گ
        DB          $51 ; ش
        DB          $C5 ; ت  (last byte: bit 7 set = end of message)
; $FF (255)  COPY      کپی
        DB          $5A ; ک
        DB          $44 ; پ
        DB          $E9 ; ی  (last byte: bit 7 set = end of message)
