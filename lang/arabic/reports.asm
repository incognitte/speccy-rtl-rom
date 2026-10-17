        DB          $80              ; start marker
; report 0  OK  =>  جيد
        DM          "Li"
        DB          'O'+$80
; report 1  NEXT without FOR  =>  لا لاجل
        DM          "B BL"
        DB          'd'+$80
; report 2  Variable not found  =>  لا متغير
        DM          "B eJZi"
        DB          'Q'+$80
; report 3  Subscript wrong  =>  صفة خطأ
        DM          "UaI NW"
        DB          'C'+$80
; report 4  Out of memory  =>  لا ذاكرة
        DM          "B PGcQ"
        DB          'I'+$80
; report 5  Out of screen  =>  لا شاشة
        DM          "B TGT"
        DB          'I'+$80
; report 6  Number too big  =>  رقم كبير
        DM          "Qbe cHi"
        DB          'Q'+$80
; report 7  RETURN without GOSUB  =>  لا اذهب
        DM          "B GPg"
        DB          'H'+$80
; report 8  End of file  =>  نهاية ملف
        DM          "fgGiI ed"
        DB          'a'+$80
; report 9  STOP statement  =>  قف
        DM          "b"
        DB          'a'+$80
; report 10  Invalid argument  =>  لا جدال
        DM          "B LOG"
        DB          'd'+$80
; report 11  Integer out of range  =>  صحيح ك
        DM          "UMiM "
        DB          'c'+$80
; report 12  Nonsense in BASIC  =>  لا معنى
        DM          "B eYf"
        DB          'j'+$80
; report 13  BREAK - CONT repeats  =>  مقطع
        DM          "ebW"
        DB          'Y'+$80
; report 14  Out of DATA  =>  من افادة
        DM          "ef GaGO"
        DB          'I'+$80
; report 15  Invalid file name  =>  لا اسم ملف
        DM          "B GSe ed"
        DB          'a'+$80
; report 16  No room for line  =>  لا فرغ لسطر
        DM          "B aQZ dSW"
        DB          'Q'+$80
; report 17  STOP in INPUT  =>  قف
        DM          "b"
        DB          'a'+$80
; report 18  FOR without NEXT  =>  لا لاجل
        DM          "B BL"
        DB          'd'+$80
; report 19  Invalid I/O device  =>  لا ادخال/اخراج
        DM          "B GONGd/GNQG"
        DB          'L'+$80
; report 20  Invalid colour  =>  لا لون
        DM          "B dh"
        DB          'f'+$80
; report 21  BREAK into program  =>  اقطع
        DM          "GbW"
        DB          'Y'+$80
; report 22  RAMTOP no good  =>  رام بوب غير جيد
        DM          "QGe HhH ZiQ Li"
        DB          'O'+$80
; report 23  Statement lost  =>  ضياع امر
        DM          "ViGY Ge"
        DB          'Q'+$80
; report 24  Invalid stream  =>  لا اتصال
        DM          "B GJUG"
        DB          'd'+$80
; report 25  FN without DEF  =>  لا مثل معرفة
        DM          "B eKd eYQa"
        DB          'I'+$80
; report 26  Parameter error  =>  خطأ مقدار
        DM          "NWC ebOG"
        DB          'Q'+$80
; report 27  Tape loading error  =>  خطأ تعبئة
        DM          "NWC JYHF"
        DB          'I'+$80
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF

; ---- DIGIT FONT ($39F0-$3A3F): Arabic-Indic digits. Glyph address = $3870 + 8*code
