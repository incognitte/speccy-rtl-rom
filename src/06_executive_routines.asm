;;; @file 06_executive_routines.asm
;;; @brief Part 6. EXECUTIVE ROUTINES

; *********************************
; ** Part 6. EXECUTIVE ROUTINES  **
; *********************************


; The memory.
;
; +---------+-----------+------------+--------------+-------------+--
; | BASIC   |  Display  | Attributes | ZX Printer   |    System   |
; |  ROM    |   File    |    File    |   Buffer     |  Variables  |
; +---------+-----------+------------+--------------+-------------+--
; ^         ^           ^            ^              ^             ^
; $0000   $4000       $5800        $5B00          $5C00         $5CB6 = CHANS
;
;
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    | Channel  |$80|  BASIC  | Variables |$80| Edit Line  |NL|$80|
;    |   Info   |   | Program |   Area    |   | or Command |  |   |
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    ^              ^         ^               ^                   ^
;  CHANS           PROG      VARS           E_LINE              WORKSP
;
;
;                             ---5-->         <---2---  <--3---
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    | INPUT |NL| Temporary  | Calc. | Spare | Machine | GOSUB |?|$3E| UDGs |
;    | data  |  | Work Space | Stack |       |  Stack  | Stack | |   |      |
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    ^                       ^       ^       ^                   ^   ^      ^
;  WORKSP                  STKBOT  STKEND   sp               RAMTOP UDG  P_RAMT
;

;;; @brief THE 'NEW' COMMAND
;;;
;;;   The NEW command is about to set all RAM below RAMTOP to zero and then
;;;   re-initialize the system.  All RAM above RAMTOP should, and will be,
;;;   preserved.
;;;   There is nowhere to store values in RAM or on the stack which becomes
;;;   inoperable. Similarly PUSH and CALL instructions cannot be used to store
;;;   values or section common code. The alternate register set is the only place
;;;   available to store 3 persistent 16-bit system variables.
;;;
;;; ; NEW
;;; @fallthrough START_NEW
NEW:
        DI                      ; Disable Interrupts - machine stack will be
                                ; cleared.
        LD      A,$FF           ; Flag coming from NEW.
        LD      DE,(RAMTOP)      ; Fetch RAMTOP as top value.
        EXX                     ; Switch in alternate set.
        LD      BC,(P_RAMT)      ; Fetch P-RAMT differs on 16K/48K machines.
        LD      DE,(RASP)      ; Fetch RASP/PIP.
        LD      HL,(UDG)      ; Fetch UDG    differs on 16K/48K machines.
        EXX                     ; Switch back to main set and continue into...

;;; @brief THE 'START-NEW' BRANCH
;;;
;;;   This branch is taken from above and from RST 00h.
;;;   The common code tests RAM and sets it to zero re-initializing all the
;;;   non-zero system variables and channel information.  The A register flags
;;;   if coming from START or NEW.
;;;
;;; ; START-NEW
;;; @jumpedfrom START
;;; @fallthrough RAM_CHECK
START_NEW:
        LD      B,A             ; Save the flag to control later branching.

        LD      A,$07           ; Select a white border
        OUT     ($FE),A         ; and set it now by writing to a port.

        LD      A,$3F           ; Load the accumulator with last page in ROM.
        LD      I,A             ; Set the I register - this remains constant
                                ; and can't be in the range $40 - $7F as 'snow'
                                ; appears on the screen.

        NOP                     ; These seem unnecessary.
        NOP                     ;
        NOP                     ;
        NOP                     ;
        NOP                     ;
        NOP                     ;

;;; @brief THE 'RAM CHECK' SECTION
;;;
;;;   Typically, a Spectrum will have 16K or 48K of RAM and this code will test
;;;   it all till it finds an unpopulated location or, less likely, a faulty
;;;   location.  Usually it stops when it reaches the top $FFFF, or in the case
;;;   of NEW the supplied top value.  The entire screen turns black with
;;;   sometimes red stripes on black paper just visible.
;;;
;;; ; ram-check
;;; @fallthrough RAM_FILL
RAM_CHECK:
        LD      H,D             ; Transfer the top value to the HL register
        LD      L,E             ; pair.

;;; @brief ; RAM-FILL
;;;
;;; ; RAM-FILL
;;; @fallthrough RAM_READ
RAM_FILL:
        LD      (HL),$02        ; Load memory with $02 - red ink on black paper.
        DEC     HL              ; Decrement memory address.
        CP      H               ; Have we reached ROM - $3F ?
        JR      NZ,RAM_FILL     ; Back to RAM-FILL if not.

;;; @brief ; RAM-READ
;;;
;;; ; RAM-READ
;;; @jumps RAM_DONE
;;; @fallthrough RAM_DONE
RAM_READ:
        AND     A               ; Clear carry - prepare to subtract.
        SBC     HL,DE           ; subtract and add back setting
        ADD     HL,DE           ; carry when back at start.
        INC     HL              ; and increment for next iteration.
        JR      NC,RAM_DONE     ; forward to RAM-DONE if we've got back to
                                ; starting point with no errors.

        DEC     (HL)            ; decrement to 1.
        JR      Z,RAM_DONE      ; forward to RAM-DONE if faulty.

        DEC     (HL)            ; decrement to zero.
        JR      Z,RAM_READ      ; back to RAM-READ if zero flag was set.

;;; @brief ; RAM-DONE
;;;
;;; ; RAM-DONE
;;; @jumps RAM_SET
;;; @jumpedfrom RAM_READ
;;; @fallthrough RAM_SET
RAM_DONE:
        DEC     HL              ; step back to last valid location.
        EXX                     ; regardless of state, set up possibly
                                ; stored system variables in case from NEW.
        LD      (P_RAMT),BC      ; insert P-RAMT.
        LD      (RASP),DE      ; insert RASP/PIP.
        LD      (UDG),HL      ; insert UDG.
        EXX                     ; switch in main set.
        INC     B               ; now test if we arrived here from NEW.
        JR      Z,RAM_SET       ; forward to RAM-SET if we did.

;   This section applies to START only.

        LD      (P_RAMT),HL      ; set P-RAMT to the highest working RAM
                                ; address.
        LD      DE,L3D00+('U'-$20)*8+7 ; address of last byte of 'U' bitmap in ROM.
        LD      BC,$00A8        ; there are 21 user defined graphics.
        EX      DE,HL           ; switch pointers and make the UDGs a
        LDDR                    ; copy of the standard characters A - U.
        EX      DE,HL           ; switch the pointer to HL.
        INC     HL              ; update to start of 'A' in RAM.
        LD      (UDG),HL      ; make UDG system variable address the first
                                ; bitmap.
        DEC     HL              ; point at RAMTOP again.

        LD      BC,$0040        ; set the values of
        LD      (RASP),BC      ; the PIP and RASP system variables.

;   The NEW command path rejoins here.

;;; @brief ; RAM-SET
;;;
;;; ; RAM-SET
;;; @jumpedfrom RAM_DONE
;;; @fallthrough NMI_VECT
RAM_SET:
        LD      (RAMTOP),HL      ; set system variable RAMTOP to HL.

;   New
;   Note. this entry point is a disabled Warm Restart that was almost certainly
;   once pointed to by the System Variable NMIADD.  It would be essential that
;   any NMI Handler would perform the tasks from here to the EI instruction
;   below.

;;; @brief ; NMI_VECT
;;;
;;; ; NMI_VECT
;;; @calls CLEAR_PRB, CLS, RTL_PRINT_EXTRA_MSG, PO_MSG
NMI_VECT:
        LD      HL,L3D00-$100   ; a strange place to set the pointer to the
        LD      (CHARS),HL      ; character set, CHARS - as no printing yet.

        LD      HL,(RAMTOP)      ; fetch RAMTOP to HL again as we've lost it.

        LD      (HL),$3E        ; top of user ram holds GOSUB end marker
                                ; an impossible line number - see RETURN.
                                ; no significance in the number $3E. It has
                                ; been traditional since the ZX80.

        DEC     HL              ; followed by empty byte (not important).
        LD      SP,HL           ; set up the machine stack pointer.
        DEC     HL              ;
        DEC     HL              ;
        LD      (ERR_SP),HL      ; ERR_SP is where the error pointer is
                                ; at moment empty - will take address MAIN-4
                                ; at the call preceding that address,
                                ; although interrupts and calls will make use
                                ; of this location in meantime.

        IM      1               ; select interrupt mode 1.

        LD      IY,ERR_NR        ; set IY to ERR_NR. IY can reach all standard
                                ; system variables but shadow ROM system
                                ; variables will be mostly out of range.

        EI                      ; enable interrupts now that we have a stack.

;   If, as suggested above, the NMI service routine pointed to this section of
;   code then a decision would have to be made at this point to jump forward,
;   in a Warm Restart scenario, to produce a report code, leaving any program
;   intact.

        LD      HL,$5CB6        ; The address of the channels - initially
                                ; following system variables.
        LD      (CHANS),HL      ; Set the CHANS system variable.

        LD      DE,INIT_CHAN    ; Address: init-chan in ROM.
        LD      BC,$0015        ; There are 21 bytes of initial data in ROM.
        EX      DE,HL           ; swap the pointers.
        LDIR                    ; Copy the bytes to RAM.

        EX      DE,HL           ; Swap pointers. HL points to program area.
        DEC     HL              ; Decrement address.
        LD      (DATADD),HL      ; Set DATADD to location before program area.
        INC     HL              ; Increment again.

        LD      (PROG),HL      ; Set PROG the location where BASIC starts.
        LD      (VARS),HL      ; Set VARS to same location with a
        LD      (HL),$80        ; variables end-marker.
        INC     HL              ; Advance address.
        LD      (E_LINE),HL      ; Set E_LINE, where the edit line
                                ; will be created.
                                ; Note. it is not strictly necessary to
                                ; execute the next fifteen bytes of code
                                ; as this will be done by the call to SET-MIN.
                                ; --
        LD      (HL),$0D        ; initially just has a carriage return
        INC     HL              ; followed by
        LD      (HL),$80        ; an end-marker.
        INC     HL              ; address the next location.
        LD      (WORKSP),HL      ; set WORKSP - empty workspace.
        LD      (STKBOT),HL      ; set STKBOT - bottom of the empty stack.
        LD      (STKEND),HL      ; set STKEND to the end of the empty stack.
                                ; --
        LD      A,$38           ; the colour system is set to white paper,
                                ; black ink, no flash or bright.
        LD      (ATTR_P),A       ; set ATTR_P permanent colour attributes.
        LD      (ATTR_T),A       ; set ATTR_T temporary colour attributes.
        LD      (BORDCR),A       ; set BORDCR the border colour/lower screen
                                ; attributes.

        LD      HL,$0523        ; The keyboard repeat and delay values are
        LD      (REPDEL),HL      ; loaded to REPDEL and REPPER.

        DEC     (IY-$3A)        ; set KSTATE-0 to $FF - keyboard map available.
        DEC     (IY-$36)        ; set KSTATE-4 to $FF - keyboard map available.

        LD      HL,INIT_STRM    ; set source to ROM Address: init-strm
        LD      DE,STRMS        ; set destination to system variable STRMS-FD
        LD      BC,$000E        ; copy the 14 bytes of initial 7 streams data
        LDIR                    ; from ROM to RAM.

        SET     1,(IY+$01)      ; update FLAGS  - signal printer in use.
        CALL    CLEAR_PRB       ; call routine CLEAR-PRB to initialize system
                                ; variables associated with printer.
                                ; The buffer is clear.

        LD      (IY+$31),$02    ; set DF_SZ the lower screen display size to
                                ; two lines
        ;
        ; ---- ARABIC BOOT SPLASH (replaces the English "(c) 1982 Sinclair Research Ltd") ----
        ; Step 1: RTL_PRINT_EXTRA_MSG ($3CF6, file 11) = CALL CLS; XOR A; LD DE,$09DF; JP PO_MSG.
        ;   It clears the screen and prints the Arabic TITLE LOGO, the message stored in the
        ;   cassette message table (file 04, message at $09E0).  Like every message printed
        ;   straight after CLS it goes to the LOWER-SCREEN channel starting on the bottom line;
        ;   the lower screen window grows (DF_SZ 2 -> 13, scrolling the text up), which leaves it
        ;   centred on screen.  What it shows (verified by running the ROM and on the real boot
        ;   screen capture):
        ;         row 12, column 15 :   *
        ;         row 13, column 15 :   |
        ;         row 14, columns 11-19 :   عرب | رام      =  "ARAB | RAM"
        ;   (key codes "YQH | QGe"; text prints right to left).
        ; Step 2: the copyright line below is printed at the bottom row (row 23, columns 7-23):
        ;         (c) اوتورام كمبيوتر                    =  "(c) AutoRAM Computer"
        ;   (key codes $7F " GhJhQGe ceHihJQ"; stored at $01ED in file 01, LANG_BOOT_COPYRIGHT_MSG).
        ;   DE=$01EC is the inverted last byte of the COPY token in the token table, used as the
        ;   step-over byte that PO-MSG skips (message number 0 starts at the next byte).
        IFDEF   LANG_PERSIAN
        CALL    CLS
        ELSE
        CALL    RTL_PRINT_EXTRA_MSG    ; clear screen and print the Arabic title logo (see above)
        ENDIF
        XOR     A                       ; message number 0 ...
        LD      DE,LANG_BOOT_COPYRIGHT_MSG-1 ; ... starting after the step-over byte just before the Arabic copyright line
        CALL    PO_MSG                  ; prints "(c) اوتورام كمبيوتر" at the bottom of the display
        SET     5,(IY+$02)      ; update TV_FLAG  - signal lower screen will
                                ; require clearing.

        JR      MAIN_1           ; forward to MAIN-1

;;; @brief THE 'MAIN EXECUTION LOOP'
;;; @calls AUTO_LIST, SET_MIN, CHAN_OPEN, EDITOR, LINE_SCAN, REMOVE_FP, E_LINE_NO, CL_ALL, CLS_LOWER, LINE_RUN, +5 more
;;; @jumps MAIN_ADD
;;; @jumpedfrom MAIN_ADD2
MAIN_EXEC:
        LD      (IY+$31),$02    ; set DF_SZ lower screen display file size to
                                ; two lines.
        CALL    AUTO_LIST           ; routine AUTO-LIST

MAIN_1:
        CALL    SET_MIN           ; routine SET-MIN clears work areas.

MAIN_2:
        LD      A,$00           ; select channel 'K' the keyboard

        CALL    CHAN_OPEN           ; routine CHAN-OPEN opens it

        CALL    EDITOR           ; routine EDITOR is called.
                                ; Note the above routine is where the Spectrum
                                ; waits for user-interaction. Perhaps the
                                ; most common input at this stage
                                ; is LOAD "".

        CALL    LINE_SCAN           ; routine LINE-SCAN scans the input.

        BIT     7,(IY+$00)      ; test ERR_NR - will be $FF if syntax is OK.
        JR      NZ,MAIN_3       ; forward, if correct, to MAIN-3.

;

        BIT     4,(IY+$30)      ; test FLAGS2 - K channel in use ?
        JR      Z,MAIN_4        ; forward to MAIN-4 if not.

;

        LD      HL,(E_LINE)      ; an editing error so address E_LINE.
        CALL    REMOVE_FP       ; routine REMOVE-FP removes the hidden
                                ; floating-point forms.
        LD      (IY+$00),$FF    ; system variable ERR_NR is reset to 'OK'.
        JR      MAIN_2          ; back to MAIN-2 to allow user to correct.

; ---

; the branch was here if syntax has passed test.

MAIN_3:
        LD      HL,(E_LINE)      ; fetch the edit line address from E_LINE.

        LD      (CH_ADD),HL      ; system variable CH_ADD is set to first
                                ; character of edit line.
                                ; Note. the above two instructions are a little
                                ; inadequate.
                                ; They are repeated with a subtle difference
                                ; at the start of the next subroutine and are
                                ; therefore not required above.

        CALL    E_LINE_NO           ; routine E-LINE-NO will fetch any line
                                ; number to BC if this is a program line.

        LD      A,B             ; test if the number of
        OR      C               ; the line is non-zero.
        JP      NZ,MAIN_ADD     ; jump forward to MAIN-ADD if so to add the
                                ; line to the BASIC program.

; Has the user just pressed the ENTER key ?

        RST     18H             ; GET-CHAR gets character addressed by CH_ADD.
        CP      $0D             ; is it a carriage return ?
        JR      Z,MAIN_EXEC     ; back to MAIN-EXEC if so for an automatic
                                ; listing.

; this must be a direct command.

        BIT     0,(IY+$30)      ; test FLAGS2 - clear the main screen ?

        CALL    NZ,CL_ALL        ; routine CL-ALL, if so, e.g. after listing.

        CALL    CLS_LOWER           ; routine CLS-LOWER anyway.

        LD      A,$19           ; compute scroll count as 25 minus
        SUB     (IY+$4F)        ; value of S_POSN_hi.
        LD      (SCR_CT),A       ; update SCR_CT system variable.
        SET     7,(IY+$01)      ; update FLAGS - signal running program.
        LD      (IY+$00),$FF    ; set ERR_NR to 'OK'.
        LD      (IY+$0A),$01    ; set NSPPC to one for first statement.
        CALL    LINE_RUN        ; call routine LINE-RUN to run the line.
                                ; sysvar ERR_SP therefore addresses MAIN-4

; Examples of direct commands are RUN, CLS, LOAD "", PRINT USR 40000,
; LPRINT "A"; etc..
; If a user written machine-code program disables interrupts then it
; must enable them to pass the next step. We also jumped to here if the
; keyboard was not being used.

MAIN_4:
        HALT                    ; wait for interrupt the only routine that can
                                ; set bit 5 of FLAGS.

        RES     5,(IY+$01)      ; update bit 5 of FLAGS - signal no new key.

        BIT     1,(IY+$30)      ; test FLAGS2 - is printer buffer clear ?
        CALL    NZ,COPY_BUFF    ; call routine COPY-BUFF if not.
                                ; Note. the programmer has neglected
                                ; to set bit 1 of FLAGS first.

        LD      A,(ERR_NR)       ; fetch ERR_NR
        INC     A               ; increment to give true code.

; Now deal with a runtime error as opposed to an editing error.
; However if the error code is now zero then the OK message will be printed.

MAIN_G:
        PUSH    AF              ; save the error number.

        LD      HL,$0000        ; prepare to clear some system variables.
        LD      (IY+$37),H      ; clear all the bits of FLAGX.
        LD      (IY+$26),H      ; blank X_PTR_hi to suppress error marker.
        LD      (DEFADD),HL      ; blank DEFADD to signal that no defined
                                ; function is currently being evaluated.

        LD      HL,$0001        ; explicit - inc hl would do.
        LD      ($5C16),HL      ; ensure STRMS-00 is keyboard.

        CALL    SET_MIN         ; routine SET-MIN clears workspace etc.
        RES     5,(IY+$37)      ; update FLAGX - signal in EDIT not INPUT mode.
                                ; Note. all the bits were reset earlier.

        CALL    CLS_LOWER           ; call routine CLS-LOWER.

        SET     5,(IY+$02)      ; update TV_FLAG - signal lower screen
                                ; requires clearing.

        POP     AF              ; bring back the true error number


;; MAIN-5
        ;   Report number -> printed characters.  The English code printed the digit/letter
        ;   with OUT_CODE and then a ', ' separator.  The Arabic ROM prints it as follows:
        ;     L1391 first forces ARABIC mode (RES 4,(IY+1)) and clears the join-context bits so the
        ;     report text is always Arabic even if the user left the editor in Latin mode.
        ;     Report codes 0-9 print as digits.  Codes 10-27 print as the letter whose key code is
        ;     code+$3E ($3A+14 = 'H'): 10=H ب, 11=I ة, 12=J ت, 13=K ث, 14=L ج, 15=M ح, 16=N خ,
        ;     17=O د, 18=P ذ, 19=Q ر, 20=R ز, 21=S س, 22=T ش, 23=U ص, 24=V ض, 25=W ط, 26=X ظ, 27=Y ع.
        ;   Then: space, the Arabic message from LANG_MSG_TABLE ($3923, file 11), space, and
        ;   the line number and ':' statement number as before.
        CALL    L1391                   ; Arabic ON + clear context bits (see L1391 below)
        LD      B,A                     ; B = A
        ADD     A,$30                   ; A = A + $30
        CP      $3A                     ; compare A with $3A
        JR      C,L1341                 ; if carry (code 0-9), print it as it is
        ADD     A,14                    ; A = A + 14
L133C   EQU    $133C                    ; this address now falls inside the block above (label kept for reference)
L1341:
        RST     10H                     ; PRINT-A


        LD      A,$20                   ; A = $20
        RST     $10                     ; restart at $10
        LD      A,B                     ; A = B
        LD      DE,LANG_MSG_TABLE    ; DE = Arabic report message table
X1349:
        CALL    PO_MSG                  ; call PO_MSG
        LD      A,$20                   ; A = $20
        RST     $10                     ; restart at $10
        NOP                             ; no operation
                                ; be more succinct to use RST $10.

        LD      BC,(PPC)      ; fetch PPC the current line number.
        CALL    OUT_NUM_1       ; routine OUT-NUM-1 will print that

        LD      A,$3A           ; then a ':' character.
        RST     10H             ; PRINT-A

        LD      C,(IY+$0D)      ; then SUBPPC for statement
        LD      B,$00           ; limited to 127
        CALL    OUT_NUM_1       ; routine OUT-NUM-1 prints BC.

        CALL    CLEAR_SP           ; routine CLEAR-SP clears editing area which
                                ; probably contained 'RUN'.

        LD      A,(ERR_NR)       ; fetch ERR_NR again
        INC     A               ; test for no error originally $FF.
        JR      Z,MAIN_9        ; forward to MAIN-9 if no error.

        CP      $09             ; is code Report 9 STOP ?
        JR      Z,MAIN_6        ; forward to MAIN-6 if so

        CP      $15             ; is code Report L Break ?
        JR      NZ,MAIN_7       ; forward to MAIN-7 if not

; Stop or Break was encountered so consider CONTINUE.

MAIN_6:
        INC     (IY+$0D)        ; increment SUBPPC to next statement.

MAIN_7:
        LD      BC,$0003        ; prepare to copy 3 system variables to
        LD      DE,OSPPC        ; address OSPPC - statement for CONTINUE.
                                ; also updating OLDPPC line number below.

        LD      HL,NSPPC        ; set source top to NSPPC next statement.
        BIT     7,(HL)          ; did BREAK occur before the jump ?
                                ; e.g. between GO TO and next statement.
        JR      Z,MAIN_8         ; skip forward to MAIN-8, if not, as set-up
                                ; is correct.

        ADD     HL,BC           ; set source to SUBPPC number of current
                                ; statement/line which will be repeated.

MAIN_8:
        LDDR                    ; copy PPC to OLDPPC and SUBPPC to OSPCC
                                ; or NSPPC to OLDPPC and NEWPPC to OSPCC

MAIN_9:
        LD      (IY+$0A),$FF    ; update NSPPC - signal 'no jump'.
        RES     3,(IY+$01)      ; update FLAGS - signal use 'K' mode for
                                ; the first character in the editor and

        JP      MAIN_2           ; jump back to MAIN-2.


;;; @brief Canned report messages - REMOVED / REPLACED IN THE ARABIC ROM
;;;
;;; In the standard ROM this area ($1391-$1555) held the error report text
;;; table (the "rpt-mesgs", "OK", "NEXT without FOR" ...), the ', ' separator
;;; and the copyright line " 1982 Sinclair Research Lt"+'d'.  The Arabic ROM
;;; has moved all of that elsewhere:
;;; @verbatim
;;;     report messages  ->  LANG_MSG_TABLE at $3923 (file 11), 28 Arabic messages
;;;     copyright line   ->  LANG_BOOT_COPYRIGHT_MSG at $01ED (file 01):
;;;                          "(c) اوتورام كمبيوتر" = "(c) AutoRAM Computer"
;;;     boot title logo  ->  message at $09E0 (file 04): "عرب | رام" = "ARAB | RAM"
;;; @endverbatim
;;; The freed ~460 bytes ($1391 up to RTL_GLYPH_SUBSTITUTE at $145D) were
;;; reused for the small routines below, which were moved or added so that
;;; numbers display correctly in a right-to-left screen:
;;; @verbatim
;;;     L1391 / L1395   reset the Arabic mode / join-context flags
;;;     L139E-L13F7     number scanner: copies the digits of a typed number
;;;                     in reverse into a buffer before DEC_TO_FP reads them
;;;     L13FC-L1424     line-number scanner for E_LINE_NO (digits are
;;;                     read units first)
;;;     L1426 / L1434   one decimal digit (replaces OUT-SP-NO)
;;;     L1436           prints a 4-digit number UNITS FIRST (replaces OUT-NUM-3)
;;;                     so that right-to-left printing shows the most
;;;                     significant digit on the LEFT, as for normal numerals.
;;; @endverbatim
;;; Numbers are therefore held in "units first" text order inside the
;;; edit line while they are scanned or printed.
;;;
;;; L1391 / L1395 - "Arabic ON and reset joining context"
;;;   L1391: RES 4,(IY+1)  - clear the "Latin / substitution off" flag, so Arabic
;;;                          glyph substitution is active (same as CHR$ 4).
;;;   L1395: RES 2,(IY+2); RES 1,(IY+2) - clear TV_FLAG bits 2 and 1, the
;;; @verbatim
;;;                          "does not join next" and "previous letter joined"
;;;                          context bits (see file 11), so the next letter starts
;;;                          a fresh word.  Used by CHR$ 4, by the report printer
;;;                          (MAIN-5), by TEMPS (RTL_TEMPS_HOOK in file 01) and
;;;                          by the one-shot form override at $154C.
;;; @endverbatim
;;; @address $1391
;;; @calledby RTL_TEMPS_HOOK, MAIN_EXEC
;;; @jumpedfrom RTL_NEW_CTRL_HANDLER
;;; @fallthrough L1395
L1391:
        RES     4,(IY+1)                ; clear bit 4 of (IY+1)
;;; @brief Entry point L1395 (no original comment).
;;; @address $1395
;;; @calledby L1543
L1395:
        RES     2,(IY+2)                ; clear bit 2 of (IY+2)
        RES     1,(IY+2)                ; clear bit 1 of (IY+2)
        RET                             ; return
;;; @brief L139E - scan a number typed in the edit line (called from S_DECIMAL, file 08, while a BASIC line is being syntax-checked
;;;
;;; L139E - scan a number typed in the edit line (called from S_DECIMAL, file 08,
;;;   while a BASIC line is being syntax-checked)
;;;   The digit characters are copied, going BACKWARDS from $5CAF, into a small
;;;   buffer (L13E2: DEC DE; LD (DE),A; ... loop while NUMERIC), handling the BIN
;;;   token ($C4: L13EB), a decimal point ($2E) and the exponent marker $5D (the
;;;   ']' key, shown as an 'E' glyph).  Finally CH_ADD is pointed at the buffer
;;;   (TEMP_PTR2) and DEC_TO_FP converts the reversed text, so the number is read
;;;   with the LAST digit stored in the line as its most significant one.
;;;   This is the counterpart of L1436 which prints numbers units-first.
;;; @address $139E
;;; @calls L13E2, TEMP_PTR2, DEC_TO_FP
;;; @jumps TEMP_PTR2
;;; @calledby S_DECIMAL
L139E:
        LD      DE,$5CAF                ; DE = $5CAF
        LD      A,E                     ; A = E
        LD      (DE),A                  ; (DE) = A
        RST     $18                     ; restart at $18
        CP      $C4                     ; compare A with $C4
        JR      Z,L13EB                 ; if zero, jump to L13EB
        CP      $2E                     ; compare A with $2E
        JR      Z,L13D3                 ; if zero, jump to L13D3
        CALL    L13E2                   ; call L13E2
        CP      $2E                     ; compare A with $2E
        JR      Z,L13D3                 ; if zero, jump to L13D3
        CP      $5D                     ; compare A with $5D
        JR      Z,L13CA                 ; if zero, jump to L13CA
        CP      $2B                     ; compare A with $2B
        JR      Z,L13BF                 ; if zero, jump to L13BF
        CP      $2D                     ; compare A with $2D
        JR      NZ,L13D6                ; if not zero, jump to L13D6
L13BF:
        LD      C,A                     ; C = A
        PUSH    HL                      ; push HL onto the stack
        RST     $20                     ; restart at $20
        CP      $5D                     ; compare A with $5D
        POP     HL                      ; pop HL off the stack
        JR      NZ,L13D6                ; if not zero, jump to L13D6
        LD      A,C                     ; A = C
        DEC     DE                      ; DE = DE - 1
        LD      (DE),A                  ; (DE) = A
L13CA:
        LD      A,$5D                   ; A = $5D
        CALL    L13E2                   ; call L13E2
        CP      $2E                     ; compare A with $2E
        JR      NZ,L13D6                ; if not zero, jump to L13D6
L13D3:
        CALL    L13E2                   ; call L13E2
L13D6:
        PUSH    HL                      ; push HL onto the stack
        EX      DE,HL                   ; swap DE and HL
        CALL    TEMP_PTR2               ; call TEMP_PTR2
        CALL    DEC_TO_FP               ; call DEC_TO_FP
        POP     HL                      ; pop HL off the stack
        JP      TEMP_PTR2               ; jump to TEMP_PTR2
;;; @brief Entry point L13E2 (no original comment).
;;; @address $13E2
;;; @calls NUMERIC
;;; @calledby L139E
L13E2:
        DEC     DE                      ; DE = DE - 1
        LD      (DE),A                  ; (DE) = A
        RST     $20                     ; restart at $20
        CALL    NUMERIC                 ; call NUMERIC
        RET     C                       ; return if carry
        JR      L13E2                   ; jump to L13E2
L13EB:
        DEC     DE                      ; DE = DE - 1
        RST     $20                     ; restart at $20
        SUB     $31                     ; A = A - $31
        ADC     A,0                     ; A = A + 0 + carry
        JR      NZ,L13F7                ; if not zero, jump to L13F7
        RST     $18                     ; restart at $18
        LD      (DE),A                  ; (DE) = A
        JR      L13EB                   ; jump to L13EB
L13F7:
        LD      A,$C4                   ; A = $C4
        LD      (DE),A                  ; (DE) = A
        JR      L13D6                   ; jump to L13D6
;;; @brief L13FC - scan a LINE NUMBER from the edit line (called by E_LINE_NO) Returns HL = line number, carry set if the first cha
;;;
;;; L13FC - scan a LINE NUMBER from the edit line (called by E_LINE_NO)
;;;   Returns HL = line number, carry set if the first character is not a digit.
;;;   The first digit read is the UNITS digit, each following digit has ten times the
;;;   weight of the one before (DE holds the weight: 1, 10, 100 ...), the reverse of
;;;   the original left-to-right scanner.  Overflow (carry) ends the scan.
;;; @address $13FC
;;; @calls NUMERIC
;;; @calledby E_LINE_NO
L13FC:
        LD      HL,0                    ; HL = 0
        LD      DE,1                    ; DE = 1
        CALL    NUMERIC                 ; call NUMERIC
        CCF                             ; complement the carry flag
        RET     NC                      ; return if no carry
        SUB     $30                     ; A = A - $30
        LD      L,A                     ; L = A
L140A:
        PUSH    HL                      ; push HL onto the stack
        RST     $20                     ; restart at $20
        CALL    NUMERIC                 ; call NUMERIC
        CCF                             ; complement the carry flag
        JR      NC,L1424                ; if no carry, jump to L1424
        LD      H,D                     ; H = D
        LD      L,E                     ; L = E
        ADD     HL,HL                   ; HL = HL + HL
        ADD     HL,HL                   ; HL = HL + HL
        ADD     HL,HL                   ; HL = HL + HL
        ADD     HL,DE                   ; HL = HL + DE
        ADD     HL,DE                   ; HL = HL + DE
        EX      DE,HL                   ; swap DE and HL
        POP     HL                      ; pop HL off the stack
        SUB     $30                     ; A = A - $30
L141D:
        JR      Z,L140A                 ; if zero, jump to L140A
        ADD     HL,DE                   ; HL = HL + DE
        RET     C                       ; return if carry
        DEC     A                       ; A = A - 1
        JR      L141D                   ; jump to L141D
L1424:
        POP     HL                      ; pop HL off the stack
        RET                             ; return
;;; @brief L1426 / L1434 - one decimal digit of a number (replaces OUT-SP-NO) HL = value, BC = negative power of ten (e.g
;;;
;;; L1426 / L1434 - one decimal digit of a number (replaces OUT-SP-NO)
;;;   HL = value, BC = negative power of ten (e.g. $FC18 = -1000).  Counts how many
;;;   times BC can be subtracted.  Returns A = '0'+count, or - when the count is zero -
;;;   A = E, the "leading zero" marker ($FF = print nothing, $20 = print a space).
;;; @address $1426
;;; @calledby L1436
L1426:
        XOR     A                       ; A = 0
L1427:
        ADD     HL,BC                   ; HL = HL + BC
        INC     A                       ; A = A + 1
        JR      C,L1427                 ; if carry, jump to L1427
        SBC     HL,BC                   ; HL = HL - BC - carry
        DEC     A                       ; A = A - 1
        JR      Z,L1434                 ; if zero, jump to L1434
        LD      E,$30                   ; E = $30
        ADD     A,E                     ; A = A + E
        RET                             ; return
L1434:
        LD      A,E                     ; A = E
        RET                             ; return
;;; @brief L1436 - print a 16-bit number in HL, UNITS FIRST (replaces OUT-NUM-3; entered through L1A30 'JP L1436') E = $FF
;;;
;;; L1436 - print a 16-bit number in HL, UNITS FIRST (replaces OUT-NUM-3;
;;;   entered through L1A30 'JP L1436')
;;;   E = $FF: no leading zeros (BASIC listing statement numbers), E = $20: leading
;;;   spaces (right-aligns line numbers).  The thousands, hundreds and tens digits are
;;;   worked out and pushed, then the UNITS digit is printed first, followed by tens,
;;;   hundreds and thousands (a $FF marker prints nothing).  Because the screen
;;;   prints right to left this puts the most significant digit on the left, so
;;;   Arabic-Indic numerals read normally.  Ends with JP $1A45 (the original
;;;   OUT-NUM-4 exit that restores DE and HL and returns).
;;; @address $1436
;;; @calls L1426, OUT_CODE, PRINT_A_2
;;; @jumpedfrom L1A30
L1436:
        LD      BC,$FC18                ; BC = $FC18
        CALL    L1426                   ; call L1426
        PUSH    AF                      ; push AF onto the stack
        LD      BC,$FF9C                ; BC = $FF9C
        CALL    L1426                   ; call L1426
        PUSH    AF                      ; push AF onto the stack
        LD      C,$F6                   ; C = $F6
        CALL    L1426                   ; call L1426
        PUSH    AF                      ; push AF onto the stack
        LD      A,L                     ; A = L
        CALL    OUT_CODE                ; call OUT_CODE
        LD      B,3                     ; B = 3
L1450:
        POP     AF                      ; pop AF off the stack
        CP      $FF                     ; compare A with $FF
        PUSH    BC                      ; push BC onto the stack
        CALL    NZ,PRINT_A_2            ; if not zero, call PRINT_A_2
        POP     BC                      ; pop BC off the stack
        DJNZ    L1450                   ; B = B - 1; loop to L1450 while B != 0
        JP      L1A45                   ; jump to the register restore + RET of OUT-NUM-4
;;; @brief Entry point RTL_GLYPH_SUBSTITUTE (no original comment).
;;; @calls RTL_GLYPH_GUARD, L0363
;;; @calledby PO_CHAR
RTL_GLYPH_SUBSTITUTE:
        LD      BC,(CHARS)              ; fetch CHARS as usual (unaffected characters keep the normal font)
        BIT     4,(IY+1)                ; test bit 4 of (IY+1)
        RET     NZ                      ; return if not zero
        CALL    RTL_GLYPH_GUARD        ; call RTL_GLYPH_GUARD
        RET     NC                      ; return if no carry
        CP      $6C                     ; compare A with $6C
        RET     NC                      ; return if no carry
        EX      DE,HL                   ; swap DE and HL
        LD      HL,RTL_GLYPH_FLAG_LOOKUP_BASE ; HL = character-flag lookup base
        LD      C,A                     ; C = A
        LD      B,0                     ; B = 0
        ADD     HL,BC                   ; HL = HL + BC
        LD      B,(HL)                  ; B = (HL)
        LD      C,(IY+2)                ; C = (IY+2)
        BIT     2,C                     ; test bit 2 of C
        JR      Z,L148E                 ; if zero, jump to L148E
        BIT     1,C                     ; test bit 1 of C
        JR      Z,L1488                 ; if zero, jump to L1488
        BIT     4,B                     ; test bit 4 of B
        LD      HL,LANG_GLYPH_TABLE_1   ; HL = first glyph-substitution table
        JR      Z,L14A0                 ; if zero, jump to L14A0
L1488:
        EX      DE,HL                   ; swap DE and HL
        LD      BC,LANG_ISOLATED_FONT-8*$41 ; BC = isolated font base (glyph = BC + 8*code, codes start at $41)
        JR      L14AE                   ; jump to L14AE
L148E:
        BIT     1,C                     ; test bit 1 of C
        JR      Z,L1499                 ; if zero, jump to L1499
        BIT     5,B                     ; test bit 5 of B
        LD      HL,LANG_GLYPH_TABLE_2   ; HL = second glyph-substitution table
        JR      Z,L14A0                 ; if zero, jump to L14A0
L1499:
        BIT     6,B                     ; test bit 6 of B
        JR      NZ,L1488                ; if not zero, jump to L1488
        LD      HL,LANG_GLYPH_TABLE_3   ; HL = third glyph-substitution table
L14A0:
        LD      BC,9                    ; BC = 9
L14A3:
        CP      (HL)                    ; compare A with (HL)
        JR      Z,L14A9                 ; if zero, jump to L14A9
        ADD     HL,BC                   ; HL = HL + BC
        JR      L14A3                   ; jump to L14A3
L14A9:
        LD      B,H                     ; B = H
        LD      C,L                     ; C = L
        INC     BC                      ; BC = BC + 1
        XOR     A                       ; A = 0
        EX      DE,HL                   ; swap DE and HL
L14AE:
        PUSH    AF                      ; push AF onto the stack
        LD      A,(TV_FLAG)               ; A = (TVFLAG)
        SET     1,A                     ; set bit 1 of A
        BIT     7,A                     ; test bit 7 of A
        JR      NZ,L14BA                ; if not zero, jump to L14BA
        RES     1,A                     ; clear bit 1 of A
L14BA:
        LD      (TV_FLAG),A               ; (TVFLAG) = A
        POP     AF                      ; pop AF off the stack
        RET                             ; return
L14BF:
        BIT     6,(IY+2)                ; test bit 6 of (IY+2)
        JP      NZ,L035E                ; if not zero, jump to L035E
        CALL    L0363                   ; call L0363
        CP      $41                     ; compare A with $41
        RET     C                       ; return if carry
        CP      $7B                     ; compare A with $7B
        RET     NC                      ; return if no carry
        LD      HL,LANG_KEY_LOOKUP_TABLE - $41 ; base for ASCII-indexed key lookup
        LD      E,A                     ; E = A
        JP      K_LOOK_UP               ; jump to K_LOOK_UP
LANG_KEY_LOOKUP_TABLE:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/key_lookup.asm"
        ELSE
        INCLUDE "lang/arabic/key_lookup.asm"
        ENDIF
;;; @brief Entry point L1510 (no original comment).
;;; @address $1510
;;; @calls ALPHA
;;; @calledby RTL_PO_MSG_HOOK, RTL_PO_MSG_LAST, RTL_PR_STRING_HOOK
L1510:
        PUSH    HL                      ; push HL onto the stack
        CALL    ALPHA                   ; call ALPHA
        JR      NC,L1533                ; if no carry, jump to L1533
        CP      $6C                     ; compare A with $6C
        JR      NC,L1533                ; if no carry, jump to L1533
        PUSH    BC                      ; push BC onto the stack
        LD      C,A                     ; C = A
        LD      B,0                     ; B = 0
        LD      HL,RTL_GLYPH_FLAG_LOOKUP_BASE ; HL = character-flag lookup base
        ADD     HL,BC                   ; HL = HL + BC
        BIT     7,(HL)                  ; test bit 7 of (HL)
        POP     BC                      ; pop BC off the stack
        JR      Z,L152F                 ; if zero, jump to L152F
        LD      C,A                     ; C = A
        LD      A,B                     ; A = B
        CALL    ALPHA                   ; call ALPHA
        LD      A,C                     ; A = C
        JR      C,L1539                 ; if carry, jump to L1539
L152F:
        SET     2,(IY+2)                ; set bit 2 of (IY+2)
L1533:
        RES     7,(IY+2)                ; clear bit 7 of (IY+2)
L1537:
        POP     HL                      ; pop HL off the stack
        RET                             ; return
L1539:
        RES     2,(IY+2)                ; clear bit 2 of (IY+2)
        SET     7,(IY+2)                ; set bit 7 of (IY+2)
        POP     HL                      ; pop HL off the stack
        RET                             ; return
;;; @brief Entry point L1543 (no original comment).
;;; @address $1543
;;; @calls NUMERIC, L1395, RTL_INSTALL_PRINT_HOOK
;;; @jumps L387B
;;; @calledby S_SCRN_S
L1543:
        CALL    NUMERIC                 ; call NUMERIC
        RET     NC                      ; return if no carry
        CP      $2E                     ; compare A with $2E
        RET     Z                       ; return if zero
        SCF                             ; set the carry flag
        RET                             ; return
RTL_FORM_OVERRIDE_OUT:
        CALL    L1395                   ; call L1395
        CALL    RTL_INSTALL_PRINT_HOOK ; call RTL_INSTALL_PRINT_HOOK
        JP      L387B                   ; jump to L387B


;;; @brief REPORT-G
;;;
;;; Note ERR_SP points here during line entry which allows the
;;; normal 'Out of Memory' report to be augmented to the more
;;; precise 'No Room for line' report.
;;;
;;; ; REPORT-G
;;; No Room for line
;;; @address $1555
L1555:
        LD      A,$10           ; i.e. 'G' -$30 -$07
        LD      BC,$0000        ; this seems unnecessary.
        JP      MAIN_G          ; jump back to MAIN-G

;;; @brief Handle addition of BASIC line
;;;
;;; Note this is not a subroutine but a branch of the main execution loop.
;;; System variable ERR_SP still points to editing error handler.
;;; A new line is added to the BASIC program at the appropriate place.
;;; An existing line with same number is deleted first.
;;; Entering an existing line number deletes that line.
;;; Entering a non-existent line allows the subsequent line to be edited next.
;;;
;;; ; MAIN-ADD
;;; @calls LINE_ADDR, NEXT_ONE, RECLAIM_2
;;; @jumps MAIN_ADD1
;;; @jumpedfrom MAIN_EXEC
;;; @fallthrough MAIN_ADD1
MAIN_ADD:
        LD      (E_PPC),BC      ; set E_PPC to extracted line number.
        LD      HL,(CH_ADD)      ; fetch CH_ADD - points to location after the
                                ; initial digits (set in E_LINE_NO).
        EX      DE,HL           ; save start of BASIC in DE.

        LD      HL,L1555        ; Address: REPORT-G
        PUSH    HL              ; is pushed on stack and addressed by ERR_SP.
                                ; the only error that can occur is
                                ; 'Out of memory'.

        LD      HL,(WORKSP)      ; fetch WORKSP - end of line.
        SCF                     ; prepare for true subtraction.
        SBC     HL,DE           ; find length of BASIC and
        PUSH    HL              ; save it on stack.
        LD      H,B             ; transfer line number
        LD      L,C             ; to HL register.
        CALL    LINE_ADDR       ; routine LINE-ADDR will see if
                                ; a line with the same number exists.
        JR      NZ,MAIN_ADD1        ; forward if no existing line to MAIN-ADD1.

        CALL    NEXT_ONE           ; routine NEXT-ONE finds the existing line.
        CALL    RECLAIM_2          ; routine RECLAIM-2 reclaims it.

;;; @brief ; MAIN-ADD1
;;;
;;; ; MAIN-ADD1
;;; @calls MAKE_ROOM
;;; @jumps MAIN_ADD2
;;; @jumpedfrom MAIN_ADD
;;; @fallthrough MAIN_ADD2
MAIN_ADD1:
        POP     BC              ; retrieve the length of the new line.
        LD      A,C             ; and test if carriage return only
        DEC     A               ; i.e. one byte long.
        OR      B               ; result would be zero.
        JR      Z,MAIN_ADD2     ; forward to MAIN-ADD2 is so.

        PUSH    BC              ; save the length again.
        INC     BC              ; adjust for inclusion
        INC     BC              ; of line number (two bytes)
        INC     BC              ; and line length
        INC     BC              ; (two bytes).
        DEC     HL              ; HL points to location before the destination

        LD      DE,(PROG)      ; fetch the address of PROG
        PUSH    DE              ; and save it on the stack
        CALL    MAKE_ROOM       ; routine MAKE-ROOM creates BC spaces in
                                ; program area and updates pointers.
        POP     HL              ; restore old program pointer.
        LD      (PROG),HL      ; and put back in PROG as it may have been
                                ; altered by the POINTERS routine.

        POP     BC              ; retrieve BASIC length
        PUSH    BC              ; and save again.

        INC     DE              ; points to end of new area.
        LD      HL,(WORKSP)      ; set HL to WORKSP - location after edit line.
        DEC     HL              ; decrement to address end marker.
        DEC     HL              ; decrement to address carriage return.
        LDDR                    ; copy the BASIC line back to initial command.

        LD      HL,(E_PPC)      ; fetch E_PPC - line number.
        EX      DE,HL           ; swap it to DE, HL points to last of
                                ; four locations.
        POP     BC              ; retrieve length of line.
        LD      (HL),B          ; high byte last.
        DEC     HL              ;
        LD      (HL),C          ; then low byte of length.
        DEC     HL              ;
        LD      (HL),E          ; then low byte of line number.
        DEC     HL              ;
        LD      (HL),D          ; then high byte range $0 - $27 (1-9999).

;;; @brief ; MAIN-ADD2
;;;
;;; ; MAIN-ADD2
;;; @jumps MAIN_EXEC
;;; @jumpedfrom MAIN_ADD1
MAIN_ADD2:
        POP     AF              ; drop the address of Report G
        JP      MAIN_EXEC       ; and back to MAIN-EXEC producing a listing
                                ; and to reset ERR_SP in EDITOR.


;;; @brief THE 'INITIAL CHANNEL' INFORMATION
;;;
;;;   This initial channel information is copied from ROM to RAM, during
;;;   initialization.  It's new location is after the system variables and is
;;;   addressed by the system variable CHANS which means that it can slide up and
;;;   down in memory.  The table is never searched, by this ROM, and the last
;;;   character, which could be anything other than a comma, provides a
;;;   convenient resting place for DATADD.
;;;
;;; ; init-chan
INIT_CHAN:
        DW    RTL_PO_FETCH_EXT  ; PRINT-OUT
        DW    KEY_INPUT          ; KEY-INPUT
        DB          $4B          ; 'K'
        DW    RTL_PO_FETCH_EXT  ; PRINT-OUT
        DW    REPORT_J           ; REPORT-J
        DB          $53          ; 'S'
        DW    ADD_CHAR           ; ADD-CHAR
        DW    REPORT_J           ; REPORT-J
        DB          $52          ; 'R'
        DW    RTL_PO_FETCH_EXT  ; PRINT-OUT
        DW    REPORT_J           ; REPORT-J
        DB          $50          ; 'P'

        DB          $80             ; End Marker

;;; @brief ; REPORT-J
;;;
;;; ; REPORT-J
REPORT_J:
        RST     08H             ; ERROR-1
        DB          $12         ; Error Report: Invalid I/O device


;;; @brief THE 'INITIAL STREAM' DATA
;;;
;;;   This is the initial stream data for the seven streams $FD - $03 that is
;;;   copied from ROM to the STRMS system variables area during initialization.
;;;   There are reserved locations there for another 12 streams.  Each location
;;;   contains an offset to the second byte of a channel.  The first byte of a
;;;   channel can't be used as that would result in an offset of zero for some
;;;   and zero is used to denote that a stream is closed.
;;;
;;; ; init-strm
INIT_STRM:
        DB          $01, $00        ; stream $FD offset to channel 'K'
        DB          $06, $00        ; stream $FE offset to channel 'S'
        DB          $0B, $00        ; stream $FF offset to channel 'R'

        DB          $01, $00        ; stream $00 offset to channel 'K'
        DB          $01, $00        ; stream $01 offset to channel 'K'
        DB          $06, $00        ; stream $02 offset to channel 'S'
        DB          $10, $00        ; stream $03 offset to channel 'P'

;;; @brief THE 'INPUT CONTROL' SUBROUTINE
;;;
;;; ; WAIT-KEY
;;; @jumps WAIT_KEY1
;;; @calledby SA_CONTRL, PO_SCR, L0F38, ED_CONTR, ED_IGNORE, RTL_ED_KEY_EXT
;;; @fallthrough WAIT_KEY1
WAIT_KEY:
        BIT     5,(IY+$02)      ; test TV_FLAG - clear lower screen ?
        JR      NZ,WAIT_KEY1    ; forward to WAIT-KEY1 if so.

        SET     3,(IY+$02)      ; update TV_FLAG - signal reprint the edit
                                ; line to the lower screen.

;;; @brief ; WAIT-KEY1
;;;
;;; ; WAIT-KEY1
;;; @calls INPUT_AD
;;; @jumpedfrom WAIT_KEY
;;; @fallthrough REPORT_8
WAIT_KEY1:
        CALL    INPUT_AD           ; routine INPUT-AD is called.

        RET     C               ; return with acceptable keys.

        JR      Z,WAIT_KEY1         ; back to WAIT-KEY1 if no key is pressed
                                ; or it has been handled within INPUT-AD.

;   Note. When inputting from the keyboard all characters are returned with
;   above conditions so this path is never taken.

;;; @brief ; REPORT-8
;;;
;;; ; REPORT-8
REPORT_8:
        RST     08H             ; ERROR-1
        DB          $07         ; Error Report: End of file

;;; @brief THE 'INPUT ADDRESS' ROUTINE
;;;
;;;   This routine fetches the address of the input stream from the current
;;;   channel area using the system variable CURCHL.
;;;
;;; ; INPUT-AD
;;; @jumps CALL_SUB
;;; @calledby WAIT_KEY1, READ_IN
INPUT_AD:
        EXX                     ; switch in alternate set.
        PUSH    HL              ; save HL register
        LD      HL,(CURCHL)      ; fetch address of CURCHL - current channel.
        INC     HL              ; step over output routine
        INC     HL              ; to point to low byte of input routine.
        JR      CALL_SUB        ; forward to CALL-SUB.

;;; @brief THE 'CODE OUTPUT' ROUTINE
;;;
;;;   This routine is called on five occasions to print the ASCII equivalent of
;;;   a value 0-9.
;;;
;;; ; OUT-CODE
;;; @calledby L1436, OUT_NUM_4, PF_NOT_E, PF_OUT_DT
;;; @jumpedfrom OUT_SP_1
;;; @fallthrough PRINT_A_2
OUT_CODE:
        LD      E,$30           ; add 48 decimal to give the ASCII character
        ADD     A,E             ; '0' to '9' and continue into the main output
                                ; routine.

;;; @brief THE 'MAIN OUTPUT' ROUTINE
;;;
;;;   PRINT-A-2 is a continuation of the RST 10 restart that prints any character.
;;;   The routine prints to the current channel and the printing of control codes
;;;   may alter that channel to divert subsequent RST 10 instructions to temporary
;;;   routines. The normal channel is $09F4.
;;;
;;; ; PRINT-A-2
;;; @calledby L1436
;;; @jumpedfrom PRINT_A
;;; @fallthrough CALL_SUB
PRINT_A_2:
        EXX                     ; switch in alternate set
        PUSH    HL              ; save HL register
        LD      HL,(CURCHL)      ; fetch CURCHL the current channel.

; input-ad rejoins here also.

;;; @brief ; CALL-SUB
;;;
;;; ; CALL-SUB
;;; @calls CALL_JUMP
;;; @jumpedfrom INPUT_AD
CALL_SUB:
        LD      E,(HL)          ; put the low byte in E.
        INC     HL              ; advance address.
        LD      D,(HL)          ; put the high byte to D.
        EX      DE,HL           ; transfer the stream to HL.
        CALL    CALL_JUMP       ; use routine CALL-JUMP.
                                ; in effect CALL (HL).

        POP     HL              ; restore saved HL register.
        EXX                     ; switch back to the main set and
        RET                     ; return.

;;; @brief THE 'OPEN CHANNEL' ROUTINE
;;;
;;;   This subroutine is used by the ROM to open a channel 'K', 'S', 'R' or 'P'.
;;;   This is either for its own use or in response to a user's request, for
;;;   example, when '#' is encountered with output - PRINT, LIST etc.
;;;   or with input - INPUT, INKEY$ etc.
;;;   It is entered with a system stream $FD - $FF, or a user stream $00 - $0F
;;;   in the accumulator.
;;;
;;; ; CHAN-OPEN
;;; @jumps CHAN_OP_1
;;; @calledby REPORT_FA, SA_CONTRL, PO_SCR, CL_CHAN, CL_ALL, ED_EDIT, MAIN_EXEC, LIST_1, PRINT_1, STR_ALTER, +3 more
;;; @jumpedfrom ED_LIST
;;; @fallthrough REPORT_OA
CHAN_OPEN:
        ADD     A,A             ; double the stream ($FF will become $FE etc.)
        ADD     A,$16           ; add the offset to stream 0 from KSTATE_0
        LD      L,A             ; result to L
        LD      H,$5C           ; now form the address in STRMS area.
        LD      E,(HL)          ; fetch low byte of CHANS offset
        INC     HL              ; address next
        LD      D,(HL)          ; fetch high byte of offset
        LD      A,D             ; test that the stream is open.
        OR      E               ; zero if closed.
        JR      NZ,CHAN_OP_1    ; forward to CHAN-OP-1 if open.

;;; @brief ; REPORT-Oa
;;;
;;; ; REPORT-Oa
;;; @jumpedfrom STR_ALTER
REPORT_OA:
        RST     08H             ; ERROR-1
        DB          $17         ; Error Report: Invalid stream

; continue here if stream was open. Note that the offset is from CHANS
; to the second byte of the channel.

;;; @brief ; CHAN-OP-1
;;;
;;; ; CHAN-OP-1
;;; @jumpedfrom CHAN_OPEN
;;; @fallthrough CHAN_FLAG
CHAN_OP_1:
        DEC     DE              ; reduce offset so it points to the channel.
        LD      HL,(CHANS)      ; fetch CHANS the location of the base of
                                ; the channel information area
        ADD     HL,DE           ; and add the offset to address the channel.
                                ; and continue to set flags.

;;; @brief Set channel flags
;;;
;;; This subroutine is used from ED-EDIT, str$ and read-in to reset the
;;; current channel when it has been temporarily altered.
;;;
;;; ; CHAN-FLAG
;;; @calls INDEXER
;;; @calledby ED_EDIT, STR, READ_IN
;;; @fallthrough CALL_JUMP
CHAN_FLAG:
        LD      (CURCHL),HL      ; set CURCHL system variable to the
                                ; address in HL
        RES     4,(IY+$30)      ; update FLAGS2  - signal K channel not in use.
                                ; Note. provide a default for channel 'R'.
        INC     HL              ; advance past
        INC     HL              ; output routine.
        INC     HL              ; advance past
        INC     HL              ; input routine.
        LD      C,(HL)          ; pick up the letter.
        LD      HL,CHN_CD_LU    ; address: chn-cd-lu
        CALL    INDEXER         ; routine INDEXER finds offset to a
                                ; flag-setting routine.

        RET     NC              ; but if the letter wasn't found in the
                                ; table just return now. - channel 'R'.

        LD      D,$00           ; prepare to add
        LD      E,(HL)          ; offset to E
        ADD     HL,DE           ; add offset to location of offset to form
                                ; address of routine

;;; @brief ; CALL-JUMP
;;;
;;; ; CALL-JUMP
;;; @calledby CALL_SUB
CALL_JUMP:
        JP      (HL)            ; jump to the routine

; Footnote. calling any location that holds JP (HL) is the equivalent to
; a pseudo Z80 instruction CALL (HL). The ROM uses the instruction above.

;;; @brief Channel code look-up table
;;;
;;; This table is used by the routine above to find one of the three
;;; flag setting routines below it.
;;; A zero end-marker is required as channel 'R' is not present.
;;;
;;; ; chn-cd-lu
CHN_CD_LU:
        DB          'K', CHAN_K-$-1  ; offset $06 to CHAN-K
        DB          'S', CHAN_S-$-1  ; offset $12 to CHAN-S
        DB          'P', CHAN_P-$-1  ; offset $1B to CHAN-P

        DB          $00             ; end marker.

;;; @brief Channel K flag
;;;
;;; routine to set flags for lower screen/keyboard channel.
;;;
;;; ; CHAN-K
;;; @jumps CHAN_S_1
CHAN_K:
        SET     0,(IY+$02)      ; update TV_FLAG  - signal lower screen in use
        RES     5,(IY+$01)      ; update FLAGS    - signal no new key
        SET     4,(IY+$30)      ; update FLAGS2   - signal K channel in use
        JR      CHAN_S_1        ; forward to CHAN-S-1 for indirect exit

;;; @brief Channel S flag
;;;
;;; routine to set flags for upper screen channel.
;;;
;;; ; CHAN-S
;;; @fallthrough CHAN_S_1
CHAN_S:
        RES     0,(IY+$02)      ; TV_FLAG  - signal main screen in use

;;; @brief ; CHAN-S-1
;;;
;;; ; CHAN-S-1
;;; @jumps TEMPS
;;; @jumpedfrom CHAN_K
CHAN_S_1:
        RES     1,(IY+$01)      ; update FLAGS  - signal printer not in use
        JP      TEMPS           ; jump back to TEMPS and exit via that
                                ; routine after setting temporary attributes.
;;; @brief Channel P flag
;;;
;;; This routine sets a flag so that subsequent print related commands
;;; print to printer or update the relevant system variables.
;;; This status remains in force until reset by the routine above.
;;;
;;; ; CHAN-P
CHAN_P:
        SET     1,(IY+$01)      ; update FLAGS  - signal printer in use
        RET                     ; return

;;; @brief THE 'ONE SPACE' SUBROUTINE
;;;
;;; This routine is called once only to create a single space
;;; in workspace by ADD-CHAR.
;;;
;;; ; ONE-SPACE
;;; @calledby L0F38, ADD_CHAR
;;; @fallthrough MAKE_ROOM
ONE_SPACE:
        LD      BC,$0001        ; create space for a single character.

;;; @brief Make Room
;;;
;;; This entry point is used to create BC spaces in various areas such as
;;; program area, variables area, workspace etc..
;;; The entire free RAM is available to each BASIC statement.
;;; On entry, HL addresses where the first location is to be created.
;;; Afterwards, HL will point to the location before this.
;;;
;;; ; MAKE-ROOM
;;; @calls TEST_ROOM, POINTERS
;;; @calledby LD_CONTRL, ME_ENTER, ED_CONTR, MAIN_ADD1, RESERVE, F_REORDER, DEF_FN_5, S_DECIMAL, L_SPACES, L_STRING, +1 more
MAKE_ROOM:
        PUSH    HL              ; save the address pointer.
        CALL    TEST_ROOM       ; routine TEST-ROOM checks if room
                                ; exists and generates an error if not.
        POP     HL              ; restore the address pointer.
        CALL    POINTERS        ; routine POINTERS updates the
                                ; dynamic memory location pointers.
                                ; DE now holds the old value of STKEND.
        LD      HL,(STKEND)      ; fetch new STKEND the top destination.

        EX      DE,HL           ; HL now addresses the top of the area to
                                ; be moved up - old STKEND.
        LDDR                    ; the program, variables, etc are moved up.
        RET                     ; return with new area ready to be populated.
                                ; HL points to location before new area,
                                ; and DE to last of new locations.

;;; @brief Adjust pointers before making or reclaiming room
;;;
;;; This routine is called by MAKE-ROOM to adjust upwards and by RECLAIM to
;;; adjust downwards the pointers within dynamic memory.
;;; The fourteen pointers to dynamic memory, starting with VARS and ending
;;; with STKEND, are updated adding BC if they are higher than the position
;;; in HL.
;;; The system variables are in no particular order except that STKEND, the first
;;; free location after dynamic memory must be the last encountered.
;;;
;;; ; POINTERS
;;; @calledby MAKE_ROOM, RECLAIM_2
;;; @fallthrough PTR_NEXT
POINTERS:
        PUSH    AF              ; preserve accumulator.
        PUSH    HL              ; put pos pointer on stack.
        LD      HL,VARS        ; address VARS the first of the
        LD      A,$0E           ; fourteen variables to consider.

;;; @brief ; PTR-NEXT
;;;
;;; ; PTR-NEXT
;;; @jumps PTR_DONE
;;; @jumpedfrom PTR_DONE
;;; @fallthrough PTR_DONE
PTR_NEXT:
        LD      E,(HL)          ; fetch the low byte of the system variable.
        INC     HL              ; advance address.
        LD      D,(HL)          ; fetch high byte of the system variable.
        EX      (SP),HL         ; swap pointer on stack with the variable
                                ; pointer.
        AND     A               ; prepare to subtract.
        SBC     HL,DE           ; subtract variable address
        ADD     HL,DE           ; and add back
        EX      (SP),HL         ; swap pos with system variable pointer
        JR      NC,PTR_DONE     ; forward to PTR-DONE if var before pos

        PUSH    DE              ; save system variable address.
        EX      DE,HL           ; transfer to HL
        ADD     HL,BC           ; add the offset
        EX      DE,HL           ; back to DE
        LD      (HL),D          ; load high byte
        DEC     HL              ; move back
        LD      (HL),E          ; load low byte
        INC     HL              ; advance to high byte
        POP     DE              ; restore old system variable address.

;;; @brief ; PTR-DONE
;;;
;;; ; PTR-DONE
;;; @jumps PTR_NEXT
;;; @jumpedfrom PTR_NEXT
PTR_DONE:
        INC     HL              ; address next system variable.
        DEC     A               ; decrease counter.
        JR      NZ,PTR_NEXT     ; back to PTR-NEXT if more.
        EX      DE,HL           ; transfer old value of STKEND to HL.
                                ; Note. this has always been updated.
        POP     DE              ; pop the address of the position.

        POP     AF              ; pop preserved accumulator.
        AND     A               ; clear carry flag preparing to subtract.

        SBC     HL,DE           ; subtract position from old stkend
        LD      B,H             ; to give number of data bytes
        LD      C,L             ; to be moved.
        INC     BC              ; increment as we also copy byte at old STKEND.
        ADD     HL,DE           ; recompute old stkend.
        EX      DE,HL           ; transfer to DE.
        RET                     ; return.



;;; @brief Collect line number
;;;
;;; This routine extracts a line number, at an address that has previously
;;; been found using LINE-ADDR, and it is entered at LINE-NO. If it encounters
;;; the program 'end-marker' then the previous line is used and if that
;;; should also be unacceptable then zero is used as it must be a direct
;;; command. The program end-marker is the variables end-marker $80, or
;;; if variables exist, then the first character of any variable name.
;;;
;;; ; LINE-ZERO
LINE_ZERO:
        DB          $00, $00        ; dummy line number used for direct commands


;;; @brief ; LINE-NO-A
;;;
;;; ; LINE-NO-A
;;; @jumpedfrom LINE_NO
;;; @fallthrough LINE_NO
LINE_NO_A:
        EX      DE,HL           ; fetch the previous line to HL and set
        LD      DE,LINE_ZERO    ; DE to LINE-ZERO should HL also fail.

; -> The Entry Point.

;;; @brief ; LINE-NO
;;;
;;; ; LINE-NO
;;; @jumps LINE_NO_A
;;; @calledby ED_EDIT, ED_UP, LN_FETCH
LINE_NO:
        LD      A,(HL)          ; fetch the high byte - max $2F
        AND     $C0             ; mask off the invalid bits.
        JR      NZ,LINE_NO_A    ; to LINE-NO-A if an end-marker.

        LD      D,(HL)          ; reload the high byte.
        INC     HL              ; advance address.
        LD      E,(HL)          ; pick up the low byte.
        RET                     ; return from here.

;;; @brief Handle reserve room
;;;
;;; This is a continuation of the restart BC-SPACES
;;;
;;; ; RESERVE
;;; @calls MAKE_ROOM
;;; @jumpedfrom BC_SPACES
RESERVE:
        LD      HL,(STKBOT)      ; STKBOT first location of calculator stack
        DEC     HL              ; make one less than new location
        CALL    MAKE_ROOM       ; routine MAKE-ROOM creates the room.
        INC     HL              ; address the first new location
        INC     HL              ; advance to second
        POP     BC              ; restore old WORKSP
        LD      (WORKSP),BC      ; system variable WORKSP was perhaps
                                ; changed by POINTERS routine.
        POP     BC              ; restore count for return value.
        EX      DE,HL           ; switch. DE = location after first new space
        INC     HL              ; HL now location after new space
        RET                     ; return.

;;; @brief Clear various editing areas
;;;
;;; This routine sets the editing area, workspace and calculator stack
;;; to their minimum configurations as at initialization and indeed this
;;; routine could have been relied on to perform that task.
;;; This routine uses HL only and returns with that register holding
;;; WORKSP/STKBOT/STKEND though no use is made of this. The routines also
;;; reset MEM to its usual place in the systems variable area should it
;;; have been relocated to a FOR-NEXT variable. The main entry point
;;; SET-MIN is called at the start of the MAIN-EXEC loop and prior to
;;; displaying an error.
;;;
;;; ; SET-MIN
;;; @calledby MAIN_EXEC
;;; @fallthrough SET_WORK
SET_MIN:
        LD      HL,(E_LINE)      ; fetch E_LINE
        LD      (HL),$0D        ; insert carriage return
        LD      (K_CUR),HL      ; make K_CUR keyboard cursor point there.
        INC     HL              ; next location
        LD      (HL),$80        ; holds end-marker $80
        INC     HL              ; next location becomes
        LD      (WORKSP),HL      ; start of WORKSP

; This entry point is used prior to input and prior to the execution,
; or parsing, of each statement.

;;; @brief ; SET-WORK
;;;
;;; ; SET-WORK
;;; @calledby STMT_L_1, IN_PROMPT
;;; @fallthrough SET_STK
SET_WORK:
        LD      HL,(WORKSP)      ; fetch WORKSP value
        LD      (STKBOT),HL      ; and place in STKBOT

; This entry point is used to move the stack back to its normal place
; after temporary relocation during line entry and also from ERROR-3

;;; @brief ; SET-STK
;;;
;;; ; SET-STK
;;; @jumpedfrom ERROR_3, E_L_1
SET_STK:
        LD      HL,(STKBOT)      ; fetch STKBOT value
        LD      (STKEND),HL      ; and place in STKEND.

        PUSH    HL              ; perhaps an obsolete entry point.
        LD      HL,MEM_0        ; normal location of MEM-0
        LD      (MEM),HL      ; is restored to system variable MEM.
        POP     HL              ; saved value not required.
        RET                     ; return.

;;; @brief Reclaim edit-line?
;;;
;;; This seems to be legacy code from the ZX80/ZX81 as it is
;;; not used in this ROM.
;;; That task, in fact, is performed here by the dual-area routine CLEAR-SP.
;;; This routine is designed to deal with something that is known to be in the
;;; edit buffer and not workspace.
;;; On entry, HL must point to the end of the something to be deleted.
;;;
;;; ; REC-EDIT
;;; @jumps RECLAIM_1
REC_EDIT:
        LD      DE,(E_LINE)      ; fetch start of edit line from E_LINE.
        JP      RECLAIM_1       ; jump forward to RECLAIM-1.

;;; @brief The Table INDEXING routine
;;;
;;; This routine is used to search two-byte hash tables for a character
;;; held in C, returning the address of the following offset byte.
;;; if it is known that the character is in the table e.g. for priorities,
;;; then the table requires no zero end-marker. If this is not known at the
;;; outset then a zero end-marker is required and carry is set to signal
;;; success.
;;;
;;; ; INDEXER-1
;;; @jumpedfrom INDEXER
;;; @fallthrough INDEXER
INDEXER_1:
        INC     HL              ; address the next pair of values.

; -> The Entry Point.

;;; @brief ; INDEXER
;;;
;;; ; INDEXER
;;; @jumps INDEXER_1
;;; @calledby CHAN_FLAG, ROM_TRAP, OPEN_3, S_LOOP_1, S_OPERTR
INDEXER:
        LD      A,(HL)          ; fetch the first byte of pair
        AND     A               ; is it the end-marker ?
        RET     Z               ; return with carry reset if so.

        CP      C               ; is it the required character ?
        INC     HL              ; address next location.
        JR      NZ,INDEXER_1    ; back to INDEXER-1 if no match.

        SCF                     ; else set the carry flag.
        RET                     ; return with carry set

; --------------------------------
; The Channel and Streams Routines
; --------------------------------
; A channel is an input/output route to a hardware device
; and is identified to the system by a single letter e.g. 'K' for
; the keyboard. A channel can have an input and output route
; associated with it in which case it is bi-directional like
; the keyboard. Others like the upper screen 'S' are output
; only and the input routine usually points to a report message.
; Channels 'K' and 'S' are system channels and it would be inappropriate
; to close the associated streams so a mechanism is provided to
; re-attach them. When the re-attachment is no longer required, then
; closing these streams resets them as at initialization.
; Early adverts said that the network and RS232 were in this ROM.
; Channels 'N' and 'B' are user channels and have been removed successfully
; if, as seems possible, they existed.
; Ironically the tape streamer is not accessed through streams and
; channels.
; Early demonstrations of the Spectrum showed a single microdrive being
; controlled by the main ROM.

;;; @brief THE 'CLOSE #' COMMAND
;;;
;;;   This command allows streams to be closed after use.
;;;   Any temporary memory areas used by the stream would be reclaimed and
;;;   finally flags set or reset if necessary.
;;;
;;; ; CLOSE
;;; @calls STR_DATA, CLOSE_2
;;; @jumps CLOSE_1
;;; @fallthrough CLOSE_1
CLOSE:
        CALL    STR_DATA           ; routine STR-DATA fetches parameter
                                ; from calculator stack and gets the
                                ; existing STRMS data pointer address in HL
                                ; and stream offset from CHANS in BC.

                                ; Note. this offset could be zero if the
                                ; stream is already closed. A check for this
                                ; should occur now and an error should be
                                ; generated, for example,
                                ; Report S 'Stream status closed'.

        CALL    CLOSE_2           ; routine CLOSE-2 would perform any actions
                                ; peculiar to that stream without disturbing
                                ; data pointer to STRMS entry in HL.

        LD      BC,$0000        ; the stream is to be blanked.
        LD      DE,$A3E2        ; the number of bytes from stream 4, $5C1E,
                                ; to $10000
        EX      DE,HL           ; transfer offset to HL, STRMS data pointer
                                ; to DE.
        ADD     HL,DE           ; add the offset to the data pointer.
        JR      C,CLOSE_1       ; forward to CLOSE-1 if a non-system stream.
                                ; i.e. higher than 3.

; proceed with a negative result.

        LD      BC,INIT_STRM + 14   ; prepare the address of the byte after
                                ; the initial stream data in ROM. ($15D4)
        ADD     HL,BC           ; index into the data table with negative value.
        LD      C,(HL)          ; low byte to C
        INC     HL              ; address next.
        LD      B,(HL)          ; high byte to B.

;   and for streams 0 - 3 just enter the initial data back into the STRMS entry
;   streams 0 - 2 can't be closed as they are shared by the operating system.
;   -> for streams 4 - 15 then blank the entry.

;;; @brief ; CLOSE-1
;;;
;;; ; CLOSE-1
;;; @jumpedfrom CLOSE
CLOSE_1:
        EX      DE,HL           ; address of stream to HL.
        LD      (HL),C          ; place zero (or low byte).
        INC     HL              ; next address.
        LD      (HL),B          ; place zero (or high byte).
        RET                     ; return.

;;; @brief THE 'CLOSE-2' SUBROUTINE
;;;
;;;   There is not much point in coming here.
;;;   The purpose was once to find the offset to a special closing routine,
;;;   in this ROM and within 256 bytes of the close stream look up table that
;;;   would reclaim any buffers associated with a stream. At least one has been
;;;   removed.
;;;   Any attempt to CLOSE streams $00 to $04, without first opening the stream,
;;;   will lead to either a system restart or the production of a strange report.
;;;   credit: Martin Wren-Hilton 1982.
;;;
;;; ; CLOSE-2
;;; @calledby CLOSE
;;; @fallthrough ROM_TRAP
CLOSE_2:
        PUSH    HL              ; * save address of stream data pointer
                                ; in STRMS on the machine stack.
        LD      HL,(CHANS)      ; fetch CHANS address to HL
        ADD     HL,BC           ; add the offset to address the second
                                ; byte of the output routine hopefully.
        INC     HL              ; step past
        INC     HL              ; the input routine.

;    Note. When the Sinclair Interface1 is fitted then an instruction fetch
;    on the next address pages this ROM out and the shadow ROM in.

;;; @brief ; ROM_TRAP
;;;
;;; ; ROM_TRAP
;;; @calls INDEXER
ROM_TRAP:
        INC     HL              ; to address channel's letter
        LD      C,(HL)          ; pick it up in C.
                                ; Note. but if stream is already closed we
                                ; get the value $10 (the byte preceding 'K').

        EX      DE,HL           ; save the pointer to the letter in DE.

;   Note. The string pointer is saved but not used!!

        LD      HL,CL_STR_LU      ; address: cl-str-lu in ROM.
        CALL    INDEXER           ; routine INDEXER uses the code to get
                                ; the 8-bit offset from the current point to
                                ; the address of the closing routine in ROM.
                                ; Note. it won't find $10 there!

        LD      C,(HL)          ; transfer the offset to C.
        LD      B,$00           ; prepare to add.
        ADD     HL,BC           ; add offset to point to the address of the
                                ; routine that closes the stream.
                                ; (and presumably removes any buffers that
                                ; are associated with it.)
        JP      (HL)            ; jump to that routine.

;;; @brief THE 'CLOSE STREAM LOOK-UP' TABLE
;;;
;;;   This table contains an entry for a letter found in the CHANS area.
;;;   followed by an 8-bit displacement, from that byte's address in the
;;;   table to the routine that performs any ancillary actions associated
;;;   with closing the stream of that channel.
;;;   The table doesn't require a zero end-marker as the letter has been
;;;   picked up from a channel that has an open stream.
;;;
;;; ; cl-str-lu
CL_STR_LU:
        DB          'K', CLOSE_STR-$-1  ; offset 5 to CLOSE-STR
        DB          'S', CLOSE_STR-$-1  ; offset 3 to CLOSE-STR
        DB          'P', CLOSE_STR-$-1  ; offset 1 to CLOSE-STR


;;; @brief THE 'CLOSE STREAM' SUBROUTINES
;;;
;;; The close stream routines in fact have no ancillary actions to perform
;;; which is not surprising with regard to 'K' and 'S'.
;;;
;;; ; CLOSE-STR
CLOSE_STR:
        POP     HL              ; * now just restore the stream data pointer
        RET                     ; in STRMS and return.

;;; @brief Stream data
;;;
;;; This routine finds the data entry in the STRMS area for the specified
;;; stream which is passed on the calculator stack. It returns with HL
;;; pointing to this system variable and BC holding a displacement from
;;; the CHANS area to the second byte of the stream's channel. If BC holds
;;; zero, then that signifies that the stream is closed.
;;;
;;; ; STR-DATA
;;; @calls FIND_INT1
;;; @jumps STR_DATA1
;;; @calledby CLOSE, OPEN
;;; @fallthrough REPORT_OB
STR_DATA:
        CALL    FIND_INT1           ; routine FIND-INT1 fetches parameter to A
        CP      $10                 ; is it less than 16d ?
        JR      C,STR_DATA1         ; skip forward to STR-DATA1 if so.

;;; @brief ; REPORT-Ob
;;;
;;; ; REPORT-Ob
;;; @jumpedfrom OPEN, CAT_ETC
REPORT_OB:
        RST     08H             ; ERROR-1
        DB          $17         ; Error Report: Invalid stream

;;; @brief ; STR-DATA1
;;;
;;; ; STR-DATA1
;;; @jumpedfrom STR_DATA
STR_DATA1:
        ADD     A,$03           ; add the offset for 3 system streams.
                                ; range 00 - 15d becomes 3 - 18d.
        RLCA                    ; double as there are two bytes per
                                ; stream - now 06 - 36d
        LD      HL,STRMS        ; address STRMS - the start of the streams
                                ; data area in system variables.
        LD      C,A             ; transfer the low byte to A.
        LD      B,$00           ; prepare to add offset.
        ADD     HL,BC           ; add to address the data entry in STRMS.

; the data entry itself contains an offset from CHANS to the address of the
; stream

        LD      C,(HL)          ; low byte of displacement to C.
        INC     HL              ; address next.
        LD      B,(HL)          ; high byte of displacement to B.
        DEC     HL              ; step back to leave HL pointing to STRMS
                                ; data entry.
        RET                     ; return with CHANS displacement in BC
                                ; and address of stream data entry in HL.

;;; @brief Handle OPEN# command
;;;
;;; Command syntax example: OPEN #5,"s"
;;; On entry the channel code entry is on the calculator stack with the next
;;; value containing the stream identifier. They have to swapped.
;;;
;;; ; OPEN
;;; @calls STR_DATA
;;; @jumps OPEN_1, REPORT_OB
;;; @fallthrough OPEN_1
OPEN:
        RST     28H                 ;; FP-CALC    ;s,c.
        DB          $01             ;;exchange    ;c,s.
        DB          $38             ;;end-calc

        CALL    STR_DATA           ; routine STR-DATA fetches the stream off
                                ; the stack and returns with the CHANS
                                ; displacement in BC and HL addressing
                                ; the STRMS data entry.
        LD      A,B             ; test for zero which
        OR      C               ; indicates the stream is closed.
        JR      Z,OPEN_1        ; skip forward to OPEN-1 if so.

; if it is a system channel then it can re-attached.

        EX      DE,HL           ; save STRMS address in DE.
        LD      HL,(CHANS)      ; fetch CHANS.
        ADD     HL,BC           ; add the offset to address the second
                                ; byte of the channel.
        INC     HL              ; skip over the
        INC     HL              ; input routine.
        INC     HL              ; and address the letter.
        LD      A,(HL)          ; pick up the letter.
        EX      DE,HL           ; save letter pointer and bring back
                                ; the STRMS pointer.

        CP      $4B             ; is it 'K' ?
        JR      Z,OPEN_1        ; forward to OPEN-1 if so

        CP      $53             ; is it 'S' ?
        JR      Z,OPEN_1        ; forward to OPEN-1 if so

        CP      $50             ; is it 'P' ?
        JR      NZ,REPORT_OB    ; back to REPORT-Ob if not.
                                ; to report 'Invalid stream'.

; continue if one of the upper-case letters was found.
; and rejoin here from above if stream was closed.

;;; @brief ; OPEN-1
;;;
;;; ; OPEN-1
;;; @calls OPEN_2
;;; @jumpedfrom OPEN
OPEN_1:
        CALL    OPEN_2           ; routine OPEN-2 opens the stream.

; it now remains to update the STRMS variable.

        LD      (HL),E          ; insert or overwrite the low byte.
        INC     HL              ; address high byte in STRMS.
        LD      (HL),D          ; insert or overwrite the high byte.
        RET                     ; return.

;;; @brief OPEN-2 Subroutine
;;;
;;; There is some point in coming here as, as well as once creating buffers,
;;; this routine also sets flags.
;;;
;;; ; OPEN-2
;;; @calls STK_FETCH
;;; @jumps OPEN_3
;;; @calledby OPEN_1
;;; @fallthrough REPORT_FB
OPEN_2:
        PUSH    HL              ; * save the STRMS data entry pointer.
        CALL    STK_FETCH       ; routine STK-FETCH now fetches the
                                ; parameters of the channel string.
                                ; start in DE, length in BC.

        LD      A,B             ; test that it is not
        OR      C               ; the null string.
        JR      NZ,OPEN_3       ; skip forward to OPEN-3 with 1 character
                                ; or more!

;;; @brief ; REPORT-Fb
;;;
;;; ; REPORT-Fb
;;; @jumpedfrom OPEN_3, OPEN_END
REPORT_FB:
        RST     08H             ; ERROR-1
        DB          $0E         ; Error Report: Invalid file name

;;; @brief ; OPEN-3
;;;
;;; ; OPEN-3
;;; @calls INDEXER
;;; @jumps REPORT_FB
;;; @jumpedfrom OPEN_2
OPEN_3:
        PUSH    BC              ; save the length of the string.
        LD      A,(DE)          ; pick up the first character.
                                ; Note. There can be more than one character.
        AND     $DF             ; make it upper-case.
        LD      C,A             ; place it in C.
        LD      HL,OP_STR_LU    ; address: op-str-lu is loaded.
        CALL    INDEXER         ; routine INDEXER will search for letter.
        JR      NC,REPORT_FB    ; back to REPORT-F if not found
                                ; 'Invalid filename'

        LD      C,(HL)          ; fetch the displacement to opening routine.
        LD      B,$00           ; prepare to add.
        ADD     HL,BC           ; now form address of opening routine.
        POP     BC              ; restore the length of string.
        JP      (HL)            ; now jump forward to the relevant routine.

;;; @brief OPEN stream look-up table
;;;
;;; The open stream look-up table consists of matched pairs.
;;; The channel letter is followed by an 8-bit displacement to the
;;; associated stream-opening routine in this ROM.
;;; The table requires a zero end-marker as the letter has been
;;; provided by the user and not the operating system.
;;;
;;; ; op-str-lu
OP_STR_LU:
        DB          'K', OPEN_K-$-1  ; $06 offset to OPEN-K
        DB          'S', OPEN_S-$-1  ; $08 offset to OPEN-S
        DB          'P', OPEN_P-$-1  ; $0A offset to OPEN-P

        DB          $00             ; end-marker.

; ----------------------------
; The Stream Opening Routines.
; ----------------------------
; These routines would have opened any buffers associated with the stream
; before jumping forward to OPEN-END with the displacement value in E
; and perhaps a modified value in BC. The strange pathing does seem to
; provide for flexibility in this respect.
;
; There is no need to open the printer buffer as it is there already
; even if you are still saving up for a ZX Printer or have moved onto
; something bigger. In any case it would have to be created after
; the system variables but apart from that it is a simple task
; and all but one of the ROM routines can handle a buffer in that position.
; (PR-ALL-6 would require an extra 3 bytes of code).
; However it wouldn't be wise to have two streams attached to the ZX Printer
; as you can now, so one assumes that if PR_CC_hi was non-zero then
; the OPEN-P routine would have refused to attach a stream if another
; stream was attached.

; Something of significance is being passed to these ghost routines in the
; second character. Strings 'RB', 'RT' perhaps or a drive/station number.
; The routine would have to deal with that and exit to OPEN_END with BC
; containing $0001 or more likely there would be an exit within the routine.
; Anyway doesn't matter, these routines are long gone.

;;; @brief OPEN-K Subroutine
;;;
;;; Open Keyboard stream.
;;;
;;; ; OPEN-K
;;; @jumps OPEN_END
OPEN_K:
        LD      E,$01           ; 01 is offset to second byte of channel 'K'.
        JR      OPEN_END        ; forward to OPEN-END

;;; @brief OPEN-S Subroutine
;;;
;;; Open Screen stream.
;;;
;;; ; OPEN-S
;;; @jumps OPEN_END
OPEN_S:
        LD      E,$06           ; 06 is offset to 2nd byte of channel 'S'
        JR      OPEN_END        ; to OPEN-END

;;; @brief OPEN-P Subroutine
;;;
;;; Open Printer stream.
;;;
;;; ; OPEN-P
;;; @fallthrough OPEN_END
OPEN_P:
        LD      E,$10           ; 16d is offset to 2nd byte of channel 'P'

;;; @brief ; OPEN-END
;;;
;;; ; OPEN-END
;;; @jumps REPORT_FB
;;; @jumpedfrom OPEN_K, OPEN_S
OPEN_END:
        DEC     BC              ; the stored length of 'K','S','P' or
                                ; whatever is now tested. ??
        LD      A,B             ; test now if initial or residual length
        OR      C               ; is one character.
        JR      NZ,REPORT_FB    ; to REPORT-Fb 'Invalid file name' if not.

        LD      D,A             ; load D with zero to form the displacement
                                ; in the DE register.
        POP     HL              ; * restore the saved STRMS pointer.
        RET                     ; return to update STRMS entry thereby
                                ; signaling stream is open.

;;; @brief Handle CAT, ERASE, FORMAT, MOVE commands
;;;
;;; These just generate an error report as the ROM is 'incomplete'.
;;;
;;; Luckily this provides a mechanism for extending these in a shadow ROM
;;; but without the powerful mechanisms set up in this ROM.
;;; An instruction fetch on $0008 may page in a peripheral ROM,
;;; e.g. the Sinclair Interface 1 ROM, to handle these commands.
;;; However that wasn't the plan.
;;; Development of this ROM continued for another three months until the cost
;;; of replacing it and the manual became unfeasible.
;;; The ultimate power of channels and streams died at birth.
;;;
;;; ; CAT-ETC
;;; @jumps REPORT_OB
CAT_ETC:
        JR      REPORT_OB           ; to REPORT-Ob

;;; @brief Perform AUTO-LIST
;;;
;;; This produces an automatic listing in the upper screen.
;;;
;;; ; AUTO-LIST
;;; @calls CL_ALL, CL_LINE, LINE_ADDR
;;; @jumps AUTO_L_2
;;; @calledby ED_LIST, MAIN_EXEC
;;; @fallthrough AUTO_L_1
AUTO_LIST:
        LD      (LIST_SP),SP      ; save stack pointer in LIST_SP
        LD      (IY+$02),$10    ; update TV_FLAG set bit 3
        CALL    CL_ALL          ; routine CL-ALL.
        SET     0,(IY+$02)      ; update TV_FLAG  - signal lower screen in use

        LD      B,(IY+$31)      ; fetch DF_SZ to B.
        CALL    CL_LINE         ; routine CL-LINE clears lower display
                                ; preserving B.
        RES     0,(IY+$02)      ; update TV_FLAG  - signal main screen in use
        SET     0,(IY+$30)      ; update FLAGS2 - signal will be necessary to
                                ; clear main screen.
        LD      HL,(E_PPC)      ; fetch E_PPC current edit line to HL.
        LD      DE,(S_TOP)      ; fetch S_TOP to DE, the current top line
                                ; (initially zero)
        AND     A               ; prepare for true subtraction.
        SBC     HL,DE           ; subtract and
        ADD     HL,DE           ; add back.
        JR      C,AUTO_L_2      ; to AUTO-L-2 if S_TOP higher than E_PPC
                                ; to set S_TOP to E_PPC

        PUSH    DE              ; save the top line number.
        CALL    LINE_ADDR       ; routine LINE-ADDR gets address of E_PPC.
        LD      DE,$02C0        ; prepare known number of characters in
                                ; the default upper screen.
        EX      DE,HL           ; offset to HL, program address to DE.
        SBC     HL,DE           ; subtract high value from low to obtain
                                ; negated result used in addition.
        EX      (SP),HL         ; swap result with top line number on stack.
        CALL    LINE_ADDR       ; routine LINE-ADDR  gets address of that
                                ; top line in HL and next line in DE.
        POP     BC              ; restore the result to balance stack.

;;; @brief ; AUTO-L-1
;;;
;;; ; AUTO-L-1
;;; @calls NEXT_ONE
;;; @jumps AUTO_L_3
AUTO_L_1:
        PUSH    BC              ; save the result.
        CALL    NEXT_ONE        ; routine NEXT-ONE gets address in HL of
                                ; line after auto-line (in DE).
        POP     BC              ; restore result.
        ADD     HL,BC           ; compute back.
        JR      C,AUTO_L_3      ; to AUTO-L-3 if line 'should' appear

        EX      DE,HL           ; address of next line to HL.
        LD      D,(HL)          ; get line
        INC     HL              ; number
        LD      E,(HL)          ; in DE.
        DEC     HL              ; adjust back to start.
        LD      (S_TOP),DE      ; update S_TOP.
        JR      AUTO_L_1        ; to AUTO-L-1 until estimate reached.

; ---

; the jump was to here if S_TOP was greater than E_PPC

;;; @brief ; AUTO-L-2
;;;
;;; ; AUTO-L-2
;;; @jumpedfrom AUTO_LIST
;;; @fallthrough AUTO_L_3
AUTO_L_2:
        LD      (S_TOP),HL      ; make S_TOP the same as E_PPC.

; continue here with valid starting point from above or good estimate
; from computation

;;; @brief ; AUTO-L-3
;;;
;;; ; AUTO-L-3
;;; @calls LINE_ADDR
;;; @jumps AUTO_L_4
;;; @jumpedfrom AUTO_L_1
;;; @fallthrough AUTO_L_4
AUTO_L_3:
        LD      HL,(S_TOP)      ; fetch S_TOP line number to HL.
        CALL    LINE_ADDR       ; routine LINE-ADDR gets address in HL.
                                ; address of next in DE.
        JR      Z,AUTO_L_4         ; to AUTO-L-4 if line exists.

        EX      DE,HL           ; else use address of next line.

;;; @brief ; AUTO-L-4
;;;
;;; ; AUTO-L-4
;;; @calls LIST_ALL
;;; @jumpedfrom AUTO_L_3
AUTO_L_4:
        CALL    LIST_ALL           ; routine LIST-ALL                >>>

; The return will be to here if no scrolling occurred

        RES     4,(IY+$02)      ; update TV_FLAG  - signal no auto listing.
        RET                     ; return.

;;; @brief Handle LLIST
;;;
;;; A short form of LIST #3. The listing goes to stream 3 - default printer.
;;;
;;; ; LLIST
;;; @jumps LIST_1
LLIST:
        LD      A,$03           ; the usual stream for ZX Printer
        JR      LIST_1          ; forward to LIST-1

;;; @brief Handle LIST
;;;
;;; List to any stream.
;;; Note. While a starting line can be specified it is
;;; not possible to specify an end line.
;;; Just listing a line makes it the current edit line.
;;;
;;; ; LIST
;;; @fallthrough LIST_1
LIST:
        LD      A,$02           ; default is stream 2 - the upper screen.

;;; @brief ; LIST-1
;;;
;;; ; LIST-1
;;; @calls SYNTAX_Z, CHAN_OPEN, STR_ALTER
;;; @jumps LIST_4, LIST_2, LIST_3
;;; @jumpedfrom LLIST
;;; @fallthrough LIST_2
LIST_1:
        LD      (IY+$02),$00    ; the TV_FLAG is initialized with bit 0 reset
                                ; indicating upper screen in use.
        CALL    SYNTAX_Z           ; routine SYNTAX-Z - checking syntax ?
        CALL    NZ,CHAN_OPEN       ; routine CHAN-OPEN if in run-time.

        RST     18H             ; GET-CHAR
        CALL    STR_ALTER       ; routine STR-ALTER will alter if '#'.
        JR      C,LIST_4        ; forward to LIST-4 not a '#' .


        RST     18H             ; GET-CHAR
        CP      $3B             ; is it ';' ?
        JR      Z,LIST_2        ; skip to LIST-2 if so.

        CP      $2C             ; is it ',' ?
        JR      NZ,LIST_3       ; forward to LIST-3 if neither separator.

; we have, say,  LIST #15, and a number must follow the separator.

;;; @brief ; LIST-2
;;;
;;; ; LIST-2
;;; @calls EXPT_1NUM
;;; @jumps LIST_5
;;; @jumpedfrom LIST_1
LIST_2:
        RST     20H             ; NEXT-CHAR
        CALL    EXPT_1NUM       ; routine EXPT-1NUM
        JR      LIST_5          ; forward to LIST-5

; ---

; the branch was here with just LIST #3 etc.

;;; @brief ; LIST-3
;;;
;;; ; LIST-3
;;; @calls USE_ZERO
;;; @jumps LIST_5
;;; @jumpedfrom LIST_1
LIST_3:
        CALL    USE_ZERO         ; routine USE-ZERO
        JR      LIST_5           ; forward to LIST-5

; ---

; the branch was here with LIST

;;; @brief ; LIST-4
;;;
;;; ; LIST-4
;;; @calls FETCH_NUM
;;; @jumpedfrom LIST_1
;;; @fallthrough LIST_5
LIST_4:
        CALL    FETCH_NUM           ; routine FETCH-NUM checks if a number
                                ; follows else uses zero.

;;; @brief ; LIST-5
;;;
;;; ; LIST-5
;;; @calls CHECK_END, FIND_INT2, LINE_ADDR
;;; @jumpedfrom LIST_2, LIST_3
;;; @fallthrough LIST_ALL
LIST_5:
        CALL    CHECK_END           ; routine CHECK-END quits if syntax OK >>>

        CALL    FIND_INT2           ; routine FIND-INT2 fetches the number
                                ; from the calculator stack in run-time.
        LD      A,B             ; fetch high byte of line number and
        AND     $3F             ; make less than $40 so that NEXT-ONE
                                ; (from LINE-ADDR) doesn't lose context.
                                ; Note. this is not satisfactory and the typo
                                ; LIST 20000 will list an entirely different
                                ; section than LIST 2000. Such typos are not
                                ; available for checking if they are direct
                                ; commands.

        LD      H,A             ; transfer the modified
        LD      L,C             ; line number to HL.
        LD      (E_PPC),HL      ; update E_PPC to new line number.
        CALL    LINE_ADDR       ; routine LINE-ADDR gets the address of the
                                ; line.

; This routine is called from AUTO-LIST

;;; @brief ; LIST-ALL
;;;
;;; ; LIST-ALL
;;; @calledby AUTO_L_4
;;; @fallthrough LIST_ALL_2
LIST_ALL:
        LD      E,$01           ; signal current line not yet printed

;;; @brief ; LIST-ALL-2
;;;
;;; ; LIST-ALL-2
;;; @calls OUT_LINE, LN_FETCH
LIST_ALL_2:
        CALL    OUT_LINE           ; routine OUT-LINE outputs a BASIC line
                                ; using PRINT-OUT and makes an early return
                                ; when no more lines to print. >>>

        RST     10H             ; PRINT-A prints the carriage return (in A)

        BIT     4,(IY+$02)      ; test TV_FLAG  - automatic listing ?
        JR      Z,LIST_ALL_2    ; back to LIST-ALL-2 if not
                                ; (loop exit is via OUT-LINE)

; continue here if an automatic listing required.

        LD      A,(DF_SZ)       ; fetch DF_SZ lower display file size.
        SUB     (IY+$4F)        ; subtract S_POSN_hi ithe current line number.
        JR      NZ,LIST_ALL_2   ; back to LIST-ALL-2 if upper screen not full.

        XOR     E               ; A contains zero, E contains one if the
                                ; current edit line has not been printed
                                ; or zero if it has (from OUT-LINE).
        RET     Z               ; return if the screen is full and the line
                                ; has been printed.

; continue with automatic listings if the screen is full and the current
; edit line is missing. OUT-LINE will scroll automatically.

        PUSH    HL              ; save the pointer address.
        PUSH    DE              ; save the E flag.
        LD      HL,S_TOP        ; fetch S_TOP the rough estimate.
        CALL    LN_FETCH        ; routine LN-FETCH updates S_TOP with
                                ; the number of the next line.
        POP     DE              ; restore the E flag.
        POP     HL              ; restore the address of the next line.
        JR      LIST_ALL_2      ; back to LIST-ALL-2.

;;; @brief Print a whole BASIC line
;;;
;;; This routine prints a whole BASIC line and it is called
;;; from LIST-ALL to output the line to current channel
;;; and from ED-EDIT to 'sprint' the line to the edit buffer.
;;;
;;; ; OUT-LINE
;;; @calls CP_LINES
;;; @jumps OUT_LINE1
;;; @calledby ED_EDIT, LIST_ALL_2
;;; @fallthrough OUT_LINE1
OUT_LINE:
        LD      BC,(E_PPC)      ; fetch E_PPC the current line which may be
                                ; unchecked and not exist.
        CALL    CP_LINES        ; routine CP-LINES finds match or line after.
        LD      D,$3E           ; prepare cursor '>' in D.
        JR      Z,OUT_LINE1     ; to OUT-LINE1 if matched or line after.

        LD      DE,$0000        ; put zero in D, to suppress line cursor.
        RL      E               ; pick up carry in E if line before current
                                ; leave E zero if same or after.

;;; @brief ; OUT-LINE1
;;;
;;; ; OUT-LINE1
;;; @calls OUT_NUM_2
;;; @jumps OUT_LINE3
;;; @jumpedfrom OUT_LINE
;;; @fallthrough OUT_LINE2
OUT_LINE1:
        LD      (IY+$2D),E      ; save flag in BREG which is spare.
        LD      A,(HL)          ; get high byte of line number.
        CP      $40             ; is it too high ($2F is maximum possible) ?
        POP     BC              ; drop the return address and
        RET     NC              ; make an early return if so >>>

        PUSH    BC              ; save return address
        CALL    OUT_NUM_2       ; routine OUT-NUM-2 to print addressed number
                                ; with leading space.
        INC     HL              ; skip low number byte.
        INC     HL              ; and the two
        INC     HL              ; length bytes.
        RES     0,(IY+$01)      ; update FLAGS - signal leading space required.
        LD      A,D             ; fetch the cursor.
        AND     A               ; test for zero.
        JR      Z,OUT_LINE3     ; to OUT-LINE3 if zero.


        RST     10H             ; PRINT-A prints '>' the current line cursor.

; this entry point is called from ED-COPY

;;; @brief ; OUT-LINE2
;;;
;;; ; OUT-LINE2
;;; @calledby L111D
;;; @fallthrough OUT_LINE3
OUT_LINE2:
        SET     0,(IY+$01)      ; update FLAGS - suppress leading space.

;;; @brief ; OUT-LINE3
;;;
;;; ; OUT-LINE3
;;; @jumps OUT_LINE4
;;; @jumpedfrom OUT_LINE1
;;; @fallthrough OUT_LINE4
OUT_LINE3:
        PUSH    DE              ; save flag E for a return value.
        EX      DE,HL           ; save HL address in DE.
        RES     2,(IY+$30)      ; update FLAGS2 - signal NOT in QUOTES.

        LD      HL,FLAGS        ; point to FLAGS.
        RES     2,(HL)          ; signal 'K' mode. (starts before keyword)
        BIT     5,(IY+$37)      ; test FLAGX - input mode ?
        JR      Z,OUT_LINE4     ; forward to OUT-LINE4 if not.

        SET     2,(HL)          ; signal 'L' mode. (used for input)

;;; @brief ; OUT-LINE4
;;;
;;; ; OUT-LINE4
;;; @calls OUT_FLASH
;;; @jumps OUT_LINE5
;;; @jumpedfrom OUT_LINE3
;;; @fallthrough OUT_LINE5
OUT_LINE4:
        LD      HL,(X_PTR)      ; fetch X_PTR - possibly the error pointer
                                ; address.
        AND     A               ; clear the carry flag.
        SBC     HL,DE           ; test if an error address has been reached.
        JR      NZ,OUT_LINE5    ; forward to OUT-LINE5 if not.

        LD      A,$3F           ; load A with '?' the error marker.
        CALL    OUT_FLASH       ; routine OUT-FLASH to print flashing marker.

;;; @brief ; OUT-LINE5
;;;
;;; ; OUT-LINE5
;;; @calls OUT_CURS, NUMBER
;;; @jumps OUT_LINE6
;;; @jumpedfrom OUT_LINE4
OUT_LINE5:
        CALL    OUT_CURS           ; routine OUT-CURS will print the cursor if
                                ; this is the right position.
        EX      DE,HL           ; restore address pointer to HL.
        LD      A,(HL)          ; fetch the addressed character.
        CALL    NUMBER          ; routine NUMBER skips a hidden floating
                                ; point number if present.
        INC     HL              ; now increment the pointer.
        CP      $0D             ; is character end-of-line ?
        JR      Z,OUT_LINE6     ; to OUT-LINE6, if so, as line is finished.

        NOP                             ; no operation
        LD      B,(HL)                  ; B = (HL)
        EX      DE,HL                   ; swap DE and HL
        JP      L04B9                   ; jump to L04B9

; ---

;;; @brief ; OUT-LINE6
;;;
;;; ; OUT-LINE6
;;; @jumpedfrom OUT_LINE5
OUT_LINE6:
        POP     DE              ; bring back the flag E, zero if current
                                ; line printed else 1 if still to print.
        RET                     ; return with A holding $0D

;;; @brief Check for a number marker
;;;
;;; this subroutine is called from two processes. while outputting BASIC lines
;;; and while searching statements within a BASIC line.
;;; during both, this routine will pass over an invisible number indicator
;;; and the five bytes floating-point number that follows it.
;;; Note that this causes floating point numbers to be stripped from
;;; the BASIC line when it is fetched to the edit buffer by OUT_LINE.
;;; the number marker also appears after the arguments of a DEF FN statement
;;; and may mask old 5-byte string parameters.
;;;
;;; ; NUMBER
;;; @calledby OUT_LINE5, EACH_S_3
NUMBER:
        CP      $0E             ; character fourteen ?
        RET     NZ              ; return if not.

        INC     HL              ; skip the character
        INC     HL              ; and five bytes
        INC     HL              ; following.
        INC     HL              ;
        INC     HL              ;
        INC     HL              ;
        LD      A,(HL)          ; fetch the following character
        RET                     ; for return value.

;;; @brief Print a flashing character
;;;
;;; This subroutine is called from OUT-LINE to print a flashing error
;;; marker '?' or from the next routine to print a flashing cursor e.g. 'L'.
;;; However, this only gets called from OUT-LINE when printing the edit line
;;; or the input buffer to the lower screen so a direct call to $09F4 can
;;; be used, even though out-line outputs to other streams.
;;; In fact the alternate set is used for the whole routine.
;;;
;;; ; OUT-FLASH
;;; @calls RTL_PO_FETCH_EXT
;;; @calledby OUT_LINE4, OUT_CURS
OUT_FLASH:
        EXX                     ; switch in alternate set

        LD      HL,(ATTR_T)      ; fetch L = ATTR_T, H = MASK-T
        PUSH    HL              ; save masks.
        RES     7,H             ; reset flash mask bit so active.
        SET     7,L             ; make attribute FLASH.
        LD      (ATTR_T),HL      ; resave ATTR_T and MASK-T

        LD      HL,P_FLAG        ; address P_FLAG
        LD      D,(HL)          ; fetch to D
        PUSH    DE              ; and save.
        LD      (HL),$00        ; clear inverse, over, ink/paper 9

        CALL    RTL_PO_FETCH_EXT           ; routine PRINT-OUT outputs character
                                ; without the need to vector via RST 10.

        POP     HL              ; pop P_FLAG to H.
        LD      (IY+$57),H      ; and restore system variable P_FLAG.
        POP     HL              ; restore temporary masks
        LD      (ATTR_T),HL      ; and restore system variables ATTR_T/MASK_T

        EXX                     ; switch back to main set
        RET                     ; return

;;; @brief Print the cursor
;;;
;;; This routine is called before any character is output while outputting
;;; a BASIC line or the input buffer. This includes listing to a printer
;;; or screen, copying a BASIC line to the edit buffer and printing the
;;; input buffer or edit buffer to the lower screen. It is only in the
;;; latter two cases that it has any relevance and in the last case it
;;; performs another very important function also.
;;;
;;; ; OUT-CURS
;;; @calls RTL_MODE_TOGGLE, OUT_FLASH
;;; @calledby L111D, OUT_LINE5
OUT_CURS:
        LD      HL,(K_CUR)      ; fetch K_CUR the current cursor address
        AND     A               ; prepare for true subtraction.
        SBC     HL,DE           ; test against pointer address in DE and
        RET     NZ              ; return if not at exact position.

; the value of MODE, maintained by KEY-INPUT, is tested and if non-zero
; then this value 'E' or 'G' will take precedence.


                                ; or 'G' if originally 2.

; ---

; If mode was zero then, while printing a BASIC line, bit 2 of flags has been
; set if 'THEN' or ':' was encountered as a main character and reset otherwise.
; This is now used to determine if the 'K' cursor is to be printed but this
; transient state is also now transferred permanently to bit 3 of FLAGS
; to let the interrupt routine know how to decode the next key.

;; OUT-C-1
                                ; previous main character ':' or 'THEN' ?

                                ; Note. transient bit has been made permanent.

                                ; which is maintained by KEY-INPUT.


;; OUT-C-2
                                ; uses alternate set without RST 10.

;==========================================================================
; OUT-CURSOR / mode-letter indicator rewrite -- $18E8-$190C
;   Original OUT-CURS printed a single letter to show the current
;   keyboard mode: 'K','L','C','E','G' (K-cursor, L-cursor, Caps,
;   Extended, Graphics). The patched version starts with a new call to
;   $3888 (a tiny helper, see the free-space listing at $386E onward)
;   which manipulates a flag in FLAGS ($5C3B) bit 6/TV_FLAG-style state,
;   then computes the letter to print via "LD HL,$1908; ADD A,L; LD L,A;
;   LD A,(HL)" -- i.e. it now indexes into a small in-line lookup table
;   of mode-letter characters at $1908 rather than using the original
;   chain of CP/JR comparisons. This is consistent with simply adding
;   one or two extra keyboard-mode letters (for an Arabic input mode)
;   to the standard K/L/C/E/G set, without needing to touch the letters
;   choice logic itself.
;==========================================================================
        CALL    RTL_MODE_TOGGLE        ; call RTL_MODE_TOGGLE
        LD      A,(MODE)               ; A = (MODE)
        AND     A                       ; A = A AND A
        JR      NZ,RTL_OUT_CURS_HOOK   ; if not zero, jump to RTL_OUT_CURS_HOOK
        DEC     HL                      ; HL = HL - 1
        RES     3,(HL)                  ; clear bit 3 of (HL)
        BIT     2,(HL)                  ; test bit 2 of (HL)
        JR      Z,RTL_OUT_CURS_HOOK    ; if zero, jump to RTL_OUT_CURS_HOOK
        SET     3,(HL)                  ; set bit 3 of (HL)
        LD      A,3                     ; A = 3
RTL_OUT_CURS_HOOK:
        LD      HL,LANG_CURS_TABLE      ; HL = cursor letter table
        ADD     A,L                     ; A = A + L
        LD      L,A                     ; L = A
        LD      A,(HL)                  ; A = (HL)
        PUSH    DE                      ; push DE onto the stack
        CALL    OUT_FLASH               ; call OUT_FLASH
        POP     DE                      ; pop DE off the stack
        RET                             ; return
LANG_CURS_TABLE:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/cursor_letters.asm"
        ELSE
        INCLUDE "lang/arabic/cursor_letters.asm"
        ENDIF
L1909 EQU LANG_CURS_TABLE + 1
L18F3   EQU    $18F3                  ; this address now falls inside the block above (label kept for reference)

        POP     DE              ; restore and
        RET                     ; return.

;;; @brief Get line number of next line
;;;
;;; These two subroutines are called while editing.
;;; This entry point is from ED-DOWN with HL addressing E_PPC
;;; to fetch the next line number.
;;; Also from AUTO-LIST with HL addressing S_TOP just to update S_TOP
;;; with the value of the next line number. It gets fetched but is discarded.
;;; These routines never get called while the editor is being used for input.
;;;
;;; ; LN-FETCH
;;; @calls LINE_ADDR, LINE_NO
;;; @calledby ED_DOWN, LIST_ALL_2
;;; @fallthrough LN_STORE
LN_FETCH:
        LD      E,(HL)          ; fetch low byte
        INC     HL              ; address next
        LD      D,(HL)          ; fetch high byte.
        PUSH    HL              ; save system variable hi pointer.
        EX      DE,HL           ; line number to HL,
        INC     HL              ; increment as a starting point.
        CALL    LINE_ADDR       ; routine LINE-ADDR gets address in HL.
        CALL    LINE_NO         ; routine LINE-NO gets line number in DE.
        POP     HL              ; restore system variable hi pointer.

; This entry point is from the ED-UP with HL addressing E_PPC_hi

;;; @brief ; LN-STORE
;;;
;;; ; LN-STORE
;;; @calledby ED_UP
LN_STORE:
        BIT     5,(IY+$37)      ; test FLAGX - input mode ?
        RET     NZ              ; return if so.
                                ; Note. above already checked by ED-UP/ED-DOWN.

        LD      (HL),D          ; save high byte of line number.
        DEC     HL              ; address lower
        LD      (HL),E          ; save low byte of line number.
        RET                     ; return.

;;; @brief Outputting numbers at start of BASIC line
;;;
;;; This routine entered at OUT-SP-NO is used to compute then output the first
;;; three digits of a 4-digit BASIC line printing a space if necessary.
;;; The line number, or residual part, is held in HL and the BC register
;;; holds a subtraction value -1000, -100 or -10.
;;; Note. for example line number 200 -
;;; space(out_char), 2(out_code), 0(out_char) final number always out-code.
;;;
;;; ; OUT-SP-2
;;; @jumps OUT_CHAR
;;; @jumpedfrom OUT_SP_1
OUT_SP_2:
        LD      A,E             ; will be space if OUT-CODE not yet called.
                                ; or $FF if spaces are suppressed.
                                ; else $30 ('0').
                                ; (from the first instruction at OUT-CODE)
                                ; this guy is just too clever.
        AND     A               ; test bit 7 of A.
        RET     M               ; return if $FF, as leading spaces not
                                ; required. This is set when printing line
                                ; number and statement in MAIN-5.

        JR      OUT_CHAR           ; forward to exit via OUT-CHAR.

; ---

; -> the single entry point.

;;; @brief ; OUT-SP-NO
;;;
;;; ; OUT-SP-NO
;;; @calledby L1A30
;;; @fallthrough OUT_SP_1
OUT_SP_NO:
        XOR     A               ; initialize digit to 0

;;; @brief ; OUT-SP-1
;;;
;;; ; OUT-SP-1
;;; @jumps OUT_SP_2, OUT_CODE
OUT_SP_1:
        ADD     HL,BC           ; add negative number to HL.
        INC     A               ; increment digit
        JR      C,OUT_SP_1      ; back to OUT-SP-1 until no carry from
                                ; the addition.

        SBC     HL,BC           ; cancel the last addition
        DEC     A               ; and decrement the digit.
        JR      Z,OUT_SP_2      ; back to OUT-SP-2 if it is zero.

        JP      OUT_CODE           ; jump back to exit via OUT-CODE.    ->


;;; @brief Outputting characters in a BASIC line
;;;
;;; This subroutine ...
;;;
;;; ; OUT-CHAR
;;; @calls NUMERIC
;;; @jumps OUT_CH_3, OUT_CH_1, OUT_CH_2
;;; @jumpedfrom OUT_SP_2
OUT_CHAR:
        CALL    NUMERIC           ; routine NUMERIC tests if it is a digit ?
        JR      NC,OUT_CH_3       ; to OUT-CH-3 to print digit without
                                ; changing mode. Will be 'K' mode if digits
                                ; are at beginning of edit line.

        CP      $21             ; less than quote character ?
        JR      C,OUT_CH_3      ; to OUT-CH-3 to output controls and space.

        RES     2,(IY+$01)      ; initialize FLAGS to 'K' mode and leave
                                ; unchanged if this character would precede
                                ; a keyword.

        CP      $CB             ; is character 'THEN' token ?
        JR      Z,OUT_CH_3      ; to OUT-CH-3 to output if so.

        CP      $3A             ; is it ':' ?
        JR      NZ,OUT_CH_1     ; to OUT-CH-1 if not statement separator
                                ; to change mode back to 'L'.

        BIT     5,(IY+$37)      ; FLAGX  - Input Mode ??
        JR      NZ,OUT_CH_2     ; to OUT-CH-2 if in input as no statements.
                                ; Note. this check should seemingly be at
                                ; the start. Commands seem inappropriate in
                                ; INPUT mode and are rejected by the syntax
                                ; checker anyway.
                                ; unless INPUT LINE is being used.

        BIT     2,(IY+$30)      ; test FLAGS2 - is the ':' within quotes ?
        JR      Z,OUT_CH_3      ; to OUT-CH-3 if ':' is outside quoted text.

        JR      OUT_CH_2           ; to OUT-CH-2 as ':' is within quotes

; ---

;;; @brief ; OUT-CH-1
;;;
;;; ; OUT-CH-1
;;; @jumps OUT_CH_2
;;; @jumpedfrom OUT_CHAR
;;; @fallthrough OUT_CH_2
OUT_CH_1:
        CP      $22             ; is it quote character '"'  ?
        JR      NZ,OUT_CH_2     ; to OUT-CH-2 with others to set 'L' mode.

        PUSH    AF              ; save character.
        LD      A,(FLAGS2)       ; fetch FLAGS2.
        XOR     $04             ; toggle the quotes flag.
        LD      (FLAGS2),A       ; update FLAGS2
        POP     AF              ; and restore character.

;;; @brief ; OUT-CH-2
;;;
;;; ; OUT-CH-2
;;; @jumpedfrom OUT_CHAR, OUT_CH_1
;;; @fallthrough OUT_CH_3
OUT_CH_2:
        SET     2,(IY+$01)      ; update FLAGS - signal L mode if the cursor
                                ; is next.

;;; @brief ; OUT-CH-3
;;;
;;; ; OUT-CH-3
;;; @jumpedfrom OUT_CHAR
OUT_CH_3:
        RST     10H             ; PRINT-A vectors the character to
                                ; channel 'S', 'K', 'R' or 'P'.
        RET                     ; return.

;;; @brief Get starting address of line, or line after
;;;
;;; This routine is used often to get the address, in HL, of a BASIC line
;;; number supplied in HL, or failing that the address of the following line
;;; and the address of the previous line in DE.
;;;
;;; ; LINE-ADDR
;;; @calledby ED_EDIT, ED_UP, MAIN_ADD, AUTO_LIST, AUTO_L_3, LIST_5, LN_FETCH, LINE_NEW, REST_RUN
;;; @fallthrough LINE_AD_1
LINE_ADDR:
        PUSH    HL              ; save line number in HL register
        LD      HL,(PROG)      ; fetch start of program from PROG
        LD      D,H             ; transfer address to
        LD      E,L             ; the DE register pair.

;;; @brief ; LINE-AD-1
;;;
;;; ; LINE-AD-1
;;; @calls CP_LINES, NEXT_ONE
LINE_AD_1:
        POP     BC              ; restore the line number to BC
        CALL    CP_LINES        ; routine CP-LINES compares with that
                                ; addressed by HL
        RET     NC              ; return if line has been passed or matched.
                                ; if NZ, address of previous is in DE

        PUSH    BC              ; save the current line number
        CALL    NEXT_ONE        ; routine NEXT-ONE finds address of next
                                ; line number in DE, previous in HL.
        EX      DE,HL           ; switch so next in HL
        JR      LINE_AD_1       ; back to LINE-AD-1 for another comparison

;;; @brief Compare line numbers
;;;
;;; This routine compares a line number supplied in BC with an addressed
;;; line number pointed to by HL.
;;;
;;; ; CP-LINES
;;; @calledby OUT_LINE, LINE_AD_1
CP_LINES:
        LD      A,(HL)          ; Load the high byte of line number and
        CP      B               ; compare with that of supplied line number.
        RET     NZ              ; return if yet to match (carry will be set).

        INC     HL              ; address low byte of
        LD      A,(HL)          ; number and pick up in A.
        DEC     HL              ; step back to first position.
        CP      C               ; now compare.
        RET                     ; zero set if exact match.
                                ; carry set if yet to match.
                                ; no carry indicates a match or
                                ; next available BASIC line or
                                ; program end marker.

;;; @brief Find each statement
;;;
;;; The single entry point EACH-STMT is used to
;;; 1) To find the D'th statement in a line.
;;; 2) To find a token in held E.
;;;
;;; ; not-used
;;; @fallthrough EACH_STMT
NOT_USED:
        INC     HL              ;
        INC     HL              ;
        INC     HL              ;

; -> entry point.

;;; @brief ; EACH-STMT
;;;
;;; ; EACH-STMT
;;; @calledby NEXT_LINE, LOOK_P_2, SF_NOT_FD
;;; @jumpedfrom PASS_BY
;;; @fallthrough EACH_S_1
EACH_STMT:
        LD      (CH_ADD),HL      ; save HL in CH_ADD
        LD      C,$00           ; initialize quotes flag

;;; @brief ; EACH-S-1
;;;
;;; ; EACH-S-1
;;; @jumps EACH_S_3
;;; @jumpedfrom EACH_S_5
EACH_S_1:
        DEC     D               ; decrease statement count
        RET     Z               ; return if zero


        RST     20H             ; NEXT-CHAR
        CP      E               ; is it the search token ?
        JR      NZ,EACH_S_3     ; forward to EACH-S-3 if not

        AND     A               ; clear carry
        RET                     ; return signalling success.

; ---

;;; @brief ; EACH-S-2
;;;
;;; ; EACH-S-2
;;; @jumpedfrom EACH_S_6
;;; @fallthrough EACH_S_3
EACH_S_2:
        INC     HL              ; next address
        LD      A,(HL)          ; next character

;;; @brief ; EACH-S-3
;;;
;;; ; EACH-S-3
;;; @calls NUMBER
;;; @jumps EACH_S_4
;;; @jumpedfrom EACH_S_1
;;; @fallthrough EACH_S_4
EACH_S_3:
        CALL    NUMBER          ; routine NUMBER skips if number marker
        LD      (CH_ADD),HL      ; save in CH_ADD
        CP      $22             ; is it quotes '"' ?
        JR      NZ,EACH_S_4     ; to EACH-S-4 if not

        DEC     C               ; toggle bit 0 of C

;;; @brief ; EACH-S-4
;;;
;;; ; EACH-S-4
;;; @jumps EACH_S_5, EACH_S_6
;;; @jumpedfrom EACH_S_3
;;; @fallthrough EACH_S_5
EACH_S_4:
        CP      $3A             ; is it ':'
        JR      Z,EACH_S_5      ; to EACH-S-5

        CP      $CB             ; 'THEN'
        JR      NZ,EACH_S_6     ; to EACH-S-6

;;; @brief ; EACH-S-5
;;;
;;; ; EACH-S-5
;;; @jumps EACH_S_1
;;; @jumpedfrom EACH_S_4
;;; @fallthrough EACH_S_6
EACH_S_5:
        BIT     0,C             ; is it in quotes
        JR      Z,EACH_S_1      ; to EACH-S-1 if not

;;; @brief ; EACH-S-6
;;;
;;; ; EACH-S-6
;;; @jumps EACH_S_2
;;; @jumpedfrom EACH_S_4
EACH_S_6:
        CP      $0D             ; end of line ?
        JR      NZ,EACH_S_2     ; to EACH-S-2

        DEC     D               ; decrease the statement counter
                                ; which should be zero else
                                ; 'Statement Lost'.
        SCF                     ; set carry flag - not found
        RET                     ; return

; -----------------------------------------------------------------------
; Storage of variables. For full details - see chapter 24.
; ZX Spectrum BASIC Programming by Steven Vickers 1982.
; It is bits 7-5 of the first character of a variable that allow
; the six types to be distinguished. Bits 4-0 are the reduced letter.
; So any variable name is higher that $3F and can be distinguished
; also from the variables area end-marker $80.
;
; 76543210 meaning                               brief outline of format.
; -------- ------------------------              -----------------------
; 010      string variable.                      2 byte length + contents.
; 110      string array.                         2 byte length + contents.
; 100      array of numbers.                     2 byte length + contents.
; 011      simple numeric variable.              5 bytes.
; 101      variable length named numeric.        5 bytes.
; 111      for-next loop variable.               18 bytes.
; 10000000 the variables area end-marker.
;
; Note. any of the above seven will serve as a program end-marker.
;
; -----------------------------------------------------------------------

;;; @brief Get next one
;;;
;;; This versatile routine is used to find the address of the next line
;;; in the program area or the next variable in the variables area.
;;; The reason one routine is made to handle two apparently unrelated tasks
;;; is that it can be called indiscriminately when merging a line or a
;;; variable.
;;;
;;; ; NEXT-ONE
;;; @jumps NEXT_O_3, NEXT_O_4, NEXT_O_1
;;; @calledby ME_CONTRL, ME_ENTER, MAIN_ADD, AUTO_L_1, LINE_AD_1, V_NEXT, D_RUN
;;; @fallthrough NEXT_O_1
NEXT_ONE:
        PUSH    HL              ; save the pointer address.
        LD      A,(HL)          ; get first byte.
        CP      $40             ; compare with upper limit for line numbers.
        JR      C,NEXT_O_3      ; forward to NEXT-O-3 if within BASIC area.

; the continuation here is for the next variable unless the supplied
; line number was erroneously over 16383. see RESTORE command.

        BIT     5,A             ; is it a string or an array variable ?
        JR      Z,NEXT_O_4      ; forward to NEXT-O-4 to compute length.

        ADD     A,A             ; test bit 6 for single-character variables.
        JP      M,NEXT_O_1      ; forward to NEXT-O-1 if so

        CCF                     ; clear the carry for long-named variables.
                                ; it remains set for for-next loop variables.

;;; @brief ; NEXT-O-1
;;;
;;; ; NEXT-O-1
;;; @jumps NEXT_O_2
;;; @jumpedfrom NEXT_ONE
;;; @fallthrough NEXT_O_2
NEXT_O_1:
        LD      BC,$0005        ; set BC to 5 for floating point number
        JR      NC,NEXT_O_2     ; forward to NEXT-O-2 if not a for/next
                                ; variable.

        LD      C,$12           ; set BC to eighteen locations.
                                ; value, limit, step, line and statement.

; now deal with long-named variables

;;; @brief ; NEXT-O-2
;;;
;;; ; NEXT-O-2
;;; @jumps NEXT_O_5
;;; @jumpedfrom NEXT_O_1
NEXT_O_2:
        RLA                     ; test if character inverted. carry will also
                                ; be set for single character variables
        INC     HL              ; address next location.
        LD      A,(HL)          ; and load character.
        JR      NC,NEXT_O_2     ; back to NEXT-O-2 if not inverted bit.
                                ; forward immediately with single character
                                ; variable names.

        JR      NEXT_O_5           ; forward to NEXT-O-5 to add length of
                                ; floating point number(s etc.).

; ---

; this branch is for line numbers.

;;; @brief ; NEXT-O-3
;;;
;;; ; NEXT-O-3
;;; @jumpedfrom NEXT_ONE
;;; @fallthrough NEXT_O_4
NEXT_O_3:
        INC     HL              ; increment pointer to low byte of line no.

; strings and arrays rejoin here

;;; @brief ; NEXT-O-4
;;;
;;; ; NEXT-O-4
;;; @jumpedfrom NEXT_ONE
;;; @fallthrough NEXT_O_5
NEXT_O_4:
        INC     HL              ; increment to address the length low byte.
        LD      C,(HL)          ; transfer to C and
        INC     HL              ; point to high byte of length.
        LD      B,(HL)          ; transfer that to B
        INC     HL              ; point to start of BASIC/variable contents.

; the three types of numeric variables rejoin here

;;; @brief ; NEXT-O-5
;;;
;;; ; NEXT-O-5
;;; @jumpedfrom NEXT_O_2
;;; @fallthrough DIFFER
NEXT_O_5:
        ADD     HL,BC           ; add the length to give address of next
                                ; line/variable in HL.
        POP     DE              ; restore previous address to DE.

;;; @brief Difference routine
;;;
;;; This routine terminates the above routine and is also called from the
;;; start of the next routine to calculate the length to reclaim.
;;;
;;; ; DIFFER
;;; @calledby RECLAIM_1
DIFFER:
        AND     A               ; prepare for true subtraction.
        SBC     HL,DE           ; subtract the two pointers.
        LD      B,H             ; transfer result
        LD      C,L             ; to BC register pair.
        ADD     HL,DE           ; add back
        EX      DE,HL           ; and switch pointers
        RET                     ; return values are the length of area in BC,
                                ; low pointer (previous) in HL,
                                ; high pointer (next) in DE.

;;; @brief Handle reclaiming space
;;;
;;; ; RECLAIM-1
;;; @calls DIFFER
;;; @calledby LD_CONTRL, CLEAR_SP, CLEAR_1
;;; @jumpedfrom REC_EDIT
;;; @fallthrough RECLAIM_2
RECLAIM_1:
        CALL    DIFFER           ; routine DIFFER immediately above

;;; @brief ; RECLAIM-2
;;;
;;; ; RECLAIM-2
;;; @calls POINTERS
;;; @calledby LD_CONTRL, ME_ENTER, REMOVE_FP, MAIN_ADD, D_RUN
;;; @jumpedfrom ED_DELETE, L_ADD
RECLAIM_2:
        PUSH    BC              ;

        LD      A,B             ;
        CPL                     ;
        LD      B,A             ;
        LD      A,C             ;
        CPL                     ;
        LD      C,A             ;
        INC     BC              ;

        CALL    POINTERS        ; routine POINTERS
        EX      DE,HL           ;
        POP     HL              ;

        ADD     HL,DE           ;
        PUSH    DE              ;
        LDIR                    ; copy bytes

        POP     HL              ;
        RET                     ;

;;; @brief Read line number of line in editing area
;;;
;;; This routine reads a line number in the editing area returning the number
;;; in the BC register or zero if no digits exist before commands.
;;; It is called from LINE-SCAN to check the syntax of the digits.
;;; It is called from MAIN-3 to extract the line number in preparation for
;;; inclusion of the line in the BASIC program area.
;;;
;;; Interestingly the calculator stack is moved from its normal place at the
;;; end of dynamic memory to an adequate area within the system variables area.
;;; This ensures that in a low memory situation, that valid line numbers can
;;; be extracted without raising an error and that memory can be reclaimed
;;; by deleting lines. If the stack was in its normal place then a situation
;;; arises whereby the Spectrum becomes locked with no means of reclaiming space.
;;;
;;; ; E-LINE-NO
;;; @calls L13FC
;;; @jumps E_L_1
;;; @calledby MAIN_EXEC, LINE_SCAN
;;; @fallthrough E_L_1
E_LINE_NO:
        LD      HL,(E_LINE)      ; load HL from system variable E_LINE.

        DEC     HL              ; decrease so that NEXT_CHAR can be used
                                ; without skipping the first digit.

        LD      (CH_ADD),HL      ; store in the system variable CH_ADD.

        RST     20H             ; NEXT-CHAR skips any noise and white-space
                                ; to point exactly at the first digit.

                                ; an overhead of three locations are needed.

                                ; a non-digit found.
                                ; from stack at membot.
        LD      BC,0                    ; BC = 0
        CALL    L13FC                   ; call L13FC
        JR      C,E_L_1                 ; if carry, jump to E_L_1
        LD      B,H                     ; B = H
        LD      C,L                     ; C = L
        NOP                             ; no operation
        NOP                             ; no operation
        NOP                             ; no operation
        NOP                             ; no operation
                                ; 'Nonsense in BASIC'

        LD      HL,$D8F0        ; load HL with value -9999
        ADD     HL,BC           ; add to line number in BC

;;; @brief ; E-L-1
;;;
;;; ; E-L-1
;;; @jumps REPORT_C, SET_STK
;;; @jumpedfrom E_LINE_NO
E_L_1:
        JP      C,REPORT_C         ; to REPORT-C 'Nonsense in BASIC' if over.
                                ; Note. As ERR_SP points to ED_ERROR
                                ; the report is never produced although
                                ; the RST $08 will update X_PTR leading to
                                ; the error marker being displayed when
                                ; the ED_LOOP is reiterated.
                                ; in fact, since it is immediately
                                ; cancelled, any report will do.

; a line in the range 0 - 9999 has been entered.

        JP      SET_STK           ; jump back to SET-STK to set the calculator
                                ; stack back to its normal place and exit
                                ; from there.

;;; @brief Report and line number outputting
;;;
;;; Entry point OUT-NUM-1 is used by the Error Reporting code to print
;;; the line number and later the statement number held in BC.
;;; If the statement was part of a direct command then -2 is used as a
;;; dummy line number so that zero will be printed in the report.
;;; This routine is also used to print the exponent of E-format numbers.
;;;
;;; Entry point OUT-NUM-2 is used from OUT-LINE to output the line number
;;; addressed by HL with leading spaces if necessary.
;;;
;;; ; OUT-NUM-1
;;; @jumps OUT_NUM_4, L1A30
;;; @calledby MAIN_EXEC
;;; @jumpedfrom PF_E_SIGN
OUT_NUM_1:
        PUSH    DE              ; save the
        PUSH    HL              ; registers.
        XOR     A               ; set A to zero.
        BIT     7,B             ; is the line number minus two ?
        JR      NZ,OUT_NUM_4    ; forward to OUT-NUM-4 if so to print zero
                                ; for a direct command.

        LD      H,B             ; transfer the
        LD      L,C             ; number to HL.
        LD      E,$FF           ; signal 'no leading zeros'.
        JR      L1A30           ; forward to continue at OUT-NUM-3

; ---

; from OUT-LINE - HL addresses line number.

;;; @brief ; OUT-NUM-2
;;;
;;; ; OUT-NUM-2
;;; @calledby OUT_LINE1
;;; @fallthrough L1A30
OUT_NUM_2:
        PUSH    DE              ; save flags
        LD      D,(HL)          ; high byte to D
        INC     HL              ; address next
        LD      E,(HL)          ; low byte to E
        PUSH    HL              ; save pointer
        EX      DE,HL           ; transfer number to HL
        LD      E,$20           ; signal 'output leading spaces'

;;; @brief ; OUT-NUM-3
;;;
;;; ; OUT-NUM-3
;;; @address $1A30
;;; @calls OUT_SP_NO
;;; @jumps L1436
;;; @jumpedfrom OUT_NUM_1
;;; @fallthrough OUT_NUM_4
L1A30:
        JP      L1436           ; jump to L1436
        CALL    OUT_SP_NO       ; routine OUT-SP-NO outputs space or number
        LD      BC,$FF9C        ; value -100
        CALL    OUT_SP_NO       ; routine OUT-SP-NO
        LD      C,$F6           ; value -10 ( B is still $FF )
        CALL    OUT_SP_NO       ; routine OUT-SP-NO
        LD      A,L             ; remainder to A.

;;; @brief ; OUT-NUM-4
;;;
;;; ; OUT-NUM-4
;;; @calls OUT_CODE
;;; @jumpedfrom OUT_NUM_1
OUT_NUM_4:
        CALL    OUT_CODE           ; routine OUT-CODE for final digit.
                                ; else report code zero wouldn't get
                                ; printed.
L1A45:
        POP     HL              ; restore the
        POP     DE              ; registers and
        RET                     ; return.


;***************************************************
