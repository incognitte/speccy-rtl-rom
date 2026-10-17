;;; @file 05_screen_and_printer_routines.asm
;;; @brief Part 5. SCREEN AND PRINTER HANDLING ROUTINES

;**************************************************
;** Part 5. SCREEN AND PRINTER HANDLING ROUTINES **
;**************************************************
;;; @brief Printable character(s)
;;;
;;; This routine prints printable characters and continues into
;;; the position store routine
;;; @calls PO_ANY
;;; @fallthrough PO_STORE
PO_ABLE:
        CALL    PO_ANY           ; routine PO-ANY
                                ; and continue into position store routine.

;;; @brief THE 'POSITION STORE' ROUTINE
;;;
;;;   This routine updates the system variables associated with the main screen,
;;;   the lower screen/input buffer or the ZX printer.
;;; @jumpedfrom RTL_PO_FETCH_EXT, CL_SET_1
PO_STORE:
        BIT     1,(IY+$01)      ; Test FLAGS - is printer in use ?
        JR      NZ,PO_ST_PR     ; Forward, if so, to PO-ST-PR

        BIT     0,(IY+$02)      ; Test TV_FLAG - is lower screen in use ?
        JR      NZ,PO_ST_E      ; Forward, if so, to PO-ST-E

;   This section deals with the upper screen.

        LD      (S_POSN),BC      ; Update S_POSN - line/column upper screen
        LD      (DF_CC),HL      ; Update DF_CC - upper display file address

        RET                     ; Return.

; ---

;   This section deals with the lower screen.

PO_ST_E:
        LD      (SPOSNL),BC      ; Update SPOSNL line/column lower screen
        LD      (ECHO_E),BC      ; Update ECHO_E line/column input buffer
        LD      (DFCCL),HL      ; Update DFCCL  lower screen memory address
        RET                     ; Return.

; ---

;   This section deals with the ZX Printer.

PO_ST_PR:
        LD      (IY+$45),C      ; Update P_POSN column position printer
        LD      (PR_CC),HL      ; Update PR_CC - full printer buffer memory
                                ; address
        RET                     ; Return.

;   Note. that any values stored in location 23681 will be overwritten with
;   the value 91 decimal.
;   Credit April 1983, Dilwyn Jones. "Delving Deeper into your ZX Spectrum".

;;; @brief THE 'POSITION FETCH' ROUTINE
;;;
;;;   This routine fetches the line/column and display file address of the upper
;;;   and lower screen or, if the printer is in use, the column position and
;;;   absolute memory address.
;;;   Note. that PR-CC-hi (23681) is used by this routine and if, in accordance
;;;   with the manual (that says this is unused), the location has been used for
;;;   other purposes, then subsequent output to the printer buffer could corrupt
;;;   a 256-byte section of memory.
;;; @jumps PO_F_PR
;;; @calledby RTL_PO_FETCH_EXT, PO_ANY
;;; @jumpedfrom RTL_PO_FETCH_EXT, PO_GR_2
PO_FETCH:
        BIT     1,(IY+$01)      ; Test FLAGS - is printer in use ?
        JR      NZ,PO_F_PR      ; Forward, if so, to PO-F-PR

;   assume upper screen in use and thus optimize for path that requires speed.

        LD      BC,(S_POSN)      ; Fetch line/column from S_POSN
        LD      HL,(DF_CC)      ; Fetch DF_CC display file address

        BIT     0,(IY+$02)      ; Test TV_FLAG - lower screen in use ?
        RET     Z               ; Return if upper screen in use.

;   Overwrite registers with values for lower screen.

        LD      BC,(SPOSNL)      ; Fetch line/column from SPOSNL
        LD      HL,(DFCCL)      ; Fetch display file address from DFCCL
        RET                     ; Return.

; ---

;;; @brief This section deals with the ZX Printer
;;;
;;;   This section deals with the ZX Printer.
;;; @jumpedfrom PO_FETCH
PO_F_PR:
        LD      C,(IY+$45)      ; Fetch column from P_POSN.
        LD      HL,(PR_CC)      ; Fetch printer buffer address from PR_CC.
        RET                     ; Return.

;;; @brief THE 'PRINT ANY CHARACTER' ROUTINE
;;;
;;;   This routine is used to print any character in range 32d - 255d
;;;   It is only called from PO-ABLE which continues into PO-STORE
;;; @calls PO_GR_1, PO_FETCH
;;; @jumps PO_CHAR, PR_ALL
;;; @calledby PO_ABLE
PO_ANY:
        CP      $80             ; ASCII ?
        JR      C,PO_CHAR       ; to PO-CHAR is so.

        CP      $90             ; test if a block graphic character.
        JR      NC,PO_T_UDG     ; to PO-T&UDG to print tokens and UDGs

; The 16 2*2 mosaic characters 128-143 decimal are formed from
; bits 0-3 of the character.

        LD      B,A             ; save character
        CALL    PO_GR_1         ; routine PO-GR-1 to construct top half
                                ; then bottom half.
        CALL    PO_FETCH        ; routine PO-FETCH fetches print position.
        LD      DE,MEM_0        ; MEM-0 is location of 8 bytes of character
        JR      PR_ALL          ; to PR-ALL to print to screen or printer

; ---

;;; @brief Entry point PO_GR_1 (no original comment).
;;; @calls PO_GR_2
;;; @calledby PO_ANY
;;; @fallthrough PO_GR_2
PO_GR_1:
        LD      HL,MEM_0        ; address MEM-0 - a temporary buffer in
                                ; systems variables which is normally used
                                ; by the calculator.
        CALL    PO_GR_2           ; routine PO-GR-2 to construct top half
                                ; and continue into routine to construct
                                ; bottom half.

;;; @brief Entry point PO_GR_2 (no original comment).
;;; @calls PO_TOKENS
;;; @jumps PO_FETCH
;;; @calledby PO_GR_1
PO_GR_2:
        RR      B               ; rotate bit 0/2 to carry
        SBC     A,A             ; result $00 or $FF
        AND     $0F             ; mask off right hand side
        LD      C,A             ; store part in C
        RR      B               ; rotate bit 1/3 of original chr to carry
        SBC     A,A             ; result $00 or $FF
        AND     $F0             ; mask off left hand side
        OR      C               ; combine with stored pattern
        LD      C,$04           ; four bytes for top/bottom half

PO_GR_3:
        LD      (HL),A          ; store bit patterns in temporary buffer
        INC     HL              ; next address
        DEC     C               ; jump back to
        JR      NZ,PO_GR_3      ; to PO-GR-3 until byte is stored 4 times

        RET                     ; return

; ---

; Tokens and User defined graphics are now separated.

PO_T_UDG:
        SUB     $A5            ; the 'RND' character
        JR      NC,PO_T        ; to PO-T to print tokens

        ADD     A,$15           ; add 21d to restore to 0 - 20
        PUSH    BC              ; save current print position
        LD      BC,(UDG)      ; fetch UDG to address bit patterns
        JR      PO_CHAR_2       ; to PO-CHAR-2 - common code to lay down
                                ; a bit patterned character

; ---

PO_T:
        CALL    PO_TOKENS          ; routine PO-TOKENS prints tokens
        JP      PO_FETCH           ; exit via a JUMP to PO-FETCH as this routine
                                ; must continue into PO-STORE.
                                ; A JR instruction could be used.

; This point is used to print ASCII characters  32d - 127d.

;;; @brief Entry point PO_CHAR (no original comment).
;;; @calls RTL_GLYPH_SUBSTITUTE
;;; @calledby RTL_PO_FETCH_EXT
;;; @jumpedfrom PO_ANY
;;; @fallthrough PR_ALL
PO_CHAR:
        PUSH    BC              ; save print position
;==========================================================================
; Hook into the character-bitmap lookup -- $0B66
;   The original single instruction "LD BC,(CHARS)" (fetch the CHARS
;   system variable, base of the font bitmap table) is replaced by
;   "CALL $145D", a new routine (in the free-space area, documented in
;   full at its definition near $145D further down this file) which:
;     1. still fetches CHARS into BC as before (so normal characters are
;        completely unaffected), but
;     2. first checks whether the character now being drawn is one of a
;        specific set of Latin keyboard letters (G,H,I,J,K,L,M,N,S,T,U,
;        V,Y,Z,a,b,c,d,e,f,g -- see the three 9-byte-record tables at
;        $3BC4/$3BFA/$3C42), and if so substitutes a completely custom
;        8x8 pixel bitmap for that key instead of the standard font
;        glyph.
;   CONFIRMED ON REAL HARDWARE (owner ran a test .TAP and photographed
;   the ArabRAM screen): this is how Arabic LETTERS are drawn, and the
;   letter part of the trace below is fully verified against a real
;   keyboard overlay. The physical keys keep producing ordinary ASCII
;   codes internally (so the rest of BASIC/ROM logic -- variable names,
;   keywords, syntax -- is completely untouched), but at the very last
;   moment, just before a bitmap address is computed for the screen,
;   the routine at $145D looks the character up in one of three
;   9-byte-keyed tables ($3BC4/$3BFA/$3C42) and substitutes a custom
;   8x8 Arabic-letter bitmap instead of the Latin glyph, for letters
;   A-Z/a-z that have a table entry. Because this lives inside PO-CHAR,
;   the universal low-level character printing routine, the
;   substitution applies everywhere a character is drawn -- PRINT
;   statements, LIST, and line-editor keystroke echo alike -- not just
;   live typing. See the full key/letter cross-reference table at the
;   $386E free-space block below.
;
;   CORRECTION / OPEN ITEM: an earlier pass of this analysis (based on
;   tracing the NUMERIC/ALPHA carry-flag convention alone) predicted
;   that DIGIT characters ('0'-'9') would be excluded from any
;   substitution and print as plain Western numerals. A real-hardware
;   photo disproves this: digits are clearly rendered as Persian/
;   Arabic-Indic numeral shapes (a distinctive V/checkmark for 7, a
;   small hollow circle for 5, a looped tail for 9, a stepped shape for
;   3 were all directly observed). The NUMERIC-carry trace at $3917
;   itself re-checked correct on the raw bytes (CALL $2D1B; JP C,$2C8D;
;   LD BC,$3870; INC SP; INC SP; RET), so the digit path genuinely does
;   take the "INC SP:INC SP:RET" double-return escape rather than
;   falling into the table lookup at $146A onward. The most likely
;   explanation is that this double-return does NOT simply abort the
;   substitution (as first assumed) but instead unwinds to a SEPARATE,
;   not-yet-located digit-glyph routine elsewhere in the ROM that
;   installs the Persian-digit bitmaps by a different path. This has
;   not been isolated yet -- flagged as an open item rather than guessed
;   at further.
;==========================================================================
        CALL    RTL_GLYPH_SUBSTITUTE   ; call RTL_GLYPH_SUBSTITUTE
        NOP                             ; no operation

; This common code is used to transfer the character bytes to memory.

PO_CHAR_2:
        EX      DE,HL           ; transfer destination address to DE
        LD      HL,FLAGS        ; point to FLAGS
        RES     0,(HL)          ; allow for leading space
        CP      $20             ; is it a space ?
        JR      NZ,PO_CHAR_3    ; to PO-CHAR-3 if not

        SET     0,(HL)          ; signal no leading space to FLAGS

PO_CHAR_3:
        LD      H,$00           ; set high byte to 0
        LD      L,A             ; character to A
                                ; 0-21 UDG or 32-127 ASCII.
        ADD     HL,HL           ; multiply
        ADD     HL,HL           ; by
        ADD     HL,HL           ; eight
        ADD     HL,BC           ; HL now points to first byte of character
        POP     BC              ; the source address CHARS or UDG
        EX      DE,HL           ; character address to DE

;;; @brief THE 'PRINT ALL CHARACTERS' ROUTINE
;;;
;;;   This entry point entered from above to print ASCII and UDGs but also from
;;;   earlier to print mosaic characters.
;;;   HL=destination
;;;   DE=character source
;;;   BC=line/column
;;; @calls COPY_BUFF, PO_SCR, PO_ATTR
;;; @jumpedfrom PO_ANY
PR_ALL:
        LD      A,C             ; column to A
        DEC     A               ; move right
        LD      A,$21           ; pre-load with leftmost position
        JR      NZ,PR_ALL_1     ; but if not zero to PR-ALL-1

        DEC     B               ; down one line
        LD      C,A             ; load C with $21
        BIT     1,(IY+$01)      ; test FLAGS  - Is printer in use
        JR      Z,PR_ALL_1      ; to PR-ALL-1 if not

        PUSH    DE              ; save source address
        CALL    COPY_BUFF       ; routine COPY-BUFF outputs line to printer
        POP     DE              ; restore character source address
        LD      A,C             ; the new column number ($21) to C

PR_ALL_1:
        CP      C               ; this test is really for screen - new line ?
        PUSH    DE              ; save source

        CALL    Z,PO_SCR         ; routine PO-SCR considers scrolling

        POP     DE              ; restore source
        PUSH    BC              ; save line/column
        PUSH    HL              ; and destination
        LD      A,(P_FLAG)       ; fetch P_FLAG to accumulator
        LD      B,$FF           ; prepare OVER mask in B.
        RRA                     ; bit 0 set if OVER 1
        JR      C,PR_ALL_2      ; to PR-ALL-2

        INC     B               ; set OVER mask to 0

PR_ALL_2:
        RRA                     ; skip bit 1 of P_FLAG
        RRA                     ; bit 2 is INVERSE
        SBC     A,A             ; will be FF for INVERSE 1 else zero
        LD      C,A             ; transfer INVERSE mask to C
        LD      A,$08           ; prepare to count 8 bytes
        AND     A               ; clear carry to signal screen
        BIT     1,(IY+$01)      ; test FLAGS  - is printer in use ?
        JR      Z,PR_ALL_3      ; to PR-ALL-3 if screen

        SET     1,(IY+$30)      ; update FLAGS2  - signal printer buffer has
                                ; been used.
        SCF                     ; set carry flag to signal printer.

PR_ALL_3:
        EX      DE,HL           ; now HL=source, DE=destination

PR_ALL_4:
        EX      AF,AF'          ; save printer/screen flag
        LD      A,(DE)          ; fetch existing destination byte
        AND     B               ; consider OVER
        XOR     (HL)            ; now XOR with source
        XOR     C               ; now with INVERSE MASK
        LD      (DE),A          ; update screen/printer
        EX      AF,AF'          ; restore flag
        JR      C,PR_ALL_6      ; to PR-ALL-6 - printer address update

        INC     D               ; gives next pixel line down screen

PR_ALL_5:
        INC     HL              ; address next character byte
        DEC     A               ; the byte count is decremented
        JR      NZ,PR_ALL_4     ; back to PR-ALL-4 for all 8 bytes

        EX      DE,HL           ; destination to HL
        DEC     H               ; bring back to last updated screen position
        BIT     1,(IY+$01)      ; test FLAGS  - is printer in use ?
        CALL    Z,PO_ATTR       ; if not, call routine PO-ATTR to update
                                ; corresponding colour attribute.
        POP     HL              ; restore original screen/printer position
        POP     BC              ; and line column
        DEC     C               ; move column to right
        DEC     HL              ; HL = HL - 1
        RET                     ; return and continue into PO-STORE
                                ; within PO-ABLE

; ---

;   This branch is used to update the printer position by 32 places
;   Note. The high byte of the address D remains constant (which it should).

PR_ALL_6:
        EX      AF,AF'          ; save the flag
        LD      A,$20           ; load A with 32 decimal
        ADD     A,E             ; add this to E
        LD      E,A             ; and store result in E
        EX      AF,AF'          ; fetch the flag
        JR      PR_ALL_5        ; back to PR-ALL-5

;;; @brief THE 'GET ATTRIBUTE ADDRESS' ROUTINE
;;;
;;;   This routine is entered with the HL register holding the last screen
;;;   address to be updated by PRINT or PLOT.
;;;   The Spectrum screen arrangement leads to the L register holding the correct
;;;   value for the attribute file and it is only necessary to manipulate H to
;;;   form the correct colour attribute address.
;;; @calledby PR_ALL
;;; @jumpedfrom PLOT_END
PO_ATTR:
        LD       A,H            ; fetch high byte $40 - $57
        RRCA                    ; shift
        RRCA                    ; bits 3 and 4
        RRCA                    ; to right.
        AND     $03             ; range is now 0 - 2
        OR      $58             ; form correct high byte for third of screen
        LD      H,A             ; HL is now correct
        LD      DE,(ATTR_T)      ; make D hold ATTR_T, E hold MASK-T
        LD      A,(HL)          ; fetch existing attribute
        XOR     E               ; apply masks
        AND     D               ;
        XOR     E               ;
        BIT     6,(IY+$57)      ; test P_FLAG  - is this PAPER 9 ??
        JR      Z,PO_ATTR_1     ; skip to PO-ATTR-1 if not.

        AND     $C7             ; set paper
        BIT     2,A             ; to contrast with ink
        JR      NZ,PO_ATTR_1    ; skip to PO-ATTR-1

        XOR     $38             ;

PO_ATTR_1:
        BIT     4,(IY+$57)      ; test P_FLAG  - Is this INK 9 ??
        JR      Z,PO_ATTR_2     ; skip to PO-ATTR-2 if not

        AND     $F8             ; make ink
        BIT     5,A             ; contrast with paper.
        JR      NZ,PO_ATTR_2    ; to PO-ATTR-2

        XOR     $07             ;

PO_ATTR_2:
        LD      (HL),A          ; save the new attribute.
        RET                     ; return.

;;; @brief THE 'MESSAGE PRINTING' SUBROUTINE
;;;
;;;   This entry point is used to print tape, boot-up, scroll? and error messages.
;;;   On entry the DE register points to an initial step-over byte or the
;;;   inverted end-marker of the previous entry in the table.
;;;   Register A contains the message number, often zero to print first message.
;;;   (HL has nothing important usually P_FLAG)
;;; @calledby REPORT_FA, SA_CONTRL, PO_SCR, NMI_VECT, MAIN_EXEC
;;; @jumpedfrom RTL_PRINT_EXTRA_MSG
PO_MSG:
        PUSH    HL              ; put hi-byte zero on stack to suppress
        LD      H,$00           ; trailing spaces
        EX      (SP),HL         ; ld h,0; push hl would have done ?.
        JR      PO_TABLE        ; forward to PO-TABLE.

; ---

;   This entry point prints the BASIC keywords, '<>' etc. from alt set

;;; @brief Entry point PO_TOKENS (no original comment).
;;; @calls PO_SEARCH, PO_SAVE
;;; @jumps RTL_PO_MSG_HOOK
;;; @calledby PO_GR_2
;;; @fallthrough PO_SAVE
PO_TOKENS:
        LD      DE,TKN_TABLE    ; address: TKN-TABLE
        PUSH    AF              ; save the token number to control
                                ; trailing spaces - see later *

; ->

PO_TABLE:
        CALL    PO_SEARCH       ; routine PO-SEARCH will set carry for
                                ; all messages and function words.

        JR      C,PO_EACH         ; forward to PO-EACH if not a command, '<>' etc.

        LD      A,$20           ; prepare leading space
        BIT     0,(IY+$01)      ; test FLAGS  - leading space if not set

        CALL    Z,PO_SAVE       ; routine PO-SAVE to print a space without
                                ; disturbing registers.

                                ; set of registers.
                                ; (this also doubles character)

PO_EACH:
        EX      DE,HL                   ; swap DE and HL
L0C23:
        LD      A,(HL)                  ; A = (HL)
        INC     HL                      ; HL = HL + 1
        BIT     7,A                     ; test bit 7 of A
        JP      RTL_PO_MSG_HOOK        ; jump to the Arabic PO-MSG hook (file 11)
L0C2A:
        DEC     HL                      ; HL = HL - 1
        LD      A,(HL)                  ; A = (HL)
        EX      DE,HL                   ; swap DE and HL

        POP     DE              ; * re-fetch trailing space byte to D

        CP      $A4                ; compare A with $A4
        JR      Z,PO_TR_SP         ; forward to PO-TR-SP to consider trailing
                                ; space if so.

        CP      $C1                     ; compare A with $C1
                                ; or ' ','.' (from tape) or '?' from scroll

        RET     C               ; Return if so as no trailing space required.

PO_TR_SP:
        LD      A,D             ; The trailing space flag (zero if an error msg)

        CP      $03             ; Test against RND, INKEY$ and PI which have no
                                ; parameters and therefore no trailing space.

        RET     C               ; Return if no trailing space.

        LD      A,$20           ; Prepare the space character and continue to
                                ; print and make an indirect return.

;;; @brief THE 'RECURSIVE PRINTING' SUBROUTINE
;;;
;;;   This routine which is part of PRINT-OUT allows RST $10 to be used
;;;   recursively to print tokens and the spaces associated with them.
;;;   It is called on three occasions when the value of DE must be preserved.
;;; @calledby RTL_PO_FETCH_EXT, PO_TOKENS, RTL_PO_MSG_HOOK, RTL_PO_MSG_LAST
PO_SAVE:
        PUSH    DE              ; Save DE value.
        EXX                     ; Switch in main set

        RST     10H             ; PRINT-A prints using this alternate set.

        EXX                     ; Switch back to this alternate set.
        POP     DE              ; Restore the initial DE value.

        RET                     ; Return.

;;; @brief Table search
;;;
;;; This subroutine searches a message or the token table for the
;;; message number held in A. DE holds the address of the table.
;;; @calledby PO_TOKENS
PO_SEARCH:
        PUSH    AF              ; save the message/token number
        EX      DE,HL           ; transfer DE to HL
        INC     A               ; adjust for initial step-over byte

PO_STEP:
        BIT     7,(HL)          ; is character inverted ?
        INC     HL              ; address next
        JR      Z,PO_STEP       ; back to PO-STEP if not inverted.

        DEC     A               ; decrease counter
        JR      NZ,PO_STEP      ; back to PO-STEP if not zero

        EX      DE,HL           ; transfer address to DE
        POP     AF              ; restore message/token number
        CP      $20             ; return with carry set
        RET     C               ; for all messages and function tokens

        LD      A,(DE)          ; test first character of token
        SUB     $41             ; and return with carry set
        RET                     ; if it is less that 'A'
                                ; i.e. '<>', '<=', '>='

;;; @brief Test for scroll
;;;
;;; This test routine is called when printing carriage return, when considering
;;; PRINT AT and from the general PRINT ALL characters routine to test if
;;; scrolling is required, prompting the user if necessary.
;;; This is therefore using the alternate set.
;;; The B register holds the current line.
;;; @calls CHAN_OPEN, PO_MSG, WAIT_KEY, CL_SC_ALL, CL_ADDR
;;; @calledby RTL_PO_FETCH_EXT, PR_ALL
;;; @jumpedfrom RTL_PO_FETCH_EXT
PO_SCR:
        BIT     1,(IY+$01)      ; test FLAGS  - is printer in use ?
        RET     NZ              ; return immediately if so.

        LD      DE,CL_SET       ; set DE to address: CL-SET
        PUSH    DE              ; and push for return address.

        LD      A,B             ; transfer the line to A.
        BIT     0,(IY+$02)      ; test TV_FLAG - lower screen in use ?
        JP      NZ,PO_SCR_4     ; jump forward to PO-SCR-4 if so.

        CP      (IY+$31)        ; greater than DF_SZ display file size ?
        JR      C,REPORT_5      ; forward to REPORT-5 if less.
                                ; 'Out of screen'

        RET     NZ              ; return (via CL-SET) if greater

        BIT     4,(IY+$02)      ; test TV_FLAG  - Automatic listing ?
        JR      Z,PO_SCR_2      ; forward to PO-SCR-2 if not.

        LD      E,(IY+$2D)      ; fetch BREG - the count of scroll lines to E.
        DEC     E               ; decrease and jump
        JR      Z,PO_SCR_3      ; to PO-SCR-3 if zero and scrolling required.

        LD      A,$00           ; explicit - select channel zero.
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens it.

        LD      SP,(LIST_SP)      ; set stack pointer to LIST_SP

        RES     4,(IY+$02)      ; reset TV_FLAG  - signal auto listing finished.
        RET                     ; return ignoring pushed value, CL-SET
                                ; to MAIN or EDITOR without updating
                                ; print position                         >>

; ---

REPORT_5:
        RST     08H             ; ERROR-1
        DB          $04         ; Error Report: Out of screen

; continue here if not an automatic listing.

PO_SCR_2:
        DEC     (IY+$52)        ; decrease SCR_CT
        JR      NZ,PO_SCR_3     ; forward to PO-SCR-3 to scroll display if
                                ; result not zero.

; now produce prompt.

        LD      A,$18           ; reset
        SUB     B               ; the
        LD      (SCR_CT),A       ; SCR_CT scroll count
        LD      HL,(ATTR_T)      ; L=ATTR_T, H=MASK_T
        PUSH    HL              ; save on stack
        LD      A,(P_FLAG)       ; P_FLAG
        PUSH    AF              ; save on stack to prevent lower screen
                                ; attributes (BORDCR etc.) being applied.
        LD      A,$FD           ; select system channel 'K'
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens it
        XOR     A               ; clear to address message directly
        LD      DE,SCRL_MSSG    ; make DE address: scrl-mssg
        CALL    PO_MSG          ; routine PO-MSG prints to lower screen
        SET     5,(IY+$02)      ; set TV_FLAG  - signal lower screen requires
                                ; clearing
        LD      HL,FLAGS        ; make HL address FLAGS
        SET     3,(HL)          ; signal 'L' mode.
        RES     5,(HL)          ; signal 'no new key'.
        EXX                     ; switch to main set.
                                ; as calling chr input from alternative set.
        CALL    WAIT_KEY           ; routine WAIT-KEY waits for new key
                                ; Note. this is the right routine but the
                                ; stream in use is unsatisfactory. From the
                                ; choices available, it is however the best.

        EXX                     ; switch back to alternate set.
        CP      $20             ; space is considered as BREAK
        JR      Z,REPORT_D      ; forward to REPORT-D if so
                                ; 'BREAK - CONT repeats'

        CP      $E2             ; is character 'STOP' ?
        JR      Z,REPORT_D      ; forward to REPORT-D if so

        OR      $20             ; convert to lower-case
        CP      $6E             ; is character 'n' ?
        JR      Z,REPORT_D      ; forward to REPORT-D if so else scroll.

        LD      A,$FE           ; select system channel 'S'
        CALL    CHAN_OPEN       ; routine CHAN-OPEN
        POP     AF              ; restore original P_FLAG
        LD      (P_FLAG),A       ; and save in P_FLAG.
        POP     HL              ; restore original ATTR_T, MASK_T
        LD      (ATTR_T),HL      ; and reset ATTR_T, MASK-T as 'scroll?' has
                                ; been printed.

PO_SCR_3:
        CALL    CL_SC_ALL       ; routine CL-SC-ALL to scroll whole display
        LD      B,(IY+$31)      ; fetch DF_SZ to B
        INC     B               ; increase to address last line of display
        LD      C,$21           ; set C to $21 (was $21 from above routine)
        PUSH    BC              ; save the line and column in BC.

        CALL    CL_ADDR           ; routine CL-ADDR finds display address.

        LD      A,H             ; now find the corresponding attribute byte
        RRCA                    ; (this code sequence is used twice
        RRCA                    ; elsewhere and is a candidate for
        RRCA                    ; a subroutine.)
        AND     $03             ;
        OR      $58             ;
        LD      H,A             ;

        LD      DE,$5AE0        ; start of last 'line' of attribute area
        LD      A,(DE)          ; get attribute for last line
        LD      C,(HL)          ; transfer to base line of upper part
        LD      B,$20           ; there are thirty two bytes
        EX      DE,HL           ; swap the pointers.

PO_SCR_3A:
        LD      (DE),A          ; transfer
        LD      (HL),C          ; attributes.
        INC     DE              ; address next.
        INC     HL              ; address next.
        DJNZ    PO_SCR_3A       ; loop back to PO-SCR-3A for all adjacent
                                ; attribute lines.

        POP     BC              ; restore the line/column.
        RET                     ; return via CL-SET (was pushed on stack).

; ---

; The message 'scroll?' appears here with last byte inverted.

;;; @brief Deciphered
;;;
;;; Deciphered: the message is "رفع؟" (key codes "QaY" + '?'):
;;;   'Q' = ر (ra), 'a' = ف (fa), 'Y' = ع (ain)  ->  "رفع" ("raise / lift [the screen up]")
;;;   followed by a plain Latin '?'.
;;; The original English text was "scroll?" (7 bytes: "scroll" + '?'+$80).  The Arabic
;;; patch overwrote the first 5 bytes with  $04 'Q' 'a' 'Y' '?'+$80  and the last two bytes
;;; of the English message ('l', '?'+$80) were left behind.  PO-MSG stops at the FIRST byte
;;; with bit 7 set, so those last two bytes are DEAD, never printed.
;;; @calls TEMPS, CL_SCROLL, CL_SET
SCRL_MSSG:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/scroll_msg.asm"
        ELSE
        INCLUDE "lang/arabic/scroll_msg.asm"
        ENDIF
REPORT_D:
        RST     08H             ; ERROR-1
        DB          $0C         ; Error Report: BREAK - CONT repeats

; continue here if using lower display - A holds line number.

PO_SCR_4:
        CP      $02             ; is line number less than 2 ?
        JR      C,REPORT_5      ; to REPORT-5 if so
                                ; 'Out of Screen'.

        ADD     A,(IY+$31)      ; add DF_SZ
        SUB     $19             ;
        RET     NC              ; return if scrolling unnecessary

        NEG                     ; Negate to give number of scrolls required.
        PUSH    BC              ; save line/column
        LD      B,A             ; count to B
        LD      HL,(ATTR_T)      ; fetch current ATTR_T, MASK_T to HL.
        PUSH    HL              ; and save
        LD      HL,(P_FLAG)      ; fetch P_FLAG
        PUSH    HL              ; and save.
                                ; to prevent corruption by input AT

        CALL    TEMPS           ; routine TEMPS sets to BORDCR etc
        LD      A,B             ; transfer scroll number to A.

PO_SCR_4A:
        PUSH    AF              ; save scroll number.
        LD      HL,DF_SZ        ; address DF_SZ
        LD      B,(HL)          ; fetch old value
        LD      A,B             ; transfer to A
        INC     A               ; and increment
        LD      (HL),A          ; then put back.
        LD      HL,S_POSN_hi        ; address S_POSN_hi - line
        CP      (HL)            ; compare
        JR      C,PO_SCR_4B     ; forward to PO-SCR-4B if scrolling required

        INC     (HL)            ; else increment S_POSN_hi
        LD      B,$18           ; set count to whole display ??
                                ; Note. should be $17 and the top line will be
                                ; scrolled into the ROM which is harmless on
                                ; the standard set up.
                                ; credit P.Giblin 1984.

PO_SCR_4B:
        CALL    CL_SCROLL       ; routine CL-SCROLL scrolls B lines
        POP     AF              ; restore scroll counter.
        DEC     A               ; decrease
        JR      NZ,PO_SCR_4A    ; back to PO-SCR-4A until done

        POP     HL              ; restore original P_FLAG.
        LD      (IY+$57),L      ; and overwrite system variable P_FLAG.

        POP     HL              ; restore original ATTR_T/MASK_T.
        LD      (ATTR_T),HL      ; and update system variables.

        LD      BC,(S_POSN)      ; fetch S_POSN to BC.
        RES     0,(IY+$02)      ; signal to TV_FLAG  - main screen in use.
        CALL    CL_SET          ; call routine CL-SET for upper display.

        SET     0,(IY+$02)      ; signal to TV_FLAG  - lower screen in use.
        POP     BC              ; restore line/column
        RET                     ; return via CL-SET for lower display.

;;; @brief Temporary colour items
;;;
;;; This subroutine is called 11 times to copy the permanent colour items
;;; to the temporary ones.
;;; @calledby SCRL_MSSG, CLS_LOWER, CL_ALL, L111D, CLASS_07, CLASS_09, PRINT_1
;;; @jumpedfrom NEXT_CHAR, CHAN_S_1, PLOT, LINE_DRAW
TEMPS:
        XOR     A               ; clear the accumulator
        LD      HL,(ATTR_P)      ; fetch L=ATTR_P and H=MASK_P
        BIT     0,(IY+$02)      ; test TV_FLAG  - is lower screen in use ?
        JR      Z,TEMPS_1       ; skip to TEMPS-1 if not

        LD      H,A             ; set H, MASK P, to 00000000.
        LD      L,(IY+$0E)      ; fetch BORDCR to L which is used for lower
                                ; screen.

TEMPS_1:
        LD      (ATTR_T),HL      ; transfer values to ATTR_T and MASK_T

; for the print flag the permanent values are odd bits, temporary even bits.

        LD      HL,P_FLAG        ; address P_FLAG.
        JR      NZ,TEMPS_2      ; skip to TEMPS-2 if lower screen using A=0.

        LD      A,(HL)          ; else pick up flag bits.
        RRCA                    ; rotate permanent bits to temporary bits.

TEMPS_2:
        XOR     (HL)            ;
        AND     $55             ; BIN 01010101
        XOR     (HL)            ; permanent now as original
        LD      (HL),A          ; apply permanent bits to temporary bits.
        RET                     ; and return.

;;; @brief THE 'CLS' COMMAND
;;;
;;; @verbatim
;;;    This command clears the display.
;;;    The routine is also called during initialization and by the CLEAR command.
;;;    If it's difficult to write it should be difficult to read.
;;; @endverbatim
;;; @calls CL_ALL
;;; @calledby NMI_VECT, CLEAR_1, RTL_PRINT_EXTRA_MSG
;;; @fallthrough CLS_LOWER
CLS:
        CALL    CL_ALL           ; Routine CL-ALL clears the entire display and
                                ; sets the attributes to the permanent ones
                                ; from ATTR-P.

;   Having cleared all 24 lines of the display area, continue into the
;   subroutine that clears the lower display area.  Note that at the moment
;   the attributes for the lower lines are the same as upper ones and have
;   to be changed to match the BORDER colour.

;;; @brief THE 'CLS-LOWER' SUBROUTINE
;;;
;;;   This routine is called from INPUT, and from the MAIN execution loop.
;;;   This is very much a housekeeping routine which clears between 2 and 23
;;;   lines of the display, setting attributes and correcting situations where
;;;   errors have occurred while the normal input and output routines have been
;;;   temporarily diverted to deal with, say colour control codes.
;;; @calls TEMPS, CL_LINE
;;; @jumps CLS_3
;;; @calledby KEY_INPUT, MAIN_EXEC, INPUT
;;; @jumpedfrom INPUT_2
;;; @fallthrough CLS_3
CLS_LOWER:
        LD      HL,TV_FLAG        ; address System Variable TV_FLAG.
        RES     5,(HL)          ; TV_FLAG - signal do not clear lower screen.
        SET     0,(HL)          ; TV_FLAG - signal lower screen in use.

        CALL    TEMPS           ; routine TEMPS applies permanent attributes,
                                ; in this case BORDCR to ATTR_T.
                                ; Note. this seems unnecessary and is repeated
                                ; within CL-LINE.

        LD      B,(IY+$31)      ; fetch lower screen display file size DF_SZ

        CALL    CL_LINE           ; routine CL-LINE clears lines to bottom of the
                                ; display and sets attributes from BORDCR while
                                ; preserving the B register.

        LD      HL,$5AC0        ; set initial attribute address to the leftmost
                                ; cell of second line up.

        LD      A,(ATTR_P)       ; fetch permanent attribute from ATTR_P.

        DEC     B               ; decrement lower screen display file size.

        JR      CLS_3           ; forward to enter the backfill loop at CLS-3
                                ; where B is decremented again.

; ---

;   The backfill loop is entered at midpoint and ensures, if more than 2
;   lines have been cleared, that any other lines take the permanent screen
;   attributes.

CLS_1:
        LD      C,$20           ; set counter to 32 character cells per line

CLS_2:
        DEC     HL              ; decrease attribute address.
        LD      (HL),A          ; and place attributes in next line up.
        DEC     C               ; decrease the 32 counter.
        JR      NZ,CLS_2        ; loop back to CLS-2 until all 32 cells done.

;;; @brief ; CLS-3
;;;
;;; ; CLS-3
;;; @jumpedfrom CLS_LOWER
;;; @fallthrough CL_CHAN
CLS_3:
        DJNZ    CLS_1           ; decrease B counter and back to CLS-1
                                ; if not zero.

        LD      (IY+$31),$02    ; now set DF_SZ lower screen to 2

; This entry point is also called from CL-ALL below to
; reset the system channel input and output addresses to normal.

;;; @brief ; CL-CHAN
;;;
;;; ; CL-CHAN
;;; @calls CHAN_OPEN
;;; @calledby CL_ALL
;;; @fallthrough CL_CHAN_A
CL_CHAN:
        LD      A,$FD           ; select system channel 'K'

        CALL    CHAN_OPEN           ; routine CHAN-OPEN opens it.

        LD      HL,(CURCHL)      ; fetch CURCHL to HL to address current channel
        LD      DE,RTL_PO_FETCH_EXT ; set address to PRINT-OUT for first pass.
        AND     A               ; clear carry for first pass.

;;; @brief ; CL-CHAN-A
;;;
;;; ; CL-CHAN-A
;;; @jumps CL_SET
CL_CHAN_A:
        LD      (HL),E          ; Insert the output address on the first pass
        INC     HL              ; or the input address on the second pass.
        LD      (HL),D          ;
        INC     HL              ;

        LD      DE,KEY_INPUT    ; fetch address KEY-INPUT for second pass
        CCF                     ; complement carry flag - will set on pass 1.

        JR      C,CL_CHAN_A         ; back to CL-CHAN-A if first pass else done.

        LD      BC,$1721        ; line 23 for lower screen
        JR      CL_SET          ; exit via CL-SET to set column
                                ; for lower display

;;; @brief Clearing whole display area
;;;
;;; This subroutine called from CLS, AUTO-LIST and MAIN-3
;;; clears 24 lines of the display and resets the relevant system variables.
;;; This routine also recovers from an error situation where, for instance, an
;;; invalid colour or position control code has left the output routine addressing
;;; PO-TV-2 or PO-CONT.
;;;
;;; ; CL-ALL
;;; @calls CL_CHAN, CHAN_OPEN, TEMPS, CL_LINE
;;; @calledby CLS, MAIN_EXEC, AUTO_LIST
;;; @fallthrough CL_SET
CL_ALL:
        LD      HL,$0000        ; Initialize plot coordinates.
        LD      (COORDS),HL      ; Set system variable COORDS to 0,0.

        RES     0,(IY+$30)      ; update FLAGS2  - signal main screen is clear.

        CALL    CL_CHAN           ; routine CL-CHAN makes channel 'K' 'normal'.

        LD      A,$FE           ; select system channel 'S'
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens it.

        CALL    TEMPS           ; routine TEMPS applies permanent attributes,
                                ; in this case ATTR_P, to ATTR_T.
                                ; Note. this seems unnecessary.

        LD      B,$18           ; There are 24 lines.

        CALL    CL_LINE           ; routine CL-LINE clears 24 text lines and sets
                                ; attributes from ATTR-P.
                                ; This routine preserves B and sets C to $21.

        LD      HL,(CURCHL)      ; fetch CURCHL make HL address output routine.

        LD      DE,RTL_PO_FETCH_EXT ; address: PRINT-OUT
        LD      (HL),E          ; is made
        INC     HL              ; the normal
        LD      (HL),D          ; output address.

        LD      (IY+$52),$01    ; set SCR_CT - scroll count - to default.

;   Note. BC already contains $1821.

        LD      BC,$1821        ; reset column and line to 0,0
                                ; and continue into CL-SET, below, exiting
                                ; via PO-STORE (for the upper screen).

;;; @brief THE 'CL-SET' ROUTINE
;;;
;;; This important subroutine is used to calculate the character output
;;; address for screens or printer based on the line/column for screens
;;; or the column for printer.
;;;
;;; ; CL-SET
;;; @jumps CL_SET_1
;;; @calledby SCRL_MSSG, ED_C_END, INPUT_2, IN_VAR_4
;;; @jumpedfrom RTL_PO_FETCH_EXT, CL_CHAN_A, PRB_BYTES
;;; @fallthrough CL_SET_1
CL_SET:
        LD      HL,SWAP        ; the base address of printer buffer
        BIT     1,(IY+$01)      ; test FLAGS  - is printer in use ?
        JR      NZ,L0DF4        ; forward to CL-SET-2 if so.

        LD      A,B             ; transfer line to A.
        BIT     0,(IY+$02)      ; test TV_FLAG  - lower screen in use ?
        JR      Z,CL_SET_1      ; skip to CL-SET-1 if handling upper part

        ADD     A,(IY+$31)      ; add DF_SZ for lower screen
        SUB     $18             ; and adjust.

;;; @brief ; CL-SET-1
;;;
;;; ; CL-SET-1
;;; @calls CL_ADDR
;;; @jumps PO_STORE
;;; @jumpedfrom CL_SET
CL_SET_1:
        PUSH    BC              ; save the line/column.
        LD      B,A             ; transfer line to B
                                ; (adjusted if lower screen)

        CALL    CL_ADDR           ; routine CL-ADDR calculates address at left
                                ; of screen.
        POP     BC              ; restore the line/column.

;; CL-SET-2
;==========================================================================
; *** RIGHT-TO-LEFT CURSOR/COLUMN FORMULA CHANGE *** -- $0DF4-$0DF6
;==========================================================================
;   This is one of the most significant single changes in the whole
;   patch, despite being only 3 bytes.
;
;   Original CL-SET code:      LD A,$21   ; A = 33
;                               SUB C      ; A = 33 - column
;   Patched code:               LD A,C     ; A = column
;                               DEC A      ; A = column - 1
;                               DEC A      ; A = column - 2
;
;   Context: C holds the current column from S_POSN/PPC (the stock ROM
;   stores on-screen column position "backwards", counting down from 33
;   at the left edge to 1 at the right edge, which is what lets PRINT
;   naturally advance left-to-right on screen while the column number
;   itself decreases). The original formula "33 - C" converts that
;   internal countdown value into a left-to-right pixel-column offset
;   for the display file address calculation that follows.
;
;   The patched formula "C - 2" is a DIFFERENT linear mapping from column
;   number to screen offset. Combined with the ROM being described (per
;   external sources on ArabRAM/Egyptian-Arabic Spectrum ROMs) as making
;   "the entire BASIC ... written from right to left", the most likely
;   explanation is that this ROM has redefined the column-counting
;   convention itself (e.g. counting 1..32 left-to-right normally, but
;   printing characters into descending screen addresses / decrementing
;   positions), so that text visibly flows from the right edge of the
;   screen towards the left as successive characters are printed -- the
;   correct behaviour for Arabic. This is a strong, well-evidenced
;   hypothesis but has NOT been confirmed by tracing every caller of
;   PO-STORE/CL-SET in this pass; treat the exact direction convention
;   as inferred, not verified on real hardware.
;==========================================================================
L0DF4:
        LD      A,C             ; A = C
        DEC     A               ; A = A - 1
        DEC     A               ; A = A - 1
        LD      E,A             ; now transfer to DE
        LD      D,$00           ; prepare for addition
        ADD     HL,DE           ; and add to base address

        JP      PO_STORE           ; exit via PO-STORE to update the relevant
                                ; system variables.
;;; @brief Handle scrolling
;;;
;;; The routine CL-SC-ALL is called once from PO to scroll all the display
;;; and from the routine CL-SCROLL, once, to scroll part of the display.
;;; @calledby PO_SCR
;;; @fallthrough CL_SCROLL
CL_SC_ALL:
        LD      B,$17           ; scroll 23 lines, after 'scroll?'.

;;; @brief Entry point CL_SCROLL (no original comment).
;;; @calls CL_ADDR, CL_ATTR
;;; @calledby SCRL_MSSG
;;; @fallthrough CL_LINE
CL_SCROLL:
        CALL    CL_ADDR         ; routine CL-ADDR gets screen address in HL.
        LD      C,$08           ; there are 8 pixel lines to scroll.

CL_SCR_1:
        PUSH    BC              ; save counters.
        PUSH    HL              ; and initial address.
        LD      A,B             ; get line count.
        AND     $07             ; will set zero if all third to be scrolled.
        LD      A,B             ; re-fetch the line count.
        JR      NZ,CL_SCR_3     ; forward to CL-SCR-3 if partial scroll.

; HL points to top line of third and must be copied to bottom of previous 3rd.
; ( so HL = $4800 or $5000 ) ( but also sometimes $4000 )

CL_SCR_2:
        EX      DE,HL           ; copy HL to DE.
        LD      HL,$F8E0        ; subtract $08 from H and add $E0 to L -
        ADD     HL,DE           ; to make destination bottom line of previous
                                ; third.
        EX      DE,HL           ; restore the source and destination.
        LD      BC,$0020        ; thirty-two bytes are to be copied.
        DEC     A               ; decrement the line count.
        LDIR                    ; copy a pixel line to previous third.

CL_SCR_3:
        EX      DE,HL           ; save source in DE.
        LD      HL,$FFE0        ; load the value -32.
        ADD     HL,DE           ; add to form destination in HL.
        EX      DE,HL           ; switch source and destination
        LD      B,A             ; save the count in B.
        AND     $07             ; mask to find count applicable to current
        RRCA                    ; third and
        RRCA                    ; multiply by
        RRCA                    ; thirty two (same as 5 RLCAs)

        LD      C,A             ; transfer byte count to C ($E0 at most)
        LD      A,B             ; store line count to A
        LD      B,$00           ; make B zero
        LDIR                    ; copy bytes (BC=0, H incremented, L=0)
        LD      B,$07           ; set B to 7, C is zero.
        ADD     HL,BC           ; add 7 to H to address next third.
        AND     $F8             ; has last third been done ?
        JR      NZ,CL_SCR_2     ; back to CL-SCR-2 if not.

        POP     HL              ; restore topmost address.
        INC     H               ; next pixel line down.
        POP     BC              ; restore counts.
        DEC     C               ; reduce pixel line count.
        JR      NZ,CL_SCR_1     ; back to CL-SCR-1 if all eight not done.

        CALL    CL_ATTR           ; routine CL-ATTR gets address in attributes
                                ; from current 'ninth line', count in BC.

        LD      HL,$FFE0        ; set HL to the 16-bit value -32.
        ADD     HL,DE           ; and add to form destination address.
        EX      DE,HL           ; swap source and destination addresses.
        LDIR                    ; copy bytes scrolling the linear attributes.
        LD      B,$01           ; continue to clear the bottom line.

;;; @brief THE 'CLEAR TEXT LINES' ROUTINE
;;;
;;; This subroutine, called from CL-ALL, CLS-LOWER and AUTO-LIST and above,
;;; clears text lines at bottom of display.
;;; The B register holds on entry the number of lines to be cleared 1-24.
;;; @calls CL_ADDR, CL_ATTR
;;; @calledby CLS_LOWER, CL_ALL, AUTO_LIST
CL_LINE:
        PUSH    BC              ; save line count
        CALL    CL_ADDR         ; routine CL-ADDR gets top address
        LD      C,$08           ; there are eight screen lines to a text line.
CL_LINE_1:
        PUSH    BC              ; save pixel line count
        PUSH    HL              ; and save the address
        LD      A,B             ; transfer the line to A (1-24).
CL_LINE_2:
        AND     $07             ; mask 0-7 to consider thirds at a time
        RRCA                    ; multiply
        RRCA                    ; by 32  (same as five RLCA instructions)
        RRCA                    ; now 32 - 256(0)
        LD      C,A             ; store result in C
        LD      A,B             ; save line in A (1-24)
        LD      B,$00           ; set high byte to 0, prepare for ldir.
        DEC     C               ; decrement count 31-255.
        LD      D,H             ; copy HL
        LD      E,L             ; to DE.
        LD      (HL),$00        ; blank the first byte.
        INC     DE              ; make DE point to next byte.
        LDIR                    ; ldir will clear lines.
        LD      DE,$0701        ; now address next third adjusting
        ADD     HL,DE           ; register E to address left hand side
        DEC     A               ; decrease the line count.
        AND     $F8             ; will be 16, 8 or 0  (AND $18 will do).
        LD      B,A             ; transfer count to B.
        JR      NZ,CL_LINE_2    ; back to CL-LINE-2 if 16 or 8 to do
                                ; the next third.

        POP     HL              ; restore start address.
        INC     H               ; address next line down.
        POP     BC              ; fetch counts.
        DEC     C               ; decrement pixel line count
        JR      NZ,CL_LINE_1    ; back to CL-LINE-1 till all done.

        CALL    CL_ATTR           ; routine CL-ATTR gets attribute address
                                ; in DE and B * 32 in BC.

        LD      H,D             ; transfer the address
        LD      L,E             ; to HL.

        INC     DE              ; make DE point to next location.

        LD      A,(ATTR_P)       ; fetch ATTR_P - permanent attributes
        BIT     0,(IY+$02)      ; test TV_FLAG  - lower screen in use ?
        JR      Z,CL_LINE_3     ; skip to CL-LINE-3 if not.

        LD      A,(BORDCR)       ; else lower screen uses BORDCR as attribute.

CL_LINE_3:
        LD      (HL),A          ; put attribute in first byte.
        DEC     BC              ; decrement the counter.
        LDIR                    ; copy bytes to set all attributes.
        POP     BC              ; restore the line $01-$24.
        LD      C,$21           ; make column $21. (No use is made of this)
        RET                     ; return to the calling routine.

;;; @brief Attribute handling
;;;
;;; This subroutine is called from CL-LINE or CL-SCROLL with the HL register
;;; pointing to the 'ninth' line and H needs to be decremented before or after
;;; the division. Had it been done first then either present code or that used
;;; at the start of PO-ATTR could have been used.
;;; The Spectrum screen arrangement leads to the L register already holding
;;; the correct value for the attribute file and it is only necessary
;;; to manipulate H to form the correct colour attribute address.
;;; @calledby CL_SCROLL, CL_LINE
CL_ATTR:
        LD      A,H             ; fetch H to A - $48, $50, or $58.
        RRCA                    ; divide by
        RRCA                    ; eight.
        RRCA                    ; $09, $0A or $0B.
        DEC     A               ; $08, $09 or $0A.
        OR      $50             ; $58, $59 or $5A.
        LD      H,A             ; save high byte of attributes.

        EX      DE,HL           ; transfer attribute address to DE
        LD      H,C             ; set H to zero - from last LDIR.
        LD      L,B             ; load L with the line from B.
        ADD     HL,HL           ; multiply
        ADD     HL,HL           ; by
        ADD     HL,HL           ; thirty two
        ADD     HL,HL           ; to give count of attribute
        ADD     HL,HL           ; cells to the end of display.

        LD      B,H             ; transfer the result
        LD      C,L             ; to register BC.

        RET                     ; return.

;;; @brief Handle display with line number
;;;
;;; This subroutine is called from four places to calculate the address
;;; of the start of a screen character line which is supplied in B.
;;; @calledby PO_SCR, CL_SET_1, CL_SCROLL, CL_LINE
CL_ADDR:
        LD      A,$18           ; reverse the line number
        SUB     B               ; to range $00 - $17.
        LD      D,A             ; save line in D for later.
        RRCA                    ; multiply
        RRCA                    ; by
        RRCA                    ; thirty-two.

        AND     $E0             ; mask off low bits to make
        LD      L,A             ; L a multiple of 32.

        LD      A,D             ; bring back the line to A.

        AND     $18             ; now $00, $08 or $10.

        OR      $40             ; add the base address of screen.

        LD      H,A             ; HL now has the correct address.
        RET                     ; return.

;;; @brief Handle COPY command
;;;
;;; This command copies the top 176 lines to the ZX Printer
;;; It is popular to call this from machine code at point
;;; L0EAF with B holding 192 (and interrupts disabled) for a full-screen
;;; copy. This particularly applies to 16K Spectrums as time-critical
;;; machine code routines cannot be written in the first 16K of RAM as
;;; it is shared with the ULA which has precedence over the Z80 chip.
;;; @calls COPY_LINE
;;; @jumps COPY_END
COPY:
        DI                      ; disable interrupts as this is time-critical.

        LD      B,$B0           ; top 176 lines.
L0EAF:
        LD      HL,$4000        ; address start of the display file.

; now enter a loop to handle each pixel line.

COPY_1:
        PUSH    HL              ; save the screen address.
        PUSH    BC              ; and the line counter.

        CALL    COPY_LINE           ; routine COPY-LINE outputs one line.

        POP     BC              ; restore the line counter.
        POP     HL              ; and display address.
        INC     H               ; next line down screen within 'thirds'.
        LD      A,H             ; high byte to A.
        AND     $07             ; result will be zero if we have left third.
        JR      NZ,COPY_2       ; forward to COPY-2 if not to continue loop.

        LD      A,L             ; consider low byte first.
        ADD     A,$20           ; increase by 32 - sets carry if back to zero.
        LD      L,A             ; will be next group of 8.
        CCF                     ; complement - carry set if more lines in
                                ; the previous third.
        SBC     A,A             ; will be FF, if more, else 00.
        AND     $F8             ; will be F8 (-8) or 00.
        ADD     A,H             ; that is subtract 8, if more to do in third.
        LD      H,A             ; and reset address.

COPY_2:
        DJNZ    COPY_1           ; back to COPY-1 for all lines.

        JR      COPY_END           ; forward to COPY-END to switch off the printer
                                ; motor and enable interrupts.
                                ; Note. Nothing else is required.

;;; @brief Pass printer buffer to printer
;;;
;;; This routine is used to copy 8 text lines from the printer buffer
;;; to the ZX Printer. These text lines are mapped linearly so HL does
;;; not need to be adjusted at the end of each line.
;;; @calledby PR_ALL, MAIN_EXEC
;;; @jumpedfrom RTL_PO_FETCH_EXT
;;; @fallthrough COPY_3
COPY_BUFF:
        DI                      ; disable interrupts
        LD      HL,SWAP        ; the base address of the Printer Buffer.
        LD      B,$08           ; set count to 8 lines of 32 bytes.

;;; @brief ; COPY-3
;;;
;;; ; COPY-3
;;; @calls COPY_LINE
;;; @fallthrough COPY_END
COPY_3:
        PUSH    BC              ; save counter.

        CALL    COPY_LINE           ; routine COPY-LINE outputs 32 bytes

        POP     BC              ; restore counter.
        DJNZ    COPY_3          ; loop back to COPY-3 for all 8 lines.
                                ; then stop motor and clear buffer.

; Note. the COPY command rejoins here, essentially to execute the next
; three instructions.

;;; @brief ; COPY-END
;;;
;;; ; COPY-END
;;; @jumpedfrom COPY
;;; @fallthrough CLEAR_PRB
COPY_END:
        LD      A,$04           ; output value 4 to port
        OUT     ($FB),A         ; to stop the slowed printer motor.
        EI                      ; enable interrupts.

;;; @brief Clear Printer Buffer
;;;
;;; This routine clears an arbitrary 256 bytes of memory.
;;; Note. The routine seems designed to clear a buffer that follows the
;;; system variables.
;;; The routine should check a flag or HL address and simply return if COPY
;;; is in use.
;;; As a consequence of this omission the buffer will needlessly
;;; be cleared when COPY is used and the screen/printer position may be set to
;;; the start of the buffer and the line number to 0 (B)
;;; giving an 'Out of Screen' error.
;;; There seems to have been an unsuccessful attempt to circumvent the use
;;; of PR_CC_hi.
;;;
;;; ; CLEAR-PRB
;;; @calledby COPY_L_1, NMI_VECT
;;; @fallthrough PRB_BYTES
CLEAR_PRB:
        LD      HL,SWAP        ; the location of the buffer.
        LD      (IY+$46),L      ; update PR_CC_lo - set to zero - superfluous.
        XOR     A               ; clear the accumulator.
        LD      B,A             ; set count to 256 bytes.

;;; @brief ; PRB-BYTES
;;;
;;; ; PRB-BYTES
;;; @jumps CL_SET
PRB_BYTES:
        LD      (HL),A          ; set addressed location to zero.
        INC     HL              ; address next byte - Note. not INC L.
        DJNZ    PRB_BYTES       ; back to PRB-BYTES. repeat for 256 bytes.

        RES     1,(IY+$30)      ; set FLAGS2 - signal printer buffer is clear.
        LD      C,$21           ; set the column position .
        JP      CL_SET          ; exit via CL-SET and then PO-STORE.

;;; @brief Copy line routine
;;;
;;; This routine is called from COPY and COPY-BUFF to output a line of
;;; 32 bytes to the ZX Printer.
;;; Output to port $FB -
;;; bit 7 set - activate stylus.
;;; bit 7 low - deactivate stylus.
;;; bit 2 set - stops printer.
;;; bit 2 reset - starts printer
;;; bit 1 set - slows printer.
;;; bit 1 reset - normal speed.
;;;
;;; ; COPY-LINE
;;; @calledby COPY, COPY_3
;;; @fallthrough COPY_L_1
COPY_LINE:
        LD      A,B             ; fetch the counter 1-8 or 1-176
        CP      $03             ; is it 01 or 02 ?.
        SBC     A,A             ; result is $FF if so else $00.
        AND     $02             ; result is 02 now else 00.
                                ; bit 1 set slows the printer.
        OUT     ($FB),A         ; slow the printer for the
                                ; last two lines.
        LD      D,A             ; save the mask to control the printer later.

;;; @brief ; COPY-L-1
;;;
;;; ; COPY-L-1
;;; @calls BREAK_KEY, CLEAR_PRB
;;; @fallthrough COPY_L_4
COPY_L_1:
        CALL    BREAK_KEY          ; call BREAK-KEY to read keyboard immediately.
        JR      C,COPY_L_2         ; forward to COPY-L-2 if 'break' not pressed.

        LD      A,$04           ; else stop the
        OUT     ($FB),A         ; printer motor.
        EI                      ; enable interrupts.
        CALL    CLEAR_PRB       ; call routine CLEAR-PRB.
                                ; Note. should not be cleared if COPY in use.

REPORT_DC:
        RST     08H             ; ERROR-1
        DB          $0C         ; Error Report: BREAK - CONT repeats

COPY_L_2:
        IN      A,($FB)         ; test now to see if
        ADD     A,A             ; a printer is attached.
        RET     M               ; return if not - but continue with parent
                                ; command.

        JR      NC,COPY_L_1        ; back to COPY-L-1 if stylus of printer not
                                ; in position.

        LD      C,$20           ; set count to 32 bytes.

COPY_L_3:
        LD      E,(HL)          ; fetch a byte from line.
        INC     HL              ; address next location. Note. not INC L.
        LD      B,$08           ; count the bits.

;;; @brief ; COPY-L-4
;;;
;;; ; COPY-L-4
;;; @fallthrough COPY_L_5
COPY_L_4:
        RL      D               ; prepare mask to receive bit.
        RL      E               ; rotate leftmost print bit to carry
        RR      D               ; and back to bit 7 of D restoring bit 1

;;; @brief ; COPY-L-5
;;;
;;; ; COPY-L-5
COPY_L_5:
        IN      A,($FB)         ; read the port.
        RRA                     ; bit 0 to carry.
        JR      NC,COPY_L_5     ; back to COPY-L-5 if stylus not in position.

        LD      A,D             ; transfer command bits to A.
        OUT     ($FB),A         ; and output to port.
        DJNZ    COPY_L_4        ; loop back to COPY-L-4 for all 8 bits.

        DEC     C               ; decrease the byte count.
        JR      NZ,COPY_L_3     ; back to COPY-L-3 until 256 bits done.

        RET                     ; return to calling routine COPY/COPY-BUFF.


;;; @brief Editor routine for BASIC and INPUT
;;;
;;; The editor is called to prepare or edit a BASIC line.
;;; It is also called from INPUT to input a numeric or string expression.
;;; The behaviour and options are quite different in the various modes
;;; and distinguished by bit 5 of FLAGX.
;;;
;;; This is a compact and highly versatile routine.
;;;
;;; ; EDITOR
;;; @calledby MAIN_EXEC, IN_VAR_2, IN_VAR_3
;;; @fallthrough ED_AGAIN
EDITOR:
        LD      HL,(ERR_SP)      ; fetch ERR_SP
        PUSH    HL              ; save on stack

;;; @brief ; ED-AGAIN
;;;
;;; ; ED-AGAIN
;;; @jumpedfrom ED_ERROR
;;; @fallthrough L0F38
ED_AGAIN:
        LD      HL,ED_ERROR     ; address: ED-ERROR
        PUSH    HL              ; save address on stack and
        LD      (ERR_SP),SP      ; make ERR_SP point to it.

; Note. While in editing/input mode should an error occur then RST 08 will
; update X_PTR to the location reached by CH_ADD and jump to ED-ERROR
; where the error will be cancelled and the loop begin again from ED-AGAIN
; above. The position of the error will be apparent when the lower screen is
; reprinted. If no error then the re-iteration is to ED-LOOP below when
; input is arriving from the keyboard.

;; ED-LOOP
                                ; changing the mode.
                                ; with rubber keyboard.

; At this point there is a looping return address on the stack, an error
; handler and an input stream set up to supply characters.
; The character that has been received can now be processed.

;;; @brief (original ROM code at this address, superseded above)
;;;
;;; (original ROM code at this address, superseded above): LD D,$00 ; and give a short click based
;;; (original ROM code at this address, superseded above): LD E,(IY-$01) ; on PIP value for duration.
;;; (original ROM code at this address, superseded above): CALL BEEPER ; routine BEEPER gives click - effective
;;; (original ROM code at this address, superseded above): POP AF ; get saved key value.
;;; @address $0F38
;;; @calls ONE_SPACE, WAIT_KEY
;;; @jumps RTL_ED_KEY_EXT, ADD_CHAR, ED_KEYS, ED_CONTR, ED_IGNORE
;;; @fallthrough ED_CONTR
L0F38:
        JP      RTL_ED_KEY_EXT                   ; jump to RTL_ED_KEY_EXT
L0F3B:
        BIT     6,(IY+2)                ; test bit 6 of (IY+2)
        JR      Z,ADD_CHAR              ; if zero, jump to ADD_CHAR
L0F41:
        RES     0,(IY+7)                ; clear bit 0 of (IY+7)
        LD      HL,(K_CUR)              ; HL = (K_CUR)
        CALL    ONE_SPACE               ; call ONE_SPACE
        LD      (DE),A                  ; (DE) = A
        RET                             ; return
L0F4D:
        NOP                             ; no operation
        JR      NC,L0F3B                ; if no carry, jump to L0F3B

        CP      $07             ; lower than 7 ?
        JR      C,L0F3B         ; if carry, jump to L0F3B
                                ; Note. This is a 'bug' and chr$ 6, the comma
                                ; control character, should have had an
                                ; entry in the ED-KEYS table.
                                ; Steven Vickers, 1984, Pitman.

        CP      $10             ; less than 16 ?
        JR      C,ED_KEYS       ; forward to ED-KEYS if editing control
                                ; range 7 to 15 dealt with by a table

        LD      BC,$0002        ; prepare for ink/paper etc.
        LD      D,A             ; save character in D
        CP      $16             ; is it ink/paper/bright etc. ?
        JR      C,ED_CONTR      ; forward to ED-CONTR if so

                                ; leaves 22d AT and 23d TAB
                                ; which can't be entered via KEY-INPUT.
                                ; so this code is never normally executed
                                ; when the keyboard is used for input.

        INC     BC              ; if it was AT/TAB - 3 locations required
        BIT     7,(IY+$37)      ; test FLAGX  - Is this INPUT LINE ?
        JP      Z,ED_IGNORE     ; jump to ED-IGNORE if not, else

        CALL    WAIT_KEY           ; routine WAIT-KEY - input address is KEY-NEXT
                                ; but is reset to KEY-INPUT
        LD      E,A             ; save first in E

;;; @brief ; ED-CONTR
;;;
;;; ; ED-CONTR
;;; @calls WAIT_KEY, MAKE_ROOM
;;; @jumps ADD_CH_1
;;; @jumpedfrom L0F38
ED_CONTR:
        CALL    WAIT_KEY           ; routine WAIT-KEY for control.
                                ; input address will be key-next.

        PUSH    DE              ; saved code/parameters
        LD      HL,(K_CUR)      ; fetch address of keyboard cursor from K_CUR
        RES     0,(IY+$07)      ; set MODE to 'L'

        CALL    MAKE_ROOM           ; routine MAKE-ROOM makes 2/3 spaces at cursor

        POP     BC              ; restore code/parameters
        INC     HL              ; address first location
        LD      (HL),B          ; place code (ink etc.)
        INC     HL              ; address next
        LD      (HL),C          ; place possible parameter. If only one
                                ; then DE points to this location also.
        JR      ADD_CH_1           ; forward to ADD-CH-1

;;; @brief Add code to current line
;;;
;;; this is the branch used to add normal non-control characters
;;; with ED-LOOP as the stacked return address.
;;; it is also the OUTPUT service routine for system channel 'R'.
;;;
;;; ; ADD-CHAR
;;; @calls ONE_SPACE
;;; @calledby RTL_ED_KEY_EXT
;;; @jumpedfrom L0F38, ED_GRAPH
;;; @fallthrough ADD_CH_1
ADD_CHAR:
        RES     0,(IY+$07)      ; set MODE to 'L'
X0F85:
        LD      HL,(K_CUR)      ; fetch address of keyboard cursor from K_CUR

        CALL    ONE_SPACE           ; routine ONE-SPACE creates one space.

; either a continuation of above or from ED-CONTR with ED-LOOP on stack.

;;; @brief ; ADD-CH-1
;;;
;;; ; ADD-CH-1
;;; @jumpedfrom ED_CONTR
ADD_CH_1:
        LD      (DE),A          ; load current character to last new location.
        INC     DE              ; address next
        LD      (K_CUR),DE      ; and update K_CUR system variable.
        RET                     ; return - either a simple return
                                ; from ADD-CHAR or to ED-LOOP on stack.

; ---

; a branch of the editing loop to deal with control characters
; using a look-up table.

;;; @brief ; ED-KEYS
;;;
;;; ; ED-KEYS
;;; @jumpedfrom L0F38
ED_KEYS:
        LD      E,A             ; character to E.
        LD      D,$00           ; prepare to add.
        LD      HL,ED_KEYS_T - 7 ; base address of editing keys table. $0F99
        ADD     HL,DE           ; add E
        LD      E,(HL)          ; fetch offset to E
        ADD     HL,DE           ; add offset for address of handling routine.
        PUSH    HL              ; push the address on machine stack.
        LD      HL,(K_CUR)      ; load address of cursor from K_CUR.
        RET                     ; Make an indirect jump forward to routine.

;;; @brief Editing keys table
;;;
;;; For each code in the range $07 to $0F this table contains a
;;; single offset byte to the routine that services that code.
;;; Note. for what was intended there should also have been an
;;; entry for chr$ 6 with offset to ed-symbol.
;;;
;;; ; ed-keys-t
ED_KEYS_T:
        DB          ED_EDIT - $  ; 07d offset $09 to Address: ED-EDIT
        DB          ED_LEFT - $  ; 08d offset $66 to Address: ED-LEFT
        DB          ED_RIGHT - $ ; 09d offset $6A to Address: ED-RIGHT
        DB          ED_DOWN - $  ; 10d offset $50 to Address: ED-DOWN
        DB          ED_UP - $    ; 11d offset $B5 to Address: ED-UP
        DB          ED_DELETE - $ ; 12d offset $70 to Address: ED-DELETE
        DB          ED_ENTER - $ ; 13d offset $7E to Address: ED-ENTER
        DB          ED_SYMBOL - $ ; 14d offset $CF to Address: ED-SYMBOL
        DB          ED_GRAPH - $ ; 15d offset $D4 to Address: ED-GRAPH

;;; @brief Handle EDIT key
;;;
;;; The user has pressed SHIFT 1 to bring edit line down to bottom of screen.
;;; Alternatively the user wishes to clear the input buffer and start again.
;;; Alternatively ...
;;;
;;; ; ED-EDIT
;;; @calls LINE_ADDR, LINE_NO, TEST_ROOM, CLEAR_SP, CHAN_OPEN, OUT_LINE, CHAN_FLAG
;;; @jumps CLEAR_SP
ED_EDIT:
        LD      HL,(E_PPC)      ; fetch E_PPC the last line number entered.
                                ; Note. may not exist and may follow program.
        BIT     5,(IY+$37)      ; test FLAGX  - input mode ?
        JP      NZ,CLEAR_SP     ; jump forward to CLEAR-SP if not in editor.

        CALL    LINE_ADDR           ; routine LINE-ADDR to find address of line
                                ; or following line if it doesn't exist.
        CALL    LINE_NO           ; routine LINE-NO will get line number from
                                ; address or previous line if at end-marker.
        LD      A,D             ; if there is no program then DE will
        OR      E               ; contain zero so test for this.
        JP      Z,CLEAR_SP      ; jump to CLEAR-SP if so.

; Note. at this point we have a validated line number, not just an
; approximation and it would be best to update E_PPC with the true
; cursor line value which would enable the line cursor to be suppressed
; in all situations - see shortly.

        PUSH    HL              ; save address of line.
        INC     HL              ; address low byte of length.
        LD      C,(HL)          ; transfer to C
        INC     HL              ; next to high byte
        LD      B,(HL)          ; transfer to B.
        LD      HL,$000A        ; an overhead of ten bytes
        ADD     HL,BC           ; is added to length.
        LD      B,H             ; transfer adjusted value
        LD      C,L             ; to BC register.
        CALL    TEST_ROOM       ; routine TEST-ROOM checks free memory.
        CALL    CLEAR_SP        ; routine CLEAR-SP clears editing area.
        LD      HL,(CURCHL)      ; address CURCHL
        EX      (SP),HL         ; swap with line address on stack
        PUSH    HL              ; save line address underneath

        LD      A,$FF           ; select system channel 'R'
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens it

        POP     HL              ; drop line address
        DEC     HL              ; make it point to first byte of line num.
        DEC     (IY+$0F)        ; decrease E_PPC_lo to suppress line cursor.
                                ; Note. ineffective when E_PPC is one
                                ; greater than last line of program perhaps
                                ; as a result of a delete.
                                ; credit. Paul Harrison 1982.

        CALL    OUT_LINE           ; routine OUT-LINE outputs the BASIC line
                                ; to the editing area.
        INC     (IY+$0F)        ; restore E_PPC_lo to the previous value.
        LD      HL,(E_LINE)      ; address E_LINE in editing area.
        INC     HL              ; advance
        INC     HL              ; past space
        INC     HL              ; and digit characters
        INC     HL              ; of line number.

        LD      (K_CUR),HL      ; update K_CUR to address start of BASIC.
        POP     HL              ; restore the address of CURCHL.
        CALL    CHAN_FLAG       ; routine CHAN-FLAG sets flags for it.

        RET                     ; RETURN to ED-LOOP.

;;; @brief Cursor down editing
;;;
;;;   The BASIC lines are displayed at the top of the screen and the user
;;;   wishes to move the cursor down one line in edit mode.
;;;   With INPUT LINE, this key must be used instead of entering STOP.
;;;
;;; ; ED-DOWN
;;; @calls LN_FETCH
;;; @jumps ED_STOP, ED_LIST
ED_DOWN:
        BIT     5,(IY+$37)      ; test FLAGX  - Input Mode ?
        JR      NZ,ED_STOP      ; skip to ED-STOP if so

        LD      HL,E_PPC        ; address E_PPC - 'current line'
        CALL    LN_FETCH        ; routine LN-FETCH fetches number of next
                                ; line or same if at end of program.
        JR      ED_LIST           ; forward to ED-LIST to produce an
                                ; automatic listing.

; ---

;;; @brief ; ED-STOP
;;;
;;; ; ED-STOP
;;; @jumps ED_ENTER
;;; @jumpedfrom ED_DOWN
ED_STOP:
        LD      (IY+$00),$10    ; set ERR_NR to 'STOP in INPUT' code
        JR      ED_ENTER        ; forward to ED-ENTER to produce error.

;;; @brief Cursor left editing
;;;
;;; This acts on the cursor in the lower section of the screen in both
;;; editing and input mode.
;;;
;;; ; ED-LEFT
;;; @calls ED_EDGE
;;; @jumps ED_CUR
ED_LEFT:
        CALL    ED_EDGE          ; routine ED-EDGE moves left if possible
        JR      ED_CUR           ; forward to ED-CUR to update K-CUR
                                ; and return to ED-LOOP.

;;; @brief Cursor right editing
;;;
;;; This acts on the cursor in the lower screen in both editing and input
;;; mode and moves it to the right.
;;;
;;; ; ED-RIGHT
;;; @fallthrough ED_CUR
ED_RIGHT:
        LD      A,(HL)          ; fetch addressed character.
        CP      $0D             ; is it carriage return ?
        RET     Z               ; return if so to ED-LOOP

L1010:
        INC     HL              ; address next character

;;; @brief ; ED-CUR
;;;
;;; ; ED-CUR
;;; @jumpedfrom ED_LEFT, RTL_ED_KEY_EXT
ED_CUR:
        LD      (K_CUR),HL      ; update K_CUR system variable
        RET                     ; return to ED-LOOP

;;; @brief DELETE editing
;;;
;;; This acts on the lower screen and deletes the character to left of
;;; cursor. If control characters are present these are deleted first
;;; leaving the naked parameter (0-7) which appears as a '?' except in the
;;; case of chr$ 6 which is the comma control character. It is not mandatory
;;; to delete these second characters.
;;;
;;; ; ED-DELETE
;;; @calls ED_EDGE
;;; @jumps RECLAIM_2
ED_DELETE:
        CALL    ED_EDGE         ; routine ED-EDGE moves cursor to left.
L1018:
        LD      BC,$0001        ; of character to be deleted.
        JP      RECLAIM_2       ; to RECLAIM-2 reclaim the character.

;;; @brief Ignore next 2 codes from key-input routine
;;;
;;; Since AT and TAB cannot be entered this point is never reached
;;; from the keyboard. If inputting from a tape device or network then
;;; the control and two following characters are ignored and processing
;;; continues as if a carriage return had been received.
;;; Here, perhaps, another Spectrum has said print #15; AT 0,0; "This is yellow"
;;; and this one is interpreting input #15; a$.
;;;
;;; ; ED-IGNORE
;;; @calls WAIT_KEY
;;; @jumpedfrom L0F38
;;; @fallthrough ED_ENTER
ED_IGNORE:
        CALL    WAIT_KEY           ; routine WAIT-KEY to ignore keystroke.
        CALL    WAIT_KEY           ; routine WAIT-KEY to ignore next key.

;;; @brief Enter/newline
;;;
;;; The enter key has been pressed to have BASIC line or input accepted.
;;;
;;; ; ED-ENTER
;;; @jumpedfrom ED_STOP, ED_SYMBOL
;;; @fallthrough ED_END
ED_ENTER:
        POP     HL              ; discard address ED-LOOP
        POP     HL              ; drop address ED-ERROR

;;; @brief ; ED-END
;;;
;;; ; ED-END
;;; @jumpedfrom ED_ERROR
ED_END:
        POP     HL              ; the previous value of ERR_SP
        LD      (ERR_SP),HL      ; is restored to ERR_SP system variable
        BIT     7,(IY+$00)      ; is ERR_NR $FF (= 'OK') ?
        RET     NZ              ; return if so

        LD      SP,HL           ; else put error routine on stack
        RET                     ; and make an indirect jump to it.

;;; @brief Move cursor left when editing
;;;
;;; This routine moves the cursor left. The complication is that it must
;;; not position the cursor between control codes and their parameters.
;;; It is further complicated in that it deals with TAB and AT characters
;;; which are never present from the keyboard.
;;; The method is to advance from the beginning of the line each time,
;;; jumping one, two, or three characters as necessary saving the original
;;; position at each jump in DE. Once it arrives at the cursor then the next
;;; legitimate leftmost position is in DE.
;;;
;;; ; ED-EDGE
;;; @calls SET_DE
;;; @calledby ED_LEFT, ED_DELETE
;;; @fallthrough ED_EDGE_1
ED_EDGE:
        SCF                     ; carry flag must be set to call the nested
        CALL    SET_DE          ; subroutine SET-DE.
                                ; if input   then DE=WORKSP
                                ; if editing then DE=E_LINE
        SBC     HL,DE           ; subtract address from start of line
        ADD     HL,DE           ; and add back.
        INC     HL              ; adjust for carry.
        POP     BC              ; drop return address
        RET     C               ; return to ED-LOOP if already at left
                                ; of line.

        PUSH    BC              ; resave return address - ED-LOOP.
        LD      B,H             ; transfer HL - cursor address
        LD      C,L             ; to BC register pair.
                                ; at this point DE addresses start of line.

;;; @brief ; ED-EDGE-1
;;;
;;; ; ED-EDGE-1
;;; @jumps ED_EDGE_2
;;; @jumpedfrom ED_EDGE_2
;;; @fallthrough ED_EDGE_2
ED_EDGE_1:
        LD      H,D             ; transfer DE - leftmost pointer
        LD      L,E             ; to HL
        INC     HL              ; address next leftmost character to
                                ; advance position each time.
        LD      A,(DE)          ; pick up previous in A
        AND     $F0             ; lose the low bits
        CP      $10             ; is it INK to TAB $10-$1F ?
                                ; that is, is it followed by a parameter ?
        JR      NZ,ED_EDGE_2        ; to ED-EDGE-2 if not
                                ; HL has been incremented once

        INC     HL              ; address next as at least one parameter.

; in fact since 'tab' and 'at' cannot be entered the next section seems
; superfluous.
; The test will always fail and the jump to ED-EDGE-2 will be taken.

        LD      A,(DE)          ; reload leftmost character
        SUB     $17             ; decimal 23 ('tab')
        ADC     A,$00           ; will be 0 for 'tab' and 'at'.
        JR      NZ,ED_EDGE_2    ; forward to ED-EDGE-2 if not
                                ; HL has been incremented twice

        INC     HL              ; increment a third time for 'at'/'tab'

;;; @brief ; ED-EDGE-2
;;;
;;; ; ED-EDGE-2
;;; @jumps ED_EDGE_1
;;; @jumpedfrom ED_EDGE_1
ED_EDGE_2:
        AND     A               ; prepare for true subtraction
        SBC     HL,BC           ; subtract cursor address from pointer
        ADD     HL,BC           ; and add back
                                ; Note when HL matches the cursor position BC,
                                ; there is no carry and the previous
                                ; position is in DE.
        EX      DE,HL           ; transfer result to DE if looping again.
                                ; transfer DE to HL to be used as K-CUR
                                ; if exiting loop.
        JR      C,ED_EDGE_1         ; back to ED-EDGE-1 if cursor not matched.

        RET                     ; return.

;;; @brief Cursor up editing
;;;
;;; The main screen displays part of the BASIC program and the user wishes
;;; to move up one line scrolling if necessary.
;;; This has no alternative use in input mode.
;;;
;;; ; ED-UP
;;; @calls LINE_ADDR, LINE_NO, LN_STORE
;;; @fallthrough ED_LIST
ED_UP:
        BIT     5,(IY+$37)      ; test FLAGX  - input mode ?
        RET     NZ              ; return if not in editor - to ED-LOOP.

        LD      HL,(E_PPC)      ; get current line from E_PPC
        CALL    LINE_ADDR       ; routine LINE-ADDR gets address
        EX      DE,HL           ; and previous in DE
        CALL    LINE_NO         ; routine LINE-NO gets prev line number
        LD      HL,$5C4A        ; set HL to E_PPC_hi as next routine stores
                                ; top first.
        CALL    LN_STORE           ; routine LN-STORE loads DE value to HL
                                ; high byte first - E_PPC_lo takes E

; this branch is also taken from ed-down.

;;; @brief ; ED-LIST
;;;
;;; ; ED-LIST
;;; @calls AUTO_LIST
;;; @jumps CHAN_OPEN
;;; @jumpedfrom ED_DOWN
ED_LIST:
        CALL    AUTO_LIST           ; routine AUTO-LIST lists to upper screen
                                ; including adjusted current line.
        LD      A,$00           ; select lower screen again
        JP      CHAN_OPEN       ; exit via CHAN-OPEN to ED-LOOP

;;; @brief Use of symbol and graphics codes
;;;
;;; These will not be encountered with the keyboard but would be handled
;;; otherwise as follows.
;;; As noted earlier, Vickers says there should have been an entry in
;;; the KEYS table for chr$ 6 which also pointed here.
;;; If, for simplicity, two Spectrums were both using #15 as a bi-directional
;;; channel connected to each other:-
;;; then when the other Spectrum has said PRINT #15; x, y
;;; input #15; i ; j  would treat the comma control as a newline and the
;;; control would skip to input j.
;;; You can get round the missing chr$ 6 handler by sending multiple print
;;; items separated by a newline '.
;;;
;;; chr$14 would have the same functionality.
;;;
;;; This is chr$ 14.
;;; ; ED-SYMBOL
;;; @jumps ED_ENTER
;;; @fallthrough ED_GRAPH
ED_SYMBOL:
        BIT     7,(IY+$37)      ; test FLAGX - is this INPUT LINE ?
        JR      Z,ED_ENTER      ; back to ED-ENTER if not to treat as if
                                ; enter had been pressed.
                                ; else continue and add code to buffer.

; Next is chr$ 15
; Note that ADD-CHAR precedes the table so we can't offset to it directly.

;;; @brief ; ED-GRAPH
;;;
;;; ; ED-GRAPH
;;; @jumps ADD_CHAR
ED_GRAPH:
        JP      ADD_CHAR           ; jump back to ADD-CHAR

;;; @brief Editor error routine
;;;
;;; If an error occurs while editing, or inputting, then ERR_SP
;;; points to the stack location holding address ED_ERROR.
;;;
;;; ; ED-ERROR
;;; @calls BEEPER
;;; @jumps ED_END, ED_AGAIN
ED_ERROR:
        BIT     4,(IY+$30)      ; test FLAGS2  - is K channel in use ?
        JR      Z,ED_END        ; back to ED-END if not.

; but as long as we're editing lines or inputting from the keyboard, then
; we've run out of memory so give a short rasp.

        LD      (IY+$00),$FF    ; reset ERR_NR to 'OK'.
        LD      D,$00           ; prepare for beeper.
        LD      E,(IY-$02)      ; use RASP value.
        LD      HL,$1A90        ; set the pitch - or tone period.
        CALL    BEEPER          ; routine BEEPER emits a warning rasp.
        JP      ED_AGAIN        ; to ED-AGAIN to re-stack address of
                                ; this routine and make ERR_SP point to it.

;;; @brief Clear edit/work space
;;;
;;; The editing area or workspace is cleared depending on context.
;;; This is called from ED-EDIT to clear workspace if edit key is
;;; used during input, to clear editing area if no program exists
;;; and to clear editing area prior to copying the edit line to it.
;;; It is also used by the error routine to clear the respective
;;; area depending on FLAGX.
;;;
;;; ; CLEAR-SP
;;; @calls SET_HL, RECLAIM_1
;;; @calledby ED_EDIT, MAIN_EXEC
;;; @jumpedfrom ED_EDIT
CLEAR_SP:
        PUSH    HL              ; preserve HL
        CALL    SET_HL          ; routine SET-HL
                                ; if in edit   HL = WORKSP-1, DE = E_LINE
                                ; if in input  HL = STKBOT,   DE = WORKSP
        DEC     HL              ; adjust
        CALL    RECLAIM_1       ; routine RECLAIM-1 reclaims space
        LD      (K_CUR),HL      ; set K_CUR to start of empty area
        LD      (IY+$07),$00    ; set MODE to 'KLC'
        POP     HL              ; restore HL.
        RET                     ; return.

;;; @brief THE 'KEYBOARD INPUT' ROUTINE
;;;
;;; This is the service routine for the input stream of the keyboard channel 'K'.
;;;
;;; ; KEY-INPUT
;;; @calls L111D, CLS_LOWER
;;; @jumps L38F3, KEY_CONTR, KEY_M_CL, KEY_DATA
KEY_INPUT:
        BIT     3,(IY+$02)      ; test TV_FLAG  - has a key been pressed in
                                ; editor ?

        CALL    NZ,L111D        ; routine ED-COPY, if so, to reprint the lower
                                ; screen at every keystroke/mode change.

        AND     A               ; clear carry flag - required exit condition.

        BIT     5,(IY+$01)      ; test FLAGS  - has a new key been pressed ?
        RET     Z               ; return if not.                        >>

        LD      A,(LASTK)       ; system variable LASTK will hold last key -
                                ; from the interrupt routine.

        RES     5,(IY+$01)      ; update FLAGS  - reset the new key flag.
        PUSH    AF              ; save the input character.

        BIT     5,(IY+$02)      ; test TV_FLAG  - clear lower screen ?

        CALL    NZ,CLS_LOWER        ; routine CLS-LOWER if so.

        POP     AF              ; restore the character code.

; (original ROM code at this address, superseded above): JR NC,KEY_DONE2 ; forward to KEY-DONE2 and return with carry
        JP      L38F3                   ; jump to L38F3
L10C8:
        NOP                             ; no operation
                                ; set to signal key-found.

        CP      $10             ; with 16d INK and higher skip
        JR      NC,KEY_CONTR    ; forward to KEY-CONTR.

        CP      $06             ; for 6 - 15d
        JR      NC,KEY_M_CL     ; skip forward to KEY-M-CL to handle Modes
                                ; and CapsLock.

; that only leaves 0-5, the flash bright inverse switches.

        LD      B,A             ; save character in B
        AND     $01             ; isolate the embedded parameter (0/1).
        LD      C,A             ; and store in C
        LD      A,B             ; re-fetch copy (0-5)
        RRA                     ; halve it 0, 1 or 2.
        ADD     A,$12           ; add 18d gives 'flash', 'bright'
                                ; and 'inverse'.
        JR      KEY_DATA           ; forward to KEY-DATA with the
                                ; parameter (0/1) in C.

; ---

; Now separate capslock 06 from modes 7-15.

;;; @brief ; KEY-M-CL
;;;
;;; ; KEY-M-CL
;;; @jumps KEY_MODE, KEY_FLAG
;;; @jumpedfrom KEY_INPUT
KEY_M_CL:
        JR      NZ,KEY_MODE        ; forward to KEY-MODE if not 06 (capslock)

        LD      HL,FLAGS2        ; point to FLAGS2
        LD      A,$08           ; value 00001000
        XOR     (HL)            ; toggle BIT 3 of FLAGS2 the capslock bit
        LD      (HL),A          ; and store result in FLAGS2 again.
        JR      KEY_FLAG        ; forward to KEY-FLAG to signal no-key.

; ---

;;; @brief ; KEY-MODE
;;;
;;; ; KEY-MODE
;;; @jumps KEY_FLAG
;;; @jumpedfrom KEY_M_CL
;;; @fallthrough KEY_FLAG
KEY_MODE:
        CP      $0E             ; compare with chr 14d
        RET     C               ; return with carry set "key found" for
                                ; codes 7 - 13d leaving 14d and 15d
                                ; which are converted to mode codes.

        SUB     $0D             ; subtract 13d leaving 1 and 2
                                ; 1 is 'E' mode, 2 is 'G' mode.
        LD      HL,MODE        ; address the MODE system variable.
        CP      (HL)            ; compare with existing value before
        LD      (HL),A          ; inserting the new value.
        JR      NZ,KEY_FLAG     ; forward to KEY-FLAG if it has changed.

        LD      (HL),$00        ; else make MODE zero - KLC mode
                                ; Note. while in Extended/Graphics mode,
                                ; the Extended Mode/Graphics key is pressed
                                ; again to get out.

;;; @brief ; KEY-FLAG
;;;
;;; ; KEY-FLAG
;;; @jumpedfrom KEY_M_CL, KEY_MODE
KEY_FLAG:
        SET     3,(IY+$02)      ; update TV_FLAG  - show key state has changed
        CP      A               ; clear carry and reset zero flags -
                                ; no actual key returned.
        RET                     ; make the return.

; ---

; now deal with colour controls - 16-23 ink, 24-31 paper

;;; @brief ; KEY-CONTR
;;;
;;; ; KEY-CONTR
;;; @jumps KEY_DATA
;;; @jumpedfrom KEY_INPUT
;;; @fallthrough KEY_DATA
KEY_CONTR:
        LD      B,A             ; make a copy of character.
        AND     $07             ; mask to leave bits 0-7
        LD      C,A             ; and store in C.
        LD      A,$10           ; initialize to 16d - INK.
        BIT     3,B             ; was it paper ?
        JR      NZ,KEY_DATA     ; forward to KEY-DATA with INK 16d and
                                ; colour in C.

        INC     A               ; else change from INK to PAPER (17d) if so.

;;; @brief ; KEY-DATA
;;;
;;; ; KEY-DATA
;;; @jumps KEY_CHAN
;;; @jumpedfrom KEY_INPUT, KEY_CONTR
KEY_DATA:
        LD      (IY-$2D),C         ; put the colour (0-7)/state(0/1) in KDATA
        LD      DE,KEY_NEXT        ; address: KEY-NEXT will be next input stream
        JR      KEY_CHAN           ; forward to KEY-CHAN to change it ...

; ---

; ... so that INPUT_AD directs control to here at next call to WAIT-KEY

;;; @brief ; KEY-NEXT
;;;
;;; ; KEY-NEXT
;;; @fallthrough KEY_CHAN
KEY_NEXT:
        LD      A,(KDATA)       ; pick up the parameter stored in KDATA.
        LD      DE,KEY_INPUT    ; address: KEY-INPUT will be next input stream
                                ; continue to restore default channel and
                                ; make a return with the control code.

;;; @brief ; KEY-CHAN
;;;
;;; ; KEY-CHAN
;;; @jumpedfrom KEY_DATA
;;; @fallthrough KEY_DONE2
KEY_CHAN:
        LD      HL,(CHANS)      ; address start of CHANNELS area using CHANS
                                ; system variable.
                                ; Note. One might have expected CURCHL to
                                ; have been used.
        INC     HL              ; step over the
        INC     HL              ; output address
        LD      (HL),E          ; and update the input
        INC     HL              ; routine address for
        LD      (HL),D          ; the next call to WAIT-KEY.

;;; @brief ; KEY-DONE2
;;;
;;; ; KEY-DONE2
;;; @jumpedfrom L38F3
KEY_DONE2:
        SCF                     ; set carry flag to show a key has been found
        RET                     ; and return.

;;; @brief Lower screen copying
;;;
;;; This subroutine is called whenever the line in the editing area or
;;; input workspace is required to be printed to the lower screen.
;;; It is by calling this routine after any change that the cursor, for
;;; instance, appears to move to the left.
;;; Remember the edit line will contain characters and tokens
;;; e.g. "1000 LET a=1" is 8 characters.
;;;
;;; ; ED-COPY
;;; @address $111D
;;; @calls RTL_TEMPS_HOOK, SET_DE, OUT_LINE2, OUT_CURS, TEMPS
;;; @calledby KEY_INPUT, IN_VAR_4
;;; @fallthrough ED_BLANK
L111D:
        CALL    RTL_TEMPS_HOOK ; call RTL_TEMPS_HOOK
        RES     3,(IY+$02)      ; update TV_FLAG  - signal no change in mode
        RES     5,(IY+$02)      ; update TV_FLAG  - signal don't clear lower
                                ; screen.
        LD      HL,(SPOSNL)      ; fetch SPOSNL
        PUSH    HL              ; and save on stack.

        LD      HL,(ERR_SP)      ; fetch ERR_SP
        PUSH    HL              ; and save also
        LD      HL,ED_FULL      ; address: ED-FULL
        PUSH    HL              ; is pushed as the error routine
        LD      (ERR_SP),SP      ; and ERR_SP made to point to it.

        LD      HL,(ECHO_E)      ; fetch ECHO_E
        PUSH    HL              ; and push also

        SCF                     ; set carry flag to control SET-DE
        CALL    SET_DE          ; call routine SET-DE
                                ; if in input DE = WORKSP
                                ; if in edit  DE = E_LINE
        EX      DE,HL           ; start address to HL

        CALL    OUT_LINE2           ; routine OUT-LINE2 outputs entire line up to
                                ; carriage return including initial
                                ; characterized line number when present.
        EX      DE,HL           ; transfer new address to DE
        CALL    OUT_CURS        ; routine OUT-CURS considers a
                                ; terminating cursor.

        LD      HL,(SPOSNL)      ; fetch updated SPOSNL
        EX      (SP),HL         ; exchange with ECHO_E on stack
        EX      DE,HL           ; transfer ECHO_E to DE
        CALL    TEMPS           ; routine TEMPS to re-set attributes
                                ; if altered.

; the lower screen was not cleared, at the outset, so if deleting then old
; text from a previous print may follow this line and requires blanking.

;;; @brief ; ED-BLANK
;;;
;;; ; ED-BLANK
;;; @jumps ED_C_DONE, ED_SPACES
;;; @jumpedfrom ED_SPACES
;;; @fallthrough ED_SPACES
ED_BLANK:
        LD      A,($5C8B)       ; fetch SPOSNL_hi is current line
        SUB     D               ; compare with old
        JR      C,ED_C_DONE     ; forward to ED-C-DONE if no blanking

        JR      NZ,ED_SPACES        ; forward to ED-SPACES if line has changed

        LD      A,E             ; old column to A
        SUB     (IY+$50)        ; subtract new in SPOSNL_lo
        JR      NC,ED_C_DONE    ; forward to ED-C-DONE if no backfilling.

;;; @brief ; ED-SPACES
;;;
;;; ; ED-SPACES
;;; @calls RTL_PO_FETCH_EXT
;;; @jumps ED_BLANK
;;; @jumpedfrom ED_BLANK
ED_SPACES:
        LD      A,$20           ; prepare a space.
        PUSH    DE              ; save old line/column.
        CALL    RTL_PO_FETCH_EXT ; routine PRINT-OUT prints a space over
                                ; any text from previous print.
                                ; Note. Since the blanking only occurs when
                                ; using $09F4 to print to the lower screen,
                                ; there is no need to vector via a RST 10
                                ; and we can use this alternate set.
        POP     DE              ; restore the old line column.
        JR      ED_BLANK        ; back to ED-BLANK until all old text blanked.

;;; @brief THE 'EDITOR-FULL' ERROR ROUTINE
;;;
;;;   This is the error routine addressed by ERR_SP.  This is not for the out of
;;;   memory situation as we're just printing.  The pitch and duration are exactly
;;;   the same as used by ED-ERROR from which this has been augmented.  The
;;;   situation is that the lower screen is full and a rasp is given to suggest
;;;   that this is perhaps not the best idea you've had that day.
;;;
;;; ; ED-FULL
;;; @calls BEEPER
;;; @jumps ED_C_END
ED_FULL:
        LD      D,$00           ; prepare to moan.
        LD      E,(IY-$02)      ; fetch RASP value.
        LD      HL,$1A90        ; set pitch or tone period.

        CALL    BEEPER           ; routine BEEPER.

        LD      (IY+$00),$FF    ; clear ERR_NR.
        LD      DE,(SPOSNL)      ; fetch SPOSNL.
        JR      ED_C_END        ; forward to ED-C-END

; -------

; the exit point from line printing continues here.

;;; @brief ; ED-C-DONE
;;;
;;; ; ED-C-DONE
;;; @jumpedfrom ED_BLANK
;;; @fallthrough ED_C_END
ED_C_DONE:
        POP     DE              ; fetch new line/column.
        POP     HL              ; fetch the error address.

; the error path rejoins here.

;;; @brief ; ED-C-END
;;;
;;; ; ED-C-END
;;; @calls CL_SET
;;; @jumpedfrom ED_FULL
ED_C_END:
        POP     HL              ; restore the old value of ERR_SP.
        LD      (ERR_SP),HL      ; update the system variable ERR_SP

        POP     BC              ; old value of SPOSN_L
        PUSH    DE              ; save new value

        CALL    CL_SET           ; routine CL-SET and PO-STORE
                                ; update ECHO_E and SPOSN_L from BC

        POP     HL              ; restore new value
        LD      (ECHO_E),HL      ; and overwrite ECHO_E

        LD      (IY+$26),$00    ; make error pointer X_PTR_hi out of bounds

        RET                     ; return

;;; @brief Point to first and last locations of work space
;;;
;;;   These two nested routines ensure that the appropriate pointers are
;;;   selected for the editing area or workspace. The routines that call
;;;   these routines are designed to work on either area.
;;;
;;; this routine is called once
;;;
;;; ; SET-HL
;;; @calledby CLEAR_SP
;;; @fallthrough SET_DE
SET_HL:
        LD      HL,(WORKSP)      ; fetch WORKSP to HL.
        DEC     HL              ; point to last location of editing area.
        AND     A               ; clear carry to limit exit points to first
                                ; or last.

; this routine is called with carry set and exits at a conditional return.

;;; @brief ; SET-DE
;;;
;;; ; SET-DE
;;; @calledby ED_EDGE, L111D
SET_DE:
        LD      DE,(E_LINE)      ; fetch E_LINE to DE
        BIT     5,(IY+$37)      ; test FLAGX  - Input Mode ?
        RET     Z               ; return now if in editing mode

        LD      DE,(WORKSP)      ; fetch WORKSP to DE
        RET     C               ; return if carry set ( entry = set-de)

        LD      HL,(STKBOT)      ; fetch STKBOT to HL as well
        RET                     ; and return  (entry = set-hl (in input))

;;; @brief THE 'REMOVE FLOATING POINT' ROUTINE
;;;
;;;   When a BASIC LINE or the INPUT BUFFER is parsed any numbers will have
;;;   an invisible chr 14d inserted after them and the 5-byte integer or
;;;   floating point form inserted after that.  Similar invisible value holders
;;;   are also created after the numeric and string variables in a DEF FN list.
;;;   This routine removes these 'compiled' numbers from the edit line or
;;;   input workspace.
;;;
;;; ; REMOVE-FP
;;; @calls RECLAIM_2
;;; @calledby MAIN_EXEC, IN_VAR_2
REMOVE_FP:
        LD      A,(HL)          ; fetch character
        CP      $0E             ; is it the CHR$ 14 number marker ?
        LD      BC,$0006        ; prepare to strip six bytes

        CALL    Z,RECLAIM_2         ; routine RECLAIM-2 reclaims bytes if CHR$ 14.

        LD      A,(HL)          ; reload next (or same) character
        INC     HL              ; and advance address
        CP      $0D             ; end of line or input buffer ?
        JR      NZ,REMOVE_FP    ; back to REMOVE-FP until entire line done.

        RET                     ; return.


; *********************************
