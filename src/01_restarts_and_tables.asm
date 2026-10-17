;;; @file 01_restarts_and_tables.asm
;;; @brief Part 1. RESTART ROUTINES AND TABLES

;*****************************************
;** Part 1. RESTART ROUTINES AND TABLES **
;*****************************************

;   It is always a good idea to anchor, using ORGs, important sections such as
;   the character bitmaps so that they don't move as code is added and removed.

;   Generally most approaches try to maintain main entry points as they are
;   often used by third-party software.

        ORG 0000

;;; @brief THE 'START'
;;;
;;;   At switch on, the Z80 chip is in Interrupt Mode 0.
;;;   The Spectrum uses Interrupt Mode 1.
;;;   This location can also be 'called' to reset the machine.
;;;   Typically with PRINT USR 0.
;;; @jumps START_NEW
START:
        DI                      ; Disable Interrupts.
        XOR     A               ; Signal coming from START.
        LD      DE,$FFFF        ; Set pointer to top of possible physical RAM.
        JP      START_NEW       ; Jump forward to common code at START-NEW.

;;; @brief THE 'ERROR' RESTART
;;;
;;;   The error pointer is made to point to the position of the error to enable
;;;   the editor to highlight the error position if it occurred during syntax
;;;   checking.  It is used at 37 places in the program.  An instruction fetch
;;;   on address $0008 may page in a peripheral ROM such as the Sinclair
;;;   Interface 1 or Disciple Disk Interface.  This was not an original design
;;;   concept and not all errors pass through here.
;;; @jumps ERROR_2
ERROR_1:
        LD      HL,(CH_ADD)      ; Fetch the character address from CH_ADD.
        LD      (X_PTR),HL      ; Copy it to the error pointer X_PTR.
        JR      ERROR_2         ; Forward to continue at ERROR-2.

;;; @brief THE 'PRINT CHARACTER' RESTART
;;;
;;;   The A register holds the code of the character that is to be sent to
;;;   the output stream of the current channel.  The alternate register set is
;;;   used to output a character in the A register so there is no need to
;;;   preserve any of the current main registers (HL, DE, BC).
;;;   This restart is used 21 times.
;;; @jumps PRINT_A_2
PRINT_A:
        JP      PRINT_A_2           ; Jump forward to continue at PRINT-A-2.

; ---

;==========================================================================
; ARABIC-ROM PATCH -- OVERVIEW OF THIS BLOCK ($0013-$0017)
;==========================================================================
;   In the stock 48K ROM, $0013-$0017 are 5 unused "filler" bytes that sit
;   in the gap after the one-instruction RST $10 (PRINT-A) handler and
;   before RST $18 (GET-CHAR). ArabRAM reuses this dead space to hold a
;   tiny wrapper routine, reached only via a patched CALL at $111D (see
;   that address below, normally "CALL TEMPS" in the editor-loop).
;
;   ARAB-TEMPS-HOOK: reset the keyboard-mode flags (via the ARAB-MODE-RESET
;   helper now living at $1391, formerly the start of the English
;   report-message table) and then fall through into the ORIGINAL
;   TEMPS routine at $0D4D via a second small stub at $0025.
;   Net effect: every time the line editor calls TEMPS (i.e. on entry to
;   edit a fresh input line), the K/E/G keyboard-mode flags are also
;   force-reset, presumably so that a half-typed Arabic multi-key
;   sequence from a previous line can't bleed into the next one.
;==========================================================================
;;; @brief Entry point RTL_TEMPS_HOOK (no original comment).
;;; @calls L1391
;;; @calledby L111D
RTL_TEMPS_HOOK:
        CALL    L1391                   ; reset the keyboard-mode flags before falling into TEMPS
        JR      RTL_TEMPS_HOOK_CONT    ; continue at the TEMPS wrapper's second half

;;; @brief THE 'COLLECT CHARACTER' RESTART
;;;
;;;   The contents of the location currently addressed by CH_ADD are fetched.
;;;   A return is made if the value represents a character that has
;;;   relevance to the BASIC parser. Otherwise CH_ADD is incremented and the
;;;   tests repeated. CH_ADD will be addressing somewhere -
;;;   1) in the BASIC program area during line execution.
;;;   2) in workspace if evaluating, for example, a string expression.
;;;   3) in the edit buffer if parsing a direct command or a new BASIC line.
;;;   4) in workspace if accepting input but not that from INPUT LINE.
;;; @calls SKIP_OVER
;;; @jumpedfrom S_LOOP
;;; @fallthrough NEXT_CHAR
GET_CHAR:
        LD      HL,(CH_ADD)      ; fetch the address from CH_ADD.
        LD      A,(HL)          ; use it to pick up current character.

TEST_CHAR:
        CALL    SKIP_OVER       ; routine SKIP-OVER tests if the character is
                                ; relevant.
        RET     NC              ; Return if it is significant.

;;; @brief THE 'COLLECT NEXT CHARACTER' RESTART
;;;
;;;   As the BASIC commands and expressions are interpreted, this routine is
;;;   called repeatedly to step along the line.  It is used 83 times.
;;; @calls CH_ADD_1
;;; @jumps TEMPS
NEXT_CHAR:
        CALL    CH_ADD_1        ; routine CH-ADD+1 fetches the next immediate
                                ; character.
        JR      TEST_CHAR       ; jump back to TEST-CHAR until a valid
                                ; character is found.

; ---

;==========================================================================
; ARAB-TEMPS-HOOK (continued) -- $0025-$0027
;   Second half of the wrapper above: simply chains on to the untouched,
;   original TEMPS routine at $0D4D. This stub lives in the 3 filler
;   bytes between RST $18 and the fixed RST $20 (KEY-INPUT) vector, so the
;   real RST $20 code immediately after it (at $0028, unaffected) is not
;   disturbed.
;==========================================================================
RTL_TEMPS_HOOK_CONT:
        JP      TEMPS           ; chain on to the original TEMPS routine

;;; @brief THE 'CALCULATE' RESTART
;;;
;;;   This restart enters the Spectrum's internal, floating-point, stack-based,
;;;   FORTH-like language.
;;;   It is further used recursively from within the calculator.
;;;   It is used on 77 occasions.
;;; @jumps CALCULATE
FP_CALC:
        JP      CALCULATE       ; jump forward to the CALCULATE routine.

; ---

;==========================================================================
; ARAB-INSTALL-PRINT-HOOK -- $002B-$002F
;   Lives in the filler gap between the RST $28 (CALCULATE) vector and the
;   fixed RST $30 (BC-SPACES) vector. Loads DE with the address of the new
;   Arabic-aware character-output dispatcher (ARAB-PO-FETCH-EXT, $09F4)
;   and falls into ARAB-SET-CURCHL-VECTOR ($005F, below) to install it as
;   the *current channel's* output routine.
;
;   Background: on the real 128K/48K ROM, CURCHL ($5C51) points at a
;   5-byte descriptor for the currently open I/O channel; the first two
;   bytes of that descriptor are the address of the routine PR-ALL/
;   channel output code calls for every character printed on that
;   channel. By overwriting those two bytes on the fly, ArabRAM can swap
;   in a different output routine per keystroke without touching the
;   higher-level PRINT/OUT-CHAR machinery at all -- a classic
;   "self-modifying vector swap" trick, used here as a tiny state
;   machine (see $0A64-$0A8F below, which swaps in one of three
;   different one-shot handlers depending on context, each of which
;   re-installs the normal handler, i.e. calls back into this very
;   routine, once it has consumed its one special byte).
;==========================================================================
;;; @brief Entry point RTL_INSTALL_PRINT_HOOK (no original comment).
;;; @calledby RTL_PO_FETCH_EXT, L1543
RTL_INSTALL_PRINT_HOOK:
        LD      DE,RTL_PO_FETCH_EXT    ; DE = address of the Arabic-aware print dispatcher
        JR      RTL_SET_CURCHL_VECTOR  ; install DE as the current channel's output routine
                                        ; used for the five-byte end-calc literal.

;;; @brief THE 'CREATE BC SPACES' RESTART
;;;
;;;   This restart is used on only 12 occasions to create BC spaces
;;;   between workspace and the calculator stack.
;;; @jumps RESERVE
BC_SPACES:
        PUSH    BC              ; Save number of spaces.
        LD      HL,(WORKSP)      ; Fetch WORKSP.
        PUSH    HL              ; Save address of workspace.
        JP      RESERVE         ; Jump forward to continuation code RESERVE.

;;; @brief THE 'MASKABLE INTERRUPT' ROUTINE
;;;
;;;   This routine increments the Spectrum's three-byte FRAMES counter fifty
;;;   times a second (sixty times a second in the USA ).
;;;   Both this routine and the called KEYBOARD subroutine use the IY register
;;;   to access system variables and flags so a user-written program must
;;;   disable interrupts to make use of the IY register.
;;; @calls KEYBOARD
MASK_INT:
        PUSH    AF              ; Save the registers that will be used but not
        PUSH    HL              ; the IY register unfortunately.
        LD      HL,(FRAMES1)      ; Fetch the first two bytes at FRAMES1.
        INC     HL              ; Increment lowest two bytes of counter.
        LD      (FRAMES1),HL      ; Place back in FRAMES1.
        LD      A,H             ; Test if the result was zero.
        OR      L               ;
        JR      NZ,KEY_INT      ; Forward, if not, to KEY-INT
        INC     (IY+$40)        ; otherwise increment FRAMES3 the third byte.

;   Now save the rest of the main registers and read and decode the keyboard.

KEY_INT:
        PUSH    BC              ; Save the other main registers.
        PUSH    DE              ;

        CALL    KEYBOARD        ; Routine KEYBOARD executes a stage in the
                                ; process of reading a key-press.
        POP     DE              ;
        POP     BC              ; Restore registers.

        POP     HL              ;
        POP     AF              ;

        EI                      ; Enable Interrupts.
        RET                     ; Return.

;;; @brief THE 'ERROR-2' ROUTINE
;;;
;;;   A continuation of the code at 0008.
;;;   The error code is stored and after clearing down stacks, an indirect jump
;;;   is made to MAIN-4, etc. to handle the error.
;;; @jumpedfrom ERROR_1
;;; @fallthrough ERROR_3
ERROR_2:
        POP     HL              ; drop the return address - the location
                                ; after the RST 08H instruction.
        LD      L,(HL)          ; fetch the error code that follows.
                                ; (nice to see this instruction used.)

;;; @brief Note. this entry point is used when out of memory at REPORT-4
;;;
;;;   Note. this entry point is used when out of memory at REPORT-4.
;;;   The L register has been loaded with the report code but X-PTR is not
;;;   updated.
;;; @jumps SET_STK
;;; @jumpedfrom REPORT_4
ERROR_3:
        LD      (IY+$00),L      ; Store it in the system variable ERR_NR.
        LD      SP,(ERR_SP)      ; ERR_SP points to an error handler on the
                                ; machine stack. There may be a hierarchy
                                ; of routines.
                                ; To MAIN-4 initially at base.
                                ; or REPORT-G on line entry.
                                ; or  ED-ERROR when editing.
                                ; or   ED-FULL during ed-enter.
                                ; or  IN-VAR-1 during runtime input etc.

        JP      SET_STK         ; Jump to SET-STK to clear the calculator stack
                                ; and reset MEM to usual place in the systems
                                ; variables area and then indirectly to MAIN-4,
                                ; etc.

; ---

;==========================================================================
; ARAB-SET-CURCHL-VECTOR -- $005F-$0065
;   Generic helper: store DE into the two bytes CURCHL ($5C51) points at,
;   i.e. "make DE the output routine for whatever channel is open right
;   now". Lives in the unused bytes just before the fixed RST $66 (NMI)
;   entry point, so it had to be kept to exactly 7 bytes.
;   Entered either directly (with DE preloaded, e.g. from $002B above or
;   from the small state-machine dispatch at $0A64) or as a shared tail
;   call from several places.
;==========================================================================
RTL_SET_CURCHL_VECTOR:
        LD      HL,(CURCHL)              ; fetch CURCHL, the current channel's descriptor pointer
        LD      (HL),E                  ; store E into the channel's output-routine address (low byte)
        INC     HL                      ; move to the output-routine address high byte
        LD      (HL),D                  ; store D into the channel's output-routine address (high byte)
        RET                             ; return

;;; @brief THE 'NON-MASKABLE INTERRUPT' ROUTINE
;;;
;;;   New
;;;   There is no NMI switch on the standard Spectrum or its peripherals.
;;;   When the NMI line is held low, then no matter what the Z80 was doing at
;;;   the time, it will now execute the code at 66 Hex.
;;;   This Interrupt Service Routine will jump to location zero if the contents
;;;   of the system variable NMIADD are zero or return if the location holds a
;;;   non-zero address.   So attaching a simple switch to the NMI as in the book
;;;   "Spectrum Hardware Manual" causes a reset.  The logic was obviously
;;;   intended to work the other way.  Sinclair Research said that, since they
;;;   had never advertised the NMI, they had no plans to fix the error "until
;;;   the opportunity arose".
;;;
;;;   Note. The location NMIADD was, in fact, later used by Sinclair Research
;;;   to enhance the text channel on the ZX Interface 1.
;;;   On later Amstrad-made Spectrums, and the Brazilian Spectrum, the logic of
;;;   this routine was indeed reversed but not as at first intended.
;;;
;;;   It can be deduced by looking elsewhere in this ROM that the NMIADD system
;;;   variable pointed to NMI_VECT and that this enabled a Warm Restart to be
;;;   performed at any time, even while playing machine code games, or while
;;;   another Spectrum has been allowed to gain control of this one.
;;;
;;;   Software houses would have been able to protect their games from attack by
;;;   placing two zeros in the NMIADD system variable.
RESET:
        PUSH    AF              ; save the
        PUSH    HL              ; registers.
        LD      HL,(NMIADD)      ; fetch the system variable NMIADD.
        LD      A,H             ; test address
        OR      L               ; for zero.

        JR      NZ,NO_RESET     ; skip to NO-RESET if NOT ZERO

        JP      (HL)            ; jump to routine ( i.e. START )
NO_RESET:
        POP     HL              ; restore the
        POP     AF              ; registers.
        RETN                    ; return to previous interrupt state.

;;; @brief THE 'CH ADD + 1' SUBROUTINE
;;;
;;;   This subroutine is called from RST 20, and three times from elsewhere
;;;   to fetch the next immediate character following the current valid character
;;;   address and update the associated system variable.
;;;   The entry point TEMP-PTR1 is used from the SCANNING routine.
;;;   Both TEMP-PTR1 and TEMP-PTR2 are used by the READ command routine.
;;; @calledby NEXT_CHAR, S_QUOTE_S, NXT_DGT_2
;;; @fallthrough TEMP_PTR1
CH_ADD_1:
        LD      HL,(CH_ADD)      ; fetch address from CH_ADD.

;;; @brief Entry point TEMP_PTR1 (no original comment).
;;; @calledby READ_1, S_DECIMAL
;;; @fallthrough TEMP_PTR2
TEMP_PTR1:
        INC     HL              ; increase the character address by one.

;;; @brief Entry point TEMP_PTR2 (no original comment).
;;; @calledby L139E, READ_1
;;; @jumpedfrom L139E
TEMP_PTR2:
        LD      (CH_ADD),HL      ; update CH_ADD with character address.
X007B:
        LD      A,(HL)          ; load character to A from HL.
        RET                     ; and return.

;;; @brief THE 'SKIP OVER' SUBROUTINE
;;;
;;;   This subroutine is called once from RST 18 to skip over white-space and
;;;   other characters irrelevant to the parsing of a BASIC line etc. .
;;;   Initially the A register holds the character to be considered
;;;   and HL holds its address which will not be within quoted text
;;;   when a BASIC line is parsed.
;;;   Although the 'tab' and 'at' characters will not appear in a BASIC line,
;;;   they could be present in a string expression, and in other situations.
;;;   Note. although white-space is usually placed in a program to indent loops
;;;   and make it more readable, it can also be used for the opposite effect and
;;;   spaces may appear in variable names although the parser never sees them.
;;;   It is this routine that helps make the variables 'Anum bEr5 3BUS' and
;;;   'a number 53 bus' appear the same to the parser.
;;; @calledby GET_CHAR
SKIP_OVER:
        CP      $21             ; test if higher than space.
        RET     NC              ; return with carry clear if so.

        CP      $0D             ; carriage return ?
        RET     Z               ; return also with carry clear if so.

                                ; all other characters have no relevance
                                ; to the parser and must be returned with
                                ; carry set.

        CP      $10             ; test if 0-15d
        RET     C               ; return, if so, with carry set.

        CP      $18             ; test if 24-32d
        CCF                     ; complement carry flag.
        RET     C               ; return with carry set if so.

                                ; now leaves 16d-23d

        INC     HL              ; all above have at least one extra character
                                ; to be stepped over.

        CP      $16             ; controls 22d ('at') and 23d ('tab') have two.
        JR      C,SKIPS         ; forward to SKIPS with ink, paper, flash,
                                ; bright, inverse or over controls.
                                ; Note. the high byte of tab is for RS232 only.
                                ; it has no relevance on this machine.

        INC     HL              ; step over the second character of 'at'/'tab'.
SKIPS:
        SCF                     ; set the carry flag
        LD      (CH_ADD),HL      ; update the CH_ADD system variable.
        RET                     ; return with carry set.


;;; @brief THE 'TOKEN' TABLES
;;;
;;;   The tokenized characters 134d (RND) to 255d (COPY) are expanded using
;;;   this table. The last byte of a token is inverted to denote the end of
;;;   the word. The first is an inverted step-over byte.
;;;
;;; ; TKN-TABLE
;;;   ARABIC KEYWORD (TOKEN) TABLE.  Same format as the original English table:
;;;   one word per token $A5-$FF, the LAST character of each word has bit 7 set,
;;;   and the table starts with a dummy inverted byte ('?') so that PO-SEARCH can
;;;   skip entries by counting inverted bytes.  PO-TOKENS reads it from $0095.
;;;
;;;   The words are stored as KEY CODES, exactly as typed on the Arabic keyboard;
;;;   the Arabic ROM's print routine (RTL_GLYPH_SUBSTITUTE, file 06) turns them
;;;   into joined Arabic letters on screen.  The Arabic text in the comments below
;;;   is the CORRECT decoding:
;;; @verbatim
;;;       G ا  H ب  I ة  J ت  K ث  L ج  M ح  N خ  O د  P ذ  Q ر  R ز  S س  T ش
;;;       U ص  V ض  W ط  X ظ  Y ع  Z غ   A ء  B لا  C أ  D ؤ  E إ  F ئ
;;;       a ف  b ق  c ك  d ل  e م  f ن  g ه  h و  i ي  j ى  k ال
;;; @endverbatim
;;;   Plain symbols ($ # < > = space) are printed as they are.  '[' prints as the
;;;   pi glyph and ']' as an 'E' glyph (the exponent marker) - see file 11.
;;;
;;;   Each entry below: token code, English keyword, decoded Arabic, literal gloss.
;;;   The words are shorter than the English ones, which freed the space at the
;;;   end of the table that now holds the Arabic copyright line and the $01FE
;;;   control-code stub (see the end of this table).
TKN_TABLE:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/keywords.asm"
        ELSE
        INCLUDE "lang/arabic/keywords.asm"
        ENDIF
LANG_BOOT_COPYRIGHT_MSG:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/copyright.asm"
        ELSE
        INCLUDE "lang/arabic/copyright.asm"
        ENDIF
        IFDEF   LANG_PERSIAN
        ASSERT  $ <= $0205
        DS      $0205-$, $FF
        ELSE
RTL_FORM_OVERRIDE_ENTRY:
        ADD     A,A
        LD      DE,RTL_FORM_OVERRIDE_OUT ; one-shot output handler for the next character
        JP      L0A7B
        ENDIF

MAIN_KEYS:
        DB          $42             ; B
        DB          $48             ; H
        DB          $59             ; Y
        DB          $36             ; 6
        DB          $35             ; 5
        DB          $54             ; T
        DB          $47             ; G
        DB          $56             ; V
        DB          $4E             ; N
        DB          $4A             ; J
        DB          $55             ; U
        DB          $37             ; 7
        DB          $34             ; 4
        DB          $52             ; R
        DB          $46             ; F
        DB          $43             ; C
        DB          $4D             ; M
        DB          $4B             ; K
        DB          $49             ; I
        DB          $38             ; 8
        DB          $33             ; 3
        DB          $45             ; E
        DB          $44             ; D
        DB          $58             ; X
        DB          $0E             ; SYMBOL SHIFT
        DB          $4C             ; L
        DB          $4F             ; O
        DB          $39             ; 9
        DB          $32             ; 2
        DB          $57             ; W
        DB          $53             ; S
        DB          $5A             ; Z
        DB          $20             ; SPACE
        DB          $0D             ; ENTER
        DB          $50             ; P
        DB          $30             ; 0
        DB          $31             ; 1
        DB          $51             ; Q
        DB          $41             ; A


;;; @brief The 26 unshifted extended mode keys for the alphabetic characters
;;;
;;;  The 26 unshifted extended mode keys for the alphabetic characters.
;;;  The green keywords on the original keyboard.
E_UNSHIFT:
        DB          $E3             ; READ
        DB          $C4             ; BIN
        DB          $E0             ; LPRINT
        DB          $E4             ; DATA
        DB          $B4             ; TAN
        DB          $BC             ; SGN
        DB          $BD             ; ABS
        DB          $BB             ; SQR
        DB          $AF             ; CODE
        DB          $B0             ; VAL
        DB          $B1             ; LEN
        DB          $C0             ; USR
        DB          $A7             ; PI
        DB          $A6             ; INKEY$
        DB          $BE             ; PEEK
        DB          $AD             ; TAB
        DB          $B2             ; SIN
        DB          $BA             ; INT
        DB          $E5             ; RESTORE
        DB          $A5             ; RND
        DB          $C2             ; CHR$
        DB          $E1             ; LLIST
        DB          $B3             ; COS
        DB          $B9             ; EXP
        DB          $C1             ; STR$
        DB          $B8             ; LN


;;; @brief The 26 shifted extended mode keys for the alphabetic characters
;;;
;;;  The 26 shifted extended mode keys for the alphabetic characters.
;;;  The red keywords below keys on the original keyboard.
EXT_SHIFT:
        DB          $7E             ; ~
        DB          $DC             ; BRIGHT
        DB          $DA             ; PAPER
        DB          $5C             ; \
        DB          $B7             ; ATN
        DB          $7B             ; {
        DB          $7D             ; }
        DB          $D8             ; CIRCLE
        DB          $BF             ; IN
        DB          $AE             ; VAL$
        DB          $AA             ; SCREEN$
        DB          $AB             ; ATTR
        DB          $DD             ; INVERSE
        DB          $DE             ; OVER
        DB          $DF             ; OUT
        DB          $7F             ; (Copyright character)
        DB          $B5             ; ASN
        DB          $D6             ; VERIFY
        DB          $7C             ; |
        DB          $D5             ; MERGE
        DB          $3F             ; table data
        DB          $DB             ; FLASH
        DB          $B6             ; ACS
        DB          $D9             ; INK
        DB          $3F             ; table data
        DB          $D7             ; BEEP

;;; @brief The ten control codes assigned to the top line of digits when the shift key is pressed
;;;
;;;  The ten control codes assigned to the top line of digits when the shift
;;;  key is pressed.
CTL_CODES:
        DB          $0C             ; DELETE
        DB          $07             ; EDIT
        DB          $06             ; CAPS LOCK
        DB          $04             ; TRUE VIDEO
        DB          $05             ; INVERSE VIDEO
        DB          $09             ; table data
        DB          $0A             ; CURSOR DOWN
        DB          $0B             ; CURSOR UP
        DB          $08             ; table data
        DB          $0F             ; GRAPHICS

;;; @brief The 26 red symbols assigned to the alphabetic characters of the keyboard
;;;
;;;  The 26 red symbols assigned to the alphabetic characters of the keyboard.
;;;  The ten single-character digit symbols are converted without the aid of
;;;  a table using subtraction and minor manipulation.
SYM_CODES:
        DB          $E2             ; STOP
        DB          $2A             ; *
        DB          $3F             ; ?
        DB          $CD             ; STEP
        DB          $C7             ; table data
        DB          $CC             ; TO
        DB          $CB             ; THEN
        DB          $5E             ; ^
        DB          $AC             ; AT
        DB          $2D             ; -
        DB          $2B             ; +
        DB          $3D             ; =
        DB          $2E             ; .
        DB          $2C             ; ,
        DB          $3B             ; ;
        DB          $22             ; "
        DB          $C8             ; table data
        DB          $3E             ; table data
        DB          $C3             ; NOT
        DB          $3C             ; table data
        DB          $C5             ; OR
        DB          $2F             ; /
        DB          $C9             ; <>
        DB          $60             ; pound
        DB          $C6             ; AND
        DB          $3A             ; :

;;; @brief The ten keywords assigned to the digits in extended mode
;;;
;;;  The ten keywords assigned to the digits in extended mode.
;;;  The remaining red keywords below the keys.
E_DIGITS:
        DB          $D0             ; FORMAT
        DB          $CE             ; DEF FN
        DB          $A8             ; FN
        DB          $CA             ; LINE
        DB          $D3             ; OPEN #
        DB          $D4             ; CLOSE #
        DB          $D1             ; MOVE
        DB          $D2             ; ERASE
        DB          $A9             ; POINT
        DB          $CF             ; CAT
