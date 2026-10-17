;;; @file 09_arithmetic_routines.asm
;;; @brief Part 9. ARITHMETIC ROUTINES

;*********************************
;** Part 9. ARITHMETIC ROUTINES **
;*********************************

;;; @brief E-format to floating point
;;;
;;; This subroutine is used by the PRINT-FP routine and the decimal to FP
;;; routines to stack a number expressed in exponent format.
;;; Note. Though not used by the ROM as such, it has also been set up as
;;; a unary calculator literal but this will not work as the accumulator
;;; is not available from within the calculator.
;;;
;;; on entry there is a value x on the calculator stack and an exponent of ten
;;; in A.    The required value is x + 10 ^ A
;;; @calls FP_0_1
;;; @calledby PF_SMALL, PF_LARGE
;;; @jumpedfrom E_FP_JUMP
E_TO_FP:
        RLCA                    ; this will set the          x.
        RRCA                    ; carry if bit 7 is set

        JR      NC,E_SAVE        ; to E-SAVE  if positive.

        CPL                     ; make negative positive
        INC     A               ; without altering carry.

E_SAVE:
        PUSH    AF              ; save positive exp and sign in carry

        LD      HL,MEM_0        ; address MEM-0

        CALL    FP_0_1           ; routine FP-0/1
                                ; places an integer zero, if no carry,
                                ; else a one in mem-0 as a sign flag

        RST     28H             ;; FP-CALC
        DB          $A4             ;;stk-ten                    x, 10.
        DB          $38             ;;end-calc

        POP     AF              ; pop the exponent.

; now enter a loop

E_LOOP:
        SRL     A               ; 0>76543210>C

        JR      NC,E_TST_END        ; forward to E-TST-END if no bit

        PUSH    AF              ; save shifted exponent.

        RST     28H             ;; FP-CALC
        DB          $C1             ;;st-mem-1                   x, 10.
        DB          $E0             ;;get-mem-0                  x, 10, (0/1).
        DB          $00             ;;jump-true

        DB          $04             ;;to E_DIVSN, E-DIVSN

        DB          $04             ;;multiply                   x*10.
        DB          $33             ;;jump

        DB          $02             ;;to E_FETCH, E-FETCH

E_DIVSN:
        DB          $05             ;;division                   x/10.

E_FETCH:
        DB          $E1             ;;get-mem-1                  x/10 or x*10, 10.
        DB          $38             ;;end-calc                   new x, 10.

        POP     AF              ; restore shifted exponent

; the loop branched to here with no carry

E_TST_END:
        JR      Z,E_END         ; forward to E-END  if A emptied of bits

        PUSH    AF              ; re-save shifted exponent

        RST     28H             ;; FP-CALC
        DB          $31             ;;duplicate                  new x, 10, 10.
        DB          $04             ;;multiply                   new x, 100.
        DB          $38             ;;end-calc

        POP     AF              ; restore shifted exponent
        JR      E_LOOP           ; back to E-LOOP  until all bits done.

; ---

; although only the first pass is shown it can be seen that for each set bit
; representing a power of two, x is multiplied or divided by the
; corresponding power of ten.

E_END:
        RST     28H             ;; FP-CALC                   final x, factor.
        DB          $02             ;;delete                     final x.
        DB          $38             ;;end-calc                   x.

        RET                     ; return




;;; @brief Fetch integer
;;;
;;; This routine is called by the mathematical routines - FP-TO-BC, PRINT-FP,
;;; mult, re-stack and negate to fetch an integer from address HL.
;;; HL points to the stack or a location in MEM and no deletion occurs.
;;; If the number is negative then a similar process to that used in INT-STORE
;;; is used to restore the twos complement number to normal in DE and a sign
;;; in C.
;;;
;;; ; INT-FETCH
;;; @calledby FP_TO_BC, PF_LOOP, MULTIPLY, RE_STACK, INT_CASE
INT_FETCH:
        INC     HL              ; skip zero indicator.
        LD      C,(HL)          ; fetch sign to C
        INC     HL              ; address low byte
        LD      A,(HL)          ; fetch to A
        XOR     C               ; two's complement
        SUB     C               ;
        LD      E,A             ; place in E
        INC     HL              ; address high byte
        LD      A,(HL)          ; fetch to A
        ADC     A,C             ; two's complement
        XOR     C               ;
        LD      D,A             ; place in D
        RET                     ; return

;;; @brief Store a positive integer
;;;
;;; This entry point is not used in this ROM but would
;;; store any integer as positive.
;;; @fallthrough INT_STORE
P_INT_STO:
        LD      C,$00           ; make sign byte positive and continue

;;; @brief Store integer
;;;
;;; this routine stores an integer in DE at address HL.
;;; It is called from mult, truncate, negate and sgn.
;;; The sign byte $00 +ve or $FF -ve is in C.
;;; If negative, the number is stored in 2's complement form so that it is
;;; ready to be added.
;;; @calledby MULT_RSLT, T_STORE, INT_CASE, SGN
INT_STORE:
        PUSH    HL              ; preserve HL

        LD      (HL),$00        ; first byte zero shows integer not exponent
        INC     HL              ;
        LD      (HL),C          ; then store the sign byte
        INC     HL              ;
                                ; e.g.             +1             -1
        LD      A,E             ; fetch low byte   00000001       00000001
        XOR     C               ; xor sign         00000000   or  11111111
                                ; gives            00000001   or  11111110
        SUB     C               ; sub sign         00000000   or  11111111
                                ; gives            00000001>0 or  11111111>C
        LD      (HL),A          ; store 2's complement.
        INC     HL              ;
        LD      A,D             ; high byte        00000000       00000000
        ADC     A,C             ; sign             00000000<0     11111111<C
                                ; gives            00000000   or  00000000
        XOR     C               ; xor sign         00000000       11111111
        LD      (HL),A          ; store 2's complement.
        INC     HL              ;
        LD      (HL),$00        ; last byte always zero for integers.
                                ; is not used and need not be looked at when
                                ; testing for zero but comes into play should
                                ; an integer be converted to fp.
        POP     HL              ; restore HL
        RET                     ; return.


;;; @brief Floating point to BC register
;;;
;;; This routine gets a floating point number e.g. 127.4 from the calculator
;;; stack to the BC register.
;;; @calls INT_FETCH
;;; @calledby FIND_INT2, S_RND, FP_TO_A
FP_TO_BC:
        RST     28H             ;; FP-CALC            set HL to
        DB          $38             ;;end-calc            point to last value.

        LD      A,(HL)          ; get first of 5 bytes
        AND     A               ; and test
        JR      Z,FP_DELETE         ; forward to FP-DELETE if an integer

; The value is first rounded up and then converted to integer.

        RST     28H             ;; FP-CALC           x.
        DB          $A2             ;;stk-half           x. 1/2.
        DB          $0F             ;;addition           x + 1/2.
        DB          $27             ;;int                int(x + .5)
        DB          $38             ;;end-calc

; now delete but leave HL pointing at integer

FP_DELETE:
        RST     28H             ;; FP-CALC
        DB          $02             ;;delete
        DB          $38             ;;end-calc

        PUSH    HL              ; save pointer.
        PUSH    DE              ; and STKEND.
        EX      DE,HL           ; make HL point to exponent/zero indicator
        LD      B,(HL)          ; indicator to B
        CALL    INT_FETCH           ; routine INT-FETCH
                                ; gets int in DE sign byte to C
                                ; but meaningless values if a large integer

        XOR     A               ; clear A
        SUB     B               ; subtract indicator byte setting carry
                                ; if not a small integer.

        BIT     7,C             ; test a bit of the sign byte setting zero
                                ; if positive.

        LD      B,D             ; transfer int
        LD      C,E             ; to BC
        LD      A,E             ; low byte to A as a useful return value.

        POP     DE              ; pop STKEND
        POP     HL              ; and pointer to last value
        RET                     ; return
                                ; if carry is set then the number was too big.

;;; @brief LOG(2^A)
;;;
;;; This routine is used when printing floating point numbers to calculate
;;; the number of digits before the decimal point.
;;;
;;; first convert a one-byte signed integer to its five byte form.
;;; @calls STK_STORE
;;; @calledby PF_SMALL, PF_LARGE
LOG_2_A:
        LD      D,A             ; store a copy of A in D.
        RLA                     ; test sign bit of A.
        SBC     A,A             ; now $FF if negative or $00
        LD      E,A             ; sign byte to E.
        LD      C,A             ; and to C
        XOR     A               ; clear A
        LD      B,A             ; and B.
        CALL    STK_STORE           ; routine STK-STORE stacks number AEDCB

;  so 00 00 XX 00 00 (positive) or 00 FF XX FF 00 (negative).
;  i.e. integer indicator, sign byte, low, high, unused.

; now multiply exponent by log to the base 10 of two.

        RST      28H            ;; FP-CALC

        DB          $34             ;;stk-data                      .30103 (log 2)
        DB          $EF             ;;Exponent: $7F, Bytes: 4
        DB          $1A,$20,$9A,$85 ;;
        DB          $04             ;;multiply

        DB          $27             ;;int

        DB          $38             ;;end-calc

;;; @brief Floating point to A
;;;
;;; this routine collects a floating point number from the stack into the
;;; accumulator returning carry set if not in range 0 - 255.
;;; Not all the calling routines raise an error with overflow so no attempt
;;; is made to produce an error report here.
;;; @calls FP_TO_BC
;;; @jumps FP_A_END
;;; @calledby TWO_PARAM, FIND_INT1, STK_TO_A, CD_PRMS1, ST_E_PART, PF_SMALL, CHRS, EXP
FP_TO_A:
        CALL    FP_TO_BC           ; routine FP-TO-BC returns with C in A also.
        RET     C               ; return with carry set if > 65535, overflow

        PUSH    AF              ; save the value and flags
        DEC     B               ; and test that
        INC     B               ; the high byte is zero.
        JR      Z,FP_A_END         ; forward  FP-A-END if zero

; else there has been 8-bit overflow

        POP     AF              ; retrieve the value
        SCF                     ; set carry flag to show overflow
        RET                     ; and return.

; ---

;;; @brief ; FP-A-END
;;;
;;; ; FP-A-END
;;; @jumpedfrom FP_TO_A
FP_A_END:
        POP     AF              ; restore value and success flag and
        RET                     ; return.


;;; @brief Print a floating point number
;;;
;;; Not a trivial task.
;;; Begin by considering whether to print a leading sign for negative numbers.
;;;
;;; ; PRINT-FP
;;; @calledby STR
PRINT_FP:
        RST     28H             ;; FP-CALC
        DB          $31             ;;duplicate
        DB          $36             ;;less-0
        DB          $00             ;;jump-true

        DB          $0B             ;;to PF_NEGTVE, PF-NEGTVE

        DB          $31             ;;duplicate
        DB          $37             ;;greater-0
        DB          $00             ;;jump-true

        DB          $0D             ;;to PF_POSTVE, PF-POSTVE

; must be zero itself

        DB          $02             ;;delete
        DB          $38             ;;end-calc

        LD      A,$30           ; prepare the character '0'

        RST     10H             ; PRINT-A
        RET                     ; return.                 ->
; ---

;;; @brief ; PF-NEGTVE
;;;
;;; ; PF-NEGTVE
;;; @fallthrough PF_POSTVE
PF_NEGTVE:
        DB          $2A             ;;abs
        DB          $38             ;;end-calc

        LD      A,$2D           ; the character '-'

        RST     10H             ; PRINT-A

; and continue to print the now positive number.

        RST     28H             ;; FP-CALC

;;; @brief ; PF-POSTVE
;;;
;;; ; PF-POSTVE
;;; @fallthrough PF_LOOP
PF_POSTVE:
        DB          $A0             ;;stk-zero     x,0.     begin by
        DB          $C3             ;;st-mem-3     x,0.     clearing a temporary
        DB          $C4             ;;st-mem-4     x,0.     output buffer to
        DB          $C5             ;;st-mem-5     x,0.     fifteen zeros.
        DB          $02             ;;delete       x.
        DB          $38             ;;end-calc     x.

        EXX                     ; in case called from 'str$' then save the
        PUSH    HL              ; pointer to whatever comes after
        EXX                     ; str$ as H'L' will be used.

; now enter a loop?

;;; @brief ; PF-LOOP
;;;
;;; ; PF-LOOP
;;; @calls INT_FETCH
;;; @jumps PF_LARGE, PF_SAVE, PF_SMALL
;;; @jumpedfrom PF_LARGE
;;; @fallthrough PF_SAVE
PF_LOOP:
        RST     28H             ;; FP-CALC
        DB          $31             ;;duplicate    x,x.
        DB          $27             ;;int          x,int x.
        DB          $C2             ;;st-mem-2     x,int x.
        DB          $03             ;;subtract     x-int x.     fractional part.
        DB          $E2             ;;get-mem-2    x-int x, int x.
        DB          $01             ;;exchange     int x, x-int x.
        DB          $C2             ;;st-mem-2     int x, x-int x.
        DB          $02             ;;delete       int x.
        DB          $38             ;;end-calc     int x.
                                ;
                                ; mem-2 holds the fractional part.

; HL points to last value int x

        LD      A,(HL)          ; fetch exponent of int x.
        AND     A               ; test
        JR      NZ,PF_LARGE        ; forward to PF-LARGE if a large integer
                                ; > 65535

; continue with small positive integer components in range 0 - 65535
; if original number was say .999 then this integer component is zero.

        CALL    INT_FETCH           ; routine INT-FETCH gets x in DE
                                ; (but x is not deleted)

        LD      B,$10           ; set B, bit counter, to 16d

        LD      A,D             ; test if
        AND     A               ; high byte is zero
        JR      NZ,PF_SAVE        ; forward to PF-SAVE if 16-bit integer.

; and continue with integer in range 0 - 255.

        OR      E               ; test the low byte for zero
                                ; i.e. originally just point something or other.
        JR      Z,PF_SMALL         ; forward if so to PF-SMALL

;

        LD      D,E             ; transfer E to D
        LD      B,$08           ; and reduce the bit counter to 8.

;;; @brief ; PF-SAVE
;;;
;;; ; PF-SAVE
;;; @jumps PF_BITS
;;; @jumpedfrom PF_LOOP
PF_SAVE:
        PUSH    DE              ; save the part before decimal point.
        EXX                     ;
        POP     DE              ; and pop in into D'E'
        EXX                     ;
        JR      PF_BITS           ; forward to PF-BITS

; ---------------------

; the branch was here when 'int x' was found to be zero as in say 0.5.
; The zero has been fetched from the calculator stack but not deleted and
; this should occur now. This omission leaves the stack unbalanced and while
; that causes no problems with a simple PRINT statement, it will if str$ is
; being used in an expression e.g. "2" + STR$ 0.5 gives the result "0.5"
; instead of the expected result "20.5".
; credit Tony Stratton, 1982.
; A DEFB 02 delete is required immediately on using the calculator.

;;; @brief ; PF-SMALL
;;;
;;; ; PF-SMALL
;;; @calls LOG_2_A, E_TO_FP, FP_TO_A
;;; @jumps PF_FRACTN
;;; @jumpedfrom PF_LOOP
PF_SMALL:
        RST     28H             ;; FP-CALC       int x = 0.
L2E25:
        DB          $E2             ;;get-mem-2      int x = 0, x-int x.
        DB          $38             ;;end-calc

        LD      A,(HL)          ; fetch exponent of positive fractional number
        SUB     $7E             ; subtract

        CALL    LOG_2_A           ; routine LOG(2^A) calculates leading digits.

        LD      D,A             ; transfer count to D
        LD      A,($5CAC)       ; fetch total MEM-5-1
        SUB     D               ;
        LD      ($5CAC),A       ; MEM-5-1
        LD      A,D             ;
        CALL    E_TO_FP           ; routine E-TO-FP

        RST     28H             ;; FP-CALC
        DB          $31             ;;duplicate
        DB          $27             ;;int
        DB          $C1             ;;st-mem-1
        DB          $03             ;;subtract
        DB          $E1             ;;get-mem-1
        DB          $38             ;;end-calc

        CALL    FP_TO_A           ; routine FP-TO-A

        PUSH    HL              ; save HL
        LD      ($5CA1),A       ; MEM-3-1
        DEC     A               ;
        RLA                     ;
        SBC     A,A             ;
        INC     A               ;

        LD      HL,$5CAB        ; address MEM-5-1 leading digit counter
        LD      (HL),A          ; store counter
        INC     HL              ; address MEM-5-2 total digits
        ADD     A,(HL)          ; add counter to contents
        LD      (HL),A          ; and store updated value
        POP     HL              ; restore HL

        JP      PF_FRACTN           ; JUMP forward to PF-FRACTN

; ---

; Note. while it would be pedantic to comment on every occasion a JP
; instruction could be replaced with a JR instruction, this applies to the
; above, which is useful if you wish to correct the unbalanced stack error
; by inserting a 'DEFB 02 delete' at L2E25, and maintain main addresses.

; the branch was here with a large positive integer > 65535 e.g. 123456789
; the accumulator holds the exponent.

;;; @brief ; PF-LARGE
;;;
;;; ; PF-LARGE
;;; @calls LOG_2_A, E_TO_FP
;;; @jumps PF_MEDIUM, PF_LOOP
;;; @jumpedfrom PF_LOOP
PF_LARGE:
        SUB     $80             ; make exponent positive
        CP      $1C             ; compare to 28
        JR      C,PF_MEDIUM         ; to PF-MEDIUM if integer <= 2^27

        CALL    LOG_2_A           ; routine LOG(2^A)
        SUB     $07             ;
        LD      B,A             ;
        LD      HL,$5CAC        ; address MEM-5-1 the leading digits counter.
        ADD     A,(HL)          ; add A to contents
        LD      (HL),A          ; store updated value.
        LD      A,B             ;
        NEG                     ; negate
        CALL    E_TO_FP           ; routine E-TO-FP
        JR      PF_LOOP           ; back to PF-LOOP

; ----------------------------

;;; @brief ; PF-MEDIUM
;;;
;;; ; PF-MEDIUM
;;; @calls FETCH_TWO
;;; @jumpedfrom PF_LARGE
;;; @fallthrough PF_BITS
PF_MEDIUM:
        EX      DE,HL           ;
        CALL    FETCH_TWO           ; routine FETCH-TWO
        EXX                     ;
        SET     7,D             ;
        LD      A,L             ;
        EXX                     ;
        SUB     $80             ;
        LD      B,A             ;

; the branch was here to handle bits in DE with 8 or 16 in B  if small int
; and integer in D'E', 6 nibbles will accommodate 065535 but routine does
; 32-bit numbers as well from above

;;; @brief ; PF-BITS
;;;
;;; ; PF-BITS
;;; @jumpedfrom PF_SAVE
;;; @fallthrough PF_BYTES
PF_BITS:
        SLA     E               ;  C<xxxxxxxx<0
        RL      D               ;  C<xxxxxxxx<C
        EXX                     ;
        RL      E               ;  C<xxxxxxxx<C
        RL      D               ;  C<xxxxxxxx<C
        EXX                     ;

        LD      HL,$5CAA        ; set HL to mem-4-5th last byte of buffer
        LD      C,$05           ; set byte count to 5 -  10 nibbles

;;; @brief ; PF-BYTES
;;;
;;; ; PF-BYTES
;;; @fallthrough PF_DIGITS
PF_BYTES:
        LD      A,(HL)          ; fetch 0 or prev value
        ADC     A,A             ; shift left add in carry    C<xxxxxxxx<C

        DAA                     ; Decimal Adjust Accumulator.
                                ; if greater than 9 then the left hand
                                ; nibble is incremented. If greater than
                                ; 99 then adjusted and carry set.
                                ; so if we'd built up 7 and a carry came in
                                ;      0000 0111 < C
                                ;      0000 1111
                                ; daa     1 0101  which is 15 in BCD

        LD      (HL),A          ; put back
        DEC     HL              ; work down thru mem 4
        DEC     C               ; decrease the 5 counter.
        JR      NZ,PF_BYTES        ; back to PF-BYTES until the ten nibbles rolled

        DJNZ    PF_BITS           ; back to PF-BITS until 8 or 16 (or 32) done

; at most 9 digits for 32-bit number will have been loaded with digits
; each of the 9 nibbles in mem 4 is placed into ten bytes in mem-3 and mem 4
; unless the nibble is zero as the buffer is already zero.
; ( or in the case of mem-5 will become zero as a result of RLD instruction )

        XOR     A               ; clear to accept
        LD      HL,$5CA6        ; address MEM-4-0 byte destination.
        LD      DE,$5CA1        ; address MEM-3-0 nibble source.
        LD      B,$09           ; the count is 9 (not ten) as the first
                                ; nibble is known to be blank.

        RLD                     ; shift RH nibble to left in (HL)
                                ;    A           (HL)
                                ; 0000 0000 < 0000 3210
                                ; 0000 0000   3210 0000
                                ; A picks up the blank nibble


        LD      C,$FF           ; set a flag to indicate when a significant
                                ; digit has been encountered.

;;; @brief ; PF-DIGITS
;;;
;;; ; PF-DIGITS
;;; @jumps PF_INSERT, PF_TEST_2
;;; @fallthrough PF_INSERT
PF_DIGITS:
        RLD                     ; pick up leftmost nibble from (HL)
                                ;    A           (HL)
                                ; 0000 0000 < 7654 3210
                                ; 0000 7654   3210 0000


        JR      NZ,PF_INSERT        ; to PF-INSERT if non-zero value picked up.

        DEC     C               ; test
        INC     C               ; flag
        JR      NZ,PF_TEST_2        ; skip forward to PF-TEST-2 if flag still $FF
                                ; indicating this is a leading zero.

; but if the zero is a significant digit e.g. 10 then include in digit totals.
; the path for non-zero digits rejoins here.

;;; @brief ; PF-INSERT
;;;
;;; ; PF-INSERT
;;; @jumpedfrom PF_DIGITS
;;; @fallthrough PF_TEST_2
PF_INSERT:
        LD      (DE),A          ; insert digit at destination
        INC     DE              ; increase the destination pointer
        INC     (IY+$71)        ; increment MEM-5-1st  digit counter
        INC     (IY+$72)        ; increment MEM-5-2nd  leading digit counter
        LD      C,$00           ; set flag to zero indicating that any
                                ; subsequent zeros are significant and not
                                ; leading.

;;; @brief ; PF-TEST-2
;;;
;;; ; PF-TEST-2
;;; @jumps PF_ALL_9
;;; @jumpedfrom PF_DIGITS
;;; @fallthrough PF_ALL_9
PF_TEST_2:
        BIT     0,B             ; test if the nibble count is even
        JR      Z,PF_ALL_9         ; skip to PF-ALL-9 if so to deal with the
                                ; other nibble in the same byte

        INC     HL              ; point to next source byte if not

;;; @brief ; PF-ALL-9
;;;
;;; ; PF-ALL-9
;;; @jumps PF_MORE, PF_ROUND
;;; @jumpedfrom PF_TEST_2
PF_ALL_9:
        DJNZ    PF_DIGITS           ; decrement the nibble count, back to PF-DIGITS
                                ; if all nine not done.

; For 8-bit integers there will be at most 3 digits.
; For 16-bit integers there will be at most 5 digits.
; but for larger integers there could be nine leading digits.
; if nine digits complete then the last one is rounded up as the number will
; be printed using E-format notation

        LD      A,($5CAB)       ; fetch digit count from MEM-5-1st
        SUB     $09             ; subtract 9 - max possible
        JR      C,PF_MORE         ; forward if less to PF-MORE

        DEC     (IY+$71)        ; decrement digit counter MEM-5-1st to 8
        LD      A,$04           ; load A with the value 4.
        CP      (IY+$6F)        ; compare with MEM-4-4th - the ninth digit
        JR      PF_ROUND           ; forward to PF-ROUND
                                ; to consider rounding.

; ---------------------------------------

; now delete int x from calculator stack and fetch fractional part.

;;; @brief ; PF-MORE
;;;
;;; ; PF-MORE
;;; @jumpedfrom PF_ALL_9
PF_MORE:
        RST     28H             ;; FP-CALC        int x.
        DB          $02             ;;delete          .
        DB          $E2             ;;get-mem-2       x - int x = f.
        DB          $38             ;;end-calc        f.

;;; @brief ; PF-FRACTN
;;;
;;; ; PF-FRACTN
;;; @calls FETCH_TWO, SHIFT_FP
;;; @jumpedfrom PF_SMALL
;;; @fallthrough PF_FRN_LP
PF_FRACTN:
        EX      DE,HL           ;
        CALL    FETCH_TWO           ; routine FETCH-TWO
        EXX                     ;
        LD      A,$80           ;
        SUB     L               ;
        LD      L,$00           ;
        SET     7,D             ;
        EXX                     ;
        CALL    SHIFT_FP           ; routine SHIFT-FP

;;; @brief ; PF-FRN-LP
;;;
;;; ; PF-FRN-LP
;;; @jumps PF_FR_DGT, PF_ROUND
;;; @jumpedfrom PF_FR_EXX
PF_FRN_LP:
        LD      A,(IY+$71)      ; MEM-5-1st
        CP      $08             ;
        JR      C,PF_FR_DGT         ; to PF-FR-DGT

        EXX                     ;
        RL      D               ;
        EXX                     ;
        JR      PF_ROUND           ; to PF-ROUND

; ---

;;; @brief ; PF-FR-DGT
;;;
;;; ; PF-FR-DGT
;;; @jumpedfrom PF_FRN_LP
;;; @fallthrough PF_FR_EXX
PF_FR_DGT:
        LD      BC,$0200        ;

;;; @brief ; PF-FR-EXX
;;;
;;; ; PF-FR-EXX
;;; @calls CA_10_A_C
;;; @jumps PF_FRN_LP
PF_FR_EXX:
        LD      A,E             ;
        CALL    CA_10_A_C           ; routine CA-10*A+C
        LD      E,A             ;
        LD      A,D             ;
        CALL    CA_10_A_C           ; routine CA-10*A+C
        LD      D,A             ;
        PUSH    BC              ;
        EXX                     ;
        POP     BC              ;
        DJNZ    PF_FR_EXX           ; to PF-FR-EXX

        LD      HL,$5CA1        ; MEM-3
        LD      A,C             ;
        LD      C,(IY+$71)      ; MEM-5-1st
        ADD     HL,BC           ;
        LD      (HL),A          ;
        INC     (IY+$71)        ; MEM-5-1st
        JR      PF_FRN_LP           ; to PF-FRN-LP

; ----------------

; 1) with 9 digits but 8 in mem-5-1 and A holding 4, carry set if rounding up.
; e.g.
;      999999999 is printed as 1E+9
;      100000001 is printed as 1E+8
;      100000009 is printed as 1.0000001E+8

;;; @brief ; PF-ROUND
;;;
;;; ; PF-ROUND
;;; @jumpedfrom PF_ALL_9, PF_FRN_LP
;;; @fallthrough PF_RND_LP
PF_ROUND:
        PUSH    AF              ; save A and flags
        LD      HL,$5CA1        ; address MEM-3 start of digits
        LD      C,(IY+$71)      ; MEM-5-1st No. of digits to C
        LD      B,$00           ; prepare to add
        ADD     HL,BC           ; address last digit + 1
        LD      B,C             ; No. of digits to B counter
        POP     AF              ; restore A and carry flag from comparison.

;;; @brief ; PF-RND-LP
;;;
;;; ; PF-RND-LP
;;; @jumps PF_R_BACK, PF_COUNT
;;; @fallthrough PF_R_BACK
PF_RND_LP:
        DEC     HL              ; address digit at rounding position.
        LD      A,(HL)          ; fetch it
        ADC     A,$00           ; add carry from the comparison
        LD      (HL),A          ; put back result even if $0A.
        AND     A               ; test A
        JR      Z,PF_R_BACK         ; skip to PF-R-BACK if ZERO?

        CP      $0A             ; compare to 'ten' - overflow
        CCF                     ; complement carry flag so that set if ten.
        JR      NC,PF_COUNT        ; forward to PF-COUNT with 1 - 9.

;;; @brief ; PF-R-BACK
;;;
;;; ; PF-R-BACK
;;; @jumpedfrom PF_RND_LP
;;; @fallthrough PF_COUNT
PF_R_BACK:
        DJNZ    PF_RND_LP           ; loop back to PF-RND-LP

; if B counts down to zero then we've rounded right back as in 999999995.
; and the first 8 locations all hold $0A.


        LD      (HL),$01        ; load first location with digit 1.
        INC     B               ; make B hold 1 also.
                                ; could save an instruction byte here.
        INC     (IY+$72)        ; make MEM-5-2nd hold 1.
                                ; and proceed to initialize total digits to 1.

;;; @brief ; PF-COUNT
;;;
;;; ; PF-COUNT
;;; @jumps PF_NOT_E, PF_E_FRMT
;;; @jumpedfrom PF_RND_LP
;;; @fallthrough PF_NOT_E
PF_COUNT:
        LD      (IY+$71),B      ; MEM-5-1st

; now balance the calculator stack by deleting  it

        RST     28H             ;; FP-CALC
        DB          $02             ;;delete
        DB          $38             ;;end-calc

; note if used from str$ then other values may be on the calculator stack.
; we can also restore the next literal pointer from its position on the
; machine stack.

        EXX                     ;
        POP     HL              ; restore next literal pointer.
        EXX                     ;

        LD      BC,($5CAB)      ; set C to MEM-5-1st digit counter.
                                ; set B to MEM-5-2nd leading digit counter.
        LD      HL,$5CA1        ; set HL to start of digits at MEM-3-1
        LD      A,B             ;
        CP      $09             ;
        JR      C,PF_NOT_E         ; to PF-NOT-E

        CP      $FC             ;
        JR      C,PF_E_FRMT         ; to PF-E-FRMT

;;; @brief ; PF-NOT-E
;;;
;;; ; PF-NOT-E
;;; @calls OUT_CODE
;;; @jumpedfrom PF_COUNT
;;; @fallthrough PF_E_SBRN
PF_NOT_E:
        AND     A               ; test for zero leading digits as in .123

        CALL    Z,OUT_CODE         ; routine OUT-CODE prints a zero e.g. 0.123

;;; @brief ; PF-E-SBRN
;;;
;;; ; PF-E-SBRN
;;; @jumps PF_OUT_LP, PF_DC_OUT
;;; @calledby PF_E_FRMT
PF_E_SBRN:
        XOR     A               ;
        SUB     B               ;
        JP      M,PF_OUT_LP         ; skip forward to PF-OUT-LP if originally +ve

        LD      B,A             ; else negative count now +ve
        JR      PF_DC_OUT           ; forward to PF-DC-OUT       ->

; ---

;;; @brief ; PF-OUT-LP
;;;
;;; ; PF-OUT-LP
;;; @jumps PF_OUT_DT
;;; @jumpedfrom PF_E_SBRN, PF_DEC_0S
;;; @fallthrough PF_OUT_DT
PF_OUT_LP:
        LD      A,C             ; fetch total digit count
        AND     A               ; test for zero
        JR      Z,PF_OUT_DT         ; forward to PF-OUT-DT if so

        LD      A,(HL)          ; fetch digit
        INC     HL              ; address next digit
        DEC     C               ; decrease total digit counter

;;; @brief ; PF-OUT-DT
;;;
;;; ; PF-OUT-DT
;;; @calls OUT_CODE
;;; @jumpedfrom PF_OUT_LP
;;; @fallthrough PF_DC_OUT
PF_OUT_DT:
        CALL    OUT_CODE           ; routine OUT-CODE outputs it.
        DJNZ    PF_OUT_LP           ; loop back to PF-OUT-LP until B leading
                                ; digits output.

;;; @brief ; PF-DC-OUT
;;;
;;; ; PF-DC-OUT
;;; @jumpedfrom PF_E_SBRN
;;; @fallthrough PF_DEC_0S
PF_DC_OUT:
        LD      A,C             ; fetch total digits and
        AND     A               ; test if also zero
        RET     Z               ; return if so              -->

;

        INC     B               ; increment B
        LD      A,$2E           ; prepare the character '.'

;;; @brief ; PF-DEC-0S
;;;
;;; ; PF-DEC-0S
;;; @jumps PF_OUT_LP
PF_DEC_0S:
        RST     10H             ; PRINT-A outputs the character '.' or '0'

        LD      A,$30           ; prepare the character '0'
                                ; (for cases like .000012345678)
        DJNZ    PF_DEC_0S           ; loop back to PF-DEC-0S for B times.

        LD      B,C             ; load B with now trailing digit counter.
        JR      PF_OUT_LP           ; back to PF-OUT-LP

; ---------------------------------

; the branch was here for E-format printing e.g. 123456789 => 1.2345679e+8

;;; @brief ; PF-E-FRMT
;;;
;;; ; PF-E-FRMT
;;; @calls PF_E_SBRN
;;; @jumps PF_E_POS, PF_E_SIGN
;;; @jumpedfrom PF_COUNT
PF_E_FRMT:
        LD      D,B             ; counter to D
        DEC     D               ; decrement
        LD      B,$01           ; load B with 1.

        CALL    PF_E_SBRN           ; routine PF-E-SBRN above

        LD      A,$5D                   ; A = $5D
        RST     10H             ; PRINT-A

        LD      C,D             ; exponent to C
        LD      A,C             ; and to A
        AND     A               ; test exponent
        JP      P,PF_E_POS         ; to PF-E-POS if positive

        NEG                     ; negate
        LD      C,A             ; positive exponent to C
        LD      A,$2D           ; prepare character '-'
        JR      PF_E_SIGN           ; skip to PF-E-SIGN

; ---

;;; @brief ; PF-E-POS
;;;
;;; ; PF-E-POS
;;; @jumpedfrom PF_E_FRMT
;;; @fallthrough PF_E_SIGN
PF_E_POS:
        LD      A,$2B           ; prepare character '+'

;;; @brief ; PF-E-SIGN
;;;
;;; ; PF-E-SIGN
;;; @jumps OUT_NUM_1
;;; @jumpedfrom PF_E_FRMT
PF_E_SIGN:
        RST     10H             ; PRINT-A outputs the sign

        LD      B,$00           ; make the high byte zero.
        JP      OUT_NUM_1           ; exit via OUT-NUM-1 to print exponent in BC

;;; @brief Handle printing floating point
;;;
;;; This subroutine is called twice from above when printing floating-point
;;; numbers. It returns 10*A +C in registers C and A
;;;
;;; ; CA-10*A+C
;;; @calledby PF_FR_EXX
CA_10_A_C:
        PUSH    DE              ; preserve DE.
        LD      L,A             ; transfer A to L
        LD      H,$00           ; zero high byte.
        LD      E,L             ; copy HL
        LD      D,H             ; to DE.
        ADD     HL,HL           ; double (*2)
        ADD     HL,HL           ; double (*4)
        ADD     HL,DE           ; add DE (*5)
        ADD     HL,HL           ; double (*10)
        LD      E,C             ; copy C to E    (D is 0)
        ADD     HL,DE           ; and add to give required result.
        LD      C,H             ; transfer to
        LD      A,L             ; destination registers.
        POP     DE              ; restore DE
        RET                     ; return with result.

;;; @brief Prepare to add
;;;
;;; This routine is called twice by addition to prepare the two numbers. The
;;; exponent is picked up in A and the location made zero. Then the sign bit
;;; is tested before being set to the implied state. Negative numbers are twos
;;; complemented.
;;;
;;; ; PREP-ADD
;;; @calledby FULL_ADDN
;;; @fallthrough NEG_BYTE
PREP_ADD:
        LD      A,(HL)          ; pick up exponent
        LD      (HL),$00        ; make location zero
        AND     A               ; test if number is zero
        RET     Z               ; return if so

        INC     HL              ; address mantissa
        BIT     7,(HL)          ; test the sign bit
        SET     7,(HL)          ; set it to implied state
        DEC     HL              ; point to exponent
        RET     Z               ; return if positive number.

        PUSH    BC              ; preserve BC
        LD      BC,$0005        ; length of number
        ADD     HL,BC           ; point HL past end
        LD      B,C             ; set B to 5 counter
        LD      C,A             ; store exponent in C
        SCF                     ; set carry flag

;;; @brief ; NEG-BYTE
;;;
;;; ; NEG-BYTE
NEG_BYTE:
        DEC     HL              ; work from LSB to MSB
        LD      A,(HL)          ; fetch byte
        CPL                     ; complement
        ADC     A,$00           ; add in initial carry or from prev operation
        LD      (HL),A          ; put back
        DJNZ    NEG_BYTE           ; loop to NEG-BYTE till all 5 done

        LD      A,C             ; stored exponent to A
        POP     BC              ; restore original BC
        RET                     ; return

;;; @brief Fetch two numbers
;;;
;;; This routine is called twice when printing floating point numbers and also
;;; to fetch two numbers by the addition, multiply and division routines.
;;; HL addresses the first number, DE addresses the second number.
;;; For arithmetic only, A holds the sign of the result which is stored in
;;; the second location.
;;;
;;; ; FETCH-TWO
;;; @calledby PF_MEDIUM, PF_FRACTN, SHIFT_LEN, MULT_LONG, DIVISION
FETCH_TWO:
        PUSH    HL              ; save pointer to first number, result if math.
        PUSH    AF              ; save result sign.

        LD      C,(HL)          ;
        INC     HL              ;

        LD      B,(HL)          ;
        LD      (HL),A          ; store the sign at correct location in
                                ; destination 5 bytes for arithmetic only.
        INC     HL              ;

        LD      A,C             ;
        LD      C,(HL)          ;
        PUSH    BC              ;
        INC     HL              ;
        LD      C,(HL)          ;
        INC     HL              ;
        LD      B,(HL)          ;
        EX      DE,HL           ;
        LD      D,A             ;
        LD      E,(HL)          ;
        PUSH    DE              ;
        INC     HL              ;
        LD      D,(HL)          ;
        INC     HL              ;
        LD      E,(HL)          ;
        PUSH    DE              ;
        EXX                     ;
        POP     DE              ;
        POP     HL              ;
        POP     BC              ;
        EXX                     ;
        INC     HL              ;
        LD      D,(HL)          ;
        INC     HL              ;
        LD      E,(HL)          ;

        POP     AF              ; restore possible result sign.
        POP     HL              ; and pointer to possible result.
        RET                     ; return.

;;; @brief Shift floating point number right
;;;
;;; ; SHIFT-FP
;;; @jumps ADDEND_0
;;; @calledby PF_FRACTN, SHIFT_LEN
;;; @fallthrough ONE_SHIFT
SHIFT_FP:
        AND     A               ;
        RET     Z               ;

        CP      $21             ;
        JR      NC,ADDEND_0        ; to ADDEND-0

        PUSH    BC              ;
        LD      B,A             ;

;;; @brief ; ONE-SHIFT
;;;
;;; ; ONE-SHIFT
;;; @calls ADD_BACK
;;; @fallthrough ADDEND_0
ONE_SHIFT:
        EXX                     ;
        SRA     L               ;
        RR      D               ;
        RR      E               ;
        EXX                     ;
        RR      D               ;
        RR      E               ;
        DJNZ    ONE_SHIFT           ; to ONE-SHIFT

        POP     BC              ;
        RET     NC              ;

        CALL    ADD_BACK           ; routine ADD-BACK
        RET     NZ              ;

;;; @brief ; ADDEND-0
;;;
;;; ; ADDEND-0
;;; @jumpedfrom SHIFT_FP
;;; @fallthrough ZEROS_4_5
ADDEND_0:
        EXX                     ;
        XOR     A               ;

;;; @brief ; ZEROS-4/5
;;;
;;; ; ZEROS-4/5
;;; @calledby SKIP_ZERO
ZEROS_4_5:
        LD      L,$00           ;
        LD      D,A             ;
        LD      E,L             ;
        EXX                     ;
        LD      DE,$0000        ;
        RET                     ;

;;; @brief Add back any carry
;;;
;;; ; ADD-BACK
;;; @jumps ALL_ADDED
;;; @calledby ONE_SHIFT, NORML_NOW
;;; @fallthrough ALL_ADDED
ADD_BACK:
        INC     E               ;
        RET     NZ              ;

        INC      D              ;
        RET     NZ              ;

        EXX                     ;
        INC     E               ;
        JR      NZ,ALL_ADDED        ; to ALL-ADDED

        INC     D               ;

;;; @brief ; ALL-ADDED
;;;
;;; ; ALL-ADDED
;;; @jumpedfrom ADD_BACK
ALL_ADDED:
        EXX                     ;
        RET                     ;

;;; @brief Handle subtraction (03)
;;;
;;; Subtraction is done by switching the sign byte/bit of the second number
;;; which may be integer of floating point and continuing into addition.
;;;
;;; ; subtract
;;; @calls NEGATE
;;; @calledby STR_NO
;;; @fallthrough ADDITION
SUBTRACT:
        EX      DE,HL           ; address second number with HL

        CALL    NEGATE           ; routine NEGATE switches sign

        EX      DE,HL           ; address first number again
                                ; and continue.

;;; @brief Handle addition (0F)
;;;
;;; HL points to first number, DE to second.
;;; If they are both integers, then go for the easy route.
;;;
;;; ; addition
;;; @jumps FULL_ADDN, ADDN_OFLW
ADDITION:
        LD      A,(DE)          ; fetch first byte of second
        OR      (HL)            ; combine with first byte of first
        JR      NZ,FULL_ADDN        ; forward to FULL-ADDN if at least one was
                                ; in floating point form.

; continue if both were small integers.

        PUSH    DE              ; save pointer to lowest number for result.

        INC     HL              ; address sign byte and
        PUSH    HL              ; push the pointer.

        INC     HL              ; address low byte
        LD      E,(HL)          ; to E
        INC     HL              ; address high byte
        LD      D,(HL)          ; to D
        INC     HL              ; address unused byte

        INC     HL              ; address known zero indicator of 1st number
        INC     HL              ; address sign byte

        LD      A,(HL)          ; sign to A, $00 or $FF

        INC     HL              ; address low byte
        LD      C,(HL)          ; to C
        INC     HL              ; address high byte
        LD      B,(HL)          ; to B

        POP     HL              ; pop result sign pointer
        EX      DE,HL           ; integer to HL

        ADD     HL,BC           ; add to the other one in BC
                                ; setting carry if overflow.

        EX      DE,HL           ; save result in DE bringing back sign pointer

        ADC     A,(HL)          ; if pos/pos A=01 with overflow else 00
                                ; if neg/neg A=FF with overflow else FE
                                ; if mixture A=00 with overflow else FF

        RRCA                    ; bit 0 to (C)

        ADC     A,$00           ; both acceptable signs now zero

        JR      NZ,ADDN_OFLW        ; forward to ADDN-OFLW if not

        SBC     A,A             ; restore a negative result sign

        LD      (HL),A          ;
        INC     HL              ;
        LD      (HL),E          ;
        INC     HL              ;
        LD      (HL),D          ;
        DEC     HL              ;
        DEC     HL              ;
        DEC     HL              ;

        POP     DE              ; STKEND
        RET                     ;

; ---

;;; @brief ; ADDN-OFLW
;;;
;;; ; ADDN-OFLW
;;; @jumpedfrom ADDITION
;;; @fallthrough FULL_ADDN
ADDN_OFLW:
        DEC     HL              ;
        POP     DE              ;

;;; @brief ; FULL-ADDN
;;;
;;; ; FULL-ADDN
;;; @calls RE_ST_TWO, PREP_ADD
;;; @jumps SHIFT_LEN
;;; @jumpedfrom ADDITION
;;; @fallthrough SHIFT_LEN
FULL_ADDN:
        CALL    RE_ST_TWO           ; routine RE-ST-TWO
        EXX                     ;
        PUSH    HL              ;
        EXX                     ;
        PUSH    DE              ;
        PUSH    HL              ;
        CALL    PREP_ADD           ; routine PREP-ADD
        LD      B,A             ;
        EX      DE,HL           ;
        CALL    PREP_ADD           ; routine PREP-ADD
        LD       C,A            ;
        CP      B               ;
        JR      NC,SHIFT_LEN        ; to SHIFT-LEN

        LD      A,B             ;
        LD      B,C             ;
        EX      DE,HL           ;

;;; @brief ; SHIFT-LEN
;;;
;;; ; SHIFT-LEN
;;; @calls FETCH_TWO, SHIFT_FP
;;; @jumps TEST_NEG, ADD_REP_6
;;; @jumpedfrom FULL_ADDN
;;; @fallthrough TEST_NEG
SHIFT_LEN:
        PUSH    AF              ;
        SUB     B               ;
        CALL    FETCH_TWO           ; routine FETCH-TWO
        CALL    SHIFT_FP           ; routine SHIFT-FP
        POP     AF              ;
        POP     HL              ;
        LD      (HL),A          ;
        PUSH    HL              ;
        LD      L,B             ;
        LD      H,C             ;
        ADD     HL,DE           ;
        EXX                     ;
        EX      DE,HL           ;
        ADC     HL,BC           ;
        EX      DE,HL           ;
        LD      A,H             ;
        ADC     A,L             ;
        LD      L,A             ;
        RRA                     ;
        XOR     L               ;
        EXX                     ;
        EX      DE,HL           ;
        POP     HL              ;
        RRA                     ;
        JR      NC,TEST_NEG        ; to TEST-NEG

        LD      A,$01           ;
        CALL    SHIFT_FP           ; routine SHIFT-FP
        INC     (HL)            ;
        JR      Z,ADD_REP_6         ; to ADD-REP-6

;;; @brief ; TEST-NEG
;;;
;;; ; TEST-NEG
;;; @jumps GO_NC_MLT, END_COMPL
;;; @jumpedfrom SHIFT_LEN
;;; @fallthrough ADD_REP_6
TEST_NEG:
        EXX                     ;
        LD      A,L             ;
        AND     $80             ;
        EXX                     ;
        INC     HL              ;
        LD      (HL),A          ;
        DEC     HL              ;
        JR      Z,GO_NC_MLT         ; to GO-NC-MLT

        LD      A,E             ;
        NEG                     ; Negate
        CCF                     ; Complement Carry Flag
        LD      E,A             ;
        LD      A,D             ;
        CPL                     ;
        ADC     A,$00           ;
        LD      D,A             ;
        EXX                     ;
        LD      A,E             ;
        CPL                     ;
        ADC     A,$00           ;
        LD      E,A             ;
        LD      A,D             ;
        CPL                     ;
        ADC     A,$00           ;
        JR      NC,END_COMPL        ; to END-COMPL

        RRA                     ;
        EXX                     ;
        INC     (HL)            ;

;;; @brief ; ADD-REP-6
;;;
;;; ; ADD-REP-6
;;; @jumps REPORT_6
;;; @jumpedfrom SHIFT_LEN
;;; @fallthrough END_COMPL
ADD_REP_6:
        JP      Z,REPORT_6         ; to REPORT-6

        EXX                     ;

;;; @brief ; END-COMPL
;;;
;;; ; END-COMPL
;;; @jumpedfrom TEST_NEG
;;; @fallthrough GO_NC_MLT
END_COMPL:
        LD      D,A             ;
        EXX                     ;

;;; @brief ; GO-NC-MLT
;;;
;;; ; GO-NC-MLT
;;; @jumps TEST_NORM
;;; @jumpedfrom TEST_NEG
GO_NC_MLT:
        XOR     A               ;
        JP      TEST_NORM           ; to TEST-NORM

;;; @brief Used in 16 bit multiplication
;;;
;;; This routine is used, in the first instance, by the multiply calculator
;;; literal to perform an integer multiplication in preference to
;;; 32-bit multiplication to which it will resort if this overflows.
;;;
;;; It is also used by STK-VAR to calculate array subscripts and by DIM to
;;; calculate the space required for multi-dimensional arrays.
;;;
;;; ; HL-HL*DE
;;; @calledby GET_HL_DE, MULTIPLY
;;; @fallthrough HL_LOOP
HL_HL_DE:
        PUSH    BC              ; preserve BC throughout
        LD      B,$10           ; set B to 16
        LD      A,H             ; save H in A high byte
        LD      C,L             ; save L in C low byte
        LD      HL,$0000        ; initialize result to zero

; now enter a loop.

;;; @brief ; HL-LOOP
;;;
;;; ; HL-LOOP
;;; @jumps HL_END, HL_AGAIN
;;; @fallthrough HL_AGAIN
HL_LOOP:
        ADD     HL,HL           ; double result
        JR      C,HL_END         ; to HL-END if overflow

        RL      C               ; shift AC left into carry
        RLA                     ;
        JR      NC,HL_AGAIN        ; to HL-AGAIN to skip addition if no carry

        ADD     HL,DE           ; add in DE
        JR      C,HL_END         ; to HL-END if overflow

;;; @brief ; HL-AGAIN
;;;
;;; ; HL-AGAIN
;;; @jumpedfrom HL_LOOP
;;; @fallthrough HL_END
HL_AGAIN:
        DJNZ    HL_LOOP           ; back to HL-LOOP for all 16 bits

;;; @brief ; HL-END
;;;
;;; ; HL-END
;;; @jumpedfrom HL_LOOP
HL_END:
        POP     BC              ; restore preserved BC
        RET                     ; return with carry reset if successful
                                ; and result in HL.

;;; @brief THE 'PREPARE TO MULTIPLY OR DIVIDE' SUBROUTINE
;;;
;;;   This routine is called in succession from multiply and divide to prepare
;;;   two mantissas by setting the leftmost bit that is used for the sign.
;;;   On the first call A holds zero and picks up the sign bit. On the second
;;;   call the two bits are XORed to form the result sign - minus * minus giving
;;;   plus etc. If either number is zero then this is flagged.
;;;   HL addresses the exponent.
;;;
;;; ; PREP-M/D
;;; @calls TEST_ZERO
;;; @calledby MULT_LONG, DIVISION
PREP_M_D:
        CALL    TEST_ZERO           ; routine TEST-ZERO  preserves accumulator.
        RET     C               ; return carry set if zero

        INC     HL              ; address first byte of mantissa
        XOR     (HL)            ; pick up the first or xor with first.
        SET     7,(HL)          ; now set to give true 32-bit mantissa
        DEC     HL              ; point to exponent
        RET                     ; return with carry reset

;;; @brief THE 'MULTIPLY' ROUTINE
;;;
;;; (offset: $04 'multiply')
;;;
;;;
;;;   "He said go forth and something about mathematics, I wasn't really
;;; @verbatim
;;;    listening" - overheard conversation between two unicorns.
;;;    [ The Odd Streak ].
;;; @endverbatim
;;;
;;; ; multiply
;;; @calls INT_FETCH, HL_HL_DE
;;; @jumps MULT_LONG, MULT_OFLW, MULT_RSLT
;;; @fallthrough MULT_RSLT
MULTIPLY:
        LD      A,(DE)          ;
        OR      (HL)            ;
        JR      NZ,MULT_LONG        ; to MULT-LONG

        PUSH    DE              ;
        PUSH    HL              ;
        PUSH    DE              ;
        CALL    INT_FETCH           ; routine INT-FETCH
        EX      DE,HL           ;
        EX      (SP),HL         ;
        LD      B,C             ;
        CALL    INT_FETCH           ; routine INT-FETCH
        LD      A,B             ;
        XOR     C               ;
        LD      C,A             ;
        POP     HL              ;
        CALL    HL_HL_DE           ; routine HL-HL*DE
        EX      DE,HL           ;
        POP     HL              ;
        JR      C,MULT_OFLW         ; to MULT-OFLW

        LD      A,D             ;
        OR      E               ;
        JR      NZ,MULT_RSLT        ; to MULT-RSLT

        LD      C,A             ;

;;; @brief ; MULT-RSLT
;;;
;;; ; MULT-RSLT
;;; @calls INT_STORE
;;; @jumpedfrom MULTIPLY
MULT_RSLT:
        CALL    INT_STORE           ; routine INT-STORE
        POP      DE             ;
        RET                     ;

; ---

;;; @brief ; MULT-OFLW
;;;
;;; ; MULT-OFLW
;;; @jumpedfrom MULTIPLY
;;; @fallthrough MULT_LONG
MULT_OFLW:
        POP     DE              ;

;;; @brief ; MULT-LONG
;;;
;;; ; MULT-LONG
;;; @calls RE_ST_TWO, PREP_M_D, FETCH_TWO
;;; @jumps ZERO_RSLT, STRT_MLT
;;; @jumpedfrom MULTIPLY
MULT_LONG:
        CALL    RE_ST_TWO           ; routine RE-ST-TWO
        XOR     A               ;
        CALL    PREP_M_D           ; routine PREP-M/D
        RET     C               ;

        EXX                     ;
        PUSH    HL              ;
        EXX                     ;
        PUSH    DE              ;
        EX      DE,HL           ;
        CALL    PREP_M_D           ; routine PREP-M/D
        EX      DE,HL           ;
        JR      C,ZERO_RSLT         ; to ZERO-RSLT

        PUSH    HL              ;
        CALL    FETCH_TWO           ; routine FETCH-TWO
        LD      A,B             ;
        AND     A               ;
        SBC     HL,HL           ;
        EXX                     ;
        PUSH    HL              ;
        SBC     HL,HL           ;
        EXX                     ;
        LD      B,$21           ;
        JR      STRT_MLT           ; to STRT-MLT

; ---

;;; @brief ; MLT-LOOP
;;;
;;; ; MLT-LOOP
;;; @jumps NO_ADD
;;; @fallthrough NO_ADD
MLT_LOOP:
        JR      NC,NO_ADD        ; to NO-ADD

        ADD     HL,DE           ;
        EXX                     ;
        ADC     HL,DE           ;
        EXX                     ;

;;; @brief ; NO-ADD
;;;
;;; ; NO-ADD
;;; @jumpedfrom MLT_LOOP
;;; @fallthrough STRT_MLT
NO_ADD:
        EXX                     ;
        RR      H               ;
        RR      L               ;
        EXX                     ;
        RR      H               ;
        RR      L               ;

;;; @brief ; STRT-MLT
;;;
;;; ; STRT-MLT
;;; @jumps MAKE_EXPT
;;; @jumpedfrom MULT_LONG
;;; @fallthrough MAKE_EXPT
STRT_MLT:
        EXX                     ;
        RR      B               ;
        RR      C               ;
        EXX                     ;
        RR      C               ;
        RRA                     ;
        DJNZ    MLT_LOOP           ; to MLT-LOOP

        EX      DE,HL           ;
        EXX                     ;
        EX      DE,HL           ;
        EXX                     ;
        POP     BC              ;
        POP     HL              ;
        LD      A,B             ;
        ADD     A,C             ;
        JR      NZ,MAKE_EXPT        ; to MAKE-EXPT

        AND     A               ;

;;; @brief ; MAKE-EXPT
;;;
;;; ; MAKE-EXPT
;;; @jumpedfrom STRT_MLT
;;; @fallthrough DIVN_EXPT
MAKE_EXPT:
        DEC     A               ;
        CCF                     ; Complement Carry Flag

;;; @brief ; DIVN-EXPT
;;;
;;; ; DIVN-EXPT
;;; @jumps OFLW1_CLR, REPORT_6
;;; @jumpedfrom COUNT_ONE
;;; @fallthrough OFLW1_CLR
DIVN_EXPT:
        RLA                     ;
        CCF                     ; Complement Carry Flag
        RRA                     ;
        JP      P,OFLW1_CLR         ; to OFLW1-CLR

        JR      NC,REPORT_6        ; to REPORT-6

        AND     A               ;

;;; @brief ; OFLW1-CLR
;;;
;;; ; OFLW1-CLR
;;; @jumps OFLW2_CLR, REPORT_6
;;; @jumpedfrom DIVN_EXPT
;;; @fallthrough OFLW2_CLR
OFLW1_CLR:
        INC     A               ;
        JR      NZ,OFLW2_CLR        ; to OFLW2-CLR

        JR      C,OFLW2_CLR         ; to OFLW2-CLR

        EXX                     ;
        BIT     7,D             ;
        EXX                     ;
        JR      NZ,REPORT_6        ; to REPORT-6

;;; @brief ; OFLW2-CLR
;;;
;;; ; OFLW2-CLR
;;; @jumpedfrom OFLW1_CLR
;;; @fallthrough TEST_NORM
OFLW2_CLR:
        LD      (HL),A          ;
        EXX                     ;
        LD      A,B             ;
        EXX                     ;

;;; @brief ; TEST-NORM
;;;
;;; ; TEST-NORM
;;; @jumps NORMALISE
;;; @jumpedfrom GO_NC_MLT
;;; @fallthrough NEAR_ZERO
TEST_NORM:
        JR      NC,NORMALISE        ; to NORMALISE

        LD      A,(HL)          ;
        AND     A               ;

;;; @brief ; NEAR-ZERO
;;;
;;; ; NEAR-ZERO
;;; @jumps SKIP_ZERO
;;; @jumpedfrom SHIFT_ONE
;;; @fallthrough ZERO_RSLT
NEAR_ZERO:
        LD      A,$80           ;
        JR      Z,SKIP_ZERO         ; to SKIP-ZERO

;;; @brief ; ZERO-RSLT
;;;
;;; ; ZERO-RSLT
;;; @jumpedfrom MULT_LONG, SHIFT_ONE
;;; @fallthrough SKIP_ZERO
ZERO_RSLT:
        XOR     A               ;

;;; @brief ; SKIP-ZERO
;;;
;;; ; SKIP-ZERO
;;; @calls ZEROS_4_5
;;; @jumps OFLOW_CLR
;;; @jumpedfrom NEAR_ZERO
SKIP_ZERO:
        EXX                     ;
        AND     D               ;
        CALL    ZEROS_4_5           ; routine ZEROS-4/5
        RLCA                    ;
        LD      (HL),A          ;
        JR      C,OFLOW_CLR         ; to OFLOW-CLR

        INC     HL              ;
        LD      (HL),A          ;
        DEC     HL              ;
        JR      OFLOW_CLR           ; to OFLOW-CLR

; ---

;;; @brief ; NORMALISE
;;;
;;; ; NORMALISE
;;; @jumpedfrom TEST_NORM
;;; @fallthrough SHIFT_ONE
NORMALISE:
        LD      B,$20           ;

;;; @brief ; SHIFT-ONE
;;;
;;; ; SHIFT-ONE
;;; @jumps NORML_NOW, NEAR_ZERO, ZERO_RSLT
SHIFT_ONE:
        EXX                     ;
        BIT     7,D             ;
        EXX                     ;
        JR      NZ,NORML_NOW        ; to NORML-NOW

        RLCA                    ;
        RL      E               ;
        RL      D               ;
        EXX                     ;
        RL      E               ;
        RL      D               ;
        EXX                     ;
        DEC     (HL)            ;
        JR      Z,NEAR_ZERO         ; to NEAR-ZERO

        DJNZ    SHIFT_ONE           ; to SHIFT-ONE

        JR      ZERO_RSLT           ; to ZERO-RSLT

; ---

;;; @brief ; NORML-NOW
;;;
;;; ; NORML-NOW
;;; @calls ADD_BACK
;;; @jumps OFLOW_CLR, REPORT_6
;;; @jumpedfrom SHIFT_ONE
;;; @fallthrough OFLOW_CLR
NORML_NOW:
        RLA                     ;
        JR      NC,OFLOW_CLR        ; to OFLOW-CLR

        CALL    ADD_BACK           ; routine ADD-BACK
        JR      NZ,OFLOW_CLR        ; to OFLOW-CLR

        EXX                     ;
        LD       D,$80          ;
        EXX                     ;
        INC     (HL)            ;
        JR      Z,REPORT_6         ; to REPORT-6

;;; @brief ; OFLOW-CLR
;;;
;;; ; OFLOW-CLR
;;; @jumpedfrom SKIP_ZERO, NORML_NOW
OFLOW_CLR:
        PUSH    HL              ;
        INC     HL              ;
        EXX                     ;
        PUSH    DE              ;
        EXX                     ;
        POP     BC              ;
        LD      A,B             ;
        RLA                     ;
        RL      (HL)            ;
        RRA                     ;
        LD      (HL),A          ;
        INC     HL              ;
        LD      (HL),C          ;
        INC     HL              ;
        LD      (HL),D          ;
        INC     HL              ;
        LD      (HL),E          ;
        POP     HL              ;
        POP     DE              ;
        EXX                     ;
        POP     HL              ;
        EXX                     ;
        RET                     ;

; ---

;;; @brief ; REPORT-6
;;;
;;; ; REPORT-6
;;; @jumpedfrom BIN_DIGIT, ST_E_PART, ADD_REP_6, DIVN_EXPT, OFLW1_CLR, NORML_NOW, DIVISION
REPORT_6:
        RST     08H             ; ERROR-1
        DB          $05             ; Error Report: Number too big

;;; @brief THE 'DIVISION' ROUTINE
;;;
;;; (offset: $05 'division')
;;;
;;;   "He who can properly define and divide is to be considered a god"
;;;   - Plato,  429 - 347 B.C.
;;;
;;; ; division
;;; @calls RE_ST_TWO, PREP_M_D, FETCH_TWO
;;; @jumps REPORT_6, DIV_START
DIVISION:
        CALL    RE_ST_TWO           ; routine RE-ST-TWO
        EX      DE,HL           ;
        XOR     A               ;
        CALL    PREP_M_D           ; routine PREP-M/D
        JR      C,REPORT_6         ; to REPORT-6

        EX      DE,HL           ;
        CALL    PREP_M_D           ; routine PREP-M/D
        RET     C               ;

        EXX                     ;
        PUSH    HL              ;
        EXX                     ;
        PUSH    DE              ;
        PUSH    HL              ;
        CALL    FETCH_TWO           ; routine FETCH-TWO
        EXX                     ;
        PUSH    HL              ;
        LD      H,B             ;
        LD      L,C             ;
        EXX                     ;
        LD      H,C             ;
        LD      L,B             ;
        XOR     A               ;
        LD      B,$DF           ;
        JR      DIV_START           ; to DIV-START

; ---

;;; @brief ; DIV-LOOP
;;;
;;; ; DIV-LOOP
;;; @jumpedfrom COUNT_ONE
;;; @fallthrough DIV_34TH
DIV_LOOP:
        RLA                     ;
        RL      C               ;
        EXX                     ;
        RL      C               ;
        RL      B               ;
        EXX                     ;

;;; @brief ; div-34th
;;;
;;; ; div-34th
;;; @jumps SUBN_ONLY
;;; @fallthrough DIV_START
DIV_34TH:
        ADD     HL,HL           ;
        EXX                     ;
        ADC     HL,HL           ;
        EXX                     ;
        JR      C,SUBN_ONLY         ; to SUBN-ONLY

;;; @brief ; DIV-START
;;;
;;; ; DIV-START
;;; @jumps NO_RSTORE, COUNT_ONE
;;; @jumpedfrom DIVISION, COUNT_ONE
DIV_START:
        SBC     HL,DE           ;
        EXX                     ;
        SBC     HL,DE           ;
        EXX                     ;
        JR      NC,NO_RSTORE        ; to NO-RSTORE

        ADD     HL,DE           ;
        EXX                     ;
        ADC     HL,DE           ;
        EXX                     ;
        AND     A               ;
        JR      COUNT_ONE           ; to COUNT-ONE

; ---

;;; @brief ; SUBN-ONLY
;;;
;;; ; SUBN-ONLY
;;; @jumpedfrom DIV_34TH
;;; @fallthrough NO_RSTORE
SUBN_ONLY:
        AND     A               ;
        SBC     HL,DE           ;
        EXX                     ;
        SBC     HL,DE           ;
        EXX                     ;

;;; @brief ; NO-RSTORE
;;;
;;; ; NO-RSTORE
;;; @jumpedfrom DIV_START
;;; @fallthrough COUNT_ONE
NO_RSTORE:
        SCF                     ; Set Carry Flag

;;; @brief ; COUNT-ONE
;;;
;;; ; COUNT-ONE
;;; @jumps DIV_LOOP, DIV_START, DIVN_EXPT
;;; @jumpedfrom DIV_START
COUNT_ONE:
        INC     B               ;
        JP      M,DIV_LOOP         ; to DIV-LOOP

        PUSH    AF              ;
        JR      Z,DIV_START         ; to DIV-START

;
;
;
;

        LD      E,A             ;
        LD      D,C             ;
        EXX                     ;
        LD      E,C             ;
        LD      D,B             ;
        POP     AF              ;
        RR      B               ;
        POP     AF              ;
        RR      B               ;
        EXX                     ;
        POP     BC              ;
        POP     HL              ;
        LD      A,B             ;
        SUB     C               ;
        JP      DIVN_EXPT           ; jump back to DIVN-EXPT

;;; @brief Integer truncation towards zero ($3A)
;;;
;;; ; truncate
;;; @jumps T_GR_ZERO, NIL_BYTES
TRUNCATE:
        LD      A,(HL)          ;
        AND     A               ;
        RET     Z               ;

        CP      $81             ;
        JR      NC,T_GR_ZERO        ; to T-GR-ZERO

        LD      (HL),$00        ;
        LD      A,$20           ;
        JR      NIL_BYTES           ; to NIL-BYTES

; ---

;;; @brief ; T-GR-ZERO
;;;
;;; ; T-GR-ZERO
;;; @jumps T_SMALL, T_FIRST
;;; @jumpedfrom TRUNCATE
;;; @fallthrough T_FIRST
T_GR_ZERO:
        CP      $91             ;
        JR      NZ,T_SMALL        ; to T-SMALL

        INC     HL              ;
        INC     HL              ;
        INC     HL              ;
        LD      A,$80           ;
        AND     (HL)            ;
        DEC     HL              ;
        OR      (HL)            ;
        DEC     HL              ;
        JR      NZ,T_FIRST        ; to T-FIRST

        LD      A,$80           ;
        XOR     (HL)            ;

;;; @brief ; T-FIRST
;;;
;;; ; T-FIRST
;;; @jumps T_EXPNENT, NIL_BYTES
;;; @jumpedfrom T_GR_ZERO
T_FIRST:
        DEC     HL              ;
        JR      NZ,T_EXPNENT        ; to T-EXPNENT

        LD      (HL),A          ;
        INC     HL              ;
        LD      (HL),$FF        ;
        DEC     HL              ;
        LD      A,$18           ;
        JR      NIL_BYTES           ; to NIL-BYTES

; ---

;;; @brief ; T-SMALL
;;;
;;; ; T-SMALL
;;; @jumps X_LARGE, T_NUMERIC
;;; @jumpedfrom T_GR_ZERO
;;; @fallthrough T_NUMERIC
T_SMALL:
        JR      NC,X_LARGE        ; to X-LARGE

        PUSH    DE              ;
        CPL                     ;
        ADD     A,$91           ;
        INC     HL              ;
        LD      D,(HL)          ;
        INC     HL              ;
        LD      E,(HL)          ;
        DEC     HL              ;
        DEC     HL              ;
        LD      C,$00           ;
        BIT     7,D             ;
        JR      Z,T_NUMERIC         ; to T-NUMERIC

        DEC     C               ;

;;; @brief ; T-NUMERIC
;;;
;;; ; T-NUMERIC
;;; @jumps T_TEST
;;; @jumpedfrom T_SMALL
;;; @fallthrough T_TEST
T_NUMERIC:
        SET     7,D             ;
        LD      B,$08           ;
        SUB     B               ;
        ADD     A,B             ;
        JR      C,T_TEST         ; to T-TEST

        LD      E,D             ;
        LD      D,$00           ;
        SUB     B               ;

;;; @brief ; T-TEST
;;;
;;; ; T-TEST
;;; @jumps T_STORE
;;; @jumpedfrom T_NUMERIC
;;; @fallthrough T_SHIFT
T_TEST:
        JR      Z,T_STORE         ; to T-STORE

        LD      B,A             ;

;;; @brief ; T-SHIFT
;;;
;;; ; T-SHIFT
;;; @fallthrough T_STORE
T_SHIFT:
        SRL     D               ;
        RR      E               ;
        DJNZ    T_SHIFT           ; to T-SHIFT

;;; @brief ; T-STORE
;;;
;;; ; T-STORE
;;; @calls INT_STORE
;;; @jumpedfrom T_TEST
T_STORE:
        CALL    INT_STORE           ; routine INT-STORE
        POP     DE              ;
        RET                     ;

; ---

;;; @brief ; T-EXPNENT
;;;
;;; ; T-EXPNENT
;;; @jumpedfrom T_FIRST
;;; @fallthrough X_LARGE
T_EXPNENT:
        LD      A,(HL)          ;

;;; @brief ; X-LARGE
;;;
;;; ; X-LARGE
;;; @jumpedfrom T_SMALL
;;; @fallthrough NIL_BYTES
X_LARGE:
        SUB     $A0             ;
        RET     P               ;

        NEG                     ; Negate

;;; @brief ; NIL-BYTES
;;;
;;; ; NIL-BYTES
;;; @jumps BITS_ZERO
;;; @jumpedfrom TRUNCATE, T_FIRST
;;; @fallthrough BYTE_ZERO
NIL_BYTES:
        PUSH    DE              ;
        EX      DE,HL           ;
        DEC     HL              ;
        LD      B,A             ;
        SRL     B               ;
        SRL     B               ;
        SRL     B               ;
        JR      Z,BITS_ZERO         ; to BITS-ZERO

;;; @brief ; BYTE-ZERO
;;;
;;; ; BYTE-ZERO
;;; @fallthrough BITS_ZERO
BYTE_ZERO:
        LD      (HL),$00        ;
        DEC     HL              ;
        DJNZ    BYTE_ZERO           ; to BYTE-ZERO

;;; @brief ; BITS-ZERO
;;;
;;; ; BITS-ZERO
;;; @jumps IX_END
;;; @jumpedfrom NIL_BYTES
;;; @fallthrough LESS_MASK
BITS_ZERO:
        AND     $07             ;
        JR      Z,IX_END         ; to IX-END

        LD      B,A             ;
        LD      A,$FF           ;

;;; @brief ; LESS-MASK
;;;
;;; ; LESS-MASK
;;; @fallthrough IX_END
LESS_MASK:
        SLA     A               ;
        DJNZ    LESS_MASK           ; to LESS-MASK

        AND     (HL)            ;
        LD      (HL),A          ;

;;; @brief ; IX-END
;;;
;;; ; IX-END
;;; @jumpedfrom BITS_ZERO
IX_END:
        EX      DE,HL           ;
        POP     DE              ;
        RET                     ;

; ----------------------------------
; Storage of numbers in 5 byte form.
; ==================================
; Both integers and floating-point numbers can be stored in five bytes.
; Zero is a special case stored as 5 zeros.
; For integers the form is
; Byte 1 - zero,
; Byte 2 - sign byte, $00 +ve, $FF -ve.
; Byte 3 - Low byte of integer.
; Byte 4 - High byte
; Byte 5 - unused but always zero.
;
; it seems unusual to store the low byte first but it is just as easy either
; way. Statistically it just increases the chances of trailing zeros which
; is an advantage elsewhere in saving ROM code.
;
;             zero     sign     low      high    unused
; So +1 is  00000000 00000000 00000001 00000000 00000000
;
; and -1 is 00000000 11111111 11111111 11111111 00000000
;
; much of the arithmetic found in BASIC lines can be done using numbers
; in this form using the Z80's 16 bit register operation ADD.
; (multiplication is done by a sequence of additions).
;
; Storing -ve integers in two's complement form, means that they are ready for
; addition and you might like to add the numbers above to prove that the
; answer is zero. If, as in this case, the carry is set then that denotes that
; the result is positive. This only applies when the signs don't match.
; With positive numbers a carry denotes the result is out of integer range.
; With negative numbers a carry denotes the result is within range.
; The exception to the last rule is when the result is -65536
;
; Floating point form is an alternative method of storing numbers which can
; be used for integers and larger (or fractional) numbers.
;
; In this form 1 is stored as
;           10000001 00000000 00000000 00000000 00000000
;
; When a small integer is converted to a floating point number the last two
; bytes are always blank so they are omitted in the following steps
;
; first make exponent +1 +16d  (bit 7 of the exponent is set if positive)

; 10010001 00000000 00000001
; 10010000 00000000 00000010 <-  now shift left and decrement exponent
; ...
; 10000010 01000000 00000000 <-  until a 1 abuts the imaginary point
; 10000001 10000000 00000000     to the left of the mantissa.
;
; however since the leftmost bit of the mantissa is always set then it can
; be used to denote the sign of the mantissa and put back when needed by the
; PREP routines which gives
;
; 10000001 00000000 00000000

;;; @brief THE 'RE-STACK TWO "SMALL" INTEGERS' SUBROUTINE
;;;
;;;   This routine is called to re-stack two numbers in full floating point form
;;;   e.g. from mult when integer multiplication has overflowed.
;;;
;;; ; RE-ST-TWO
;;; @calls RESTK_SUB
;;; @calledby FULL_ADDN, MULT_LONG, DIVISION
;;; @fallthrough RESTK_SUB
RE_ST_TWO:
        CALL    RESTK_SUB           ; routine RESTK-SUB  below and continue
                                ; into the routine to do the other one.

;;; @brief ; RESTK-SUB
;;;
;;; ; RESTK-SUB
;;; @calledby RE_ST_TWO
;;; @fallthrough RE_STACK
RESTK_SUB:
        EX      DE,HL           ; swap pointers

;;; @brief THE 'RE-STACK ONE "SMALL" INTEGER' SUBROUTINE
;;;
;;; (offset: $3D 're-stack')
;;;   This routine re-stacks an integer, usually on the calculator stack, in full
;;;   floating point form.  HL points to first byte.
;;;
;;; ; re-stack
;;; @calls INT_FETCH
;;; @jumps RS_NRMLSE, RS_STORE
;;; @calledby ATN
;;; @fallthrough RS_NRMLSE
RE_STACK:
        LD      A,(HL)          ; Fetch Exponent byte to A
        AND     A               ; test it
        RET     NZ              ; return if not zero as already in full
                                ; floating-point form.

        PUSH    DE              ; preserve DE.
        CALL    INT_FETCH           ; routine INT-FETCH
                                ; integer to DE, sign to C.

; HL points to 4th byte.

        XOR     A               ; clear accumulator.
        INC     HL              ; point to 5th.
        LD      (HL),A          ; and blank.
        DEC     HL              ; point to 4th.
        LD      (HL),A          ; and blank.

        LD      B,$91           ; set exponent byte +ve $81
                                ; and imaginary dec point 16 bits to right
                                ; of first bit.

;   we could skip to normalize now but it's quicker to avoid normalizing
;   through an empty D.

        LD      A,D             ; fetch the high byte D
        AND     A               ; is it zero ?
        JR      NZ,RS_NRMLSE        ; skip to RS-NRMLSE if not.

        OR      E               ; low byte E to A and test for zero
        LD      B,D             ; set B exponent to 0
        JR      Z,RS_STORE         ; forward to RS-STORE if value is zero.

        LD      D,E             ; transfer E to D
        LD      E,B             ; set E to 0
        LD      B,$89           ; reduce the initial exponent by eight.


;;; @brief ; RS-NRMLSE
;;;
;;; ; RS-NRMLSE
;;; @jumpedfrom RE_STACK
;;; @fallthrough RSTK_LOOP
RS_NRMLSE:
        EX      DE,HL           ; integer to HL, addr of 4th byte to DE.

;;; @brief ; RSTK-LOOP
;;;
;;; ; RSTK-LOOP
;;; @fallthrough RS_STORE
RSTK_LOOP:
        DEC     B               ; decrease exponent
        ADD     HL,HL           ; shift DE left
        JR      NC,RSTK_LOOP        ; loop back to RSTK-LOOP
                                ; until a set bit pops into carry

        RRC     C               ; now rotate the sign byte $00 or $FF
                                ; into carry to give a sign bit

        RR      H               ; rotate the sign bit to left of H
        RR      L               ; rotate any carry into L

        EX      DE,HL           ; address 4th byte, normalized int to DE

;;; @brief ; RS-STORE
;;;
;;; ; RS-STORE
;;; @jumpedfrom RE_STACK
RS_STORE:
        DEC     HL              ; address 3rd byte
        LD      (HL),E          ; place E
        DEC     HL              ; address 2nd byte
        LD      (HL),D          ; place D
        DEC     HL              ; address 1st byte
        LD      (HL),B          ; store the exponent

        POP     DE              ; restore initial DE.
        RET                     ; return.

;****************************************
