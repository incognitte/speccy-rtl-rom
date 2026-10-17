;;; @file 10_floating_point_calculator.asm
;;; @brief Part 10. FLOATING-POINT CALCULATOR

;****************************************
;** Part 10. FLOATING-POINT CALCULATOR **
;****************************************

; As a general rule the calculator avoids using the IY register.
; exceptions are val, val$ and str$.
; So an assembly language programmer who has disabled interrupts to use
; IY for other purposes can still use the calculator for mathematical
; purposes.


;;; @brief THE 'TABLE OF CONSTANTS'
CONST_ZERO:
        ; 00 00 00 00 00
        DB          $00             ;;Bytes: 1
        DB          $B0             ;;Exponent $00
        DB          $00             ;;(+00,+00,+00)
CONST_ONE:
        ; 00 00 01 00 00
        DB          $40             ;;Bytes: 2
        DB          $B0             ;;Exponent $00
        DB          $00,$01         ;;(+00,+00)
CONST_HALF:
        ; 80 00 00 00 00
        DB          $30             ;;Exponent: $80, Bytes: 1
        DB          $00             ;;(+00,+00,+00)
CONST_PI_OVER_2:
        ; 81 49 0F DA A2
        DB          $F1             ;;Exponent: $81, Bytes: 4
        DB          $49,$0F,$DA,$A2 ;;
CONST_TEN:
        ; 00 00 0A 00 00
        DB          $40             ;;Bytes: 2
        DB          $B0             ;;Exponent $00
        DB          $00,$0A         ;;(+00,+00)

;;; @brief THE 'TABLE OF ADDRESSES'
;;;
;;;   Starts with binary operations which have two operands and one result.
;;;   Three pseudo binary operations first.
TBL_ADDRS:
        DW    JUMP_TRUE        ; $00 Address: $368F - jump-true
        DW    EXCHANGE         ; $01 Address: $343C - exchange
        DW    DELETE           ; $02 Address: $33A1 - delete

;   True binary operations.

        DW    SUBTRACT           ; $03 Address: $300F - subtract
        DW    MULTIPLY           ; $04 Address: $30CA - multiply
        DW    DIVISION           ; $05 Address: $31AF - division
        DW    TO_POWER           ; $06 Address: $3851 - to-power
        DW    OR_RTN             ; $07 Address: $351B - or

        DW    NO_NO                  ; $08 Address: $3524 - no-&-no
        DW    NO_L_EQL_ETC           ; $09 Address: $353B - no-l-eql
        DW    NO_L_EQL_ETC           ; $0A Address: $353B - no-gr-eql
        DW    NO_L_EQL_ETC           ; $0B Address: $353B - nos-neql
        DW    NO_L_EQL_ETC           ; $0C Address: $353B - no-grtr
        DW    NO_L_EQL_ETC           ; $0D Address: $353B - no-less
        DW    NO_L_EQL_ETC           ; $0E Address: $353B - nos-eql
        DW    ADDITION               ; $0F Address: $3014 - addition

        DW    STR_NO                 ; $10 Address: $352D - str-&-no
        DW    NO_L_EQL_ETC           ; $11 Address: $353B - str-l-eql
        DW    NO_L_EQL_ETC           ; $12 Address: $353B - str-gr-eql
        DW    NO_L_EQL_ETC           ; $13 Address: $353B - strs-neql
        DW    NO_L_EQL_ETC           ; $14 Address: $353B - str-grtr
        DW    NO_L_EQL_ETC           ; $15 Address: $353B - str-less
        DW    NO_L_EQL_ETC           ; $16 Address: $353B - strs-eql
        DW    STRS_ADD               ; $17 Address: $359C - strs-add

;   Unary follow.

        DW    VAL           ; $18 Address: $35DE - val$
        IFDEF LANG_PERSIAN
        DW    REPORT_A
        ELSE
        DW    USR           ; $19 Address: $34BC - usr-$
        ENDIF
        DW    READ_IN       ; $1A Address: $3645 - read-in
        DW    NEGATE        ; $1B Address: $346E - negate

        DW    CODE          ; $1C Address: $3669 - code
        DW    VAL           ; $1D Address: $35DE - val
        DW    LEN           ; $1E Address: $3674 - len
        DW    SIN           ; $1F Address: $37B5 - sin
        DW    COS           ; $20 Address: $37AA - cos
        DW    TAN           ; $21 Address: $37DA - tan
        DW    ASN           ; $22 Address: $3833 - asn
        DW    ACS           ; $23 Address: $3843 - acs
        DW    ATN           ; $24 Address: $37E2 - atn
        DW    LN            ; $25 Address: $3713 - ln
        DW    EXP           ; $26 Address: $36C4 - exp
        DW    INT           ; $27 Address: $36AF - int
        DW    SQR           ; $28 Address: $384A - sqr
        DW    SGN           ; $29 Address: $3492 - sgn
        DW    ABS_RTN       ; $2A Address: $346A - abs
        DW    PEEK          ; $2B Address: $34AC - peek
        DW    IN_RTN        ; $2C Address: $34A5 - in
        DW    USR_NO        ; $2D Address: $34B3 - usr-no
        DW    STR           ; $2E Address: $361F - str$
        DW    CHRS          ; $2F Address: $35C9 - chrs
        DW    NOT_RTN       ; $30 Address: $3501 - not

;   End of true unary.

        DW    MOVE_FP            ; $31 Address: $33C0 - duplicate
        DW    N_MOD_M            ; $32 Address: $36A0 - n-mod-m
        DW    JUMP               ; $33 Address: $3686 - jump
        DW    STK_DATA           ; $34 Address: $33C6 - stk-data
        DW    DEC_JR_NZ          ; $35 Address: $367A - dec-jr-nz
        DW    LESS_0             ; $36 Address: $3506 - less-0
        DW    GREATER_0          ; $37 Address: $34F9 - greater-0
        DW    END_CALC           ; $38 Address: $369B - end-calc
        DW    GET_ARGT           ; $39 Address: $3783 - get-argt
        DW    TRUNCATE           ; $3A Address: $3214 - truncate
        DW    FP_CALC_2          ; $3B Address: $33A2 - fp-calc-2
        DW    E_TO_FP            ; $3C Address: $2D4F - e-to-fp
        DW    RE_STACK           ; $3D Address: $3297 - re-stack

;   The following are just the next available slots for the 128 compound
;   literals which are in range $80 - $FF.

        DW    SERIES_XX           ;     Address: $3449 - series-xx    $80 - $9F.
        DW    STK_CONST_XX        ;     Address: $341B - stk-const-xx $A0 - $BF.
        DW    ST_MEM_XX           ;     Address: $342D - st-mem-xx    $C0 - $DF.
        DW    GET_MEM_XX          ;     Address: $340F - get-mem-xx   $E0 - $FF.

;   Aside: 3E - 3F are therefore unused calculator literals.
;   If the literal has to be also usable as a function then bits 6 and 7 are
;   used to show type of arguments and result.

;;; @brief The Calculator
;;; @calls STK_PNTRS
;;; @jumpedfrom FP_CALC
;;; @fallthrough GEN_ENT_1
CALCULATE:
        CALL    STK_PNTRS           ; routine STK-PNTRS is called to set up the
                                ; calculator stack pointers for a default
                                ; unary operation. HL = last value on stack.
                                ; DE = STKEND first location after stack.

; the calculate routine is called at this point by the series generator...

;;; @brief Entry point GEN_ENT_1 (no original comment).
;;; @calledby SERIES_XX
;;; @fallthrough GEN_ENT_2
GEN_ENT_1:
        LD      A,B             ; fetch the Z80 B register to A
        LD      (BREG),A       ; and store value in system variable BREG.
                                ; this will be the counter for dec-jr-nz
                                ; or if used from fp-calc2 the calculator
                                ; instruction.

; ... and again later at this point

;;; @brief Entry point GEN_ENT_2 (no original comment).
;;; @calledby SERIES_XX
;;; @fallthrough DELETE
GEN_ENT_2:
        EXX                     ; switch sets
        EX      (SP),HL         ; and store the address of next instruction,
                                ; the return address, in H'L'.
                                ; If this is a recursive call the H'L'
                                ; of the previous invocation goes on stack.
                                ; c.f. end-calc.
        EXX                     ; switch back to main set

; this is the re-entry looping point when handling a string of literals.

RE_ENTRY:
        LD      (STKEND),DE      ; save end of stack in system variable STKEND
        EXX                     ; switch to alt
        LD      A,(HL)          ; get next literal
        INC     HL              ; increase pointer'

; single operation jumps back to here

SCAN_ENT:
        PUSH    HL              ; save pointer on stack
        AND     A               ; now test the literal
        JP      P,FIRST_3D      ; forward to FIRST-3D if in range $00 - $3D
                                ; anything with bit 7 set will be one of
                                ; 128 compound literals.

; compound literals have the following format.
; bit 7 set indicates compound.
; bits 6-5 the subgroup 0-3.
; bits 4-0 the embedded parameter $00 - $1F.
; The subgroup 0-3 needs to be manipulated to form the next available four
; address places after the simple literals in the address table.

        LD      D,A             ; save literal in D
        AND     $60             ; and with 01100000 to isolate subgroup
        RRCA                    ; rotate bits
        RRCA                    ; 4 places to right
        RRCA                    ; not five as we need offset * 2
        RRCA                    ; 00000xx0
        ADD     A,$7C           ; add ($3E * 2) to give correct offset.
                                ; alter above if you add more literals.
        LD      L,A             ; store in L for later indexing.
        LD      A,D             ; bring back compound literal
        AND     $1F             ; use mask to isolate parameter bits
        JR      ENT_TABLE       ; forward to ENT-TABLE

; ---

; the branch was here with simple literals.

FIRST_3D:
        CP      $18             ; compare with first unary operations.
        JR      NC,DOUBLE_A     ; to DOUBLE-A with unary operations

; it is binary so adjust pointers.

        EXX                     ;
        LD      BC,$FFFB        ; the value -5
        LD      D,H             ; transfer HL, the last value, to DE.
        LD      E,L             ;
        ADD     HL,BC           ; subtract 5 making HL point to second
                                ; value.
        EXX                     ;

DOUBLE_A:
        RLCA                    ; double the literal
        LD      L,A             ; and store in L for indexing

ENT_TABLE:
        LD      DE,TBL_ADDRS    ; Address: tbl-addrs
        LD      H,$00           ; prepare to index
        ADD     HL,DE           ; add to get address of routine
        LD      E,(HL)          ; low byte to E
        INC     HL              ;
        LD      D,(HL)          ; high byte to D
        LD      HL,RE_ENTRY     ; Address: RE-ENTRY
        EX      (SP),HL         ; goes to stack
        PUSH    DE              ; now address of routine
        EXX                     ; main set
                                ; avoid using IY register.
        LD      BC,($5C66)      ; STKEND_hi
                                ; nothing much goes to C but BREG to B
                                ; and continue into next ret instruction
                                ; which has a dual identity


;;; @brief Handle delete (02)
;;;
;;; A simple return but when used as a calculator literal this
;;; deletes the last value from the calculator stack.
;;; On entry, as always with binary operations,
;;; HL=first number, DE=second number
;;; On exit, HL=result, DE=stkend.
;;; So nothing to do
DELETE:
        RET                     ; return - indirect jump if from above.

;;; @brief Single operation (3B)
;;;
;;;   This single operation is used, in the first instance, to evaluate most
;;;   of the mathematical and string functions found in BASIC expressions.
FP_CALC_2:
        POP     AF              ; drop return address.
        LD      A,(BREG)       ; load accumulator from system variable BREG
                                ; value will be literal e.g. 'tan'
        EXX                     ; switch to alt
        JR      SCAN_ENT        ; back to SCAN-ENT
                                ; next literal will be end-calc at L2758

;;; @brief THE 'TEST FIVE SPACES' SUBROUTINE
;;;
;;;   This routine is called from MOVE-FP, STK-CONST and STK-STORE to test that
;;;   there is enough space between the calculator stack and the machine stack
;;;   for another five-byte value.  It returns with BC holding the value 5 ready
;;;   for any subsequent LDIR.
;;; @calls TEST_ROOM
;;; @calledby STK_STORE, MOVE_FP, STK_CONST
TEST_5_SP:
        PUSH    DE              ; save
        PUSH    HL              ; registers
        LD      BC,$0005        ; an overhead of five bytes
        CALL    TEST_ROOM       ; routine TEST-ROOM tests free RAM raising
                                ; an error if not.
        POP     HL              ; else restore
        POP     DE              ; registers.
        RET                     ; return with BC set at 5.

;;; @brief THE 'STACK NUMBER' SUBROUTINE
;;;
;;;   This routine is called to stack a hidden floating point number found in
;;;   a BASIC line.  It is also called to stack a numeric variable value, and
;;;   from BEEP, to stack an entry in the semi-tone table.  It is not part of the
;;;   calculator suite of routines.  On entry, HL points to the number to be
;;;   stacked.
;;; @calls MOVE_FP
;;; @calledby BEEP, S_SD_SKIP, S_LETTER
STACK_NUM:
        LD      DE,(STKEND)      ; Load destination from STKEND system variable.

        CALL    MOVE_FP           ; Routine MOVE-FP puts on calculator stack
                                ; with a memory check.
        LD      (STKEND),DE      ; Set STKEND to next free location.

        RET                     ; Return.

;;; @brief Move a floating point number (31)
;;;
;;; This simple routine is a 5-byte LDIR instruction
;;; that incorporates a memory check.
;;; When used as a calculator literal it duplicates the last value on the
;;; calculator stack.
;;; Unary so on entry HL points to last value, DE to stkend
;;;
;;; ; duplicate
;;; @calls TEST_5_SP
;;; @calledby SFA_MATCH, STACK_NUM, GET_MEM_XX, ST_MEM_XX
MOVE_FP:
        CALL    TEST_5_SP           ; routine TEST-5-SP test free memory
                                ; and sets BC to 5.
        LDIR                    ; copy the five bytes.
        RET                     ; return with DE addressing new STKEND
                                ; and HL addressing new last value.

;;; @brief Stack literals ($34)
;;;
;;; When a calculator subroutine needs to put a value on the calculator
;;; stack that is not a regular constant this routine is called with a
;;; variable number of following data bytes that convey to the routine
;;; the integer or floating point form as succinctly as is possible.
;;; @calledby SERIES_XX
;;; @fallthrough STK_CONST
STK_DATA:
        LD      H,D             ; transfer STKEND
        LD      L,E             ; to HL for result.

;;; @brief Entry point STK_CONST (no original comment).
;;; @calls TEST_5_SP
;;; @calledby SKIP_CONS, STK_CONST_XX
STK_CONST:
        CALL    TEST_5_SP           ; routine TEST-5-SP tests that room exists
                                ; and sets BC to $05.

        EXX                     ; switch to alternate set
        PUSH    HL              ; save the pointer to next literal on stack
        EXX                     ; switch back to main set

        EX      (SP),HL         ; pointer to HL, destination to stack.

        PUSH    BC              ; save BC - value 5 from test room ??.

        LD      A,(HL)          ; fetch the byte following 'stk-data'
        AND     $C0             ; isolate bits 7 and 6
        RLCA                    ; rotate
        RLCA                    ; to bits 1 and 0  range $00 - $03.
        LD      C,A             ; transfer to C
        INC     C               ; and increment to give number of bytes
                                ; to read. $01 - $04
        LD      A,(HL)          ; reload the first byte
        AND     $3F             ; mask off to give possible exponent.
        JR      NZ,FORM_EXP     ; forward to FORM-EXP if it was possible to
                                ; include the exponent.

; else byte is just a byte count and exponent comes next.

        INC     HL              ; address next byte and
        LD      A,(HL)          ; pick up the exponent ( - $50).

FORM_EXP:
        ADD     A,$50           ; now add $50 to form actual exponent
        LD      (DE),A          ; and load into first destination byte.
        LD      A,$05           ; load accumulator with $05 and
        SUB     C               ; subtract C to give count of trailing
                                ; zeros plus one.
        INC     HL              ; increment source
        INC     DE              ; increment destination
        LD      B,$00           ; prepare to copy
        LDIR                    ; copy C bytes

        POP     BC              ; restore 5 counter to BC ??.

        EX      (SP),HL         ; put HL on stack as next literal pointer
                                ; and the stack value - result pointer -
                                ; to HL.

        EXX                     ; switch to alternate set.
        POP     HL              ; restore next literal pointer from stack
                                ; to H'L'.
        EXX                     ; switch back to main set.

        LD      B,A             ; zero count to B
        XOR     A               ; clear accumulator

STK_ZEROS:
        DEC     B               ; decrement B counter
        RET     Z               ; return if zero.          >>
                                ; DE points to new STKEND
                                ; HL to new number.

        LD      (DE),A          ; else load zero to destination
        INC     DE              ; increase destination
        JR      STK_ZEROS       ; loop back to STK-ZEROS until done.

;;; @brief THE 'SKIP CONSTANTS' SUBROUTINE
;;;
;;;   This routine traverses variable-length entries in the table of constants,
;;;   stacking intermediate, unwanted constants onto a dummy calculator stack,
;;;   in the first five bytes of ROM.  The destination DE normally points to the
;;;   end of the calculator stack which might be in the normal place or in the
;;;   system variables area during E-LINE-NO; INT-TO-FP; stk-ten.  In any case,
;;;   it would be simpler all round if the routine just shoved unwanted values
;;;   where it is going to stick the wanted value.  The instruction LD DE, $0000
;;;   can be removed.
;;; @calls STK_CONST
;;; @calledby STK_CONST_XX
SKIP_CONS:
        AND     A               ; test if initially zero.

SKIP_NEXT:
        RET     Z               ; return if zero.          >>

        PUSH    AF              ; save count.
        PUSH    DE              ; and normal STKEND

        LD      DE,$0000        ; dummy value for STKEND at start of ROM
                                ; Note. not a fault but this has to be
                                ; moved elsewhere when running in RAM.
                                ; e.g. with Expandor Systems 'Soft ROM'.
                                ; Better still, write to the normal place.
        CALL    STK_CONST           ; routine STK-CONST works through variable
                                ; length records.

        POP     DE              ; restore real STKEND
        POP     AF              ; restore count
        DEC     A               ; decrease
        JR      SKIP_NEXT       ; loop back to SKIP-NEXT

;;; @brief THE 'LOCATE MEMORY' SUBROUTINE
;;;
;;;   This routine, when supplied with a base address in HL and an index in A,
;;;   will calculate the address of the A'th entry, where each entry occupies
;;;   five bytes.  It is used for reading the semi-tone table and addressing
;;;   floating-point numbers in the calculator's memory area.
;;;   It is not possible to use this routine for the table of constants as these
;;;   six values are held in compressed format.
;;; @calledby BEEP, GET_MEM_XX, ST_MEM_XX
LOC_MEM:
        LD      C,A             ; store the original number $00-$1F.
        RLCA                    ; X2 - double.
        RLCA                    ; X4 - quadruple.
        ADD     A,C             ; X5 - now add original to multiply by five.

        LD      C,A             ; place the result in the low byte.
        LD      B,$00           ; set high byte to zero.
        ADD     HL,BC           ; add to form address of start of number in HL.

        RET                     ; return.

;;; @brief Get from memory area ($E0 etc.)
;;;
;;; Literals $E0 to $FF
;;; A holds $00-$1F offset.
;;; The calculator stack increases by 5 bytes.
;;; @calls LOC_MEM, MOVE_FP
GET_MEM_XX:
        PUSH    DE              ; save STKEND
        LD      HL,(MEM)      ; MEM is base address of the memory cells.
        CALL    LOC_MEM         ; routine LOC-MEM so that HL = first byte
        CALL    MOVE_FP         ; routine MOVE-FP moves 5 bytes with memory
                                ; check.
                                ; DE now points to new STKEND.
        POP     HL              ; original STKEND is now RESULT pointer.
        RET                     ; return.

;;; @brief Stack a constant (A0 etc.)
;;;
;;; This routine allows a one-byte instruction to stack up to 32 constants
;;; held in short form in a table of constants. In fact only 5 constants are
;;; required. On entry the A register holds the literal ANDed with 1F.
;;; It isn't very efficient and it would have been better to hold the
;;; numbers in full, five byte form and stack them in a similar manner
;;; to that used for semi-tone table values.
;;; @calls SKIP_CONS, STK_CONST
STK_CONST_XX:
        LD      H,D             ; save STKEND - required for result
        LD      L,E             ;
        EXX                     ; swap
        PUSH    HL              ; save pointer to next literal
        LD      HL,CONST_ZERO   ; Address: stk-zero - start of table of
                                ; constants
        EXX                     ;
        CALL    SKIP_CONS       ; routine SKIP-CONS
        CALL    STK_CONST       ; routine STK-CONST
        EXX                     ;
        POP     HL              ; restore pointer to next literal.
        EXX                     ;
        RET                     ; return.

;;; @brief Store in a memory area ($C0 etc.)
;;;
;;; Offsets $C0 to $DF
;;; Although 32 memory storage locations can be addressed, only six
;;; $C0 to $C5 are required by the ROM and only the thirty bytes (6*5)
;;; required for these are allocated. Spectrum programmers who wish to
;;; use the floating point routines from assembly language may wish to
;;; alter the system variable MEM to point to 160 bytes of RAM to have
;;; use the full range available.
;;; A holds the derived offset $00-$1F.
;;; This is a unary operation, so on entry HL points to the last value and DE
;;; points to STKEND.
;;; @calls LOC_MEM, MOVE_FP
ST_MEM_XX:
        PUSH    HL              ; save the result pointer.
        EX      DE,HL           ; transfer to DE.
        LD      HL,(MEM)      ; fetch MEM the base of memory area.
        CALL    LOC_MEM         ; routine LOC-MEM sets HL to the destination.
        EX      DE,HL           ; swap - HL is start, DE is destination.
        CALL    MOVE_FP         ; routine MOVE-FP.
                                ; note. a short ld bc,5; ldir
                                ; the embedded memory check is not required
                                ; so these instructions would be faster.
        EX      DE,HL           ; DE = STKEND
        POP     HL              ; restore original result pointer
        RET                     ; return.

;;; @brief THE 'EXCHANGE' SUBROUTINE
;;;
;;; (offset: $01 'exchange')
;;;   This routine swaps the last two values on the calculator stack.
;;;   On entry, as always with binary operations,
;;;   HL=first number, DE=second number
;;;   On exit, HL=result, DE=stkend.
;;;
;;; ; exchange
;;; @calledby STR_NO
EXCHANGE:
        LD      B,$05           ; there are five bytes to be swapped

; start of loop.

SWAP_BYTE:
        LD      A,(DE)          ; each byte of second
        LD      C,(HL)          ; each byte of first
        EX      DE,HL           ; swap pointers
        LD      (DE),A          ; store each byte of first
        LD      (HL),C          ; store each byte of second
        INC     HL              ; advance both
        INC     DE              ; pointers.
        DJNZ    SWAP_BYTE       ; loop back to SWAP-BYTE until all 5 done.

        EX      DE,HL           ; even up the exchanges so that DE addresses
                                ; STKEND.

        RET                     ; return.

;;; @brief THE 'SERIES GENERATOR' ROUTINE
;;;
;;; (offset: $86 'series-06')
;;; (offset: $88 'series-08')
;;; (offset: $8C 'series-0C')
;;;   The Spectrum uses Chebyshev polynomials to generate approximations for
;;;   SIN, ATN, LN and EXP. For calculators are concerned, Chebyshev polynomials
;;;   have an advantage over other series as they can reach an approximation in just
;;;   six iterations for SIN, eight for EXP and twelve for LN and ATN.
;;;   Reference: "The Complete Spectrum ROM Disassembly" by Dr Ian Logan
;;;   and Dr Frank O'Hara, published 1983 by Melbourne House.
;;; @calls GEN_ENT_1, STK_DATA, GEN_ENT_2
SERIES_XX:
        LD      B,A             ; parameter $00 - $1F to B counter
        CALL    GEN_ENT_1       ; routine GEN-ENT-1 is called.
                                ; A recursive call to a special entry point
                                ; in the calculator that puts the B register
                                ; in the system variable BREG. The return
                                ; address is the next location and where
                                ; the calculator will expect its first
                                ; instruction - now pointed to by HL'.
                                ; The previous pointer to the series of
                                ; five-byte numbers goes on the machine stack.

; The initialization phase.

        DB          $31             ;;duplicate       x,x
        DB          $0F             ;;addition        x+x
        DB          $C0             ;;st-mem-0        x+x
        DB          $02             ;;delete          .
        DB          $A0             ;;stk-zero        0
        DB          $C2             ;;st-mem-2        0

; a loop is now entered to perform the algebraic calculation for each of
; the numbers in the series

G_LOOP:
        DB          $31             ;;duplicate       v,v.
        DB          $E0             ;;get-mem-0       v,v,x+2
        DB          $04             ;;multiply        v,v*x+2
        DB          $E2             ;;get-mem-2       v,v*x+2,v
        DB          $C1             ;;st-mem-1
        DB          $03             ;;subtract
        DB          $38             ;;end-calc

; the previous pointer is fetched from the machine stack to H'L' where it
; addresses one of the numbers of the series following the series literal.

        CALL    STK_DATA           ; routine STK-DATA is called directly to
                                ; push a value and advance H'L'.
        CALL    GEN_ENT_2           ; routine GEN-ENT-2 recursively re-enters
                                ; the calculator without disturbing
                                ; system variable BREG
                                ; H'L' value goes on the machine stack and is
                                ; then loaded as usual with the next address.

        DB          $0F             ;;addition
        DB          $01             ;;exchange
        DB          $C2             ;;st-mem-2
        DB          $02             ;;delete

        DB          $35             ;;dec-jr-nz
        DB          $EE             ;;back to G_LOOP, G-LOOP

; when the counted loop is complete the final subtraction yields the result
; for example SIN X.

        DB          $E1             ;;get-mem-1
        DB          $03             ;;subtract
        DB          $38             ;;end-calc

        RET                     ; return with H'L' pointing to location
                                ; after last number in series.

;;; @brief THE 'ABSOLUTE MAGNITUDE' FUNCTION
;;;
;;; (offset: $2A 'abs')
;;;   This calculator literal finds the absolute value of the last value,
;;;   integer or floating point, on calculator stack.
ABS_RTN:
        LD      B,$FF           ; signal abs
        JR      NEG_TEST        ; forward to NEG-TEST

;;; @brief THE 'UNARY MINUS' OPERATION
;;;
;;; (offset: $1B 'negate')
;;;   Unary so on entry HL points to last value, DE to STKEND.
;;; @calls TEST_ZERO
;;; @jumps INT_CASE
;;; @calledby SUBTRACT
NEGATE:
        CALL    TEST_ZERO       ; call routine TEST-ZERO and
        RET     C               ; return if so leaving zero unchanged.

        LD      B,$00           ; signal negate required before joining
                                ; common code.

NEG_TEST:
        LD      A,(HL)          ; load first byte and
        AND     A               ; test for zero
        JR      Z,INT_CASE      ; forward to INT-CASE if a small integer

; for floating point numbers a single bit denotes the sign.

        INC     HL              ; address the first byte of mantissa.
        LD      A,B             ; action flag $FF=abs, $00=neg.
        AND     $80             ; now         $80      $00
        OR      (HL)            ; sets bit 7 for abs
        RLA                     ; sets carry for abs and if number negative
        CCF                     ; complement carry flag
        RRA                     ; and rotate back in altering sign
        LD      (HL),A          ; put the altered adjusted number back
        DEC     HL              ; HL points to result
        RET                     ; return with DE unchanged

; ---

;;; @brief for integer numbers an entire byte denotes the sign
;;;
;;; for integer numbers an entire byte denotes the sign.
;;; @calls INT_FETCH, INT_STORE
;;; @jumpedfrom NEGATE
INT_CASE:
        PUSH    DE              ; save STKEND.

        PUSH    HL              ; save pointer to the last value/result.

        CALL    INT_FETCH           ; routine INT-FETCH puts integer in DE
                                ; and the sign in C.

        POP     HL              ; restore the result pointer.

        LD      A,B             ; $FF=abs, $00=neg
        OR      C               ; $FF for abs, no change neg
        CPL                     ; $00 for abs, switched for neg
        LD      C,A             ; transfer result to sign byte.

        CALL    INT_STORE           ; routine INT-STORE to re-write the integer.

        POP     DE              ; restore STKEND.
        RET                     ; return.

;;; @brief THE 'SIGNUM' FUNCTION
;;;
;;; (offset: $29 'sgn')
;;;   This routine replaces the last value on the calculator stack,
;;;   which may be in floating point or integer form, with the integer values
;;;   zero if zero, with one if positive and  with -minus one if negative.
;;; @calls TEST_ZERO, INT_STORE
SGN:
        CALL    TEST_ZERO       ; call routine TEST-ZERO and
        RET     C               ; exit if so as no change is required.

        PUSH    DE              ; save pointer to STKEND.

        LD      DE,$0001        ; the result will be 1.
        INC     HL              ; skip over the exponent.
        RL      (HL)            ; rotate the sign bit into the carry flag.
        DEC     HL              ; step back to point to the result.
        SBC     A,A             ; byte will be $FF if negative, $00 if positive.
        LD      C,A             ; store the sign byte in the C register.
        CALL    INT_STORE       ; routine INT-STORE to overwrite the last
                                ; value with 0001 and sign.

        POP     DE              ; restore STKEND.
        RET                     ; return.

;;; @brief THE 'IN' FUNCTION
;;;
;;; (offset: $2C 'in')
;;;   This function reads a byte from an input port.
;;; @calls FIND_INT2
IN_RTN:
        CALL    FIND_INT2           ; Routine FIND-INT2 puts port address in BC.
                                ; All 16 bits are put on the address line.

        IN      A,(C)           ; Read the port.

        JR      IN_PK_STK           ; exit to STACK-A (via IN-PK-STK to save a byte
                                ; of instruction code).

;;; @brief THE 'PEEK' FUNCTION
;;;
;;; (offset: $2B 'peek')
;;;   This function returns the contents of a memory address.
;;;   The entire address space can be peeked including the ROM.
;;; @calls FIND_INT2
;;; @jumps STACK_A
PEEK:
        CALL    FIND_INT2       ; routine FIND-INT2 puts address in BC.
        LD      A,(BC)          ; load contents into A register.

IN_PK_STK:
        JP      STACK_A           ; exit via STACK-A to put the value on the
                                ; calculator stack.

;;; @brief THE 'USR' FUNCTION
;;;
;;; (offset: $2d 'usr-no')
;;;   The USR function followed by a number 0-65535 is the method by which
;;;   the Spectrum invokes machine code programs. This function returns the
;;;   contents of the BC register pair.
;;;   Note. that STACK-BC re-initializes the IY register if a user-written
;;;   program has altered it.
;;; @calls FIND_INT2, STK_FETCH, ALPHA
;;; @jumps STACK_BC
USR_NO:
        CALL    FIND_INT2           ; routine FIND-INT2 to fetch the
                                ; supplied address into BC.

        LD      HL,STACK_BC     ; address: STACK-BC is
        PUSH    HL              ; pushed onto the machine stack.
        PUSH    BC              ; then the address of the machine code
                                ; routine.

        RET                     ; make an indirect jump to the routine
                                ; and, hopefully, to STACK-BC also.

; -------------------------
; THE 'USR STRING' FUNCTION
; -------------------------
; (offset: $19 'usr-$')
;   The user function with a one-character string argument, calculates the
;   address of the User Defined Graphic character that is in the string.
;   As an alternative, the ASCII equivalent, upper or lower case,
;   may be supplied. This provides a user-friendly method of redefining
;   the 21 User Definable Graphics e.g.
;   POKE USR "a", BIN 10000000 will put a dot in the top left corner of the
;   character 144.
;   Note. the curious double check on the range. With 26 UDGs the first check
;   only is necessary. With anything less the second check only is required.
;   It is highly likely that the first check was written by Steven Vickers.
        IFDEF   LANG_PERSIAN
        ASSERT  $ <= $34BC
        IF      $ < $34BC
        DS      $34BC-$, $FF
        ENDIF
        ASSERT  $ == $34BC
RTL_GLYPH_FLAG_TABLE:
        INCLUDE "lang/persian/flags.asm"
        ASSERT  $ == REPORT_A
        ASSERT  REPORT_A == $34E7
RTL_GLYPH_FLAG_LOOKUP_BASE EQU RTL_GLYPH_FLAG_TABLE-$41
        ELSE
USR:
        CALL    STK_FETCH           ; routine STK-FETCH fetches the string
                                ; parameters.
        DEC     BC              ; decrease BC by
        LD      A,B             ; one to test
        OR      C               ; the length.
        JR      NZ,REPORT_A     ; to REPORT-A if not a single character.

        LD      A,(DE)          ; fetch the character
        CALL    ALPHA           ; routine ALPHA sets carry if 'A-Z' or 'a-z'.
        JR      C,USR_RANGE     ; forward to USR-RANGE if ASCII.

        SUB     $90             ; make UDGs range 0-20d
        JR      C,REPORT_A      ; to REPORT-A if too low. e.g. usr " ".

        CP      $15             ; Note. this test is not necessary.
        JR      NC,REPORT_A     ; to REPORT-A if higher than 20.

        INC     A               ; make range 1-21d to match LSBs of ASCII

USR_RANGE:
        DEC     A               ; make range of bits 0-4 start at zero
        ADD     A,A             ; multiply by eight
        ADD     A,A             ; and lose any set bits
        ADD     A,A             ; range now 0 - 25*8
        CP      $A8             ; compare to 21*8
        JR      NC,REPORT_A     ; to REPORT-A if originally higher
                                ; than 'U','u' or graphics U.

        LD      BC,(UDG)      ; fetch the UDG system variable value.
        ADD     A,C             ; add the offset to character
        LD      C,A             ; and store back in register C.
        JR      NC,USR_STACK    ; forward to USR-STACK if no overflow.

        INC     B               ; increment high byte.

USR_STACK:
        JP      STACK_BC           ; jump back and exit via STACK-BC to store

        ENDIF

; ---

REPORT_A:
        RST     08H             ; ERROR-1
        DB          $09         ; Error Report: Invalid argument

;;; @brief THE 'TEST FOR ZERO' SUBROUTINE
;;;
;;;   Test if top value on calculator stack is zero.  The carry flag is set if
;;;   the last value is zero but no registers are altered.
;;;   All five bytes will be zero but first four only need be tested.
;;;   On entry, HL points to the exponent the first byte of the value.
;;; @calledby STOP, PREP_M_D, NEGATE, SGN, GREATER_0, NOT_RTN, OR_RTN, NO_NO, STR_NO
TEST_ZERO:
        PUSH    HL              ; preserve HL which is used to address.
        PUSH    BC              ; preserve BC which is used as a store.
        LD      B,A             ; preserve A in B.

        LD      A,(HL)          ; load first byte to accumulator
        INC     HL              ; advance.
        OR      (HL)            ; OR with second byte and clear carry.
        INC     HL              ; advance.
        OR      (HL)            ; OR with third byte.
        INC     HL              ; advance.
        OR      (HL)            ; OR with fourth byte.

        LD      A,B             ; restore A without affecting flags.
        POP     BC              ; restore the saved
        POP     HL              ; registers.

        RET     NZ              ; return if not zero and with carry reset.

        SCF                     ; set the carry flag.
        RET                     ; return with carry set if zero.

;;; @brief THE 'GREATER THAN ZERO' OPERATOR
;;;
;;; (offset: $37 'greater-0' )
;;;   Test if the last value on the calculator stack is greater than zero.
;;;   This routine is also called directly from the end-tests of the comparison
;;;   routine.
;;; @calls TEST_ZERO
;;; @calledby SECND_LOW
GREATER_0:
        CALL    TEST_ZERO       ; routine TEST-ZERO
        RET     C               ; return if was zero as this
                                ; is also the Boolean 'false' value.

        LD      A,$FF           ; prepare XOR mask for sign bit
        JR      SIGN_TO_C       ; forward to SIGN-TO-C
                                ; to put sign in carry
                                ; (carry will become set if sign is positive)
                                ; and then overwrite location with 1 or 0
                                ; as appropriate.

;;; @brief THE 'NOT' FUNCTION
;;;
;;; (offset: $30 'not')
;;;   This overwrites the last value with 1 if it was zero else with zero
;;;   if it was any other value.
;;;
;;;   e.g. NOT 0 returns 1, NOT 1 returns 0, NOT -3 returns 0.
;;;
;;;   The subroutine is also called directly from the end-tests of the comparison
;;;   operator.
;;; @calls TEST_ZERO
;;; @jumps FP_0_1
;;; @calledby SECND_LOW
NOT_RTN:
        CALL    TEST_ZERO           ; routine TEST-ZERO sets carry if zero

        JR      FP_0_1           ; to FP-0/1 to overwrite operand with
                                ; 1 if carry is set else to overwrite with zero.

;;; @brief THE 'LESS THAN ZERO' OPERATION
;;;
;;; (offset: $36 'less-0' )
;;;   Destructively test if last value on calculator stack is less than zero.
;;;   Bit 7 of second byte will be set if so.
;;; @fallthrough FP_0_1
LESS_0:
        XOR     A               ; set XOR mask to zero
                                ; (carry will become set if sign is negative).

;   transfer sign of mantissa to Carry Flag.

SIGN_TO_C:
        INC     HL              ; address 2nd byte.
        XOR     (HL)            ; bit 7 of HL will be set if number is negative.
        DEC     HL              ; address 1st byte again.
        RLCA                    ; rotate bit 7 of A to carry.

;;; @brief THE 'ZERO OR ONE' SUBROUTINE
;;;
;;;   This routine places an integer value of zero or one at the addressed
;;;   location of the calculator stack or MEM area.  The value one is written if
;;;   carry is set on entry else zero.
;;; @calledby E_TO_FP
;;; @jumpedfrom NOT_RTN, OR_RTN, NO_NO
FP_0_1:
        PUSH    HL              ; save pointer to the first byte
        LD      A,$00           ; load accumulator with zero - without
                                ; disturbing flags.
        LD      (HL),A          ; zero to first byte
        INC     HL              ; address next
        LD      (HL),A          ; zero to 2nd byte
        INC     HL              ; address low byte of integer
        RLA                     ; carry to bit 0 of A
        LD      (HL),A          ; load one or zero to low byte.
        RRA                     ; restore zero to accumulator.
        INC     HL              ; address high byte of integer.
        LD      (HL),A          ; put a zero there.
        INC     HL              ; address fifth byte.
        LD      (HL),A          ; put a zero there.
        POP     HL              ; restore pointer to the first byte.
        RET                     ; return.

;;; @brief THE 'OR' OPERATOR
;;;
;;; (offset: $07 'or' )
;;; The Boolean OR operator. e.g. X OR Y
;;; The result is zero if both values are zero else a non-zero value.
;;;
;;; @verbatim
;;; e.g.    0 OR 0  returns 0.
;;;        -3 OR 0  returns -3.
;;;         0 OR -3 returns 1.
;;;        -3 OR 2  returns 1.
;;; @endverbatim
;;;
;;; A binary operation.
;;; On entry HL points to first operand (X) and DE to second operand (Y).
;;; @calls TEST_ZERO
;;; @jumps FP_0_1
OR_RTN:
        EX      DE,HL           ; make HL point to second number
        CALL    TEST_ZERO       ; routine TEST-ZERO
        EX      DE,HL           ; restore pointers
        RET     C               ; return if result was zero - first operand,
                                ; now the last value, is the result.

        SCF                     ; set carry flag
        JR      FP_0_1          ; back to FP-0/1 to overwrite the first operand
                                ; with the value 1.


;;; @brief THE 'NUMBER AND NUMBER' OPERATION
;;;
;;; (offset: $08 'no-&-no')
;;;   The Boolean AND operator.
;;;
;;; @verbatim
;;;   e.g.    -3 AND 2  returns -3.
;;;           -3 AND 0  returns 0.
;;;            0 and -2 returns 0.
;;;            0 and 0  returns 0.
;;; @endverbatim
;;;
;;;   Compare with OR routine above.
;;; @calls TEST_ZERO
;;; @jumps FP_0_1
NO_NO:
        EX      DE,HL           ; make HL address second operand.

        CALL    TEST_ZERO           ; routine TEST-ZERO sets carry if zero.

        EX      DE,HL           ; restore pointers.
        RET     NC              ; return if second non-zero, first is result.

;

        AND     A               ; else clear carry.
        JR      FP_0_1          ; back to FP-0/1 to overwrite first operand
                                ; with zero for return value.

;;; @brief THE 'STRING AND NUMBER' OPERATION
;;;
;;; (offset: $10 'str-&-no')
;;;   e.g. "You Win" AND score>99 will return the string if condition is true
;;;   or the null string if false.
;;; @calls TEST_ZERO, EXCHANGE, SUBTRACT, STK_FETCH
;;; @fallthrough BYTE_COMP
STR_NO:
        EX      DE,HL           ; make HL point to the number.
        CALL    TEST_ZERO       ; routine TEST-ZERO.
        EX      DE,HL           ; restore pointers.
        RET     NC              ; return if number was not zero - the string
                                ; is the result.

;   if the number was zero (false) then the null string must be returned by
;   altering the length of the string on the calculator stack to zero.

        PUSH    DE              ; save pointer to the now obsolete number
                                ; (which will become the new STKEND)

        DEC     DE              ; point to the 5th byte of string descriptor.
        XOR     A               ; clear the accumulator.
        LD      (DE),A          ; place zero in high byte of length.
        DEC     DE              ; address low byte of length.
        LD      (DE),A          ; place zero there - now the null string.

        POP     DE              ; restore pointer - new STKEND.
        RET                     ; return.

; ---------------------------
; THE 'COMPARISON' OPERATIONS
; ---------------------------
; (offset: $0A 'no-gr-eql')
; (offset: $0B 'nos-neql')
; (offset: $0C 'no-grtr')
; (offset: $0D 'no-less')
; (offset: $0E 'nos-eql')
; (offset: $11 'str-l-eql')
; (offset: $12 'str-gr-eql')
; (offset: $13 'strs-neql')
; (offset: $14 'str-grtr')
; (offset: $15 'str-less')
; (offset: $16 'strs-eql')

;   True binary operations.
;   A single entry point is used to evaluate six numeric and six string
;   comparisons. On entry, the calculator literal is in the B register and
;   the two numeric values, or the two string parameters, are on the
;   calculator stack.
;   The individual bits of the literal are manipulated to group similar
;   operations although the SUB 8 instruction does nothing useful and merely
;   alters the string test bit.
;   Numbers are compared by subtracting one from the other, strings are
;   compared by comparing every character until a mismatch, or the end of one
;   or both, is reached.
;
;   Numeric Comparisons.
;   --------------------
;   The 'x>y' example is the easiest as it employs straight-thru logic.
;   Number y is subtracted from x and the result tested for greater-0 yielding
;   a final value 1 (true) or 0 (false).
;   For 'x<y' the same logic is used but the two values are first swapped on the
;   calculator stack.
;   For 'x=y' NOT is applied to the subtraction result yielding true if the
;   difference was zero and false with anything else.
;   The first three numeric comparisons are just the opposite of the last three
;   so the same processing steps are used and then a final NOT is applied.
;
; literal    Test   No  sub 8       ExOrNot  1st RRCA  exch sub  ?   End-Tests
; =========  ====   == ======== === ======== ========  ==== ===  =  === === ===
; no-l-eql   x<=y   09 00000001 dec 00000000 00000000  ---- x-y  ?  --- >0? NOT
; no-gr-eql  x>=y   0A 00000010 dec 00000001 10000000c swap y-x  ?  --- >0? NOT
; nos-neql   x<>y   0B 00000011 dec 00000010 00000001  ---- x-y  ?  NOT --- NOT
; no-grtr    x>y    0C 00000100  -  00000100 00000010  ---- x-y  ?  --- >0? ---
; no-less    x<y    0D 00000101  -  00000101 10000010c swap y-x  ?  --- >0? ---
; nos-eql    x=y    0E 00000110  -  00000110 00000011  ---- x-y  ?  NOT --- ---
;
;                                                           comp -> C/F
;                                                           ====    ===
; str-l-eql  x$<=y$ 11 00001001 dec 00001000 00000100  ---- x$y$ 0  !or >0? NOT
; str-gr-eql x$>=y$ 12 00001010 dec 00001001 10000100c swap y$x$ 0  !or >0? NOT
; strs-neql  x$<>y$ 13 00001011 dec 00001010 00000101  ---- x$y$ 0  !or >0? NOT
; str-grtr   x$>y$  14 00001100  -  00001100 00000110  ---- x$y$ 0  !or >0? ---
; str-less   x$<y$  15 00001101  -  00001101 10000110c swap y$x$ 0  !or >0? ---
; strs-eql   x$=y$  16 00001110  -  00001110 00000111  ---- x$y$ 0  !or >0? ---
;
;   String comparisons are a little different in that the eql/neql carry flag
;   from the 2nd RRCA is, as before, fed into the first of the end tests but
;   along the way it gets modified by the comparison process. The result on the
;   stack always starts off as zero and the carry fed in determines if NOT is
;   applied to it. So the only time the greater-0 test is applied is if the
;   stack holds zero which is not very efficient as the test will always yield
;   zero. The most likely explanation is that there were once separate end tests
;   for numbers and strings.

NO_L_EQL_ETC:
        LD      A,B             ; transfer literal to accumulator.
        SUB     $08             ; subtract eight - which is not useful.

        BIT     2,A             ; isolate '>', '<', '='.

        JR      NZ,EX_OR_NOT        ; skip to EX-OR-NOT with these.

        DEC     A               ; else make $00-$02, $08-$0A to match bits 0-2.

EX_OR_NOT:
        RRCA                    ; the first RRCA sets carry for a swap.
        JR      NC,NU_OR_STR    ; forward to NU-OR-STR with other 8 cases

; for the other 4 cases the two values on the calculator stack are exchanged.

        PUSH    AF              ; save A and carry.
        PUSH    HL              ; save HL - pointer to first operand.
                                ; (DE points to second operand).

        CALL    EXCHANGE           ; routine exchange swaps the two values.
                                ; (HL = second operand, DE = STKEND)

        POP     DE              ; DE = first operand
        EX      DE,HL           ; as we were.
        POP     AF              ; restore A and carry.

; Note. it would be better if the 2nd RRCA preceded the string test.
; It would save two duplicate bytes and if we also got rid of that sub 8
; at the beginning we wouldn't have to alter which bit we test.

NU_OR_STR:
        BIT     2,A             ; test if a string comparison.
        JR      NZ,STRINGS      ; forward to STRINGS if so.

; continue with numeric comparisons.

        RRCA                    ; 2nd RRCA causes eql/neql to set carry.
        PUSH    AF              ; save A and carry

        CALL    SUBTRACT           ; routine subtract leaves result on stack.
        JR      END_TESTS          ; forward to END-TESTS

; ---

STRINGS
        RRCA                    ; 2nd RRCA causes eql/neql to set carry.
        PUSH    AF              ; save A and carry.

        CALL    STK_FETCH       ; routine STK-FETCH gets 2nd string params
        PUSH    DE              ; save start2 *.
        PUSH    BC              ; and the length.

        CALL    STK_FETCH           ; routine STK-FETCH gets 1st string
                                ; parameters - start in DE, length in BC.
        POP     HL              ; restore length of second to HL.

; A loop is now entered to compare, by subtraction, each corresponding character
; of the strings. For each successful match, the pointers are incremented and
; the lengths decreased and the branch taken back to here. If both string
; remainders become null at the same time, then an exact match exists.

;;; @brief ; BYTE-COMP
;;;
;;; ; BYTE-COMP
;;; @jumpedfrom SECND_LOW
;;; @fallthrough SECND_LOW
BYTE_COMP:
        LD      A,H             ; test if the second string
        OR      L               ; is the null string and hold flags.

        EX      (SP),HL         ; put length2 on stack, bring start2 to HL *.
        LD      A,B             ; hi byte of length1 to A

        JR      NZ,SEC_PLUS        ; forward to SEC-PLUS if second not null.

        OR      C               ; test length of first string.

;;; @brief ; SECND-LOW
;;;
;;; ; SECND-LOW
;;; @calls NOT_RTN, GREATER_0
;;; @jumps BYTE_COMP
SECND_LOW:
        POP     BC              ; pop the second length off stack.
        JR      Z,BOTH_NULL     ; forward to BOTH-NULL if first string is also
                                ; of zero length.

; the true condition - first is longer than second (SECND-LESS)

        POP     AF              ; restore carry (set if eql/neql)
        CCF                     ; complement carry flag.
                                ; Note. equality becomes false.
                                ; Inequality is true. By swapping or applying
                                ; a terminal 'not', all comparisons have been
                                ; manipulated so that this is success path.
        JR      STR_TEST           ; forward to leave via STR-TEST

; ---
; the branch was here with a match

BOTH_NULL:
        POP     AF              ; restore carry - set for eql/neql
        JR      STR_TEST        ; forward to STR-TEST

; ---
; the branch was here when 2nd string not null and low byte of first is yet
; to be tested.

SEC_PLUS:
        OR      C               ; test the length of first string.
        JR      Z,FRST_LESS     ; forward to FRST-LESS if length is zero.

; both strings have at least one character left.

        LD      A,(DE)          ; fetch character of first string.
        SUB     (HL)            ; subtract with that of 2nd string.
        JR      C,FRST_LESS     ; forward to FRST-LESS if carry set

        JR      NZ,SECND_LOW        ; back to SECND-LOW and then STR-TEST
                                ; if not exact match.

        DEC     BC              ; decrease length of 1st string.
        INC     DE              ; increment 1st string pointer.

        INC     HL              ; increment 2nd string pointer.
        EX      (SP),HL         ; swap with length on stack
        DEC     HL              ; decrement 2nd string length
        JR      BYTE_COMP       ; back to BYTE-COMP

; ---
; the false condition.

FRST_LESS:
        POP     BC              ; discard length
        POP     AF              ; pop A
        AND     A               ; clear the carry for false result.

; ---
; exact match and x$>y$ rejoin here

STR_TEST:
        PUSH    AF              ; save A and carry

        RST     28H                 ;; FP-CALC
        DB          $A0             ;;stk-zero      an initial false value.
        DB          $38             ;;end-calc

; both numeric and string paths converge here.

END_TESTS:
        POP     AF              ; pop carry  - will be set if eql/neql
        PUSH    AF              ; save it again.

        CALL    C,NOT_RTN         ; routine NOT sets true(1) if equal(0)
                                ; or, for strings, applies true result.

        POP     AF              ; pop carry and
        PUSH    AF              ; save A

        CALL    NC,GREATER_0        ; routine GREATER-0 tests numeric subtraction
                                ; result but also needlessly tests the string
                                ; value for zero - it must be.

        POP     AF              ; pop A
        RRCA                    ; the third RRCA - test for '<=', '>=' or '<>'.
        CALL    NC,NOT_RTN      ; apply a terminal NOT if so.
        RET                     ; return.

;;; @brief THE 'STRING CONCATENATION' OPERATION
;;;
;;; (offset: $17 'strs-add')
;;;   This literal combines two strings into one e.g. LET a$ = b$ + c$
;;;   The two parameters of the two strings to be combined are on the stack.
;;; @calls STK_FETCH, STK_STO
;;; @jumps STK_PNTRS
;;; @fallthrough STK_PNTRS
STRS_ADD:
        CALL    STK_FETCH           ; routine STK-FETCH fetches string parameters
                                ; and deletes calculator stack entry.
        PUSH    DE              ; save start address.
        PUSH    BC              ; and length.

        CALL    STK_FETCH       ; routine STK-FETCH for first string
        POP     HL              ; re-fetch first length
        PUSH    HL              ; and save again
        PUSH    DE              ; save start of second string
        PUSH    BC              ; and its length.

        ADD     HL,BC           ; add the two lengths.
        LD      B,H             ; transfer to BC
        LD      C,L             ; and create
        RST     30H             ; BC-SPACES in workspace.
                                ; DE points to start of space.

        CALL    STK_STO           ; routine STK-STO-$ stores parameters
                                ; of new string updating STKEND.

        POP     BC              ; length of first
        POP     HL              ; address of start
        LD      A,B             ; test for
        OR      C               ; zero length.
        JR      Z,OTHER_STR     ; to OTHER-STR if null string

        LDIR                    ; copy string to workspace.

OTHER_STR:
        POP     BC              ; now second length
        POP     HL              ; and start of string
        LD      A,B             ; test this one
        OR      C               ; for zero length
        JR      Z,STK_PNTRS     ; skip forward to STK-PNTRS if so as complete.

        LDIR                    ; else copy the bytes.
                                ; and continue into next routine which
                                ; sets the calculator stack pointers.

;;; @brief THE 'SET STACK POINTERS' SUBROUTINE
;;;
;;;   Register DE is set to STKEND and HL, the result pointer, is set to five
;;;   locations below this.
;;;   This routine is used when it is inconvenient to save these values at the
;;;   time the calculator stack is manipulated due to other activity on the
;;;   machine stack.
;;;   This routine is also used to terminate the VAL and READ-IN  routines for
;;;   the same reason and to initialize the calculator stack at the start of
;;;   the CALCULATE routine.
;;; @calledby CALCULATE
;;; @jumpedfrom STRS_ADD, VAL, READ_IN
STK_PNTRS:
        LD      HL,(STKEND)      ; fetch STKEND value from system variable.
        LD      DE,$FFFB        ; the value -5
        PUSH    HL              ; push STKEND value.

        ADD     HL,DE           ; subtract 5 from HL.

        POP     DE              ; pop STKEND to DE.
        RET                     ; return.

;;; @brief THE 'CHR$' FUNCTION
;;;
;;; (offset: $2f 'chr$')
;;;   This function returns a single character string that is a result of
;;;   converting a number in the range 0-255 to a string e.g. CHR$ 65 = "A".
;;; @calls FP_TO_A, STK_STO
CHRS:
        CALL    FP_TO_A           ; routine FP-TO-A puts the number in A.

        JR      C,REPORT_BD         ; forward to REPORT-Bd if overflow
        JR      NZ,REPORT_BD        ; forward to REPORT-Bd if negative

        PUSH    AF              ; save the argument.

        LD      BC,$0001        ; one space required.
        RST     30H             ; BC-SPACES makes DE point to start

        POP     AF              ; restore the number.

        LD      (DE),A          ; and store in workspace

        CALL    STK_STO           ; routine STK-STO-$ stacks descriptor.

        EX      DE,HL           ; make HL point to result and DE to STKEND.
        RET                     ; return.

; ---

REPORT_BD:
        RST     08H             ; ERROR-1
        DB          $0A         ; Error Report: Integer out of range

;;; @brief THE 'VAL and VAL$' FUNCTIONS
;;;
;;; (offset: $1d 'val')
;;; (offset: $18 'val$')
;;;   VAL treats the characters in a string as a numeric expression.
;;;   e.g. VAL "2.3" = 2.3, VAL "2+4" = 6, VAL ("2" + "4") = 24.
;;;   VAL$ treats the characters in a string as a string expression.
;;;   e.g. VAL$ (z$+"(2)") = a$(2) if z$ happens to be "a$".
;;; @calls STK_FETCH, SCANNING
;;; @jumps REPORT_C, STK_PNTRS
VAL:
        LD      HL,(CH_ADD)      ; fetch value of system variable CH_ADD
        PUSH    HL              ; and save on the machine stack.
        LD      A,B             ; fetch the literal (either $1D or $18).
        ADD     A,$E3           ; add $E3 to form $00 (setting carry) or $FB.
        SBC     A,A             ; now form $FF bit 6 = numeric result
                                ; or $00 bit 6 = string result.
        PUSH    AF              ; save this mask on the stack

        CALL    STK_FETCH           ; routine STK-FETCH fetches the string operand
                                ; from calculator stack.

        PUSH    DE              ; save the address of the start of the string.
        INC     BC              ; increment the length for a carriage return.

        RST     30H             ; BC-SPACES creates the space in workspace.
        POP     HL              ; restore start of string to HL.
        LD      (CH_ADD),DE      ; load CH_ADD with start DE in workspace.

        PUSH    DE              ; save the start in workspace
        LDIR                    ; copy string from program or variables or
                                ; workspace to the workspace area.
        EX      DE,HL           ; end of string + 1 to HL
        DEC     HL              ; decrement HL to point to end of new area.
        LD      (HL),$0D        ; insert a carriage return at end.
        RES     7,(IY+$01)      ; update FLAGS  - signal checking syntax.
        CALL    SCANNING        ; routine SCANNING evaluates string
                                ; expression and result.

        RST     18H             ; GET-CHAR fetches next character.
        CP      $0D             ; is it the expected carriage return ?
        JR      NZ,V_RPORT_C    ; forward to V-RPORT-C if not
                                ; 'Nonsense in BASIC'.

        POP     HL              ; restore start of string in workspace.
        POP     AF              ; restore expected result flag (bit 6).
        XOR     (IY+$01)        ; xor with FLAGS now updated by SCANNING.
        AND     $40             ; test bit 6 - should be zero if result types
                                ; match.

V_RPORT_C:
        JP      NZ,REPORT_C        ; jump back to REPORT-C with a result mismatch.

        LD      (CH_ADD),HL      ; set CH_ADD to the start of the string again.
        SET     7,(IY+$01)      ; update FLAGS  - signal running program.
        CALL    SCANNING        ; routine SCANNING evaluates the string
                                ; in full leaving result on calculator stack.

        POP     HL              ; restore saved character address in program.
        LD      (CH_ADD),HL      ; and reset the system variable CH_ADD.

        JR      STK_PNTRS           ; back to exit via STK-PNTRS.
                                ; resetting the calculator stack pointers
                                ; HL and DE from STKEND as it wasn't possible
                                ; to preserve them during this routine.

;;; @brief THE 'STR$' FUNCTION
;;;
;;; (offset: $2e 'str$')
;;;   This function produces a string comprising the characters that would appear
;;;   if the numeric argument were printed.
;;;   e.g. STR$ (1/10) produces "0.1".
;;; @calls CHAN_OPEN, PRINT_FP, CHAN_FLAG, STK_STO
STR:
        LD      BC,$0001        ; create an initial byte in workspace
        RST     30H             ; using BC-SPACES restart.

        LD      (K_CUR),HL      ; set system variable K_CUR to new location.
        PUSH    HL              ; and save start on machine stack also.

        LD      HL,(CURCHL)      ; fetch value of system variable CURCHL
        PUSH    HL              ; and save that too.

        LD      A,$FF           ; select system channel 'R'.
        CALL    CHAN_OPEN       ; routine CHAN-OPEN opens it.
        CALL    PRINT_FP        ; routine PRINT-FP outputs the number to
                                ; workspace updating K-CUR.

        POP     HL              ; restore current channel.
        CALL    CHAN_FLAG       ; routine CHAN-FLAG resets flags.

        POP     DE              ; fetch saved start of string to DE.
        LD      HL,(K_CUR)      ; load HL with end of string from K_CUR.

        AND     A               ; prepare for true subtraction.
        SBC     HL,DE           ; subtract start from end to give length.
        LD      B,H             ; transfer the length to
        LD      C,L             ; the BC register pair.

        CALL    STK_STO           ; routine STK-STO-$ stores string parameters
                                ; on the calculator stack.

        EX      DE,HL           ; HL = last value, DE = STKEND.
        RET                     ; return.

;;; @brief THE 'READ-IN' SUBROUTINE
;;;
;;; (offset: $1a 'read-in')
;;;   This is the calculator literal used by the INKEY$ function when a '#'
;;;   is encountered after the keyword.
;;;   INKEY$ # does not interact correctly with the keyboard, #0 or #1, and
;;;   its uses are for other channels.
;;; @calls FIND_INT1, CHAN_OPEN, INPUT_AD, STK_STO, CHAN_FLAG
;;; @jumps REPORT_BB, STK_PNTRS
READ_IN:
        CALL    FIND_INT1           ; routine FIND-INT1 fetches stream to A
        CP      $10                 ; compare with 16 decimal.
        JP      NC,REPORT_BB        ; JUMP to REPORT-Bb if not in range 0 - 15.
                                ; 'Integer out of range'
                                ; (REPORT-Bd is within range)

        LD      HL,(CURCHL)      ; fetch current channel CURCHL
        PUSH    HL              ; save it

        CALL    CHAN_OPEN           ; routine CHAN-OPEN opens channel

        CALL    INPUT_AD           ; routine INPUT-AD - the channel must have an
                                ; input stream or else error here from stream
                                ; stub.
        LD      BC,$0000        ; initialize length of string to zero
        JR      NC,R_I_STORE    ; forward to R-I-STORE if no key detected.

        INC     C               ; increase length to one.

        RST     30H             ; BC-SPACES creates space for one character
                                ; in workspace.
        LD      (DE),A          ; the character is inserted.

R_I_STORE:
        CALL    STK_STO           ; routine STK-STO-$ stacks the string
                                ; parameters.
        POP     HL              ; restore current channel address

        CALL    CHAN_FLAG           ; routine CHAN-FLAG resets current channel
                                ; system variable and flags.

        JP      STK_PNTRS           ; jump back to STK-PNTRS

;;; @brief THE 'CODE' FUNCTION
;;;
;;; (offset: $1c 'code')
;;;   Returns the ASCII code of a character or first character of a string
;;;   e.g. CODE "Aardvark" = 65, CODE "" = 0.
;;; @calls STK_FETCH
;;; @jumps STACK_A
CODE:
        CALL    STK_FETCH           ; routine STK-FETCH to fetch and delete the
                                ; string parameters.
                                ; DE points to the start, BC holds the length.

        LD      A,B             ; test length
        OR      C               ; of the string.
        JR      Z,STK_CODE      ; skip to STK-CODE with zero if the null string.

        LD      A,(DE)          ; else fetch the first character.

STK_CODE:
        JP      STACK_A           ; jump back to STACK-A (with memory check)

;;; @brief THE 'LEN' FUNCTION
;;;
;;; (offset: $1e 'len')
;;;   Returns the length of a string.
;;;   In Sinclair BASIC strings can be more than twenty thousand characters long
;;;   so a sixteen-bit register is required to store the length
;;; @calls STK_FETCH
;;; @jumps STACK_BC
LEN:
        CALL    STK_FETCH           ; Routine STK-FETCH to fetch and delete the
                                ; string parameters from the calculator stack.
                                ; Register BC now holds the length of string.

        JP      STACK_BC           ; Jump back to STACK-BC to save result on the
                                ; calculator stack (with memory check).

;;; @brief THE 'DECREASE THE COUNTER' SUBROUTINE
;;;
;;; (offset: $35 'dec-jr-nz')
;;;   The calculator has an instruction that decrements a single-byte
;;;   pseudo-register and makes consequential relative jumps just like
;;;   the Z80's DJNZ instruction.
DEC_JR_NZ:
        EXX                     ; switch in set that addresses code

        PUSH    HL              ; save pointer to offset byte
        LD      HL,BREG        ; address BREG in system variables
        DEC     (HL)            ; decrement it
        POP     HL              ; restore pointer

        JR      NZ,JUMP_2        ; to JUMP-2 if not zero

        INC     HL              ; step past the jump length.
        EXX                     ; switch in the main set.
        RET                     ; return.

; Note. as a general rule the calculator avoids using the IY register
; otherwise the cumbersome 4 instructions in the middle could be replaced by
; dec (iy+$2d) - three bytes instead of six.


;;; @brief THE 'JUMP' SUBROUTINE
;;;
;;; (offset: $33 'jump')
;;;   This enables the calculator to perform relative jumps just like the Z80
;;;   chip's JR instruction.
;;; @jumpedfrom JUMP_TRUE
JUMP:
        EXX                     ; switch in pointer set

JUMP_2:
        LD      E,(HL)          ; the jump byte 0-127 forward, 128-255 back.
        LD      A,E             ; transfer to accumulator.
        RLA                     ; if backward jump, carry is set.
        SBC     A,A             ; will be $FF if backward or $00 if forward.
        LD      D,A             ; transfer to high byte.
        ADD     HL,DE           ; advance calculator pointer forward or back.

        EXX                     ; switch back.
        RET                     ; return.

;;; @brief THE 'JUMP-TRUE' SUBROUTINE
;;;
;;; (offset: $00 'jump-true')
;;;   This enables the calculator to perform conditional relative jumps dependent
;;;   on whether the last test gave a true result.
;;; @jumps JUMP
JUMP_TRUE:
        INC     DE              ; Collect the
        INC     DE              ; third byte
        LD      A,(DE)          ; of the test
        DEC     DE              ; result and
        DEC     DE              ; backtrack.

        AND     A              ; Is result 0 or 1 ?
        JR      NZ,JUMP        ; Back to JUMP if true (1).

        EXX                     ; Else switch in the pointer set.
        INC     HL              ; Step past the jump length.
        EXX                     ; Switch in the main set.
        RET                     ; Return.

;;; @brief THE 'END-CALC' SUBROUTINE
;;;
;;; (offset: $38 'end-calc')
;;;   The end-calc literal terminates a mini-program written in the Spectrum's
;;;   internal language.
END_CALC:
        POP     AF              ; Drop the calculator return address RE-ENTRY
        EXX                     ; Switch to the other set.

        EX      (SP),HL         ; Transfer H'L' to machine stack for the
                                ; return address.
                                ; When exiting recursion, then the previous
                                ; pointer is transferred to H'L'.

        EXX                     ; Switch back to main set.
        RET                     ; Return.


;;; @brief THE 'MODULUS' SUBROUTINE
;;;
;;; (offset: $32 'n-mod-m')
;;; (n1,n2 -- r,q)
;;;   Similar to FORTH's 'divide mod' /MOD
;;;   On the Spectrum, this is only used internally by the RND function and could
;;;   have been implemented inline.  On the ZX81, this calculator routine was also
;;;   used by PRINT-FP.
N_MOD_M:
        RST     28H                 ;; FP-CALC          17, 3.
        DB          $C0             ;;st-mem-0          17, 3.
        DB          $02             ;;delete            17.
        DB          $31             ;;duplicate         17, 17.
        DB          $E0             ;;get-mem-0         17, 17, 3.
        DB          $05             ;;division          17, 17/3.
        DB          $27             ;;int               17, 5.
        DB          $E0             ;;get-mem-0         17, 5, 3.
        DB          $01             ;;exchange          17, 3, 5.
        DB          $C0             ;;st-mem-0          17, 3, 5.
        DB          $04             ;;multiply          17, 15.
        DB          $03             ;;subtract          2.
        DB          $E0             ;;get-mem-0         2, 5.
        DB          $38             ;;end-calc          2, 5.

        RET                     ; return.


;;; @brief THE 'INT' FUNCTION
;;;
;;; (offset $27: 'int' )
;;; This function returns the integer of x, which is just the same as truncate
;;; for positive numbers. The truncate literal truncates negative numbers
;;; upwards so that -3.4 gives -3 whereas the BASIC INT function has to
;;; truncate negative numbers down so that INT -3.4 is -4.
;;; It is best to work through using, say, +-3.4 as examples.
INT:
        RST     28H                 ;; FP-CALC              x.    (= 3.4 or -3.4).
        DB          $31             ;;duplicate             x, x.
        DB          $36             ;;less-0                x, (1/0)
        DB          $00             ;;jump-true             x, (1/0)
        DB          $04             ;;to X_NEG, X-NEG

        DB          $3A             ;;truncate              trunc 3.4 = 3.
        DB          $38             ;;end-calc              3.

        RET                     ; return with + int x on stack.

; ---

X_NEG:
        DB          $31             ;;duplicate             -3.4, -3.4.
        DB          $3A             ;;truncate              -3.4, -3.
        DB          $C0             ;;st-mem-0              -3.4, -3.
        DB          $03             ;;subtract              -.4
        DB          $E0             ;;get-mem-0             -.4, -3.
        DB          $01             ;;exchange              -3, -.4.
        DB          $30             ;;not                   -3, (0).
        DB          $00             ;;jump-true             -3.
        DB          $03             ;;to EXIT, EXIT        -3.

        DB          $A1             ;;stk-one               -3, 1.
        DB          $03             ;;subtract              -4.

EXIT:
        DB          $38             ;;end-calc              -4.

        RET                     ; return.


;;; @brief THE 'EXP' FUNCTION
;;;
;;; (offset $26: 'exp')
;;;   The exponential function EXP x is equal to e^x, where e is the mathematical
;;;   name for a number approximated to 2.718281828.
;;;   ERROR 6 if argument is more than about 88.
;;; @calls FP_TO_A
;;; @jumps RSLT_ZERO
;;; @jumpedfrom TO_POWER
EXP:
        RST     28H                 ;; FP-CALC
        DB          $3D             ;;re-stack      (not required - mult will do)
        DB          $34             ;;stk-data
        DB          $F1             ;;Exponent: $81, Bytes: 4
        DB          $38,$AA,$3B,$29 ;;
        DB          $04             ;;multiply
        DB          $31             ;;duplicate
        DB          $27             ;;int
        DB          $C3             ;;st-mem-3
        DB          $03             ;;subtract
        DB          $31             ;;duplicate
        DB          $0F             ;;addition
        DB          $A1             ;;stk-one
        DB          $03             ;;subtract
        DB          $88             ;;series-08
        DB          $13             ;;Exponent: $63, Bytes: 1
        DB          $36             ;;(+00,+00,+00)
        DB          $58             ;;Exponent: $68, Bytes: 2
        DB          $65,$66         ;;(+00,+00)
        DB          $9D             ;;Exponent: $6D, Bytes: 3
        DB          $78,$65,$40     ;;(+00)
        DB          $A2             ;;Exponent: $72, Bytes: 3
        DB          $60,$32,$C9     ;;(+00)
        DB          $E7             ;;Exponent: $77, Bytes: 4
        DB          $21,$F7,$AF,$24 ;;
        DB          $EB             ;;Exponent: $7B, Bytes: 4
        DB          $2F,$B0,$B0,$14 ;;
        DB          $EE             ;;Exponent: $7E, Bytes: 4
        DB          $7E,$BB,$94,$58 ;;
        DB          $F1             ;;Exponent: $81, Bytes: 4
        DB          $3A,$7E,$F8,$CF ;;
        DB          $E3             ;;get-mem-3
        DB          $38             ;;end-calc

        CALL    FP_TO_A           ; routine FP-TO-A
        JR      NZ,N_NEGTV        ; to N-NEGTV

        JR      C,REPORT_6B         ; to REPORT-6b
                                ; 'Number too big'

        ADD     A,(HL)          ;
        JR      NC,RESULT_OK    ; to RESULT-OK

REPORT_6B:
        RST     08H             ; ERROR-1
        DB          $05         ; Error Report: Number too big

; ---

N_NEGTV:
        JR      C,RSLT_ZERO         ; to RSLT-ZERO

        SUB     (HL)            ;
        JR      NC,RSLT_ZERO    ; to RSLT-ZERO

        NEG                     ; Negate
RESULT_OK:
        LD      (HL),A          ;
        RET                     ; return.

; ---


;;; @brief ; RSLT-ZERO
;;;
;;; ; RSLT-ZERO
;;; @jumpedfrom EXP
RSLT_ZERO:
        RST     28H                 ;; FP-CALC
        DB          $02             ;;delete
        DB          $A0             ;;stk-zero
        DB          $38             ;;end-calc

        RET                     ; return.


;;; @brief THE 'NATURAL LOGARITHM' FUNCTION
;;;
;;; (offset $25: 'ln')
;;;   Function to calculate the natural logarithm (to the base e ).
;;;   Natural logarithms were devised in 1614 by well-traveled Scotsman John
;;;   Napier who noted
;;;   "Nothing doth more molest and hinder calculators than the multiplications,
;;;    divisions, square and cubical extractions of great numbers".
;;;
;;;   Napier's logarithms enabled the above operations to be accomplished by
;;;   simple addition and subtraction simplifying the navigational and
;;;   astronomical calculations which beset his age.
;;;   Napier's logarithms were quickly overtaken by logarithms to the base 10
;;;   devised, in conjunction with Napier, by Henry Briggs a Cambridge-educated
;;;   professor of Geometry at Oxford University. These simplified the layout
;;;   of the tables enabling humans to easily scale calculations.
;;;
;;;   It is only recently with the introduction of pocket calculators and machines
;;;   like the ZX Spectrum that natural logarithms are once more at the fore,
;;;   although some computers retain logarithms to the base ten.
;;;
;;;   'Natural' logarithms are powers to the base 'e', which like 'pi' is a
;;;   naturally occurring number in branches of mathematics.
;;;   Like 'pi' also, 'e' is an irrational number and starts 2.718281828...
;;;
;;;   The tabular use of logarithms was that to multiply two numbers one looked
;;;   up their two logarithms in the tables, added them together and then looked
;;;   for the result in a table of antilogarithms to give the desired product.
;;;
;;;   The EXP function is the BASIC equivalent of a calculator's 'antiln' function
;;;   and by picking any two numbers, 1.72 and 6.89 say,
;;;     10 PRINT EXP ( LN 1.72 + LN 6.89 )
;;;   will give just the same result as
;;;     20 PRINT 1.72 * 6.89.
;;;   Division is accomplished by subtracting the two logs.
;;;
;;;   Napier also mentioned "square and cubicle extractions".
;;;   To raise a number to the power 3, find its 'ln', multiply by 3 and find the
;;;   'antiln'.  e.g. PRINT EXP( LN 4 * 3 )  gives 64.
;;;   Similarly to find the n'th root divide the logarithm by 'n'.
;;;   The ZX81 ROM used PRINT EXP ( LN 9 / 2 ) to find the square root of the
;;;   number 9. The Napieran square root function is just a special case of
;;;   the 'to_power' function. A cube root or indeed any root/power would be just
;;;   as simple.
;;;
;;;   First test that the argument to LN is a positive, non-zero number.
;;;   Error A if the argument is 0 or negative.
;;; @calls STACK_A
LN:
        RST     28H                 ;; FP-CALC
        DB          $3D             ;;re-stack
        DB          $31             ;;duplicate
        DB          $37             ;;greater-0
        DB          $00             ;;jump-true
        DB          $04             ;;to VALID, VALID

        DB          $38             ;;end-calc


REPORT_AB:
        RST     08H             ; ERROR-1
        DB          $09         ; Error Report: Invalid argument

VALID:
        DB          $A0             ;;stk-zero              Note. not
        DB          $02             ;;delete                necessary.
        DB          $38             ;;end-calc
        LD      A,(HL)              ;

        LD      (HL),$80        ;
        CALL    STACK_A         ; routine STACK-A

        RST     28H                 ;; FP-CALC
        DB          $34             ;;stk-data
        DB          $38             ;;Exponent: $88, Bytes: 1
        DB          $00             ;;(+00,+00,+00)
        DB          $03             ;;subtract
        DB          $01             ;;exchange
        DB          $31             ;;duplicate
        DB          $34             ;;stk-data
        DB          $F0             ;;Exponent: $80, Bytes: 4
        DB          $4C,$CC,$CC,$CD ;;
        DB          $03             ;;subtract
        DB          $37             ;;greater-0
        DB          $00             ;;jump-true
        DB          $08             ;;to GRE_8, GRE.8

        DB          $01             ;;exchange
        DB          $A1             ;;stk-one
        DB          $03             ;;subtract
        DB          $01             ;;exchange
        DB          $38             ;;end-calc

        INC     (HL)            ;

        RST     28H             ;; FP-CALC

GRE_8:
        DB          $01             ;;exchange
        DB          $34             ;;stk-data
        DB          $F0             ;;Exponent: $80, Bytes: 4
        DB          $31,$72,$17,$F8 ;;
        DB          $04             ;;multiply
        DB          $01             ;;exchange
        DB          $A2             ;;stk-half
        DB          $03             ;;subtract
        DB          $A2             ;;stk-half
        DB          $03             ;;subtract
        DB          $31             ;;duplicate
        DB          $34             ;;stk-data
        DB          $32             ;;Exponent: $82, Bytes: 1
        DB          $20             ;;(+00,+00,+00)
        DB          $04             ;;multiply
        DB          $A2             ;;stk-half
        DB          $03             ;;subtract
        DB          $8C             ;;series-0C
        DB          $11             ;;Exponent: $61, Bytes: 1
        DB          $AC             ;;(+00,+00,+00)
        DB          $14             ;;Exponent: $64, Bytes: 1
        DB          $09             ;;(+00,+00,+00)
        DB          $56             ;;Exponent: $66, Bytes: 2
        DB          $DA,$A5         ;;(+00,+00)
        DB          $59             ;;Exponent: $69, Bytes: 2
        DB          $30,$C5         ;;(+00,+00)
        DB          $5C             ;;Exponent: $6C, Bytes: 2
        DB          $90,$AA         ;;(+00,+00)
        DB          $9E             ;;Exponent: $6E, Bytes: 3
        DB          $70,$6F,$61     ;;(+00)
        DB          $A1             ;;Exponent: $71, Bytes: 3
        DB          $CB,$DA,$96     ;;(+00)
        DB          $A4             ;;Exponent: $74, Bytes: 3
        DB          $31,$9F,$B4     ;;(+00)
        DB          $E7             ;;Exponent: $77, Bytes: 4
        DB          $A0,$FE,$5C,$FC ;;
        DB          $EA             ;;Exponent: $7A, Bytes: 4
        DB          $1B,$43,$CA,$36 ;;
        DB          $ED             ;;Exponent: $7D, Bytes: 4
        DB          $A7,$9C,$7E,$5E ;;
        DB          $F0             ;;Exponent: $80, Bytes: 4
        DB          $6E,$23,$80,$93 ;;
        DB          $04             ;;multiply
        DB          $0F             ;;addition
        DB          $38             ;;end-calc

        RET                     ; return.


; -----------------------------
; THE 'TRIGONOMETRIC' FUNCTIONS
; -----------------------------
; Trigonometry is rocket science. It is also used by carpenters and pyramid
; builders.
; Some uses can be quite abstract but the principles can be seen in simple
; right-angled triangles. Triangles have some special properties -
;
; 1) The sum of the three angles is always PI radians (180 degrees).
;    Very helpful if you know two angles and wish to find the third.
; 2) In any right-angled triangle the sum of the squares of the two shorter
;    sides is equal to the square of the longest side opposite the right-angle.
;    Very useful if you know the length of two sides and wish to know the
;    length of the third side.
; 3) Functions sine, cosine and tangent enable one to calculate the length
;    of an unknown side when the length of one other side and an angle is
;    known.
; 4) Functions arcsin, arccosine and arctan enable one to calculate an unknown
;    angle when the length of two of the sides is known.

;;; @brief THE 'REDUCE ARGUMENT' SUBROUTINE
;;;
;;; (offset $39: 'get-argt')
;;;
;;; This routine performs two functions on the angle, in radians, that forms
;;; the argument to the sine and cosine functions.
;;; First it ensures that the angle 'wraps round'. That if a ship turns through
;;; an angle of, say, 3*PI radians (540 degrees) then the net effect is to turn
;;; through an angle of PI radians (180 degrees).
;;; Secondly it converts the angle in radians to a fraction of a right angle,
;;; depending within which quadrant the angle lies, with the periodicity
;;; resembling that of the desired sine value.
;;; The result lies in the range -1 to +1.
;;;
;;;                     90 deg.
;;;
;;; @verbatim
;;;                     (pi/2)
;;;              II       +1        I
;;;                       |
;;;        sin+      |\   |   /|    sin+
;;;        cos-      | \  |  / |    cos+
;;;        tan-      |  \ | /  |    tan+
;;;                  |   \|/)  |
;;; 180 deg. (pi) 0 -|----+----|-- 0  (0)   0 degrees
;;;                  |   /|\   |
;;;        sin-      |  / | \  |    sin-
;;;        cos-      | /  |  \ |    cos+
;;;        tan+      |/   |   \|    tan-
;;;                       |
;;;              III      -1       IV
;;;                     (3pi/2)
;;;
;;;                     270 deg.
;;; @endverbatim
GET_ARGT:
        RST     28H                 ;; FP-CALC      X.
        DB          $3D             ;;re-stack      (not rquired done by mult)
        DB          $34             ;;stk-data
        DB          $EE             ;;Exponent: $7E,
                                ;;Bytes: 4
        DB          $22,$F9,$83,$6E ;;              X, 1/(2*PI)
        DB          $04             ;;multiply      X/(2*PI) = fraction
        DB          $31             ;;duplicate
        DB          $A2             ;;stk-half
        DB          $0F             ;;addition
        DB          $27             ;;int

        DB          $03             ;;subtract      now range -.5 to .5

        DB          $31             ;;duplicate
        DB          $0F             ;;addition      now range -1 to 1.
        DB          $31             ;;duplicate
        DB          $0F             ;;addition      now range -2 to +2.

; quadrant I (0 to +1) and quadrant IV (-1 to 0) are now correct.
; quadrant II ranges +1 to +2.
; quadrant III ranges -2 to -1.

        DB          $31             ;;duplicate     Y, Y.
        DB          $2A             ;;abs           Y, abs(Y).    range 1 to 2
        DB          $A1             ;;stk-one       Y, abs(Y), 1.
        DB          $03             ;;subtract      Y, abs(Y)-1.  range 0 to 1
        DB          $31             ;;duplicate     Y, Z, Z.
        DB          $37             ;;greater-0     Y, Z, (1/0).

        DB          $C0             ;;st-mem-0         store as possible sign
                                ;;                 for cosine function.

        DB          $00             ;;jump-true
        DB          $04             ;;to ZPLUS, ZPLUS  with quadrants II and III.

; else the angle lies in quadrant I or IV and value Y is already correct.

        DB          $02             ;;delete        Y.   delete the test value.
        DB          $38             ;;end-calc      Y.

        RET                     ; return.       with Q1 and Q4           >>>

; ---

;;; @brief the branch was here with quadrants II (0 to 1) and III (1 to 0)
;;;
;;; the branch was here with quadrants II (0 to 1) and III (1 to 0).
;;; Y will hold -2 to -1 if this is quadrant III.
ZPLUS:
        DB          $A1             ;;stk-one         Y, Z, 1.
        DB          $03             ;;subtract        Y, Z-1.       Q3 = 0 to -1
        DB          $01             ;;exchange        Z-1, Y.
        DB          $36             ;;less-0          Z-1, (1/0).
        DB          $00             ;;jump-true       Z-1.
        DB          $02             ;;to YNEG, YNEG
                                ;;if angle in quadrant III

; else angle is within quadrant II (-1 to 0)

        DB          $1B             ;;negate          range +1 to 0.

YNEG:
        DB          $38             ;;end-calc        quadrants II and III correct.

        RET                     ; return.


;;; @brief THE 'COSINE' FUNCTION
;;;
;;; (offset $20: 'cos')
;;; Cosines are calculated as the sine of the opposite angle rectifying the
;;; sign depending on the quadrant rules.
;;;
;;;
;;; @verbatim
;;;           /|
;;;        h /y|
;;;         /  |o
;;;        /x  |
;;;       /----|
;;;         a
;;; @endverbatim
;;;
;;; The cosine of angle x is the adjacent side (a) divided by the hypotenuse 1.
;;; However if we examine angle y then a/h is the sine of that angle.
;;; Since angle x plus angle y equals a right-angle, we can find angle y by
;;; subtracting angle x from pi/2.
;;; However it's just as easy to reduce the argument first and subtract the
;;; reduced argument from the value 1 (a reduced right-angle).
;;; It's even easier to subtract 1 from the angle and rectify the sign.
;;; In fact, after reducing the argument, the absolute value of the argument
;;; is used and rectified using the test result stored in mem-0 by 'get-argt'
;;; for that purpose.
COS:
        RST     28H             ;; FP-CALC              angle in radians.
        DB          $39         ;;get-argt              X     reduce -1 to +1

        DB          $2A             ;;abs                   ABS X.   0 to 1
        DB          $A1             ;;stk-one               ABS X, 1.
        DB          $03             ;;subtract              now opposite angle
                                ;;                      although sign is -ve.

        DB          $E0             ;;get-mem-0             fetch the sign indicator
        DB          $00             ;;jump-true
        DB          $06             ;;fwd to C_ENT, C-ENT
                                ;;forward to common code if in QII or QIII.

        DB          $1B             ;;negate                else make sign +ve.
        DB          $33             ;;jump
        DB          $03             ;;fwd to C_ENT, C-ENT
                                ;; with quadrants I and IV.

;;; @brief THE 'SINE' FUNCTION
;;;
;;; (offset $1F: 'sin')
;;; This is a fundamental transcendental function from which others such as cos
;;; and tan are directly, or indirectly, derived.
;;; It uses the series generator to produce Chebyshev polynomials.
;;;
;;;
;;; @verbatim
;;;           /|
;;;        1 / |
;;;         /  |x
;;;        /a  |
;;;       /----|
;;;         y
;;; @endverbatim
;;;
;;; The 'get-argt' function is designed to modify the angle and its sign
;;; in line with the desired sine value and afterwards it can launch straight
;;; into common code.
SIN:
        RST     28H             ;; FP-CALC      angle in radians
        DB          $39         ;;get-argt      reduce - sign now correct.

C_ENT:
        DB          $31             ;;duplicate
        DB          $31             ;;duplicate
        DB          $04             ;;multiply
        DB          $31             ;;duplicate
        DB          $0F             ;;addition
        DB          $A1             ;;stk-one
        DB          $03             ;;subtract

        DB          $86             ;;series-06
        DB          $14             ;;Exponent: $64, Bytes: 1
        DB          $E6             ;;(+00,+00,+00)
        DB          $5C             ;;Exponent: $6C, Bytes: 2
        DB          $1F,$0B         ;;(+00,+00)
        DB          $A3             ;;Exponent: $73, Bytes: 3
        DB          $8F,$38,$EE     ;;(+00)
        DB          $E9             ;;Exponent: $79, Bytes: 4
        DB          $15,$63,$BB,$23 ;;
        DB          $EE             ;;Exponent: $7E, Bytes: 4
        DB          $92,$0D,$CD,$ED ;;
        DB          $F1             ;;Exponent: $81, Bytes: 4
        DB          $23,$5D,$1B,$EA ;;
        DB          $04             ;;multiply
        DB          $38             ;;end-calc

        RET                     ; return.

;;; @brief THE 'TANGENT' FUNCTION
;;;
;;; (offset $21: 'tan')
;;;
;;; Evaluates tangent x as    sin(x) / cos(x).
;;;
;;;
;;; @verbatim
;;;           /|
;;;        h / |
;;;         /  |o
;;;        /x  |
;;;       /----|
;;;         a
;;; @endverbatim
;;;
;;; the tangent of angle x is the ratio of the length of the opposite side
;;; divided by the length of the adjacent side. As the opposite length can
;;; be calculates using sin(x) and the adjacent length using cos(x) then
;;; the tangent can be defined in terms of the previous two functions.
;;;
;;; Error 6 if the argument, in radians, is too close to one like pi/2
;;; which has an infinite tangent. e.g. PRINT TAN (PI/2)  evaluates as 1/0.
;;; Similarly PRINT TAN (3*PI/2), TAN (5*PI/2) etc.
TAN:
        RST     28H                 ;; FP-CALC          x.
        DB          $31             ;;duplicate         x, x.
        DB          $1F             ;;sin               x, sin x.
        DB          $01             ;;exchange          sin x, x.
        DB          $20             ;;cos               sin x, cos x.
        DB          $05             ;;division          sin x/cos x (= tan x).
        DB          $38             ;;end-calc          tan x.

        RET                     ; return.

;;; @brief THE 'ARCTAN' FUNCTION
;;;
;;; (Offset $24: 'atn')
;;; the inverse tangent function with the result in radians.
;;; This is a fundamental transcendental function from which others such as asn
;;; and acs are directly, or indirectly, derived.
;;; It uses the series generator to produce Chebyshev polynomials.
;;; @calls RE_STACK
ATN:
        CALL    RE_STACK        ; routine re-stack
        LD      A,(HL)          ; fetch exponent byte.
        CP      $81             ; compare to that for 'one'
        JR      C,SMALL         ; forward, if less, to SMALL

        RST     28H                 ;; FP-CALC
        DB          $A1             ;;stk-one
        DB          $1B             ;;negate
        DB          $01             ;;exchange
        DB          $05             ;;division
        DB          $31             ;;duplicate
        DB          $36             ;;less-0
        DB          $A3             ;;stk-pi/2
        DB          $01             ;;exchange
        DB          $00             ;;jump-true
        DB          $06             ;;to CASES, CASES

        DB          $1B             ;;negate
        DB          $33             ;;jump
        DB          $03             ;;to CASES, CASES

SMALL:
        RST     28H             ;; FP-CALC
        DB          $A0         ;;stk-zero

CASES:
        DB          $01             ;;exchange
        DB          $31             ;;duplicate
        DB          $31             ;;duplicate
        DB          $04             ;;multiply
        DB          $31             ;;duplicate
        DB          $0F             ;;addition
        DB          $A1             ;;stk-one
        DB          $03             ;;subtract
        DB          $8C             ;;series-0C
        DB          $10             ;;Exponent: $60, Bytes: 1
        DB          $B2             ;;(+00,+00,+00)
        DB          $13             ;;Exponent: $63, Bytes: 1
        DB          $0E             ;;(+00,+00,+00)
        DB          $55             ;;Exponent: $65, Bytes: 2
        DB          $E4,$8D         ;;(+00,+00)
        DB          $58             ;;Exponent: $68, Bytes: 2
        DB          $39,$BC         ;;(+00,+00)
        DB          $5B             ;;Exponent: $6B, Bytes: 2
        DB          $98,$FD         ;;(+00,+00)
        DB          $9E             ;;Exponent: $6E, Bytes: 3
        DB          $00,$36,$75     ;;(+00)
        DB          $A0             ;;Exponent: $70, Bytes: 3
        DB          $DB,$E8,$B4     ;;(+00)
        DB          $63             ;;Exponent: $73, Bytes: 2
        DB          $42,$C4         ;;(+00,+00)
        DB          $E6             ;;Exponent: $76, Bytes: 4
        DB          $B5,$09,$36,$BE ;;
        DB          $E9             ;;Exponent: $79, Bytes: 4
        DB          $36,$73,$1B,$5D ;;
        DB          $EC             ;;Exponent: $7C, Bytes: 4
        DB          $D8,$DE,$63,$BE ;;
        DB          $F0             ;;Exponent: $80, Bytes: 4
        DB          $61,$A1,$B3,$0C ;;
        DB          $04             ;;multiply
        DB          $0F             ;;addition
        DB          $38             ;;end-calc

        RET                     ; return.


;;; @brief THE 'ARCSIN' FUNCTION
;;;
;;; (Offset $22: 'asn')
;;;   The inverse sine function with result in radians.
;;;   Derived from arctan function above.
;;;   Error A unless the argument is between -1 and +1 inclusive.
;;;   Uses an adaptation of the formula asn(x) = atn(x/sqr(1-x*x))
;;;
;;;
;;; @verbatim
;;;                 /|
;;;                / |
;;;              1/  |x
;;;              /a  |
;;;             /----|
;;;               y
;;; @endverbatim
;;;
;;;   e.g. We know the opposite side (x) and hypotenuse (1)
;;;   and we wish to find angle a in radians.
;;;   We can derive length y by Pythagoras and then use ATN instead.
;;;   Since y*y + x*x = 1*1 (Pythagoras Theorem) then
;;;   y=sqr(1-x*x)                         - no need to multiply 1 by itself.
;;;   So, asn(a) = atn(x/y)
;;;   or more fully,
;;;   asn(a) = atn(x/sqr(1-x*x))
;;;
;;;   Close but no cigar.
;;;
;;;   While PRINT ATN (x/SQR (1-x*x)) gives the same results as PRINT ASN x,
;;;   it leads to division by zero when x is 1 or -1.
;;;   To overcome this, 1 is added to y giving half the required angle and the
;;;   result is then doubled.
;;;   That is, PRINT ATN (x/(SQR (1-x*x) +1)) *2
;;;
;;;   GEOMETRIC PROOF.
;;;
;;;
;;; @verbatim
;;;               . /|
;;;            .  c/ |
;;;         .     /1 |x
;;;      . c   b /a  |
;;;    ---------/----|
;;;      1      y
;;; @endverbatim
;;;
;;;   By creating an isosceles triangle with two equal sides of 1, angles c and
;;;   c are also equal. If b+c+c = 180 degrees and b+a = 180 degrees then c=a/2.
;;;
;;;   A value higher than 1 gives the required error as attempting to find  the
;;;   square root of a negative number generates an error in Sinclair BASIC.
ASN:
        RST     28H                 ;; FP-CALC      x.
        DB          $31             ;;duplicate     x, x.
        DB          $31             ;;duplicate     x, x, x.
        DB          $04             ;;multiply      x, x*x.
        DB          $A1             ;;stk-one       x, x*x, 1.
        DB          $03             ;;subtract      x, x*x-1.
        DB          $1B             ;;negate        x, 1-x*x.
        DB          $28             ;;sqr           x, sqr(1-x*x) = y
        DB          $A1             ;;stk-one       x, y, 1.
        DB          $0F             ;;addition      x, y+1.
        DB          $05             ;;division      x/y+1.
        DB          $24             ;;atn           a/2       (half the angle)
        DB          $31             ;;duplicate     a/2, a/2.
        DB          $0F             ;;addition      a.
        DB          $38             ;;end-calc      a.

        RET                     ; return.


;;; @brief THE 'ARCCOS' FUNCTION
;;;
;;; (Offset $23: 'acs')
;;; the inverse cosine function with the result in radians.
;;; Error A unless the argument is between -1 and +1.
;;; Result in range 0 to pi.
;;; Derived from asn above which is in turn derived from the preceding atn.
;;; It could have been derived directly from atn using acs(x) = atn(sqr(1-x*x)/x).
;;; However, as sine and cosine are horizontal translations of each other,
;;; uses acs(x) = pi/2 - asn(x)
;;;
;;; e.g. the arccosine of a known x value will give the required angle b in
;;; radians.
;;; We know, from above, how to calculate the angle a using asn(x).
;;; Since the three angles of any triangle add up to 180 degrees, or pi radians,
;;; and the largest angle in this case is a right-angle (pi/2 radians), then
;;; we can calculate angle b as pi/2 (both angles) minus asn(x) (angle a).
;;;
;;;
;;; @verbatim
;;;           /|
;;;        1 /b|
;;;         /  |x
;;;        /a  |
;;;       /----|
;;;         y
;;; @endverbatim
ACS:
        RST     28H                 ;; FP-CALC      x.
        DB          $22             ;;asn           asn(x).
        DB          $A3             ;;stk-pi/2      asn(x), pi/2.
        DB          $03             ;;subtract      asn(x) - pi/2.
        DB          $1B             ;;negate        pi/2 -asn(x)  =  acs(x).
        DB          $38             ;;end-calc      acs(x).

        RET                     ; return.


;;; @brief THE 'SQUARE ROOT' FUNCTION
;;;
;;; (Offset $28: 'sqr')
;;; This routine is remarkable for its brevity - 7 bytes.
;;; It wasn't written here but in the ZX81 where the programmers had to squeeze
;;; a bulky operating system into an 8K ROM. It simply calculates
;;; the square root by stacking the value .5 and continuing into the 'to-power'
;;; routine. With more space available the much faster Newton-Raphson method
;;; could have been used as on the Jupiter Ace.
SQR:
        RST     28H                 ;; FP-CALC
        DB          $31             ;;duplicate
        DB          $30             ;;not
        DB          $00             ;;jump-true
        DB          $1E             ;;to LAST, LAST

        DB          $A2             ;;stk-half
        DB          $38             ;;end-calc


;;; @brief THE 'EXPONENTIATION' OPERATION
;;;
;;; (Offset $06: 'to-power')
;;; This raises the first number X to the power of the second number Y.
;;; As with the ZX80,
;;; 0 ^ 0 = 1.
;;; 0 ^ +n = 0.
;;; 0 ^ -n = arithmetic overflow.
;;; @jumps EXP
TO_POWER:
        RST     28H                 ;; FP-CALC              X, Y.
        DB          $01             ;;exchange              Y, X.
        DB          $31             ;;duplicate             Y, X, X.
        DB          $30             ;;not                   Y, X, (1/0).
        DB          $00             ;;jump-true
        DB          $07             ;;to XIS0, XIS0   if X is zero.

;   else X is non-zero. Function 'ln' will catch a negative value of X.

        DB          $25             ;;ln                    Y, LN X.
        DB          $04             ;;multiply              Y * LN X.
        DB          $38             ;;end-calc

        JP      EXP           ; jump back to EXP routine   ->

; ---

;;; @brief these routines form the three simple results when the number is zero
;;;
;;;   these routines form the three simple results when the number is zero.
;;;   begin by deleting the known zero to leave Y the power factor.
XIS0:
        DB          $02             ;;delete                Y.
        DB          $31             ;;duplicate             Y, Y.
        DB          $30             ;;not                   Y, (1/0).
        DB          $00             ;;jump-true
        DB          $09             ;;to ONE, ONE         if Y is zero.

        DB          $A0             ;;stk-zero              Y, 0.
        DB          $01             ;;exchange              0, Y.
        DB          $37             ;;greater-0             0, (1/0).
        DB          $00             ;;jump-true             0.
        DB          $06             ;;to LAST, LAST        if Y was any positive
                                ;;                      number.

;   else force division by zero thereby raising an Arithmetic overflow error.
;   There are some one and two-byte alternatives but perhaps the most formal
;   might have been to use end-calc; rst 08; defb 05.

        DB          $A1             ;;stk-one               0, 1.
        DB          $01             ;;exchange              1, 0.
        DB          $05             ;;division              1/0        ouch!

; ---

ONE:
        DB          $02             ;;delete                .
        DB          $A1             ;;stk-one               1.

LAST:
        DB          $38             ;;end-calc              last value is 1 or 0.

        RET                     ; return.