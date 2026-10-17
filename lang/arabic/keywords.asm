        DB          '?'+$80        ; dummy inverted step-over byte (precedes RND)
; $A5 (165)  RND       عشوا   - random
        DM          "YTh"
        DB          'G'+$80
; $A6 (166)  INKEY$    ياخذم$   - takes key (INKEY$)
        DM          "iGNPe"
        DB          '$'+$80
; $A7 (167)  PI        [   - pi (glyph is the pi symbol)
        DB          '['+$80
; $A8 (168)  FN        حالة   - state/function
        DM          "MGd"
        DB          'I'+$80
; $A9 (169)  POINT     نقطة   - point
        DM          "fbW"
        DB          'I'+$80
; $AA (170)  SCREEN$   شاشة$   - screen$
        DM          "TGTI"
        DB          '$'+$80
; $AB (171)  ATTR      عزا   - attribute
        DM          "YR"
        DB          'G'+$80
; $AC (172)  AT        عند   - at
        DM          "Yf"
        DB          'O'+$80
; $AD (173)  TAB       جدول   - table/tab
        DM          "LOh"
        DB          'd'+$80
; $AE (174)  VAL$      قيم$   - evaluate$
        DM          "bie"
        DB          '$'+$80
; $AF (175)  CODE      شفرة   - code/cipher
        DM          "TaQ"
        DB          'I'+$80
; $B0 (176)  VAL       قيم   - evaluate
        DM          "bi"
        DB          'e'+$80
; $B1 (177)  LEN       طول   - length
        DM          "Wh"
        DB          'd'+$80
; $B2 (178)  SIN       جا   - sine (abbr.)
        DM          "L"
        DB          'G'+$80
; $B3 (179)  COS       جتا   - cosine (abbr.)
        DM          "LJ"
        DB          'G'+$80
; $B4 (180)  TAN       ظل   - tangent (shadow)
        DM          "X"
        DB          'd'+$80
; $B5 (181)  ASN       قوجا   - arc-sine (qaws-jaa)
        DM          "bhL"
        DB          'G'+$80
; $B6 (182)  ACS       قوجتا   - arc-cosine
        DM          "bhLJ"
        DB          'G'+$80
; $B7 (183)  ATN       قوظل   - arc-tangent
        DM          "bhX"
        DB          'd'+$80
; $B8 (184)  LN        لوغ ط   - log + 't' (abbreviation: natural log)
        DM          "dhZ "
        DB          'W'+$80
; $B9 (185)  EXP       اس   - exponent
        DM          "G"
        DB          'S'+$80
; $BA (186)  INT       صحيح   - integer (correct)
        DM          "UMi"
        DB          'M'+$80
; $BB (187)  SQR       جذر   - root
        DM          "LP"
        DB          'Q'+$80
; $BC (188)  SGN       اشارة   - sign/signal
        DM          "GTGQ"
        DB          'I'+$80
; $BD (189)  ABS       مطلق   - absolute
        DM          "eWd"
        DB          'b'+$80
; $BE (190)  PEEK      يجد   - finds
        DM          "iL"
        DB          'O'+$80
; $BF (191)  IN        في   - in
        DM          "a"
        DB          'i'+$80
; $C0 (192)  USR       خاص   - special/user
        DM          "NG"
        DB          'U'+$80
; $C1 (193)  STR$      مجموعة$   - set (string)$
        DM          "eLehYI"
        DB          '$'+$80
; $C2 (194)  CHR$      حرف$   - character$
        DM          "MQa"
        DB          '$'+$80
; $C3 (195)  NOT       لا   - no/not
        DB          'B'+$80
; $C4 (196)  BIN       ثنائي   - binary
        DM          "KfGF"
        DB          'i'+$80
; $C5 (197)  OR        او   - or
        DM          "G"
        DB          'h'+$80
; $C6 (198)  AND       ايضا   - also
        DM          "GiV"
        DB          'G'+$80
; $C7 (199)  <=        <=   - less or equal (plain symbols)
        DM          "<"
        DB          '='+$80
; $C8 (200)  >=        >=   - greater or equal (plain symbols)
        DM          ">"
        DB          '='+$80
; $C9 (201)  <>        <>   - not equal (plain symbols)
        DM          "<"
        DB          '>'+$80
; $CA (202)  LINE      خط   - line
        DM          "N"
        DB          'W'+$80
; $CB (203)  THEN      اذن   - then
        DM          "GP"
        DB          'f'+$80
; $CC (204)  TO        الى   - to
        DM          "Gd"
        DB          'j'+$80
; $CD (205)  STEP      خطوة   - step
        DM          "NWh"
        DB          'I'+$80
; $CE (206)  DEF FN    حاله معرفه   - state defined (function)
        DM          "MGdg eYQa"
        DB          'g'+$80
; $CF (207)  CAT       كتلوج   - catalogue
        DM          "cJdh"
        DB          'L'+$80
; $D0 (208)  FORMAT    تصميم   - design
        DM          "JUei"
        DB          'e'+$80
; $D1 (209)  MOVE      حركه   - movement
        DM          "MQc"
        DB          'g'+$80
; $D2 (210)  ERASE     امسح   - wipe/erase
        DM          "GeS"
        DB          'M'+$80
; $D3 (211)  OPEN #    فتح #   - open #
        DM          "aJM "
        DB          '#'+$80
; $D4 (212)  CLOSE #   اغلق #   - close #
        DM          "GZdb "
        DB          '#'+$80
; $D5 (213)  MERGE     دمج   - merge
        DM          "Oe"
        DB          'L'+$80
; $D6 (214)  VERIFY    تحقق   - verify
        DM          "JMb"
        DB          'b'+$80
; $D7 (215)  BEEP      نغمة   - tone
        DM          "fZe"
        DB          'I'+$80
; $D8 (216)  CIRCLE    دائرة   - circle
        DM          "OGFQ"
        DB          'I'+$80
; $D9 (217)  INK       حبر   - ink
        DM          "MH"
        DB          'Q'+$80
; $DA (218)  PAPER     ورقة   - paper
        DM          "hQb"
        DB          'I'+$80
; $DB (219)  FLASH     ومض   - flash
        DM          "he"
        DB          'V'+$80
; $DC (220)  BRIGHT    لامع   - bright
        DM          "Be"
        DB          'Y'+$80
; $DD (221)  INVERSE   معكوس   - inverted
        DM          "eYch"
        DB          'S'+$80
; $DE (222)  OVER      فوق   - over
        DM          "ah"
        DB          'b'+$80
; $DF (223)  OUT       خارج   - out
        DM          "NGQ"
        DB          'L'+$80
; $E0 (224)  LPRINT    اطبع ط   - print + 't' (abbreviation: printer print)
        DM          "GWHY "
        DB          'W'+$80
; $E1 (225)  LLIST     بيان ط   - list + 't' (abbreviation: printer list)
        DM          "HiGf "
        DB          'W'+$80
; $E2 (226)  STOP      قف   - stop
        DM          "b"
        DB          'a'+$80
; $E3 (227)  READ      اقرأ   - read
        DM          "GbQ"
        DB          'C'+$80
; $E4 (228)  DATA      افادة   - statement/data
        DM          "GaGO"
        DB          'I'+$80
; $E5 (229)  RESTORE   استعاد   - restore
        DM          "GSJYG"
        DB          'O'+$80
; $E6 (230)  NEW       جدد   - renew
        DM          "LO"
        DB          'O'+$80
; $E7 (231)  BORDER    جوانب   - sides/borders
        DM          "LhGf"
        DB          'H'+$80
; $E8 (232)  CONTINUE  تابع   - continue
        DM          "JGH"
        DB          'Y'+$80
; $E9 (233)  DIM       بعد   - dimension
        DM          "HY"
        DB          'O'+$80
; $EA (234)  REM       لاحظ   - note
        DM          "BM"
        DB          'X'+$80
; $EB (235)  FOR       لاجل   - for the sake of
        DM          "BL"
        DB          'd'+$80
; $EC (236)  GO TO     اذهب الى   - go to
        DM          "GPgH Gd"
        DB          'j'+$80
; $ED (237)  GO SUB    اقصد   - go (aim) to
        DM          "GbU"
        DB          'O'+$80
; $EE (238)  INPUT     ادخل   - enter
        DM          "GON"
        DB          'd'+$80
; $EF (239)  LOAD      عبا   - load (fill)
        DM          "YH"
        DB          'G'+$80
; $F0 (240)  LIST      بيان   - statement/list
        DM          "HiG"
        DB          'f'+$80
; $F1 (241)  LET       دع   - let
        DM          "O"
        DB          'Y'+$80
; $F2 (242)  PAUSE     وقف   - pause
        DM          "hb"
        DB          'a'+$80
; $F3 (243)  NEXT      يلي   - follows
        DM          "id"
        DB          'i'+$80
; $F4 (244)  POKE      ضع   - put
        DM          "V"
        DB          'Y'+$80
; $F5 (245)  PRINT     اطبع   - print
        DM          "GWH"
        DB          'Y'+$80
; $F6 (246)  PLOT      رسم   - draw/plot
        DM          "QS"
        DB          'e'+$80
; $F7 (247)  RUN       شغل   - operate/run
        DM          "TZ"
        DB          'd'+$80
; $F8 (248)  SAVE      سجل   - record
        DM          "SL"
        DB          'd'+$80
; $F9 (249)  RANDOMIZE  عشواي   - randomize
        DM          "YThG"
        DB          'i'+$80
; $FA (250)  IF        اذا   - if
        DM          "GP"
        DB          'G'+$80
; $FB (251)  CLS       امح ش   - erase + 'sh' (abbreviation: erase screen)
        DM          "GeM "
        DB          'T'+$80
; $FC (252)  DRAW      يرسم   - draws
        DM          "iQS"
        DB          'e'+$80
; $FD (253)  CLEAR     امح   - erase/clear
        DM          "Ge"
        DB          'M'+$80
; $FE (254)  RETURN    ارجع   - return
        DM          "GQL"
        DB          'Y'+$80
; $FF (255)  COPY      نسخ   - copy
        DM          "fS"
        DB          'N'+$80

; ----------------------------------------------------------------------------
; ARABIC BOOT COPYRIGHT LINE  ($01ED-$01FD).  Replaces the original
; " 1982 Sinclair Research Lt" + 'd' message that used to live at $1539.
; It is one message (last character inverted) printed by START-NEW (file 06)
; with  XOR A / LD DE,$01EC / CALL PO-MSG  at the bottom of the boot screen:
;
;       (c)   اوتورام   كمبيوتر        =  "(c) AutoRAM Computer"
;
; ($7F is the copyright glyph; the text is printed right to left, so the
; (c) sign appears at the right-hand end of the line - bottom row, columns 7-23.)
; ----------------------------------------------------------------------------
