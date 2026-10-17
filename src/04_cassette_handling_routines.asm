;;; @file 04_cassette_handling_routines.asm
;;; @brief Part 4. CASSETTE HANDLING ROUTINES

;****************************************
;** Part 4. CASSETTE HANDLING ROUTINES **
;****************************************

;   These routines begin with the service routines followed by a single
;   command entry point.
;   The first of these service routines is a curiosity.

; -----------------------
; THE 'ZX81 NAME' ROUTINE
; -----------------------
;   This routine fetches a filename in ZX81 format and is not used by the
;   cassette handling routines in this ROM.

;; zx81-name
                                ; 'Nonsense in BASIC'.


                                ; or multiple of 256!

                                ; and also clear carry.
L04AA:
        CALL    STR                   ; call STR
        CALL    STK_FETCH                   ; call STK_FETCH
        EX      DE,HL                   ; swap DE and HL
        ADD     HL,BC                   ; HL = HL + BC
        LD      B,C                     ; B = C
L04B3:
        DEC     HL                      ; HL = HL - 1
        LD      A,(HL)                  ; A = (HL)
        RST     $10                     ; restart at $10
        DJNZ    L04B3                   ; B = B - 1; loop to L04B3 while B != 0
        RET                             ; return
L04B9:
        CALL    L1510                   ; call L1510
        CALL    OUT_CHAR                   ; call OUT_CHAR
        JP      OUT_LINE4                   ; jump to OUT_LINE4

; =========================================
;
; PORT 254 ($FE)
;
;                      spk mic { border  }
;          ___ ___ ___ ___ ___ ___ ___ ___
; PORT    |   |   |   |   |   |   |   |   |
; 254     |   |   |   |   |   |   |   |   |
; $FE     |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;

;;; @brief Save header and program/data bytes
;;;
;;;   This routine saves a section of data. It is called from SA-CTRL to save the
;;;   seventeen bytes of header data. It is also the exit route from that routine
;;;   when it is set up to save the actual data.
;;;   On entry -
;;;   HL points to start of data.
;;;   IX points to descriptor.
;;;   The accumulator is set to  $00 for a header, $FF for data.
;;; @calledby SA_CONTRL
;;; @jumpedfrom SA_CONTRL
SA_BYTES:
        LD      HL,SA_LD_RET    ; address: SA/LD-RET
        PUSH    HL              ; is pushed as common exit route.
                                ; however there is only one non-terminal exit
                                ; point.

        LD      HL,$1F80        ; a timing constant H=$1F, L=$80
                                ; inner and outer loop counters
                                ; a five second lead-in is used for a header.

        BIT     7,A             ; test one bit of accumulator.
                                ; (AND A ?)
        JR      Z,SA_FLAG         ; skip to SA-FLAG if a header is being saved.

;   else is data bytes and a shorter lead-in is used.

        LD      HL,$0C98        ; another timing value H=$0C, L=$98.
                                ; a two second lead-in is used for the data.


SA_FLAG:
        EX      AF,AF'          ; save flag
        INC     DE              ; increase length by one.
        DEC     IX              ; decrease start.

        DI                      ; disable interrupts

        LD      A,$02           ; select red for border, microphone bit on.
        LD      B,A             ; also does as an initial slight counter value.

SA_LEADER:
        DJNZ    SA_LEADER           ; self loop to SA-LEADER for delay.
                                ; after initial loop, count is $A4 (or $A3)

        OUT     ($FE),A         ; output byte $02/$0D to tape port.

        XOR     $0F             ; switch from RED (mic on) to CYAN (mic off).

        LD      B,$A4           ; hold count. also timed instruction.

        DEC     L               ; originally $80 or $98.
                                ; but subsequently cycles 256 times.
        JR      NZ,SA_LEADER        ; back to SA-LEADER until L is zero.

;   the outer loop is counted by H

        DEC     B               ; decrement count
        DEC     H               ; originally  twelve or thirty-one.
        JP      P,SA_LEADER         ; back to SA-LEADER until H becomes $FF

;   now send a sync pulse. At this stage mic is off and A holds value
;   for mic on.
;   A sync pulse is much shorter than the steady pulses of the lead-in.

        LD      B,$2F           ; another short timed delay.

SA_SYNC_1:
        DJNZ    SA_SYNC_1           ; self loop to SA-SYNC-1

        OUT     ($FE),A         ; switch to mic on and red.
        LD      A,$0D           ; prepare mic off - cyan
        LD      B,$37           ; another short timed delay.

SA_SYNC_2:
        DJNZ    SA_SYNC_2           ; self loop to SA-SYNC-2

        OUT     ($FE),A         ; output mic off, cyan border.
        LD      BC,$3B0E        ; B=$3B time(*), C=$0E, YELLOW, MIC OFF.

;

        EX      AF,AF'          ; restore saved flag
                                ; which is 1st byte to be saved.

        LD      L,A             ; and transfer to L.
                                ; the initial parity is A, $FF or $00.
        JP      SA_START           ; JUMP forward to SA-START     ->
                                ; the mid entry point of loop.

; -------------------------
;   During the save loop a parity byte is maintained in H.
;   the save loop begins by testing if reduced length is zero and if so
;   the final parity byte is saved reducing count to $FFFF.

SA_LOOP:
        LD      A,D             ; fetch high byte
        OR      E               ; test against low byte.
        JR      Z,SA_PARITY         ; forward to SA-PARITY if zero.

        LD      L,(IX+$00)      ; load currently addressed byte to L.

SA_LOOP_P:
        LD      A,H             ; fetch parity byte.
        XOR     L               ; exclusive or with new byte.

; -> the mid entry point of loop.

SA_START:
        LD      H,A             ; put parity byte in H.
        LD      A,$01           ; prepare blue, mic=on.
        SCF                     ; set carry flag ready to rotate in.
        JP      SA_8_BITS           ; JUMP forward to SA-8-BITS            -8->

; ---

SA_PARITY:
        LD      L,H             ; transfer the running parity byte to L and
        JR      SA_LOOP_P           ; back to SA-LOOP-P
                                ; to output that byte before quitting normally.

; ---

;;; @brief The entry point to save yellow part of bit
;;;
;;;   The entry point to save yellow part of bit.
;;;   A bit consists of a period with mic on and blue border followed by
;;;   a period of mic off with yellow border.
;;;   Note. since the DJNZ instruction does not affect flags, the zero flag is
;;;   used to indicate which of the two passes is in effect and the carry
;;;   maintains the state of the bit to be saved.
;;; @jumpedfrom SA_BIT_1
;;; @fallthrough SA_BIT_1
SA_BIT_2:
        LD      A,C             ; fetch 'mic on and yellow' which is
                                ; held permanently in C.
        BIT     7,B             ; set the zero flag. B holds $3E.

;;; @brief The entry point to save 1 entire bit
;;;
;;;   The entry point to save 1 entire bit. For first bit B holds $3B(*).
;;;   Carry is set if saved bit is 1. zero is reset NZ on entry.
;;; @jumps SA_BIT_2
SA_BIT_1:
        DJNZ    SA_BIT_1           ; self loop for delay to SA-BIT-1

        JR      NC,SA_OUT        ; forward to SA-OUT if bit is 0.

;   but if bit is 1 then the mic state is held for longer.

        LD      B,$42           ; set timed delay. (66 decimal)

SA_SET:
        DJNZ    SA_SET           ; self loop to SA-SET
                                ; (roughly an extra 66*13 clock cycles)

SA_OUT:
        OUT     ($FE),A         ; blue and mic on OR  yellow and mic off.

        LD      B,$3E           ; set up delay
        JR      NZ,SA_BIT_2        ; back to SA-BIT-2 if zero reset NZ (first pass)

;   proceed when the blue and yellow bands have been output.

        DEC     B               ; change value $3E to $3D.
        XOR     A               ; clear carry flag (ready to rotate in).
        INC     A               ; reset zero flag i.e. NZ.

; -8->

SA_8_BITS:
        RL      L               ; rotate left through carry
                                ; C<76543210<C
        JP      NZ,SA_BIT_1        ; JUMP back to SA-BIT-1
                                ; until all 8 bits done.

;   when the initial set carry is passed out again then a byte is complete.

        DEC     DE              ; decrease length
        INC     IX              ; increase byte pointer
        LD      B,$31           ; set up timing.

        LD      A,$7F           ; test the space key and
        IN      A,($FE)         ; return to common exit (to restore border)
        RRA                     ; if a space is pressed
        RET     NC              ; return to SA/LD-RET.   - - >

;   now test if byte counter has reached $FFFF.

        LD      A,D             ; fetch high byte
        INC     A               ; increment.
        JP      NZ,SA_LOOP        ; JUMP to SA-LOOP if more bytes.

        LD      B,$3B           ; a final delay.

SA_DELAY:
        DJNZ    SA_DELAY           ; self loop to SA-DELAY

        RET                     ; return - - >

;;; @brief THE 'SAVE/LOAD RETURN' ROUTINE
;;;
;;;   The address of this routine is pushed on the stack prior to any load/save
;;;   operation and it handles normal completion with the restoration of the
;;;   border and also abnormal termination when the break key, or to be more
;;;   precise the space key is pressed during a tape operation.
;;;
;;; - - >
SA_LD_RET:
        PUSH    AF              ; preserve accumulator throughout.
        LD      A,(BORDCR)       ; fetch border colour from BORDCR.
        AND     $38             ; mask off paper bits.
        RRCA                    ; rotate
        RRCA                    ; to the
        RRCA                    ; range 0-7.

        OUT     ($FE),A         ; change the border colour.

        LD      A,$7F           ; read from port address $7FFE the
        IN      A,($FE)         ; row with the space key at outside.

        RRA                     ; test for space key pressed.
        EI                      ; enable interrupts
        JR      C,SA_LD_END         ; forward to SA/LD-END if not

REPORT_DA:
        RST     08H             ; ERROR-1
        DB          $0C             ; Error Report: BREAK - CONT repeats

; ---

SA_LD_END:
        POP     AF              ; restore the accumulator.
        RET                     ; return.

;;; @brief Load header or block of information
;;;
;;;   This routine is used to load bytes and on entry A is set to $00 for a
;;;   header or to $FF for data.  IX points to the start of receiving location
;;;   and DE holds the length of bytes to be loaded. If, on entry the carry flag
;;;   is set then data is loaded, if reset then it is verified.
;;; @calls LD_EDGE_1, LD_EDGE_2
;;; @calledby REPORT_FA, LD_BLOCK
;;; @fallthrough LD_SYNC
LD_BYTES:
        INC     D               ; reset the zero flag without disturbing carry.
        EX      AF,AF'          ; preserve entry flags.
        DEC     D               ; restore high byte of length.

        DI                      ; disable interrupts

        LD      A,$0F           ; make the border white and mic off.
        OUT     ($FE),A         ; output to port.

        LD      HL,SA_LD_RET        ; Address: SA/LD-RET
        PUSH    HL              ; is saved on stack as terminating routine.

;   the reading of the EAR bit (D6) will always be preceded by a test of the
;   space key (D0), so store the initial post-test state.

        IN      A,($FE)         ; read the ear state - bit 6.
        RRA                     ; rotate to bit 5.
        AND     $20             ; isolate this bit.
        OR      $02             ; combine with red border colour.
        LD      C,A             ; and store initial state long-term in C.
        CP      A               ; set the zero flag.

;

LD_BREAK:
        RET     NZ              ; return if at any time space is pressed.

LD_START:
        CALL    LD_EDGE_1           ; routine LD-EDGE-1
        JR      NC,LD_BREAK        ; back to LD-BREAK with time out and no
                                ; edge present on tape.

;   but continue when a transition is found on tape.

        LD      HL,$0415        ; set up 16-bit outer loop counter for
                                ; approx 1 second delay.

LD_WAIT:
        DJNZ    LD_WAIT           ; self loop to LD-WAIT (for 256 times)

        DEC     HL              ; decrease outer loop counter.
        LD      A,H             ; test for
        OR      L               ; zero.
        JR      NZ,LD_WAIT        ; back to LD-WAIT, if not zero, with zero in B.

;   continue after delay with H holding zero and B also.
;   sample 256 edges to check that we are in the middle of a lead-in section.

        CALL    LD_EDGE_2           ; routine LD-EDGE-2
        JR      NC,LD_BREAK        ; back to LD-BREAK
                                ; if no edges at all.
LD_LEADER:
        LD      B,$9C           ; set timing value.
        CALL    LD_EDGE_2           ; routine LD-EDGE-2
        JR      NC,LD_BREAK        ; back to LD-BREAK if time-out

        LD      A,$C6           ; two edges must be spaced apart.
        CP      B               ; compare
        JR      NC,LD_START        ; back to LD-START if too close together for a
                                ; lead-in.

        INC     H               ; proceed to test 256 edged sample.
        JR      NZ,LD_LEADER        ; back to LD-LEADER while more to do.

;;; @brief sample indicates we are in the middle of a two or five second lead-in
;;;
;;;   sample indicates we are in the middle of a two or five second lead-in.
;;;   Now test every edge looking for the terminal sync signal.
;;; @calls LD_EDGE_1
LD_SYNC:
        LD      B,$C9           ; initial timing value in B.
        CALL    LD_EDGE_1           ; routine LD-EDGE-1
        JR      NC,LD_BREAK        ; back to LD-BREAK with time-out.

        LD      A,B             ; fetch augmented timing value from B.
        CP      $D4             ; compare
        JR      NC,LD_SYNC        ; back to LD-SYNC if gap too big, that is,
                                ; a normal lead-in edge gap.

;   but a short gap will be the sync pulse.
;   in which case another edge should appear before B rises to $FF

        CALL    LD_EDGE_1           ; routine LD-EDGE-1
        RET     NC              ; return with time-out.

; proceed when the sync at the end of the lead-in is found.
; We are about to load data so change the border colours.

        LD      A,C             ; fetch long-term mask from C
        XOR     $03             ; and make blue/yellow.

        LD      C,A             ; store the new long-term byte.

        LD      H,$00           ; set up parity byte as zero.
        LD      B,$B0           ; timing.
        JR      LD_MARKER           ; forward to LD-MARKER
                                ; the loop mid entry point with the alternate
                                ; zero flag reset to indicate first byte
                                ; is discarded.

;;; @brief the loading loop loads each byte and is entered at the mid point
;;;
;;;   the loading loop loads each byte and is entered at the mid point.
;;; @calls LD_EDGE_2
LD_LOOP:
        EX      AF,AF'          ; restore entry flags and type in A.
        JR      NZ,LD_FLAG        ; forward to LD-FLAG if awaiting initial flag
                                ; which is to be discarded.

        JR      NC,LD_VERIFY        ; forward to LD-VERIFY if not to be loaded.

        LD      (IX+$00),L      ; place loaded byte at memory location.
        JR      LD_NEXT           ; forward to LD-NEXT

; ---

LD_FLAG:
        RL      C               ; preserve carry (verify) flag in long-term
                                ; state byte. Bit 7 can be lost.

        XOR     L               ; compare type in A with first byte in L.
        RET     NZ              ; return if no match e.g. CODE vs. DATA.

;   continue when data type matches.

        LD      A,C             ; fetch byte with stored carry
        RRA                     ; rotate it to carry flag again
        LD      C,A             ; restore long-term port state.

        INC     DE              ; increment length ??
        JR      LD_DEC           ; forward to LD-DEC.
                                ; but why not to location after ?

; ---
;   for verification the byte read from tape is compared with that in memory.

LD_VERIFY:
        LD      A,(IX+$00)      ; fetch byte from memory.
        XOR     L               ; compare with that on tape
        RET     NZ              ; return if not zero.

LD_NEXT:
        INC     IX              ; increment byte pointer.

LD_DEC:
        DEC     DE              ; decrement length.
        EX      AF,AF'          ; store the flags.
        LD      B,$B2           ; timing.

;   when starting to read 8 bits the receiving byte is marked with bit at right.
;   when this is rotated out again then 8 bits have been read.

LD_MARKER:
        LD      L,$01           ; initialize as %00000001

LD_8_BITS:
        CALL    LD_EDGE_2           ; routine LD-EDGE-2 increments B relative to
                                ; gap between 2 edges.
        RET     NC              ; return with time-out.

        LD      A,$CB           ; the comparison byte.
        CP      B               ; compare to incremented value of B.
                                ; if B is higher then bit on tape was set.
                                ; if <= then bit on tape is reset.

        RL      L               ; rotate the carry bit into L.

        LD      B,$B0           ; reset the B timer byte.
        JP      NC,LD_8_BITS        ; JUMP back to LD-8-BITS

;   when carry set then marker bit has been passed out and byte is complete.

        LD      A,H             ; fetch the running parity byte.
        XOR     L               ; include the new byte.
        LD      H,A             ; and store back in parity register.

        LD      A,D             ; check length of
        OR      E               ; expected bytes.
        JR      NZ,LD_LOOP        ; back to LD-LOOP
                                ; while there are more.

;   when all bytes loaded then parity byte should be zero.

        LD      A,H             ; fetch parity byte.
        CP      $01             ; set carry if zero.
        RET                     ; return
                                ; in no carry then error as checksum disagrees.

;;; @brief Check signal being loaded
;;;
;;;   An edge is a transition from one mic state to another.
;;;   More specifically a change in bit 6 of value input from port $FE.
;;;   Graphically it is a change of border colour, say, blue to yellow.
;;;   The first entry point looks for two adjacent edges. The second entry point
;;;   is used to find a single edge.
;;;   The B register holds a count, up to 256, within which the edge (or edges)
;;;   must be found. The gap between two edges will be more for a '1' than a '0'
;;;   so the value of B denotes the state of the bit (two edges) read from tape.
;;;
;;; ->
;;; @calls LD_EDGE_1
;;; @calledby LD_BYTES, LD_LOOP
;;; @fallthrough LD_EDGE_1
LD_EDGE_2:
        CALL    LD_EDGE_1           ; call routine LD-EDGE-1 below.
        RET     NC              ; return if space pressed or time-out.
                                ; else continue and look for another adjacent
                                ; edge which together represent a bit on the
                                ; tape.

; ->
;   this entry point is used to find a single edge from above but also
;   when detecting a read-in signal on the tape.

;;; @brief Entry point LD_EDGE_1 (no original comment).
;;; @calledby LD_BYTES, LD_SYNC, LD_EDGE_2
LD_EDGE_1:
        LD      A,$16           ; a delay value of twenty two.

LD_DELAY:
        DEC     A               ; decrement counter
        JR      NZ,LD_DELAY        ; loop back to LD-DELAY 22 times.

        AND      A              ; clear carry.

LD_SAMPLE:
        INC     B               ; increment the time-out counter.
        RET     Z               ; return with failure when $FF passed.

        LD      A,$7F           ; prepare to read keyboard and EAR port
        IN      A,($FE)         ; row $7FFE. bit 6 is EAR, bit 0 is SPACE key.
        RRA                     ; test outer key the space. (bit 6 moves to 5)
        RET     NC              ; return if space pressed.  >>>

        XOR     C               ; compare with initial long-term state.
        AND     $20             ; isolate bit 5
        JR      Z,LD_SAMPLE         ; back to LD-SAMPLE if no edge.

;   but an edge, a transition of the EAR bit, has been found so switch the
;   long-term comparison byte containing both border colour and EAR bit.

        LD      A,C             ; fetch comparison value.
        CPL                     ; switch the bits
        LD      C,A             ; and put back in C for long-term.

        AND     $07             ; isolate new colour bits.
        OR      $08             ; set bit 3 - MIC off.
        OUT     ($FE),A         ; send to port to effect the change of colour.

        SCF                     ; set carry flag signaling edge found within
                                ; time allowed.
        RET                     ; return.

;;; @brief Entry point for all tape commands
;;;
;;;   This is the single entry point for the four tape commands.
;;;   The routine first determines in what context it has been called by examining
;;;   the low byte of the Syntax table entry which was stored in T_ADDR.
;;;   Subtracting $EO (the present arrangement) gives a value of
;;;   $00 - SAVE
;;;   $01 - LOAD
;;;   $02 - VERIFY
;;;   $03 - MERGE
;;;   As with all commands the address STMT-RET is on the stack.
;;; @jumpedfrom CLASS_0B
;;; @fallthrough L0609
SAVE_ETC:
        POP     AF              ; discard address STMT-RET.
        LD      A,(T_ADDR)       ; fetch T_ADDR

;;; @brief Now reduce the low byte of the Syntax table entry to give command
;;;
;;;   Now reduce the low byte of the Syntax table entry to give command.
;;;   Note. For ZASM use SUB $E0 as next instruction.
;;; @address $0609
;;; @calls EXPT_EXP, SYNTAX_Z, STK_FETCH
;;; @fallthrough REPORT_FA
L0609:
        SUB     LOW(P_SAVE + 1 % 256) ; subtract the known offset.
                                ; ( is SUB $E0 in standard ROM )

        LD      (T_ADDR),A       ; and put back in T_ADDR as 0,1,2, or 3
                                ; for future reference.

        CALL    EXPT_EXP           ; routine EXPT-EXP checks that a string
                                ; expression follows and stacks the
                                ; parameters in run-time.

        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,SA_DATA         ; forward to SA-DATA if checking syntax.

        LD      BC,$0011        ; presume seventeen bytes for a header.
        LD      A,(T_ADDR)       ; fetch command from T_ADDR.
        AND     A               ; test for zero - SAVE.
        JR      Z,SA_SPACE         ; forward to SA-SPACE if so.

        LD      C,$22           ; else double length to thirty four.

SA_SPACE:
        RST     30H             ; BC-SPACES creates 17/34 bytes in workspace.

        PUSH    DE              ; transfer the start of new space to
        POP     IX              ; the available index register.

;   ten spaces are required for the default filename but it is simpler to
;   overwrite the first file-type indicator byte as well.

        LD      B,$0B           ; set counter to eleven.
        LD      A,$20           ; prepare a space.

SA_BLANK:
        LD      (DE),A          ; set workspace location to space.
        INC     DE              ; next location.
        DJNZ    SA_BLANK           ; loop back to SA-BLANK till all eleven done.

        LD      (IX+$01),$FF    ; set first byte of ten character filename
                                ; to $FF as a default to signal null string.

        CALL    STK_FETCH           ; routine STK-FETCH fetches the filename
                                ; parameters from the calculator stack.
                                ; length of string in BC.
                                ; start of string in DE.

        LD      HL,$FFF6        ; prepare the value minus ten.
        DEC     BC              ; decrement length.
                                ; ten becomes nine, zero becomes $FFFF.
        ADD     HL,BC           ; trial addition.
        INC     BC              ; restore true length.
        JR      NC,SA_NAME        ; forward to SA-NAME if length is one to ten.

;   the filename is more than ten characters in length or the null string.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR.
        AND     A               ; test for zero - SAVE.
        JR      NZ,SA_NULL        ; forward to SA-NULL if not the SAVE command.

;;; @brief but no more than ten characters are allowed for SAVE
;;;
;;;   but no more than ten characters are allowed for SAVE.
;;;   The first ten characters of any other command parameter are acceptable.
;;;   Weird, but necessary, if saving to sectors.
;;;   Note. the golden rule that there are no restriction on anything is broken.
;;; @calls LOOK_VARS, SYNTAX_Z, CHECK_END, PR_ST_END, USE_ZERO, EXPT_1NUM, FIND_INT2, LD_BYTES, CHAN_OPEN, PO_MSG
;;; @jumps REPORT_C, SA_CONTRL, VR_CONTRL, LD_CONTRL, ME_CONTRL
;;; @fallthrough VR_CONTRL
REPORT_FA:
        RST     08H             ; ERROR-1
        DB          $0E             ; Error Report: Invalid file name

;   continue with LOAD, MERGE, VERIFY and also SAVE within ten character limit.

SA_NULL:
        LD      A,B             ; test length of filename
        OR      C               ; for zero.
        JR      Z,SA_DATA         ; forward to SA-DATA if so using the 255
                                ; indicator followed by spaces.

        LD      BC,$000A        ; else trim length to ten.

;   other paths rejoin here with BC holding length in range 1 - 10.

SA_NAME:
        PUSH    IX              ; push start of file descriptor.
        POP     HL              ; and pop into HL.

        INC     HL              ; HL now addresses first byte of filename.
        EX      DE,HL           ; transfer destination address to DE, start
                                ; of string in command to HL.
        LDIR                    ; copy up to ten bytes
                                ; if less than ten then trailing spaces follow.

;   the case for the null string rejoins here.

SA_DATA:
        RST     18H             ; GET-CHAR
        CP      $E4             ; is character after filename the token 'DATA' ?
        JR      NZ,SA_SCR        ; forward to SA-SCR$ to consider SCREEN$ if
                                ; not.

;   continue to consider DATA.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        CP      $03             ; is it 'VERIFY' ?
        JP      Z,REPORT_C         ; jump forward to REPORT-C if so.
                                ; 'Nonsense in BASIC'
                                ; VERIFY "d" DATA is not allowed.

;   continue with SAVE, LOAD, MERGE of DATA.

        RST     20H             ; NEXT-CHAR
        CALL    LOOK_VARS           ; routine LOOK-VARS searches variables area
                                ; returning with carry reset if found or
                                ; checking syntax.
        SET     7,C             ; this converts a simple string to a
                                ; string array. The test for an array or string
                                ; comes later.
        JR      NC,SA_V_OLD        ; forward to SA-V-OLD if variable found.

        LD      HL,$0000        ; set destination to zero as not fixed.
        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        DEC     A               ; test for 1 - LOAD
        JR      Z,SA_V_NEW         ; forward to SA-V-NEW with LOAD DATA.
                                ; to load a new array.

;   otherwise the variable was not found in run-time with SAVE/MERGE.

REPORT_2A:
        RST     08H             ; ERROR-1
        DB          $01             ; Error Report: Variable not found

;   continue with SAVE/LOAD  DATA

SA_V_OLD:
        JP      NZ,REPORT_C        ; to REPORT-C if not an array variable.
                                ; or erroneously a simple string.
                                ; 'Nonsense in BASIC'


        CALL    SYNTAX_Z           ; routine SYNTAX-Z
        JR      Z,SA_DATA_1         ; forward to SA-DATA-1 if checking syntax.

        INC     HL              ; step past single character variable name.
        LD      A,(HL)          ; fetch low byte of length.
        LD      (IX+$0B),A      ; place in descriptor.
        INC     HL              ; point to high byte.
        LD      A,(HL)          ; and transfer that
        LD      (IX+$0C),A      ; to descriptor.
        INC     HL              ; increase pointer within variable.

SA_V_NEW:
        LD      (IX+$0E),C      ; place character array name in  header.
        LD      A,$01           ; default to type numeric.
        BIT     6,C             ; test result from look-vars.
        JR      Z,SA_V_TYPE         ; forward to SA-V-TYPE if numeric.

        INC     A               ; set type to 2 - string array.

SA_V_TYPE:
        LD      (IX+$00),A      ; place type 0, 1 or 2 in descriptor.

SA_DATA_1:
        EX      DE,HL           ; save var pointer in DE

        RST     20H             ; NEXT-CHAR
        CP      $29             ; is character ')' ?
        JR      NZ,SA_V_OLD        ; back if not to SA-V-OLD to report
                                ; 'Nonsense in BASIC'

        RST     20H             ; NEXT-CHAR advances character address.
        CALL    CHECK_END           ; routine CHECK-END errors if not end of
                                ; the statement.

        EX      DE,HL           ; bring back variables data pointer.
        JP      SA_ALL           ; jump forward to SA-ALL

; ---
;   the branch was here to consider a 'SCREEN$', the display file.

SA_SCR:
        CP      $AA             ; is character the token 'SCREEN$' ?
        JR      NZ,SA_CODE        ; forward to SA-CODE if not.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        CP      $03             ; is it MERGE ?
        JP       Z,REPORT_C        ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   continue with SAVE/LOAD/VERIFY SCREEN$.

        RST     20H             ; NEXT-CHAR
        CALL    CHECK_END           ; routine CHECK-END errors if not at end of
                                ; statement.

;   continue in runtime.

        LD      (IX+$0B),$00    ; set descriptor length
        LD      (IX+$0C),$1B    ; to $1b00 to include bitmaps and attributes.

        LD      HL,$4000        ; set start to display file start.
        LD      (IX+$0D),L      ; place start in
        LD      (IX+$0E),H      ; the descriptor.
        JR      SA_TYPE_3           ; forward to SA-TYPE-3

; ---
;   the branch was here to consider CODE.

SA_CODE:
        CP      $AF             ; is character the token 'CODE' ?
        JR      NZ,SA_LINE        ; forward if not to SA-LINE to consider an
                                ; auto-started BASIC program.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        CP      $03             ; is it MERGE ?
        JP      Z,REPORT_C         ; jump forward to REPORT-C if so.
                                ; 'Nonsense in BASIC'


        RST     20H             ; NEXT-CHAR advances character address.
        CALL    PR_ST_END           ; routine PR-ST-END checks if a carriage
                                ; return or ':' follows.
        JR      NZ,SA_CODE_1        ; forward to SA-CODE-1 if there are parameters.

        LD      A,(T_ADDR)       ; else fetch the command from T_ADDR.
        AND     A               ; test for zero - SAVE without a specification.
        JP      Z,REPORT_C         ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   for LOAD/VERIFY put zero on stack to signify handle at location saved from.

        CALL    USE_ZERO           ; routine USE-ZERO
        JR      SA_CODE_2           ; forward to SA-CODE-2

; ---

;   if there are more characters after CODE expect start and possibly length.

SA_CODE_1:
        CALL    EXPT_1NUM           ; routine EXPT-1NUM checks for numeric
                                ; expression and stacks it in run-time.

        RST     18H             ; GET-CHAR
        CP      $2C             ; does a comma follow ?
        JR      Z,SA_CODE_3         ; forward if so to SA-CODE-3

;   else allow saved code to be loaded to a specified address.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR.
        AND     A               ; is the command SAVE which requires length ?
        JP      Z,REPORT_C         ; jump to REPORT-C if so.
                                ; 'Nonsense in BASIC'

;   the command LOAD code may rejoin here with zero stacked as start.

SA_CODE_2:
        CALL    USE_ZERO           ; routine USE-ZERO stacks zero for length.
        JR      SA_CODE_4           ; forward to SA-CODE-4

; ---
;   the branch was here with SAVE CODE start,

SA_CODE_3:
        RST     20H             ; NEXT-CHAR advances character address.
        CALL    EXPT_1NUM           ; routine EXPT-1NUM checks for expression
                                ; and stacks in run-time.

;   paths converge here and nothing must follow.

SA_CODE_4:
        CALL    CHECK_END           ; routine CHECK-END errors with extraneous
                                ; characters and quits if checking syntax.

;   in run-time there are two 16-bit parameters on the calculator stack.

        CALL    FIND_INT2           ; routine FIND-INT2 gets length.
        LD      (IX+$0B),C      ; place length
        LD      (IX+$0C),B      ; in descriptor.
        CALL    FIND_INT2           ; routine FIND-INT2 gets start.
        LD      (IX+$0D),C      ; place start
        LD      (IX+$0E),B      ; in descriptor.
        LD      H,B             ; transfer the
        LD      L,C             ; start to HL also.

SA_TYPE_3:
        LD      (IX+$00),$03    ; place type 3 - code in descriptor.
        JR      SA_ALL           ; forward to SA-ALL.

; ---
;   the branch was here with BASIC to consider an optional auto-start line
;   number.

SA_LINE:
        CP      $CA             ; is character the token 'LINE' ?
        JR      Z,SA_LINE_1         ; forward to SA-LINE-1 if so.

;   else all possibilities have been considered and nothing must follow.

        CALL    CHECK_END           ; routine CHECK-END

;   continue in run-time to save BASIC without auto-start.

        LD      (IX+$0E),$80    ; place high line number in descriptor to
                                ; disable auto-start.
        JR      SA_TYPE_0           ; forward to SA-TYPE-0 to save program.

; ---
;   the branch was here to consider auto-start.

SA_LINE_1:
        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        AND     A               ; test for SAVE.
        JP      NZ,REPORT_C        ; jump forward to REPORT-C with anything else.
                                ; 'Nonsense in BASIC'

;

        RST     20H             ; NEXT-CHAR
        CALL    EXPT_1NUM           ; routine EXPT-1NUM checks for numeric
                                ; expression and stacks in run-time.
        CALL    CHECK_END           ; routine CHECK-END quits if syntax path.
        CALL    FIND_INT2           ; routine FIND-INT2 fetches the numeric
                                ; expression.
        LD      (IX+$0D),C      ; place the auto-start
        LD      (IX+$0E),B      ; line number in the descriptor.

;   Note. this isn't checked, but is subsequently handled by the system.
;   If the user typed 40000 instead of 4000 then it won't auto-start
;   at line 4000, or indeed, at all.

;   continue to save program and any variables.

SA_TYPE_0:
        LD      (IX+$00),$00    ; place type zero - program in descriptor.
        LD      HL,(E_LINE)      ; fetch E_LINE to HL.
        LD      DE,(PROG)      ; fetch PROG to DE.
        SCF                     ; set carry flag to calculate from end of
                                ; variables E_LINE -1.
        SBC     HL,DE           ; subtract to give total length.

        LD      (IX+$0B),L      ; place total length
        LD      (IX+$0C),H      ; in descriptor.
        LD      HL,(VARS)      ; load HL from system variable VARS
        SBC     HL,DE           ; subtract to give program length.
        LD      (IX+$0F),L      ; place length of program
        LD      (IX+$10),H      ; in the descriptor.
        EX      DE,HL           ; start to HL, length to DE.

SA_ALL:
        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        AND     A               ; test for zero - SAVE.
        JP      Z,SA_CONTRL         ; jump forward to SA-CONTRL with SAVE  ->

; ---
;   continue with LOAD, MERGE and VERIFY.

        PUSH    HL              ; save start.
        LD      BC,$0011        ; prepare to add seventeen
        ADD     IX,BC           ; to point IX at second descriptor.

LD_LOOK_H:
        PUSH    IX              ; save IX
        LD      DE,$0011        ; seventeen bytes
        XOR     A               ; reset zero flag
        SCF                     ; set carry flag
        CALL    LD_BYTES           ; routine LD-BYTES loads a header from tape
                                ; to second descriptor.
        POP     IX              ; restore IX.
        JR      NC,LD_LOOK_H        ; loop back to LD-LOOK-H until header found.

        LD      A,$FE           ; select system channel 'S'
        CALL    CHAN_OPEN           ; routine CHAN-OPEN opens it.

        LD      (IY+$52),$03    ; set SCR_CT to 3 lines.

        LD      C,$80           ; C has bit 7 set to indicate type mismatch as
                                ; a default startpoint.

        LD      A,(IX+$00)      ; fetch loaded header type to A
        CP      (IX-$11)        ; compare with expected type.
        JR      NZ,LD_TYPE        ; forward to LD-TYPE with mis-match.

        LD      C,$F6           ; set C to minus ten - will count characters
                                ; up to zero.

LD_TYPE:
        CP      $04             ; check if type in acceptable range 0 - 3.
        JR      NC,LD_LOOK_H        ; back to LD-LOOK-H with 4 and over.

;   else A indicates type 0-3.

        LD      DE,TAPE_MSG_0_END       ; DE = end marker of message 0 (messages 1-4 follow it)
        PUSH    BC              ; save BC
        CALL    PO_MSG           ; routine PO-MSG outputs relevant message.
                                ; Note. all messages have a leading newline.
        POP     BC              ; restore BC

        PUSH    IX              ; transfer IX,
        POP     DE              ; the 2nd descriptor, to DE.
        LD      HL,$FFF0        ; prepare minus seventeen.
        ADD     HL,DE           ; add to point HL to 1st descriptor.
        LD      B,$0A           ; the count will be ten characters for the
                                ; filename.

        LD      A,(HL)          ; fetch first character and test for
        INC     A               ; value 255.
        JR      NZ,LD_NAME        ; forward to LD-NAME if not the wildcard.

;   but if it is the wildcard, then add ten to C which is minus ten for a type
;   match or -128 for a type mismatch. Although characters have to be counted
;   bit 7 of C will not alter from state set here.

        LD      A,C             ; transfer $F6 or $80 to A
        ADD     A,B             ; add $0A
        LD      C,A             ; place result, zero or -118, in C.

;   At this point we have either a type mismatch, a wildcard match or ten
;   characters to be counted. The characters must be shown on the screen.

LD_NAME:
        INC     DE              ; address next input character
        LD      A,(DE)          ; fetch character
        CP      (HL)            ; compare to expected
        INC     HL              ; address next expected character
        JR      NZ,LD_CH_PR        ; forward to LD-CH-PR with mismatch

        INC     C               ; increment matched character count

LD_CH_PR:
        RST     10H             ; PRINT-A prints character
        DJNZ    LD_NAME           ; loop back to LD-NAME for ten characters.

;   if ten characters matched and the types previously matched then C will
;   now hold zero.

        BIT     7,C             ; test if all matched
        JR      NZ,LD_LOOK_H        ; back to LD-LOOK-H if not

;   else print a terminal carriage return.

        LD      A,$0D           ; prepare carriage return.
        RST     10H             ; PRINT-A outputs it.

;   The various control routines for LOAD, VERIFY and MERGE are executed
;   during the one-second gap following the header on tape.

        POP     HL              ; restore xx
        LD      A,(IX+$00)      ; fetch incoming type
        CP      $03             ; compare with CODE
        JR      Z,VR_CONTRL         ; forward to VR-CONTRL if it is CODE.

;  type is a program or an array.

        LD      A,(T_ADDR)       ; fetch command from T_ADDR
        DEC     A               ; was it LOAD ?
        JP      Z,LD_CONTRL         ; JUMP forward to LD-CONTRL if so to
                                ; load BASIC or variables.

        CP      $02             ; was command MERGE ?
        JP      Z,ME_CONTRL         ; jump forward to ME-CONTRL if so.

;   else continue into VERIFY control routine to verify.

;;; @brief THE 'VERIFY CONTROL' ROUTINE
;;;
;;;   There are two branches to this routine.
;;;   1) From above to verify a program or array
;;;   2) from earlier with no carry to load or verify code.
;;; @jumpedfrom REPORT_FA
;;; @fallthrough LD_BLOCK
VR_CONTRL:
        PUSH    HL              ; save pointer to data.
        LD      L,(IX-$06)      ; fetch length of old data
        LD      H,(IX-$05)      ; to HL.
        LD      E,(IX+$0B)      ; fetch length of new data
        LD      D,(IX+$0C)      ; to DE.
        LD      A,H             ; check length of old
        OR      L               ; for zero.
        JR      Z,VR_CONT_1         ; forward to VR-CONT-1 if length unspecified
                                ; e.g. LOAD "x" CODE

;   as opposed to, say, LOAD 'x' CODE 32768,300.

        SBC     HL,DE           ; subtract the two lengths.
        JR      C,REPORT_R         ; forward to REPORT-R if the length on tape is
                                ; larger than that specified in command.
                                ; 'Tape loading error'

        JR      Z,VR_CONT_1         ; forward to VR-CONT-1 if lengths match.

;   a length on tape shorter than expected is not allowed for CODE

        LD      A,(IX+$00)      ; else fetch type from tape.
        CP      $03             ; is it CODE ?
        JR      NZ,REPORT_R        ; forward to REPORT-R if so
                                ; 'Tape loading error'

VR_CONT_1:
        POP     HL              ; pop pointer to data
        LD      A,H             ; test for zero
        OR      L               ; e.g. LOAD 'x' CODE
        JR      NZ,VR_CONT_2        ; forward to VR-CONT-2 if destination specified.

        LD      L,(IX+$0D)      ; else use the destination in the header
        LD      H,(IX+$0E)      ; and load code at address saved from.

VR_CONT_2:
        PUSH    HL              ; push pointer to start of data block.
        POP     IX              ; transfer to IX.
        LD      A,(T_ADDR)       ; fetch reduced command from T_ADDR
        CP      $02             ; is it VERIFY ?
        SCF                     ; prepare a set carry flag
        JR      NZ,VR_CONT_3        ; skip to VR-CONT-3 if not

        AND     A               ; clear carry flag for VERIFY so that
                                ; data is not loaded.

VR_CONT_3:
        LD      A,$FF           ; signal data block to be loaded

;;; @brief Load a data block
;;;
;;;   This routine is called from 3 places other than above to load a data block.
;;;   In all cases the accumulator is first set to $FF so the routine could be
;;;   called at the previous instruction.
;;; @calls LD_BYTES
;;; @calledby ME_CONTRL
;;; @jumpedfrom LD_CONTRL
LD_BLOCK:
        CALL    LD_BYTES           ; routine LD-BYTES
        RET     C               ; return if successful.

REPORT_R:
        RST     08H             ; ERROR-1
        DB          $1A             ; Error Report: Tape loading error

;;; @brief THE 'LOAD CONTROL' ROUTINE
;;;
;;;   This branch is taken when the command is LOAD with type 0, 1 or 2.
;;; @calls TEST_ROOM, RECLAIM_2, MAKE_ROOM, RECLAIM_1
;;; @jumps LD_BLOCK
;;; @jumpedfrom REPORT_FA
LD_CONTRL:
        LD      E,(IX+$0B)      ; fetch length of found data block
        LD      D,(IX+$0C)      ; from 2nd descriptor.
        PUSH    HL              ; save destination
        LD      A,H             ; test for zero
        OR      L               ;
        JR      NZ,LD_CONT_1        ; forward if not to LD-CONT-1

        INC     DE              ; increase length
        INC     DE              ; for letter name
        INC     DE              ; and 16-bit length
        EX      DE,HL           ; length to HL,
        JR      LD_CONT_2           ; forward to LD-CONT-2

; ---

LD_CONT_1:
        LD      L,(IX-$06)      ; fetch length from
        LD      H,(IX-$05)      ; the first header.
        EX      DE,HL           ;
        SCF                     ; set carry flag
        SBC     HL,DE           ;
        JR      C,LD_DATA         ; to LD-DATA

LD_CONT_2:
        LD      DE,$0005        ; allow overhead of five bytes.
        ADD     HL,DE           ; add in the difference in data lengths.
        LD      B,H             ; transfer to
        LD      C,L             ; the BC register pair
        CALL    TEST_ROOM           ; routine TEST-ROOM fails if not enough room.

LD_DATA:
        POP     HL              ; pop destination
        LD      A,(IX+$00)      ; fetch type 0, 1 or 2.
        AND     A               ; test for program and variables.
        JR      Z,LD_PROG         ; forward if so to LD-PROG

;   the type is a numeric or string array.

        LD      A,H             ; test the destination for zero
        OR      L               ; indicating variable does not already exist.
        JR      Z,LD_DATA_1         ; forward if so to LD-DATA-1

;   else the destination is the first dimension within the array structure

        DEC     HL              ; address high byte of total length
        LD      B,(HL)          ; transfer to B.
        DEC     HL              ; address low byte of total length.
        LD      C,(HL)          ; transfer to C.
        DEC     HL              ; point to letter of variable.
        INC     BC              ; adjust length to
        INC     BC              ; include these
        INC     BC              ; three bytes also.
        LD      (X_PTR),IX      ; save header pointer in X_PTR.
        CALL    RECLAIM_2           ; routine RECLAIM-2 reclaims the old variable
                                ; sliding workspace including the two headers
                                ; downwards.
        LD      IX,(X_PTR)      ; reload IX from X_PTR which will have been
                                ; adjusted down by POINTERS routine.

LD_DATA_1:
        LD      HL,(E_LINE)      ; address E_LINE
        DEC     HL              ; now point to the $80 variables end-marker.
        LD      C,(IX+$0B)      ; fetch new data length
        LD      B,(IX+$0C)      ; from 2nd header.
        PUSH    BC              ; * save it.
        INC     BC              ; adjust the
        INC     BC              ; length to include
        INC     BC              ; letter name and total length.
        LD      A,(IX-$03)      ; fetch letter name from old header.
        PUSH    AF              ; preserve accumulator though not corrupted.

        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates space for variable
                                ; sliding workspace up. IX no longer addresses
                                ; anywhere meaningful.
        INC     HL              ; point to first new location.

        POP     AF              ; fetch back the letter name.
        LD      (HL),A          ; place in first new location.
        POP     DE              ; * pop the data length.
        INC     HL              ; address 2nd location
        LD      (HL),E          ; store low byte of length.
        INC     HL              ; address next.
        LD      (HL),D          ; store high byte.
        INC     HL              ; address start of data.
        PUSH    HL              ; transfer address
        POP     IX              ; to IX register pair.
        SCF                     ; set carry flag indicating load not verify.
        LD      A,$FF           ; signal data not header.
        JP      LD_BLOCK           ; JUMP back to LD-BLOCK

; -----------------
;   the branch is here when a program as opposed to an array is to be loaded.

LD_PROG:
        EX      DE,HL           ; transfer dest to DE.
        LD      HL,(E_LINE)      ; address E_LINE
        DEC     HL              ; now variables end-marker.
        LD      (X_PTR),IX      ; place the IX header pointer in X_PTR
        LD      C,(IX+$0B)      ; get new length
        LD      B,(IX+$0C)      ; from 2nd header
        PUSH    BC              ; and save it.

        CALL    RECLAIM_1           ; routine RECLAIM-1 reclaims program and vars.
                                ; adjusting X-PTR.

        POP     BC              ; restore new length.
        PUSH    HL              ; * save start
        PUSH    BC              ; ** and length.

        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates the space.

        LD      IX,(X_PTR)      ; reload IX from adjusted X_PTR
        INC     HL              ; point to start of new area.
        LD      C,(IX+$0F)      ; fetch length of BASIC on tape
        LD      B,(IX+$10)      ; from 2nd descriptor
        ADD     HL,BC           ; add to address the start of variables.
        LD      (VARS),HL      ; set system variable VARS

        LD      H,(IX+$0E)      ; fetch high byte of autostart line number.
        LD      A,H             ; transfer to A
        AND     $C0             ; test if greater than $3F.
        JR      NZ,LD_PROG_1        ; forward to LD-PROG-1 if so with no autostart.

        LD      L,(IX+$0D)      ; else fetch the low byte.
        LD      (NEWPPC),HL      ; set system variable to line number NEWPPC
        LD      (IY+$0A),$00    ; set statement NSPPC to zero.

LD_PROG_1:
        POP     DE              ; ** pop the length
        POP     IX              ; * and start.
        SCF                     ; set carry flag
        LD      A,$FF           ; signal data as opposed to a header.
        JP      LD_BLOCK           ; jump back to LD-BLOCK

;;; @brief THE 'MERGE CONTROL' ROUTINE
;;;
;;;   the branch was here to merge a program and its variables or an array.
;;; @calls LD_BLOCK, NEXT_ONE, ME_ENTER
;;; @jumpedfrom REPORT_FA
ME_CONTRL:
        LD      C,(IX+$0B)      ; fetch length
        LD      B,(IX+$0C)      ; of data block on tape.
        PUSH    BC              ; save it.
        INC     BC              ; one for the pot.

        RST     30H             ; BC-SPACES creates room in workspace.
                                ; HL addresses last new location.
        LD      (HL),$80        ; place end-marker at end.
        EX      DE,HL           ; transfer first location to HL.
        POP     DE              ; restore length to DE.
        PUSH    HL              ; save start.

        PUSH    HL              ; and transfer it
        POP     IX              ; to IX register.
        SCF                     ; set carry flag to load data on tape.
        LD      A,$FF           ; signal data not a header.
        CALL    LD_BLOCK           ; routine LD-BLOCK loads to workspace.
        POP     HL              ; restore first location in workspace to HL.
X08CE   LD      DE,(PROG)      ; set DE from system variable PROG.

;   now enter a loop to merge the data block in workspace with the program and
;   variables.

ME_NEW_LP:
        LD      A,(HL)          ; fetch next byte from workspace.
        AND     $C0             ; compare with $3F.
        JR      NZ,ME_VAR_LP        ; forward to ME-VAR-LP if a variable or
                                ; end-marker.

;   continue when HL addresses a BASIC line number.

ME_OLD_LP:
        LD      A,(DE)          ; fetch high byte from program area.
        INC     DE              ; bump prog address.
        CP      (HL)            ; compare with that in workspace.
        INC     HL              ; bump workspace address.
        JR      NZ,ME_OLD_L1        ; forward to ME-OLD-L1 if high bytes don't match

        LD      A,(DE)          ; fetch the low byte of program line number.
        CP      (HL)            ; compare with that in workspace.

ME_OLD_L1:
        DEC     DE              ; point to start of
        DEC     HL              ; respective lines again.
        JR      NC,ME_NEW_L2        ; forward to ME-NEW-L2 if line number in
                                ; workspace is less than or equal to current
                                ; program line as has to be added to program.

        PUSH    HL              ; else save workspace pointer.
        EX      DE,HL           ; transfer prog pointer to HL
        CALL    NEXT_ONE           ; routine NEXT-ONE finds next line in DE.
        POP     HL              ; restore workspace pointer
        JR      ME_OLD_LP           ; back to ME-OLD-LP until destination position
                                ; in program area found.

; ---
;   the branch was here with an insertion or replacement point.

ME_NEW_L2:
        CALL    ME_ENTER           ; routine ME-ENTER enters the line
        JR      ME_NEW_LP           ; loop back to ME-NEW-LP.

; ---
;   the branch was here when the location in workspace held a variable.

ME_VAR_LP:
        LD      A,(HL)          ; fetch first byte of workspace variable.
        LD      C,A             ; copy to C also.
        CP      $80             ; is it the end-marker ?
        RET     Z               ; return if so as complete.  >>>>>

        PUSH    HL              ; save workspace area pointer.
        LD      HL,(VARS)      ; load HL with VARS - start of variables area.

ME_OLD_VP:
        LD      A,(HL)          ; fetch first byte.
        CP      $80             ; is it the end-marker ?
        JR      Z,ME_VAR_L2         ; forward if so to ME-VAR-L2 to add
                                ; variable at end of variables area.

        CP      C               ; compare with variable in workspace area.
        JR      Z,ME_OLD_V2         ; forward to ME-OLD-V2 if a match to replace.

;   else entire variables area has to be searched.

ME_OLD_V1:
        PUSH    BC              ; save character in C.
        CALL    NEXT_ONE           ; routine NEXT-ONE gets following variable
                                ; address in DE.
        POP     BC              ; restore character in C
        EX      DE,HL           ; transfer next address to HL.
        JR      ME_OLD_VP           ; loop back to ME-OLD-VP

; ---
;   the branch was here when first characters of name matched.

ME_OLD_V2:
        AND     $E0             ; keep bits 11100000
        CP      $A0             ; compare   10100000 - a long-named variable.

        JR      NZ,ME_VAR_L1        ; forward to ME-VAR-L1 if just one-character.

;   but long-named variables have to be matched character by character.

        POP     DE              ; fetch workspace 1st character pointer
        PUSH    DE              ; and save it on the stack again.
        PUSH    HL              ; save variables area pointer on stack.

ME_OLD_V3:
        INC     HL              ; address next character in vars area.
        INC     DE              ; address next character in workspace area.
        LD      A,(DE)          ; fetch workspace character.
        CP      (HL)            ; compare to variables character.
        JR      NZ,ME_OLD_V4        ; forward to ME-OLD-V4 with a mismatch.

        RLA                     ; test if the terminal inverted character.
        JR      NC,ME_OLD_V3        ; loop back to ME-OLD-V3 if more to test.

;   otherwise the long name matches in its entirety.

        POP     HL              ; restore pointer to first character of variable
        JR      ME_VAR_L1           ; forward to ME-VAR-L1

; ---
;   the branch is here when two characters don't match

ME_OLD_V4:
        POP     HL              ; restore the prog/vars pointer.
        JR      ME_OLD_V1           ; back to ME-OLD-V1 to resume search.

; ---
;   branch here when variable is to replace an existing one

ME_VAR_L1:
        LD      A,$FF           ; indicate a replacement.

;   this entry point is when A holds $80 indicating a new variable.

ME_VAR_L2:
        POP     DE              ; pop workspace pointer.
        EX      DE,HL           ; now make HL workspace pointer, DE vars pointer
        INC     A               ; zero flag set if replacement.
        SCF                     ; set carry flag indicating a variable not a
                                ; program line.
        CALL    ME_ENTER           ; routine ME-ENTER copies variable in.
        JR      ME_VAR_LP           ; loop back to ME-VAR-LP

;;; @brief Merge a Line or Variable
;;;
;;;   A BASIC line or variable is inserted at the current point. If the line
;;;   number or variable names match (zero flag set) then a replacement takes
;;;   place.
;;; @calls NEXT_ONE, RECLAIM_2, MAKE_ROOM
;;; @calledby ME_CONTRL
ME_ENTER:
        JR      NZ,ME_ENT_1        ; forward to ME-ENT-1 for insertion only.

;   but the program line or variable matches so old one is reclaimed.

        EX      AF,AF'          ; save flag??
        LD      (X_PTR),HL      ; preserve workspace pointer in dynamic X_PTR
        EX      DE,HL           ; transfer program dest pointer to HL.
        CALL    NEXT_ONE           ; routine NEXT-ONE finds following location
                                ; in program or variables area.
        CALL    RECLAIM_2           ; routine RECLAIM-2 reclaims the space between.
        EX      DE,HL           ; transfer program dest pointer back to DE.
        LD      HL,(X_PTR)      ; fetch adjusted workspace pointer from X_PTR
        EX      AF,AF'          ; restore flags.

;   now the new line or variable is entered.

ME_ENT_1:
        EX      AF,AF'          ; save or re-save flags.
        PUSH    DE              ; save dest pointer in prog/vars area.
        CALL    NEXT_ONE           ; routine NEXT-ONE finds next in workspace.
                                ; gets next in DE, difference in BC.
                                ; prev addr in HL
        LD      (X_PTR),HL      ; store pointer in X_PTR
        LD      HL,(PROG)      ; load HL from system variable PROG
        EX      (SP),HL         ; swap with prog/vars pointer on stack.
        PUSH    BC              ; ** save length of new program line/variable.
        EX      AF,AF'          ; fetch flags back.
        JR      C,ME_ENT_2         ; skip to ME-ENT-2 if variable

        DEC     HL              ; address location before pointer
        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates room for BASIC line
        INC     HL              ; address next.
        JR      ME_ENT_3           ; forward to ME-ENT-3

; ---

ME_ENT_2:
        CALL    MAKE_ROOM           ; routine MAKE-ROOM creates room for variable.

ME_ENT_3:
        INC     HL              ; address next?

        POP     BC              ; ** pop length
        POP     DE              ; * pop value for PROG which may have been
                                ; altered by POINTERS if first line.
        LD      (PROG),DE      ; set PROG to original value.
        LD      DE,(X_PTR)      ; fetch adjusted workspace pointer from X_PTR
        PUSH    BC              ; save length
        PUSH    DE              ; and workspace pointer
        EX      DE,HL           ; make workspace pointer source, prog/vars
                                ; pointer the destination
        LDIR                    ; copy bytes of line or variable into new area.
        POP     HL              ; restore workspace pointer.
        POP     BC              ; restore length.
        PUSH    DE              ; save new prog/vars pointer.
        CALL    RECLAIM_2           ; routine RECLAIM-2 reclaims the space used
                                ; by the line or variable in workspace block
                                ; as no longer required and space could be
                                ; useful for adding more lines.
        POP     DE              ; restore the prog/vars pointer
        RET                     ; return.

;;; @brief THE 'SAVE CONTROL' ROUTINE
;;;
;;;   A branch from the main SAVE-ETC routine at SAVE-ALL.
;;;   First the header data is saved. Then after a wait of 1 second
;;;   the data itself is saved.
;;;   HL points to start of data.
;;;   IX points to start of descriptor.
;;; @calls CHAN_OPEN, PO_MSG, WAIT_KEY, SA_BYTES
;;; @jumps SA_BYTES
;;; @jumpedfrom REPORT_FA
SA_CONTRL:
        PUSH    HL              ; save start of data

        LD      A,$FD           ; select system channel 'S'
        CALL    CHAN_OPEN           ; routine CHAN-OPEN

        XOR     A               ; clear to address table directly
        LD      DE,TAPE_MSGS        ; address: tape-msgs
        CALL    PO_MSG           ; routine PO-MSG -
                                ; 'Start tape then press any key.'

        SET     5,(IY+$02)      ; TV_FLAG  - Signal lower screen requires
                                ; clearing
        CALL    WAIT_KEY           ; routine WAIT-KEY

        PUSH    IX              ; save pointer to descriptor.
        LD      DE,$0011        ; there are seventeen bytes.
        XOR     A               ; signal a header.
        CALL    SA_BYTES           ; routine SA-BYTES

        POP     IX              ; restore descriptor pointer.

        LD      B,$32           ; wait for a second - 50 interrupts.

SA_1_SEC:
        HALT                    ; wait for interrupt
        DJNZ    SA_1_SEC           ; back to SA-1-SEC until pause complete.

        LD      E,(IX+$0B)      ; fetch length of bytes from the
        LD      D,(IX+$0C)      ; descriptor.

        LD      A,$FF           ; signal data bytes.

        POP     IX              ; retrieve pointer to start
        JP      SA_BYTES           ; jump back to SA-BYTES


;   Arrangement of two headers in workspace.
;   Originally IX addresses first location and only one header is required
;   when saving.
;
;   OLD     NEW         PROG   DATA  DATA  CODE
;   HEADER  HEADER             num   chr          NOTES.
;   ------  ------      ----   ----  ----  ----   -----------------------------
;   IX-$11  IX+$00      0      1     2     3      Type.
;   IX-$10  IX+$01      x      x     x     x      F  ($FF if filename is null).
;   IX-$0F  IX+$02      x      x     x     x      i
;   IX-$0E  IX+$03      x      x     x     x      l
;   IX-$0D  IX+$04      x      x     x     x      e
;   IX-$0C  IX+$05      x      x     x     x      n
;   IX-$0B  IX+$06      x      x     x     x      a
;   IX-$0A  IX+$07      x      x     x     x      m
;   IX-$09  IX+$08      x      x     x     x      e
;   IX-$08  IX+$09      x      x     x     x      .
;   IX-$07  IX+$0A      x      x     x     x      (terminal spaces).
;   IX-$06  IX+$0B      lo     lo    lo    lo     Total
;   IX-$05  IX+$0C      hi     hi    hi    hi     Length of datablock.
;   IX-$04  IX+$0D      Auto   -     -     Start  Various
;   IX-$03  IX+$0E      Start  a-z   a-z   addr   ($80 if no autostart).
;   IX-$02  IX+$0F      lo     -     -     -      Length of Program
;   IX-$01  IX+$10      hi     -     -     -      only i.e. without variables.
;


;;; @brief Canned cassette messages
;;;
;;;   The last-character-inverted Cassette messages.
;;;   Starts with normal initial step-over byte.
TAPE_MSGS:
        IFDEF   LANG_PERSIAN
        INCLUDE "lang/persian/tape_msgs.asm"
        ELSE
        INCLUDE "lang/arabic/tape_msgs.asm"
        ENDIF
        IFNDEF  LANG_PERSIAN
TAPE_MSG_0_END EQU TAPE_MSGS + $18
TAPE_MSG_4_END EQU TAPE_MSGS + $3E
        ENDIF
; Message 5 - NOT a cassette message: the ARABIC BOOT TITLE LOGO (boot splash).
; Appended to this table by the Arabic ROM.  RTL_PRINT_EXTRA_MSG ($3CF6, file 11),
; called from START-NEW (file 06), does  CALL CLS / XOR A / LD DE,$09DF / JP PO-MSG
; ($09DF = the ':'+$80 that ends message 4, used as the step-over byte), so the
; message starts at $09E0.  Like every message printed right after CLS it goes to the
; LOWER-SCREEN channel starting on the bottom line, each new line making the lower
; window grow and scroll the text up.  Control codes used (verified by running the ROM):
;       $06            PRINT comma: pad with spaces to column 16 (counted from the right)
;       $17,$0C,$00    TAB 12 (16-bit column)
;       $16,$0C,$08    AT 12,8 - the last byte is $88 = $08 with the end bit set
; and the printed result on the captured boot screen is:
;       row 12, column 15 :   *
;       row 13, column 15 :   |
;       row 14, columns 11-19 :   عرب | رام        =  "ARAB | RAM"
; The closing AT 12,8 opens the lower window to 13 lines (DF_SZ=13), which pushes the
; three logo lines up so they end up in the middle of the screen.  The copyright line
; (file 01, LANG_BOOT_COPYRIGHT_MSG) is then printed at the bottom:
;       (c) اوتورام كمبيوتر                  =  "(c) AutoRAM Computer"
; ----------------------------------------------------------------------------
        IFNDEF  LANG_PERSIAN
        INCLUDE "lang/arabic/boot_title.asm"
        ENDIF
        IFDEF   LANG_PERSIAN
        ASSERT  $ <= $09ED
        IF      $ < $09ED
        DS      $09ED-$, $FF
        ENDIF
RTL_FORM_OVERRIDE_ENTRY:
        ADD     A,A
        LD      DE,RTL_FORM_OVERRIDE_OUT
        JP      L0A7B
        ASSERT  $ == $09F4
        ENDIF
;;; @brief Entry point RTL_PO_FETCH_EXT (no original comment).
;;; @calls PO_SCR, PO_CHAR, RTL_INSTALL_PRINT_HOOK, PO_FETCH, PO_SAVE
;;; @jumps RTL_NEW_CTRL_HANDLER, PO_FETCH, COPY_BUFF, CL_SET, PO_STORE, CO_TEMP_5, REPORT_BB, PO_SCR
;;; @calledby ED_SPACES, OUT_FLASH
;;; @jumpedfrom L387B
RTL_PO_FETCH_EXT:
        CP      6                       ; is this a new Arabic control code (0-5)?
        JP      C,RTL_NEW_CTRL_HANDLER ; if so, divert to the new control-code handler
        LD      HL,PO_CTRL_TABLE-6      ; HL = control-code jump table base (first entry is code 6)
        LD      DE,$20                  ; DE = $20
        CP      E                       ; compare A with E
        JR      NC,L0A03                ; if no carry, jump to L0A03
        LD      E,A                     ; E = A
L0A03:
        ADD     HL,DE                   ; HL = HL + DE
        LD      E,(HL)                  ; E = (HL)
        ADD     HL,DE                   ; HL = HL + DE
        PUSH    HL                      ; push HL onto the stack
        JP      PO_FETCH                   ; jump to PO_FETCH
        DB          $FF              ; (byte before the table)
PO_CTRL_TABLE:
        DB          $59, $CA, $29, $42, $C7, $C6; table data
L0A11:
        DB          $C5, $14, $C3, $C2, $63, $62, $61, $60; table data
        DB          $5F, $5E, $58, $57, $B9, $B8, $B7, $B6; table data
        DB          $B5, $B4         ; table data
L0A23:
        DB          $B3, $B2, $B4    ; table data
        BIT     1,(IY+1)                ; test bit 1 of (IY+1)
        JP      NZ,COPY_BUFF                ; if not zero, jump to COPY_BUFF
        LD      C,$21                   ; C = $21
        CALL    PO_SCR                   ; call PO_SCR
        DEC     B                       ; B = B - 1
        JP      CL_SET                   ; jump to CL_SET
        INC     C                       ; C = C + 1
        LD      A,$22                   ; A = $22
        CP      C                       ; compare A with C
L0A3A:
        JR      NZ,L0A4D                ; if not zero, jump to L0A4D
        BIT     1,(IY+1)                ; test bit 1 of (IY+1)
        JR      NZ,L0A4B                ; if not zero, jump to L0A4B
        INC     B                       ; B = B + 1
        LD      C,2                     ; C = 2
        LD      A,$19                   ; A = $19
        CP      B                       ; compare A with B
        JR      NZ,L0A4D                ; if not zero, jump to L0A4D
        DEC     B                       ; B = B - 1
L0A4B:
        LD      C,$21                   ; C = $21
L0A4D:
        JP      CL_SET                   ; jump to CL_SET
        LD      A,(P_FLAG)               ; A = (P_FLAG)
        PUSH    AF                      ; push AF onto the stack
        DB          $FD              ; table data
        INC     BC                      ; BC = BC + 1
        LD      D,A                     ; D = A
        LD      BC,$203E                ; BC = $203E
        CALL    PO_CHAR                   ; call PO_CHAR
        POP     AF                      ; pop AF off the stack
        LD      (P_FLAG),A               ; (P_FLAG) = A
        JP      PO_STORE                   ; jump to PO_STORE
        LD      A,C                     ; A = C
        DEC     A                       ; A = A - 1
        DEC     A                       ; A = A - 1
        AND     $10                     ; A = A AND $10
L0A69:
        JR      L0ABF                   ; jump to L0ABF
L0A6B:
        LD      DE,L0A8B                ; DE = address of the next output handler
        LD      ($5C0F),A               ; ($5C0F) = A
        JR      L0A7E                   ; jump to L0A7E
        LD      DE,L0A6B                ; DE = address of the next output handler
        JR      L0A7B                   ; jump to L0A7B
        LD      DE,L0A81                ; DE = address of the next output handler
L0A7B:
        LD      (TVDATA),A               ; (TVDATA) = A
L0A7E:
        JP      RTL_SET_CURCHL_VECTOR                   ; jump to RTL_SET_CURCHL_VECTOR
L0A81:
        CALL    RTL_INSTALL_PRINT_HOOK                   ; call RTL_INSTALL_PRINT_HOOK
        LD      D,A                     ; D = A
        LD      A,(TVDATA)               ; A = (TVDATA)
        JP      CO_TEMP_5                   ; jump to CO_TEMP_5
L0A8B:
        CALL    RTL_INSTALL_PRINT_HOOK                   ; call RTL_INSTALL_PRINT_HOOK
        LD      HL,(TVDATA)              ; HL = (TVDATA)
        BIT     0,L                     ; test bit 0 of L
        JR      NZ,L0ABE                ; if not zero, jump to L0ABE
        LD      B,H                     ; B = H
        LD      C,A                     ; C = A
        LD      A,$1F                   ; A = $1F
        SUB     C                       ; A = A - C
        JR      C,L0AA8                 ; if carry, jump to L0AA8
        INC     A                       ; A = A + 1
        INC     A                       ; A = A + 1
        LD      C,A                     ; C = A
        BIT     1,(IY+1)                ; test bit 1 of (IY+1)
        JR      NZ,L0ABB                ; if not zero, jump to L0ABB
        LD      A,$16                   ; A = $16
        SUB     B                       ; A = A - B
L0AA8:
        JP      C,REPORT_BB                 ; if carry, jump to REPORT_BB
        INC     A                       ; A = A + 1
L0AAC:
        LD      B,A                     ; B = A
        INC     B                       ; B = B + 1
        BIT     0,(IY+2)                ; test bit 0 of (IY+2)
        JP      NZ,PO_SCR                ; if not zero, jump to PO_SCR
        CP      (IY+$31)                ; compare A with (IY+$31)
        JP      C,REPORT_5                 ; if carry, jump to REPORT_5
L0ABB:
        JP      CL_SET                   ; jump to CL_SET
L0ABE:
        LD      A,H                     ; A = H
L0ABF:
        CALL    PO_FETCH                   ; call PO_FETCH
L0AC2:
        ADD     A,C                     ; A = A + C
L0AC3:
        DEC     A                       ; A = A - 1
        AND     $1F                     ; A = A AND $1F
        RET     Z                       ; return if zero
        LD      B,A                     ; B = A
        SET     0,(IY+1)                ; set bit 0 of (IY+1)
L0ACC:
        LD      A,$20                   ; A = $20
        PUSH    BC                      ; push BC onto the stack
        CALL    PO_SAVE                   ; call PO_SAVE
        POP     BC                      ; pop BC off the stack
        DJNZ    L0ACC                   ; B = B - 1; loop to L0ACC while B != 0
        RET                             ; return
        LD      A,$3F                   ; A = $3F
        NOP                             ; no operation
L0A38  EQU    $0A38                   ; this address now falls inside the block above (label kept for reference)
L0A3D  EQU    $0A3D                   ; this address now falls inside the block above (label kept for reference)
L0A4F  EQU    $0A4F                   ; this address now falls inside the block above (label kept for reference)
L0A5F  EQU    $0A5F                   ; this address now falls inside the block above (label kept for reference)
L0A6D  EQU    $0A6D                   ; this address now falls inside the block above (label kept for reference)
L0A75  EQU    $0A75                   ; this address now falls inside the block above (label kept for reference)
L0A7A  EQU    $0A7A                   ; this address now falls inside the block above (label kept for reference)
L0A7D  EQU    $0A7D                   ; this address now falls inside the block above (label kept for reference)
L0A80  EQU    $0A80                   ; this address now falls inside the block above (label kept for reference)
L0A87  EQU    $0A87                   ; this address now falls inside the block above (label kept for reference)
L0AD0  EQU    $0AD0                   ; this address now falls inside the block above (label kept for reference)
