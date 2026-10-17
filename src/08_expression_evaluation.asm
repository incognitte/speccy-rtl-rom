;;; @file 08_expression_evaluation.asm
;;; @brief Part 8. EXPRESSION EVALUATION

;***********************************
;** Part 8. EXPRESSION EVALUATION **
;***********************************
;
; It is a this stage of the ROM that the Spectrum ceases altogether to be
; just a colourful novelty. One remarkable feature is that in all previous
; commands when the Spectrum is expecting a number or a string then an
; expression of the same type can be substituted ad infinitum.
; This is the routine that evaluates that expression.
; This is what causes 2 + 2 to give the answer 4.
; That is quite easy to understand. However you don't have to make it much
; more complex to start a remarkable juggling act.
; e.g. PRINT 2 * (VAL "2+2" + TAN 3)
; In fact, provided there is enough free RAM, the Spectrum can evaluate
; an expression of unlimited complexity.
; Apart from a couple of minor glitches, which you can now correct, the
; system is remarkably robust.


;;; @brief Scan expression or sub-expression
;;;
;;; ; SCANNING
;;; @calledby VAL_FET_2, EXPT_1NUM, EXPT_EXP, DATA_1, DEF_FN_6, PR_ITEM_3, S_BRACKET, SF_ARGMTS, SF_ARG_VL, SF_VALUE, +1 more
;;; @fallthrough S_LOOP_1
SCANNING:
        RST     18H             ; GET-CHAR
        LD      B,$00           ; priority marker zero is pushed on stack
                                ; to signify end of expression when it is
                                ; popped off again.
        PUSH    BC              ; put in on stack.
                                ; and proceed to consider the first character
                                ; of the expression.

;;; @brief ; S-LOOP-1
;;;
;;; ; S-LOOP-1
;;; @calls INDEXER
;;; @jumps S_ALPHNUM
;;; @jumpedfrom S_U_PLUS, S_PUSH_PO, S_NEXT
S_LOOP_1:
        LD      C,A             ; store the character while a look up is done.
        LD      HL,SCAN_FUNC        ; Address: scan-func
        CALL    INDEXER           ; routine INDEXER is called to see if it is
                                ; part of a limited range '+', '(', 'ATTR' etc.

        LD      A,C             ; fetch the character back
        JP      NC,S_ALPHNUM        ; jump forward to S-ALPHNUM if not in primary
                                ; operators and functions to consider in the
                                ; first instance a digit or a variable and
                                ; then anything else.                >>>

        LD      B,$00           ; but here if it was found in table so
        LD      C,(HL)          ; fetch offset from table and make B zero.
        ADD     HL,BC           ; add the offset to position found
        JP      (HL)            ; and jump to the routine e.g. S-BIN
                                ; making an indirect exit from there.

;;; @brief The four service subroutines for routines in the scanning function table
;;;
;;; PRINT """Hooray!"" he cried."
;;;
;;; ; S-QUOTE-S
;;; @calls CH_ADD_1
;;; @jumps REPORT_C
;;; @calledby S_QUOTE, S_Q_AGAIN
S_QUOTE_S:
        CALL    CH_ADD_1           ; routine CH-ADD+1 points to next character
                                ; and fetches that character.
        INC     BC              ; increase length counter.
        CP      $0D             ; is it carriage return ?
                                ; inside a quote.
        JP      Z,REPORT_C         ; jump back to REPORT-C if so.
                                ; 'Nonsense in BASIC'.

        CP      $22             ; is it a quote '"' ?
        JR      NZ,S_QUOTE_S        ; back to S-QUOTE-S if not for more.

        CALL    CH_ADD_1           ; routine CH-ADD+1
        CP      $22             ; compare with possible adjacent quote
        RET                     ; return. with zero set if two together.

; ---

; This subroutine is used to get two coordinate expressions for the three
; functions SCREEN$, ATTR and POINT that have two fixed parameters and
; therefore require surrounding braces.

;;; @brief ; S-2-COORD
;;;
;;; ; S-2-COORD
;;; @calls NEXT_2NUM
;;; @jumps S_RPORT_C
;;; @calledby S_SCREEN, S_ATTR, S_POINT
;;; @fallthrough S_RPORT_C
S_2_COORD:
        RST     20H             ; NEXT-CHAR
        CP      $28             ; is it the opening '(' ?
        JR      NZ,S_RPORT_C        ; forward to S-RPORT-C if not
                                ; 'Nonsense in BASIC'.

        CALL    NEXT_2NUM           ; routine NEXT-2NUM gets two comma-separated
                                ; numeric expressions. Note. this could cause
                                ; many more recursive calls to SCANNING but
                                ; the parent function will be evaluated fully
                                ; before rejoining the main juggling act.

        RST     18H             ; GET-CHAR
        CP      $29             ; is it the closing ')' ?

;;; @brief ; S-RPORT-C
;;;
;;; ; S-RPORT-C
;;; @jumps REPORT_C
;;; @jumpedfrom S_2_COORD
;;; @fallthrough SYNTAX_Z
S_RPORT_C:
        JP      NZ,REPORT_C        ; jump back to REPORT-C if not.
                                ; 'Nonsense in BASIC'.

;;; @brief Check syntax
;;;
;;; This routine is called on a number of occasions to check if syntax is being
;;; checked or if the program is being run. To test the flag inline would use
;;; four bytes of code, but a call instruction only uses 3 bytes of code.
;;;
;;; ; SYNTAX-Z
;;; @calledby L0609, REPORT_FA, LIST_1, LINE_END, CHECK_END, VAR_A_2, CLASS_09, USE_ZERO, STOP, READ, +21 more
SYNTAX_Z:
        BIT     7,(IY+$01)      ; test FLAGS  - checking syntax only ?
        RET                     ; return.

;;; @brief Scanning SCREEN$
;;;
;;; This function returns the code of a bit-mapped character at screen
;;; position at line C, column B. It is unable to detect the mosaic characters
;;; which are not bit-mapped but detects the ASCII 32 - 127 range.
;;; The bit-mapped UDGs are ignored which is curious as it requires only a
;;; few extra bytes of code. As usual, anything to do with CHARS is weird.
;;; If no match is found a null string is returned.
;;; No actual check on ranges is performed - that's up to the BASIC programmer.
;;; No real harm can come from SCREEN$(255,255) although the BASIC manual
;;; says that invalid values will be trapped.
;;; Interestingly, in the Pitman pocket guide, 1984, Vickers says that the
;;; range checking will be performed.
;;;
;;; ; S-SCRN$-S
;;; @calls STK_TO_BC, L1543
;;; @calledby S_SCREEN
;;; @fallthrough S_SCR_STO
S_SCRN_S:
        CALL    STK_TO_BC           ; routine STK-TO-BC.
                                ; Note. not inc h. ??

;; S-SCRN-LP
                                ; if inverse result would be $FF
                                ; if any other then mismatch



; a match has been found so seven more to test.

;; S-SC-MTCH

;; S-SC-ROWS


; continue if a match of all eight bytes was found

                                ; to give the code 32-127

                                ; the calculator stack upwards.

; ---

; the jump was here if no match and more bitmaps to test.

;; S-SCR-NXT
; (original ROM code at this address, superseded above): LD A,C ; transfer line to A.
; (original ROM code at this address, superseded above): RRCA ; by
; (original ROM code at this address, superseded above): RRCA ; thirty-two.
; (original ROM code at this address, superseded above): AND $E0 ; and with 11100000
; (original ROM code at this address, superseded above): XOR B ; combine with column $00 - $1F
; (original ROM code at this address, superseded above): AND $18 ; and with 00011000
; (original ROM code at this address, superseded above): XOR $40 ; xor with 01000000 (high byte screen start)
; (original ROM code at this address, superseded above): L254F: PUSH BC ; save count
; (original ROM code at this address, superseded above): PUSH HL ; save bitmap start
; (original ROM code at this address, superseded above): XOR (HL) ; xor with corresponding character byte
; (original ROM code at this address, superseded above): JR Z,L255A ; forward to S-SC-MTCH if they match
; (original ROM code at this address, superseded above): JR NZ,L2573 ; forward to S-SCR-NXT if a mismatch
; (original ROM code at this address, superseded above): L255A: LD C,A ; load C with inverse mask $00 or $FF
; (original ROM code at this address, superseded above): LD B,$07 ; count seven more bytes
; (original ROM code at this address, superseded above): INC HL ; increment bitmap address.
; (original ROM code at this address, superseded above): XOR (HL) ; will give $00 or $FF (inverse)
; (original ROM code at this address, superseded above): XOR C ; xor with inverse mask
; (original ROM code at this address, superseded above): JR NZ,L2573 ; forward to S-SCR-NXT if no match.
; (original ROM code at this address, superseded above): DJNZ L255D ; back to S-SC-ROWS until all eight matched.
; (original ROM code at this address, superseded above): POP BC ; pointers
; (original ROM code at this address, superseded above): LD A,$80 ; the endpoint of character set
; (original ROM code at this address, superseded above): SUB B ; subtract the counter
; (original ROM code at this address, superseded above): JR S_SCR_STO ; forward to S-SCR-STO
; (original ROM code at this address, superseded above): LD DE,$0008 ; and prepare to add 8.
; (original ROM code at this address, superseded above): POP DE ; restore screen address
; (original ROM code at this address, superseded above): DJNZ L254F ; back to S-SCRN-LP if more characters.
        LD      BC,0                    ; BC = 0
        RET                             ; return
L253C:
        CP      12                      ; compare A with 12
        JR      NZ,L254D                ; if not zero, jump to L254D
        BIT     6,(IY+2)                ; test bit 6 of (IY+2)
        JR      Z,L2573                 ; if zero, jump to L2573
        LD      A,(HL)                  ; A = (HL)
        CP      13                      ; compare A with 13
        JP      NZ,L1018                ; if not zero, jump to the 1-byte RECLAIM in ED-DELETE
        RST     8                       ; restart at 8
L254D:
        CALL    L1543                   ; call L1543
        JR      C,L2559                 ; if carry, jump to L2559
        SET     3,(IY+$37)              ; set bit 3 of (IY+$37)
        JP      L0F41                   ; jump to L0F41
L2559:
        BIT     3,(IY+$37)              ; test bit 3 of (IY+$37)
L255D:
        JR      Z,L2573                 ; if zero, jump to L2573
        BIT     6,(IY+2)                ; test bit 6 of (IY+2)
        JR      NZ,L2573                ; if not zero, jump to L2573
        PUSH    AF                      ; push AF onto the stack
L2566:
        LD      A,(HL)                  ; A = (HL)
        CALL    L1543                   ; call L1543
        JR      C,L256F                 ; if carry, jump to L256F
        INC     HL                      ; HL = HL + 1
        JR      L2566                   ; jump to L2566
L256F:
        POP     AF                      ; pop AF off the stack
        LD      (K_CUR),HL              ; (K_CUR) = HL
L2573:
        RES     3,(IY+$37)              ; clear bit 3 of (IY+$37)
        CP      $18                     ; compare A with $18
        JP      L0F4D                   ; jump to L0F4D
L254F  EQU    $254F                   ; this address now falls inside the block above (label kept for reference)
L255A  EQU    $255A                   ; this address now falls inside the block above (label kept for reference)

        LD      C,B             ; B is now zero, so BC now zero.

;;; @brief ; S-SCR-STO
;;;
;;; ; S-SCR-STO
;;; @jumps STK_STO
S_SCR_STO:
        JP      STK_STO           ; to STK-STO-$ to store the string in
                                ; workspace or a string with zero length.
                                ; (value of DE doesn't matter in last case)

; Note. this exit seems correct but the general-purpose routine S-STRING
; that calls this one will also stack any of its string results so this
; leads to a double storing of the result in this case.
; The instruction at S_SCR_STO should just be a RET.
; credit Stephen Kelly and others, 1982.

;;; @brief Scanning ATTR
;;;
;;; This function subroutine returns the attributes of a screen location -
;;; a numeric result.
;;; Again it's up to the BASIC programmer to supply valid values of line/column.
;;;
;;; ; S-ATTR-S
;;; @calls STK_TO_BC
;;; @jumps STACK_A
;;; @calledby S_ATTR
S_ATTR_S:
        CALL    STK_TO_BC           ; routine STK-TO-BC fetches line to C,
                                ; and column to B.
        LD      A,C             ; line to A $00 - $17   (max 00010111)
        RRCA                    ; rotate
        RRCA                    ; bits
        RRCA                    ; left.
        LD      C,A             ; store in C as an intermediate value.

        AND     $E0             ; pick up bits 11100000 ( was 00011100 )
        XOR     B               ; combine with column $00 - $1F
        LD      L,A             ; low byte now correct.

        LD      A,C             ; bring back intermediate result from C
        AND     $03             ; mask to give correct third of
                                ; screen $00 - $02
        XOR     $58             ; combine with base address.
        LD      H,A             ; high byte correct.
        LD      A,(HL)          ; pick up the colour attribute.
        JP      STACK_A           ; forward to STACK-A to store result
                                ; and make an indirect exit.

;;; @brief Scanning function table
;;;
;;; This table is used by INDEXER routine to find the offsets to
;;; four operators and eight functions. e.g. $A8 is the token 'FN'.
;;; This table is used in the first instance for the first character of an
;;; expression or by a recursive call to SCANNING for the first character of
;;; any sub-expression. It eliminates functions that have no argument or
;;; functions that can have more than one argument and therefore require
;;; braces. By eliminating and dealing with these now it can later take a
;;; simplistic approach to all other functions and assume that they have
;;; one argument.
;;; Similarly by eliminating BIN and '.' now it is later able to assume that
;;; all numbers begin with a digit and that the presence of a number or
;;; variable can be detected by a call to ALPHANUM.
;;; By default all expressions are positive and the spurious '+' is eliminated
;;; now as in print +2. This should not be confused with the operator '+'.
;;; Note. this does allow a degree of nonsense to be accepted as in
;;; PRINT +"3 is the greatest.".
;;; An acquired programming skill is the ability to include brackets where
;;; they are not necessary.
;;; A bracket at the start of a sub-expression may be spurious or necessary
;;; to denote that the contained expression is to be evaluated as an entity.
;;; In either case this is dealt with by recursive calls to SCANNING.
;;; An expression that begins with a quote requires special treatment.
;;;
;;; ; scan-func
SCAN_FUNC:
        DB          $22, S_QUOTE-$-1  ; $1C offset to S-QUOTE
        DB          '(', S_BRACKET-$-1  ; $4F offset to S-BRACKET
        DB          '.', S_DECIMAL-$-1  ; $F2 offset to S-DECIMAL
        DB          '+', S_U_PLUS-$-1  ; $12 offset to S-U-PLUS

        DB          $A8, S_FN-$-1  ; $56 offset to S-FN
        DB          $A5, S_RND-$-1  ; $57 offset to S-RND
        DB          $A7, S_PI-$-1  ; $84 offset to S-PI
        DB          $A6, S_INKEY-$-1  ; $8F offset to S-INKEY$
        DB          $C4, S_DECIMAL-$-1  ; $E6 offset to S-BIN
        DB          $AA, S_SCREEN-$-1  ; $BF offset to S-SCREEN$
        DB          $AB, S_ATTR-$-1  ; $C7 offset to S-ATTR
        DB          $A9, S_POINT-$-1  ; $CE offset to S-POINT

        DB          $00             ; zero end marker

;;; @brief Scanning function routines
;;;
;;; These are the 11 subroutines accessed by the above table.
;;; S-BIN and S-DECIMAL are the same
;;; The 1-byte offset limits their location to within 255 bytes of their
;;; entry in the table.
;;;
;;; ->
;;; ; S-U-PLUS
;;; @jumps S_LOOP_1
S_U_PLUS:
        RST     20H             ; NEXT-CHAR just ignore
        JP      S_LOOP_1           ; to S-LOOP-1

; ---

;;; @brief > ; S-QUOTE
;;;
;;; ->
;;; ; S-QUOTE
;;; @calls S_QUOTE_S
;;; @jumps S_Q_PRMS
;;; @fallthrough S_Q_AGAIN
S_QUOTE:
        RST     18H             ; GET-CHAR
        INC     HL              ; address next character (first in quotes)
        PUSH    HL              ; save start of quoted text.
        LD      BC,$0000        ; initialize length of string to zero.
        CALL    S_QUOTE_S           ; routine S-QUOTE-S
        JR      NZ,S_Q_PRMS        ; forward to S-Q-PRMS if

;;; @brief ; S-Q-AGAIN
;;;
;;; ; S-Q-AGAIN
;;; @calls S_QUOTE_S, SYNTAX_Z
;;; @jumps S_Q_PRMS
;;; @fallthrough S_Q_COPY
S_Q_AGAIN:
        CALL    S_QUOTE_S           ; routine S-QUOTE-S copies string until a
                                ; quote is encountered
        JR      Z,S_Q_AGAIN         ; back to S-Q-AGAIN if two quotes WERE
                                ; together.

; but if just an isolated quote then that terminates the string.

        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,S_Q_PRMS         ; forward to S-Q-PRMS if checking syntax.


        RST     30H             ; BC-SPACES creates the space for true
                                ; copy of string in workspace.
        POP     HL              ; re-fetch start of quoted text.
        PUSH    DE              ; save start in workspace.

;;; @brief ; S-Q-COPY
;;;
;;; ; S-Q-COPY
;;; @fallthrough S_Q_PRMS
S_Q_COPY:
        LD      A,(HL)          ; fetch a character from source.
        INC     HL              ; advance source address.
        LD      (DE),A          ; place in destination.
        INC     DE              ; advance destination address.
        CP      $22             ; was it a '"' just copied ?
        JR      NZ,S_Q_COPY        ; back to S-Q-COPY to copy more if not

        LD      A,(HL)          ; fetch adjacent character from source.
        INC     HL              ; advance source address.
        CP      $22             ; is this '"' ? - i.e. two quotes together ?
        JR      Z,S_Q_COPY         ; to S-Q-COPY if so including just one of the
                                ; pair of quotes.

; proceed when terminating quote encountered.

;;; @brief ; S-Q-PRMS
;;;
;;; ; S-Q-PRMS
;;; @jumpedfrom S_QUOTE, S_Q_AGAIN
;;; @fallthrough S_STRING
S_Q_PRMS:
        DEC     BC              ; decrease count by 1.
        POP     DE              ; restore start of string in workspace.

;;; @brief ; S-STRING
;;;
;;; ; S-STRING
;;; @calls STK_STO
;;; @jumps S_CONT_2
;;; @jumpedfrom S_SCREEN
S_STRING:
        LD      HL,FLAGS        ; Address FLAGS system variable.
        RES     6,(HL)          ; signal string result.
        BIT     7,(HL)          ; is syntax being checked.
        CALL    NZ,STK_STO        ; routine STK-STO-$ is called in runtime.
        JP      S_CONT_2           ; jump forward to S-CONT-2          ===>

; ---

;;; @brief > ; S-BRACKET
;;;
;;; ->
;;; ; S-BRACKET
;;; @calls SCANNING
;;; @jumps REPORT_C, S_CONT_2
S_BRACKET:
        RST     20H             ; NEXT-CHAR
        CALL    SCANNING           ; routine SCANNING is called recursively.
        CP      $29             ; is it the closing ')' ?
        JP      NZ,REPORT_C        ; jump back to REPORT-C if not
                                ; 'Nonsense in BASIC'

        RST     20H             ; NEXT-CHAR
        JP      S_CONT_2           ; jump forward to S-CONT-2          ===>

; ---

;;; @brief > ; S-FN
;;;
;;; ->
;;; ; S-FN
;;; @jumps S_FN_SBRN
S_FN:
        JP      S_FN_SBRN           ; jump forward to S-FN-SBRN.

; --------------------------------------------------------------------
;
;   RANDOM THEORY from the ZX81 manual by Steven Vickers
;
;   (same algorithm as the ZX Spectrum).
;
;   Chapter 5. Exercise 6. (For mathematicians only.)
;
;   Let p be a [large] prime, & let a be a primitive root modulo p.
;   Then if b_i is the residue of a^i modulo p (1<=b_i<p-1), the
;   sequence
;
;                           (b_i-1)/(p-1)
;
;   is a cyclical sequence of p-1 distinct numbers in the range 0 to 1
;   (excluding 1). By choosing a suitably, these can be made to look
;   fairly random.
;
;     65537 is a Mersenne prime 2^16-1. Note.
;
;   Use this, & Gauss' law of quadratic reciprocity, to show that 75
;   is a primitive root modulo 65537.
;
;     The ZX81 uses p=65537 & a=75, & stores some b_i-1 in memory.
;   The function RND involves replacing b_i-1 in memory by b_(i+1)-1,
;   & yielding the result (b_(i+1)-1)/(p-1). RAND n (with 1<=n<=65535)
;   makes b_i equal to n+1.
;
; --------------------------------------------------------------------
;
; Steven Vickers writing in comp.sys.sinclair on 20-DEC-1993
;
;   Note. (Of course, 65537 is 2^16 + 1, not -1.)
;
;   Consider arithmetic modulo a prime p. There are p residue classes, and the
;   non-zero ones are all invertible. Hence under multiplication they form a
;   group (Fp*, say) of order p-1; moreover (and not so obvious) Fp* is cyclic.
;   Its generators are the "primitive roots". The "quadratic residues modulo p"
;   are the squares in Fp*, and the "Legendre symbol" (d/p) is defined (when p
;   does not divide d) as +1 or -1, according as d is or is not a quadratic
;   residue mod p.
;
;   In the case when p = 65537, we can show that d is a primitive root if and
;   only if it's not a quadratic residue. For let w be a primitive root, d
;   congruent to w^r (mod p). If d is not primitive, then its order is a proper
;   factor of 65536: hence w^{32768*r} = 1 (mod p), so 65536 divides 32768*r,
;   and hence r is even and d is a square (mod p). Conversely, the squares in
;   Fp* form a subgroup of (Fp*)^2 of index 2, and so cannot be generators.
;
;   Hence to check whether 75 is primitive mod 65537, we want to calculate that
;   (75/65537) = -1. There is a multiplicative formula (ab/p) = (a/p)(b/p) (mod
;   p), so (75/65537) = (5/65537)^2 * (3/65537) = (3/65537). Now the law of
;   quadratic reciprocity says that if p and q are distinct odd primes, then
;
;    (p/q)(q/p) = (-1)^{(p-1)(q-1)/4}
;
;   Hence (3/65537) = (65537/3) * (-1)^{65536*2/4} = (65537/3)
;            = (2/3)  (because 65537 = 2 mod 3)
;            = -1
;
;   (I referred to Pierre Samuel's "Algebraic Theory of Numbers".)
;
; ->

;;; @brief ; S-RND
;;;
;;; ; S-RND
;;; @calls SYNTAX_Z, STACK_BC, FP_TO_BC
;;; @jumps S_RND_END
;;; @fallthrough S_RND_END
S_RND:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,S_RND_END         ; forward to S-RND-END if checking syntax.

        LD      BC,(SEED)      ; fetch system variable SEED
        CALL    STACK_BC           ; routine STACK-BC places on calculator stack

        RST     28H             ;; FP-CALC           ;s.
        DB          $A1             ;;stk-one            ;s,1.
        DB          $0F             ;;addition           ;s+1.
        DB          $34             ;;stk-data           ;
        DB          $37             ;;Exponent: $87,
                                ;;Bytes: 1
        DB          $16             ;;(+00,+00,+00)      ;s+1,75.
        DB          $04             ;;multiply           ;(s+1)*75 = v
        DB          $34             ;;stk-data           ;v.
        DB          $80             ;;Bytes: 3
        DB          $41             ;;Exponent $91
        DB          $00,$00,$80     ;;(+00)              ;v,65537.
        DB          $32             ;;n-mod-m            ;remainder, result.
        DB          $02             ;;delete             ;remainder.
        DB          $A1             ;;stk-one            ;remainder, 1.
        DB          $03             ;;subtract           ;remainder - 1. = rnd
        DB          $31             ;;duplicate          ;rnd,rnd.
        DB          $38             ;;end-calc

        CALL    FP_TO_BC           ; routine FP-TO-BC
        LD      (SEED),BC      ; store in SEED for next starting point.
        LD      A,(HL)          ; fetch exponent
        AND     A               ; is it zero ?
        JR      Z,S_RND_END         ; forward if so to S-RND-END

        SUB     $10             ; reduce exponent by 2^16
        LD      (HL),A          ; place back

;;; @brief ; S-RND-END
;;;
;;; ; S-RND-END
;;; @jumps S_PI_END
;;; @jumpedfrom S_RND
S_RND_END:
        JR      S_PI_END           ; forward to S-PI-END

; ---

; the number PI 3.14159...

;;; @brief > ; S-PI
;;;
;;; ->
;;; ; S-PI
;;; @calls SYNTAX_Z
;;; @jumps S_PI_END
;;; @fallthrough S_PI_END
S_PI:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,S_PI_END         ; to S-PI-END if checking syntax.

        RST     28H             ;; FP-CALC
        DB          $A3             ;;stk-pi/2                          pi/2.
        DB          $38             ;;end-calc

        INC     (HL)            ; increment the exponent leaving pi
                                ; on the calculator stack.

;;; @brief ; S-PI-END
;;;
;;; ; S-PI-END
;;; @jumps S_NUMERIC
;;; @jumpedfrom S_RND_END, S_PI
S_PI_END:
        RST     20H             ; NEXT-CHAR
        JP      S_NUMERIC           ; jump forward to S-NUMERIC

; ---

;;; @brief > ; S-INKEY$
;;;
;;; ->
;;; ; S-INKEY$
;;; @calls KEY_SCAN, K_TEST, K_DECODE
;;; @jumps S_PUSH_PO, S_INK_EN, S_IK_STK
;;; @fallthrough S_IK_STK
S_INKEY:
        LD      BC,$105A        ; priority $10, operation code $1A ('read-in')
                                ; +$40 for string result, numeric operand.
                                ; set this up now in case we need to use the
                                ; calculator.
        RST     20H             ; NEXT-CHAR
        CP      $23             ; '#' ?
        JP      Z,S_PUSH_PO         ; to S-PUSH-PO if so to use the calculator
                                ; single operation
                                ; to read from network/RS232 etc. .

; else read a key from the keyboard.

        LD      HL,FLAGS        ; fetch FLAGS
        RES     6,(HL)          ; signal string result.
        BIT     7,(HL)          ; checking syntax ?
        JR      Z,S_INK_EN         ; forward to S-INK$-EN if so

        CALL    KEY_SCAN           ; routine KEY-SCAN key in E, shift in D.
        LD      C,$00           ; the length of an empty string
        JR      NZ,S_IK_STK        ; to S-IK$-STK to store empty string if
                                ; no key returned.

        CALL    K_TEST           ; routine K-TEST get main code in A
        JR      NC,S_IK_STK        ; to S-IK$-STK to stack null string if
                                ; invalid

        DEC     D               ; D is expected to be FLAGS so set bit 3 $FF
                                ; 'L' Mode so no keywords.
        LD      E,A             ; main key to A
                                ; C is MODE 0 'KLC' from above still.
        CALL    K_DECODE           ; routine K-DECODE
        PUSH    AF              ; save the code
        LD      BC,$0001        ; make room for one character

        RST     30H             ; BC-SPACES
        POP     AF              ; bring the code back
        LD      (DE),A          ; put the key in workspace
        LD      C,$01           ; set C length to one

;;; @brief ; S-IK$-STK
;;;
;;; ; S-IK$-STK
;;; @calls STK_STO
;;; @jumpedfrom S_INKEY
;;; @fallthrough S_INK_EN
S_IK_STK:
        LD      B,$00           ; set high byte of length to zero
        CALL    STK_STO           ; routine STK-STO-$

;;; @brief ; S-INK$-EN
;;;
;;; ; S-INK$-EN
;;; @jumps S_CONT_2
;;; @jumpedfrom S_INKEY
S_INK_EN:
        JP      S_CONT_2           ; to S-CONT-2            ===>

; ---

;;; @brief > ; S-SCREEN$
;;;
;;; ->
;;; ; S-SCREEN$
;;; @calls S_2_COORD, S_SCRN_S
;;; @jumps S_STRING
S_SCREEN:
        CALL    S_2_COORD           ; routine S-2-COORD
        CALL    NZ,S_SCRN_S        ; routine S-SCRN$-S

        RST     20H             ; NEXT-CHAR
        JP      S_STRING           ; forward to S-STRING to stack result

; ---

;;; @brief > ; S-ATTR
;;;
;;; ->
;;; ; S-ATTR
;;; @calls S_2_COORD, S_ATTR_S
;;; @jumps S_NUMERIC
S_ATTR:
        CALL    S_2_COORD           ; routine S-2-COORD
        CALL    NZ,S_ATTR_S        ; routine S-ATTR-S

        RST     20H             ; NEXT-CHAR
        JR      S_NUMERIC           ; forward to S-NUMERIC

; ---

;;; @brief > ; S-POINT
;;;
;;; ->
;;; ; S-POINT
;;; @calls S_2_COORD, POINT_SUB
;;; @jumps S_NUMERIC
S_POINT:
        CALL    S_2_COORD           ; routine S-2-COORD
        CALL    NZ,POINT_SUB        ; routine POINT-SUB

        RST     20H             ; NEXT-CHAR
        JR      S_NUMERIC           ; forward to S-NUMERIC

; -----------------------------

; ==> The branch was here if not in table.

;;; @brief ; S-ALPHNUM
;;;
;;; ; S-ALPHNUM
;;; @calls ALPHANUM
;;; @jumps S_NEGATE, S_LETTER
;;; @jumpedfrom S_LOOP_1
;;; @fallthrough S_DECIMAL
S_ALPHNUM:
        CALL    ALPHANUM           ; routine ALPHANUM checks if variable or
                                ; a digit.
        JR      NC,S_NEGATE        ; forward to S-NEGATE if not to consider
                                ; a '-' character then functions.

        CP      $41             ; compare 'A'
        JR      NC,S_LETTER        ; forward to S-LETTER if alpha       ->
                                ; else must have been numeric so continue
                                ; into that routine.

; This important routine is called during runtime and from LINE-SCAN
; when a BASIC line is checked for syntax. It is this routine that
; inserts, during syntax checking, the invisible floating point numbers
; after the numeric expression. During runtime it just picks these
; numbers up. It also handles BIN format numbers.

;;; @brief > ; S-BIN ; S-DECIMAL
;;;
;;; ->
;;; ; S-BIN
;;; ; S-DECIMAL
;;; @calls SYNTAX_Z, L139E, MAKE_ROOM, TEMP_PTR1
;;; @jumps S_STK_DEC, S_NUMERIC
S_DECIMAL:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      NZ,S_STK_DEC        ; to S-STK-DEC in runtime

; this route is taken when checking syntax.

        CALL    L139E                   ; call L139E

        RST     18H             ; GET-CHAR to fetch HL
        LD      BC,$0006        ; six locations required
        CALL    MAKE_ROOM           ; routine MAKE-ROOM
        INC     HL              ; to first new location
        LD      (HL),$0E        ; insert number marker
        INC     HL              ; address next
        EX      DE,HL           ; make DE destination.
        LD      HL,(STKEND)      ; STKEND points to end of stack.
        LD      C,$05           ; result is five locations lower
        AND     A               ; prepare for true subtraction
        SBC     HL,BC           ; point to start of value.
        LD      (STKEND),HL      ; update STKEND as we are taking number.
        LDIR                    ; Copy five bytes to program location
        EX      DE,HL           ; transfer pointer to HL
        DEC     HL              ; adjust
        CALL    TEMP_PTR1           ; routine TEMP-PTR1 sets CH-ADD
        JR      S_NUMERIC           ; to S-NUMERIC to record nature of result

; ---

; branch here in runtime.

;;; @brief ; S-STK-DEC
;;;
;;; ; S-STK-DEC
;;; @jumpedfrom S_DECIMAL
;;; @fallthrough S_SD_SKIP
S_STK_DEC:
        RST     18H             ; GET-CHAR positions HL at digit.

;;; @brief ; S-SD-SKIP
;;;
;;; ; S-SD-SKIP
;;; @calls STACK_NUM
;;; @fallthrough S_NUMERIC
S_SD_SKIP:
        INC     HL              ; advance pointer
        LD      A,(HL)          ; until we find
        CP      $0E             ; chr 14d - the number indicator
        JR      NZ,S_SD_SKIP        ; to S-SD-SKIP until a match
                                ; it has to be here.

        INC     HL              ; point to first byte of number
        CALL    STACK_NUM           ; routine STACK-NUM stacks it
        LD      (CH_ADD),HL      ; update system variable CH_ADD

;;; @brief ; S-NUMERIC
;;;
;;; ; S-NUMERIC
;;; @jumps S_CONT_1
;;; @jumpedfrom S_PI_END, S_ATTR, S_POINT, S_DECIMAL
S_NUMERIC:
        SET     6,(IY+$01)      ; update FLAGS  - Signal numeric result
        JR      S_CONT_1           ; forward to S-CONT-1               ===>
                                ; actually S-CONT-2 is destination but why
                                ; waste a byte on a jump when a JR will do.
                                ; Actually a JR S_CONT_2 can be used. Rats.

; end of functions accessed from scanning functions table.

;;; @brief Scanning variable routines
;;;
;;; ; S-LETTER
;;; @calls LOOK_VARS, STK_VAR, STACK_NUM
;;; @jumps REPORT_2, S_CONT_1
;;; @jumpedfrom S_ALPHNUM
;;; @fallthrough S_CONT_1
S_LETTER:
        CALL    LOOK_VARS           ; routine LOOK-VARS

        JP      C,REPORT_2         ; jump back to REPORT-2 if variable not found
                                ; 'Variable not found'
                                ; but a variable is always 'found' if syntax
                                ; is being checked.

        CALL    Z,STK_VAR         ; routine STK-VAR considers a subscript/slice
        LD      A,(FLAGS)       ; fetch FLAGS value
        CP      $C0             ; compare 11000000
        JR      C,S_CONT_1         ; step forward to S-CONT-1 if string  ===>

        INC     HL              ; advance pointer
        CALL    STACK_NUM           ; routine STACK-NUM

;;; @brief ; S-CONT-1
;;;
;;; ; S-CONT-1
;;; @jumps S_CONT_2
;;; @jumpedfrom S_NUMERIC, S_LETTER
S_CONT_1:
        JR      S_CONT_2           ; forward to S-CONT-2                 ===>

; ----------------------------------------
; -> the scanning branch was here if not alphanumeric.
; All the remaining functions will be evaluated by a single call to the
; calculator. The correct priority for the operation has to be placed in
; the B register and the operation code, calculator literal in the C register.
; the operation code has bit 7 set if result is numeric and bit 6 is
; set if operand is numeric. so
; $C0 = numeric result, numeric operand.            e.g. 'sin'
; $80 = numeric result, string operand.             e.g. 'code'
; $40 = string result, numeric operand.             e.g. 'str$'
; $00 = string result, string operand.              e.g. 'val$'

;;; @brief ; S-NEGATE
;;;
;;; ; S-NEGATE
;;; @jumps S_PUSH_PO, REPORT_C, S_NO_TO
;;; @jumpedfrom S_ALPHNUM
;;; @fallthrough S_NO_TO
S_NEGATE:
        LD      BC,$09DB        ; prepare priority 09, operation code $C0 +
                                ; 'negate' ($1B) - bits 6 and 7 set for numeric
                                ; result and numeric operand.

        CP      $2D             ; is it '-' ?
        JR      Z,S_PUSH_PO         ; forward if so to S-PUSH-PO

        LD      BC,$1018        ; prepare priority $10, operation code 'val$' -
                                ; bits 6 and 7 reset for string result and
                                ; string operand.

        CP      $AE             ; is it 'VAL$' ?
        JR      Z,S_PUSH_PO         ; forward if so to S-PUSH-PO

        SUB     $AF             ; subtract token 'CODE' value to reduce
                                ; functions 'CODE' to 'NOT' although the
                                ; upper range is, as yet, unchecked.
                                ; valid range would be $00 - $14.

        JP      C,REPORT_C         ; jump back to REPORT-C with anything else
                                ; 'Nonsense in BASIC'

        LD      BC,$04F0        ; prepare priority $04, operation $C0 +
                                ; 'not' ($30)

        CP      $14             ; is it 'NOT'
        JR      Z,S_PUSH_PO         ; forward to S-PUSH-PO if so

        JP      NC,REPORT_C        ; to REPORT-C if higher
                                ; 'Nonsense in BASIC'

        LD      B,$10           ; priority $10 for all the rest
        ADD     A,$DC           ; make range $DC - $EF
                                ; $C0 + 'code'($1C) thru 'chr$' ($2F)

        LD      C,A             ; transfer 'function' to C
        CP      $DF             ; is it 'sin' ?
        JR      NC,S_NO_TO        ; forward to S-NO-TO-$  with 'sin' through
                                ; 'chr$' as operand is numeric.

; all the rest 'cos' through 'chr$' give a numeric result except 'str$'
; and 'chr$'.

        RES     6,C             ; signal string operand for 'code', 'val' and
                                ; 'len'.

;;; @brief ; S-NO-TO-$
;;;
;;; ; S-NO-TO-$
;;; @jumps S_PUSH_PO
;;; @jumpedfrom S_NEGATE
;;; @fallthrough S_PUSH_PO
S_NO_TO:
        CP      $EE             ; compare 'str$'
        JR      C,S_PUSH_PO         ; forward to S-PUSH-PO if lower as result
                                ; is numeric.

        RES     7,C             ; reset bit 7 of op code for 'str$', 'chr$'
                                ; as result is string.

; >> This is where they were all headed for.

;;; @brief ; S-PUSH-PO
;;;
;;; ; S-PUSH-PO
;;; @jumps S_LOOP_1
;;; @jumpedfrom S_INKEY, S_NEGATE, S_NO_TO
S_PUSH_PO:
        PUSH    BC              ; push the priority and calculator operation
                                ; code.

        RST     20H             ; NEXT-CHAR
        JP      S_LOOP_1           ; jump back to S-LOOP-1 to go round the loop
                                ; again with the next character.

; --------------------------------

; ===>  there were many branches forward to here

;   An important step after the evaluation of an expression is to test for
;   a string expression and allow it to be sliced.  If a numeric expression is
;   followed by a '(' then the numeric expression is complete.
;   Since a string slice can itself be sliced then loop repeatedly
;   e.g. (STR$ PI) (3 TO) (TO 2)    or "nonsense" (4 TO )

;;; @brief ; S-CONT-2
;;;
;;; ; S-CONT-2
;;; @jumpedfrom S_STRING, S_BRACKET, S_INK_EN, S_CONT_1, SF_SYN_EN, SF_VALUE
;;; @fallthrough S_CONT_3
S_CONT_2:
        RST     18H             ; GET-CHAR

;;; @brief ; S-CONT-3
;;;
;;; ; S-CONT-3
;;; @calls SLICING
;;; @jumps S_OPERTR, S_LOOP
S_CONT_3:
        CP      $28             ; is it '(' ?
        JR      NZ,S_OPERTR        ; forward, if not, to S-OPERTR

        BIT     6,(IY+$01)      ; test FLAGS - numeric or string result ?
        JR      NZ,S_LOOP        ; forward, if numeric, to S-LOOP

;   if a string expression preceded the '(' then slice it.

        CALL    SLICING           ; routine SLICING

        RST     20H             ; NEXT-CHAR
        JR      S_CONT_3           ; loop back to S-CONT-3

; ---------------------------

;   the branch was here when possibility of a '(' has been excluded.

;;; @brief ; S-OPERTR
;;;
;;; ; S-OPERTR
;;; @calls INDEXER
;;; @jumps S_LOOP
;;; @jumpedfrom S_CONT_3
;;; @fallthrough S_LOOP
S_OPERTR:
        LD      B,$00           ; prepare to add
        LD      C,A             ; possible operator to C
        LD      HL,TBL_OF_OPS        ; Address: $2795 - tbl-of-ops
        CALL    INDEXER           ; routine INDEXER
        JR      NC,S_LOOP        ; forward to S-LOOP if not in table

;   but if found in table the priority has to be looked up.

        LD      C,(HL)          ; operation code to C ( B is still zero )
        LD      HL,TBL_PRIORS - $C3  ; $26ED is base of table
        ADD     HL,BC           ; index into table.
        LD      B,(HL)          ; priority to B.

;;; @brief Scanning main loop
;;;
;;; the juggling act
;;;
;;; ; S-LOOP
;;; @jumps S_TIGHTER, GET_CHAR, S_STK_LST
;;; @jumpedfrom S_CONT_3, S_OPERTR, S_LOOPEND
;;; @fallthrough S_STK_LST
S_LOOP:
        POP     DE              ; fetch last priority and operation
        LD      A,D             ; priority to A
        CP      B               ; compare with this one
        JR      C,S_TIGHTER         ; forward to S-TIGHTER to execute the
                                ; last operation before this one as it has
                                ; higher priority.

; the last priority was greater or equal this one.

        AND     A               ; if it is zero then so is this
        JP      Z,GET_CHAR         ; jump to exit via get-char pointing at
                                ; next character.
                                ; This may be the character after the
                                ; expression or, if exiting a recursive call,
                                ; the next part of the expression to be
                                ; evaluated.

        PUSH    BC              ; save current priority/operation
                                ; as it has lower precedence than the one
                                ; now in DE.

; the 'USR' function is special in that it is overloaded to give two types
; of result.

        LD      HL,FLAGS        ; address FLAGS
        LD      A,E             ; new operation to A register
        CP      $ED             ; is it $C0 + 'usr-no' ($2D)  ?
        JR      NZ,S_STK_LST        ; forward to S-STK-LST if not

        BIT     6,(HL)          ; string result expected ?
                                ; (from the lower priority operand we've
                                ; just pushed on stack )
        JR      NZ,S_STK_LST        ; forward to S-STK-LST if numeric
                                ; as operand bits match.

        LD      E,$99           ; reset bit 6 and substitute $19 'usr-$'
                                ; for string operand.

;;; @brief ; S-STK-LST
;;;
;;; ; S-STK-LST
;;; @calls SYNTAX_Z
;;; @jumps S_SYNTEST, S_RUNTEST
;;; @jumpedfrom S_LOOP
S_STK_LST:
        PUSH    DE              ; now stack this priority/operation
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,S_SYNTEST         ; forward to S-SYNTEST if checking syntax.

        LD      A,E             ; fetch the operation code
        AND     $3F             ; mask off the result/operand bits to leave
                                ; a calculator literal.
        LD      B,A             ; transfer to B register

; now use the calculator to perform the single operation - operand is on
; the calculator stack.
; Note. although the calculator is performing a single operation most
; functions e.g. TAN are written using other functions and literals and
; these in turn are written using further strings of calculator literals so
; another level of magical recursion joins the juggling act for a while
; as the calculator too is calling itself.

        RST     28H             ;; FP-CALC
        DB          $3B             ;;fp-calc-2
L2758:
        DB          $38             ;;end-calc

        JR      S_RUNTEST           ; forward to S-RUNTEST

; ---

; the branch was here if checking syntax only.

;;; @brief ; S-SYNTEST
;;;
;;; ; S-SYNTEST
;;; @jumpedfrom S_STK_LST
;;; @fallthrough S_RPORT_C2
S_SYNTEST:
        LD      A,E             ; fetch the operation code to accumulator
        XOR     (IY+$01)        ; compare with bits of FLAGS
        AND     $40             ; bit 6 will be zero now if operand
                                ; matched expected result.

;;; @brief ; S-RPORT-C2
;;;
;;; ; S-RPORT-C2
;;; @jumps REPORT_C
;;; @jumpedfrom S_NOT_AND
;;; @fallthrough S_RUNTEST
S_RPORT_C2:
        JP      NZ,REPORT_C        ; to REPORT-C if mismatch
                                ; 'Nonsense in BASIC'
                                ; else continue to set flags for next

; the branch is to here in runtime after a successful operation.

;;; @brief ; S-RUNTEST
;;;
;;; ; S-RUNTEST
;;; @jumps S_LOOPEND
;;; @jumpedfrom S_STK_LST
;;; @fallthrough S_LOOPEND
S_RUNTEST:
        POP     DE              ; fetch the last operation from stack
        LD      HL,FLAGS        ; address FLAGS
        SET     6,(HL)          ; set default to numeric result in FLAGS
        BIT     7,E             ; test the operational result
        JR      NZ,S_LOOPEND        ; forward to S-LOOPEND if numeric

        RES     6,(HL)          ; reset bit 6 of FLAGS to show string result.

;;; @brief ; S-LOOPEND
;;;
;;; ; S-LOOPEND
;;; @jumps S_LOOP
;;; @jumpedfrom S_RUNTEST
S_LOOPEND:
        POP     BC              ; fetch the previous priority/operation
        JR      S_LOOP           ; back to S-LOOP to perform these

; ---

; the branch was here when a stacked priority/operator had higher priority
; than the current one.

;;; @brief ; S-TIGHTER
;;;
;;; ; S-TIGHTER
;;; @jumps S_NEXT, S_NOT_AND
;;; @jumpedfrom S_LOOP
S_TIGHTER:
        PUSH    DE              ; save high priority op on stack again
        LD      A,C             ; fetch lower priority operation code
        BIT     6,(IY+$01)      ; test FLAGS - Numeric or string result ?
        JR      NZ,S_NEXT        ; forward to S-NEXT if numeric result

; if this is lower priority yet has string then must be a comparison.
; Since these can only be evaluated in context and were defaulted to
; numeric in operator look up they must be changed to string equivalents.

        AND     $3F             ; mask to give true calculator literal
        ADD     A,$08           ; augment numeric literals to string
                                ; equivalents.
                                ; 'no-&-no'  => 'str-&-no'
                                ; 'no-l-eql' => 'str-l-eql'
                                ; 'no-gr-eq' => 'str-gr-eq'
                                ; 'nos-neql' => 'strs-neql'
                                ; 'no-grtr'  => 'str-grtr'
                                ; 'no-less'  => 'str-less'
                                ; 'nos-eql'  => 'strs-eql'
                                ; 'addition' => 'strs-add'
        LD      C,A             ; put modified comparison operator back
        CP      $10             ; is it now 'str-&-no' ?
        JR      NZ,S_NOT_AND        ; forward to S-NOT-AND  if not.

        SET     6,C             ; set numeric operand bit
        JR      S_NEXT           ; forward to S-NEXT

; ---

;;; @brief ; S-NOT-AND
;;;
;;; ; S-NOT-AND
;;; @jumps S_RPORT_C2, S_NEXT
;;; @jumpedfrom S_TIGHTER
;;; @fallthrough S_NEXT
S_NOT_AND:
        JR      C,S_RPORT_C2         ; back to S-RPORT-C2 if less
                                ; 'Nonsense in BASIC'.
                                ; e.g. a$ * b$

        CP      $17             ; is it 'strs-add' ?
        JR      Z,S_NEXT         ; forward to S-NEXT if so
                                ; (bit 6 and 7 are reset)

        SET     7,C             ; set numeric (Boolean) result for all others

;;; @brief ; S-NEXT
;;;
;;; ; S-NEXT
;;; @jumps S_LOOP_1
;;; @jumpedfrom S_TIGHTER, S_NOT_AND
S_NEXT:
        PUSH    BC              ; now save this priority/operation on stack

        RST     20H             ; NEXT-CHAR
        JP      S_LOOP_1           ; jump back to S-LOOP-1

;;; @brief Table of operators
;;;
;;; This table is used to look up the calculator literals associated with
;;; the operator character. The thirteen calculator operations $03 - $0F
;;; have bits 6 and 7 set to signify a numeric result.
;;; Some of these codes and bits may be altered later if the context suggests
;;; a string comparison or operation.
;;; that is '+', '=', '>', '<', '<=', '>=' or '<>'.
;;;
;;; ; tbl-of-ops
TBL_OF_OPS:
        DB          '+', $CF        ;        $C0 + 'addition'
        DB          '-', $C3        ;        $C0 + 'subtract'
        DB          '*', $C4        ;        $C0 + 'multiply'
        DB          '/', $C5        ;        $C0 + 'division'
        DB          '^', $C6        ;        $C0 + 'to-power'
        DB          '=', $CE        ;        $C0 + 'nos-eql'
        DB          '>', $CC        ;        $C0 + 'no-grtr'
        DB          '<', $CD        ;        $C0 + 'no-less'

        DB          $C7, $C9        ; '<='   $C0 + 'no-l-eql'
        DB          $C8, $CA        ; '>='   $C0 + 'no-gr-eql'
        DB          $C9, $CB        ; '<>'   $C0 + 'nos-neql'
        DB          $C5, $C7        ; 'OR'   $C0 + 'or'
        DB          $C6, $C8        ; 'AND'  $C0 + 'no-&-no'

        DB          $00             ; zero end-marker.


;;; @brief Table of priorities
;;;
;;; This table is indexed with the operation code obtained from the above
;;; table $C3 - $CF to obtain the priority for the respective operation.
;;;
;;; ; tbl-priors
TBL_PRIORS:
        DB          $06             ; '-'   opcode $C3
        DB          $08             ; '*'   opcode $C4
        DB          $08             ; '/'   opcode $C5
        DB          $0A             ; '^'   opcode $C6
        DB          $02             ; 'OR'  opcode $C7
        DB          $03             ; 'AND' opcode $C8
        DB          $05             ; '<='  opcode $C9
        DB          $05             ; '>='  opcode $CA
        DB          $05             ; '<>'  opcode $CB
        DB          $05             ; '>'   opcode $CC
        DB          $05             ; '<'   opcode $CD
        DB          $05             ; '='   opcode $CE
        DB          $06             ; '+'   opcode $CF

;;; @brief Scanning function (FN)
;;;
;;; This routine deals with user-defined functions.
;;; The definition can be anywhere in the program area but these are best
;;; placed near the start of the program as we shall see.
;;; The evaluation process is quite complex as the Spectrum has to parse two
;;; statements at the same time. Syntax of both has been checked previously
;;; and hidden locations have been created immediately after each argument
;;; of the DEF FN statement. Each of the arguments of the FN function is
;;; evaluated by SCANNING and placed in the hidden locations. Then the
;;; expression to the right of the DEF FN '=' is evaluated by SCANNING and for
;;; any variables encountered, a search is made in the DEF FN variable list
;;; in the program area before searching in the normal variables area.
;;;
;;; Recursion is not allowed: i.e. the definition of a function should not use
;;; the same function, either directly or indirectly ( through another function).
;;; You'll normally get error 4, ('Out of memory'), although sometimes the system
;;; will crash. - Vickers, Pitman 1984.
;;;
;;; As the definition is just an expression, there would seem to be no means
;;; of breaking out of such recursion.
;;; However, by the clever use of string expressions and VAL, such recursion is
;;; possible.
;;; e.g. DEF FN a(n) = VAL "n+FN a(n-1)+0" ((n<1) * 10 + 1 TO )
;;; will evaluate the full 11-character expression for all values where n is
;;; greater than zero but just the 11th character, "0", when n drops to zero
;;; thereby ending the recursion producing the correct result.
;;; Recursive string functions are possible using VAL$ instead of VAL and the
;;; null string as the final addend.
;;; - from a turn of the century newsgroup discussion initiated by Mike Wynne.
;;;
;;; ; S-FN-SBRN
;;; @calls SYNTAX_Z, ALPHA
;;; @jumps SF_RUN, REPORT_C, SF_BRKT_1
;;; @jumpedfrom S_FN
;;; @fallthrough SF_BRKT_1
S_FN_SBRN:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      NZ,SF_RUN        ; forward to SF-RUN in runtime


        RST     20H             ; NEXT-CHAR
        CALL    ALPHA           ; routine ALPHA check for letters A-Z a-z
        JP      NC,REPORT_C        ; jump back to REPORT-C if not
                                ; 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR
        CP      $24             ; is it '$' ?
        PUSH    AF              ; save character and flags
        JR      NZ,SF_BRKT_1        ; forward to SF-BRKT-1 with numeric function


        RST     20H             ; NEXT-CHAR

;;; @brief ; SF-BRKT-1
;;;
;;; ; SF-BRKT-1
;;; @jumps SF_RPRT_C, SF_FLAG_6
;;; @jumpedfrom S_FN_SBRN
;;; @fallthrough SF_ARGMTS
SF_BRKT_1:
        CP      $28             ; is '(' ?
        JR      NZ,SF_RPRT_C        ; forward to SF-RPRT-C if not
                                ; 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR
        CP      $29             ; is it ')' ?
        JR      Z,SF_FLAG_6         ; forward to SF-FLAG-6 if no arguments.

;;; @brief ; SF-ARGMTS
;;;
;;; ; SF-ARGMTS
;;; @calls SCANNING
;;; @jumps SF_BRKT_2
SF_ARGMTS:
        CALL    SCANNING           ; routine SCANNING checks each argument
                                ; which may be an expression.

        RST     18H             ; GET-CHAR
        CP      $2C             ; is it a ',' ?
        JR      NZ,SF_BRKT_2        ; forward if not to SF-BRKT-2 to test bracket


        RST     20H             ; NEXT-CHAR if a comma was found
        JR      SF_ARGMTS           ; back to SF-ARGMTS to parse all arguments.

; ---

;;; @brief ; SF-BRKT-2
;;;
;;; ; SF-BRKT-2
;;; @jumpedfrom SF_ARGMTS
;;; @fallthrough SF_RPRT_C
SF_BRKT_2:
        CP      $29             ; is character the closing ')' ?

;;; @brief ; SF-RPRT-C
;;;
;;; ; SF-RPRT-C
;;; @jumps REPORT_C
;;; @jumpedfrom SF_BRKT_1
;;; @fallthrough SF_FLAG_6
SF_RPRT_C:
        JP      NZ,REPORT_C        ; jump to REPORT-C
                                ; 'Nonsense in BASIC'

; at this point any optional arguments have had their syntax checked.

;;; @brief ; SF-FLAG-6
;;;
;;; ; SF-FLAG-6
;;; @jumps SF_SYN_EN
;;; @jumpedfrom SF_BRKT_1
;;; @fallthrough SF_SYN_EN
SF_FLAG_6:
        RST     20H             ; NEXT-CHAR
        LD      HL,FLAGS        ; address system variable FLAGS
        RES     6,(HL)          ; signal string result
        POP     AF              ; restore test against '$'.
        JR      Z,SF_SYN_EN         ; forward to SF-SYN-EN if string function.

        SET     6,(HL)          ; signal numeric result

;;; @brief ; SF-SYN-EN
;;;
;;; ; SF-SYN-EN
;;; @jumps S_CONT_2
;;; @jumpedfrom SF_FLAG_6
SF_SYN_EN:
        JP      S_CONT_2           ; jump back to S-CONT-2 to continue scanning.

; ---

; the branch was here in runtime.

;;; @brief ; SF-RUN
;;;
;;; ; SF-RUN
;;; @jumps SF_ARGMT1
;;; @jumpedfrom S_FN_SBRN
;;; @fallthrough SF_ARGMT1
SF_RUN:
        RST     20H             ; NEXT-CHAR fetches name
        AND     $DF             ; AND 11101111 - reset bit 5 - upper-case.
        LD      B,A             ; save in B

        RST     20H             ; NEXT-CHAR
        SUB     $24             ; subtract '$'
        LD      C,A             ; save result in C
        JR      NZ,SF_ARGMT1        ; forward if not '$' to SF-ARGMT1

        RST     20H             ; NEXT-CHAR advances to bracket

;;; @brief ; SF-ARGMT1
;;;
;;; ; SF-ARGMT1
;;; @jumpedfrom SF_RUN
;;; @fallthrough SF_FND_DF
SF_ARGMT1:
        RST     20H             ; NEXT-CHAR advances to start of argument
        PUSH    HL              ; save address
        LD      HL,(PROG)      ; fetch start of program area from PROG
        DEC     HL              ; the search starting point is the previous
                                ; location.

;;; @brief ; SF-FND-DF
;;;
;;; ; SF-FND-DF
;;; @calls LOOK_PROG
;;; @jumps SF_CP_DEF
;;; @jumpedfrom SF_NOT_FD
;;; @fallthrough REPORT_P
SF_FND_DF:
        LD      DE,$00CE        ; search is for token 'DEF FN' in E,
                                ; statement count in D.
        PUSH    BC              ; save C the string test, and B the letter.
        CALL    LOOK_PROG           ; routine LOOK-PROG will search for token.
        POP     BC              ; restore BC.
        JR      NC,SF_CP_DEF        ; forward to SF-CP-DEF if a match was found.


;;; @brief ; REPORT-P
;;;
;;; ; REPORT-P
REPORT_P:
        RST     08H             ; ERROR-1
        DB          $18             ; Error Report: FN without DEF

;;; @brief ; SF-CP-DEF
;;;
;;; ; SF-CP-DEF
;;; @calls FN_SKPOVR
;;; @jumps SF_NOT_FD, SF_VALUES
;;; @jumpedfrom SF_FND_DF
;;; @fallthrough SF_NOT_FD
SF_CP_DEF:
        PUSH    HL              ; save address of DEF FN
        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips over white-space etc.
                                ; without disturbing CH-ADD.
        AND     $DF             ; make fetched character upper-case.
        CP      B               ; compare with FN name
        JR      NZ,SF_NOT_FD        ; forward to SF-NOT-FD if no match.

; the letters match so test the type.

        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips white-space
        SUB     $24             ; subtract '$' from fetched character
        CP      C               ; compare with saved result of same operation
                                ; on FN name.
        JR      Z,SF_VALUES         ; forward to SF-VALUES with a match.

; the letters matched but one was string and the other numeric.

;;; @brief ; SF-NOT-FD
;;;
;;; ; SF-NOT-FD
;;; @calls EACH_STMT
;;; @jumps SF_FND_DF
;;; @jumpedfrom SF_CP_DEF
SF_NOT_FD:
        POP     HL              ; restore search point.
        DEC     HL              ; make location before
        LD      DE,$0200        ; the search is to be for the end of the
                                ; current definition - 2 statements forward.
        PUSH    BC              ; save the letter/type
        CALL    EACH_STMT           ; routine EACH-STMT steps past rejected
                                ; definition.
        POP     BC              ; restore letter/type
        JR      SF_FND_DF           ; back to SF-FND-DF to continue search

; ---

; Success!
; the branch was here with matching letter and numeric/string type.

;;; @brief ; SF-VALUES
;;;
;;; ; SF-VALUES
;;; @calls FN_SKPOVR
;;; @jumps SF_R_BR_2
;;; @jumpedfrom SF_CP_DEF
;;; @fallthrough SF_ARG_LP
SF_VALUES:
        AND     A               ; test A ( will be zero if string '$' - '$' )

        CALL    Z,FN_SKPOVR         ; routine FN-SKPOVR advances HL past '$'.

        POP     DE              ; discard pointer to 'DEF FN'.
        POP     DE              ; restore pointer to first FN argument.
        LD      (CH_ADD),DE      ; save in CH_ADD

        CALL    FN_SKPOVR           ; routine FN-SKPOVR advances HL past '('
        PUSH    HL              ; save start address in DEF FN  ***
        CP      $29             ; is character a ')' ?
        JR      Z,SF_R_BR_2         ; forward to SF-R-BR-2 if no arguments.

;;; @brief ; SF-ARG-LP
;;;
;;; ; SF-ARG-LP
;;; @calls FN_SKPOVR
;;; @jumps SF_ARG_VL
;;; @jumpedfrom SF_ARG_VL
;;; @fallthrough SF_ARG_VL
SF_ARG_LP:
        INC     HL              ; point to next character.
        LD      A,(HL)          ; fetch it.
        CP      $0E             ; is it the number marker
        LD      D,$40           ; signal numeric in D.
        JR      Z,SF_ARG_VL         ; forward to SF-ARG-VL if numeric.

        DEC     HL              ; back to letter
        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips any white-space
        INC     HL              ; advance past the expected '$' to
                                ; the 'hidden' marker.
        LD      D,$00           ; signal string.

;;; @brief ; SF-ARG-VL
;;;
;;; ; SF-ARG-VL
;;; @calls SCANNING, FN_SKPOVR
;;; @jumps REPORT_Q, SF_R_BR_2, SF_ARG_LP
;;; @jumpedfrom SF_ARG_LP
SF_ARG_VL:
        INC     HL              ; now address first of 5-byte location.
        PUSH    HL              ; save address in DEF FN statement
        PUSH    DE              ; save D - result type

        CALL    SCANNING           ; routine SCANNING evaluates expression in
                                ; the FN statement setting FLAGS and leaving
                                ; result as last value on calculator stack.

        POP     AF              ; restore saved result type to A

        XOR     (IY+$01)        ; xor with FLAGS
        AND     $40             ; and with 01000000 to test bit 6
        JR      NZ,REPORT_Q        ; forward to REPORT-Q if type mismatch.
                                ; 'Parameter error'

        POP     HL              ; pop the start address in DEF FN statement
        EX      DE,HL           ; transfer to DE ?? pop straight into de ?

        LD      HL,(STKEND)      ; set HL to STKEND location after value
        LD      BC,$0005        ; five bytes to move
        SBC     HL,BC           ; decrease HL by 5 to point to start.
        LD      (STKEND),HL      ; set STKEND 'removing' value from stack.

        LDIR                    ; copy value into DEF FN statement
        EX      DE,HL           ; set HL to location after value in DEF FN
        DEC     HL              ; step back one
        CALL    FN_SKPOVR           ; routine FN-SKPOVR gets next valid character
        CP      $29             ; is it ')' end of arguments ?
        JR      Z,SF_R_BR_2         ; forward to SF-R-BR-2 if so.

; a comma separator has been encountered in the DEF FN argument list.

        PUSH    HL              ; save position in DEF FN statement

        RST     18H             ; GET-CHAR from FN statement
        CP      $2C             ; is it ',' ?
        JR      NZ,REPORT_Q        ; forward to REPORT-Q if not
                                ; 'Parameter error'

        RST     20H             ; NEXT-CHAR in FN statement advances to next
                                ; argument.

        POP     HL              ; restore DEF FN pointer
        CALL    FN_SKPOVR           ; routine FN-SKPOVR advances to corresponding
                                ; argument.

        JR      SF_ARG_LP           ; back to SF-ARG-LP looping until all
                                ; arguments are passed into the DEF FN
                                ; hidden locations.

; ---

; the branch was here when all arguments passed.

;;; @brief ; SF-R-BR-2
;;;
;;; ; SF-R-BR-2
;;; @jumps SF_VALUE
;;; @jumpedfrom SF_VALUES, SF_ARG_VL
;;; @fallthrough REPORT_Q
SF_R_BR_2:
        PUSH    HL              ; save location of ')' in DEF FN

        RST     18H             ; GET-CHAR gets next character in FN
        CP      $29             ; is it a ')' also ?
        JR      Z,SF_VALUE         ; forward to SF-VALUE if so.


;;; @brief ; REPORT-Q
;;;
;;; ; REPORT-Q
;;; @jumpedfrom SF_ARG_VL
REPORT_Q:
        RST     08H             ; ERROR-1
        DB          $19             ; Error Report: Parameter error

;;; @brief ; SF-VALUE
;;;
;;; ; SF-VALUE
;;; @calls SCANNING
;;; @jumps S_CONT_2
;;; @jumpedfrom SF_R_BR_2
SF_VALUE:
        POP     DE              ; location of ')' in DEF FN to DE.
        EX      DE,HL           ; now to HL, FN ')' pointer to DE.
        LD      (CH_ADD),HL      ; initialize CH_ADD to this value.

; At this point the start of the DEF FN argument list is on the machine stack.
; We also have to consider that this defined function may form part of the
; definition of another defined function (though not itself).
; As this defined function may be part of a hierarchy of defined functions
; currently being evaluated by recursive calls to SCANNING, then we have to
; preserve the original value of DEFADD and not assume that it is zero.

        LD      HL,(DEFADD)      ; get original DEFADD address
        EX      (SP),HL         ; swap with DEF FN address on stack ***
        LD      (DEFADD),HL      ; set DEFADD to point to this argument list
                                ; during scanning.

        PUSH    DE              ; save FN ')' pointer.

        RST     20H             ; NEXT-CHAR advances past ')' in define

        RST     20H             ; NEXT-CHAR advances past '=' to expression

        CALL    SCANNING           ; routine SCANNING evaluates but searches
                                ; initially for variables at DEFADD

        POP     HL              ; pop the FN ')' pointer
        LD      (CH_ADD),HL      ; set CH_ADD to this
        POP     HL              ; pop the original DEFADD value
        LD      (DEFADD),HL      ; and re-insert into DEFADD system variable.

        RST     20H             ; NEXT-CHAR advances to character after ')'
        JP      S_CONT_2           ; to S-CONT-2 - to continue current
                                ; invocation of scanning

;;; @brief Used to parse DEF FN
;;;
;;; e.g. DEF FN     s $ ( x )     =  b     $ (  TO  x  ) : REM exaggerated
;;;
;;; This routine is used 10 times to advance along a DEF FN statement
;;; skipping spaces and colour control codes. It is similar to NEXT-CHAR
;;; which is, at the same time, used to skip along the corresponding FN function
;;; except the latter has to deal with AT and TAB characters in string
;;; expressions. These cannot occur in a program area so this routine is
;;; simpler as both colour controls and their parameters are less than space.
;;;
;;; ; FN-SKPOVR
;;; @calledby SF_CP_DEF, SF_VALUES, SF_ARG_LP, SF_ARG_VL, SFA_LOOP, SFA_CP_VR
FN_SKPOVR:
        INC     HL              ; increase pointer
        LD      A,(HL)          ; fetch addressed character
        CP      $21             ; compare with space + 1
        JR      C,FN_SKPOVR         ; back to FN-SKPOVR if less

        RET                     ; return pointing to a valid character.

;;; @brief LOOK-VARS
;;;
;;; ; LOOK-VARS
;;; @calls ALPHA, ALPHANUM
;;; @jumps REPORT_C, V_RUN_SYN, V_STR_VAR, V_TEST_FN
;;; @calledby REPORT_FA, CLASS_01, CLASS_04, S_LETTER, DIM
;;; @fallthrough V_CHAR
LOOK_VARS:
        SET     6,(IY+$01)      ; update FLAGS - presume numeric result

        RST     18H             ; GET-CHAR
        CALL    ALPHA           ; routine ALPHA tests for A-Za-z
        JP      NC,REPORT_C        ; jump to REPORT-C if not.
                                ; 'Nonsense in BASIC'

        PUSH    HL              ; save pointer to first letter       ^1
        AND     $1F             ; mask lower bits, 1 - 26 decimal     000xxxxx
        LD      C,A             ; store in C.

        RST     20H             ; NEXT-CHAR
        PUSH    HL              ; save pointer to second character   ^2
        CP      $28             ; is it '(' - an array ?
        JR      Z,V_RUN_SYN         ; forward to V-RUN/SYN if so.

        SET     6,C             ; set 6 signaling string if solitary  010
        CP      $24             ; is character a '$' ?
        JR      Z,V_STR_VAR         ; forward to V-STR-VAR

        SET     5,C             ; signal numeric                       011
        CALL    ALPHANUM           ; routine ALPHANUM sets carry if second
                                ; character is alphanumeric.
        JR      NC,V_TEST_FN        ; forward to V-TEST-FN if just one character

; It is more than one character but re-test current character so that 6 reset
; This loop renders the similar loop at V-PASS redundant.

;;; @brief ; V-CHAR
;;;
;;; ; V-CHAR
;;; @calls ALPHANUM
;;; @jumps V_RUN_SYN
V_CHAR:
        CALL    ALPHANUM           ; routine ALPHANUM
        JR      NC,V_RUN_SYN        ; to V-RUN/SYN when no more

        RES     6,C             ; make long named type                 001

        RST     20H             ; NEXT-CHAR
        JR      V_CHAR           ; loop back to V-CHAR

; ---


;;; @brief ; V-STR-VAR
;;;
;;; ; V-STR-VAR
;;; @jumpedfrom LOOK_VARS
;;; @fallthrough V_TEST_FN
V_STR_VAR:
        RST     20H             ; NEXT-CHAR advances past '$'
        RES     6,(IY+$01)      ; update FLAGS - signal string result.

;;; @brief ; V-TEST-FN
;;;
;;; ; V-TEST-FN
;;; @calls SYNTAX_Z
;;; @jumps V_RUN_SYN, STK_F_ARG
;;; @jumpedfrom LOOK_VARS
;;; @fallthrough V_RUN_SYN
V_TEST_FN:
        LD      A,($5C0C)       ; load A with DEFADD_hi
        AND     A               ; and test for zero.
        JR      Z,V_RUN_SYN         ; forward to V-RUN/SYN if a defined function
                                ; is not being evaluated.

; Note.

        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JP      NZ,STK_F_ARG        ; JUMP to STK-F-ARG in runtime and then
                                ; back to this point if no variable found.

;;; @brief ; V-RUN/SYN
;;;
;;; ; V-RUN/SYN
;;; @calls SYNTAX_Z
;;; @jumps V_RUN, V_SYNTAX
;;; @jumpedfrom LOOK_VARS, V_CHAR, V_TEST_FN, STK_F_ARG, SFA_CP_VR
V_RUN_SYN:
        LD      B,C             ; save flags in B
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      NZ,V_RUN        ; to V-RUN to look for the variable in runtime

; if checking syntax the letter is not returned

        LD      A,C             ; copy letter/flags to A
        AND     $E0             ; and with 11100000 to get rid of the letter
        SET     7,A             ; use spare bit to signal checking syntax.
        LD      C,A             ; and transfer to C.
        JR      V_SYNTAX           ; forward to V-SYNTAX

; ---

; but in runtime search for the variable.

;;; @brief ; V-RUN
;;;
;;; ; V-RUN
;;; @jumpedfrom V_RUN_SYN
;;; @fallthrough V_EACH
V_RUN:
        LD      HL,(VARS)      ; set HL to start of variables from VARS

;;; @brief ; V-EACH
;;;
;;; ; V-EACH
;;; @jumps V_80_BYTE, V_NEXT, V_FOUND_2
;;; @jumpedfrom V_NEXT
;;; @fallthrough V_MATCHES
V_EACH:
        LD      A,(HL)          ; get first character
        AND     $7F             ; and with 01111111
                                ; ignoring bit 7 which distinguishes
                                ; arrays or for/next variables.

        JR      Z,V_80_BYTE         ; to V-80-BYTE if zero as must be 10000000
                                ; the variables end-marker.

        CP      C               ; compare with supplied value.
        JR      NZ,V_NEXT        ; forward to V-NEXT if no match.

        RLA                     ; destructively test
        ADD     A,A             ; bits 5 and 6 of A
                                ; jumping if bit 5 reset or 6 set

        JP      P,V_FOUND_2         ; to V-FOUND-2  strings and arrays

        JR      C,V_FOUND_2         ; to V-FOUND-2  simple and for next

; leaving long name variables.

        POP     DE              ; pop pointer to 2nd. char
        PUSH    DE              ; save it again
        PUSH    HL              ; save variable first character pointer

;;; @brief ; V-MATCHES
;;;
;;; ; V-MATCHES
;;; @jumpedfrom V_SPACES
;;; @fallthrough V_SPACES
V_MATCHES:
        INC     HL              ; address next character in vars area

;;; @brief ; V-SPACES
;;;
;;; ; V-SPACES
;;; @calls ALPHANUM
;;; @jumps V_MATCHES, V_GET_PTR, V_FOUND_1
;;; @fallthrough V_GET_PTR
V_SPACES:
        LD      A,(DE)          ; pick up letter from prog area
        INC     DE              ; and advance address
        CP      $20             ; is it a space
        JR      Z,V_SPACES         ; back to V-SPACES until non-space

        OR      $20             ; convert to range 1 - 26.
        CP      (HL)            ; compare with addressed variables character
        JR      Z,V_MATCHES         ; loop back to V-MATCHES if a match on an
                                ; intermediate letter.

        OR      $80             ; now set bit 7 as last character of long
                                ; names are inverted.
        CP      (HL)            ; compare again
        JR      NZ,V_GET_PTR        ; forward to V-GET-PTR if no match

; but if they match check that this is also last letter in prog area

        LD      A,(DE)          ; fetch next character
        CALL    ALPHANUM           ; routine ALPHANUM sets carry if not alphanum
        JR      NC,V_FOUND_1        ; forward to V-FOUND-1 with a full match.

;;; @brief ; V-GET-PTR
;;;
;;; ; V-GET-PTR
;;; @jumpedfrom V_SPACES
;;; @fallthrough V_NEXT
V_GET_PTR:
        POP     HL              ; pop saved pointer to char 1

;;; @brief ; V-NEXT
;;;
;;; ; V-NEXT
;;; @calls NEXT_ONE
;;; @jumps V_EACH
;;; @jumpedfrom V_EACH
V_NEXT:
        PUSH    BC              ; save flags
        CALL    NEXT_ONE           ; routine NEXT-ONE gets next variable in DE
        EX      DE,HL           ; transfer to HL.
        POP     BC              ; restore the flags
        JR      V_EACH           ; loop back to V-EACH
                                ; to compare each variable

; ---

;;; @brief ; V-80-BYTE
;;;
;;; ; V-80-BYTE
;;; @jumpedfrom V_EACH
;;; @fallthrough V_SYNTAX
V_80_BYTE:
        SET     7,B             ; will signal not found

; the branch was here when checking syntax

;;; @brief ; V-SYNTAX
;;;
;;; ; V-SYNTAX
;;; @jumps V_PASS, V_END
;;; @jumpedfrom V_RUN_SYN
V_SYNTAX:
        POP     DE              ; discard the pointer to 2nd. character  v2
                                ; in BASIC line/workspace.

        RST     18H             ; GET-CHAR gets character after variable name.
        CP      $28             ; is it '(' ?
        JR      Z,V_PASS         ; forward to V-PASS
                                ; Note. could go straight to V-END ?

        SET     5,B             ; signal not an array
        JR      V_END           ; forward to V-END

; ---------------------------

; the jump was here when a long name matched and HL pointing to last character
; in variables area.

;;; @brief ; V-FOUND-1
;;;
;;; ; V-FOUND-1
;;; @jumpedfrom V_SPACES
;;; @fallthrough V_FOUND_2
V_FOUND_1:
        POP     DE              ; discard pointer to first var letter

; the jump was here with all other matches HL points to first var char.

;;; @brief ; V-FOUND-2
;;;
;;; ; V-FOUND-2
;;; @jumpedfrom V_EACH
;;; @fallthrough V_PASS
V_FOUND_2:
        POP     DE              ; discard pointer to 2nd prog char       v2
        POP     DE              ; drop pointer to 1st prog char          v1
        PUSH    HL              ; save pointer to last char in vars

        RST     18H             ; GET-CHAR

;;; @brief ; V-PASS
;;;
;;; ; V-PASS
;;; @calls ALPHANUM
;;; @jumps V_END
;;; @jumpedfrom V_SYNTAX
V_PASS:
        CALL    ALPHANUM           ; routine ALPHANUM
        JR      NC,V_END        ; forward to V-END if not

; but it never will be as we advanced past long-named variables earlier.

        RST     20H             ; NEXT-CHAR
        JR      V_PASS           ; back to V-PASS

; ---

;;; @brief ; V-END
;;;
;;; ; V-END
;;; @jumpedfrom V_SYNTAX, V_PASS
V_END:
        POP     HL              ; pop the pointer to first character in
                                ; BASIC line/workspace.
        RL      B               ; rotate the B register left
                                ; bit 7 to carry
        BIT     6,B             ; test the array indicator bit.
        RET                     ; return

;;; @brief Stack function argument
;;;
;;; This branch is taken from LOOK-VARS when a defined function is currently
;;; being evaluated.
;;; Scanning is evaluating the expression after the '=' and the variable
;;; found could be in the argument list to the left of the '=' or in the
;;; normal place after the program. Preference will be given to the former.
;;; The variable name to be matched is in C.
;;;
;;; ; STK-F-ARG
;;; @jumps V_RUN_SYN
;;; @jumpedfrom V_TEST_FN
;;; @fallthrough SFA_LOOP
STK_F_ARG:
        LD      HL,(DEFADD)      ; set HL to DEFADD
        LD      A,(HL)          ; load the first character
        CP      $29             ; is it ')' ?
        JP      Z,V_RUN_SYN         ; JUMP back to V-RUN/SYN, if so, as there are
                                ; no arguments.

; but proceed to search argument list of defined function first if not empty.

;;; @brief ; SFA-LOOP
;;;
;;; ; SFA-LOOP
;;; @calls FN_SKPOVR
;;; @jumps SFA_CP_VR
;;; @jumpedfrom SFA_CP_VR
;;; @fallthrough SFA_CP_VR
SFA_LOOP:
        LD      A,(HL)          ; fetch character again.
        OR      $60             ; or with 01100000 presume a simple variable.
        LD      B,A             ; save result in B.
        INC     HL              ; address next location.
        LD      A,(HL)          ; pick up byte.
        CP      $0E             ; is it the number marker ?
        JR      Z,SFA_CP_VR         ; forward to SFA-CP-VR if so.

; it was a string. White-space may be present but syntax has been checked.

        DEC     HL              ; point back to letter.
        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips to the '$'
        INC     HL              ; now address the hidden marker.
        RES     5,B             ; signal a string variable.

;;; @brief ; SFA-CP-VR
;;;
;;; ; SFA-CP-VR
;;; @calls FN_SKPOVR
;;; @jumps SFA_MATCH, V_RUN_SYN, SFA_LOOP
;;; @jumpedfrom SFA_LOOP
SFA_CP_VR:
        LD      A,B             ; transfer found variable letter to A.
        CP      C               ; compare with expected.
        JR      Z,SFA_MATCH         ; forward to SFA-MATCH with a match.

        INC     HL              ; step
        INC     HL              ; past
        INC     HL              ; the
        INC     HL              ; five
        INC     HL              ; bytes.

        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips to next character
        CP      $29             ; is it ')' ?
        JP      Z,V_RUN_SYN         ; jump back if so to V-RUN/SYN to look in
                                ; normal variables area.

        CALL    FN_SKPOVR           ; routine FN-SKPOVR skips past the ','
                                ; all syntax has been checked and these
                                ; things can be taken as read.
        JR      SFA_LOOP           ; back to SFA-LOOP while there are more
                                ; arguments.

; ---

;;; @brief ; SFA-MATCH
;;;
;;; ; SFA-MATCH
;;; @calls MOVE_FP
;;; @jumps SFA_END
;;; @jumpedfrom SFA_CP_VR
;;; @fallthrough SFA_END
SFA_MATCH:
        BIT     5,C             ; test if numeric
        JR      NZ,SFA_END        ; to SFA-END if so as will be stacked
                                ; by scanning

        INC     HL              ; point to start of string descriptor
        LD      DE,(STKEND)      ; set DE to STKEND
        CALL    MOVE_FP           ; routine MOVE-FP puts parameters on stack.
        EX      DE,HL           ; new free location to HL.
        LD      (STKEND),HL      ; use it to set STKEND system variable.

;;; @brief ; SFA-END
;;;
;;; ; SFA-END
;;; @jumpedfrom SFA_MATCH
SFA_END:
        POP     DE              ; discard
        POP     DE              ; pointers.
        XOR     A               ; clear carry flag.
        INC     A               ; and zero flag.
        RET                     ; return.

;;; @brief Stack variable component
;;;
;;; This is called to evaluate a complex structure that has been found, in
;;; runtime, by LOOK-VARS in the variables area.
;;; In this case HL points to the initial letter, bits 7-5
;;; of which indicate the type of variable.
;;; 010 - simple string, 110 - string array, 100 - array of numbers.
;;;
;;; It is called from CLASS-01 when assigning to a string or array including
;;; a slice.
;;; It is called from SCANNING to isolate the required part of the structure.
;;;
;;; An important part of the runtime process is to check that the number of
;;; dimensions of the variable match the number of subscripts supplied in the
;;; BASIC line.
;;;
;;; If checking syntax,
;;; the B register, which counts dimensions is set to zero (256) to allow
;;; the loop to continue till all subscripts are checked. While doing this it
;;; is reading dimension sizes from some arbitrary area of memory. Although
;;; these are meaningless it is of no concern as the limit is never checked by
;;; int-exp during syntax checking.
;;;
;;; The routine is also called from the syntax path of DIM command to check the
;;; syntax of both string and numeric arrays definitions except that bit 6 of C
;;; is reset so both are checked as numeric arrays. This ruse avoids a terminal
;;; slice being accepted as part of the DIM command.
;;; All that is being checked is that there are a valid set of comma-separated
;;; expressions before a terminal ')', although, as above, it will still go
;;; through the motions of checking dummy dimension sizes.
;;;
;;; ; STK-VAR
;;; @jumps SV_COUNT, SV_ARRAYS
;;; @calledby VAR_A_2, S_LETTER, D_RPORT_C
;;; @fallthrough SV_SIMPLE
STK_VAR:
        XOR     A               ; clear A
        LD      B,A             ; and B, the syntax dimension counter (256)
        BIT     7,C             ; checking syntax ?
        JR      NZ,SV_COUNT        ; forward to SV-COUNT if so.

; runtime evaluation.

        BIT     7,(HL)          ; will be reset if a simple string.
        JR      NZ,SV_ARRAYS        ; forward to SV-ARRAYS otherwise

        INC     A               ; set A to 1, simple string.

;;; @brief ; SV-SIMPLE$
;;;
;;; ; SV-SIMPLE$
;;; @calls STK_STO
;;; @jumps SV_SLICE_2
;;; @jumpedfrom SV_ARRAYS
SV_SIMPLE:
        INC     HL              ; address length low
        LD      C,(HL)          ; place in C
        INC     HL              ; address length high
        LD      B,(HL)          ; place in B
        INC     HL              ; address start of string
        EX      DE,HL           ; DE = start now.
        CALL    STK_STO           ; routine STK-STO-$ stacks string parameters
                                ; DE start in variables area,
                                ; BC length, A=1 simple string

; the only thing now is to consider if a slice is required.

        RST     18H             ; GET-CHAR puts character at CH_ADD in A
        JP      SV_SLICE_2           ; jump forward to SV-SLICE? to test for '('

; --------------------------------------------------------

; the branch was here with string and numeric arrays in runtime.

;;; @brief ; SV-ARRAYS
;;;
;;; ; SV-ARRAYS
;;; @jumps SV_PTR, SV_SIMPLE, REPORT_3
;;; @jumpedfrom STK_VAR
;;; @fallthrough SV_PTR
SV_ARRAYS:
        INC     HL              ; step past
        INC     HL              ; the total length
        INC     HL              ; to address Number of dimensions.
        LD      B,(HL)          ; transfer to B overwriting zero.
        BIT     6,C             ; a numeric array ?
        JR      Z,SV_PTR         ; forward to SV-PTR with numeric arrays

        DEC     B               ; ignore the final element of a string array
                                ; the fixed string size.

        JR      Z,SV_SIMPLE         ; back to SV-SIMPLE$ if result is zero as has
                                ; been created with DIM a$(10) for instance
                                ; and can be treated as a simple string.

; proceed with multi-dimensioned string arrays in runtime.

        EX      DE,HL           ; save pointer to dimensions in DE

        RST     18H             ; GET-CHAR looks at the BASIC line
        CP      $28             ; is character '(' ?
        JR      NZ,REPORT_3        ; to REPORT-3 if not
                                ; 'Subscript wrong'

        EX      DE,HL           ; dimensions pointer to HL to synchronize
                                ; with next instruction.

; runtime numeric arrays path rejoins here.

;;; @brief ; SV-PTR
;;;
;;; ; SV-PTR
;;; @jumps SV_COUNT
;;; @jumpedfrom SV_ARRAYS
SV_PTR:
        EX      DE,HL           ; save dimension pointer in DE
        JR      SV_COUNT           ; forward to SV-COUNT with true no of dims
                                ; in B. As there is no initial comma the
                                ; loop is entered at the midpoint.

; ----------------------------------------------------------
; the dimension counting loop which is entered at mid-point.

;;; @brief ; SV-COMMA
;;;
;;; ; SV-COMMA
;;; @jumps SV_LOOP, REPORT_3, SV_CLOSE, SV_RPT_C
SV_COMMA:
        PUSH    HL              ; save counter

        RST     18H             ; GET-CHAR

        POP     HL              ; pop counter
        CP      $2C             ; is character ',' ?
        JR      Z,SV_LOOP         ; forward to SV-LOOP if so

; in runtime the variable definition indicates a comma should appear here

        BIT     7,C             ; checking syntax ?
        JR      Z,REPORT_3         ; forward to REPORT-3 if not
                                ; 'Subscript error'

; proceed if checking syntax of an array?

        BIT     6,C             ; array of strings
        JR      NZ,SV_CLOSE        ; forward to SV-CLOSE if so

; an array of numbers.

        CP      $29             ; is character ')' ?
        JR      NZ,SV_RPT_C        ; forward to SV-RPT-C if not
                                ; 'Nonsense in BASIC'

        RST     20H             ; NEXT-CHAR moves CH-ADD past the statement
        RET                     ; return ->

; ---

; the branch was here with an array of strings.

;;; @brief ; SV-CLOSE
;;;
;;; ; SV-CLOSE
;;; @jumps SV_DIM, SV_RPT_C
;;; @jumpedfrom SV_COMMA
;;; @fallthrough SV_CH_ADD
SV_CLOSE:
        CP      $29             ; as above ')' could follow the expression
        JR      Z,SV_DIM         ; forward to SV-DIM if so

        CP      $CC             ; is it 'TO' ?
        JR      NZ,SV_RPT_C        ; to SV-RPT-C with anything else
                                ; 'Nonsense in BASIC'

; now backtrack CH_ADD to set up for slicing routine.
; Note. in a BASIC line we can safely backtrack to a colour parameter.

;;; @brief ; SV-CH-ADD
;;;
;;; ; SV-CH-ADD
;;; @jumps SV_SLICE
;;; @jumpedfrom SV_LOOP
SV_CH_ADD:
        RST     18H             ; GET-CHAR
        DEC     HL              ; backtrack HL
        LD      (CH_ADD),HL      ; to set CH_ADD up for slicing routine
        JR      SV_SLICE           ; forward to SV-SLICE and make a return
                                ; when all slicing complete.

; ----------------------------------------
; -> the mid-point entry point of the loop

;;; @brief ; SV-COUNT
;;;
;;; ; SV-COUNT
;;; @jumpedfrom STK_VAR, SV_PTR
;;; @fallthrough SV_LOOP
SV_COUNT:
        LD      HL,$0000        ; initialize data pointer to zero.

;;; @brief ; SV-LOOP
;;;
;;; ; SV-LOOP
;;; @jumps SV_MULT, SV_DIM, SV_CH_ADD
;;; @jumpedfrom SV_COMMA
;;; @fallthrough SV_MULT
SV_LOOP:
        PUSH    HL              ; save the data pointer.

        RST     20H             ; NEXT-CHAR in BASIC area points to an
                                ; expression.

        POP     HL              ; restore the data pointer.
        LD      A,C             ; transfer name/type to A.
        CP      $C0             ; is it 11000000 ?
                                ; Note. the letter component is absent if
                                ; syntax checking.
        JR      NZ,SV_MULT        ; forward to SV-MULT if not an array of
                                ; strings.

; proceed to check string arrays during syntax.

        RST     18H             ; GET-CHAR
        CP      $29             ; ')'  end of subscripts ?
        JR      Z,SV_DIM         ; forward to SV-DIM to consider further slice

        CP      $CC             ; is it 'TO' ?
        JR      Z,SV_CH_ADD         ; back to SV-CH-ADD to consider a slice.
                                ; (no need to repeat get-char at SV_CH_ADD)

; if neither, then an expression is required so rejoin runtime loop ??
; registers HL and DE only point to somewhere meaningful in runtime so
; comments apply to that situation.

;;; @brief ; SV-MULT
;;;
;;; ; SV-MULT
;;; @calls DE_DE_1, INT_EXP1, GET_HL_DE
;;; @jumps REPORT_3
;;; @jumpedfrom SV_LOOP
;;; @fallthrough SV_RPT_C
SV_MULT:
        PUSH    BC              ; save dimension number.
        PUSH    HL              ; push data pointer/rubbish.
                                ; DE points to current dimension.
        CALL    DE_DE_1           ; routine DE,(DE+1) gets next dimension in DE
                                ; and HL points to it.
        EX      (SP),HL         ; dim pointer to stack, data pointer to HL (*)
        EX      DE,HL           ; data pointer to DE, dim size to HL.

        CALL    INT_EXP1           ; routine INT-EXP1 checks integer expression
                                ; and gets result in BC in runtime.
        JR      C,REPORT_3         ; to REPORT-3 if > HL
                                ; 'Subscript out of range'

        DEC     BC              ; adjust returned result from 1-x to 0-x
        CALL    GET_HL_DE           ; routine GET-HL*DE multiplies data pointer by
                                ; dimension size.
        ADD     HL,BC           ; add the integer returned by expression.
        POP     DE              ; pop the dimension pointer.                              ***
        POP     BC              ; pop dimension counter.
        DJNZ    SV_COMMA           ; back to SV-COMMA if more dimensions
                                ; Note. during syntax checking, unless there
                                ; are more than 256 subscripts, the branch
                                ; back to SV-COMMA is always taken.

        BIT     7,C             ; are we checking syntax ?
                                ; then we've got a joker here.

;;; @brief ; SV-RPT-C
;;;
;;; ; SV-RPT-C
;;; @jumps SL_RPT_C, SV_ELEM, SV_NUMBER
;;; @jumpedfrom SV_COMMA, SV_CLOSE
;;; @fallthrough REPORT_3
SV_RPT_C:
        JR      NZ,SL_RPT_C        ; forward to SL-RPT-C if so
                                ; 'Nonsense in BASIC'
                                ; more than 256 subscripts in BASIC line.

; but in runtime the number of subscripts are at least the same as dims

        PUSH    HL              ; save data pointer.
        BIT     6,C             ; is it a string array ?
        JR      NZ,SV_ELEM        ; forward to SV-ELEM$ if so.

; a runtime numeric array subscript.

        LD      B,D             ; register DE has advanced past all dimensions
        LD      C,E             ; and points to start of data in variable.
                                ; transfer it to BC.

        RST     18H             ; GET-CHAR checks BASIC line
        CP      $29             ; must be a ')' ?
        JR      Z,SV_NUMBER         ; skip to SV-NUMBER if so

; else more subscripts in BASIC line than the variable definition.

;;; @brief ; REPORT-3
;;;
;;; ; REPORT-3
;;; @jumpedfrom SV_ARRAYS, SV_COMMA, SV_MULT, SV_ELEM, SL_DEFINE, D_NO_LOOP
REPORT_3:
        RST     08H             ; ERROR-1
        DB          $02             ; Error Report: Subscript wrong

; continue if subscripts matched the numeric array.

;;; @brief ; SV-NUMBER
;;;
;;; ; SV-NUMBER
;;; @calls GET_HL_DE
;;; @jumpedfrom SV_RPT_C
SV_NUMBER:
        RST     20H             ; NEXT-CHAR moves CH_ADD to next statement
                                ; - finished parsing.

        POP     HL              ; pop the data pointer.
        LD      DE,$0005        ; each numeric element is 5 bytes.
        CALL    GET_HL_DE           ; routine GET-HL*DE multiplies.
        ADD     HL,BC           ; now add to start of data in the variable.

        RET                     ; return with HL pointing at the numeric
                                ; array subscript.                       ->

; ---------------------------------------------------------------

; the branch was here for string subscripts when the number of subscripts
; in the BASIC line was one less than in variable definition.

;;; @brief ; SV-ELEM$
;;;
;;; ; SV-ELEM$
;;; @calls DE_DE_1, GET_HL_DE, STK_ST_0
;;; @jumps SV_DIM, REPORT_3
;;; @jumpedfrom SV_RPT_C
;;; @fallthrough SV_SLICE
SV_ELEM:
        CALL    DE_DE_1           ; routine DE,(DE+1) gets final dimension
                                ; the length of strings in this array.
        EX      (SP),HL         ; start pointer to stack, data pointer to HL.
        CALL    GET_HL_DE           ; routine GET-HL*DE multiplies by element
                                ; size.
        POP     BC              ; the start of data pointer is added
        ADD     HL,BC           ; in - now points to location before.
        INC     HL              ; point to start of required string.
        LD      B,D             ; transfer the length (final dimension size)
        LD      C,E             ; from DE to BC.
        EX      DE,HL           ; put start in DE.
        CALL    STK_ST_0           ; routine STK-ST-0 stores the string parameters
                                ; with A=0 - a slice or subscript.

; now check that there were no more subscripts in the BASIC line.

        RST     18H             ; GET-CHAR
        CP      $29             ; is it ')' ?
        JR      Z,SV_DIM         ; forward to SV-DIM to consider a separate
                                ; subscript or/and a slice.

        CP      $2C             ; a comma is allowed if the final subscript
                                ; is to be sliced e.g. a$(2,3,4 TO 6).
        JR      NZ,REPORT_3        ; to REPORT-3 with anything else
                                ; 'Subscript error'

;;; @brief ; SV-SLICE
;;;
;;; ; SV-SLICE
;;; @calls SLICING
;;; @jumpedfrom SV_CH_ADD, SV_SLICE_2
;;; @fallthrough SV_DIM
SV_SLICE:
        CALL    SLICING           ; routine SLICING slices the string.

; but a slice of a simple string can itself be sliced.

;;; @brief ; SV-DIM
;;;
;;; ; SV-DIM
;;; @jumpedfrom SV_CLOSE, SV_LOOP, SV_ELEM
;;; @fallthrough SV_SLICE_2
SV_DIM:
        RST     20H             ; NEXT-CHAR

;;; @brief ; SV-SLICE?
;;;
;;; ; SV-SLICE?
;;; @jumps SV_SLICE
;;; @jumpedfrom SV_SIMPLE
SV_SLICE_2:
        CP      $28             ; is character '(' ?
        JR      Z,SV_SLICE         ; loop back if so to SV-SLICE

        RES     6,(IY+$01)      ; update FLAGS  - Signal string result
        RET                     ; and return.

; ---

; The above section deals with the flexible syntax allowed.
; DIM a$(3,3,10) can be considered as two dimensional array of ten-character
; strings or a 3-dimensional array of characters.
; a$(1,1) will return a 10-character string as will a$(1,1,1 TO 10)
; a$(1,1,1) will return a single character.
; a$(1,1) (1 TO 6) is the same as a$(1,1,1 TO 6)
; A slice can itself be sliced ad infinitum
; b$ () () () () () () (2 TO 10) (2 TO 9) (3) is the same as b$(5)



;;; @brief Handle slicing of strings
;;;
;;; The syntax of string slicing is very natural and it is as well to reflect
;;; on the permutations possible.
;;; a$() and a$( TO ) indicate the entire string although just a$ would do
;;; and would avoid coming here.
;;; h$(16) indicates the single character at position 16.
;;; a$( TO 32) indicates the first 32 characters.
;;; a$(257 TO) indicates all except the first 256 characters.
;;; a$(19000 TO 19999) indicates the thousand characters at position 19000.
;;; Also a$(9 TO 5) returns a null string not an error.
;;; This enables a$(2 TO) to return a null string if the passed string is
;;; of length zero or 1.
;;; A string expression in brackets can be sliced. e.g. (STR$ PI) (3 TO )
;;; We arrived here from SCANNING with CH-ADD pointing to the initial '('
;;; or from above.
;;;
;;; ; SLICING
;;; @calls SYNTAX_Z, STK_FETCH, INT_EXP2
;;; @jumps SL_STORE, SL_SECOND
;;; @calledby S_CONT_3, SV_SLICE
;;; @fallthrough SL_RPT_C
SLICING:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        CALL    NZ,STK_FETCH        ; routine STK-FETCH fetches parameters of
                                ; string at runtime, start in DE, length
                                ; in BC. This could be an array subscript.

        RST     20H             ; NEXT-CHAR
        CP      $29             ; is it ')' ?     e.g. a$()
        JR      Z,SL_STORE         ; forward to SL-STORE to store entire string.

        PUSH    DE              ; else save start address of string

        XOR     A               ; clear accumulator to use as a running flag.
        PUSH    AF              ; and save on stack before any branching.

        PUSH    BC              ; save length of string to be sliced.
        LD      DE,$0001        ; default the start point to position 1.

        RST     18H             ; GET-CHAR

        POP     HL              ; pop length to HL as default end point
                                ; and limit.

        CP      $CC             ; is it 'TO' ?    e.g. a$( TO 10000)
        JR      Z,SL_SECOND         ; to SL-SECOND to evaluate second parameter.

        POP     AF              ; pop the running flag.

        CALL    INT_EXP2           ; routine INT-EXP2 fetches first parameter.

        PUSH    AF              ; save flag (will be $FF if parameter>limit)

        LD      D,B             ; transfer the start
        LD      E,C             ; to DE overwriting 0001.
        PUSH    HL              ; save original length.

        RST     18H             ; GET-CHAR
        POP     HL              ; pop the limit length.
        CP      $CC             ; is it 'TO' after a start ?
        JR      Z,SL_SECOND         ; to SL-SECOND to evaluate second parameter

        CP      $29             ; is it ')' ?       e.g. a$(365)

;;; @brief ; SL-RPT-C
;;;
;;; ; SL-RPT-C
;;; @jumps REPORT_C, SL_DEFINE
;;; @jumpedfrom SV_RPT_C, SL_SECOND
SL_RPT_C:
        JP      NZ,REPORT_C        ; jump to REPORT-C with anything else
                                ; 'Nonsense in BASIC'

        LD      H,D             ; copy start
        LD      L,E             ; to end - just a one character slice.
        JR      SL_DEFINE           ; forward to SL-DEFINE.

; ---------------------

;;; @brief ; SL-SECOND
;;;
;;; ; SL-SECOND
;;; @calls INT_EXP2
;;; @jumps SL_DEFINE, SL_RPT_C
;;; @jumpedfrom SLICING
;;; @fallthrough SL_DEFINE
SL_SECOND:
        PUSH    HL              ; save limit length.

        RST     20H             ; NEXT-CHAR

        POP     HL              ; pop the length.

        CP      $29             ; is character ')' ?        e.g. a$(7 TO )
        JR      Z,SL_DEFINE         ; to SL-DEFINE using length as end point.

        POP     AF              ; else restore flag.
        CALL    INT_EXP2           ; routine INT-EXP2 gets second expression.

        PUSH    AF              ; save the running flag.

        RST     18H             ; GET-CHAR

        LD      H,B             ; transfer second parameter
        LD      L,C             ; to HL.              e.g. a$(42 to 99)
        CP      $29             ; is character a ')' ?
        JR      NZ,SL_RPT_C        ; to SL-RPT-C if not
                                ; 'Nonsense in BASIC'

; we now have start in DE and an end in HL.

;;; @brief ; SL-DEFINE
;;;
;;; ; SL-DEFINE
;;; @jumps SL_OVER, REPORT_3
;;; @jumpedfrom SL_RPT_C, SL_SECOND
;;; @fallthrough SL_OVER
SL_DEFINE:
        POP     AF              ; pop the running flag.
        EX      (SP),HL         ; put end point on stack, start address to HL
        ADD     HL,DE           ; add address of string to the start point.
        DEC     HL              ; point to first character of slice.
        EX      (SP),HL         ; start address to stack, end point to HL (*)
        AND     A               ; prepare to subtract.
        SBC     HL,DE           ; subtract start point from end point.
        LD      BC,$0000        ; default the length result to zero.
        JR      C,SL_OVER         ; forward to SL-OVER if start > end.

        INC     HL              ; increment the length for inclusive byte.

        AND     A               ; now test the running flag.
        JP      M,REPORT_3         ; jump back to REPORT-3 if $FF.
                                ; 'Subscript out of range'

        LD      B,H             ; transfer the length
        LD      C,L             ; to BC.

;;; @brief ; SL-OVER
;;;
;;; ; SL-OVER
;;; @jumpedfrom SL_DEFINE
;;; @fallthrough SL_STORE
SL_OVER:
        POP     DE              ; restore start address from machine stack ***
        RES     6,(IY+$01)      ; update FLAGS - signal string result for
                                ; syntax.

;;; @brief ; SL-STORE
;;;
;;; ; SL-STORE
;;; @calls SYNTAX_Z
;;; @jumpedfrom SLICING
;;; @fallthrough STK_ST_0
SL_STORE:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z  (UNSTACK-Z?)
        RET     Z               ; return if checking syntax.
                                ; but continue to store the string in runtime.

;;; @brief other than from above, this routine is called from STK-VAR to stack a known string array element.
;;;
;;; ; STK-ST-0
;;; @calledby SV_ELEM
;;; @fallthrough STK_STO
STK_ST_0:
        XOR     A               ; clear to signal a sliced string or element.

;;; @brief this routine is called from chr$, scrn$ etc. to store a simple string result.
;;;
;;; ; STK-STO-$
;;; @calledby IN_VAR_6, S_STRING, S_IK_STK, SV_SIMPLE, STRS_ADD, CHRS, STR, READ_IN
;;; @jumpedfrom S_SCR_STO
;;; @fallthrough STK_STORE
STK_STO:
        RES     6,(IY+$01)      ; update FLAGS - signal string result.
                                ; and continue to store parameters of string.

;;; @brief Pass five registers to calculator stack
;;;
;;; This subroutine puts five registers on the calculator stack.
;;;
;;; ; STK-STORE
;;; @calls TEST_5_SP
;;; @calledby STACK_BC, LOG_2_A
STK_STORE:
        PUSH    BC              ; save two registers
        CALL    TEST_5_SP           ; routine TEST-5-SP checks room and puts 5
                                ; in BC.
        POP     BC              ; fetch the saved registers.
        LD      HL,(STKEND)      ; make HL point to first empty location STKEND
        LD      (HL),A          ; place the 5 registers.
        INC     HL              ;
        LD      (HL),E          ;
        INC     HL              ;
        LD      (HL),D          ;
        INC     HL              ;
        LD      (HL),C          ;
        INC     HL              ;
        LD      (HL),B          ;
        INC     HL              ;
        LD      (STKEND),HL      ; update system variable STKEND.
        RET                     ; and return.

;;; @brief Return result of evaluating next expression
;;;
;;; This clever routine is used to check and evaluate an integer expression
;;; which is returned in BC, setting A to $FF, if greater than a limit supplied
;;; in HL. It is used to check array subscripts, parameters of a string slice
;;; and the arguments of the DIM command. In the latter case, the limit check
;;; is not required and H is set to $FF. When checking optional string slice
;;; parameters, it is entered at the second entry point so as not to disturb
;;; the running flag A, which may be $00 or $FF from a previous invocation.
;;;
;;; ; INT-EXP1
;;; @calledby SV_MULT, D_NO_LOOP
;;; @fallthrough INT_EXP2
INT_EXP1:
        XOR     A               ; set result flag to zero.

; -> The entry point is here if A is used as a running flag.

;;; @brief ; INT-EXP2
;;;
;;; ; INT-EXP2
;;; @calls EXPT_1NUM, SYNTAX_Z, FIND_INT2
;;; @jumps I_RESTORE, I_CARRY
;;; @calledby SLICING, SL_SECOND
;;; @fallthrough I_CARRY
INT_EXP2:
        PUSH    DE              ; preserve DE register throughout.
        PUSH    HL              ; save the supplied limit.
        PUSH    AF              ; save the flag.

        CALL    EXPT_1NUM           ; routine EXPT-1NUM evaluates expression
                                ; at CH_ADD returning if numeric result,
                                ; with value on calculator stack.

        POP     AF              ; pop the flag.
        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,I_RESTORE         ; forward to I-RESTORE if checking syntax so
                                ; avoiding a comparison with supplied limit.

        PUSH    AF              ; save the flag.

        CALL    FIND_INT2           ; routine FIND-INT2 fetches value from
                                ; calculator stack to BC producing an error
                                ; if too high.

        POP     DE              ; pop the flag to D.
        LD      A,B             ; test value for zero and reject
        OR      C               ; as arrays and strings begin at 1.
        SCF                     ; set carry flag.
        JR      Z,I_CARRY         ; forward to I-CARRY if zero.

        POP     HL              ; restore the limit.
        PUSH    HL              ; and save.
        AND     A               ; prepare to subtract.
        SBC     HL,BC           ; subtract value from limit.

;;; @brief ; I-CARRY
;;;
;;; ; I-CARRY
;;; @jumpedfrom INT_EXP2
;;; @fallthrough I_RESTORE
I_CARRY:
        LD      A,D             ; move flag to accumulator $00 or $FF.
        SBC     A,$00           ; will set to $FF if carry set.

;;; @brief ; I-RESTORE
;;;
;;; ; I-RESTORE
;;; @jumpedfrom INT_EXP2
I_RESTORE:
        POP     HL              ; restore the limit.
        POP     DE              ; and DE register.
        RET                     ; return.


;;; @brief LD DE,(DE+1) Subroutine
;;;
;;; This routine just loads the DE register with the contents of the two
;;; locations following the location addressed by DE.
;;; It is used to step along the 16-bit dimension sizes in array definitions.
;;; Note. Such code is made into subroutines to make programs easier to
;;; write and it would use less space to include the five instructions in-line.
;;; However, there are so many exchanges going on at the places this is invoked
;;; that to implement it in-line would make the code hard to follow.
;;; It probably had a zippier label though as the intention is to simplify the
;;; program.
;;;
;;; ; DE,(DE+1)
;;; @calledby SV_MULT, SV_ELEM
DE_DE_1:
        EX      DE,HL           ;
        INC     HL              ;
        LD      E,(HL)          ;
        INC     HL              ;
        LD      D,(HL)          ;
        RET                     ;

;;; @brief HL=HL*DE Subroutine
;;;
;;; This routine calls the mathematical routine to multiply HL by DE in runtime.
;;; It is called from STK-VAR and from DIM. In the latter case syntax is not
;;; being checked so the entry point could have been at the second CALL
;;; instruction to save a few clock-cycles.
;;;
;;; ; GET-HL*DE
;;; @calls SYNTAX_Z, HL_HL_DE
;;; @jumps REPORT_4
;;; @calledby SV_MULT, SV_NUMBER, SV_ELEM, D_NO_LOOP
GET_HL_DE:
        CALL    SYNTAX_Z           ; routine SYNTAX-Z.
        RET     Z               ; return if checking syntax.

        CALL    HL_HL_DE           ; routine HL-HL*DE.
        JP      C,REPORT_4         ; jump back to REPORT-4 if over 65535.

        RET                     ; else return with 16-bit result in HL.

;;; @brief THE 'LET' COMMAND
;;;
;;; Sinclair BASIC adheres to the ANSI-78 standard and a LET is required in
;;; assignments e.g. LET a = 1  :   LET h$ = "hat".
;;;
;;; Long names may contain spaces but not colour controls (when assigned).
;;; a substring can appear to the left of the equals sign.
;;;
;;; An earlier mathematician Lewis Carroll may have been pleased that
;;; 10 LET Babies cannot manage crocodiles = Babies are illogical AND
;;; @verbatim
;;;    Nobody is despised who can manage a crocodile AND Illogical persons
;;;    are despised
;;; @endverbatim
;;; does not give the 'Nonsense..' error if the three variables exist.
;;; I digress.
;;;
;;; ; LET
;;; @jumps L_EXISTS
;;; @calledby F_REORDER, IN_VAR_6
;;; @jumpedfrom VAL_FET_2
;;; @fallthrough L_EACH_CH
LET:
        LD      HL,(DEST)      ; fetch system variable DEST to HL.
        BIT     1,(IY+$37)      ; test FLAGX - handling a new variable ?
        JR      Z,L_EXISTS         ; forward to L-EXISTS if not.

; continue for a new variable. DEST points to start in BASIC line.
; from the CLASS routines.

        LD      BC,$0005        ; assume numeric and assign an initial 5 bytes

;;; @brief ; L-EACH-CH
;;;
;;; ; L-EACH-CH
;;; @jumpedfrom L_TEST_CH
;;; @fallthrough L_NO_SP
L_EACH_CH:
        INC     BC              ; increase byte count for each relevant
                                ; character

;;; @brief ; L-NO-SP
;;;
;;; ; L-NO-SP
;;; @jumps L_TEST_CH, L_SPACES
L_NO_SP:
        INC     HL              ; increase pointer.
        LD      A,(HL)          ; fetch character.
        CP      $20             ; is it a space ?
        JR      Z,L_NO_SP         ; back to L-NO-SP is so.

        JR      NC,L_TEST_CH        ; forward to L-TEST-CH if higher.

        CP      $10             ; is it $00 - $0F ?
        JR      C,L_SPACES         ; forward to L-SPACES if so.

        CP      $16             ; is it $16 - $1F ?
        JR      NC,L_SPACES        ; forward to L-SPACES if so.

; it was $10 - $15  so step over a colour code.

        INC     HL              ; increase pointer.
        JR      L_NO_SP           ; loop back to L-NO-SP.

; ---

; the branch was to here if higher than space.

;;; @brief ; L-TEST-CH
;;;
;;; ; L-TEST-CH
;;; @calls ALPHANUM
;;; @jumps L_EACH_CH, L_NEW
;;; @jumpedfrom L_NO_SP
;;; @fallthrough L_SPACES
L_TEST_CH:
        CALL    ALPHANUM           ; routine ALPHANUM sets carry if alphanumeric
        JR      C,L_EACH_CH         ; loop back to L-EACH-CH for more if so.

        CP      $24             ; is it '$' ?
        JP      Z,L_NEW         ; jump forward if so, to L-NEW$
                                ; with a new string.

;;; @brief ; L-SPACES
;;;
;;; ; L-SPACES
;;; @calls MAKE_ROOM
;;; @jumps L_SINGLE
;;; @jumpedfrom L_NO_SP
;;; @fallthrough L_CHAR
L_SPACES:
        LD      A,C             ; save length lo in A.
        LD      HL,(E_LINE)      ; fetch E_LINE to HL.
        DEC     HL              ; point to location before, the variables
                                ; end-marker.
        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates BC spaces
                                ; for name and numeric value.
        INC     HL              ; advance to first new location.
        INC     HL              ; then to second.
        EX      DE,HL           ; set DE to second location.
        PUSH    DE              ; save this pointer.
        LD      HL,(DEST)      ; reload HL with DEST.
        DEC     DE              ; point to first.
        SUB     $06             ; subtract six from length_lo.
        LD      B,A             ; save count in B.
        JR      Z,L_SINGLE         ; forward to L-SINGLE if it was just
                                ; one character.

; HL points to start of variable name after 'LET' in BASIC line.

;;; @brief ; L-CHAR
;;;
;;; ; L-CHAR
;;; @fallthrough L_SINGLE
L_CHAR:
        INC     HL              ; increase pointer.
        LD      A,(HL)          ; pick up character.
        CP      $21             ; is it space or higher ?
        JR      C,L_CHAR         ; back to L-CHAR with space and less.

        OR      $20             ; make variable lower-case.
        INC     DE              ; increase destination pointer.
        LD      (DE),A          ; and load to edit line.
        DJNZ    L_CHAR           ; loop back to L-CHAR until B is zero.

        OR      $80             ; invert the last character.
        LD      (DE),A          ; and overwrite that in edit line.

; now consider first character which has bit 6 set

        LD      A,$C0           ; set A 11000000 is xor mask for a long name.
                                ; %101      is xor/or  result

; single character numerics rejoin here with %00000000 in mask.
;                                            %011      will be xor/or result

;;; @brief ; L-SINGLE
;;;
;;; ; L-SINGLE
;;; @calls L_FIRST
;;; @jumpedfrom L_SPACES
;;; @fallthrough L_NUMERIC
L_SINGLE:
        LD      HL,(DEST)      ; fetch DEST - HL addresses first character.
        XOR     (HL)            ; apply variable type indicator mask (above).
        OR      $20             ; make lowercase - set bit 5.
        POP     HL              ; restore pointer to 2nd character.
        CALL    L_FIRST           ; routine L-FIRST puts A in first character.
                                ; and returns with HL holding
                                ; new E_LINE-1  the $80 vars end-marker.

;;; @brief ; L-NUMERIC
;;;
;;; ; L-NUMERIC
;;; @jumps L_ENTER
;;; @jumpedfrom L_EXISTS
L_NUMERIC:
        PUSH    HL              ; save the pointer.

; the value of variable is deleted but remains after calculator stack.

        RST     28H             ;; FP-CALC
        DB          $02             ;;delete      ; delete variable value
        DB          $38             ;;end-calc

; DE (STKEND) points to start of value.

        POP     HL              ; restore the pointer.
        LD      BC,$0005        ; start of number is five bytes before.
        AND     A               ; prepare for true subtraction.
        SBC     HL,BC           ; HL points to start of value.
        JR      L_ENTER           ; forward to L-ENTER  ==>

; ---


; the jump was to here if the variable already existed.

;;; @brief ; L-EXISTS
;;;
;;; ; L-EXISTS
;;; @jumps L_DELETE, L_NUMERIC
;;; @jumpedfrom LET
L_EXISTS:
        BIT     6,(IY+$01)      ; test FLAGS - numeric or string result ?
        JR      Z,L_DELETE         ; skip forward to L-DELETE$   -*->
                                ; if string result.

; A numeric variable could be simple or an array element.
; They are treated the same and the old value is overwritten.

        LD      DE,$0006        ; six bytes forward points to loc past value.
        ADD     HL,DE           ; add to start of number.
        JR      L_NUMERIC           ; back to L-NUMERIC to overwrite value.

; ---

; -*-> the branch was here if a string existed.

;;; @brief ; L-DELETE$
;;;
;;; ; L-DELETE$
;;; @calls STK_FETCH
;;; @jumps L_ADD, L_LENGTH
;;; @jumpedfrom L_EXISTS
;;; @fallthrough L_LENGTH
L_DELETE:
        LD      HL,(DEST)      ; fetch DEST to HL.
                                ; (still set from first instruction)
        LD      BC,(STRLEN)      ; fetch STRLEN to BC.
        BIT     0,(IY+$37)      ; test FLAGX - handling a complete simple
                                ; string ?
        JR      NZ,L_ADD        ; forward to L-ADD$ if so.

; must be a string array or a slice in workspace.
; Note. LET a$(3 TO 6) = h$   will assign "hat " if h$ = "hat"
;                                  and    "hats" if h$ = "hatstand".
;
; This is known as Procrustean lengthening and shortening after a
; character Procrustes in Greek legend who made travellers sleep in his bed,
; cutting off their feet or stretching them so they fitted the bed perfectly.
; The bloke was hatstand and slain by Theseus.

        LD      A,B             ; test if length
        OR      C               ; is zero and
        RET     Z               ; return if so.

        PUSH    HL              ; save pointer to start.

        RST     30H             ; BC-SPACES creates room.
        PUSH    DE              ; save pointer to first new location.
        PUSH    BC              ; and length            (*)
        LD      D,H             ; set DE to point to last location.
        LD      E,L             ;
        INC     HL              ; set HL to next location.
        LD      (HL),$20        ; place a space there.
        LDDR                    ; copy bytes filling with spaces.

        PUSH    HL              ; save pointer to start.
        CALL    STK_FETCH           ; routine STK-FETCH start to DE,
                                ; length to BC.
        POP     HL              ; restore the pointer.
        EX      (SP),HL         ; (*) length to HL, pointer to stack.
        AND     A               ; prepare for true subtraction.
        SBC     HL,BC           ; subtract old length from new.
        ADD     HL,BC           ; and add back.
        JR      NC,L_LENGTH        ; forward if it fits to L-LENGTH.

        LD      B,H             ; otherwise set
        LD      C,L             ; length to old length.
                                ; "hatstand" becomes "hats"

;;; @brief ; L-LENGTH
;;;
;;; ; L-LENGTH
;;; @jumps L_IN_W_S
;;; @jumpedfrom L_DELETE
;;; @fallthrough L_IN_W_S
L_LENGTH:
        EX      (SP),HL         ; (*) length to stack, pointer to HL.
        EX      DE,HL           ; pointer to DE, start of string to HL.
        LD      A,B             ; is the length zero ?
        OR      C               ;
        JR      Z,L_IN_W_S         ; forward to L-IN-W/S if so
                                ; leaving prepared spaces.

        LDIR                    ; else copy bytes overwriting some spaces.

;;; @brief ; L-IN-W/S
;;;
;;; ; L-IN-W/S
;;; @jumpedfrom L_LENGTH
;;; @fallthrough L_ENTER
L_IN_W_S:
        POP     BC              ; pop the new length.  (*)
        POP     DE              ; pop pointer to new area.
        POP     HL              ; pop pointer to variable in assignment.
                                ; and continue copying from workspace
                                ; to variables area.

; ==> branch here from  L-NUMERIC

;;; @brief ; L-ENTER
;;;
;;; ; L-ENTER
;;; @jumpedfrom L_NUMERIC
L_ENTER:
        EX      DE,HL           ; exchange pointers HL=STKEND DE=end of vars.
        LD      A,B             ; test the length
        OR      C               ; and make a
        RET     Z               ; return if zero (strings only).

        PUSH    DE              ; save start of destination.
        LDIR                    ; copy bytes.
        POP     HL              ; address the start.
        RET                     ; and return.

; ---

; the branch was here from L-DELETE$ if an existing simple string.
; register HL addresses start of string in variables area.

;;; @brief ; L-ADD$
;;;
;;; ; L-ADD$
;;; @calls L_STRING
;;; @jumps RECLAIM_2
;;; @jumpedfrom L_DELETE
L_ADD:
        DEC     HL              ; point to high byte of length.
        DEC     HL              ; to low byte.
        DEC     HL              ; to letter.
        LD      A,(HL)          ; fetch masked letter to A.
        PUSH    HL              ; save the pointer on stack.
        PUSH    BC              ; save new length.
        CALL    L_STRING           ; routine L-STRING adds new string at end
                                ; of variables area.
                                ; if no room we still have old one.
        POP     BC              ; restore length.
        POP     HL              ; restore start.
        INC     BC              ; increase
        INC     BC              ; length by three
        INC     BC              ; to include character and length bytes.
        JP      RECLAIM_2           ; jump to indirect exit via RECLAIM-2
                                ; deleting old version and adjusting pointers.

; ---

; the jump was here with a new string variable.

;;; @brief ; L-NEW$
;;;
;;; ; L-NEW$
;;; @jumpedfrom L_TEST_CH
;;; @fallthrough L_STRING
L_NEW:
        LD      A,$DF           ; indicator mask %11011111 for
                                ;                %010xxxxx will be result
        LD      HL,(DEST)      ; address DEST first character.
        AND     (HL)            ; combine mask with character.

;;; @brief ; L-STRING
;;;
;;; ; L-STRING
;;; @calls STK_FETCH, MAKE_ROOM
;;; @calledby L_ADD
;;; @fallthrough L_FIRST
L_STRING:
        PUSH    AF              ; save first character and mask.
        CALL    STK_FETCH           ; routine STK-FETCH fetches parameters of
                                ; the string.
        EX      DE,HL           ; transfer start to HL.
        ADD     HL,BC           ; add to length.
        PUSH    BC              ; save the length.
        DEC     HL              ; point to end of string.
        LD      (DEST),HL      ; save pointer in DEST.
                                ; (updated by POINTERS if in workspace)
        INC     BC              ; extra byte for letter.
        INC     BC              ; two bytes
        INC     BC              ; for the length of string.
        LD      HL,(E_LINE)      ; address E_LINE.
        DEC     HL              ; now end of VARS area.
        CALL    MAKE_ROOM           ; routine MAKE-ROOM makes room for string.
                                ; updating pointers including DEST.
        LD      HL,(DEST)      ; pick up pointer to end of string from DEST.
        POP     BC              ; restore length from stack.
        PUSH    BC              ; and save again on stack.
        INC     BC              ; add a byte.
        LDDR                    ; copy bytes from end to start.
        EX      DE,HL           ; HL addresses length low
        INC     HL              ; increase to address high byte
        POP     BC              ; restore length to BC
        LD      (HL),B          ; insert high byte
        DEC     HL              ; address low byte location
        LD      (HL),C          ; insert that byte
        POP     AF              ; restore character and mask

;;; @brief ; L-FIRST
;;;
;;; ; L-FIRST
;;; @calledby L_SINGLE
L_FIRST:
        DEC     HL              ; address variable name
        LD      (HL),A          ; and insert character.
        LD      HL,(E_LINE)      ; load HL with E_LINE.
        DEC     HL              ; now end of VARS area.
        RET                     ; return

;;; @brief Get last value from calculator stack
;;;
;;; ; STK-FETCH
;;; @calledby L0609, OPEN_2, VAR_A_2, PR_ITEM_3, SLICING, L_DELETE, L_STRING, USR_NO, STR_NO, STRS_ADD, +3 more
STK_FETCH:
        LD      HL,(STKEND)      ; STKEND
        DEC     HL              ;
        LD      B,(HL)          ;
        DEC     HL              ;
        LD      C,(HL)          ;
        DEC     HL              ;
        LD      D,(HL)          ;
        DEC     HL              ;
        LD      E,(HL)          ;
        DEC     HL              ;
        LD      A,(HL)          ;
        LD      (STKEND),HL      ; STKEND
        RET                     ;

;;; @brief Handle DIM command
;;;
;;; e.g. DIM a(2,3,4,7): DIM a$(32) : DIM b$(20,2,768) : DIM c$(20000)
;;; the only limit to dimensions is memory so, for example,
;;; DIM a(2,2,2,2,2,2,2,2,2,2,2,2,2) is possible and creates a multi-
;;; dimensional array of zeros. String arrays are initialized to spaces.
;;; It is not possible to erase an array, but it can be re-dimensioned to
;;; a minimal size of 1, after use, to free up memory.
;;;
;;; ; DIM
;;; @calls LOOK_VARS
;;; @fallthrough D_RPORT_C
DIM:
        CALL    LOOK_VARS           ; routine LOOK-VARS

;;; @brief ; D-RPORT-C
;;;
;;; ; D-RPORT-C
;;; @calls SYNTAX_Z, STK_VAR, CHECK_END
;;; @jumps REPORT_C, D_RUN
;;; @jumpedfrom D_NO_LOOP
;;; @fallthrough D_RUN
D_RPORT_C:
        JP      NZ,REPORT_C        ; jump to REPORT-C if a long-name variable.
                                ; DIM lottery numbers(49) doesn't work.

        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      NZ,D_RUN        ; forward to D-RUN in runtime.

        RES     6,C             ; signal 'numeric' array even if string as
                                ; this simplifies the syntax checking.

        CALL    STK_VAR           ; routine STK-VAR checks syntax.
        CALL    CHECK_END           ; routine CHECK-END performs early exit ->

; the branch was here in runtime.

;;; @brief ; D-RUN
;;;
;;; ; D-RUN
;;; @calls NEXT_ONE, RECLAIM_2
;;; @jumps D_LETTER
;;; @jumpedfrom D_RPORT_C
;;; @fallthrough D_LETTER
D_RUN:
        JR      C,D_LETTER         ; skip to D-LETTER if variable did not exist.
                                ; else reclaim the old one.

        PUSH    BC              ; save type in C.
        CALL    NEXT_ONE           ; routine NEXT-ONE find following variable
                                ; or position of $80 end-marker.
        CALL    RECLAIM_2           ; routine RECLAIM-2 reclaims the
                                ; space between.
        POP     BC              ; pop the type.

;;; @brief ; D-LETTER
;;;
;;; ; D-LETTER
;;; @jumps D_SIZE
;;; @jumpedfrom D_RUN
;;; @fallthrough D_SIZE
D_LETTER:
        SET     7,C             ; signal array.
        LD      B,$00           ; initialize dimensions to zero and
        PUSH    BC              ; save with the type.
        LD      HL,$0001        ; make elements one character presuming string
        BIT     6,C             ; is it a string ?
        JR      NZ,D_SIZE        ; forward to D-SIZE if so.

        LD      L,$05           ; make elements 5 bytes as is numeric.

;;; @brief ; D-SIZE
;;;
;;; ; D-SIZE
;;; @jumpedfrom D_LETTER
;;; @fallthrough D_NO_LOOP
D_SIZE:
        EX      DE,HL           ; save the element size in DE.

; now enter a loop to parse each of the integers in the list.

;;; @brief ; D-NO-LOOP
;;;
;;; ; D-NO-LOOP
;;; @calls INT_EXP1, GET_HL_DE, MAKE_ROOM
;;; @jumps REPORT_3, D_RPORT_C, REPORT_4, DIM_CLEAR
;;; @fallthrough DIM_CLEAR
D_NO_LOOP:
        RST     20H             ; NEXT-CHAR
        LD      H,$FF           ; disable limit check by setting HL high
        CALL    INT_EXP1           ; routine INT-EXP1
        JP      C,REPORT_3         ; to REPORT-3 if > 65280 and then some
                                ; 'Subscript out of range'

        POP     HL              ; pop dimension counter, array type
        PUSH    BC              ; save dimension size                     ***
        INC     H               ; increment the dimension counter
        PUSH    HL              ; save the dimension counter
        LD      H,B             ; transfer size
        LD      L,C             ; to HL
        CALL    GET_HL_DE           ; routine GET-HL*DE multiplies dimension by
                                ; running total of size required initially
                                ; 1 or 5.
        EX      DE,HL           ; save running total in DE

        RST     18H             ; GET-CHAR
        CP      $2C             ; is it ',' ?
        JR      Z,D_NO_LOOP         ; loop back to D-NO-LOOP until all dimensions
                                ; have been considered

; when loop complete continue.

        CP      $29             ; is it ')' ?
        JR      NZ,D_RPORT_C        ; to D-RPORT-C with anything else
                                ; 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR advances to next statement/CR

        POP     BC              ; pop dimension counter/type
        LD      A,C             ; type to A

; now calculate space required for array variable

        LD      L,B             ; dimensions to L since these require 16 bits
                                ; then this value will be doubled
        LD      H,$00           ; set high byte to zero

; another four bytes are required for letter(1), total length(2), number of
; dimensions(1) but since we have yet to double allow for two

        INC     HL              ; increment
        INC     HL              ; increment

        ADD     HL,HL           ; now double giving 4 + dimensions * 2

        ADD     HL,DE           ; add to space required for array contents

        JP      C,REPORT_4         ; to REPORT-4 if > 65535
                                ; 'Out of memory'

        PUSH    DE              ; save data space
        PUSH    BC              ; save dimensions/type
        PUSH    HL              ; save total space
        LD      B,H             ; total space
        LD      C,L             ; to BC
        LD      HL,(E_LINE)      ; address E_LINE - first location after
                                ; variables area
        DEC     HL              ; point to location before - the $80 end-marker
        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates the space if
                                ; memory is available.

        INC     HL              ; point to first new location and
        LD      (HL),A          ; store letter/type

        POP     BC              ; pop total space
        DEC     BC              ; exclude name
        DEC     BC              ; exclude the 16-bit
        DEC     BC              ; counter itself
        INC     HL              ; point to next location the 16-bit counter
        LD      (HL),C          ; insert low byte
        INC     HL              ; address next
        LD      (HL),B          ; insert high byte

        POP     BC              ; pop the number of dimensions.
        LD      A,B             ; dimensions to A
        INC     HL              ; address next
        LD      (HL),A          ; and insert "No. of dims"

        LD      H,D             ; transfer DE space + 1 from make-room
        LD      L,E             ; to HL
        DEC     DE              ; set DE to next location down.
        LD      (HL),$00        ; presume numeric and insert a zero
        BIT     6,C             ; test bit 6 of C. numeric or string ?
        JR      Z,DIM_CLEAR         ; skip to DIM-CLEAR if numeric

        LD      (HL),$20        ; place a space character in HL

;;; @brief ; DIM-CLEAR
;;;
;;; ; DIM-CLEAR
;;; @jumpedfrom D_NO_LOOP
;;; @fallthrough DIM_SIZES
DIM_CLEAR:
        POP     BC              ; pop the data length

        LDDR                    ; LDDR sets to zeros or spaces

; The number of dimensions is still in A.
; A loop is now entered to insert the size of each dimension that was pushed
; during the D-NO-LOOP working downwards from position before start of data.

;;; @brief ; DIM-SIZES
;;;
;;; ; DIM-SIZES
DIM_SIZES:
        POP     BC              ; pop a dimension size                    ***
        LD      (HL),B          ; insert high byte at position
        DEC     HL              ; next location down
        LD      (HL),C          ; insert low byte
        DEC     HL              ; next location down
        DEC     A               ; decrement dimension counter
        JR      NZ,DIM_SIZES        ; back to DIM-SIZES until all done.

        RET                     ; return.

;;; @brief Check whether digit or letter
;;;
;;; This routine checks that the character in A is alphanumeric
;;; returning with carry set if so.
;;;
;;; ; ALPHANUM
;;; @calls NUMERIC
;;; @calledby S_ALPHNUM, LOOK_VARS, V_CHAR, V_SPACES, V_PASS, L_TEST_CH
;;; @fallthrough ALPHA
ALPHANUM:
        CALL    NUMERIC           ; routine NUMERIC will reset carry if so.
        CCF                     ; Complement Carry Flag
        RET     C               ; Return if numeric else continue into
                                ; next routine.

; This routine checks that the character in A is alphabetic

;;; @brief ; ALPHA
;;;
;;; ; ALPHA
;;; @calledby L1510, DEF_FN_1, DEF_FN_3, IN_ITEM_3, S_FN_SBRN, LOOK_VARS, USR_NO
;;; @jumpedfrom RTL_GLYPH_GUARD
ALPHA:
        CP      $41             ; less than 'A' ?
        CCF                     ; Complement Carry Flag
        RET     NC              ; return if so

        CP      $5B             ; less than 'Z'+1 ?
        RET     C               ; is within first range

        CP      $61             ; less than 'a' ?
        CCF                     ; Complement Carry Flag
        RET     NC              ; return if so.

        CP      $7B             ; less than 'z'+1 ?
        RET                     ; carry set if within a-z.

;;; @brief Decimal to floating point
;;;
;;; This routine finds the floating point number represented by an expression
;;; beginning with BIN, '.' or a digit.
;;; Note that BIN need not have any '0's or '1's after it.
;;; BIN is really just a notational symbol and not a function.
;;;
;;; ; DEC-TO-FP
;;; @jumps NOT_BIN
;;; @calledby L139E
;;; @fallthrough BIN_DIGIT
DEC_TO_FP:
        CP      $C4             ; 'BIN' token ?
        JR      NZ,NOT_BIN        ; to NOT-BIN if not

        LD      DE,$0000        ; initialize 16 bit buffer register.

;;; @brief ; BIN-DIGIT
;;;
;;; ; BIN-DIGIT
;;; @jumps BIN_END, REPORT_6
BIN_DIGIT:
        RST     20H             ; NEXT-CHAR
        SUB     $31             ; '1'
        ADC     A,$00           ; will be zero if '1' or '0'
                                ; carry will be set if was '0'
        JR      NZ,BIN_END        ; forward to BIN-END if result not zero

        EX      DE,HL           ; buffer to HL
        CCF                     ; Carry now set if originally '1'
        ADC     HL,HL           ; shift the carry into HL
        JP      C,REPORT_6         ; to REPORT-6 if overflow - too many digits
                                ; after first '1'. There can be an unlimited
                                ; number of leading zeros.
                                ; 'Number too big' - raise an error

        EX      DE,HL           ; save the buffer
        JR      BIN_DIGIT           ; back to BIN-DIGIT for more digits

; ---

;;; @brief ; BIN-END
;;;
;;; ; BIN-END
;;; @jumps STACK_BC
;;; @jumpedfrom BIN_DIGIT
BIN_END:
        LD      B,D             ; transfer 16 bit buffer
        LD      C,E             ; to BC register pair.
        JP      STACK_BC           ; JUMP to STACK-BC to put on calculator stack

; ---

; continue here with .1,  42, 3.14, 5., 2.3 E -4

;;; @brief ; NOT-BIN
;;;
;;; ; NOT-BIN
;;; @calls INT_TO_FP, NUMERIC
;;; @jumps DECIMAL, E_FORMAT, DEC_STO_1
;;; @jumpedfrom DEC_TO_FP
NOT_BIN:
        CP      $2E             ; '.' - leading decimal point ?
        JR      Z,DECIMAL         ; skip to DECIMAL if so.

        CALL    INT_TO_FP           ; routine INT-TO-FP to evaluate all digits
                                ; This number 'x' is placed on stack.
        CP      $2E             ; '.' - mid decimal point ?

        JR      NZ,E_FORMAT        ; to E-FORMAT if not to consider that format

        RST     20H             ; NEXT-CHAR
        CALL    NUMERIC           ; routine NUMERIC returns carry reset if 0-9

        JR      C,E_FORMAT         ; to E-FORMAT if not a digit e.g. '1.'

        JR      DEC_STO_1           ; to DEC-STO-1 to add the decimal part to 'x'

; ---

; a leading decimal point has been found in a number.

;;; @brief ; DECIMAL
;;;
;;; ; DECIMAL
;;; @calls NUMERIC
;;; @jumpedfrom NOT_BIN
;;; @fallthrough DEC_RPT_C
DECIMAL:
        RST     20H             ; NEXT-CHAR
        CALL    NUMERIC           ; routine NUMERIC will reset carry if digit

;;; @brief ; DEC-RPT-C
;;;
;;; ; DEC-RPT-C
;;; @jumps REPORT_C
;;; @jumpedfrom ST_E_PART
DEC_RPT_C:
        JP      C,REPORT_C         ; to REPORT-C if just a '.'
                                ; raise 'Nonsense in BASIC'

; since there is no leading zero put one on the calculator stack.

        RST     28H             ;; FP-CALC
        DB          $A0             ;;stk-zero  ; 0.
        DB          $38             ;;end-calc

; If rejoining from earlier there will be a value 'x' on stack.
; If continuing from above the value zero.
; Now store 1 in mem-0.
; Note. At each pass of the digit loop this will be divided by ten.

;;; @brief ; DEC-STO-1
;;;
;;; ; DEC-STO-1
;;; @jumpedfrom NOT_BIN
DEC_STO_1:
        RST     28H             ;; FP-CALC
        DB          $A1             ;;stk-one   ;x or 0,1.
        DB          $C0             ;;st-mem-0  ;x or 0,1.
        DB          $02             ;;delete    ;x or 0.
        DB          $38             ;;end-calc


;;; @brief ; NXT-DGT-1
;;;
;;; ; NXT-DGT-1
;;; @calls STK_DIGIT
;;; @jumps E_FORMAT
NXT_DGT_1:
        RST     18H             ; GET-CHAR
        CALL    STK_DIGIT           ; routine STK-DIGIT stacks single digit 'd'
        JR      C,E_FORMAT         ; exit to E-FORMAT when digits exhausted  >


        RST     28H             ;; FP-CALC   ;x or 0,d.           first pass.
        DB          $E0             ;;get-mem-0  ;x or 0,d,1.
        DB          $A4             ;;stk-ten    ;x or 0,d,1,10.
        DB          $05             ;;division   ;x or 0,d,1/10.
        DB          $C0             ;;st-mem-0   ;x or 0,d,1/10.
        DB          $04             ;;multiply   ;x or 0,d/10.
        DB          $0F             ;;addition   ;x or 0 + d/10.
        DB          $38             ;;end-calc   last value.

        RST     20H             ; NEXT-CHAR  moves to next character
        JR      NXT_DGT_1           ; back to NXT-DGT-1

; ---

; although only the first pass is shown it can be seen that at each pass
; the new less significant digit is multiplied by an increasingly smaller
; factor (1/100, 1/1000, 1/10000 ... ) before being added to the previous
; last value to form a new last value.

; Finally see if an exponent has been input.

;;; @brief ; E-FORMAT
;;;
;;; ; E-FORMAT
;;; @jumps SIGN_FLAG
;;; @jumpedfrom NOT_BIN, NXT_DGT_1
;;; @fallthrough SIGN_FLAG
E_FORMAT:
        CP      $45             ; is character 'E' ?
        JR      Z,SIGN_FLAG         ; to SIGN-FLAG if so

        CP      $5D                     ; compare A with $5D
        RET     NZ              ; return as no exponent.

;;; @brief ; SIGN-FLAG
;;;
;;; ; SIGN-FLAG
;;; @jumps SIGN_DONE, ST_E_PART
;;; @jumpedfrom E_FORMAT
;;; @fallthrough SIGN_DONE
SIGN_FLAG:
        LD      B,$FF           ; initialize temporary sign byte to $FF

        RST     20H             ; NEXT-CHAR
        CP      $2B             ; is character '+' ?
        JR      Z,SIGN_DONE         ; to SIGN-DONE

        CP      $2D             ; is character '-' ?
        JR      NZ,ST_E_PART        ; to ST-E-PART as no sign

        INC     B               ; set sign to zero

; now consider digits of exponent.
; Note. incidentally this is the only occasion in Spectrum BASIC when an
; expression may not be used when a number is expected.

;;; @brief ; SIGN-DONE
;;;
;;; ; SIGN-DONE
;;; @jumpedfrom SIGN_FLAG
;;; @fallthrough ST_E_PART
SIGN_DONE:
        RST     20H             ; NEXT-CHAR

;;; @brief ; ST-E-PART
;;;
;;; ; ST-E-PART
;;; @calls NUMERIC, INT_TO_FP, FP_TO_A
;;; @jumps DEC_RPT_C, REPORT_6, E_FP_JUMP
;;; @jumpedfrom SIGN_FLAG
;;; @fallthrough E_FP_JUMP
ST_E_PART:
        CALL    NUMERIC           ; routine NUMERIC
        JR      C,DEC_RPT_C         ; to DEC-RPT-C if not
                                ; raise 'Nonsense in BASIC'.

        PUSH    BC              ; save sign (in B)
        CALL    INT_TO_FP           ; routine INT-TO-FP places exponent on stack
        CALL    FP_TO_A           ; routine FP-TO-A  transfers it to A
        POP     BC              ; restore sign
        JP      C,REPORT_6         ; to REPORT-6 if overflow (over 255)
                                ; raise 'Number too big'.

        AND     A               ; set flags
        JP      M,REPORT_6         ; to REPORT-6 if over '127'.
                                ; raise 'Number too big'.
                                ; 127 is still way too high and it is
                                ; impossible to enter an exponent greater
                                ; than 39 from the keyboard. The error gets
                                ; raised later in E-TO-FP so two different
                                ; error messages depending how high A is.

        INC     B               ; $FF to $00 or $00 to $01 - expendable now.
        JR      Z,E_FP_JUMP         ; forward to E-FP-JUMP if exponent positive

        NEG                     ; Negate the exponent.

;;; @brief ; E-FP-JUMP
;;;
;;; ; E-FP-JUMP
;;; @jumps E_TO_FP
;;; @jumpedfrom ST_E_PART
E_FP_JUMP:
        JP      E_TO_FP           ; JUMP forward to E-TO-FP to assign to
                                ; last value x on stack x * 10 to power A
                                ; a relative jump would have done.

;;; @brief Check for valid digit
;;;
;;; This routine checks that the ASCII character in A is numeric
;;; returning with carry reset if so.
;;;
;;; ; NUMERIC
;;; @calledby L13E2, L13FC, L1543, OUT_CHAR, ALPHANUM, NOT_BIN, DECIMAL, ST_E_PART, STK_DIGIT, RTL_GLYPH_GUARD
NUMERIC:
        CP      $30             ; '0'
        RET     C               ; return if less than zero character.

        CP      $3A             ; The upper test is '9'
        CCF                     ; Complement Carry Flag
        RET                     ; Return - carry clear if character '0' - '9'

;;; @brief Stack Digit
;;;
;;; This subroutine is called from INT-TO-FP and DEC-TO-FP to stack a digit
;;; on the calculator stack.
;;;
;;; ; STK-DIGIT
;;; @calls NUMERIC
;;; @calledby NXT_DGT_1, NXT_DGT_2
;;; @fallthrough STACK_A
STK_DIGIT:
        CALL    NUMERIC           ; routine NUMERIC
        RET     C               ; return if not numeric character

        SUB     $30             ; convert from ASCII to digit

;;; @brief Stack accumulator
;;;
;;; ; STACK-A
;;; @calledby DR_PRMS, ARC_START, ARC_END, DRAW_SAVE, LN
;;; @jumpedfrom POINT_LP, S_ATTR_S, PEEK, CODE
;;; @fallthrough STACK_BC
STACK_A:
        LD      C,A             ; transfer to C
        LD      B,$00           ; and make B zero

;;; @brief Stack BC register pair
;;;
;;; ; STACK-BC
;;; @calls STK_STORE
;;; @calledby S_RND
;;; @jumpedfrom BIN_END, USR_NO, LEN
STACK_BC:
        LD      IY,ERR_NR        ; re-initialize ERR_NR

        XOR     A               ; clear to signal small integer
        LD      E,A             ; place in E for sign
        LD      D,C             ; LSB to D
        LD      C,B             ; MSB to C
        LD      B,A             ; last byte not used
        CALL    STK_STORE           ; routine STK-STORE

        RST     28H             ;; FP-CALC
        DB          $38             ;;end-calc  make HL = STKEND-5

        AND     A               ; clear carry
        RET                     ; before returning

;;; @brief Integer to floating point
;;;
;;; This routine places one or more digits found in a BASIC line
;;; on the calculator stack multiplying the previous value by ten each time
;;; before adding in the new digit to form a last value on calculator stack.
;;;
;;; ; INT-TO-FP
;;; @calledby NOT_BIN, ST_E_PART
;;; @fallthrough NXT_DGT_2
INT_TO_FP:
        PUSH    AF              ; save first character

        RST     28H             ;; FP-CALC
        DB          $A0             ;;stk-zero    ; v=0. initial value
        DB          $38             ;;end-calc

        POP     AF              ; fetch first character back.

;;; @brief ; NXT-DGT-2
;;;
;;; ; NXT-DGT-2
;;; @calls STK_DIGIT, CH_ADD_1
NXT_DGT_2:
        CALL    STK_DIGIT           ; routine STK-DIGIT puts 0-9 on stack
        RET     C               ; will return when character is not numeric >

        RST     28H             ;; FP-CALC    ; v, d.
        DB          $01             ;;exchange    ; d, v.
        DB          $A4             ;;stk-ten     ; d, v, 10.
        DB          $04             ;;multiply    ; d, v*10.
        DB          $0F             ;;addition    ; d + v*10 = newvalue
        DB          $38             ;;end-calc    ; v.

        CALL    CH_ADD_1           ; routine CH-ADD+1 get next character
        JR      NXT_DGT_2           ; back to NXT-DGT-2 to process as a digit


;*********************************
