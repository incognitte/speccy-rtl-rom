;;; @file 11_rtl_glyph.asm
;;; @brief ArabRAM additions in formerly unused ROM space ($386E-$3CFF): RTL control codes, editor keys, contextual glyph tables

;==========================================================================
; ARABRAM ADDITIONS IN FORMERLY-UNUSED ROM SPACE -- $386E-$3CFF
;==========================================================================
;   REWRITTEN with corrections verified on real hardware (tape capture of
;   the ROM, SCREEN$ and BASIC program, plus an emulator snapshot). The
;   assembled bytes of this file are IDENTICAL to the original; only
;   comments, annotations and a few internal label names changed.
;   Label names referenced from files 01-10 were NOT renamed.
;
;   This whole region was $FF filler in the original 48K ROM.
;
;   MAP
;   $386E-$3894  RTL_NEW_CTRL_HANDLER (control codes 0-5) and two tiny
;                helpers (L387B, RTL_MODE_TOGGLE)
;   $3895-$3922  RTL_ED_KEY_EXT (editor key front end), the key-decode
;                wrapper L38DA, the key-delivery wrapper L38F3, and
;                RTL_GLYPH_GUARD ($3917)
;   $3923-$39EF  Arabic report-message table (28 messages)
;   $39F0-$3A3F  DIGIT FONT: Arabic-Indic digits, glyph = $3870 + 8*code
;   $3A40-$3A6B  CHARACTER FLAG TABLE for codes $40-$6B (lookup $3A00+code)
;   $3A6C-$3BC3  ISOLATED-FORM FONT: glyph = $3864 + 8*code for codes
;                $41-$6B ('A'..'k'); slots for codes $5B-$60 are not
;                letters and hold CODE (two print hooks, $3B3C-$3B6B)
;   $3BC4-$3CF5  three contextual glyph tables (final / medial / initial)
;   $3CF6-$3CFF  RTL_PRINT_EXTRA_MSG (prints the Arabic boot title logo)
;
;   HOW ARABIC IS PRINTED
;   Keys produce plain ASCII codes internally. PO-CHAR ($0B65, hooked at
;   $0B66) calls RTL_GLYPH_SUBSTITUTE ($145D, file 06) which returns, in
;   BC, a font base so that the normal "BC + 8*code" glyph fetch picks an
;   Arabic bitmap instead of the Latin one. Everything printed (PRINT,
;   LIST, editor, reports, keyword tokens) goes through it. Text prints
;   RIGHT-TO-LEFT. Bit 4 of (IY+1) set = substitution OFF (Latin).
;
;   BASE ADDRESSES RETURNED IN BC
;     digits  '0'-'9'            BC=$3870  -> $39F0-$3A3F
;     isolated letters           BC=$3864  -> $3A6C-$3BC3 (also fallback)
;     joined forms               BC=address of the 8 bitmap bytes inside
;                                one of the three tables below
;     not alphabetic / >= $6C    BC=(CHARS) normal Latin font
;
;   KEY CODE -> ARABIC LETTER (corrected; the old comments used a wrong
;   transliteration table, confirmed wrong by the keyword and message tables
;   decoding to real Arabic words only with this map)
;     G ا  H ب  I ة  J ت  K ث  L ج  M ح  N خ  O د  P ذ  Q ر  R ز
;     S س  T ش  U ص  V ض  W ط  X ظ  Y ع  Z غ
;     A ء  B لا  C أ  D ؤ  E إ  F ئ
;     a ف  b ق  c ك  d ل  e م  f ن  g ه  h و  i ي  j ى  k ال
;   Examples: keyword table decodes REM=BMX=لاحظ, FOR=BLd=لاجل, NOT=B=لا.
;
;   PHYSICAL KEYS (LANG_KEY_LOOKUP_TABLE, file 06): the key pressed is
;   mapped to the code above, e.g. lowercase g->G alif, h->J ta, c->H ba,
;   d->i ya, f->d lam, b->h waw, r->a fa, u->g heh, x->W tah, z->X zah,
;   y->Y ain, t->Z ghain, v->Q ra, w->U sad, q->V dad, s->S sin, a->T shin,
;   i->N kha, o->M hah, p->L jim, l->c kaf, k->e mim, j->f nun, m->O dal,
;   n->P dhal, e->b qaf; uppercase D->A hamza, G->C, H->I, K->B lam-alef,
;   F->k al-, N->R zay, S->F, V->E, W->K tha, X->j, E->"]" (not a letter).
;   Other unmapped keys give "?".
;
;   CONTEXTUAL SHAPING (RTL_GLYPH_SUBSTITUTE, L1510)
;   TV_FLAG $5C3C = (IY+2) context bits:
;     bit 7  the letter being printed joins the NEXT letter
;     bit 2  it does NOT join the next letter
;     bit 1  the PREVIOUS letter joined into this one
;   L1510 is called with A=letter, B=LOOKAHEAD character and sets bits 7/2.
;   Form selected:   bit2 bit1
;                     0    0    INITIAL  -> Table 3  ($3C42)
;                     0    1    MEDIAL   -> Table 2  ($3BFA)
;                     1    0    ISOLATED -> $3864 font
;                     1    1    FINAL    -> Table 1  ($3BC4)
;   A missing form falls back: medial -> initial -> isolated; final ->
;   isolated. Per-letter availability is in the FLAG TABLE:
;     bit 7 set   letter can join forward (needs a following letter)
;     bit 6 set   no INITIAL form        bit 5 set  no MEDIAL form
;     bit 4 clear a FINAL form exists (Table 1 entry)
;   (verified: every flag byte agrees with which tables hold that letter.)
;
;   CONTROL CODES 0-5
;     CHR$ 0-3  FORM OVERRIDE for the NEXT printed character (that character
;               is still printed): 0=initial, 1=medial, 2=isolated, 3=final.
;               Mechanism: $01FE (ADD A,A; LD DE,$154C; JP $0A7B) stores
;               2*code in TVDATA ($5C0E) and installs one-shot handler
;               $154C, which clears TV_FLAG bits 2/1, restores normal
;               output and JPs L387B to OR TVDATA into TV_FLAG.
;     CHR$ 4    Arabic ON : RES 4,(IY+1) and clear context bits 2/1 ($1391)
;     CHR$ 5    Latin  ON : SET 4,(IY+1)
;               The pair CHR$ 5 ... CHR$ 4 brackets a Latin run inside
;               Arabic text. Codes 4/5 occupy no screen cell.
;   The previous letter never joins forward into a control byte (it is
;   not alphabetic), so a form override only affects the letter after it.
;
;   EDITOR KEYS (rewritten key loop, RTL_ED_KEY_EXT)
;     Symbol Shift+SPACE  inserts CHR$ 0, and while the cursor is on a
;                         CHR$ 0-3 byte each further press cycles it
;                         0->1->2->3->0 (so 1,2,3 presses give 0,1,2).
;     Symbol Shift+ENTER  Arabic keyboard: inserts the pair CHR$ 5,CHR$ 4
;                         with the cursor BETWEEN them (type a Latin run);
;                         Latin keyboard: jumps the cursor past the next
;                         CHR$ 4 (or to end of line) to resume Arabic.
;   The keyboard map follows TV_FLAG bit 6 (set = Latin map), refreshed
;   from (IY+1) bit 4 by RTL_MODE_TOGGLE on every cursor redraw.
;
;   KNOWN QUIRKS / OPEN ITEMS
;   * $3B57 lookahead reads the byte AFTER the string when the last
;     character is printed (see RTL_PR_STRING_HOOK), so the final letter
;     of a string variable can join forward if an alphabetic byte follows
;     it in memory. Confirmed on hardware. Left as shipped.
;   * Report 11 text decodes literally to "صحيح ك" (looks abbreviated).
;     Reports 1 and 18 share the same text.
;==========================================================================
;;; @brief Handler for the new control codes 0-5 (Arabic build $386E).
;;;
;;; Entered from RTL_PO_FETCH_EXT with the control code in A.
;;; Codes 0-3 install a one-shot FORM OVERRIDE for the next printed character
;;; (0 initial, 1 medial, 2 isolated, 3 final). Code 4 switches Arabic ON
;;; (substitution on), code 5 switches Latin ON. CHR$ 5 ... CHR$ 4 brackets a
;;; Latin run inside Arabic text. Codes 4/5 occupy no screen cell.
;;; @in A control code 0-5
;;; @jumps L1391
;;; @jumpedfrom RTL_PO_FETCH_EXT
RTL_NEW_CTRL_HANDLER:
        CP      4                       ; control codes 0-5 arrive here from RTL_PO_FETCH_EXT
        JP      C,RTL_FORM_OVERRIDE_ENTRY ; codes 0-3: FORM OVERRIDE (ADD A,A; LD DE,RTL_FORM_OVERRIDE_OUT; JP L0A7B)
        JP      Z,L1391                 ; code 4: Arabic ON ($1391: RES 4,(IY+1) then clear context bits 2,1)
        SET     4,(IY+1)                ; code 5: Latin ON (substitution off)
        RET                             ; return
;;; @brief One-shot handler tail: merge the form override into TV_FLAG (Arabic build $387B).
;;;
;;; Name kept because file 06 refers to it. TVDATA holds 2*override code, so
;;; OR-ing it into TV_FLAG sets bit 1 = code&1 and bit 2 = code>>1. The
;;; character is then printed through RTL_PO_FETCH_EXT with the forced form.
;;; @in A character about to be printed (preserved)
;;; @address $387B
;;; @jumps RTL_PO_FETCH_EXT
;;; @jumpedfrom L1543
L387B:
        LD      HL,TV_FLAG                ; (name kept, used by file 06) one-shot handler tail: HL = TV_FLAG
        PUSH    AF                      ; save the character about to be printed
        LD      A,(TVDATA)               ; A = TVDATA low = 2*override code (0,2,4,6)
        OR      (HL)                    ; merge into TV_FLAG: bit1 = code&1, bit2 = code>>1
        LD      (HL),A                  ; (bits 2/1 were cleared by $154C first)
        POP     AF                      ; restore the character
        JP      RTL_PO_FETCH_EXT       ; print it with the forced form
;;; @brief Refresh TV_FLAG bit 6 (keyboard map) from the substitution state.
;;;
;;; Bit 6 set selects the Latin keyboard map, clear the Arabic one. Called on
;;; every cursor redraw.
;;; @out HL = TV_FLAG
;;; @calledby OUT_CURS
RTL_MODE_TOGGLE:
        LD      HL,TV_FLAG    ; refresh TV_FLAG bit 6 (keyboard map) from substitution state
        SET     6,(HL)                  ; assume Latin keyboard
        BIT     4,(IY+1)                ; substitution off (Latin)?
        RET     NZ                      ; yes: keep bit 6 set
        RES     6,(HL)                  ; no: Arabic keyboard, clear bit 6
        RET                             ; return
;;; @brief Editor key loop front end (replaces the original key wait).
;;;
;;; Waits for a key, clicks the loudspeaker as the original editor did, pushes
;;; the editor loop address so every handler RETurns into the loop, then
;;; dispatches the new keys. Key 5 inserts the pair CHR$ 5, CHR$ 4. Key 4
;;; scans forward for the next CHR$ 4 (or the end of line). Key 0 inserts or
;;; cycles CHR$ 0-3. Anything else goes to the relocated original dispatch.
;;; @see L38F3 for how Symbol Shift + SPACE/ENTER become key codes 0, 4, 5
;;; @calls WAIT_KEY, BEEPER, ADD_CHAR
;;; @jumps ED_CUR
;;; @jumpedfrom L0F38
RTL_ED_KEY_EXT:
        CALL    WAIT_KEY      ; (name kept) editor key loop: wait for a key
        PUSH    AF                      ; keep key code
        LD      E,(IY-1)                ; key-click pitch
        LD      HL,$C8                  ; click duration
        LD      D,H                     ; D = 0
        CALL    BEEPER                  ; click exactly as the original editor did
        POP     AF                      ; key code
        LD      HL,L0F38                ; return address = loop again
        PUSH    HL                      ; so every handler RETurns into the loop
        LD      HL,(K_CUR)              ; HL = K_CUR (byte right of the cursor)
        CP      5                       ; key code 5 = Symbol Shift+ENTER on the Arabic keyboard
        JR      NZ,ED_KEY_4_CHECK       ; not 5
        CALL    ADD_CHAR                ; insert CHR$ 5, cursor advances past it
        DEC     A                       ; A = 4
        JP      L0F41                   ; insert CHR$ 4 to the RIGHT of the cursor (K_CUR unchanged): pair 5..4
ED_KEY_4_CHECK:
        CP      4              ; key code 4 = Symbol Shift+ENTER on the Latin keyboard
        JR      NZ,ED_KEY_0_CHECK       ; not 4
ED_SCAN_FWD:
        LD      A,(HL)            ; scan forward from the cursor
        CP      4                       ; found the closing CHR$ 4?
        JP      Z,L1010                 ; yes: INC HL and set K_CUR (cursor moves just past it)
        CP      13                      ; end of line?
        JP      Z,ED_CUR                ; yes: cursor to the ENTER
        INC     HL                      ; next byte
        JR      ED_SCAN_FWD             ; keep scanning
ED_KEY_0_CHECK:
        OR      A              ; key code 0 = Symbol Shift+SPACE
        JP      NZ,L253C                ; any other key: relocated original key dispatch (file 08)
        LD      A,(HL)                  ; byte right of the cursor
        CP      4                       ; already a CHR$ 0-3?
        JR      NC,ED_INSERT_CODE0      ; no: insert a new CHR$ 0
        INC     A                       ; yes: cycle it 0->1->2->3->0
        AND     3                       ; modulo 4
        LD      (HL),A                  ; store back
        RET                             ; return to the loop
ED_INSERT_CODE0:
        XOR     A             ; A = 0
        JP      L0F41                   ; insert CHR$ 0 right of the cursor (K_CUR unchanged, so the next press cycles it)
;;; @brief Key decode wrapper: mark Symbol Shift + SPACE/ENTER (Arabic build $38DA).
;;;
;;; Name kept because file 02 calls it. Clears FLAGX bit 4, decodes the key
;;; normally and sets bit 4 when the result is SPACE or ENTER and Symbol Shift
;;; (key value $18) was the second key.
;;; @out A decoded key code; FLAGX bit 4 = Symbol Shift + SPACE/ENTER
;;; @address $38DA
;;; @calls K_DECODE
;;; @calledby KEYBOARD
L38DA:
        RES     4,(IY+$37)              ; (name kept, called from file 02) key decode wrapper: clear marker bit (FLAGX bit 4)
        CALL    K_DECODE                ; normal key decode
        CP      $20                     ; SPACE?
        JR      Z,KEYDEC_CHECK_SHIFT    ; yes
        CP      13                      ; ENTER?
        RET     NZ                      ; neither: done
KEYDEC_CHECK_SHIFT:
        LD      C,A        ; keep code
        LD      A,$18                   ; $18 = Symbol Shift key value
        CP      B                       ; was Symbol Shift the second key?
        LD      A,C                     ; restore code
        RET     NZ                      ; no
        SET     4,(IY+$37)              ; yes: mark "Symbol Shift + SPACE/ENTER"
        RET                             ; return
;;; @brief Key delivery wrapper: turn marked SPACE/ENTER into key codes 0, 4 or 5 (Arabic build $38F3).
;;;
;;; Name kept because file 05 jumps to it. When FLAGX bit 4 is set, ENTER
;;; becomes code 4 on the Latin keyboard (TV_FLAG bit 6 set) or 5 on the Arabic
;;; keyboard, and SPACE becomes code 0. Unmarked control codes go to the
;;; original handling at L10C8, everything else to KEY_DONE2.
;;; @in A key code from L38DA
;;; @address $38F3
;;; @jumps KEY_DONE2
;;; @jumpedfrom KEY_INPUT
L38F3:
        BIT     4,(IY+$37)              ; (name kept, jumped to from file 05) deliver the key
        JR      Z,KEYMAP_PLAIN          ; not marked
        CP      13                      ; marked ENTER?
        JR      NZ,KEYMAP_SPACE         ; no
        LD      A,4                     ; Latin keyboard (TV_FLAG bit 6 set): code 4
        BIT     6,(IY+2)                ;
        JR      NZ,KEYMAP_DONE          ;
        INC     A                       ; Arabic keyboard: code 5
        JR      KEYMAP_DONE             ;
KEYMAP_SPACE:
        CP      $20              ; marked SPACE?
        JR      NZ,KEYMAP_PLAIN         ; no
        XOR     A                       ; Symbol Shift+SPACE = key code 0
        JR      KEYMAP_DONE             ;
KEYMAP_PLAIN:
        CP      $20              ; ordinary key
        JP      C,L10C8                 ; control code: original handling
KEYMAP_DONE:
        JP      KEY_DONE2         ; deliver the key
;;; @brief Digit shortcut for RTL_GLYPH_SUBSTITUTE (Arabic build $3917).
;;;
;;; Name kept. If the character is a digit it loads the digit font base into BC
;;; and returns straight out of RTL_GLYPH_SUBSTITUTE (the return address is
;;; dropped with two INC SP). Otherwise it continues through ALPHA to decide
;;; whether the character is a letter.
;;; @in A character code
;;; @out BC digit font base (LANG_DIGIT_FONT - 8*$30) for digits
;;; @calls NUMERIC
;;; @jumps ALPHA
;;; @calledby RTL_GLYPH_SUBSTITUTE
;;; @fallthrough LANG_MSG_TABLE
RTL_GLYPH_GUARD:
        CALL    NUMERIC      ; (name kept) carry CLEAR = digit
        JP      C,ALPHA                 ; not a digit: carry set only if a letter
        LD      BC,LANG_DIGIT_FONT-8*$30 ; digit: font base for the DIGIT FONT (LANG_DIGIT_FONT = glyph of '0')
        INC     SP                      ; drop our return address ...
        INC     SP                      ;
        RET                             ; ... and return straight out of RTL_GLYPH_SUBSTITUTE
;
; ---- Arabic report messages ($3923): 28 messages in report-code order, each
; ---- ending in a character with bit 7 set. Text uses the key codes above.
        IFDEF   LANG_PERSIAN
        ASSERT  $ <= $3923
        IF      $ < $3923
        DS      $3923-$, $FF
        ENDIF
        ASSERT  $ == $3923
        ENDIF
;;; @data
;;; @brief Report message table (Arabic build $3923): 28 messages in report-code order.
;;;
;;; Every message ends with a character that has bit 7 set. Text is stored in
;;; print order (right to left) using the key codes of the font tables. The
;;; content is selected by language: lang/arabic/reports.asm or
;;; lang/persian/reports.asm.
LANG_MSG_TABLE:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/reports.asm"
        ELSE
        INCLUDE "lang/arabic/reports.asm"
        ENDIF
;;; @data
;;; @brief Digit font (Arabic build $39F0-$3A3F): 8 bytes per glyph for CHR$ 48-57.
;;;
;;; The glyph of code c is at LANG_DIGIT_FONT + 8*(c-$30); BC is set to
;;; LANG_DIGIT_FONT - 8*$30 so the normal BC + 8*code fetch finds it.
LANG_DIGIT_FONT:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_digits.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_digits.asm"
        ENDIF
        IFNDEF  LANG_PERSIAN
;;; @data
;;; @brief Character flag table for letter codes (Arabic build $3A40-$3A6B).
;;;
;;; One byte per code, looked up at RTL_GLYPH_FLAG_LOOKUP_BASE + code.
;;; Bit 7: letter can join forward. Bit 6: no INITIAL form. Bit 5: no MEDIAL
;;; form. Bit 4 clear: a FINAL form exists. The glyph-table scan has no
;;; terminator, so the flags must agree exactly with the records. In the
;;; Persian build this table is generated and placed elsewhere.
RTL_GLYPH_FLAG_TABLE:
RTL_GLYPH_FLAG_LOOKUP_BASE EQU RTL_GLYPH_FLAG_TABLE - $40
        INCLUDE "lang/arabic/flags.asm"
        ENDIF
;;; @data
;;; @brief Isolated-form font (Arabic build $3A6C-$3BC3): 8 bytes per code $41-$6B.
;;;
;;; Also the fallback for every missing contextual form. The slots for codes
;;; $5B-$60 are not letters and hold the two print hooks RTL_PO_MSG_HOOK and
;;; RTL_PR_STRING_HOOK ($3B3C-$3B6B, 48 bytes).
LANG_ISOLATED_FONT:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_iso_a.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_iso_a.asm"
        ENDIF
; ---- slots for codes $5B-$60 ('[' '\' ']' '^' '_' '`') are never letters:
; ---- they hold the two print hooks below ($3B3C-$3B6B, 48 bytes).
;;; @brief Hook in the PO-MSG / PO-TOKENS print loop (Arabic build $3B3C).
;;;
;;; Reached by JP from $0C22. For each character it fetches the next byte as
;;; lookahead (bit 7 stripped), lets L1510 set the join context bits and prints
;;; the character with PO_SAVE. The last character of a message is handled by
;;; RTL_PO_MSG_LAST with a space as lookahead.
;;; @in A character (bit 7 set = last of message)
;;; @in HL address of the next character
;;; @calls L1510, PO_SAVE
;;; @jumps RTL_PO_MSG_LAST
;;; @jumpedfrom PO_TOKENS
RTL_PO_MSG_HOOK:
        ; $3B3C: JP from $0C22 (PO-MSG/PO-TOKENS loop). A=char (bit 7 = last char of the message), HL -> next char, Z flag from BIT 7,A
        JR      NZ,RTL_PO_MSG_LAST     ; last character of the message
        LD      B,(HL)                  ; B = LOOKAHEAD = the next character
        RES     7,B                     ; strip the end-of-message bit
        CALL    L1510                   ; set context bits 7/2 from A and the lookahead B
        CALL    PO_SAVE                 ; print A
        JP      L0C23                   ; continue the loop
;;; @brief Last character of a message: print it with a space as lookahead.
;;;
;;; Clears bit 7 of A, loads B = $20, calls L1510 and PO_SAVE, then leaves the
;;; PO-MSG loop at L0C2A.
;;; @in A last character with bit 7 set
;;; @calls L1510, PO_SAVE
;;; @jumpedfrom RTL_PO_MSG_HOOK
RTL_PO_MSG_LAST:
        RES     7,A          ; last char: clear bit 7
        LD      B,$20                   ; lookahead = space (nothing follows)
        CALL    L1510                   ; context bits
        CALL    PO_SAVE                 ; print
        JP      L0C2A                   ; leave the loop
;;; @brief Hook in the PR-STRING loop of PRINT (Arabic build $3B57).
;;;
;;; Reached by JP from $203C. Lookahead B is the byte after the current
;;; character, even past the end of the string, so the last letter of a string
;;; variable can join forward when an alphabetic byte follows it in memory
;;; (confirmed on hardware, left as shipped). The comment at the end of the
;;; routine records an optional untested same-size fix.
;;; @in A current character
;;; @in BC characters remaining after the current one
;;; @in HL address of the current character
;;; @calls L1510
;;; @jumpedfrom PR_ITEM_3
RTL_PR_STRING_HOOK:
        ; $3B57: JP from $203C (PRINT of a string). A=current char, BC=chars remaining AFTER it, HL=current address
        INC     HL                      ; HL -> next character
        PUSH    BC                      ; save the count
        DEC     B                       ; (see QUIRK) does not alter carry
        JR      NC,RTL_PR_NEXT         ; ALWAYS taken: carry is clear from the OR C at $203E
        DEC     C                       ; never executed ...
        LD      B,$20                   ; ... intended fallback: lookahead = space at end of string
        JR      NC,RTL_PR_CTX          ; ... (never executed)
RTL_PR_NEXT:
        LD      B,(HL)           ; B = byte after the current character, EVEN PAST THE END OF THE STRING
RTL_PR_CTX:
        CALL    L1510             ; context bits
        RST     $10                     ; print A
        POP     BC                      ; restore the count
        JP      L203D                   ; next iteration of PR-STRING
        DB          $FF, $FF             ; spare. QUIRK FIX (optional, untested, same size): replace the 21 bytes at
                                         ; RTL_PR_STRING_HOOK with 23 C5 04 05 20 02 0C 0D 46 20 02 06 20 CD 10 15
                                         ; D7 C1 C3 3D 20 (tests BC=0 without touching A; lookahead = $20 at the end)

        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_iso_b.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_iso_b.asm"
        ENDIF
;;; @data
;;; @brief Contextual glyph table 1: FINAL forms (Arabic build $3BC4).
;;;
;;; Records of 1 key byte + 8 bitmap rows. Selected when the previous letter
;;; joined into this one and this one does not join the next (bits 2 and 1 set).
LANG_GLYPH_TABLE_1:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_final.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_final.asm"
        ENDIF
;;; @data
;;; @brief Contextual glyph table 2: MEDIAL forms (Arabic build $3BFA).
;;;
;;; Records of 1 key byte + 8 bitmap rows. Falls back to INITIAL, then ISOLATED,
;;; when a letter has no medial form.
LANG_GLYPH_TABLE_2:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_medial.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_medial.asm"
        ENDIF
;;; @data
;;; @brief Contextual glyph table 3: INITIAL forms (Arabic build $3C42).
;;;
;;; Records of 1 key byte + 8 bitmap rows. Falls back to ISOLATED when a letter
;;; has no initial form.
LANG_GLYPH_TABLE_3:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/glyph_initial.asm"
        ELSE
        INCLUDE "lang/arabic/glyph_initial.asm"
        ENDIF
        IFNDEF  LANG_PERSIAN
;;; @brief Print the Arabic boot title logo (Arabic build $3CF6).
;;;
;;; Clears the screen, then prints message 0 after the step-over byte at
;;; TAPE_MSG_4_END through PO_MSG, which returns to START-NEW. Absent from the
;;; Persian build (exception E-01: no boot title).
;;; @calls CLS
;;; @jumps PO_MSG
;;; @calledby NMI_VECT
RTL_PRINT_EXTRA_MSG:
        CALL    CLS                   ; clear the screen (leaves the lower-screen channel open)
        XOR     A                       ; message number 0 ...
        LD      DE,TAPE_MSG_4_END       ; ... after the step-over byte (end of tape message 4, file 04; boot title follows)
        JP      PO_MSG                   ; print it (PO-MSG returns to START-NEW)
        ENDIF
        