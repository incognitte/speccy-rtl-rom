;;; @file 07_basic_line_and_command_interpretation.asm
;;; @brief Part 7. BASIC LINE AND COMMAND INTERPRETATION

;***************************************************
;** Part 7. BASIC LINE AND COMMAND INTERPRETATION **
;***************************************************

;;; @brief The offset table
;;;
;;; The BASIC interpreter has found a command code $CE - $FF
;;; which is then reduced to range $00 - $31 and added to the base address
;;; of this table to give the address of an offset which, when added to
;;; the offset therein, gives the location in the following parameter table
;;; where a list of class codes, separators and addresses relevant to the
;;; command exists.
;;;
;;; ; offst-tbl
OFFST_TBL:
        DB          P_DEF_FN - $     ; B1 offset to Address: P-DEF-FN
        DB          P_CAT - $        ; CB offset to Address: P-CAT
        DB          P_FORMAT - $     ; BC offset to Address: P-FORMAT
        DB          P_MOVE - $       ; BF offset to Address: P-MOVE
        DB          P_ERASE - $      ; C4 offset to Address: P-ERASE
        DB          P_OPEN - $       ; AF offset to Address: P-OPEN
        DB          P_CLOSE - $      ; B4 offset to Address: P-CLOSE
        DB          P_MERGE - $      ; 93 offset to Address: P-MERGE
        DB          P_VERIFY - $     ; 91 offset to Address: P-VERIFY
        DB          P_BEEP - $       ; 92 offset to Address: P-BEEP
        DB          P_CIRCLE - $     ; 95 offset to Address: P-CIRCLE
        DB          P_INK - $        ; 98 offset to Address: P-INK
        DB          P_PAPER - $      ; 98 offset to Address: P-PAPER
        DB          P_FLASH - $      ; 98 offset to Address: P-FLASH
        DB          P_BRIGHT - $     ; 98 offset to Address: P-BRIGHT
        DB          P_INVERSE - $    ; 98 offset to Address: P-INVERSE
        DB          P_OVER - $       ; 98 offset to Address: P-OVER
        DB          P_OUT - $        ; 98 offset to Address: P-OUT
        DB          P_LPRINT - $     ; 7F offset to Address: P-LPRINT
        DB          P_LLIST - $      ; 81 offset to Address: P-LLIST
        DB          P_STOP - $       ; 2E offset to Address: P-STOP
        DB          P_READ - $       ; 6C offset to Address: P-READ
        DB          P_DATA - $       ; 6E offset to Address: P-DATA
        DB          P_RESTORE - $    ; 70 offset to Address: P-RESTORE
        DB          P_NEW - $        ; 48 offset to Address: P-NEW
        DB          P_BORDER - $     ; 94 offset to Address: P-BORDER
        DB          P_CONT - $       ; 56 offset to Address: P-CONT
        DB          P_DIM - $        ; 3F offset to Address: P-DIM
        DB          P_REM - $        ; 41 offset to Address: P-REM
        DB          P_FOR - $        ; 2B offset to Address: P-FOR
        DB          P_GO_TO - $      ; 17 offset to Address: P-GO-TO
        DB          P_GO_SUB - $     ; 1F offset to Address: P-GO-SUB
        DB          P_INPUT - $      ; 37 offset to Address: P-INPUT
        DB          P_LOAD - $       ; 77 offset to Address: P-LOAD
        DB          P_LIST - $       ; 44 offset to Address: P-LIST
        DB          P_LET - $        ; 0F offset to Address: P-LET
        DB          P_PAUSE - $      ; 59 offset to Address: P-PAUSE
        DB          P_NEXT - $       ; 2B offset to Address: P-NEXT
        DB          P_POKE - $       ; 43 offset to Address: P-POKE
        DB          P_PRINT - $      ; 2D offset to Address: P-PRINT
        DB          P_PLOT - $       ; 51 offset to Address: P-PLOT
        DB          P_RUN - $        ; 3A offset to Address: P-RUN
        DB          P_SAVE - $       ; 6D offset to Address: P-SAVE
        DB          P_RANDOM - $     ; 42 offset to Address: P-RANDOM
        DB          P_IF - $         ; 0D offset to Address: P-IF
        DB          P_CLS - $        ; 49 offset to Address: P-CLS
        DB          P_DRAW - $       ; 5C offset to Address: P-DRAW
        DB          P_CLEAR - $      ; 44 offset to Address: P-CLEAR
        DB          P_RETURN - $     ; 15 offset to Address: P-RETURN
        DB          P_COPY - $       ; 5D offset to Address: P-COPY


;;; @brief The parameter or "Syntax" table
;;;
;;; For each command there exists a variable list of parameters.
;;; If the character is greater than a space it is a required separator.
;;; If less, then it is a command class in the range 00 - 0B.
;;; Note that classes 00, 03 and 05 will fetch the addresses from this table.
;;; Some classes e.g. 07 and 0B have the same address in all invocations
;;; and the command is re-computed from the low-byte of the parameter address.
;;; Some e.g. 02 are only called once so a call to the command is made from
;;; within the class routine rather than holding the address within the table.
;;; Some class routines check syntax entirely and some leave this task for the
;;; command itself.
;;; Others for example CIRCLE (x,y,z) check the first part (x,y) using the
;;; class routine and the final part (,z) within the command.
;;; The last few commands appear to have been added in a rush but their syntax
;;; is rather simple e.g. MOVE "M1","M2"
;;;
;;; ; P-LET
P_LET:
        DB          $01             ; Class-01 - A variable is required.
        DB          $3D             ; Separator:  '='
        DB          $02             ; Class-02 - An expression, numeric or string,
                                ; must follow.

;;; @brief ; P-GO-TO
;;;
;;; ; P-GO-TO
P_GO_TO:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    GO_TO                 ; Address: $1E67; Address: GO-TO

;;; @brief ; P-IF
;;;
;;; ; P-IF
P_IF:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $CB             ; Separator:  'THEN'
        DB          $05             ; Class-05 - Variable syntax checked
                                ; by routine.
        DW    IF           ; Address: $1CF0; Address: IF

;;; @brief ; P-GO-SUB
;;;
;;; ; P-GO-SUB
P_GO_SUB:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    GO_SUB                ; Address: $1EED; Address: GO-SUB

;;; @brief ; P-STOP
;;;
;;; ; P-STOP
P_STOP:
        DB          $00      ; Class-00 - No further operands.
        DW    STOP           ; Address: $1CEE; Address: STOP

;;; @brief ; P-RETURN
;;;
;;; ; P-RETURN
P_RETURN:
        DB          $00        ; Class-00 - No further operands.
        DW    RETURN           ; Address: $1F23; Address: RETURN

;;; @brief ; P-FOR
;;;
;;; ; P-FOR
P_FOR:
        DB          $04             ; Class-04 - A single character variable must
                                ; follow.
        DB          $3D             ; Separator:  '='
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $CC             ; Separator:  'TO'
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $05             ; Class-05 - Variable syntax checked
                                ; by routine.
        DW    FOR           ; Address: $1D03; Address: FOR

;;; @brief ; P-NEXT
;;;
;;; ; P-NEXT
P_NEXT:
        DB          $04             ; Class-04 - A single character variable must
                                ; follow.
        DB          $00      ; Class-00 - No further operands.
        DW    NEXT           ; Address: $1DAB; Address: NEXT

;;; @brief ; P-PRINT
;;;
;;; ; P-PRINT
P_PRINT:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    PRINT           ; Address: $1FCD; Address: PRINT

;;; @brief ; P-INPUT
;;;
;;; ; P-INPUT
P_INPUT:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    INPUT           ; Address: $2089; Address: INPUT

;;; @brief ; P-DIM
;;;
;;; ; P-DIM
P_DIM:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    DIM           ; Address: $2C02; Address: DIM

;;; @brief ; P-REM
;;;
;;; ; P-REM
P_REM:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    REM           ; Address: $1BB2; Address: REM

;;; @brief ; P-NEW
;;;
;;; ; P-NEW
P_NEW:
        DB          $00     ; Class-00 - No further operands.
        DW    NEW           ; Address: $11B7; Address: NEW

;;; @brief ; P-RUN
;;;
;;; ; P-RUN
P_RUN:
        DB          $03             ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        DW    RUN           ; Address: $1EA1; Address: RUN

;;; @brief ; P-LIST
;;;
;;; ; P-LIST
P_LIST:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    LIST           ; Address: $17F9; Address: LIST

;;; @brief ; P-POKE
;;;
;;; ; P-POKE
P_POKE:
        DB          $08             ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        DB          $00      ; Class-00 - No further operands.
        DW    POKE           ; Address: $1E80; Address: POKE

;;; @brief ; P-RANDOM
;;;
;;; ; P-RANDOM
P_RANDOM:
        DB          $03             ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        DW    RANDOMIZE           ; Address: $1E4F; Address: RANDOMIZE

;;; @brief ; P-CONT
;;;
;;; ; P-CONT
P_CONT:
        DB          $00          ; Class-00 - No further operands.
        DW    CONTINUE           ; Address: $1E5F; Address: CONTINUE

;;; @brief ; P-CLEAR
;;;
;;; ; P-CLEAR
P_CLEAR:
        DB          $03             ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        DW    CLEAR           ; Address: $1EAC; Address: CLEAR

;;; @brief ; P-CLS
;;;
;;; ; P-CLS
P_CLS:
        DB          $00     ; Class-00 - No further operands.
        DW    CLS           ; Address: $0D6B; Address: CLS

;;; @brief ; P-PLOT
;;;
;;; ; P-PLOT
P_PLOT:
        DB          $09             ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        DB          $00      ; Class-00 - No further operands.
        DW    PLOT           ; Address: $22DC; Address: PLOT

;;; @brief ; P-PAUSE
;;;
;;; ; P-PAUSE
P_PAUSE:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    PAUSE                 ; Address: $1F3A; Address: PAUSE

;;; @brief ; P-READ
;;;
;;; ; P-READ
P_READ:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    READ           ; Address: $1DED; Address: READ

;;; @brief ; P-DATA
;;;
;;; ; P-DATA
P_DATA:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    DATA           ; Address: $1E27; Address: DATA

;;; @brief ; P-RESTORE
;;;
;;; ; P-RESTORE
P_RESTORE:
        DB          $03             ; Class-03 - A numeric expression may follow
                                ; else default to zero.
        DW    RESTORE           ; Address: $1E42; Address: RESTORE

;;; @brief ; P-DRAW
;;;
;;; ; P-DRAW
P_DRAW:
        DB          $09             ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        DB          $05             ; Class-05 - Variable syntax checked
                                ; by routine.
        DW    DRAW           ; Address: $2382; Address: DRAW

;;; @brief ; P-COPY
;;;
;;; ; P-COPY
P_COPY:
        DB          $00      ; Class-00 - No further operands.
        DW    COPY           ; Address: $0EAC; Address: COPY

;;; @brief ; P-LPRINT
;;;
;;; ; P-LPRINT
P_LPRINT:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    LPRINT           ; Address: $1FC9; Address: LPRINT

;;; @brief ; P-LLIST
;;;
;;; ; P-LLIST
P_LLIST:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    LLIST           ; Address: $17F5; Address: LLIST

;;; @brief ; P-SAVE
;;;
;;; ; P-SAVE
P_SAVE:
        DB          $0B             ; Class-0B - Offset address converted to tape
                                ; command.

;;; @brief ; P-LOAD
;;;
;;; ; P-LOAD
P_LOAD:
        DB          $0B             ; Class-0B - Offset address converted to tape
                                ; command.

;;; @brief ; P-VERIFY
;;;
;;; ; P-VERIFY
P_VERIFY:
        DB          $0B             ; Class-0B - Offset address converted to tape
                                ; command.

;;; @brief ; P-MERGE
;;;
;;; ; P-MERGE
P_MERGE:
        DB          $0B             ; Class-0B - Offset address converted to tape
                                ; command.

;;; @brief ; P-BEEP
;;;
;;; ; P-BEEP
P_BEEP:
        DB          $08             ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        DB          $00      ; Class-00 - No further operands.
        DW    BEEP           ; Address: $03F8; Address: BEEP

;;; @brief ; P-CIRCLE
;;;
;;; ; P-CIRCLE
P_CIRCLE:
        DB          $09             ; Class-09 - Two comma-separated numeric
                                ; expressions required with optional colour
                                ; items.
        DB          $05             ; Class-05 - Variable syntax checked
                                ; by routine.
        DW    CIRCLE           ; Address: $2320; Address: CIRCLE

;;; @brief ; P-INK
;;;
;;; ; P-INK
P_INK:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-PAPER
;;;
;;; ; P-PAPER
P_PAPER:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-FLASH
;;;
;;; ; P-FLASH
P_FLASH:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-BRIGHT
;;;
;;; ; P-BRIGHT
P_BRIGHT:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-INVERSE
;;;
;;; ; P-INVERSE
P_INVERSE:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-OVER
;;;
;;; ; P-OVER
P_OVER:
        DB          $07             ; Class-07 - Offset address is converted to
                                ; colour code.

;;; @brief ; P-OUT
;;;
;;; ; P-OUT
P_OUT:
        DB          $08             ; Class-08 - Two comma-separated numeric
                                ; expressions required.
        DB          $00         ; Class-00 - No further operands.
        DW    OUT_RTN           ; Address: $1E7A; Address: OUT

;;; @brief ; P-BORDER
;;;
;;; ; P-BORDER
P_BORDER:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    BORDER                ; Address: $2294; Address: BORDER

;;; @brief ; P-DEF-FN
;;;
;;; ; P-DEF-FN
P_DEF_FN:
        DB          $05             ; Class-05 - Variable syntax checked entirely
                                ; by routine.
        DW    DEF_FN           ; Address: $1F60; Address: DEF-FN

;;; @brief ; P-OPEN
;;;
;;; ; P-OPEN
P_OPEN:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $2C             ; Separator:  ','          see Footnote *
        DB          $0A             ; Class-0A - A string expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    OPEN                  ; Address: $1736; Address: OPEN

;;; @brief ; P-CLOSE
;;;
;;; ; P-CLOSE
P_CLOSE:
        DB          $06             ; Class-06 - A numeric expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    CLOSE                 ; Address: $16E5; Address: CLOSE

;;; @brief ; P-FORMAT
;;;
;;; ; P-FORMAT
P_FORMAT:
        DB          $0A             ; Class-0A - A string expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    CAT_ETC               ; Address: $1793; Address: CAT-ETC

;;; @brief ; P-MOVE
;;;
;;; ; P-MOVE
P_MOVE:
        DB          $0A             ; Class-0A - A string expression must follow.
        DB          $2C             ; Separator:  ','
        DB          $0A             ; Class-0A - A string expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    CAT_ETC               ; Address: $1793; Address: CAT-ETC

;;; @brief ; P-ERASE
;;;
;;; ; P-ERASE
P_ERASE:
        DB          $0A             ; Class-0A - A string expression must follow.
        DB          $00             ; Class-00 - No further operands.
        DW    CAT_ETC               ; Address: $1793; Address: CAT-ETC

;;; @brief ; P-CAT
;;;
;;; ; P-CAT
P_CAT:
        DB          $00         ; Class-00 - No further operands.
        DW    CAT_ETC           ; Address: $1793; Address: CAT-ETC

; * Note that a comma is required as a separator with the OPEN command
; but the Interface 1 programmers relaxed this allowing ';' as an
; alternative for their channels creating a confusing mixture of
; allowable syntax as it is this ROM which opens or re-opens the
; normal channels.

;;; @brief Main parser (BASIC interpreter)
;;;
;;; This routine is called once from MAIN-2 when the BASIC line is to
;;; be entered or re-entered into the Program area and the syntax
;;; requires checking.
;;;
;;; ; LINE-SCAN
;;; @calls E_LINE_NO
;;; @jumps STMT_L_1
;;; @calledby MAIN_EXEC
LINE_SCAN:
        RES     7,(IY+$01)      ; update FLAGS - signal checking syntax
        CALL    E_LINE_NO       ; routine E-LINE-NO              >>
                                ; fetches the line number if in range.

        XOR     A               ; clear the accumulator.
        LD      (SUBPPC),A       ; set statement number SUBPPC to zero.
        DEC     A               ; set accumulator to $FF.
        LD      (ERR_NR),A       ; set ERR_NR to 'OK' - 1.
        JR      STMT_L_1        ; forward to continue at STMT-L-1.

;;; @brief Statement loop
;;;
;;; ; STMT-LOOP
;;; @jumpedfrom STMT_L_1, NEXT_LINE, STMT_NEXT
;;; @fallthrough STMT_L_1
STMT_LOOP:
        RST     20H             ; NEXT-CHAR

;;; @brief > the entry point from above or LINE-RUN ; STMT-L-1
;;;
;;; -> the entry point from above or LINE-RUN
;;; ; STMT-L-1
;;; @calls SET_WORK
;;; @jumps REPORT_C, LINE_END, STMT_LOOP, GET_PARAM
;;; @jumpedfrom LINE_SCAN, IF_1
STMT_L_1:
        CALL    SET_WORK           ; routine SET-WORK clears workspace etc.

        INC     (IY+$0D)        ; increment statement number SUBPPC
        JP      M,REPORT_C      ; to REPORT-C to raise
                                ; 'Nonsense in BASIC' if over 127.

        RST     18H             ; GET-CHAR

        LD      B,$00           ; set B to zero for later indexing.
                                ; early so any other reason ???

        CP      $0D             ; is character carriage return ?
                                ; i.e. an empty statement.
        JR      Z,LINE_END         ; forward to LINE-END if so.

        CP      $3A             ; is it statement end marker ':' ?
                                ; i.e. another type of empty statement.
        JR      Z,STMT_LOOP         ; back to STMT-LOOP if so.

        LD      HL,STMT_RET     ; address: STMT-RET
        PUSH    HL              ; is now pushed as a return address
        LD      C,A             ; transfer the current character to C.

; advance CH_ADD to a position after command and test if it is a command.

        RST     20H             ; NEXT-CHAR to advance pointer
        LD      A,C             ; restore current character
        SUB     $CE             ; subtract 'DEF FN' - first command
        JP      C,REPORT_C      ; jump to REPORT-C if less than a command
                                ; raising
                                ; 'Nonsense in BASIC'

        LD      C,A             ; put the valid command code back in C.
                                ; register B is zero.
        LD      HL,OFFST_TBL    ; address: offst-tbl
        ADD     HL,BC           ; index into table with one of 50 commands.
        LD      C,(HL)          ; pick up displacement to syntax table entry.
        ADD     HL,BC           ; add to address the relevant entry.
        JR      GET_PARAM       ; forward to continue at GET-PARAM

;;; @brief The main scanning loop
;;;
;;; not documented properly
;;;
;;;
;;; ; SCAN-LOOP
;;; @fallthrough GET_PARAM
SCAN_LOOP:
        LD      HL,(T_ADDR)      ; fetch temporary address from T_ADDR
                                ; during subsequent loops.

; -> the initial entry point with HL addressing start of syntax table entry.

;;; @brief ; GET-PARAM
;;;
;;; ; GET-PARAM
;;; @jumps SEPARATOR
;;; @jumpedfrom STMT_L_1
GET_PARAM:
        LD      A,(HL)          ; pick up the parameter.
        INC     HL              ; address next one.
        LD      (T_ADDR),HL      ; save pointer in system variable T_ADDR

        LD      BC,SCAN_LOOP    ; address: SCAN-LOOP
        PUSH    BC              ; is now pushed on stack as looping address.
        LD      C,A             ; store parameter in C.
        CP      $20             ; is it greater than ' '  ?
        JR      NC,SEPARATOR    ; forward to SEPARATOR to check that correct
                                ; separator appears in statement if so.

        LD      HL,CLASS_TBL    ; address: class-tbl.
        LD      B,$00           ; prepare to index into the class table.
        ADD     HL,BC           ; index to find displacement to routine.
        LD      C,(HL)          ; displacement to BC
        ADD     HL,BC           ; add to address the CLASS routine.
        PUSH    HL              ; push the address on the stack.

        RST     18H             ; GET-CHAR - HL points to place in statement.

        DEC     B               ; reset the zero flag - the initial state
                                ; for all class routines.

        RET                     ; and make an indirect jump to routine
                                ; and then SCAN-LOOP (also on stack).

; Note. one of the class routines will eventually drop the return address
; off the stack breaking out of the above seemingly endless loop.

;;; @brief THE 'SEPARATOR' ROUTINE
;;;
;;;   This routine is called once to verify that the mandatory separator
;;;   present in the parameter table is also present in the correct
;;;   location following the command.  For example, the 'THEN' token after
;;;   the 'IF' token and expression.
;;;
;;; ; SEPARATOR
;;; @jumps REPORT_C
;;; @jumpedfrom GET_PARAM
SEPARATOR:
        RST     18H             ; GET-CHAR
        CP      C               ; does it match the character in C ?
        JP      NZ,REPORT_C     ; jump forward to REPORT-C if not
                                ; 'Nonsense in BASIC'.

        RST     20H             ; NEXT-CHAR advance to next character
        RET                     ; return.

;;; @brief Come here after interpretation
;;;
;;; ; STMT-RET
;;; @calls BREAK_KEY
;;; @jumps STMT_R_1
;;; @fallthrough REPORT_L
STMT_RET:
        CALL    BREAK_KEY           ; routine BREAK-KEY is tested after every
                                ; statement.
        JR      C,STMT_R_1         ; step forward to STMT-R-1 if not pressed.

;;; @brief ; REPORT-L
;;;
;;; ; REPORT-L
REPORT_L:
        RST     08H             ; ERROR-1
        DB          $14         ; Error Report: BREAK into program

;;; @brief ; STMT-R-1
;;;
;;; ; STMT-R-1
;;; @jumps STMT_NEXT, LINE_NEW
;;; @jumpedfrom STMT_RET
;;; @fallthrough LINE_RUN
STMT_R_1:
        BIT     7,(IY+$0A)      ; test NSPPC - will be set if $FF -
                                ; no jump to be made.
        JR      NZ,STMT_NEXT        ; forward to STMT-NEXT if a program line.

        LD      HL,(NEWPPC)      ; fetch line number from NEWPPC
        BIT     7,H             ; will be set if minus two - direct command(s)
        JR      Z,LINE_NEW      ; forward to LINE-NEW if a jump is to be
                                ; made to a new program line/statement.

;;; @brief Run a direct command
;;;
;;; A direct command is to be run or, if continuing from above,
;;; the next statement of a direct command is to be considered.
;;;
;;; ; LINE-RUN
;;; @jumps NEXT_LINE
;;; @calledby MAIN_EXEC
LINE_RUN:
        LD      HL,$FFFE        ; The dummy value minus two
        LD      (PPC),HL      ; is set/reset as line number in PPC.
        LD      HL,(WORKSP)      ; point to end of line + 1 - WORKSP.
        DEC     HL              ; now point to $80 end-marker.
        LD      DE,(E_LINE)      ; address the start of line E_LINE.
        DEC     DE              ; now location before - for GET-CHAR.
        LD      A,(NSPPC)       ; load statement to A from NSPPC.
        JR      NEXT_LINE       ; forward to NEXT-LINE.

;;; @brief Find start address of new line
;;;
;;; The branch was to here if a jump is to made to a new line number
;;; and statement.
;;; That is the previous statement was a GO TO, GO SUB, RUN, RETURN, NEXT etc..
;;;
;;; ; LINE-NEW
;;; @calls LINE_ADDR
;;; @jumps LINE_USE, REPORT_N
;;; @jumpedfrom STMT_R_1
;;; @fallthrough REPORT_0
LINE_NEW:
        CALL    LINE_ADDR           ; routine LINE-ADDR gets address of line
                                ; returning zero flag set if line found.
        LD      A,(NSPPC)       ; fetch new statement from NSPPC
        JR      Z,LINE_USE      ; forward to LINE-USE if line matched.

; continue as must be a direct command.

        AND     A               ; test statement which should be zero
        JR      NZ,REPORT_N     ; forward to REPORT-N if not.
                                ; 'Statement lost'

;

        LD      B,A             ; save statement in B.??
        LD      A,(HL)          ; fetch high byte of line number.
        AND     $C0             ; test if using direct command
                                ; a program line is less than $3F
        LD      A,B             ; retrieve statement.
                                ; (we can assume it is zero).
        JR      Z,LINE_USE         ; forward to LINE-USE if was a program line

; Alternatively a direct statement has finished correctly.

;;; @brief ; REPORT-0
;;;
;;; ; REPORT-0
REPORT_0:
        RST     08H             ; ERROR-1
        DB          $FF         ; Error Report: OK

;;; @brief THE 'REM' COMMAND
;;;
;;; The REM command routine.
;;; The return address STMT-RET is dropped and the rest of line ignored.
;;;
;;; ; REM
;;; @fallthrough LINE_END
REM:
        POP     BC              ; drop return address STMT-RET and
                                ; continue ignoring rest of line.

;;; @brief End of line?
;;;
;;; ; LINE-END
;;; @calls SYNTAX_Z
;;; @jumpedfrom STMT_L_1, STMT_NEXT, STOP
;;; @fallthrough LINE_USE
LINE_END:
        CALL    SYNTAX_Z        ; routine SYNTAX-Z  (UNSTACK-Z?)
        RET     Z               ; return if checking syntax.

        LD      HL,($5C55)      ; fetch NXTLIN to HL.
        LD      A,$C0           ; test against the
        AND     (HL)            ; system limit $3F.
        RET     NZ              ; return if more as must be
                                ; end of program.
                                ; (or direct command)

        XOR     A               ; set statement to zero.

; and continue to set up the next following line and then consider this new one.

;;; @brief General line checking
;;;
;;; The branch was here from LINE-NEW if BASIC is branching.
;;; or a continuation from above if dealing with a new sequential line.
;;; First make statement zero number one leaving others unaffected.
;;;
;;; ; LINE-USE
;;; @jumpedfrom LINE_NEW
;;; @fallthrough NEXT_LINE
LINE_USE:
        CP      $01             ; will set carry if zero.
        ADC     A,$00           ; add in any carry.

        LD      D,(HL)          ; high byte of line number to D.
        INC     HL              ; advance pointer.
        LD      E,(HL)          ; low byte of line number to E.
        LD      (PPC),DE      ; set system variable PPC.

        INC     HL              ; advance pointer.
        LD      E,(HL)          ; low byte of line length to E.
        INC     HL              ; advance pointer.
        LD      D,(HL)          ; high byte of line length to D.

        EX      DE,HL           ; swap pointer to DE before
        ADD     HL,DE           ; adding to address the end of line.
        INC     HL              ; advance to start of next line.

;;; @brief Update NEXT LINE but consider previous line or edit line.
;;;
;;; The pointer will be the next line if continuing from above or to
;;; edit line end-marker ($80) if from LINE-RUN.
;;;
;;; ; NEXT-LINE
;;; @calls EACH_STMT
;;; @jumps STMT_LOOP, STMT_NEXT
;;; @jumpedfrom LINE_RUN
;;; @fallthrough REPORT_N
NEXT_LINE:
        LD      ($5C55),HL      ; store pointer in system variable NXTLIN

        EX      DE,HL           ; bring back pointer to previous or edit line
        LD      (CH_ADD),HL      ; and update CH_ADD with character address.

        LD      D,A             ; store statement in D.
        LD      E,$00           ; set E to zero to suppress token searching
                                ; if EACH-STMT is to be called.
        LD      (IY+$0A),$FF    ; set statement NSPPC to $FF signalling
                                ; no jump to be made.
        DEC     D               ; decrement and test statement
        LD      (IY+$0D),D      ; set SUBPPC to decremented statement number.
        JP      Z,STMT_LOOP     ; to STMT-LOOP if result zero as statement is
                                ; at start of line and address is known.

        INC     D               ; else restore statement.
        CALL    EACH_STMT       ; routine EACH-STMT finds the D'th statement
                                ; address as E does not contain a token.
        JR      Z,STMT_NEXT         ; forward to STMT-NEXT if address found.

;;; @brief ; REPORT-N
;;;
;;; ; REPORT-N
;;; @jumpedfrom LINE_NEW
REPORT_N:
        RST     08H             ; ERROR-1
        DB          $16         ; Error Report: Statement lost

;;; @brief End of statement?
;;;
;;; This combination of routines is called from 20 places when
;;; the end of a statement should have been reached and all preceding
;;; syntax is in order.
;;;
;;; ; CHECK-END
;;; @calls SYNTAX_Z
;;; @calledby REPORT_FA, LIST_5, CLASS_05, CLASS_02, L1CA5, FOR, F_USE_1, READ_2, DATA_1, DEF_FN_7, +6 more
;;; @fallthrough STMT_NEXT
CHECK_END:
        CALL    SYNTAX_Z        ; routine SYNTAX-Z
        RET     NZ              ; return immediately in runtime

        POP     BC              ; drop address of calling routine.
        POP     BC              ; drop address STMT-RET.
                                ; and continue to find next statement.

;;; @brief Go to next statement
;;;
;;; Acceptable characters at this point are carriage return and ':'.
;;; If so go to next statement which in the first case will be on next line.
;;;
;;; ; STMT-NEXT
;;; @jumps LINE_END, STMT_LOOP, REPORT_C
;;; @jumpedfrom STMT_R_1, NEXT_LINE
STMT_NEXT:
        RST     18H             ; GET-CHAR - ignoring white space etc.

        CP      $0D             ; is it carriage return ?
        JR      Z,LINE_END      ; back to LINE-END if so.

        CP      $3A             ; is it ':' ?
        JP      Z,STMT_LOOP     ; jump back to STMT-LOOP to consider
                                ; further statements

        JP      REPORT_C           ; jump to REPORT-C with any other character
                                ; 'Nonsense in BASIC'.

; Note. the two-byte sequence 'rst 08; defb $0b' could replace the above jp.

;;; @brief Command class table
;;;
;;; ; class-tbl
CLASS_TBL:
        DB          CLASS_00 - $       ; 0F offset to Address: CLASS-00
        DB          CLASS_01 - $       ; 1D offset to Address: CLASS-01
        DB          CLASS_02 - $       ; 4B offset to Address: CLASS-02
        DB          CLASS_03 - $       ; 09 offset to Address: CLASS-03
        DB          CLASS_04 - $       ; 67 offset to Address: CLASS-04
        DB          CLASS_05 - $       ; 0B offset to Address: CLASS-05
        DB          EXPT_1NUM - $      ; 7B offset to Address: CLASS-06
        DB          CLASS_07 - $       ; 8E offset to Address: CLASS-07
        DB          EXPT_2NUM - $      ; 71 offset to Address: CLASS-08
        DB          CLASS_09 - $       ; B4 offset to Address: CLASS-09
        DB          EXPT_EXP - $       ; 81 offset to Address: CLASS-0A
        DB          CLASS_0B - $       ; CF offset to Address: CLASS-0B


;;; @brief Command classes---00, 03, and 05
;;;
;;; @verbatim
;;; class-03 e.g. RUN or RUN 200   ;  optional operand
;;; class-00 e.g. CONTINUE         ;  no operand
;;; class-05 e.g. PRINT            ;  variable syntax checked by routine
;;; @endverbatim
;;;
;;; ; CLASS-03
;;; @calls FETCH_NUM
;;; @fallthrough CLASS_00
CLASS_03:
        CALL    FETCH_NUM           ; routine FETCH-NUM

;;; @brief ; CLASS-00
;;;
;;; ; CLASS-00
;;; @fallthrough CLASS_05
CLASS_00:
        CP      A               ; reset zero flag.

; if entering here then all class routines are entered with zero reset.

;;; @brief ; CLASS-05
;;;
;;; ; CLASS-05
;;; @calls CHECK_END
CLASS_05:
        POP     BC              ; drop address SCAN-LOOP.
        CALL    Z,CHECK_END     ; if zero set then call routine CHECK-END >>>
                                ; as should be no further characters.

        EX      DE,HL           ; save HL to DE.
        LD      HL,(T_ADDR)      ; fetch T_ADDR
        LD      C,(HL)          ; fetch low byte of routine
        INC     HL              ; address next.
        LD      B,(HL)          ; fetch high byte of routine.
        EX      DE,HL           ; restore HL from DE
        PUSH    BC              ; push the address
        RET                     ; and make an indirect jump to the command.

;;; @brief Command classes---01, 02, and 04
;;;
;;; class-01  e.g. LET A = 2*3     ; a variable is reqd
;;;
;;; This class routine is also called from INPUT and READ to find the
;;; destination variable for an assignment.
;;;
;;; ; CLASS-01
;;; @calls LOOK_VARS
;;; @calledby READ, IN_ITEM_2, IN_ITEM_3
;;; @fallthrough VAR_A_1
CLASS_01:
        CALL    LOOK_VARS           ; routine LOOK-VARS returns carry set if not
                                ; found in runtime.

;;; @brief Variable in assignment
;;;
;;; ; VAR-A-1
;;; @jumps VAR_A_2, VAR_A_3
;;; @jumpedfrom CLASS_04
;;; @fallthrough REPORT_2
VAR_A_1:
        LD      (IY+$37),$00    ; set FLAGX to zero
        JR      NC,VAR_A_2      ; forward to VAR-A-2 if found or checking
                                ; syntax.

        SET     1,(IY+$37)      ; FLAGX  - Signal a new variable
        JR      NZ,VAR_A_3      ; to VAR-A-3 if not assigning to an array
                                ; e.g. LET a$(3,3) = "X"

;;; @brief ; REPORT-2
;;;
;;; ; REPORT-2
;;; @jumpedfrom NEXT, S_LETTER
REPORT_2:
        RST     08H             ; ERROR-1
        DB          $01         ; Error Report: Variable not found

;;; @brief ; VAR-A-2
;;;
;;; ; VAR-A-2
;;; @calls STK_VAR, SYNTAX_Z, STK_FETCH
;;; @jumps VAR_A_3
;;; @jumpedfrom VAR_A_1
;;; @fallthrough VAR_A_3
VAR_A_2:
        CALL    Z,STK_VAR         ; routine STK-VAR considers a subscript/slice
        BIT     6,(IY+$01)        ; test FLAGS  - Numeric or string result ?
        JR      NZ,VAR_A_3        ; to VAR-A-3 if numeric

        XOR     A               ; default to array/slice - to be retained.
        CALL    SYNTAX_Z        ; routine SYNTAX-Z
        CALL    NZ,STK_FETCH    ; routine STK-FETCH is called in runtime
                                ; may overwrite A with 1.
        LD      HL,FLAGX        ; address system variable FLAGX
        OR      (HL)            ; set bit 0 if simple variable to be reclaimed
        LD      (HL),A          ; update FLAGX
        EX      DE,HL           ; start of string/subscript to DE

;;; @brief ; VAR-A-3
;;;
;;; ; VAR-A-3
;;; @jumpedfrom VAR_A_1, VAR_A_2
VAR_A_3:
        LD      (STRLEN),BC      ; update STRLEN
        LD      (DEST),HL      ; and DEST of assigned string.
        RET                     ; return.

; -------------------------------------------------
; class-02 e.g. LET a = 1 + 1   ; an expression must follow

;;; @brief ; CLASS-02
;;;
;;; ; CLASS-02
;;; @calls VAL_FET_1, CHECK_END
CLASS_02:
        POP     BC              ; drop return address SCAN-LOOP
        CALL    VAL_FET_1       ; routine VAL-FET-1 is called to check
                                ; expression and assign result in runtime
        CALL    CHECK_END           ; routine CHECK-END checks nothing else
                                ; is present in statement.
        RET                     ; Return

;;; @brief Fetch a value
;;;
;;; ; VAL-FET-1
;;; @calledby CLASS_02, READ_1
;;; @fallthrough VAL_FET_2
VAL_FET_1:
        LD      A,(FLAGS)       ; initial FLAGS to A

;;; @brief ; VAL-FET-2
;;;
;;; ; VAL-FET-2
;;; @calls SCANNING
;;; @jumps REPORT_C, LET
;;; @calledby IN_ASSIGN
VAL_FET_2:
        PUSH    AF              ; save A briefly
        CALL    SCANNING        ; routine SCANNING evaluates expression.
        POP     AF              ; restore A
        LD      D,(IY+$01)      ; post-SCANNING FLAGS to D
        XOR     D               ; xor the two sets of flags
        AND     $40             ; pick up bit 6 of xored FLAGS should be zero
        JR      NZ,REPORT_C     ; forward to REPORT-C if not zero
                                ; 'Nonsense in BASIC' - results don't agree.

        BIT     7,D           ; test FLAGS - is syntax being checked ?
        JP      NZ,LET        ; jump forward to LET to make the assignment
                                ; in runtime.

        RET                     ; but return from here if checking syntax.

;;; @brief Command class---04
;;;
;;; class-04 e.g. FOR i            ; a single character variable must follow
;;;
;;; ; CLASS-04
;;; @calls LOOK_VARS
;;; @jumps REPORT_C, VAR_A_1
CLASS_04:
        CALL    LOOK_VARS       ; routine LOOK-VARS
        PUSH    AF              ; preserve flags.
        LD      A,C             ; fetch type - should be 011xxxxx
        OR      $9F             ; combine with 10011111.
        INC     A               ; test if now $FF by incrementing.
        JR      NZ,REPORT_C     ; forward to REPORT-C if result not zero.

        POP     AF              ; else restore flags.
        JR      VAR_A_1         ; back to VAR-A-1


;;; @brief Expect numeric/string expression
;;;
;;; This routine is used to get the two coordinates of STRING$, ATTR and POINT.
;;; It is also called from PRINT-ITEM to get the two numeric expressions that
;;; follow the AT ( in PRINT AT, INPUT AT).
;;;
;;; ; NEXT-2NUM
;;; @calledby PR_ITEM_1, S_2_COORD
;;; @fallthrough EXPT_2NUM
NEXT_2NUM:
        RST     20H             ; NEXT-CHAR advance past 'AT' or '('.

;;; @brief class-08 e.g
;;;
;;; class-08 e.g. POKE 65535,2     ; two numeric expressions separated by comma
;;; ; CLASS-08
;;; ; EXPT-2NUM
;;; @calls EXPT_1NUM
;;; @jumps REPORT_C
;;; @jumpedfrom CL_09_1
;;; @fallthrough EXPT_1NUM
EXPT_2NUM:
        CALL    EXPT_1NUM           ; routine EXPT-1NUM is called for first
                                ; numeric expression
        CP      $2C             ; is character ',' ?
        JR      NZ,REPORT_C     ; to REPORT-C if not required separator.
                                ; 'Nonsense in BASIC'.

        RST     20H             ; NEXT-CHAR

;;; @brief > class-06 e.g
;;;
;;; ->
;;;  class-06  e.g. GOTO a*1000   ; a numeric expression must follow
;;; ; CLASS-06
;;; ; EXPT-1NUM
;;; @calls SCANNING
;;; @calledby REPORT_FA, LIST_2, EXPT_2NUM, FOR, PR_ITEM_2, STR_ALTER, CO_TEMP_4, CIRCLE, DR_3_PRMS, INT_EXP2
;;; @jumpedfrom FETCH_NUM
;;; @fallthrough REPORT_C
EXPT_1NUM:
        CALL    SCANNING        ; routine SCANNING
        BIT     6,(IY+$01)      ; test FLAGS  - Numeric or string result ?
        RET     NZ              ; return if result is numeric.

;;; @brief ; REPORT-C
;;;
;;; ; REPORT-C
;;; @jumpedfrom REPORT_FA, E_L_1, STMT_L_1, SEPARATOR, STMT_NEXT, VAL_FET_2, CLASS_04, EXPT_2NUM, EXPT_EXP, DEF_FN_4, +17 more
REPORT_C:
        RST     08H             ; ERROR-1
        DB          $0B         ; Error Report: Nonsense in BASIC

; ---------------------------------------------------------------
; class-0A e.g. ERASE "????"    ; a string expression must follow.
;                               ; these only occur in unimplemented commands
;                               ; although the routine expt-exp is called
;                               ; from SAVE-ETC

;;; @brief ; CLASS-0A ; EXPT-EXP
;;;
;;; ; CLASS-0A
;;; ; EXPT-EXP
;;; @calls SCANNING
;;; @jumps REPORT_C
;;; @calledby L0609
EXPT_EXP:
        CALL    SCANNING        ; routine SCANNING
        BIT     6,(IY+$01)      ; test FLAGS  - Numeric or string result ?
        RET     Z               ; return if string result.

        JR      REPORT_C           ; back to REPORT-C if numeric.

;;; @brief Set permanent colours class 07
;;;
;;; @verbatim
;;; class-07 e.g. PAPER 6          ; a single class for a collection of
;;;                               ; similar commands. Clever.
;;; @endverbatim
;;;
;;; Note. these commands should ensure that current channel is 'S'
;;;
;;; ; CLASS-07
;;; @calls TEMPS
;;; @fallthrough L1CA5
CLASS_07:
        BIT     7,(IY+$01)      ; test FLAGS - checking syntax only ?
                                ; Note. there is a subroutine to do this.
        RES     0,(IY+$02)      ; update TV_FLAG - signal main screen in use
        CALL    NZ,TEMPS        ; routine TEMPS is called in runtime.
        POP     AF              ; drop return address SCAN-LOOP
        LD      A,(T_ADDR)       ; T_ADDR_lo to accumulator.
                                ; points to '$07' entry + 1
                                ; e.g. for INK points to $EC now

; Note if you move alter the syntax table next line may have to be altered.

;;; @brief Note. For ZASM assembler replace following expression with SUB $13
;;;
;;; Note. For ZASM assembler replace following expression with SUB $13.
;;; @address $1CA5
;;; @calls CO_TEMP_4, CHECK_END
L1CA5:
        SUB     LOW(P_INK-$D8 % 256) ; convert $EB to $D8 ('INK') etc.
                                ; ( is SUB $13 in standard ROM )

        CALL    CO_TEMP_4           ; routine CO-TEMP-4
        CALL    CHECK_END           ; routine CHECK-END check that nothing else
                                ; in statement.

; return here in runtime.

        LD      HL,(ATTR_T)      ; pick up ATTR_T and MASK_T
        LD      (ATTR_P),HL      ; and store in ATTR_P and MASK_P
        LD      HL,P_FLAG        ; point to P_FLAG.
        LD      A,(HL)          ; pick up in A
        RLCA                    ; rotate to left
        XOR     (HL)            ; combine with HL
        AND     $AA             ; 10101010
        XOR     (HL)            ; only permanent bits affected
        LD      (HL),A          ; reload into P_FLAG.
        RET                     ; return.

;;; @brief Command class---09
;;;
;;; @verbatim
;;; e.g. PLOT PAPER 0; 128,88     ; two coordinates preceded by optional
;;;                               ; embedded colour items.
;;; @endverbatim
;;;
;;; Note. this command should ensure that current channel is actually 'S'.
;;;
;;; ; CLASS-09
;;; @calls SYNTAX_Z, TEMPS
;;; @jumps CL_09_1
;;; @fallthrough CL_09_1
CLASS_09:
        CALL    SYNTAX_Z          ; routine SYNTAX-Z
        JR      Z,CL_09_1         ; forward to CL-09-1 if checking syntax.

        RES     0,(IY+$02)      ; update TV_FLAG - signal main screen in use
        CALL    TEMPS           ; routine TEMPS is called.
        LD      HL,MASK_T        ; point to MASK_T
        LD      A,(HL)          ; fetch mask to accumulator.
        OR      $F8             ; or with 11111000 paper/bright/flash 8
        LD      (HL),A          ; mask back to MASK_T system variable.
        RES     6,(IY+$57)      ; reset P_FLAG  - signal NOT PAPER 9 ?

        RST     18H             ; GET-CHAR

;;; @brief ; CL-09-1
;;;
;;; ; CL-09-1
;;; @calls CO_TEMP_2
;;; @jumps EXPT_2NUM
;;; @jumpedfrom CLASS_09
CL_09_1:
        CALL    CO_TEMP_2           ; routine CO-TEMP-2 deals with any embedded
                                ; colour items.
        JR      EXPT_2NUM           ; exit via EXPT-2NUM to check for x,y.

; Note. if either of the numeric expressions contain STR$ then the flag setting
; above will be undone when the channel flags are reset during STR$.
; e.g.
; 10 BORDER 3 : PLOT VAL STR$ 128, VAL STR$ 100
; credit John Elliott.

;;; @brief Command class---0B
;;;
;;; Again a single class for four commands.
;;; This command just jumps back to SAVE-ETC to handle the four tape commands.
;;; The routine itself works out which command has called it by examining the
;;; address in T_ADDR_lo. Note therefore that the syntax table has to be
;;; located where these and other sequential command addresses are not split
;;; over a page boundary.
;;;
;;; ; CLASS-0B
;;; @jumps SAVE_ETC
CLASS_0B:
        JP      SAVE_ETC           ; jump way back to SAVE-ETC

;;; @brief Fetch a number
;;;
;;; This routine is called from CLASS-03 when a command may be followed by
;;; an optional numeric expression e.g. RUN. If the end of statement has
;;; been reached then zero is used as the default.
;;; Also called from LIST-4.
;;;
;;; ; FETCH-NUM
;;; @jumps USE_ZERO, EXPT_1NUM
;;; @calledby LIST_4, CLASS_03
;;; @fallthrough USE_ZERO
FETCH_NUM:
        CP      $0D             ; is character a carriage return ?
        JR      Z,USE_ZERO      ; forward to USE-ZERO if so

        CP      $3A             ; is it ':' ?
        JR      NZ,EXPT_1NUM    ; forward to EXPT-1NUM if not.
                                ; else continue and use zero.

;;; @brief Use zero routine
;;;
;;; This routine is called four times to place the value zero on the
;;; calculator stack as a default value in runtime.
;;;
;;; ; USE-ZERO
;;; @calls SYNTAX_Z
;;; @calledby REPORT_FA, LIST_3
;;; @jumpedfrom FETCH_NUM
USE_ZERO:
        CALL    SYNTAX_Z        ; routine SYNTAX-Z  (UNSTACK-Z?)
        RET     Z               ;

        RST     28H                 ;; FP-CALC
        DB          $A0             ;;stk-zero       ;0.
        DB          $38             ;;end-calc

        RET                     ; return.

;;; @brief Handle STOP command
;;;
;;; Command Syntax: STOP
;;; One of the shortest and least used commands. As with 'OK' not an error.
;;;
;;; ; REPORT-9
;;; ; STOP
;;; @calls SYNTAX_Z, TEST_ZERO
;;; @jumps IF_1, LINE_END
;;; @fallthrough IF_1
STOP:
        RST     08H             ; ERROR-1
        DB          $08         ; Error Report: STOP statement

; -----------------
; Handle IF command
; -----------------
; e.g. IF score>100 THEN PRINT "You Win"
; The parser has already checked the expression the result of which is on
; the calculator stack. The presence of the 'THEN' separator has also been
; checked and CH-ADD points to the command after THEN.
;

;; IF
IF:
        POP     BC             ; drop return address - STMT-RET
        CALL    SYNTAX_Z       ; routine SYNTAX-Z
        JR      Z,IF_1         ; forward to IF-1 if checking syntax
                                ; to check syntax of PRINT "You Win"


        RST     28H                 ;; FP-CALC    score>100 (1=TRUE 0=FALSE)
        DB          $02             ;;delete      .
        DB          $38             ;;end-calc

        EX      DE,HL           ; make HL point to deleted value
        CALL    TEST_ZERO       ; routine TEST-ZERO
        JP      C,LINE_END      ; jump to LINE-END if FALSE (0)

;;; @brief ; IF-1
;;;
;;; ; IF-1
;;; @jumps STMT_L_1
;;; @jumpedfrom STOP
IF_1:
        JP      STMT_L_1           ; to STMT-L-1, if true (1) to execute command
                                ; after 'THEN' token.

;;; @brief Handle FOR command
;;;
;;; e.g. FOR i = 0 TO 1 STEP 0.1
;;; Using the syntax tables, the parser has already checked for a start and
;;; limit value and also for the intervening separator.
;;; the two values v,l are on the calculator stack.
;;; CLASS-04 has also checked the variable and the name is in STRLEN_lo.
;;; The routine begins by checking for an optional STEP.
;;;
;;; ; FOR
;;; @calls EXPT_1NUM, CHECK_END
;;; @jumps F_USE_1, F_REORDER
FOR:
        CP      $CD             ; is there a 'STEP' ?
        JR      NZ,F_USE_1      ; to F-USE-1 if not to use 1 as default.

        RST     20H                 ; NEXT-CHAR
        CALL    EXPT_1NUM           ; routine EXPT-1NUM
        CALL    CHECK_END           ; routine CHECK-END
        JR      F_REORDER           ; to F-REORDER

; ---

;;; @brief ; F-USE-1
;;;
;;; ; F-USE-1
;;; @calls CHECK_END
;;; @jumpedfrom FOR
F_USE_1:
        CALL    CHECK_END           ; routine CHECK-END

        RST     28H                 ;; FP-CALC      v,l.
        DB          $A1             ;;stk-one       v,l,1=s.
        DB          $38             ;;end-calc


;;; @brief ; F-REORDER
;;;
;;; ; F-REORDER
;;; @calls LET, MAKE_ROOM
;;; @jumps F_L_S
;;; @jumpedfrom FOR
;;; @fallthrough F_L_S
F_REORDER:
        RST     28H                 ;; FP-CALC       v,l,s.
        DB          $C0             ;;st-mem-0       v,l,s.
        DB          $02             ;;delete         v,l.
        DB          $01             ;;exchange       l,v.
        DB          $E0             ;;get-mem-0      l,v,s.
        DB          $01             ;;exchange       l,s,v.
        DB          $38             ;;end-calc

        CALL    LET           ; routine LET assigns the initial value v to
                                ; the variable altering type if necessary.
        LD      (MEM),HL      ; The system variable MEM is made to point to
                                ; the variable instead of its normal
                                ; location MEMBOT
        DEC     HL              ; point to single-character name
        LD      A,(HL)          ; fetch name
        SET     7,(HL)          ; set bit 7 at location
        LD      BC,$0006        ; add six to HL
        ADD     HL,BC           ; to address where limit should be.
        RLCA                    ; test bit 7 of original name.
        JR      C,F_L_S         ; forward to F-L-S if already a FOR/NEXT
                                ; variable

        LD      C,$0D           ; otherwise an additional 13 bytes are needed.
                                ; 5 for each value, two for line number and
                                ; 1 byte for looping statement.
        CALL    MAKE_ROOM       ; routine MAKE-ROOM creates them.
        INC     HL              ; make HL address limit.

;;; @brief ; F-L-S
;;;
;;; ; F-L-S
;;; @calls NEXT_LOOP
;;; @jumpedfrom F_REORDER
;;; @fallthrough F_LOOP
F_L_S:
        PUSH    HL              ; save position.

        RST     28H                 ;; FP-CALC         l,s.
        DB          $02             ;;delete           l.
        DB          $02             ;;delete           .
        DB          $38             ;;end-calc
                                ; DE points to STKEND, l.

        POP     HL              ; restore variable position
        EX      DE,HL           ; swap pointers
        LD      C,$0A           ; ten bytes to move
        LDIR                    ; Copy 'deleted' values to variable.
        LD      HL,(PPC)      ; Load with current line number from PPC
        EX      DE,HL           ; exchange pointers.
        LD      (HL),E          ; save the looping line
        INC     HL              ; in the next
        LD      (HL),D          ; two locations.
        LD      D,(IY+$0D)      ; fetch statement from SUBPPC system variable.
        INC     D               ; increment statement.
        INC     HL              ; and pointer
        LD      (HL),D          ; and store the looping statement.
                                ;
        CALL    NEXT_LOOP       ; routine NEXT-LOOP considers an initial
        RET     NC              ; iteration. Return to STMT-RET if a loop is
                                ; possible to execute next statement.

; no loop is possible so execution continues after the matching 'NEXT'

        LD      B,(IY+$38)      ; get single-character name from STRLEN_lo
        LD      HL,(PPC)      ; get the current line from PPC
        LD      (NEWPPC),HL      ; and store it in NEWPPC
        LD      A,(SUBPPC)       ; fetch current statement from SUBPPC
        NEG                     ; Negate as counter decrements from zero
                                ; initially and we are in the middle of a
                                ; line.
        LD      D,A             ; Store result in D.
        LD      HL,(CH_ADD)      ; get current address from CH_ADD
        LD      E,$F3           ; search will be for token 'NEXT'

;;; @brief ; F-LOOP
;;;
;;; ; F-LOOP
;;; @calls LOOK_PROG
;;; @jumps REPORT_I, F_FOUND
F_LOOP:
        PUSH    BC              ; save variable name.
        LD      BC,($5C55)      ; fetch NXTLIN
        CALL    LOOK_PROG       ; routine LOOK-PROG searches for 'NEXT' token.
        LD      ($5C55),BC      ; update NXTLIN
        POP     BC              ; and fetch the letter
        JR      C,REPORT_I      ; forward to REPORT-I if the end of program
                                ; was reached by LOOK-PROG.
                                ; 'FOR without NEXT'

        RST     20H             ; NEXT-CHAR fetches character after NEXT
        OR      $20             ; ensure it is upper-case.
        CP      B               ; compare with FOR variable name
        JR      Z,F_FOUND       ; forward to F-FOUND if it matches.

; but if no match i.e. nested FOR/NEXT loops then continue search.

        RST     20H             ; NEXT-CHAR
        JR      F_LOOP          ; back to F-LOOP

; ---


;;; @brief ; F-FOUND
;;;
;;; ; F-FOUND
;;; @jumpedfrom F_LOOP
F_FOUND:
        RST     20H             ; NEXT-CHAR
        LD      A,$01           ; subtract the negated counter from 1
        SUB     D               ; to give the statement after the NEXT
        LD      (NSPPC),A       ; set system variable NSPPC
        RET                     ; return to STMT-RET to branch to new
                                ; line and statement. ->
; ---

;;; @brief ; REPORT-I
;;;
;;; ; REPORT-I
;;; @jumpedfrom F_LOOP
REPORT_I:
        RST     08H             ; ERROR-1
        DB          $11         ; Error Report: FOR without NEXT

;;; @brief LOOK-PROG
;;;
;;; Find DATA, DEF FN or NEXT.
;;; This routine searches the program area for one of the above three keywords.
;;; On entry, HL points to start of search area.
;;; The token is in E, and D holds a statement count, decremented from zero.
;;;
;;; ; LOOK-PROG
;;; @jumps LOOK_P_2
;;; @calledby F_LOOP, READ, SF_FND_DF
;;; @fallthrough LOOK_P_1
LOOK_PROG:
        LD      A,(HL)          ; fetch current character
        CP      $3A             ; is it ':' a statement separator ?
        JR      Z,LOOK_P_2      ; forward to LOOK-P-2 if so.

; The starting point was PROG - 1 or the end of a line.

;;; @brief ; LOOK-P-1
;;;
;;; ; LOOK-P-1
;;; @jumpedfrom LOOK_P_2
;;; @fallthrough LOOK_P_2
LOOK_P_1:
        INC     HL              ; increment pointer to address
        LD      A,(HL)          ; the high byte of line number
        AND     $C0             ; test for program end marker $80 or a
                                ; variable
        SCF                     ; Set Carry Flag
        RET     NZ              ; return with carry set if at end
                                ; of program.           ->

        LD      B,(HL)          ; high byte of line number to B
        INC     HL              ;
        LD      C,(HL)          ; low byte to C.
        LD      (NEWPPC),BC      ; set system variable NEWPPC.
        INC     HL              ;
        LD      C,(HL)          ; low byte of line length to C.
        INC     HL              ;
        LD      B,(HL)          ; high byte to B.
        PUSH    HL              ; save address
        ADD     HL,BC           ; add length to position.
        LD      B,H             ; and save result
        LD      C,L             ; in BC.
        POP     HL              ; restore address.
        LD      D,$00           ; initialize statement counter to zero.

;;; @brief ; LOOK-P-2
;;;
;;; ; LOOK-P-2
;;; @calls EACH_STMT
;;; @jumps LOOK_P_1
;;; @jumpedfrom LOOK_PROG
LOOK_P_2:
        PUSH    BC              ; save address of next line
        CALL    EACH_STMT       ; routine EACH-STMT searches current line.
        POP     BC              ; restore address.
        RET     NC              ; return if match was found. ->

        JR      LOOK_P_1           ; back to LOOK-P-1 for next line.

;;; @brief Handle NEXT command
;;;
;;; e.g. NEXT i
;;; The parameter tables have already evaluated the presence of a variable
;;;
;;; ; NEXT
;;; @calls NEXT_LOOP
;;; @jumps REPORT_2, REPORT_1, GO_TO_2
NEXT:
        BIT     1,(IY+$37)      ; test FLAGX - handling a new variable ?
        JP      NZ,REPORT_2     ; jump back to REPORT-2 if so
                                ; 'Variable not found'

; now test if found variable is a simple variable uninitialized by a FOR.

        LD      HL,(DEST)      ; load address of variable from DEST
        BIT     7,(HL)          ; is it correct type ?
        JR      Z,REPORT_1      ; forward to REPORT-1 if not
                                ; 'NEXT without FOR'

        INC     HL              ; step past variable name
        LD      (MEM),HL      ; and set MEM to point to three 5-byte values
                                ; value, limit, step.

        RST     28H                 ;; FP-CALC     add step and re-store
        DB          $E0             ;;get-mem-0    v.
        DB          $E2             ;;get-mem-2    v,s.
        DB          $0F             ;;addition     v+s.
        DB          $C0             ;;st-mem-0     v+s.
        DB          $02             ;;delete       .
        DB          $38             ;;end-calc

        CALL    NEXT_LOOP       ; routine NEXT-LOOP tests against limit.
        RET     C               ; return if no more iterations possible.

        LD      HL,(MEM)      ; find start of variable contents from MEM.
        LD      DE,$000F        ; add 3*5 to
        ADD     HL,DE           ; address the looping line number
        LD      E,(HL)          ; low byte to E
        INC     HL              ;
        LD      D,(HL)          ; high byte to D
        INC     HL              ; address looping statement
        LD      H,(HL)          ; and store in H
        EX      DE,HL           ; swap registers
        JP      GO_TO_2         ; exit via GO-TO-2 to execute another loop.

; ---

;;; @brief ; REPORT-1
;;;
;;; ; REPORT-1
;;; @jumpedfrom NEXT
REPORT_1:
        RST     08H             ; ERROR-1
        DB          $00         ; Error Report: NEXT without FOR


;;; @brief Perform NEXT loop
;;;
;;; This routine is called from the FOR command to test for an initial
;;; iteration and from the NEXT command to test for all subsequent iterations.
;;; the system variable MEM addresses the variable's contents which, in the
;;; latter case, have had the step, possibly negative, added to the value.
;;;
;;; ; NEXT-LOOP
;;; @calledby F_L_S, NEXT
NEXT_LOOP:
        RST     28H                 ;; FP-CALC
        DB          $E1             ;;get-mem-1        l.
        DB          $E0             ;;get-mem-0        l,v.
        DB          $E2             ;;get-mem-2        l,v,s.
        DB          $36             ;;less-0           l,v,(1/0) negative step ?
        DB          $00             ;;jump-true        l,v.(1/0)

        DB          $02             ;;to NEXT_1, NEXT-1 if step negative

        DB          $01             ;;exchange         v,l.

;;; @brief ; NEXT-1
;;;
;;; ; NEXT-1
NEXT_1:
        DB          $03             ;;subtract         l-v OR v-l.
        DB          $37             ;;greater-0        (1/0)
        DB          $00             ;;jump-true        .

        DB          $04             ;;to NEXT_2, NEXT-2 if no more iterations.

        DB          $38             ;;end-calc         .

        AND     A               ; clear carry flag signalling another loop.
        RET                     ; return

; ---

;;; @brief ; NEXT-2
;;;
;;; ; NEXT-2
NEXT_2:
        DB          $38             ;;end-calc         .

        SCF                     ; set carry flag signalling looping exhausted.
        RET                     ; return


;;; @brief Handle READ command
;;;
;;; e.g. READ a, b$, c$(1000 TO 3000)
;;; A list of comma-separated variables is assigned from a list of
;;; comma-separated expressions.
;;; As it moves along the first list, the character address CH_ADD is stored
;;; in X_PTR while CH_ADD is used to read the second list.
;;;
;;; ; READ-3
;;; @jumpedfrom READ_2
;;; @fallthrough READ
READ_3:
        RST     20H             ; NEXT-CHAR

;;; @brief > Entry point
;;;
;;; -> Entry point.
;;; ; READ
;;; @calls CLASS_01, SYNTAX_Z, LOOK_PROG
;;; @jumps READ_2, READ_1
;;; @fallthrough REPORT_E
READ:
        CALL    CLASS_01           ; routine CLASS-01 checks variable.
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,READ_2           ; forward to READ-2 if checking syntax


        RST     18H             ; GET-CHAR
        LD      (X_PTR),HL      ; save character position in X_PTR.
        LD      HL,(DATADD)      ; load HL with Data Address DATADD, which is
                                ; the start of the program or the address
                                ; after the last expression that was read or
                                ; the address of the line number of the
                                ; last RESTORE command.
        LD      A,(HL)          ; fetch character
        CP      $2C             ; is it a comma ?
        JR      Z,READ_1        ; forward to READ-1 if so.

; else all data in this statement has been read so look for next DATA token

        LD      E,$E4           ; token 'DATA'
        CALL    LOOK_PROG       ; routine LOOK-PROG
        JR      NC,READ_1       ; forward to READ-1 if DATA found

; else report the error.

;;; @brief ; REPORT-E
;;;
;;; ; REPORT-E
REPORT_E:
        RST     08H             ; ERROR-1
        DB          $0D         ; Error Report: Out of DATA

;;; @brief ; READ-1
;;;
;;; ; READ-1
;;; @calls TEMP_PTR1, VAL_FET_1, TEMP_PTR2
;;; @jumpedfrom READ
;;; @fallthrough READ_2
READ_1:
        CALL    TEMP_PTR1           ; routine TEMP-PTR1 advances updating CH_ADD
                                ; with new DATADD position.
        CALL    VAL_FET_1           ; routine VAL-FET-1 assigns value to variable
                                ; checking type match and adjusting CH_ADD.

        RST     18H             ; GET-CHAR fetches adjusted character position
        LD      (DATADD),HL      ; store back in DATADD
        LD      HL,(X_PTR)      ; fetch X_PTR  the original READ CH_ADD
        LD      (IY+$26),$00    ; now nullify X_PTR_hi
        CALL    TEMP_PTR2       ; routine TEMP-PTR2 restores READ CH_ADD

;;; @brief ; READ-2
;;;
;;; ; READ-2
;;; @calls CHECK_END
;;; @jumps READ_3
;;; @jumpedfrom READ
READ_2:
        RST     18H             ; GET-CHAR
        CP      $2C             ; is it ',' indicating more variables to read ?
        JR      Z,READ_3        ; back to READ-3 if so

        CALL    CHECK_END       ; routine CHECK-END
        RET                     ; return from here in runtime to STMT-RET.

;;; @brief Handle DATA command
;;;
;;; In runtime this 'command' is passed by but the syntax is checked when such
;;; a statement is found while parsing a line.
;;; e.g. DATA 1, 2, "text", score-1, a$(location, room, object), FN r(49),
;;;         wages - tax, TRUE, The meaning of life
;;;
;;; ; DATA
;;; @calls SYNTAX_Z
;;; @jumps DATA_2
;;; @fallthrough DATA_1
DATA:
        CALL    SYNTAX_Z         ; routine SYNTAX-Z to check status
        JR      NZ,DATA_2        ; forward to DATA-2 if in runtime

;;; @brief ; DATA-1
;;;
;;; ; DATA-1
;;; @calls SCANNING, CHECK_END
DATA_1:
        CALL    SCANNING           ; routine SCANNING to check syntax of
                                ; expression
        CP      $2C             ; is it a comma ?
        CALL    NZ,CHECK_END    ; routine CHECK-END checks that statement
                                ; is complete. Will make an early exit if
                                ; so. >>>
        RST     20H             ; NEXT-CHAR
        JR      DATA_1          ; back to DATA-1

; ---

;;; @brief ; DATA-2
;;;
;;; ; DATA-2
;;; @jumpedfrom DATA
;;; @fallthrough PASS_BY
DATA_2:
        LD      A,$E4           ; set token to 'DATA' and continue into
                                ; the PASS-BY routine.


;;; @brief Check statement for DATA or DEF FN
;;;
;;; This routine is used to backtrack to a command token and then
;;; forward to the next statement in runtime.
;;;
;;; ; PASS-BY
;;; @jumps EACH_STMT
;;; @jumpedfrom DEF_FN
PASS_BY:
        LD      B,A             ; Give BC enough space to find token.
        CPDR                    ; Compare decrement and repeat. (Only use).
                                ; Work backwards till keyword is found which
                                ; is start of statement before any quotes.
                                ; HL points to location before keyword.
        LD      DE,$0200        ; count 1+1 statements, dummy value in E to
                                ; inhibit searching for a token.
        JP      EACH_STMT           ; to EACH-STMT to find next statement

; -----------------------------------------------------------------------
; A General Note on Invalid Line Numbers.
; =======================================
; One of the revolutionary concepts of Sinclair BASIC was that it supported
; virtual line numbers. That is the destination of a GO TO, RESTORE etc. need
; not exist. It could be a point before or after an actual line number.
; Zero suffices for a before but the after should logically be infinity.
; Since the maximum actual line limit is 9999 then the system limit, 16383
; when variables kick in, would serve fine as a virtual end point.
; However, ironically, only the LOAD command gets it right. It will not
; autostart a program that has been saved with a line higher than 16383.
; All the other commands deal with the limit unsatisfactorily.
; LIST, RUN, GO TO, GO SUB and RESTORE have problems and the latter may
; crash the machine when supplied with an inappropriate virtual line number.
; This is puzzling as very careful consideration must have been given to
; this point when the new variable types were allocated their masks and also
; when the routine NEXT-ONE was successfully re-written to reflect this.
; An enigma.
; -------------------------------------------------------------------------

;;; @brief Handle RESTORE command
;;;
;;; The restore command sets the system variable for the data address to
;;; point to the location before the supplied line number or first line
;;; thereafter.
;;; This alters the position where subsequent READ commands look for data.
;;; Note. If supplied with inappropriate high numbers the system may crash
;;; in the LINE-ADDR routine as it will pass the program/variables end-marker
;;; and then lose control of what it is looking for - variable or line number.
;;; - observation, Steven Vickers, 1984, Pitman.
;;;
;;; ; RESTORE
;;; @calls FIND_INT2
;;; @fallthrough REST_RUN
RESTORE:
        CALL    FIND_INT2           ; routine FIND-INT2 puts integer in BC.
                                ; Note. B should be checked against limit $3F
                                ; and an error generated if higher.

; this entry point is used from RUN command with BC holding zero

;;; @brief ; REST-RUN
;;;
;;; ; REST-RUN
;;; @calls LINE_ADDR
;;; @calledby RUN
REST_RUN:
        LD      H,B             ; transfer the line
        LD      L,C             ; number to the HL register.
        CALL    LINE_ADDR       ; routine LINE-ADDR to fetch the address.
        DEC     HL              ; point to the location before the line.
        LD      (DATADD),HL      ; update system variable DATADD.
        RET                     ; return to STMT-RET (or RUN)

;;; @brief Handle RANDOMIZE command
;;;
;;; This command sets the SEED for the RND function to a fixed value.
;;; With the parameter zero, a random start point is used depending on
;;; how long the computer has been switched on.
;;;
;;; ; RANDOMIZE
;;; @calls FIND_INT2
;;; @jumps RAND_1
;;; @fallthrough RAND_1
RANDOMIZE:
        CALL    FIND_INT2       ; routine FIND-INT2 puts parameter in BC.
        LD      A,B             ; test this
        OR      C               ; for zero.
        JR      NZ,RAND_1       ; forward to RAND-1 if not zero.

        LD      BC,(FRAMES1)      ; use the lower two bytes at FRAMES1.

;;; @brief ; RAND-1
;;;
;;; ; RAND-1
;;; @jumpedfrom RANDOMIZE
RAND_1:
        LD      (SEED),BC      ; place in SEED system variable.
        RET                     ; return to STMT-RET

;;; @brief Handle CONTINUE command
;;;
;;; The CONTINUE command transfers the OLD (but incremented) values of
;;; line number and statement to the equivalent "NEW VALUE" system variables
;;; by using the last part of GO TO and exits indirectly to STMT-RET.
;;;
;;; ; CONTINUE
;;; @jumps GO_TO_2
CONTINUE:
        LD      HL,(OLDPPC)      ; fetch OLDPPC line number.
        LD      D,(IY+$36)      ; fetch OSPPC statement.
        JR      GO_TO_2         ; forward to GO-TO-2

;;; @brief Handle GO TO command
;;;
;;; The GO TO command routine is also called by GO SUB and RUN routines
;;; to evaluate the parameters of both commands.
;;; It updates the system variables used to fetch the next line/statement.
;;; It is at STMT-RET that the actual change in control takes place.
;;; Unlike some BASICs the line number need not exist.
;;; Note. the high byte of the line number is incorrectly compared with $F0
;;; instead of $3F. This leads to commands with operands greater than 32767
;;; being considered as having been run from the editing area and the
;;; error report 'Statement Lost' is given instead of 'OK'.
;;; - Steven Vickers, 1984.
;;;
;;; ; GO-TO
;;; @calls FIND_INT2
;;; @jumps REPORT_BB
;;; @calledby RUN, GO_SUB
;;; @fallthrough GO_TO_2
GO_TO:
        CALL    FIND_INT2       ; routine FIND-INT2 puts operand in BC
        LD      H,B             ; transfer line
        LD      L,C             ; number to HL.
        LD      D,$00           ; set statement to 0 - first.
        LD      A,H             ; compare high byte only
        CP      $F0             ; to $F0 i.e. 61439 in full.
        JR      NC,REPORT_BB    ; forward to REPORT-B if above.

; This call entry point is used to update the system variables e.g. by RETURN.

;;; @brief ; GO-TO-2
;;;
;;; ; GO-TO-2
;;; @jumpedfrom NEXT, CONTINUE, RETURN
GO_TO_2:
        LD      (NEWPPC),HL      ; save line number in NEWPPC
        LD      (IY+$0A),D      ; and statement in NSPPC
        RET                     ; to STMT-RET (or GO-SUB command)

;;; @brief Handle OUT command
;;;
;;; Syntax has been checked and the two comma-separated values are on the
;;; calculator stack.
;;;
;;; ; OUT
;;; @calls TWO_PARAM
OUT_RTN:
        CALL    TWO_PARAM           ; routine TWO-PARAM fetches values
                                ; to BC and A.
        OUT     (C),A           ; perform the operation.
        RET                     ; return to STMT-RET.

;;; @brief Handle POKE command
;;;
;;; This routine alters a single byte in the 64K address space.
;;; Happily no check is made as to whether ROM or RAM is addressed.
;;; Sinclair BASIC requires no poking of system variables.
;;;
;;; ; POKE
;;; @calls TWO_PARAM
POKE:
        CALL    TWO_PARAM           ; routine TWO-PARAM fetches values
                                ; to BC and A.
        LD      (BC),A          ; load memory location with A.
        RET                     ; return to STMT-RET.

;;; @brief Fetch two  parameters from calculator stack
;;;
;;; This routine fetches a byte and word from the calculator stack
;;; producing an error if either is out of range.
;;;
;;; ; TWO-PARAM
;;; @calls FP_TO_A
;;; @jumps REPORT_BB, TWO_P_1
;;; @calledby OUT_RTN, POKE
;;; @fallthrough TWO_P_1
TWO_PARAM:
        CALL    FP_TO_A           ; routine FP-TO-A
        JR      C,REPORT_BB       ; forward to REPORT-B if overflow occurred

        JR      Z,TWO_P_1         ; forward to TWO-P-1 if positive

        NEG                     ; negative numbers are made positive

;;; @brief ; TWO-P-1
;;;
;;; ; TWO-P-1
;;; @calls FIND_INT2
;;; @jumpedfrom TWO_PARAM
TWO_P_1:
        PUSH    AF              ; save the value
        CALL    FIND_INT2       ; routine FIND-INT2 gets integer to BC
        POP     AF              ; restore the value
        RET                     ; return

;;; @brief Find integers
;;;
;;; The first of these routines fetches a 8-bit integer (range 0-255) from the
;;; calculator stack to the accumulator and is used for colours, streams,
;;; durations and coordinates.
;;; The second routine fetches 16-bit integers to the BC register pair
;;; and is used to fetch command and function arguments involving line numbers
;;; or memory addresses and also array subscripts and tab arguments.
;;; ->
;;;
;;; ; FIND-INT1
;;; @calls FP_TO_A
;;; @jumps FIND_I_1
;;; @calledby BEEP, STR_DATA, STR_ALTER, CO_TEMP_4, BORDER, C_ARC_GE1, READ_IN
FIND_INT1:
        CALL    FP_TO_A           ; routine FP-TO-A
        JR      FIND_I_1          ; forward to FIND-I-1 for common exit routine.

; ---

; ->

;;; @brief ; FIND-INT2
;;;
;;; ; FIND-INT2
;;; @calls FP_TO_BC
;;; @calledby BEEP, REPORT_FA, LIST_5, RESTORE, RANDOMIZE, GO_TO, TWO_P_1, CLEAR, PAUSE, PR_ITEM_2, +4 more
;;; @fallthrough FIND_I_1
FIND_INT2:
        CALL    FP_TO_BC           ; routine FP-TO-BC

;;; @brief ; FIND-I-1
;;;
;;; ; FIND-I-1
;;; @jumps REPORT_BB
;;; @jumpedfrom FIND_INT1
;;; @fallthrough REPORT_BB
FIND_I_1:
        JR      C,REPORT_BB         ; to REPORT-Bb with overflow.

        RET     Z               ; return if positive.


;;; @brief ; REPORT-Bb
;;;
;;; ; REPORT-Bb
;;; @jumpedfrom RTL_PO_FETCH_EXT, GO_TO, TWO_PARAM, FIND_I_1, READ_IN
REPORT_BB:
        RST     08H             ; ERROR-1
        DB          $0A         ; Error Report: Integer out of range

;;; @brief Handle RUN command
;;;
;;; This command runs a program starting at an optional line.
;;; It performs a 'RESTORE 0' then CLEAR
;;;
;;; ; RUN
;;; @calls GO_TO, REST_RUN
;;; @jumps CLEAR_RUN
RUN:
        CALL    GO_TO           ; routine GO-TO puts line number in
                                ; system variables.
        LD      BC,$0000        ; prepare to set DATADD to first line.
        CALL    REST_RUN        ; routine REST-RUN does the 'restore'.
                                ; Note BC still holds zero.
        JR      CLEAR_RUN           ; forward to CLEAR-RUN to clear variables
                                ; without disturbing RAMTOP and
                                ; exit indirectly to STMT-RET

;;; @brief Handle CLEAR command
;;;
;;; This command reclaims the space used by the variables.
;;; It also clears the screen and the GO SUB stack.
;;; With an integer expression, it sets the uppermost memory
;;; address within the BASIC system.
;;; "Contrary to the manual, CLEAR doesn't execute a RESTORE" -
;;; Steven Vickers, Pitman Pocket Guide to the Spectrum, 1984.
;;;
;;; ; CLEAR
;;; @calls FIND_INT2
;;; @fallthrough CLEAR_RUN
CLEAR:
        CALL    FIND_INT2           ; routine FIND-INT2 fetches to BC.

;;; @brief ; CLEAR-RUN
;;;
;;; ; CLEAR-RUN
;;; @jumps CLEAR_1
;;; @jumpedfrom RUN
;;; @fallthrough CLEAR_1
CLEAR_RUN:
        LD      A,B             ; test for
        OR      C               ; zero.
        JR      NZ,CLEAR_1      ; skip to CLEAR-1 if not zero.

        LD      BC,(RAMTOP)      ; use the existing value of RAMTOP if zero.

;;; @brief ; CLEAR-1
;;;
;;; ; CLEAR-1
;;; @calls RECLAIM_1, CLS
;;; @jumps REPORT_M, CLEAR_2
;;; @jumpedfrom CLEAR_RUN
;;; @fallthrough REPORT_M
CLEAR_1:
        PUSH    BC              ; save ramtop value.

        LD      DE,(VARS)      ; fetch VARS
        LD      HL,(E_LINE)      ; fetch E_LINE
        DEC     HL              ; adjust to point at variables end-marker.
        CALL    RECLAIM_1       ; routine RECLAIM-1 reclaims the space used by
                                ; the variables.

        CALL    CLS           ; routine CLS to clear screen.

        LD      HL,(STKEND)      ; fetch STKEND the start of free memory.
        LD      DE,$0032        ; allow for another 50 bytes.
        ADD     HL,DE           ; add the overhead to HL.

        POP     DE              ; restore the ramtop value.
        SBC     HL,DE           ; if HL is greater than the value then jump
        JR      NC,REPORT_M     ; forward to REPORT-M
                                ; 'RAMTOP no good'

        LD      HL,(P_RAMT)      ; now P-RAMT ($7FFF on 16K RAM machine)
        AND     A               ; exact this time.
        SBC     HL,DE           ; new ramtop must be lower or the same.
        JR      NC,CLEAR_2      ; skip to CLEAR-2 if in actual RAM.

;;; @brief ; REPORT-M
;;;
;;; ; REPORT-M
;;; @jumpedfrom CLEAR_1
REPORT_M:
        RST     08H             ; ERROR-1
        DB          $15         ; Error Report: RAMTOP no good

;;; @brief ; CLEAR-2
;;;
;;; ; CLEAR-2
;;; @jumpedfrom CLEAR_1
CLEAR_2:
        EX      DE,HL           ; transfer ramtop value to HL.
        LD      (RAMTOP),HL      ; update system variable RAMTOP.
        POP     DE              ; pop the return address STMT-RET.
        POP     BC              ; pop the Error Address.
        LD      (HL),$3E        ; now put the GO SUB end-marker at RAMTOP.
        DEC     HL              ; leave a location beneath it.
        LD      SP,HL           ; initialize the machine stack pointer.
        PUSH    BC              ; push the error address.
        LD      (ERR_SP),SP      ; make ERR_SP point to location.
        EX      DE,HL           ; put STMT-RET in HL.
        JP      (HL)            ; and go there directly.

;;; @brief Handle GO SUB command
;;;
;;; The GO SUB command diverts BASIC control to a new line number
;;; in a very similar manner to GO TO but
;;; the current line number and current statement + 1
;;; are placed on the GO SUB stack as a RETURN point.
;;;
;;; ; GO-SUB
;;; @calls GO_TO
;;; @fallthrough TEST_ROOM
GO_SUB:
        POP     DE              ; drop the address STMT-RET
        LD      H,(IY+$0D)      ; fetch statement from SUBPPC and
        INC     H               ; increment it
        EX      (SP),HL         ; swap - error address to HL,
                                ; H (statement) at top of stack,
                                ; L (unimportant) beneath.
        INC     SP              ; adjust to overwrite unimportant byte
        LD      BC,(PPC)      ; fetch the current line number from PPC
        PUSH    BC              ; and PUSH onto GO SUB stack.
                                ; the empty machine-stack can be rebuilt
        PUSH    HL              ; push the error address.
        LD      (ERR_SP),SP      ; make system variable ERR_SP point to it.
        PUSH    DE              ; push the address STMT-RET.
        CALL    GO_TO           ; call routine GO-TO to update the system
                                ; variables NEWPPC and NSPPC.
                                ; then make an indirect exit to STMT-RET via
        LD      BC,$0014        ; a 20-byte overhead memory check.

;;; @brief Check available memory
;;;
;;; This routine is used on many occasions when extending a dynamic area
;;; upwards or the GO SUB stack downwards.
;;;
;;; ; TEST-ROOM
;;; @jumps REPORT_4
;;; @calledby LD_CONTRL, ED_EDIT, MAKE_ROOM, FREE_MEM, TEST_5_SP
;;; @fallthrough REPORT_4
TEST_ROOM:
        LD      HL,(STKEND)      ; fetch STKEND
        ADD     HL,BC           ; add the supplied test value
        JR      C,REPORT_4      ; forward to REPORT-4 if over $FFFF

        EX      DE,HL           ; was less so transfer to DE
        LD      HL,$0050        ; test against another 80 bytes
        ADD     HL,DE           ; anyway
        JR      C,REPORT_4      ; forward to REPORT-4 if this passes $FFFF

        SBC     HL,SP           ; if less than the machine stack pointer
        RET     C               ; then return - OK.

;;; @brief ; REPORT-4
;;;
;;; ; REPORT-4
;;; @jumps ERROR_3
;;; @jumpedfrom TEST_ROOM, GET_HL_DE, D_NO_LOOP
REPORT_4:
        LD      L,$03           ; prepare 'Out of Memory'
        JP      ERROR_3         ; jump back to ERROR-3 at $0055
                                ; Note. this error can't be trapped at $0008

;;; @brief THE 'FREE MEMORY' USER ROUTINE
;;;
;;; This routine is not used by the ROM but allows users to evaluate
;;; approximate free memory with PRINT 65536 - USR 7962.
;;;
;;; ; free-mem
;;; @calls TEST_ROOM
FREE_MEM:
        LD      BC,$0000        ; allow no overhead.

        CALL    TEST_ROOM           ; routine TEST-ROOM.

        LD      B,H             ; transfer the result
        LD      C,L             ; to the BC register.
        RET                     ; the USR function returns value of BC.

;;; @brief THE 'RETURN' COMMAND
;;;
;;; As with any command, there are two values on the machine stack at the time
;;; it is invoked.  The machine stack is below the GOSUB stack.  Both grow
;;; downwards, the machine stack by two bytes, the GOSUB stack by 3 bytes.
;;; The highest location is a statement byte followed by a two-byte line number.
;;;
;;; ; RETURN
;;; @jumps REPORT_7, GO_TO_2
RETURN:
        POP     BC              ; drop the address STMT-RET.
        POP     HL              ; now the error address.
        POP     DE              ; now a possible BASIC return line.
        LD      A,D             ; the high byte $00 - $27 is
        CP      $3E             ; compared with the traditional end-marker $3E.
        JR      Z,REPORT_7      ; forward to REPORT-7 with a match.
                                ; 'RETURN without GOSUB'

; It was not the end-marker so a single statement byte remains at the base of
; the calculator stack. It can't be popped off.

        DEC     SP              ; adjust stack pointer to create room for two
                                ; bytes.
        EX      (SP),HL         ; statement to H, error address to base of
                                ; new machine stack.
        EX      DE,HL           ; statement to D,  BASIC line number to HL.
        LD      (ERR_SP),SP      ; adjust ERR_SP to point to new stack pointer
        PUSH    BC              ; now re-stack the address STMT-RET
        JP      GO_TO_2         ; to GO-TO-2 to update statement and line
                                ; system variables and exit indirectly to the
                                ; address just pushed on stack.

; ---

;;; @brief ; REPORT-7
;;;
;;; ; REPORT-7
;;; @jumpedfrom RETURN
REPORT_7:
        PUSH    DE              ; replace the end-marker.
        PUSH    HL              ; now restore the error address
                                ; as will be required in a few clock cycles.

        RST     08H             ; ERROR-1
        DB          $06         ; Error Report: RETURN without GOSUB

;;; @brief Handle PAUSE command
;;;
;;; The pause command takes as its parameter the number of interrupts
;;; for which to wait. PAUSE 50 pauses for about a second.
;;; PAUSE 0 pauses indefinitely.
;;; Both forms can be finished by pressing a key.
;;;
;;; ; PAUSE
;;; @calls FIND_INT2
;;; @fallthrough PAUSE_1
PAUSE:
        CALL    FIND_INT2           ; routine FIND-INT2 puts value in BC

;;; @brief ; PAUSE-1
;;;
;;; ; PAUSE-1
;;; @jumps PAUSE_END, PAUSE_2
;;; @jumpedfrom PAUSE_2
;;; @fallthrough PAUSE_2
PAUSE_1:
        HALT                    ; wait for interrupt.
        DEC     BC              ; decrease counter.
        LD      A,B             ; test if
        OR      C               ; result is zero.
        JR      Z,PAUSE_END     ; forward to PAUSE-END if so.

        LD      A,B             ; test if
        AND     C               ; now $FFFF
        INC     A               ; that is, initially zero.
        JR      NZ,PAUSE_2      ; skip forward to PAUSE-2 if not.

        INC     BC              ; restore counter to zero.

;;; @brief ; PAUSE-2
;;;
;;; ; PAUSE-2
;;; @jumps PAUSE_1
;;; @jumpedfrom PAUSE_1
;;; @fallthrough PAUSE_END
PAUSE_2:
        BIT     5,(IY+$01)      ; test FLAGS - has a new key been pressed ?
        JR      Z,PAUSE_1       ; back to PAUSE-1 if not.

;;; @brief ; PAUSE-END
;;;
;;; ; PAUSE-END
;;; @jumpedfrom PAUSE_1
PAUSE_END:
        RES     5,(IY+$01)      ; update FLAGS - signal no new key
        RET                     ; and return.

;;; @brief Check for BREAK key
;;;
;;; This routine is called from COPY-LINE, when interrupts are disabled,
;;; to test if BREAK (SHIFT - SPACE) is being pressed.
;;; It is also called at STMT-RET after every statement.
;;;
;;; ; BREAK-KEY
;;; @calledby COPY_L_1, STMT_RET
BREAK_KEY:
        LD      A,$7F           ; Input address: $7FFE
        IN      A,($FE)         ; read lower right keys
        RRA                     ; rotate bit 0 - SPACE
        RET     C               ; return if not reset

        LD      A,$FE           ; Input address: $FEFE
        IN      A,($FE)         ; read lower left keys
        RRA                     ; rotate bit 0 - SHIFT
        RET                     ; carry will be set if not pressed.
                                ; return with no carry if both keys
                                ; pressed.

;;; @brief Handle DEF FN command
;;;
;;; e.g. DEF FN r$(a$,a) = a$(a TO )
;;; this 'command' is ignored in runtime but has its syntax checked
;;; during line-entry.
;;;
;;; ; DEF-FN
;;; @calls SYNTAX_Z
;;; @jumps DEF_FN_1, PASS_BY
DEF_FN:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,DEF_FN_1         ; forward to DEF-FN-1 if parsing

        LD      A,$CE           ; else load A with 'DEF FN' and
        JP      PASS_BY         ; jump back to PASS-BY

; ---

; continue here if checking syntax.

;;; @brief ; DEF-FN-1
;;;
;;; ; DEF-FN-1
;;; @calls ALPHA
;;; @jumps DEF_FN_4, DEF_FN_2
;;; @jumpedfrom DEF_FN
;;; @fallthrough DEF_FN_2
DEF_FN_1:
        SET      6,(IY+$01)     ; set FLAGS  - Assume numeric result
        CALL    ALPHA           ; call routine ALPHA
        JR      NC,DEF_FN_4     ; if not then to DEF-FN-4 to jump to
                                ; 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR
        CP      $24             ; is it '$' ?
        JR      NZ,DEF_FN_2     ; to DEF-FN-2 if not as numeric.

        RES     6,(IY+$01)      ; set FLAGS  - Signal string result

        RST     20H             ; get NEXT-CHAR

;;; @brief ; DEF-FN-2
;;;
;;; ; DEF-FN-2
;;; @jumps DEF_FN_7, DEF_FN_6
;;; @jumpedfrom DEF_FN_1
;;; @fallthrough DEF_FN_3
DEF_FN_2:
        CP      $28             ; is it '(' ?
        JR      NZ,DEF_FN_7     ; to DEF-FN-7 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR
        CP      $29             ; is it ')' ?
        JR      Z,DEF_FN_6      ; to DEF-FN-6 if null argument

;;; @brief ; DEF-FN-3
;;;
;;; ; DEF-FN-3
;;; @calls ALPHA
;;; @jumpedfrom DEF_FN_5
;;; @fallthrough DEF_FN_4
DEF_FN_3:
        CALL    ALPHA           ; routine ALPHA checks that it is the expected
                                ; alphabetic character.

;;; @brief ; DEF-FN-4
;;;
;;; ; DEF-FN-4
;;; @jumps REPORT_C, DEF_FN_5
;;; @jumpedfrom DEF_FN_1
;;; @fallthrough DEF_FN_5
DEF_FN_4:
        JP      NC,REPORT_C        ; to REPORT-C  if not
                                ; 'Nonsense in BASIC'.

        EX      DE,HL           ; save pointer in DE

        RST     20H             ; NEXT-CHAR re-initializes HL from CH_ADD
                                ; and advances.
        CP      $24             ; '$' ? is it a string argument.
        JR      NZ,DEF_FN_5     ; forward to DEF-FN-5 if not.

        EX      DE,HL           ; save pointer to '$' in DE

        RST     20H             ; NEXT-CHAR re-initializes HL and advances

;;; @brief ; DEF-FN-5
;;;
;;; ; DEF-FN-5
;;; @calls MAKE_ROOM
;;; @jumps DEF_FN_6, DEF_FN_3
;;; @jumpedfrom DEF_FN_4
DEF_FN_5:
        EX      DE,HL           ; bring back pointer.
        LD      BC,$0006        ; the function requires six hidden bytes for
                                ; each parameter passed.
                                ; The first byte will be $0E
                                ; then 5-byte numeric value
                                ; or 5-byte string pointer.

        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates space in program
                                ; area.

        INC     HL              ; adjust HL (set by LDDR)
        INC     HL              ; to point to first location.
        LD      (HL),$0E        ; insert the 'hidden' marker.

; Note. these invisible storage locations hold nothing meaningful for the
; moment. They will be used every time the corresponding function is
; evaluated in runtime.
; Now consider the following character fetched earlier.

        CP      $2C             ; is it ',' ? (more than one parameter)
        JR      NZ,DEF_FN_6     ; to DEF-FN-6 if not


        RST     20H             ; else NEXT-CHAR
        JR      DEF_FN_3        ; and back to DEF-FN-3

; ---

;;; @brief ; DEF-FN-6
;;;
;;; ; DEF-FN-6
;;; @calls SCANNING
;;; @jumps DEF_FN_7
;;; @jumpedfrom DEF_FN_2, DEF_FN_5
;;; @fallthrough DEF_FN_7
DEF_FN_6:
        CP      $29             ; should close with a ')'
        JR      NZ,DEF_FN_7     ; to DEF-FN-7 if not
                                ; 'Nonsense in BASIC'


        RST     20H             ; get NEXT-CHAR
        CP      $3D             ; is it '=' ?
        JR      NZ,DEF_FN_7     ; to DEF-FN-7 if not 'Nonsense...'


        RST     20H             ; address NEXT-CHAR
        LD      A,(FLAGS)       ; get FLAGS which has been set above
        PUSH    AF              ; and preserve

        CALL    SCANNING           ; routine SCANNING checks syntax of expression
                                ; and also sets flags.

        POP     AF              ; restore previous flags
        XOR     (IY+$01)        ; xor with FLAGS - bit 6 should be same
                                ; therefore will be reset.
        AND     $40             ; isolate bit 6.

;;; @brief ; DEF-FN-7
;;;
;;; ; DEF-FN-7
;;; @calls CHECK_END
;;; @jumps REPORT_C
;;; @jumpedfrom DEF_FN_2, DEF_FN_6
;;; @fallthrough UNSTACK_Z
DEF_FN_7:
        JP      NZ,REPORT_C        ; jump back to REPORT-C if the expected result
                                ; is not the same type.
                                ; 'Nonsense in BASIC'

        CALL    CHECK_END           ; routine CHECK-END will return early if
                                ; at end of statement and move onto next
                                ; else produce error report. >>>

                                ; There will be no return to here.

;;; @brief Returning early from subroutine
;;;
;;; All routines are capable of being run in two modes - syntax checking mode
;;; and runtime mode.  This routine is called often to allow a routine to return
;;; early if checking syntax.
;;;
;;; ; UNSTACK-Z
;;; @calls SYNTAX_Z
;;; @calledby PRINT_CR, PR_ITEM_1, PR_ITEM_2, PR_ITEM_3, STR_ALTER, CO_TEMP_4
UNSTACK_Z:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z sets zero flag if syntax
                                ; is being checked.

        POP     HL              ; drop the return address.
        RET      Z              ; return to previous call in chain if checking
                                ; syntax.

        JP      (HL)            ; jump to return address as BASIC program is
                                ; actually running.

;;; @brief Handle LPRINT command
;;;
;;; A simple form of 'PRINT #3' although it can output to 16 streams.
;;; Probably for compatibility with other BASICs particularly ZX81 BASIC.
;;; An extra UDG might have been better.
;;;
;;; ; LPRINT
;;; @jumps PRINT_1
LPRINT:
        LD      A,$03           ; the printer channel
        JR      PRINT_1         ; forward to PRINT-1

;;; @brief Handle PRINT commands
;;;
;;; The Spectrum's main stream output command.
;;; The default stream is stream 2 which is normally the upper screen
;;; of the computer. However the stream can be altered in range 0 - 15.
;;;
;;; ; PRINT
;;; @fallthrough PRINT_1
PRINT:
        LD      A,$02           ; the stream for the upper screen.

; The LPRINT command joins here.

;;; @brief ; PRINT-1
;;;
;;; ; PRINT-1
;;; @calls SYNTAX_Z, CHAN_OPEN, TEMPS, PRINT_2, CHECK_END
;;; @jumpedfrom LPRINT
PRINT_1:
        CALL    SYNTAX_Z            ; routine SYNTAX-Z checks if program running
        CALL    NZ,CHAN_OPEN        ; routine CHAN-OPEN if so
        CALL    TEMPS               ; routine TEMPS sets temporary colours.
        CALL    PRINT_2             ; routine PRINT-2 - the actual item
        CALL    CHECK_END           ; routine CHECK-END gives error if not at end
                                ; of statement
        RET                     ; and return >>>

; ------------------------------------
; this subroutine is called from above
; and also from INPUT.

;;; @brief ; PRINT-2
;;;
;;; ; PRINT-2
;;; @calls PR_END_Z
;;; @jumps PRINT_4
;;; @calledby PRINT_1, IN_ITEM_1
;;; @fallthrough PRINT_3
PRINT_2:
        RST     18H             ; GET-CHAR gets printable character
        CALL    PR_END_Z        ; routine PR-END-Z checks if more printing
        JR      Z,PRINT_4       ; to PRINT-4 if not     e.g. just 'PRINT :'

; This tight loop deals with combinations of positional controls and
; print items. An early return can be made from within the loop
; if the end of a print sequence is reached.

;;; @brief ; PRINT-3
;;;
;;; ; PRINT-3
;;; @calls PR_POSN_1, PR_ITEM_1
;;; @fallthrough PRINT_4
PRINT_3:
        CALL    PR_POSN_1           ; routine PR-POSN-1 returns zero if more
                                ; but returns early at this point if
                                ; at end of statement!
                                ;
        JR      Z,PRINT_3         ; to PRINT-3 if consecutive positioners

        CALL    PR_ITEM_1           ; routine PR-ITEM-1 deals with strings etc.
        CALL    PR_POSN_1           ; routine PR-POSN-1 for more position codes
        JR      Z,PRINT_3           ; loop back to PRINT-3 if so

;;; @brief ; PRINT-4
;;;
;;; ; PRINT-4
;;; @jumpedfrom PRINT_2
;;; @fallthrough PRINT_CR
PRINT_4:
        CP      $29             ; return now if this is ')' from input-item.
                                ; (see INPUT.)
        RET     Z               ; or continue and print carriage return in
                                ; runtime

;;; @brief Print carriage return
;;;
;;; This routine which continues from above prints a carriage return
;;; in run-time. It is also called once from PRINT-POSN.
;;;
;;; ; PRINT-CR
;;; @calls UNSTACK_Z
;;; @calledby PR_POSN_2
PRINT_CR:
        CALL    UNSTACK_Z           ; routine UNSTACK-Z

        LD      A,$0D           ; prepare a carriage return

        RST     10H             ; PRINT-A
        RET                     ; return


;;; @brief Print items
;;;
;;; This routine deals with print items as in
;;; PRINT AT 10,0;"The value of A is ";a
;;; It returns once a single item has been dealt with as it is part
;;; of a tight loop that considers sequences of positional and print items
;;;
;;; ; PR-ITEM-1
;;; @calls NEXT_2NUM, UNSTACK_Z, STK_TO_BC
;;; @jumps PR_ITEM_2, PR_AT_TAB
;;; @calledby PRINT_3, IN_NEXT_1
PR_ITEM_1:
        RST     18H             ; GET-CHAR
        CP      $AC             ; is character 'AT' ?
        JR      NZ,PR_ITEM_2    ; forward to PR-ITEM-2 if not.

        CALL    NEXT_2NUM           ; routine NEXT-2NUM  check for two comma
                                ; separated numbers placing them on the
                                ; calculator stack in runtime.
        CALL    UNSTACK_Z           ; routine UNSTACK-Z quits if checking syntax.

        CALL    STK_TO_BC           ; routine STK-TO-BC get the numbers in B and C.
        LD      A,$16               ; prepare the 'at' control.
        JR      PR_AT_TAB           ; forward to PR-AT-TAB to print the sequence.

; ---

;;; @brief ; PR-ITEM-2
;;;
;;; ; PR-ITEM-2
;;; @calls EXPT_1NUM, UNSTACK_Z, FIND_INT2
;;; @jumps PR_ITEM_3
;;; @jumpedfrom PR_ITEM_1
;;; @fallthrough PR_AT_TAB
PR_ITEM_2:
        CP      $AD             ; is character 'TAB' ?
        JR      NZ,PR_ITEM_3    ; to PR-ITEM-3 if not


        RST     20H                 ; NEXT-CHAR to address next character
        CALL    EXPT_1NUM           ; routine EXPT-1NUM
        CALL    UNSTACK_Z           ; routine UNSTACK-Z quits if checking syntax.

        CALL    FIND_INT2       ; routine FIND-INT2 puts integer in BC.
        LD      A,$17           ; prepare the 'tab' control.

;;; @brief ; PR-AT-TAB
;;;
;;; ; PR-AT-TAB
;;; @jumpedfrom PR_ITEM_1
PR_AT_TAB:
        RST     10H             ; PRINT-A outputs the control

        LD      A,C             ; first value to A
        RST     10H             ; PRINT-A outputs it.

        LD      A,B             ; second value
        RST     10H             ; PRINT-A

        RET                     ; return - item finished >>>

; ---

; Now consider paper 2; #2; a$

;;; @brief ; PR-ITEM-3
;;;
;;; ; PR-ITEM-3
;;; @calls CO_TEMP_3, STR_ALTER, SCANNING, UNSTACK_Z, STK_FETCH
;;; @jumps RTL_PR_STRING_HOOK
;;; @jumpedfrom PR_ITEM_2
PR_ITEM_3:
        CALL    CO_TEMP_3       ; routine CO-TEMP-3 will print any colour
        RET     NC              ; items - return if success.

        CALL    STR_ALTER       ; routine STR-ALTER considers new stream
        RET     NC              ; return if altered.

        CALL    SCANNING           ; routine SCANNING now to evaluate expression
        CALL    UNSTACK_Z          ; routine UNSTACK-Z if not runtime.

        BIT     6,(IY+$01)      ; test FLAGS  - Numeric or string result ?
        CALL    Z,STK_FETCH     ; routine STK-FETCH if string.
                                ; note no flags affected.

; It was a string expression - start in DE, length in BC
; Now enter a loop to print it

;; PR-STRING



; (original ROM code at this address, superseded above): JR L203C ; loop back to PR-STRING.
        JP      NZ,L04AA                ; if not zero, jump to L04AA
L203C:
        EX      DE,HL                   ; swap DE and HL
L203D:
        LD      A,B                     ; A = B
        OR      C                       ; A = A OR C
        DEC     BC                      ; BC = BC - 1
        RET     Z                       ; return if zero
        LD      A,(HL)                  ; A = (HL)
        JP      RTL_PR_STRING_HOOK     ; jump to the Arabic PR-STRING hook (file 11)

;;; @brief End of printing
;;;
;;; This subroutine returns zero if no further printing is required
;;; in the current statement.
;;; The first terminator is found in  escaped input items only,
;;; the others in print_items.
;;;
;;; ; PR-END-Z
;;; @calledby PRINT_2, PR_POSN_3
;;; @fallthrough PR_ST_END
PR_END_Z:
        CP      $29             ; is character a ')' ?
        RET     Z               ; return if so -        e.g. INPUT (p$); a$

;;; @brief ; PR-ST-END
;;;
;;; ; PR-ST-END
;;; @calledby REPORT_FA
PR_ST_END:
        CP      $0D             ; is it a carriage return ?
        RET     Z               ; return also -         e.g. PRINT a

        CP      $3A             ; is character a ':' ?
        RET                     ; return - zero flag will be set if so.
                                ;                       e.g. PRINT a :

;;; @brief Print position
;;;
;;; This routine considers a single positional character ';', ',', '''
;;;
;;; ; PR-POSN-1
;;; @calls SYNTAX_Z
;;; @jumps PR_POSN_3, PR_POSN_2
;;; @calledby PRINT_3, IN_ITEM_1, IN_NEXT_2
PR_POSN_1:
        RST     18H             ; GET-CHAR
        CP      $3B             ; is it ';' ?
                                ; i.e. print from last position.
        JR      Z,PR_POSN_3         ; forward to PR-POSN-3 if so.
                                ; i.e. do nothing.

        CP      $2C             ; is it ',' ?
                                ; i.e. print at next tabstop.
        JR      NZ,PR_POSN_2        ; forward to PR-POSN-2 if anything else.

        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,PR_POSN_3        ; forward to PR-POSN-3 if checking syntax.

        LD      A,$06           ; prepare the 'comma' control character.

        RST     10H             ; PRINT-A  outputs to current channel in
                                ; run-time.

        JR      PR_POSN_3           ; skip to PR-POSN-3.

; ---

; check for newline.

;;; @brief ; PR-POSN-2
;;;
;;; ; PR-POSN-2
;;; @calls PRINT_CR
;;; @jumpedfrom PR_POSN_1
;;; @fallthrough PR_POSN_3
PR_POSN_2:
        CP      $27             ; is character a "'" ? (newline)
        RET     NZ              ; return if no match              >>>

        CALL    PRINT_CR           ; routine PRINT-CR outputs a carriage return
                                ; in runtime only.

;;; @brief ; PR-POSN-3
;;;
;;; ; PR-POSN-3
;;; @calls PR_END_Z
;;; @jumps PR_POSN_4
;;; @jumpedfrom PR_POSN_1
;;; @fallthrough PR_POSN_4
PR_POSN_3:
        RST     20H             ; NEXT-CHAR to A.
        CALL    PR_END_Z        ; routine PR-END-Z checks if at end.
        JR      NZ,PR_POSN_4    ; to PR-POSN-4 if not.

        POP     BC              ; drop return address if at end.

;;; @brief ; PR-POSN-4
;;;
;;; ; PR-POSN-4
;;; @jumpedfrom PR_POSN_3
PR_POSN_4:
        CP      A               ; reset the zero flag.
        RET                     ; and return to loop or quit.

;;; @brief Alter stream
;;;
;;; This routine is called from PRINT ITEMS above, and also LIST as in
;;; LIST #15
;;;
;;; ; STR-ALTER
;;; @calls EXPT_1NUM, UNSTACK_Z, FIND_INT1, CHAN_OPEN
;;; @jumps REPORT_OA
;;; @calledby LIST_1, PR_ITEM_3
STR_ALTER:
        CP      $23             ; is character '#' ?
        SCF                     ; set carry flag.
        RET     NZ              ; return if no match.


        RST      20H                ; NEXT-CHAR
        CALL    EXPT_1NUM           ; routine EXPT-1NUM gets stream number
        AND     A                   ; prepare to exit early with carry reset
        CALL    UNSTACK_Z           ; routine UNSTACK-Z exits early if parsing
        CALL    FIND_INT1           ; routine FIND-INT1 gets number off stack
        CP      $10                 ; must be range 0 - 15 decimal.
        JP      NC,REPORT_OA        ; jump back to REPORT-Oa if not
                                ; 'Invalid stream'.

        CALL    CHAN_OPEN       ; routine CHAN-OPEN
        AND     A               ; clear carry - signal item dealt with.
        RET                     ; return

;;; @brief THE 'INPUT' COMMAND
;;;
;;; This command is mysterious.
;;;
;;;
;;; ; INPUT
;;; @calls SYNTAX_Z, CHAN_OPEN, CLS_LOWER
;;; @jumps INPUT_1
;;; @fallthrough INPUT_1
INPUT:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z to check if in runtime.

        JR      Z,INPUT_1         ; forward to INPUT-1 if checking syntax.

        LD      A,$01           ; select channel 'K' the keyboard for input.
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens the channel and sets
                                ; bit 0 of TV_FLAG.

;   Note. As a consequence of clearing the lower screen channel 0 is made
;   the current channel so the above two instructions are superfluous.

        CALL    CLS_LOWER           ; routine CLS-LOWER clears the lower screen
                                ; and sets DF_SZ to two and TV_FLAG to $01.

;;; @brief ; INPUT-1
;;;
;;; ; INPUT-1
;;; @calls IN_ITEM_1, CHECK_END
;;; @jumps INPUT_2
;;; @jumpedfrom INPUT
;;; @fallthrough INPUT_2
INPUT_1:
        LD      (IY+$02),$01    ; update TV_FLAG - signal lower screen in use
                                ; ensuring that the correct set of system
                                ; variables are updated and that the border
                                ; colour is used.

;   Note. The Complete Spectrum ROM Disassembly incorrectly names DF-SZ as the
;   system variable that is updated above and if, as some have done, you make
;   this unnecessary alteration then there will be two blank lines between the
;   lower screen and the upper screen areas which will also scroll wrongly.

        CALL    IN_ITEM_1           ; routine IN-ITEM-1 to handle the input.

        CALL    CHECK_END           ; routine CHECK-END will make an early exit
                                ; if checking syntax. >>>

;   Keyboard input has been made and it remains to adjust the upper
;   screen in case the lower two lines have been extended upwards.

        LD      BC,(S_POSN)      ; fetch S_POSN current line/column of
                                ; the upper screen.
        LD      A,(DF_SZ)       ; fetch DF_SZ the display file size of
                                ; the lower screen.
        CP      B               ; test that lower screen does not overlap
        JR      C,INPUT_2       ; forward to INPUT-2 if not.

; the two screens overlap so adjust upper screen.

        LD      C,$21           ; set column of upper screen to leftmost.
        LD      B,A             ; and line to one above lower screen.
                                ; continue forward to update upper screen
                                ; print position.

;;; @brief ; INPUT-2
;;;
;;; ; INPUT-2
;;; @calls CL_SET
;;; @jumps CLS_LOWER
;;; @jumpedfrom INPUT_1
INPUT_2:
        LD      (S_POSN),BC      ; set S_POSN update upper screen line/column.
        LD      A,$19           ; subtract from twenty five
        SUB     B               ; the new line number.
        LD      (SCR_CT),A       ; and place result in SCR_CT - scroll count.
        RES     0,(IY+$02)      ; update TV_FLAG - signal main screen in use.

        CALL    CL_SET           ; routine CL-SET sets the print position
                                ; system variables for the upper screen.

        JP      CLS_LOWER           ; jump back to CLS-LOWER and make
                                ; an indirect exit >>.

;;; @brief INPUT ITEM subroutine
;;;
;;;   This subroutine deals with the input items and print items.
;;;   from  the current input channel.
;;;   It is only called from the above INPUT routine but was obviously
;;;   once called from somewhere else in another context.
;;;
;;; ; IN-ITEM-1
;;; @calls PR_POSN_1, PRINT_2
;;; @jumps IN_ITEM_2, REPORT_C, IN_NEXT_2
;;; @calledby INPUT_1
;;; @jumpedfrom IN_NEXT_2
IN_ITEM_1:
        CALL    PR_POSN_1           ; routine PR-POSN-1 deals with a single
                                ; position item at each call.
        JR      Z,IN_ITEM_1         ; back to IN-ITEM-1 until no more in a
                                ; sequence.

        CP      $28             ; is character '(' ?
        JR      NZ,IN_ITEM_2    ; forward to IN-ITEM-2 if not.

;   any variables within braces will be treated as part, or all, of the prompt
;   instead of being used as destination variables.

        RST     20H             ; NEXT-CHAR
        CALL    PRINT_2         ; routine PRINT-2 to output the dynamic
                                ; prompt.

        RST     18H             ; GET-CHAR
        CP      $29             ; is character a matching ')' ?
        JP      NZ,REPORT_C     ; jump back to REPORT-C if not.
                                ; 'Nonsense in BASIC'.

        RST     20H             ; NEXT-CHAR
        JP      IN_NEXT_2       ; forward to IN-NEXT-2

; ---

;;; @brief ; IN-ITEM-2
;;;
;;; ; IN-ITEM-2
;;; @calls CLASS_01
;;; @jumps IN_ITEM_3, REPORT_C, IN_PROMPT
;;; @jumpedfrom IN_ITEM_1
IN_ITEM_2:
        CP      $CA             ; is the character the token 'LINE' ?
        JR      NZ,IN_ITEM_3    ; forward to IN-ITEM-3 if not.

        RST     20H             ; NEXT-CHAR - variable must come next.
        CALL    CLASS_01        ; routine CLASS-01 returns destination
                                ; address of variable to be assigned.
                                ; or generates an error if no variable
                                ; at this position.

        SET     7,(IY+$37)      ; update FLAGX  - signal handling INPUT LINE
        BIT     6,(IY+$01)      ; test FLAGS  - numeric or string result ?
        JP      NZ,REPORT_C     ; jump back to REPORT-C if not string
                                ; 'Nonsense in BASIC'.

        JR      IN_PROMPT           ; forward to IN-PROMPT to set up workspace.

; ---

;   the jump was here for other variables.

;;; @brief ; IN-ITEM-3
;;;
;;; ; IN-ITEM-3
;;; @calls ALPHA, CLASS_01
;;; @jumps IN_NEXT_1
;;; @jumpedfrom IN_ITEM_2
;;; @fallthrough IN_PROMPT
IN_ITEM_3:
        CALL     ALPHA          ; routine ALPHA checks if character is
                                ; a suitable variable name.
        JP      NC,IN_NEXT_1        ; forward to IN-NEXT-1 if not

        CALL    CLASS_01           ; routine CLASS-01 returns destination
                                ; address of variable to be assigned.
        RES     7,(IY+$37)      ; update FLAGX  - signal not INPUT LINE.

;;; @brief ; IN-PROMPT
;;;
;;; ; IN-PROMPT
;;; @calls SYNTAX_Z, SET_WORK
;;; @jumps IN_NEXT_2, IN_PR_2, IN_PR_1
;;; @jumpedfrom IN_ITEM_2
;;; @fallthrough IN_PR_1
IN_PROMPT:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JP      Z,IN_NEXT_2        ; forward to IN-NEXT-2 if checking syntax.

        CALL    SET_WORK        ; routine SET-WORK clears workspace.
        LD      HL,FLAGX        ; point to system variable FLAGX
        RES     6,(HL)          ; signal string result.
        SET     5,(HL)          ; signal in Input Mode for editor.
        LD      BC,$0001        ; initialize space required to one for
                                ; the carriage return.
        BIT     7,(HL)          ; test FLAGX - INPUT LINE in use ?
        JR      NZ,IN_PR_2      ; forward to IN-PR-2 if so as that is
                                ; all the space that is required.

        LD      A,(FLAGS)       ; load accumulator from FLAGS
        AND     $40             ; mask to test BIT 6 of FLAGS and clear
                                ; the other bits in A.
                                ; numeric result expected ?
        JR      NZ,IN_PR_1        ; forward to IN-PR-1 if so

        LD      C,$03           ; increase space to three bytes for the
                                ; pair of surrounding quotes.

;;; @brief ; IN-PR-1
;;;
;;; ; IN-PR-1
;;; @jumpedfrom IN_PROMPT
;;; @fallthrough IN_PR_2
IN_PR_1:
        OR      (HL)            ; if numeric result, set bit 6 of FLAGX.
        LD      (HL),A          ; and update system variable

;;; @brief ; IN-PR-2
;;;
;;; ; IN-PR-2
;;; @jumps IN_PR_3
;;; @jumpedfrom IN_PROMPT
;;; @fallthrough IN_PR_3
IN_PR_2:
        RST     30H             ; BC-SPACES opens 1 or 3 bytes in workspace
        LD      (HL),$0D        ; insert carriage return at last new location.
        LD      A,C             ; fetch the length, one or three.
        RRCA                    ; lose bit 0.
        RRCA                    ; test if quotes required.
        JR      NC,IN_PR_3      ; forward to IN-PR-3 if not.

        LD      A,$22           ; load the '"' character
        LD      (DE),A          ; place quote in first new location at DE.
        DEC     HL              ; decrease HL - from carriage return.
        LD      (HL),A          ; and place a quote in second location.

;;; @brief ; IN-PR-3
;;;
;;; ; IN-PR-3
;;; @jumps IN_VAR_3
;;; @jumpedfrom IN_PR_2
;;; @fallthrough IN_VAR_1
IN_PR_3:
        LD      (K_CUR),HL      ; set keyboard cursor K_CUR to HL
        BIT     7,(IY+$37)      ; test FLAGX  - is this INPUT LINE ??
        JR      NZ,IN_VAR_3     ; forward to IN-VAR-3 if so as input will
                                ; be accepted without checking its syntax.

        LD      HL,(CH_ADD)      ; fetch CH_ADD
        PUSH    HL              ; and save on stack.
        LD      HL,(ERR_SP)      ; fetch ERR_SP
        PUSH    HL              ; and save on stack

;;; @brief ; IN-VAR-1
;;;
;;; ; IN-VAR-1
;;; @jumps IN_VAR_2
;;; @fallthrough IN_VAR_2
IN_VAR_1:
        LD      HL,IN_VAR_1     ; address: IN-VAR-1 - this address
        PUSH    HL              ; is saved on stack to handle errors.
        BIT     4,(IY+$30)      ; test FLAGS2  - is K channel in use ?
        JR      Z,IN_VAR_2      ; forward to IN-VAR-2 if not using the
                                ; keyboard for input. (??)

        LD      (ERR_SP),SP      ; set ERR_SP to point to IN-VAR-1 on stack.

;;; @brief ; IN-VAR-2
;;;
;;; ; IN-VAR-2
;;; @calls REMOVE_FP, EDITOR, IN_ASSIGN
;;; @jumps IN_VAR_4
;;; @jumpedfrom IN_VAR_1
IN_VAR_2:
        LD      HL,(WORKSP)      ; set HL to WORKSP - start of workspace.
        CALL    REMOVE_FP       ; routine REMOVE-FP removes floating point
                                ; forms when looping in error condition.
        LD      (IY+$00),$FF    ; set ERR_NR to 'OK' cancelling the error.
                                ; but X_PTR causes flashing error marker
                                ; to be displayed at each call to the editor.
        CALL    EDITOR           ; routine EDITOR allows input to be entered
                                ; or corrected if this is second time around.

; if we pass to next then there are no system errors

        RES     7,(IY+$01)      ; update FLAGS  - signal checking syntax
        CALL    IN_ASSIGN       ; routine IN-ASSIGN checks syntax using
                                ; the VAL-FET-2 and powerful SCANNING routines.
                                ; any syntax error and its back to IN-VAR-1.
                                ; but with the flashing error marker showing
                                ; where the error is.
                                ; Note. the syntax of string input has to be
                                ; checked as the user may have removed the
                                ; bounding quotes or escaped them as with
                                ; "hat" + "stand" for example.
; proceed if syntax passed.

        JR      IN_VAR_4           ; jump forward to IN-VAR-4

; ---

; the jump was to here when using INPUT LINE.

;;; @brief ; IN-VAR-3
;;;
;;; ; IN-VAR-3
;;; @calls EDITOR
;;; @jumpedfrom IN_PR_3
;;; @fallthrough IN_VAR_4
IN_VAR_3:
        CALL    EDITOR           ; routine EDITOR is called for input

; when ENTER received rejoin other route but with no syntax check.

; INPUT and INPUT LINE converge here.

;;; @brief ; IN-VAR-4
;;;
;;; ; IN-VAR-4
;;; @calls IN_CHAN_K, L111D, CL_SET
;;; @jumps IN_VAR_5
;;; @jumpedfrom IN_VAR_2
;;; @fallthrough IN_VAR_5
IN_VAR_4:
        LD      (IY+$22),$00    ; set K_CUR_hi to a low value so that the cursor
                                ; no longer appears in the input line.

        CALL    IN_CHAN_K           ; routine IN-CHAN-K tests if the keyboard
                                ; is being used for input.
        JR      NZ,IN_VAR_5        ; forward to IN-VAR-5 if using another input
                                ; channel.

; continue here if using the keyboard.

        CALL    L111D           ; routine ED-COPY overprints the edit line
                                ; to the lower screen. The only visible
                                ; affect is that the cursor disappears.
                                ; if you're inputting more than one item in
                                ; a statement then that becomes apparent.

        LD      BC,(ECHO_E)      ; fetch line and column from ECHO_E
        CALL    CL_SET          ; routine CL-SET sets S-POSNL to those
                                ; values.

; if using another input channel rejoin here.

;;; @brief ; IN-VAR-5
;;;
;;; ; IN-VAR-5
;;; @calls IN_ASSIGN
;;; @jumps IN_VAR_6, IN_NEXT_2
;;; @jumpedfrom IN_VAR_4
IN_VAR_5:
        LD      HL,FLAGX        ; point HL to FLAGX
        RES     5,(HL)          ; signal not in input mode
        BIT     7,(HL)          ; is this INPUT LINE ?
        RES     7,(HL)          ; cancel the bit anyway.
        JR      NZ,IN_VAR_6     ; forward to IN-VAR-6 if INPUT LINE.

        POP     HL              ; drop the looping address
        POP     HL              ; drop the address of previous
                                ; error handler.
        LD      (ERR_SP),HL      ; set ERR_SP to point to it.
        POP     HL              ; drop original CH_ADD which points to
                                ; INPUT command in BASIC line.
        LD      (X_PTR),HL      ; save in X_PTR while input is assigned.
        SET     7,(IY+$01)      ; update FLAGS - Signal running program
        CALL    IN_ASSIGN       ; routine IN-ASSIGN is called again
                                ; this time the variable will be assigned
                                ; the input value without error.
                                ; Note. the previous example now
                                ; becomes "hatstand"

        LD      HL,(X_PTR)      ; fetch stored CH_ADD value from X_PTR.
        LD      (IY+$26),$00    ; set X_PTR_hi so that iy is no longer relevant.
        LD      (CH_ADD),HL      ; put restored value back in CH_ADD
        JR      IN_NEXT_2       ; forward to IN-NEXT-2 to see if anything
                                ; more in the INPUT list.

; ---

; the jump was to here with INPUT LINE only

;;; @brief ; IN-VAR-6
;;;
;;; ; IN-VAR-6
;;; @calls STK_STO, LET
;;; @jumps IN_NEXT_2
;;; @jumpedfrom IN_VAR_5
IN_VAR_6:
        LD      HL,(STKBOT)      ; STKBOT points to the end of the input.
        LD      DE,(WORKSP)      ; WORKSP points to the beginning.
        SCF                     ; prepare for true subtraction.
        SBC     HL,DE           ; subtract to get length
        LD      B,H             ; transfer it to
        LD      C,L             ; the BC register pair.
        CALL    STK_STO         ; routine STK-STO-$ stores parameters on
                                ; the calculator stack.
        CALL    LET           ; routine LET assigns it to destination.
        JR      IN_NEXT_2     ; forward to IN-NEXT-2 as print items
                                ; not allowed with INPUT LINE.
                                ; Note. that "hat" + "stand" will, for
                                ; example, be unchanged as also would
                                ; 'PRINT "Iris was here"'.

; ---

; the jump was to here when ALPHA found more items while looking for
; a variable name.

;;; @brief ; IN-NEXT-1
;;;
;;; ; IN-NEXT-1
;;; @calls PR_ITEM_1
;;; @jumpedfrom IN_ITEM_3
;;; @fallthrough IN_NEXT_2
IN_NEXT_1:
        CALL    PR_ITEM_1           ; routine PR-ITEM-1 considers further items.

;;; @brief ; IN-NEXT-2
;;;
;;; ; IN-NEXT-2
;;; @calls PR_POSN_1
;;; @jumps IN_ITEM_1
;;; @jumpedfrom IN_ITEM_1, IN_PROMPT, IN_VAR_5, IN_VAR_6
IN_NEXT_2:
        CALL    PR_POSN_1           ; routine PR-POSN-1 handles a position item.
        JP      Z,IN_ITEM_1         ; jump back to IN-ITEM-1 if the zero flag
                                ; indicates more items are present.

        RET                     ; return.

;;; @brief INPUT ASSIGNMENT Subroutine
;;;
;;; This subroutine is called twice from the INPUT command when normal
;;; keyboard input is assigned. On the first occasion syntax is checked
;;; using SCANNING. The final call with the syntax flag reset is to make
;;; the assignment.
;;;
;;; ; IN-ASSIGN
;;; @calls VAL_FET_2
;;; @jumps IN_STOP
;;; @calledby IN_VAR_2, IN_VAR_5
;;; @fallthrough REPORT_CB
IN_ASSIGN:
        LD      HL,(WORKSP)      ; fetch WORKSP start of input
        LD      (CH_ADD),HL      ; set CH_ADD to first character

        RST     18H             ; GET-CHAR ignoring leading white-space.
        CP      $E2             ; is it 'STOP'
        JR      Z,IN_STOP       ; forward to IN-STOP if so.

        LD      A,(FLAGX)       ; load accumulator from FLAGX
        CALL    VAL_FET_2       ; routine VAL-FET-2 makes assignment
                                ; or goes through the motions if checking
                                ; syntax. SCANNING is used.

        RST     18H             ; GET-CHAR
        CP      $0D             ; is it carriage return ?
        RET     Z               ; return if so
                                ; either syntax is OK
                                ; or assignment has been made.

; if another character was found then raise an error.
; User doesn't see report but the flashing error marker
; appears in the lower screen.

;;; @brief ; REPORT-Cb
;;;
;;; ; REPORT-Cb
REPORT_CB:
        RST     08H             ; ERROR-1
        DB          $0B         ; Error Report: Nonsense in BASIC

;;; @brief ; IN-STOP
;;;
;;; ; IN-STOP
;;; @calls SYNTAX_Z
;;; @jumpedfrom IN_ASSIGN
;;; @fallthrough REPORT_H
IN_STOP:
        CALL    SYNTAX_Z        ; routine SYNTAX-Z (UNSTACK-Z?)
        RET     Z               ; return if checking syntax
                                ; as user wouldn't see error report.
                                ; but generate visible error report
                                ; on second invocation.

;;; @brief ; REPORT-H
;;;
;;; ; REPORT-H
REPORT_H:
        RST     08H             ; ERROR-1
        DB          $10         ; Error Report: STOP in INPUT

;;; @brief THE 'TEST FOR CHANNEL K' SUBROUTINE
;;;
;;;   This subroutine is called once from the keyboard INPUT command to check if
;;;   the input routine in use is the one for the keyboard.
;;;
;;; ; IN-CHAN-K
;;; @calledby IN_VAR_4
IN_CHAN_K:
        LD      HL,(CURCHL)      ; fetch address of current channel CURCHL
        INC     HL              ;
        INC     HL              ; advance past
        INC     HL              ; input and
        INC     HL              ; output streams
        LD      A,(HL)          ; fetch the channel identifier.
        CP      $4B             ; test for 'K'
        RET                     ; return with zero set if keyboard is use.

;;; @brief Colour Item Routines
;;;
;;; These routines have 3 entry points -
;;; 1) CO-TEMP-2 to handle a series of embedded Graphic colour items.
;;; 2) CO-TEMP-3 to handle a single embedded print colour item.
;;; 3) CO TEMP-4 to handle a colour command such as FLASH 1
;;;
;;; "Due to a bug, if you bring in a peripheral channel and later use a colour
;;;  statement, colour controls will be sent to it by mistake." - Steven Vickers
;;;  Pitman Pocket Guide, 1984.
;;;
;;; To be fair, this only applies if the last channel was other than 'K', 'S'
;;; or 'P', which are all that are supported by this ROM, but if that last
;;; channel was a microdrive file, network channel etc. then
;;; PAPER 6; CLS will not turn the screen yellow and
;;; CIRCLE INK 2; 128,88,50 will not draw a red circle.
;;;
;;; This bug does not apply to embedded PRINT items as it is quite permissible
;;; to mix stream altering commands and colour items.
;;; The fix therefore would be to ensure that CLASS-07 and CLASS-09 make
;;; channel 'S' the current channel when not checking syntax.
;;;
;;; ; CO-TEMP-1
;;; @jumpedfrom CO_TEMP_2
;;; @fallthrough CO_TEMP_2
CO_TEMP_1:
        RST     20H             ; NEXT-CHAR

; -> Entry point from CLASS-09. Embedded Graphic colour items.
; e.g. PLOT INK 2; PAPER 8; 128,88
; Loops till all colour items output, finally addressing the coordinates.

;;; @brief ; CO-TEMP-2
;;;
;;; ; CO-TEMP-2
;;; @calls CO_TEMP_3
;;; @jumps CO_TEMP_1, REPORT_C
;;; @calledby CL_09_1
CO_TEMP_2:
        CALL    CO_TEMP_3       ; routine CO-TEMP-3 to output colour control.
        RET     C               ; return if nothing more to output. ->


        RST     18H             ; GET-CHAR
        CP      $2C             ; is it ',' separator ?
        JR      Z,CO_TEMP_1     ; back if so to CO-TEMP-1

        CP      $3B             ; is it ';' separator ?
        JR      Z,CO_TEMP_1     ; back to CO-TEMP-1 for more.

        JP      REPORT_C           ; to REPORT-C (REPORT-Cb is within range)
                                ; 'Nonsense in BASIC'

;;; @brief CO-TEMP-3
;;;
;;; -> this routine evaluates and outputs a colour control and parameter.
;;; It is called from above and also from PR-ITEM-3 to handle a single embedded
;;; print item e.g. PRINT PAPER 6; "Hi". In the latter case, the looping for
;;; multiple items is within the PR-ITEM routine.
;;; It is quite permissible to send these to any stream.
;;;
;;; ; CO-TEMP-3
;;; @calledby PR_ITEM_3, CO_TEMP_2
;;; @fallthrough CO_TEMP_4
CO_TEMP_3:
        CP      $D9             ; is it 'INK' ?
        RET     C               ; return if less.

        CP      $DF             ; compare with 'OUT'
        CCF                     ; Complement Carry Flag
        RET     C               ; return if greater than 'OVER', $DE.

        PUSH    AF              ; save the colour token.

        RST     20H             ; address NEXT-CHAR
        POP     AF              ; restore token and continue.

; -> this entry point used by CLASS-07. e.g. the command PAPER 6.

;;; @brief ; CO-TEMP-4
;;;
;;; ; CO-TEMP-4
;;; @calls EXPT_1NUM, UNSTACK_Z, FIND_INT1
;;; @calledby L1CA5
CO_TEMP_4:
        SUB     $C9             ; reduce to control character $10 (INK)
                                ; thru $15 (OVER).
        PUSH    AF              ; save control.
        CALL    EXPT_1NUM       ; routine EXPT-1NUM stacks addressed
                                ; parameter on calculator stack.
        POP     AF              ; restore control.
        AND     A               ; clear carry

        CALL    UNSTACK_Z           ; routine UNSTACK-Z returns if checking syntax.

        PUSH    AF              ; save again
        CALL    FIND_INT1       ; routine FIND-INT1 fetches parameter to A.
        LD      D,A             ; transfer now to D
        POP     AF              ; restore control.

        RST     10H             ; PRINT-A outputs the control to current
                                ; channel.
        LD      A,D             ; transfer parameter to A.

        RST     10H             ; PRINT-A outputs parameter.
        RET                     ; return. ->

; -------------------------------------------------------------------------
;
;         {fl}{br}{   paper   }{  ink    }    The temporary colour attributes
;          ___ ___ ___ ___ ___ ___ ___ ___    system variable.
; ATTR_T  |   |   |   |   |   |   |   |   |
;         |   |   |   |   |   |   |   |   |
; 23695   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
;
;         {fl}{br}{   paper   }{  ink    }    The temporary mask used for
;          ___ ___ ___ ___ ___ ___ ___ ___    transparent colours. Any bit
; MASK_T  |   |   |   |   |   |   |   |   |   that is 1 shows that the
;         |   |   |   |   |   |   |   |   |   corresponding attribute is
; 23696   |___|___|___|___|___|___|___|___|   taken not from ATTR-T but from
;           7   6   5   4   3   2   1   0     what is already on the screen.
;
;
;         {paper9 }{ ink9 }{ inv1 }{ over1}   The print flags. Even bits are
;          ___ ___ ___ ___ ___ ___ ___ ___    temporary flags. The odd bits
; P_FLAG  |   |   |   |   |   |   |   |   |   are the permanent flags.
;         | p | t | p | t | p | t | p | t |
; 23697   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
; -----------------------------------------------------------------------

;;; @brief The colour system variable handler.
;;;
;;; This is an exit branch from PO-1-OPER, PO-2-OPER
;;; A holds control $10 (INK) to $15 (OVER)
;;; D holds parameter 0-9 for ink/paper 0,1 or 8 for bright/flash,
;;; 0 or 1 for over/inverse.
;;;
;;; ; CO-TEMP-5
;;; @jumps CO_TEMP_7, CO_TEMP_C, CO_TEMP_6
;;; @jumpedfrom RTL_PO_FETCH_EXT
;;; @fallthrough CO_TEMP_6
CO_TEMP_5:
        SUB     $11             ; reduce range $FF-$04
        ADC     A,$00           ; add in carry if INK
        JR      Z,CO_TEMP_7     ; forward to CO-TEMP-7 with INK and PAPER.

        SUB     $02             ; reduce range $FF-$02
        ADC     A,$00           ; add carry if FLASH
        JR      Z,CO_TEMP_C     ; forward to CO-TEMP-C with FLASH and BRIGHT.

        CP      $01             ; is it 'INVERSE' ?
        LD      A,D             ; fetch parameter for INVERSE/OVER
        LD      B,$01           ; prepare OVER mask setting bit 0.
        JR      NZ,CO_TEMP_6    ; forward to CO-TEMP-6 if OVER

        RLCA                    ; shift bit 0
        RLCA                    ; to bit 2
        LD      B,$04           ; set bit 2 of mask for inverse.

;;; @brief ; CO-TEMP-6
;;;
;;; ; CO-TEMP-6
;;; @jumps REPORT_K, CO_CHANGE
;;; @jumpedfrom CO_TEMP_5
CO_TEMP_6:
        LD      C,A             ; save the A
        LD      A,D             ; re-fetch parameter
        CP      $02             ; is it less than 2
        JR      NC,REPORT_K     ; to REPORT-K if not 0 or 1.
                                ; 'Invalid colour'.

        LD      A,C             ; restore A
        LD      HL,P_FLAG        ; address system variable P_FLAG
        JR      CO_CHANGE       ; forward to exit via routine CO-CHANGE

; ---

; the branch was here with INK/PAPER and carry set for INK.

;;; @brief ; CO-TEMP-7
;;;
;;; ; CO-TEMP-7
;;; @jumps CO_TEMP_8
;;; @jumpedfrom CO_TEMP_5
;;; @fallthrough CO_TEMP_8
CO_TEMP_7:
        LD      A,D             ; fetch parameter
        LD      B,$07           ; set ink mask 00000111
        JR      C,CO_TEMP_8     ; forward to CO-TEMP-8 with INK

        RLCA                    ; shift bits 0-2
        RLCA                    ; to
        RLCA                    ; bits 3-5
        LD      B,$38           ; set paper mask 00111000

; both paper and ink rejoin here

;;; @brief ; CO-TEMP-8
;;;
;;; ; CO-TEMP-8
;;; @jumps CO_TEMP_9
;;; @jumpedfrom CO_TEMP_7
;;; @fallthrough REPORT_K
CO_TEMP_8:
        LD      C,A             ; value to C
        LD      A,D             ; fetch parameter
        CP      $0A             ; is it less than 10d ?
        JR      C,CO_TEMP_9     ; forward to CO-TEMP-9 if so.

; ink 10 etc. is not allowed.

;;; @brief ; REPORT-K
;;;
;;; ; REPORT-K
;;; @jumpedfrom CO_TEMP_6, CO_TEMP_D, BORDER
REPORT_K:
        RST     08H             ; ERROR-1
        DB          $13         ; Error Report: Invalid colour

;;; @brief ; CO-TEMP-9
;;;
;;; ; CO-TEMP-9
;;; @jumps CO_TEMP_B, CO_TEMP_A
;;; @jumpedfrom CO_TEMP_8
;;; @fallthrough CO_TEMP_A
CO_TEMP_9:
        LD      HL,ATTR_T        ; address system variable ATTR_T initially.
        CP      $08             ; compare with 8
        JR      C,CO_TEMP_B     ; forward to CO-TEMP-B with 0-7.

        LD      A,(HL)          ; fetch temporary attribute as no change.
        JR      Z,CO_TEMP_A     ; forward to CO-TEMP-A with INK/PAPER 8

; it is either ink 9 or paper 9 (contrasting)

        OR      B               ; or with mask to make white
        CPL                     ; make black and change other to dark
        AND     $24             ; 00100100
        JR      Z,CO_TEMP_A     ; forward to CO-TEMP-A if black and
                                ; originally light.

        LD      A,B             ; else just use the mask (white)

;;; @brief ; CO-TEMP-A
;;;
;;; ; CO-TEMP-A
;;; @jumpedfrom CO_TEMP_9
;;; @fallthrough CO_TEMP_B
CO_TEMP_A:
        LD      C,A             ; save A in C

;;; @brief ; CO-TEMP-B
;;;
;;; ; CO-TEMP-B
;;; @calls CO_CHANGE
;;; @jumpedfrom CO_TEMP_9
;;; @fallthrough CO_CHANGE
CO_TEMP_B:
        LD      A,C             ; load colour to A
        CALL    CO_CHANGE       ; routine CO-CHANGE addressing ATTR-T

        LD      A,$07           ; put 7 in accumulator
        CP      D               ; compare with parameter
        SBC     A,A             ; $00 if 0-7, $FF if 8
        CALL    CO_CHANGE       ; routine CO-CHANGE addressing MASK-T
                                ; mask returned in A.

; now consider P-FLAG.

        RLCA                    ; 01110000 or 00001110
        RLCA                    ; 11100000 or 00011100
        AND     $50             ; 01000000 or 00010000  (AND 01010000)
        LD      B,A             ; transfer to mask
        LD      A,$08           ; load A with 8
        CP      D               ; compare with parameter
        SBC     A,A             ; $FF if was 9,  $00 if 0-8
                                ; continue while addressing P-FLAG
                                ; setting bit 4 if ink 9
                                ; setting bit 6 if paper 9

;;; @brief Handle change of colour
;;;
;;; This routine addresses a system variable ATTR_T, MASK_T or P-FLAG in HL.
;;; colour value in A, mask in B.
;;;
;;; ; CO-CHANGE
;;; @calledby CO_TEMP_B, CO_TEMP_E
;;; @jumpedfrom CO_TEMP_6, CO_TEMP_E
CO_CHANGE:
        XOR     (HL)            ; impress bits specified
        AND     B               ; by mask
        XOR     (HL)            ; on system variable.
        LD      (HL),A          ; update system variable.
        INC     HL              ; address next location.
        LD      A,B             ; put current value of mask in A
        RET                     ; return.

; ---

; the branch was here with flash and bright

;;; @brief ; CO-TEMP-C
;;;
;;; ; CO-TEMP-C
;;; @jumps CO_TEMP_D
;;; @jumpedfrom CO_TEMP_5
;;; @fallthrough CO_TEMP_D
CO_TEMP_C:
        SBC     A,A             ; set zero flag for bright.
        LD      A,D             ; fetch original parameter 0,1 or 8
        RRCA                    ; rotate bit 0 to bit 7
        LD      B,$80           ; mask for flash 10000000
        JR      NZ,CO_TEMP_D    ; forward to CO-TEMP-D if flash

        RRCA                    ; rotate bit 7 to bit 6
        LD      B,$40           ; mask for bright 01000000

;;; @brief ; CO-TEMP-D
;;;
;;; ; CO-TEMP-D
;;; @jumps CO_TEMP_E, REPORT_K
;;; @jumpedfrom CO_TEMP_C
;;; @fallthrough CO_TEMP_E
CO_TEMP_D:
        LD      C,A             ; store value in C
        LD      A,D             ; fetch parameter
        CP      $08             ; compare with 8
        JR      Z,CO_TEMP_E     ; forward to CO-TEMP-E if 8

        CP      $02             ; test if 0 or 1
        JR      NC,REPORT_K     ; back to REPORT-K if not
                                ; 'Invalid colour'

;;; @brief ; CO-TEMP-E
;;;
;;; ; CO-TEMP-E
;;; @calls CO_CHANGE
;;; @jumps CO_CHANGE
;;; @jumpedfrom CO_TEMP_D
CO_TEMP_E:
        LD      A,C             ; value to A
        LD      HL,ATTR_T        ; address ATTR_T
        CALL    CO_CHANGE       ; routine CO-CHANGE addressing ATTR_T
        LD      A,C             ; fetch value
        RRCA                    ; for flash8/bright8 complete
        RRCA                    ; rotations to put set bit in
        RRCA                    ; bit 7 (flash) bit 6 (bright)
        JR      CO_CHANGE       ; back to CO-CHANGE addressing MASK_T
                                ; and indirect return.

;;; @brief Handle BORDER command
;;;
;;; Command syntax example: BORDER 7
;;; This command routine sets the border to one of the eight colours.
;;; The colours used for the lower screen are based on this.
;;;
;;; ; BORDER
;;; @calls FIND_INT1
;;; @jumps REPORT_K, BORDER_1
;;; @fallthrough BORDER_1
BORDER:
        CALL    FIND_INT1       ; routine FIND-INT1
        CP      $08             ; must be in range 0 (black) to 7 (white)
        JR      NC,REPORT_K     ; back to REPORT-K if not
                                ; 'Invalid colour'.

        OUT     ($FE),A         ; outputting to port effects an immediate
                                ; change.
        RLCA                    ; shift the colour to
        RLCA                    ; the paper bits setting the
        RLCA                    ; ink colour black.
        BIT     5,A             ; is the number light coloured ?
                                ; i.e. in the range green to white.
        JR      NZ,BORDER_1        ; skip to BORDER-1 if so

        XOR     $07             ; make the ink white.

;;; @brief ; BORDER-1
;;;
;;; ; BORDER-1
;;; @jumpedfrom BORDER
BORDER_1:
        LD      (BORDCR),A       ; update BORDCR with new paper/ink
        RET                     ; return.

;;; @brief Get pixel address
;;;
;;; ; PIXEL-ADD
;;; @jumps REPORT_BC
;;; @calledby POINT_SUB, PLOT_SUB
PIXEL_ADD:
        LD      A,$AF           ; load with 175 decimal.
        SUB     B               ; subtract the y value.
        JP      C,REPORT_BC     ; jump forward to REPORT-Bc if greater.
                                ; 'Integer out of range'

; the high byte is derived from Y only.
; the first 3 bits are always 010
; the next 2 bits denote in which third of the screen the byte is.
; the last 3 bits denote in which of the 8 scan lines within a third
; the byte is located. There are 24 discrete values.


        LD      B,A             ; the line number from top of screen to B.
        AND     A               ; clear carry (already clear)
        RRA                     ;                     0xxxxxxx
        SCF                     ; set carry flag
        RRA                     ;                     10xxxxxx
        AND     A               ; clear carry flag
        RRA                     ;                     010xxxxx

        XOR     B               ;
        AND     $F8             ; keep the top 5 bits 11111000
        XOR     B               ;                     010xxbbb
        LD      H,A             ; transfer high byte to H.

; the low byte is derived from both X and Y.

        LD      A,C             ; the x value 0-255.
        RLCA                    ;
        RLCA                    ;
        RLCA                    ;
        XOR     B               ; the y value
        AND     $C7             ; apply mask             11000111
        XOR     B               ; restore unmasked bits  xxyyyxxx
        RLCA                    ; rotate to              xyyyxxxx
        RLCA                    ; required position.     yyyxxxxx
        LD      L,A             ; low byte to L.

; finally form the pixel position in A.

        LD      A,C             ; x value to A
        AND     $07             ; mod 8
        RET                     ; return

;;; @brief Point Subroutine
;;;
;;; The point subroutine is called from s-point via the scanning functions
;;; table.
;;;
;;; ; POINT-SUB
;;; @calls STK_TO_BC, PIXEL_ADD
;;; @calledby S_POINT
;;; @fallthrough POINT_LP
POINT_SUB:
        CALL    STK_TO_BC       ; routine STK-TO-BC
        CALL    PIXEL_ADD       ; routine PIXEL-ADD finds address of pixel.
        LD      B,A             ; pixel position to B, 0-7.
        INC     B               ; increment to give rotation count 1-8.
        LD      A,(HL)          ; fetch byte from screen.

;;; @brief ; POINT-LP
;;;
;;; ; POINT-LP
;;; @jumps STACK_A
POINT_LP:
        RLCA                    ; rotate and loop back
        DJNZ    POINT_LP        ; to POINT-LP until pixel at right.

        AND      $01            ; test to give zero or one.
        JP      STACK_A         ; jump forward to STACK-A to save result.

;;; @brief Handle PLOT command
;;;
;;; Command Syntax example: PLOT 128,88
;;;
;;;
;;; ; PLOT
;;; @calls STK_TO_BC, PLOT_SUB
;;; @jumps TEMPS
;;; @jumpedfrom CIRCLE, C_R_GRE_1
PLOT:
        CALL    STK_TO_BC       ; routine STK-TO-BC
        CALL    PLOT_SUB        ; routine PLOT-SUB
        JP      TEMPS           ; to TEMPS

;;; @brief The Plot subroutine
;;;
;;; A screen byte holds 8 pixels so it is necessary to rotate a mask
;;; into the correct position to leave the other 7 pixels unaffected.
;;; However all 64 pixels in the character cell take any embedded colour
;;; items.
;;; A pixel can be reset (inverse 1), toggled (over 1), or set ( with inverse
;;; and over switches off). With both switches on, the byte is simply put
;;; back on the screen though the colours may change.
;;;
;;; ; PLOT-SUB
;;; @calls PIXEL_ADD
;;; @calledby PLOT, D_L_PLOT
;;; @fallthrough PLOT_LOOP
PLOT_SUB:
        LD      (COORDS),BC      ; store new x/y values in COORDS
        CALL    PIXEL_ADD       ; routine PIXEL-ADD gets address in HL,
                                ; count from left 0-7 in B.
        LD      B,A             ; transfer count to B.
        INC     B               ; increase 1-8.
        LD      A,$FE           ; 11111110 in A.

;;; @brief ; PLOT-LOOP
;;;
;;; ; PLOT-LOOP
;;; @jumps PL_TST_IN
;;; @fallthrough PL_TST_IN
PLOT_LOOP:
        RRCA                    ; rotate mask.
        DJNZ    PLOT_LOOP       ; to PLOT-LOOP until B circular rotations.

        LD      B,A             ; load mask to B
        LD      A,(HL)          ; fetch screen byte to A

        LD      C,(IY+$57)      ; P_FLAG to C
        BIT     0,C             ; is it to be OVER 1 ?
        JR      NZ,PL_TST_IN    ; forward to PL-TST-IN if so.

; was over 0

        AND     B               ; combine with mask to blank pixel.

;;; @brief ; PL-TST-IN
;;;
;;; ; PL-TST-IN
;;; @jumps PLOT_END
;;; @jumpedfrom PLOT_LOOP
;;; @fallthrough PLOT_END
PL_TST_IN:
        BIT     2,C             ; is it inverse 1 ?
        JR      NZ,PLOT_END     ; to PLOT-END if so.

        XOR     B               ; switch the pixel
        CPL                     ; restore other 7 bits

;;; @brief ; PLOT-END
;;;
;;; ; PLOT-END
;;; @jumps PO_ATTR
;;; @jumpedfrom PL_TST_IN
PLOT_END:
        LD      (HL),A          ; load byte to the screen.
        JP      PO_ATTR         ; exit to PO-ATTR to set colours for cell.

;;; @brief Put two numbers in BC register
;;;
;;; ; STK-TO-BC
;;; @calls STK_TO_A
;;; @calledby PR_ITEM_1, POINT_SUB, PLOT, DRAW_LINE, S_SCRN_S, S_ATTR_S
STK_TO_BC:
        CALL    STK_TO_A        ; routine STK-TO-A
        LD      B,A             ;
        PUSH    BC              ;
        CALL    STK_TO_A        ; routine STK-TO-A
        LD      E,C             ;
        POP     BC              ;
        LD      D,C             ;
        LD      C,A             ;
        RET                     ;

;;; @brief Put stack in A register
;;;
;;; This routine puts the last value on the calculator stack into the accumulator
;;; deleting the last value.
;;;
;;; ; STK-TO-A
;;; @calls FP_TO_A
;;; @jumps REPORT_BC
;;; @calledby STK_TO_BC
STK_TO_A:
        CALL    FP_TO_A           ; routine FP-TO-A compresses last value into
                                ; accumulator. e.g. PI would become 3.
                                ; zero flag set if positive.
        JP      C,REPORT_BC         ; jump forward to REPORT-Bc if >= 255.5.

        LD      C,$01           ; prepare a positive sign byte.
        RET     Z               ; return if FP-TO-BC indicated positive.

        LD      C,$FF           ; prepare negative sign byte and
        RET                     ; return.


;;; @brief THE 'CIRCLE' COMMAND
;;;
;;;   "Goe not Thou about to Square eyther circle" -
;;;   - John Donne, Cambridge educated theologian, 1624
;;;
;;;   The CIRCLE command draws a circle as a series of straight lines.
;;;   In some ways it can be regarded as a polygon, but the first line is drawn
;;;   as a tangent, taking the radius as its distance from the centre.
;;;
;;;   Both the CIRCLE algorithm and the ARC drawing algorithm make use of the
;;;   'ROTATION FORMULA' (see later).  It is only necessary to work out where
;;;   the first line will be drawn and how long it is and then the rotation
;;;   formula takes over and calculates all other rotated points.
;;;
;;;   All Spectrum circles consist of two vertical lines at each side and two
;;;   horizontal lines at the top and bottom. The number of lines is calculated
;;;   from the radius of the circle and is always divisible by 4. For complete
;;;   circles it will range from 4 for a square circle to 32 for a circle of
;;;   radius 87. The Spectrum can attempt larger circles e.g. CIRCLE 0,14,255
;;;   but these will error as they go off-screen after four lines are drawn.
;;;   At the opposite end, CIRCLE 128,88,1.23 will draw a circle as a perfect 3x3
;;;   square using 4 straight lines although very small circles are just drawn as
;;;   a dot on the screen.
;;;
;;;   The first chord drawn is the vertical chord on the right of the circle.
;;;   The starting point is at the base of this chord which is drawn upwards and
;;;   the circle continues in an anti-clockwise direction. As noted earlier the
;;;   x-coordinate of this point measured from the centre of the circle is the
;;;   radius.
;;;
;;;   The CIRCLE command makes extensive use of the calculator and as part of
;;;   process of drawing a large circle, free memory is checked 1315 times.
;;;   When drawing a large arc, free memory is checked 928 times.
;;;   A single call to 'sin' involves 63 memory checks and so values of sine
;;;   and cosine are pre-calculated and held in the mem locations. As a
;;;   clever trick 'cos' is derived from 'sin' using simple arithmetic operations
;;;   instead of the more expensive 'cos' function.
;;;
;;;   Initially, the syntax has been partly checked using the class for the DRAW
;;;   command which stacks the origin of the circle (X,Y).
;;;
;;; ; CIRCLE
;;; @calls EXPT_1NUM, CHECK_END
;;; @jumps REPORT_C, C_R_GRE_1, PLOT
CIRCLE:
        RST     18H             ; GET-CHAR              x, y.
        CP      $2C             ; Is character the required comma ?
        JP      NZ,REPORT_C     ; Jump, if not, to REPORT-C
                                ; 'Nonsense in basic'

        RST     20H                 ; NEXT-CHAR advances the parsed character address.
        CALL    EXPT_1NUM           ; routine EXPT-1NUM stacks radius in runtime.
        CALL    CHECK_END           ; routine CHECK-END will return here in runtime
                                ; if nothing follows the command.

;   Now make the radius positive and ensure that it is in floating point form
;   so that the exponent byte can be accessed for quick testing.

        RST     28H                 ;; FP-CALC              x, y, r.
        DB          $2A             ;;abs                   x, y, r.
        DB          $3D             ;;re-stack              x, y, r.
        DB          $38             ;;end-calc              x, y, r.

        LD      A,(HL)          ; Fetch first, floating-point, exponent byte.
        CP      $81             ; Compare to one.
        JR      NC,C_R_GRE_1    ; Forward to C-R-GRE-1
                                ; if circle radius is greater than one.

;    The circle is no larger than a single pixel so delete the radius from the
;    calculator stack and plot a point at the centre.

        RST     28H                 ;; FP-CALC              x, y, r.
        DB          $02             ;;delete                x, y.
        DB          $38             ;;end-calc              x, y.

        JR      PLOT           ; back to PLOT routine to just plot x,y.

; ---

;   Continue when the circle's radius measures greater than one by forming
;   the angle 2 * PI radians which is 360 degrees.

;;; @brief ; C-R-GRE-1
;;;
;;; ; C-R-GRE-1
;;; @calls CD_PRMS1
;;; @jumps C_ARC_GE1, PLOT
;;; @jumpedfrom CIRCLE
C_R_GRE_1:
        RST     28H                 ;; FP-CALC      x, y, r
        DB          $A3             ;;stk-pi/2      x, y, r, pi/2.
        DB          $38             ;;end-calc      x, y, r, pi/2.

;   Change the exponent of pi/2 from $81 to $83 giving 2*PI the central angle.
;   This is quicker than multiplying by four.

        LD      (HL),$83        ;               x, y, r, 2*PI.

;   Now store this important constant in mem-5 and delete so that other
;   parameters can be derived from it, by a routine shared with DRAW.

        RST     28H                 ;; FP-CALC      x, y, r, 2*PI.
        DB          $C5             ;;st-mem-5      store 2*PI in mem-5
        DB          $02             ;;delete        x, y, r.
        DB          $38             ;;end-calc      x, y, r.

;   The parameters derived from mem-5 (A) and from the radius are set up in
;   four of the other mem locations by the CIRCLE DRAW PARAMETERS routine which
;   also returns the number of straight lines in the B register.

        CALL    CD_PRMS1           ; routine CD-PRMS1

                                ; mem-0 ; A/No of lines (=a)            unused
                                ; mem-1 ; sin(a/2)  will be moving x    var
                                ; mem-2 ; -         will be moving y    var
                                ; mem-3 ; cos(a)                        const
                                ; mem-4 ; sin(a)                        const
                                ; mem-5 ; Angle of rotation (A) (2*PI)  const
                                ; B     ; Number of straight lines.

        PUSH    BC              ; Preserve the number of lines in B.

;   Next calculate the length of half a chord by multiplying the sine of half
;   the central angle by the radius of the circle.

        RST     28H                 ;; FP-CALC      x, y, r.
        DB          $31             ;;duplicate     x, y, r, r.
        DB          $E1             ;;get-mem-1     x, y, r, r, sin(a/2).
        DB          $04             ;;multiply      x, y, r, half-chord.
        DB          $38             ;;end-calc      x, y, r, half-chord.

        LD      A,(HL)          ; fetch exponent  of the half arc to A.
        CP      $80             ; compare to a half pixel
        JR      NC,C_ARC_GE1    ; forward, if greater than .5, to C-ARC-GE1

;   If the first line is less than .5 then 4 'lines' would be drawn on the same
;   spot so tidy the calculator stack and machine stack and plot the centre.

        RST     28H                 ;; FP-CALC      x, y, r, hc.
        DB          $02             ;;delete        x, y, r.
        DB          $02             ;;delete        x, y.
        DB          $38             ;;end-calc      x, y.

        POP     BC              ; Balance machine stack by taking chord-count.

        JP      PLOT           ; JUMP to PLOT

; ---

;   The arc is greater than 0.5 so the circle can be drawn.

;;; @brief ; C-ARC-GE1
;;;
;;; ; C-ARC-GE1
;;; @calls FIND_INT1
;;; @jumps DRW_STEPS
;;; @jumpedfrom C_R_GRE_1
C_ARC_GE1:
        RST     28H                 ;; FP-CALC      x, y, r, hc.
        DB          $C2             ;;st-mem-2      x, y, r, half chord to mem-2.
        DB          $01             ;;exchange      x, y, hc, r.
        DB          $C0             ;;st-mem-0      x, y, hc, r.
        DB          $02             ;;delete        x, y, hc.

;   Subtract the length of the half-chord from the absolute y coordinate to
;   give the starting y coordinate sy.
;   Note that for a circle this is also the end coordinate.

        DB          $03             ;;subtract      x, y-hc.  (The start y-coord)
        DB          $01             ;;exchange      sy, x.

;   Next simply add the radius to the x coordinate to give a fuzzy x-coordinate.
;   Strictly speaking, the radius should be multiplied by cos(a/2) first but
;   doing it this way makes the circle slightly larger.

        DB          $E0             ;;get-mem-0     sy, x, r.
        DB          $0F             ;;addition      sy, x+r.  (The start x-coord)

;   We now want three copies of this pair of values on the calculator stack.
;   The first pair remain on the stack throughout the circle routine and are
;   the end points. The next pair will be the moving absolute values of x and y
;   that are updated after each line is drawn. The final pair will be loaded
;   into the COORDS system variable so that the first vertical line starts at
;   the right place.

        DB          $C0             ;;st-mem-0      sy, sx.
        DB          $01             ;;exchange      sx, sy.
        DB          $31             ;;duplicate     sx, sy, sy.
        DB          $E0             ;;get-mem-0     sx, sy, sy, sx.
        DB          $01             ;;exchange      sx, sy, sx, sy.
        DB          $31             ;;duplicate     sx, sy, sx, sy, sy.
        DB          $E0             ;;get-mem-0     sx, sy, sx, sy, sy, sx.

;   Locations mem-1 and mem-2 are the relative x and y values which are updated
;   after each line is drawn. Since we are drawing a vertical line then the rx
;   value in mem-1 is zero and the ry value in mem-2 is the full chord.

        DB          $A0             ;;stk-zero      sx, sy, sx, sy, sy, sx, 0.
        DB          $C1             ;;st-mem-1      sx, sy, sx, sy, sy, sx, 0.
        DB          $02             ;;delete        sx, sy, sx, sy, sy, sx.

;   Although the three pairs of x/y values are the same for a circle, they
;   will be labelled terminating, absolute and start coordinates.

        DB          $38             ;;end-calc      tx, ty, ax, ay, sy, sx.

;   Use the exponent manipulating trick again to double the value of mem-2.

        INC     (IY+$62)        ; Increment MEM-2-1st doubling half chord.

;   Note. this first vertical chord is drawn at the radius so circles are
;   slightly displaced to the right.
;   It is only necessary to place the values (sx) and (sy) in the system
;   variable COORDS to ensure that drawing commences at the correct pixel.
;   Note. a couple of LD (COORDS),A instructions would have been quicker, and
;   simpler, than using LD (COORDS),HL.

        CALL    FIND_INT1           ; routine FIND-INT1 fetches sx from stack to A.

        LD      L,A             ; place X value in L.
        PUSH    HL              ; save the holding register.

        CALL    FIND_INT1           ; routine FIND-INT1 fetches sy to A

        POP     HL              ; restore the holding register.
        LD      H,A             ; and place y value in high byte.

        LD      (COORDS),HL      ; Update the COORDS system variable.
                                ;
                                ;               tx, ty, ax, ay.

        POP     BC              ; restore the chord count
                                ; values 4,8,12,16,20,24,28 or 32.

        JP      DRW_STEPS           ; forward to DRW-STEPS
                                ;               tx, ty, ax, ay.

;   Note. the jump to DRW-STEPS is just to decrement B and jump into the
;   middle of the arc-drawing loop. The arc count which includes the first
;   vertical arc draws one less than the perceived number of arcs.
;   The final arc offsets are obtained by subtracting the final COORDS value
;   from the initial sx and sy values which are kept at the base of the
;   calculator stack throughout the arc loop.
;   This ensures that the final line finishes exactly at the starting pixel
;   removing the possibility of any inaccuracy.
;   Since the initial sx and sy values are not required until the final arc
;   is drawn, they are not shown until then.
;   As the calculator stack is quite busy, only the active parts are shown in
;   each section.


;;; @brief THE 'DRAW' COMMAND
;;;
;;;   The Spectrum's DRAW command is overloaded and can take two parameters sets.
;;;
;;;   With two parameters, it simply draws an approximation to a straight line
;;;   at offset x,y using the LINE-DRAW routine.
;;;
;;;   With three parameters, an arc is drawn to the point at offset x,y turning
;;;   through an angle, in radians, supplied by the third parameter.
;;;   The arc will consist of 4 to 252 straight lines each one of which is drawn
;;;   by calls to the DRAW-LINE routine.
;;;
;;; ; DRAW
;;; @calls CHECK_END
;;; @jumps DR_3_PRMS, LINE_DRAW
DRAW:
        RST     18H             ; GET-CHAR
        CP      $2C             ; is it the comma character ?
        JR      Z,DR_3_PRMS     ; forward, if so, to DR-3-PRMS

;   There are two parameters e.g. DRAW 255,175

        CALL    CHECK_END           ; routine CHECK-END

        JP      LINE_DRAW           ; jump forward to LINE-DRAW

; ---

;    There are three parameters e.g. DRAW 255, 175, .5
;    The first two are relative coordinates and the third is the angle of
;    rotation in radians (A).

;;; @brief ; DR-3-PRMS
;;;
;;; ; DR-3-PRMS
;;; @calls EXPT_1NUM, CHECK_END
;;; @jumps LINE_DRAW
;;; @jumpedfrom DRAW
DR_3_PRMS:
        RST     20H             ; NEXT-CHAR skips over the 'comma'.

        CALL    EXPT_1NUM           ; routine EXPT-1NUM stacks the rotation angle.

        CALL    CHECK_END           ; routine CHECK-END

;   Now enter the calculator and store the complete rotation angle in mem-5

        RST     28H             ;; FP-CALC      x, y, A.
        DB          $C5         ;;st-mem-5      x, y, A.

;   Test the angle for the special case of 360 degrees.

        DB          $A2             ;;stk-half      x, y, A, 1/2.
        DB          $04             ;;multiply      x, y, A/2.
        DB          $1F             ;;sin           x, y, sin(A/2).
        DB          $31             ;;duplicate     x, y, sin(A/2),sin(A/2)
        DB          $30             ;;not           x, y, sin(A/2), (0/1).
        DB          $30             ;;not           x, y, sin(A/2), (1/0).
        DB          $00             ;;jump-true     x, y, sin(A/2).

        DB          $06             ;;forward to DR_SIN_NZ, DR-SIN-NZ
                                ; if sin(r/2) is not zero.

;   The third parameter is 2*PI (or a multiple of 2*PI) so a 360 degrees turn
;   would just be a straight line.  Eliminating this case here prevents
;   division by zero at later stage.

        DB          $02             ;;delete        x, y.
        DB          $38             ;;end-calc      x, y.

        JP      LINE_DRAW           ; forward to LINE-DRAW

; ---

;   An arc can be drawn.

;;; @brief ; DR-SIN-NZ
;;;
;;; ; DR-SIN-NZ
;;; @jumps DR_PRMS, LINE_DRAW
DR_SIN_NZ:
        DB          $C0             ;;st-mem-0      x, y, sin(A/2).   store mem-0
        DB          $02             ;;delete        x, y.

;   The next step calculates (roughly) the diameter of the circle of which the
;   arc will form part.  This value does not have to be too accurate as it is
;   only used to evaluate the number of straight lines and then discarded.
;   After all for a circle, the radius is used. Consequently, a circle of
;   radius 50 will have 24 straight lines but an arc of radius 50 will have 20
;   straight lines - when drawn in any direction.
;   So that simple arithmetic can be used, the length of the chord can be
;   calculated as X+Y rather than by Pythagoras Theorem and the sine of the
;   nearest angle within reach is used.

        DB          $C1             ;;st-mem-1      x, y.             store mem-1
        DB          $02             ;;delete        x.

        DB          $31             ;;duplicate     x, x.
        DB          $2A             ;;abs           x, x (+ve).
        DB          $E1             ;;get-mem-1     x, X, y.
        DB          $01             ;;exchange      x, y, X.
        DB          $E1             ;;get-mem-1     x, y, X, y.
        DB          $2A             ;;abs           x, y, X, Y (+ve).
        DB          $0F             ;;addition      x, y, X+Y.
        DB          $E0             ;;get-mem-0     x, y, X+Y, sin(A/2).
        DB          $05             ;;division      x, y, X+Y/sin(A/2).
        DB          $2A             ;;abs           x, y, X+Y/sin(A/2) = D.

;    Bring back sin(A/2) from mem-0 which will shortly get trashed.
;    Then bring D to the top of the stack again.

        DB          $E0             ;;get-mem-0     x, y, D, sin(A/2).
        DB          $01             ;;exchange      x, y, sin(A/2), D.

;   Note. that since the value at the top of the stack has arisen as a result
;   of division then it can no longer be in integer form and the next re-stack
;   is unnecessary. Only the Sinclair ZX80 had integer division.

        DB          $3D             ;;re-stack      (unnecessary)

        DB          $38             ;;end-calc      x, y, sin(A/2), D.

;   The next test avoids drawing 4 straight lines when the start and end pixels
;   are adjacent (or the same) but is probably best dispensed with.

        LD      A,(HL)          ; fetch exponent byte of D.
        CP      $81             ; compare to 1
        JR      NC,DR_PRMS      ; forward, if > 1,  to DR-PRMS

;   else delete the top two stack values and draw a simple straight line.

        RST     28H                 ;; FP-CALC
        DB          $02             ;;delete
        DB          $02             ;;delete
        DB          $38             ;;end-calc      x, y.

        JP      LINE_DRAW           ; to LINE-DRAW

; ---

;   The ARC will consist of multiple straight lines so call the CIRCLE-DRAW
;   PARAMETERS ROUTINE to pre-calculate sine values from the angle (in mem-5)
;   and determine also the number of straight lines from that value and the
;   'diameter' which is at the top of the calculator stack.

;;; @brief ; DR-PRMS
;;;
;;; ; DR-PRMS
;;; @calls CD_PRMS1, STACK_A
;;; @jumps LINE_DRAW
;;; @jumpedfrom DR_SIN_NZ
;;; @fallthrough DRW_STEPS
DR_PRMS:
        CALL    CD_PRMS1           ; routine CD-PRMS1

                                ; mem-0 ; (A)/No. of lines (=a) (step angle)
                                ; mem-1 ; sin(a/2)
                                ; mem-2 ; -
                                ; mem-3 ; cos(a)                        const
                                ; mem-4 ; sin(a)                        const
                                ; mem-5 ; Angle of rotation (A)         in
                                ; B     ; Count of straight lines - max 252.

        PUSH    BC              ; Save the line count on the machine stack.

;   Remove the now redundant diameter value D.

        RST     28H             ;; FP-CALC      x, y, sin(A/2), D.
        DB          $02         ;;delete        x, y, sin(A/2).

;   Dividing the sine of the step angle by the sine of the total angle gives
;   the length of the initial chord on a unary circle. This factor f is used
;   to scale the coordinates of the first line which still points in the
;   direction of the end point and may be larger.

        DB          $E1             ;;get-mem-1     x, y, sin(A/2), sin(a/2)
        DB          $01             ;;exchange      x, y, sin(a/2), sin(A/2)
        DB          $05             ;;division      x, y, sin(a/2)/sin(A/2)
        DB          $C1             ;;st-mem-1      x, y. f.
        DB          $02             ;;delete        x, y.

;   With the factor stored, scale the x coordinate first.

        DB          $01             ;;exchange      y, x.
        DB          $31             ;;duplicate     y, x, x.
        DB          $E1             ;;get-mem-1     y, x, x, f.
        DB          $04             ;;multiply      y, x, x*f    (=xx)
        DB          $C2             ;;st-mem-2      y, x, xx.
        DB          $02             ;;delete        y. x.

;   Now scale the y coordinate.

        DB          $01             ;;exchange      x, y.
        DB          $31             ;;duplicate     x, y, y.
        DB          $E1             ;;get-mem-1     x, y, y, f
        DB          $04             ;;multiply      x, y, y*f    (=yy)

;   Note. 'sin' and 'cos' trash locations mem-0 to mem-2 so fetch mem-2 to the
;   calculator stack for safe keeping.

        DB          $E2             ;;get-mem-2     x, y, yy, xx.

;   Once we get the coordinates of the first straight line then the 'ROTATION
;   FORMULA' used in the arc loop will take care of all other points, but we
;   now use a variation of that formula to rotate the first arc through (A-a)/2
;   radians.
;
;       xRotated = y * sin(angle) + x * cos(angle)
;       yRotated = y * cos(angle) - x * sin(angle)
;

        DB          $E5             ;;get-mem-5     x, y, yy, xx, A.
        DB          $E0             ;;get-mem-0     x, y, yy, xx, A, a.
        DB          $03             ;;subtract      x, y, yy, xx, A-a.
        DB          $A2             ;;stk-half      x, y, yy, xx, A-a, 1/2.
        DB          $04             ;;multiply      x, y, yy, xx, (A-a)/2. (=angle)
        DB          $31             ;;duplicate     x, y, yy, xx, angle, angle.
        DB          $1F             ;;sin           x, y, yy, xx, angle, sin(angle)
        DB          $C5             ;;st-mem-5      x, y, yy, xx, angle, sin(angle)
        DB          $02             ;;delete        x, y, yy, xx, angle

        DB          $20             ;;cos           x, y, yy, xx, cos(angle).

;   Note. mem-0, mem-1 and mem-2 can be used again now...

        DB          $C0             ;;st-mem-0      x, y, yy, xx, cos(angle).
        DB          $02             ;;delete        x, y, yy, xx.

        DB          $C2             ;;st-mem-2      x, y, yy, xx.
        DB          $02             ;;delete        x, y, yy.

        DB          $C1             ;;st-mem-1      x, y, yy.
        DB          $E5             ;;get-mem-5     x, y, yy, sin(angle)
        DB          $04             ;;multiply      x, y, yy*sin(angle).
        DB          $E0             ;;get-mem-0     x, y, yy*sin(angle), cos(angle)
        DB          $E2             ;;get-mem-2     x, y, yy*sin(angle), cos(angle), xx.
        DB          $04             ;;multiply      x, y, yy*sin(angle), xx*cos(angle).
        DB          $0F             ;;addition      x, y, xRotated.
        DB          $E1             ;;get-mem-1     x, y, xRotated, yy.
        DB          $01             ;;exchange      x, y, yy, xRotated.
        DB          $C1             ;;st-mem-1      x, y, yy, xRotated.
        DB          $02             ;;delete        x, y, yy.

        DB          $E0             ;;get-mem-0     x, y, yy, cos(angle).
        DB          $04             ;;multiply      x, y, yy*cos(angle).
        DB          $E2             ;;get-mem-2     x, y, yy*cos(angle), xx.
        DB          $E5             ;;get-mem-5     x, y, yy*cos(angle), xx, sin(angle).
        DB          $04             ;;multiply      x, y, yy*cos(angle), xx*sin(angle).
        DB          $03             ;;subtract      x, y, yRotated.
        DB          $C2             ;;st-mem-2      x, y, yRotated.

;   Now the initial x and y coordinates are made positive and summed to see
;   if they measure up to anything significant.

        DB          $2A             ;;abs           x, y, yRotated'.
        DB          $E1             ;;get-mem-1     x, y, yRotated', xRotated.
        DB          $2A             ;;abs           x, y, yRotated', xRotated'.
        DB          $0F             ;;addition      x, y, yRotated+xRotated.
        DB          $02             ;;delete        x, y.

        DB          $38             ;;end-calc      x, y.

;   Although the test value has been deleted it is still above the calculator
;   stack in memory and conveniently DE which points to the first free byte
;   addresses the exponent of the test value.

        LD      A,(DE)          ; Fetch exponent of the length indicator.
        CP      $81             ; Compare to that for 1

        POP     BC              ; Balance the machine stack

        JP      C,LINE_DRAW         ; forward, if the coordinates of first line
                                ; don't add up to more than 1, to LINE-DRAW

;   Continue when the arc will have a discernable shape.

        PUSH    BC              ; Restore line counter to the machine stack.

;   The parameters of the DRAW command were relative and they are now converted
;   to absolute coordinates by adding to the coordinates of the last point
;   plotted. The first two values on the stack are the terminal tx and ty
;   coordinates.  The x-coordinate is converted first but first the last point
;   plotted is saved as it will initialize the moving ax, value.

        RST     28H                 ;; FP-CALC      x, y.
        DB          $01             ;;exchange      y, x.
        DB          $38             ;;end-calc      y, x.

        LD      A,(COORDS)       ; Fetch System Variable COORDS-x
        CALL    STACK_A         ; routine STACK-A

        RST     28H             ;; FP-CALC      y, x, last-x.

;   Store the last point plotted to initialize the moving ax value.

        DB          $C0             ;;st-mem-0      y, x, last-x.
        DB          $0F             ;;addition      y, absolute x.
        DB          $01             ;;exchange      tx, y.
        DB          $38             ;;end-calc      tx, y.

        LD      A,(COORDS_y)       ; Fetch System Variable COORDS-y
        CALL    STACK_A         ; routine STACK-A

        RST     28H             ;; FP-CALC      tx, y, last-y.

;   Store the last point plotted to initialize the moving ay value.

        DB          $C5             ;;st-mem-5      tx, y, last-y.
        DB          $0F             ;;addition      tx, ty.

;   Fetch the moving ax and ay to the calculator stack.

        DB          $E0             ;;get-mem-0     tx, ty, ax.
        DB          $E5             ;;get-mem-5     tx, ty, ax, ay.
        DB          $38             ;;end-calc      tx, ty, ax, ay.

        POP     BC              ; Restore the straight line count.

;;; @brief THE 'CIRCLE/DRAW CONVERGENCE POINT'
;;;
;;;   The CIRCLE and ARC-DRAW commands converge here.
;;;
;;;   Note. for both the CIRCLE and ARC commands the minimum initial line count
;;;   is 4 (as set up by the CD_PARAMS routine) and so the zero flag will never
;;;   be set and the loop is always entered.  The first test is superfluous and
;;;   the jump will always be made to ARC-START.
;;;
;;; ; DRW-STEPS
;;; @jumps ARC_END, ARC_START
;;; @jumpedfrom C_ARC_GE1
DRW_STEPS:
        DEC     B               ; decrement the arc count (4,8,12,16...).

        JR      Z,ARC_END         ; forward, if zero (not possible), to ARC-END

        JR      ARC_START           ; forward to ARC-START

;;; @brief THE 'ARC LOOP'
;;;
;;;   The arc drawing loop will draw up to 31 straight lines for a circle and up
;;;   251 straight lines for an arc between two points. In both cases the final
;;;   closing straight line is drawn at ARC_END, but it otherwise loops back to
;;;   here to calculate the next coordinate using the ROTATION FORMULA where (a)
;;;   is the previously calculated, constant CENTRAL ANGLE of the arcs.
;;;
;;; @verbatim
;;;       Xrotated = x * cos(a) - y * sin(a)
;;;       Yrotated = x * sin(a) + y * cos(a)
;;; @endverbatim
;;;
;;;   The values cos(a) and sin(a) are pre-calculated and held in mem-3 and mem-4
;;;   for the duration of the routine.
;;;   Memory location mem-1 holds the last relative x value (rx) and mem-2 holds
;;;   the last relative y value (ry) used by DRAW.
;;;
;;;   Note. that this is a very clever twist on what is after all a very clever,
;;;   well-used formula.  Normally the rotation formula is used with the x and y
;;;   coordinates from the centre of the circle (or arc) and a supplied angle to
;;;   produce two new x and y coordinates in an anticlockwise direction on the
;;;   circumference of the circle.
;;;   What is being used here, instead, is the relative X and Y parameters from
;;;   the last point plotted that are required to get to the current point and
;;;   the formula returns the next relative coordinates to use.
;;;
;;; ; ARC-LOOP
ARC_LOOP:
        RST     28H                 ;; FP-CALC
        DB          $E1             ;;get-mem-1     rx.
        DB          $31             ;;duplicate     rx, rx.
        DB          $E3             ;;get-mem-3     cos(a)
        DB          $04             ;;multiply      rx, rx*cos(a).
        DB          $E2             ;;get-mem-2     rx, rx*cos(a), ry.
        DB          $E4             ;;get-mem-4     rx, rx*cos(a), ry, sin(a).
        DB          $04             ;;multiply      rx, rx*cos(a), ry*sin(a).
        DB          $03             ;;subtract      rx, rx*cos(a) - ry*sin(a)
        DB          $C1             ;;st-mem-1      rx, new relative x rotated.
        DB          $02             ;;delete        rx.

        DB          $E4             ;;get-mem-4     rx, sin(a).
        DB          $04             ;;multiply      rx*sin(a)
        DB          $E2             ;;get-mem-2     rx*sin(a), ry.
        DB          $E3             ;;get-mem-3     rx*sin(a), ry, cos(a).
        DB          $04             ;;multiply      rx*sin(a), ry*cos(a).
        DB          $0F             ;;addition      rx*sin(a) + ry*cos(a).
        DB          $C2             ;;st-mem-2      new relative y rotated.
        DB          $02             ;;delete        .
        DB          $38             ;;end-calc      .

;   Note. the calculator stack actually holds   tx, ty, ax, ay
;   and the last absolute values of x and y
;   are now brought into play.
;
;   Magically, the two new rotated coordinates rx and ry are all that we would
;   require to draw a circle or arc - on paper!
;   The Spectrum DRAW routine draws to the rounded x and y coordinate and so
;   repetitions of values like 3.49 would mean that the fractional parts
;   would be lost until eventually the draw coordinates might differ from the
;   floating point values used above by several pixels.
;   For this reason the accurate offsets calculated above are added to the
;   accurate, absolute coordinates maintained in ax and ay and these new
;   coordinates have the integer coordinates of the last plot position
;   ( from System Variable COORDS ) subtracted from them to give the relative
;   coordinates required by the DRAW routine.

;   The mid entry point.

;;; @brief ; ARC-START
;;;
;;; ; ARC-START
;;; @calls STACK_A, DRAW_LINE
;;; @jumpedfrom DRW_STEPS
;;; @fallthrough ARC_END
ARC_START:
        PUSH    BC              ; Preserve the arc counter on the machine stack.

;   Store the absolute ay in temporary variable mem-0 for the moment.

        RST     28H                 ;; FP-CALC      ax, ay.
        DB          $C0             ;;st-mem-0      ax, ay.
        DB          $02             ;;delete        ax.

;   Now add the fractional relative x coordinate to the fractional absolute
;   x coordinate to obtain a new fractional x-coordinate.

        DB          $E1             ;;get-mem-1     ax, xr.
        DB          $0F             ;;addition      ax+xr (= new ax).
        DB          $31             ;;duplicate     ax, ax.
        DB          $38             ;;end-calc      ax, ax.

        LD      A,(COORDS)       ; COORDS-x      last x    (integer ix 0-255)
        CALL    STACK_A         ; routine STACK-A

        RST     28H             ;; FP-CALC      ax, ax, ix.
        DB          $03         ;;subtract      ax, ax-ix  = relative DRAW Dx.

;   Having calculated the x value for DRAW do the same for the y value.

        DB          $E0             ;;get-mem-0     ax, Dx, ay.
        DB          $E2             ;;get-mem-2     ax, Dx, ay, ry.
        DB          $0F             ;;addition      ax, Dx, ay+ry (= new ay).
        DB          $C0             ;;st-mem-0      ax, Dx, ay.
        DB          $01             ;;exchange      ax, ay, Dx,
        DB          $E0             ;;get-mem-0     ax, ay, Dx, ay.
        DB          $38             ;;end-calc      ax, ay, Dx, ay.

        LD      A,(COORDS_y)       ; COORDS-y      last y (integer iy 0-175)
        CALL    STACK_A         ; routine STACK-A

        RST     28H                 ;; FP-CALC      ax, ay, Dx, ay, iy.
        DB          $03             ;;subtract      ax, ay, Dx, ay-iy ( = Dy).
        DB          $38             ;;end-calc      ax, ay, Dx, Dy.

        CALL    DRAW_LINE           ; Routine DRAW-LINE draws (Dx,Dy) relative to
                                ; the last pixel plotted leaving absolute x
                                ; and y on the calculator stack.
                                ;               ax, ay.

        POP     BC              ; Restore the arc counter from the machine stack.

        DJNZ    ARC_LOOP           ; Decrement and loop while > 0 to ARC-LOOP

;;; @brief THE 'ARC END'
;;;
;;;   To recap the full calculator stack is       tx, ty, ax, ay.
;;;
;;;   Just as one would do if drawing the curve on paper, the final line would
;;;   be drawn by joining the last point plotted to the initial start point
;;;   in the case of a CIRCLE or to the calculated end point in the case of
;;;   an ARC.
;;;   The moving absolute values of x and y are no longer required and they
;;;   can be deleted to expose the closing coordinates.
;;;
;;; ; ARC-END
;;; @calls STACK_A
;;; @jumpedfrom DRW_STEPS
ARC_END:
        RST     28H                 ;; FP-CALC      tx, ty, ax, ay.
        DB          $02             ;;delete        tx, ty, ax.
        DB          $02             ;;delete        tx, ty.
        DB          $01             ;;exchange      ty, tx.
        DB          $38             ;;end-calc      ty, tx.

;   First calculate the relative x coordinate to the end-point.

        LD      A,(COORDS)       ; COORDS-x
        CALL    STACK_A         ; routine STACK-A

        RST     28H             ;; FP-CALC      ty, tx, coords_x.
        DB          $03         ;;subtract      ty, rx.

;   Next calculate the relative y coordinate to the end-point.

        DB          $01             ;;exchange      rx, ty.
        DB          $38             ;;end-calc      rx, ty.

        LD      A,(COORDS_y)       ; COORDS-y
        CALL    STACK_A         ; routine STACK-A

        RST     28H                 ;; FP-CALC      rx, ty, coords_y
        DB          $03             ;;subtract      rx, ry.
        DB          $38             ;;end-calc      rx, ry.

;   Finally draw the last straight line.

;;; @brief ; LINE-DRAW
;;;
;;; ; LINE-DRAW
;;; @calls DRAW_LINE
;;; @jumps TEMPS
;;; @jumpedfrom DRAW, DR_3_PRMS, DR_SIN_NZ, DR_PRMS
LINE_DRAW:
        CALL    DRAW_LINE           ; routine DRAW-LINE draws to the relative
                                ; coordinates (rx, ry).

        JP      TEMPS           ; jump back and exit via TEMPS          >>>


;;; @brief THE 'INITIAL CIRCLE/DRAW PARAMETERS' ROUTINE
;;;
;;;   Begin by calculating the number of chords which will be returned in B.
;;;   A rule of thumb is employed that uses a value z which for a circle is the
;;;   radius and for an arc is the diameter with, as it happens, a pinch more if
;;;   the arc is on a slope.
;;;
;;;   NUMBER OF STRAIGHT LINES = ANGLE OF ROTATION * SQUARE ROOT ( Z ) / 2
;;;
;;; ; CD-PRMS1
;;; @calls FP_TO_A
;;; @jumps USE_252, DRAW_SAVE
;;; @calledby C_R_GRE_1, DR_PRMS
;;; @fallthrough USE_252
CD_PRMS1:
        RST     28H                 ;; FP-CALC      z.
        DB          $31             ;;duplicate     z, z.
        DB          $28             ;;sqr           z, sqr(z).
        DB          $34             ;;stk-data      z, sqr(z), 2.
        DB          $32             ;;Exponent: $82, Bytes: 1
        DB          $00             ;;(+00,+00,+00)
        DB          $01             ;;exchange      z, 2, sqr(z).
        DB          $05             ;;division      z, 2/sqr(z).
        DB          $E5             ;;get-mem-5     z, 2/sqr(z), ANGLE.
        DB          $01             ;;exchange      z, ANGLE, 2/sqr (z)
        DB          $05             ;;division      z, ANGLE*sqr(z)/2 (= No. of lines)
        DB          $2A             ;;abs           (for arc only)
        DB          $38             ;;end-calc      z, number of lines.

;    As an example for a circle of radius 87 the number of lines will be 29.

        CALL    FP_TO_A           ; routine FP-TO-A

;    The value is compressed into A register, no carry with valid circle.

        JR      C,USE_252         ; forward, if over 256, to USE-252

;    now make a multiple of 4 e.g. 29 becomes 28

        AND     $FC             ; AND 252

;    Adding 4 could set carry for arc, for the circle example, 28 becomes 32.

        ADD     A,$04           ; adding 4 could set carry if result is 256.

        JR      NC,DRAW_SAVE        ; forward if less than 256 to DRAW-SAVE

;    For an arc, a limit of 252 is imposed.

;;; @brief ; USE-252
;;;
;;; ; USE-252
;;; @jumpedfrom CD_PRMS1
;;; @fallthrough DRAW_SAVE
USE_252:
        LD      A,$FC           ; Use a value of 252 (for arc).


;   For both arcs and circles, constants derived from the central angle are
;   stored in the 'mem' locations.  Some are not relevant for the circle.

;;; @brief ; DRAW-SAVE
;;;
;;; ; DRAW-SAVE
;;; @calls STACK_A
;;; @jumpedfrom CD_PRMS1
DRAW_SAVE:
        PUSH    AF              ; Save the line count (A) on the machine stack.

        CALL    STACK_A           ; Routine STACK-A stacks the modified count(A).

        RST     28H                 ;; FP-CALC      z, A.
        DB          $E5             ;;get-mem-5     z, A, ANGLE.
        DB          $01             ;;exchange      z, ANGLE, A.
        DB          $05             ;;division      z, ANGLE/A. (Angle/count = a)
        DB          $31             ;;duplicate     z, a, a.

;  Note. that cos (a) could be formed here directly using 'cos' and stored in
;  mem-3 but that would spoil a good story and be slightly slower, as also
;  would using square roots to form cos (a) from sin (a).

        DB          $1F             ;;sin           z, a, sin(a)
        DB          $C4             ;;st-mem-4      z, a, sin(a)
        DB          $02             ;;delete        z, a.
        DB          $31             ;;duplicate     z, a, a.
        DB          $A2             ;;stk-half      z, a, a, 1/2.
        DB          $04             ;;multiply      z, a, a/2.
        DB          $1F             ;;sin           z, a, sin(a/2).

;   Note. after second sin, mem-0 and mem-1 become free.

        DB          $C1             ;;st-mem-1      z, a, sin(a/2).
        DB          $01             ;;exchange      z, sin(a/2), a.
        DB          $C0             ;;st-mem-0      z, sin(a/2), a.  (for arc only)

;   Now form cos(a) from sin(a/2) using the 'DOUBLE ANGLE FORMULA'.

        DB          $02             ;;delete        z, sin(a/2).
        DB          $31             ;;duplicate     z, sin(a/2), sin(a/2).
        DB          $04             ;;multiply      z, sin(a/2)*sin(a/2).
        DB          $31             ;;duplicate     z, sin(a/2)*sin(a/2),
                                ;;                           sin(a/2)*sin(a/2).
        DB          $0F             ;;addition      z, 2*sin(a/2)*sin(a/2).
        DB          $A1             ;;stk-one       z, 2*sin(a/2)*sin(a/2), 1.
        DB          $03             ;;subtract      z, 2*sin(a/2)*sin(a/2)-1.

        DB          $1B             ;;negate        z, 1-2*sin(a/2)*sin(a/2).

        DB          $C3             ;;st-mem-3      z, cos(a).
        DB          $02             ;;delete        z.
        DB          $38             ;;end-calc      z.

;   The radius/diameter is left on the calculator stack.

        POP     BC              ; Restore the line count to the B register.

        RET                     ; Return.

; --------------------------
; THE 'DOUBLE ANGLE FORMULA'
; --------------------------
;   This formula forms cos(a) from sin(a/2) using simple arithmetic.
;
;   THE GEOMETRIC PROOF OF FORMULA   cos (a) = 1 - 2 * sin(a/2) * sin(a/2)
;
;
;                                            A
;
;                                         . /|\
;                                     .    / | \
;                                  .      /  |  \
;                               .        /   |a/2\
;                            .          /    |    \
;                         .          1 /     |     \
;                      .              /      |      \
;                   .                /       |       \
;                .                  /        |        \
;             .  a/2             D / a      E|-+       \
;          B ---------------------/----------+-+--------\ C
;            <-         1       -><-       1           ->
;
;   cos a = 1 - 2 * sin(a/2) * sin(a/2)
;
;   The figure shows a right triangle that inscribes a circle of radius 1 with
;   centre, or origin, D.  Line BC is the diameter of length 2 and A is a point
;   on the circle. The periphery angle BAC is therefore a right angle by the
;   Rule of Thales.
;   Line AC is a chord touching two points on the circle and the angle at the
;   centre is (a).
;   Since the vertex of the largest triangle B touches the circle, the
;   inscribed angle (a/2) is half the central angle (a).
;   The cosine of (a) is the length DE as the hypotenuse is of length 1.
;   This can also be expressed as 1-length CE.  Examining the triangle at the
;   right, the top angle is also (a/2) as angle BAE and EBA add to give a right
;   angle as do BAE and EAC.
;   So cos (a) = 1 - AC * sin(a/2)
;   Looking at the largest triangle, side AC can be expressed as
;   AC = 2 * sin(a/2)   and so combining these we get
;   cos (a) = 1 - 2 * sin(a/2) * sin(a/2).
;
;   "I will be sufficiently rewarded if when telling it to others, you will
;    not claim the discovery as your own, but will say it is mine."
;   - Thales, 640 - 546 B.C.
;
;;; @brief THE 'LINE DRAWING' ROUTINE
;;;
;;; ; DRAW-LINE
;;; @calls STK_TO_BC
;;; @jumps DL_X_GE_Y, DL_LARGER
;;; @calledby ARC_START, LINE_DRAW
DRAW_LINE:
        CALL    STK_TO_BC       ; routine STK-TO-BC
        LD      A,C             ;
        CP      B               ;
        JR      NC,DL_X_GE_Y    ; to DL-X-GE-Y

        LD      L,C             ;
        PUSH    DE              ;
        XOR     A               ;
        LD      E,A             ;
        JR      DL_LARGER       ; to DL-LARGER

; ---

;;; @brief ; DL-X-GE-Y
;;;
;;; ; DL-X-GE-Y
;;; @jumpedfrom DRAW_LINE
;;; @fallthrough DL_LARGER
DL_X_GE_Y:
        OR      C               ;
        RET     Z               ;

        LD      L,B             ;
        LD      B,C             ;
        PUSH    DE              ;
        LD      D,$00           ;

;;; @brief ; DL-LARGER
;;;
;;; ; DL-LARGER
;;; @jumpedfrom DRAW_LINE
;;; @fallthrough D_L_LOOP
DL_LARGER:
        LD      H,B             ;
        LD      A,B             ;
        RRA                     ;

;;; @brief ; D-L-LOOP
;;;
;;; ; D-L-LOOP
;;; @jumps D_L_DIAG, D_L_HR_VT
;;; @fallthrough D_L_DIAG
D_L_LOOP:
        ADD     A,L             ;
        JR      C,D_L_DIAG      ; to D-L-DIAG

        CP      H               ;
        JR      C,D_L_HR_VT     ; to D-L-HR-VT

;;; @brief ; D-L-DIAG
;;;
;;; ; D-L-DIAG
;;; @jumps D_L_STEP
;;; @jumpedfrom D_L_LOOP
D_L_DIAG:
        SUB     H               ;
        LD      C,A             ;
        EXX                     ;
        POP     BC              ;
        PUSH    BC              ;
        JR      D_L_STEP        ; to D-L-STEP

; ---

;;; @brief ; D-L-HR-VT
;;;
;;; ; D-L-HR-VT
;;; @jumpedfrom D_L_LOOP
;;; @fallthrough D_L_STEP
D_L_HR_VT:
        LD      C,A             ;
        PUSH    DE              ;
        EXX                     ;
        POP     BC              ;

;;; @brief ; D-L-STEP
;;;
;;; ; D-L-STEP
;;; @jumps D_L_RANGE, REPORT_BC
;;; @jumpedfrom D_L_DIAG
;;; @fallthrough D_L_PLOT
D_L_STEP:
        LD      HL,(COORDS)      ; COORDS
        LD      A,B             ;
        ADD     A,H             ;
        LD      B,A             ;
        LD      A,C             ;
        INC     A               ;
        ADD     A,L             ;
        JR      C,D_L_RANGE     ; to D-L-RANGE

        JR      Z,REPORT_BC         ; to REPORT-Bc

;;; @brief ; D-L-PLOT
;;;
;;; ; D-L-PLOT
;;; @calls PLOT_SUB
;;; @jumpedfrom D_L_RANGE
D_L_PLOT:
        DEC     A               ;
        LD      C,A             ;
        CALL    PLOT_SUB        ; routine PLOT-SUB
        EXX                     ;
        LD      A,C             ;
        DJNZ    D_L_LOOP        ; to D-L-LOOP

        POP     DE              ;
        RET                     ;

; ---

;;; @brief ; D-L-RANGE
;;;
;;; ; D-L-RANGE
;;; @jumps D_L_PLOT
;;; @jumpedfrom D_L_STEP
;;; @fallthrough REPORT_BC
D_L_RANGE:
        JR      Z,D_L_PLOT         ; to D-L-PLOT


;;; @brief ; REPORT-Bc
;;;
;;; ; REPORT-Bc
;;; @jumpedfrom PIXEL_ADD, STK_TO_A, D_L_STEP
REPORT_BC:
        RST     08H             ; ERROR-1
        DB          $0A         ; Error Report: Integer out of range



;***********************************
