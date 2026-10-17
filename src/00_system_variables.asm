;;; @file 00_system_variables.asm
;;; @brief Part 0. ZX Spectrum system variables (EQU addresses, status X/N/R)

;**************************************************
;** Part 0. ZX Spectrum System Variables         **
;**************************************************

;; Status:
;;      X: The variable should not be changed, the system might crash.
;;      N: Changing the variable will have no lasting effect
;;      R: Routine entry point. The content should not be changed.


SWAP:	EQU	$5B00	;;;< Paging subroutine. 16 bytes
KSTATE_0:	EQU	$5C00	;;;< Used in reading the keyboard. 1 byte
LASTK:	EQU	$5C08	;;;< Stores newly pressed key. 1 byte
REPDEL:	EQU	$5C09	;;;< Time (in 50ths of a second) that a key must be held down before it repeats. -- Status/width 1
REPPER:	EQU	$5C0A	;;;< Delay (in 50ths of a second) between successive repeats of a key held downs. -- Status/width 1
DEFADD:	EQU	$5C0B	;;;< Address of arguments of user defined function (if one is being evaluated), otherwise 0. -- Status/width N2
KDATA:	EQU	$5C0D	;;;< Stores 2nd byte of colour controls entered from keyboard. -- Status/width Nl
TVDATA:	EQU	$5C0E	;;;< Stores bytes of colour, AT and TAB controls going to TV. -- Status/width N1
STRMS:	EQU	$5C10	;;;< Addresses of channels attached to streams. -- Status/width X38
CHARS:	EQU	$5C36	;;;< 256 less than address of character set (which starts with space and carries on to (C)). Normally in ROM, but you can set up your down in RAM and make CHARS point to it. -- Status/width 2
RASP:	EQU	$5C38	;;;< Length of warning buzz. -- Status/width 1
PIP:	EQU	$5C39	;;;< Length of keyboard click. -- Status/width 1
ERR_NR:	EQU	$5C3A	;;;< 1 less than the report code. Starts off at 255 (for -1) so 'PEEK 23610' gives 255. -- Status/width 1
FLAGS:	EQU	$5C3B	;;;< Various flags to control the BASIC system. -- Status/width X1
TV_FLAG:	EQU	$5C3C	;;;< Flags associated with the TV. -- Status/width X1
ERR_SP:	EQU	$5C3D	;;;< Address of item on machine stack to be used as error return. -- Status/width X2
LIST_SP:	EQU	$5C3F	;;;< Address of return address from automatic listing. -- Status/width N2
MODE:	EQU	$5C41	;;;< Specifies 'K', 'L', 'C', 'E' or 'G' cursor. -- Status/width N1
NEWPPC:	EQU	$5C42	;;;< Line to be jumped to. -- Status/width 2
NSPPC:	EQU	$5C44	;;;< Statement number in line to be jumped to. Poking first NEWPPC and then NSPPC forces a jump to a specified statement in a line. -- Status/width 1
PPC:	EQU	$5C45	;;;< Line number of statement currently being executed. -- Status/width 2
SUBPPC:	EQU	$5C47	;;;< Number within line of statement currently being executed. -- Status/width 1
BORDCR:	EQU	$5C48	;;;< Border colour multiplied by 8; also contains the attributes normally used for the lower half of the screen. -- Status/width 1
E_PPC:	EQU	$5C49	;;;< Number of current line (with program cursor). -- Status/width 2
VARS:	EQU	$5C4B	;;;< Address of variables. -- Status/width X2
DEST:	EQU	$5C4D	;;;< Address of variable in assignment. -- Status/width N2
CHANS:	EQU	$5C4F	;;;< Address of channel data. -- Status/width X2
CURCHL:	EQU	$5C51	;;;< Address of information currently being used for input and output. -- Status/width X2
PROG:	EQU	$5C53	;;;< Address of BASIC program. -- Status/width X2
DATADD:	EQU	$5C57	;;;< Address of terminator of last DATA item. -- Status/width X2
E_LINE:	EQU	$5C59	;;;< Address of command being typed in. -- Status/width X2
K_CUR:	EQU	$5C5B	;;;< Address of cursor. -- Status/width 2
CH_ADD:	EQU	$5C5D	;;;< Address of the next character to be interpreted - the character after the argument of PEEK, or the NEWLINE at the end of a POKE statement. -- Status/width X2
X_PTR:	EQU	$5C5F	;;;< Address of the character after the [] marker. -- Status/width 2
WORKSP:	EQU	$5C61	;;;< Address of temporary work space. -- Status/width X2
STKBOT:	EQU	$5C63	;;;< Address of bottom of calculator stack. -- Status/width X2
STKEND:	EQU	$5C65	;;;< Address of start of spare space. -- Status/width X2
BREG:	EQU	$5C67	;;;< Calculator's B register. -- Status/width N1
MEM:	EQU	$5C68	;;;< Address of area used for calculator's memory -- Status/width N2
FLAGS2:	EQU	$5C6A	;;;< More flags. (Bit 3 set when CAPS SHIFT or CAPS LOCK is on.) -- Status/width 1
DF_SZ:	EQU	$5C6B	;;;< The number of lines (including one blank line) in the lower part of the screen. -- Status/width X1
S_TOP:	EQU	$5C6C	;;;< The number of the top program line in automatic listings. -- Status/width 2
OLDPPC:	EQU	$5C6E	;;;< Line number to which CONTINUE jumps. -- Status/width 2
OSPPC:	EQU	$5C70	;;;< Number within line of statement to which CONTINUE jumps. -- Status/width 1
FLAGX:	EQU	$5C71	;;;< Various flags. -- Status/width N1
STRLEN:	EQU	$5C72	;;;< Length of string type destination in assignment. -- Status/width N2
T_ADDR:	EQU	$5C74	;;;< Address of next item in syntax table (very unlikely to be useful). -- Status/width N2
SEED:	EQU	$5C76	;;;< The seed for RND. This is the variable that is set by RANDOMIZE. -- Status/width 2
FRAMES1:	EQU	$5C78	;;;< 3 byte (least significant byte first), frame counter incremented every 20ms. -- Status/width 3
UDG:	EQU	$5C7B	;;;< Address of first user-defined graphic -- Status/width 2
COORDS:	EQU	$5C7D	;;;< X-coordinate of last point plotted. -- Status/width 1
COORDS_y:	EQU	$5C7E	;;;< Y-coordinate of last point plotted. -- Status/width 1
PR_CC:	EQU	$5C80	;;;< Full address of next position for LPRINT to print at (in ZX printer buffer). Legal values 5B00 - 5B1F. -- Status/width X2
ECHO_E:	EQU	$5C82	;;;< 33-column number and 24-line number (in lower half) of end of input buffer. -- Status/width 2
DF_CC:	EQU	$5C84	;;;< Address in display file of PRINT position. -- Status/width 2
DFCCL:	EQU	$5C86	;;;< Like DF CC for lower part of screen. -- Status/width 2
S_POSN:	EQU	$5C88	;;;< 33-column number for PRINT position. -- Status/width X1
S_POSN_hi:	EQU	$5C89	;;;< 24-line number for PRINT position. -- Status/width X1
SPOSNL:	EQU	$5C8A	;;;< Like S POSN for lower part. -- Status/width X2
SCR_CT:	EQU	$5C8C	;;;< Counts scrolls - it is always 1 more than the number of scrolls that will be done before stopping with 'scroll'? -- Status/width 1
ATTR_P:	EQU	$5C8D	;;;< Permanent current colours, etc., (as set up by colour statements). -- Status/width 1
ATTR_T:	EQU	$5C8F	;;;< Temporary current colours, etc., (as set up by colour items). -- Status/width N1
MASK_T:	EQU	$5C90	;;;< Like MASK P, but temporary. -- Status/width N1
P_FLAG:	EQU	$5C91	;;;< More flags. -- Status/width 1
MEM_0:	EQU	$5C92	;;;< Calculator's memory area - used to store numbers that cannot conveniently be put on the calculator stack. -- Status/width N30
NMIADD:	EQU	$5CB0	;;;< Holds the address of the users NMI service routine. -- Status/width 2
RAMTOP:	EQU	$5CB2	;;;< Address of last byte of BASIC system area. -- Status/width 2
P_RAMT:	EQU	$5CB4	;;;< Address of last byte of physical RAM. -- Status/width 2
