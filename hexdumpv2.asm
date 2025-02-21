;NASM                     :   2.14.02
;Architecture             :   X86-64
;CPU                      :   Intel® Core™2 Duo CPU T6570 @ 2.10GHz × 2
;                         :
;Description              :   This program creates a hex number output [0123456789ABCDEF]
;                         :   from stdin.
;
;

SECTION .bss              ;   Section containing uninitialised data

        BUFFLEN EQU 10h
        BUFF: RESB BUFFLEN

SECTION .data             ;   Section containing initialised data

;Here we have two parts of a single useful data structure, implementing
;the text line of a hex dump utility. The first part displays 16 bytes
;in hex separated by spaces. Immediately following is a 16‐­
;character
;line delimited by vertical bar characters. Because they are adjacent,
;the two parts can be referenced separately or as a single contiguous
;unit. If DumpLine is to be used separately, you must
;append an EOL before sending it to the Linux console.

        DUMPLINE:          DB " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
        DUMPLEN            EQU $-DUMPLINE
        ASCLINE:           DB "|................|",10
        ASCLEN             EQU $-ASCLINE
        FULLLEN            EQU $-DUMPLINE


        SYS_WRITE_CALL_VAL EQU 1
        STDERR_FD          EQU 2
        SYS_READ_CALL_VAL  EQU 0
        STDIN_FD           EQU 0
        STDOUT_FD          EQU 1
        EXIT_SYSCALL       EQU 60
        OK_RET_VAL         EQU 0

; The HEXDIGITS table is used to convert numeric values to their hex
; equivalents. Index by nybble without a scale: [HexDigits+rax]

        HEXDIGITS:         DB "0123456789ABCDEF"

; DOTXLAT is used for ASCII character translation, into the ASCII
; portion of the hex dump line, via XLAT or ordinary memory lookup.
; All printable characters "play through" as themselves. The high 128
; characters are translated to ASCII period (2Eh). The non‐­printable
; characters in the low 128 are also translated to ASCII period, as is
; char 127.

         DOTXLAT:
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
              DB 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
              DB 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
              DB 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
              DB 60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,6Ah,6Bh,6Ch,6Dh,6Eh,6Fh
              DB 70h,71h,72h,73h,74h,75h,76h,77h,78h,79h,7Ah,7Bh,7Ch,7Dh,7Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
              DB 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh

SECTION .text         ;Section containing code

;‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐
; CLEARLINE:
; Clear a hex dump line string to 16 0 values;
; INPUT:Nothing
; RETURNS:Nothing
; MODIFIES:Nothing
; CALLS:DumpChar
; DESCRIPTION: The hex dump line string is cleared to binary 0 by
; calling DumpChar 16 times, passing it 0 each time.

         CLEARLINE:
                    PUSH RAX            ;SAVE ALL CALLERS R*X registers
                    PUSH RBX
                    PUSH RCX
                    PUSH RDX

                    MOV RDX,15           ;Going to 16 pokes, counting from 0

         .POKE:
                    MOV RAX,0             ;Tell DUMPCHAR to poke a '0'
                    CALL DUMPCHAR         ;Insert '0' into the hex dump string
                    SUB RDX,1             ;DEC doesn't affect CF! Hence sub is used
                    JAE .POKE             ;If RDX >= 0, Loopback

                    POP RDX               ;Restore caller's R*X registers
                    POP RCX
                    POP RBX
                    POP RAX

                    RET                    ;This procedure is done. returns to caller

;‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐
; DUMPCHAR:"Poke" a value into the hex dump line string.
;
; INPUT:Pass the 8‐­bit value to be poked in RAX.
;  Pass the value's position in the line (0‐­15) in RDX
; RETURNS: Nothing
; MODIFIES: RAX, ASCLINE, DUMPLINE
; CALLS: Nothing
; DESCRIPTION: The value passed in RAX will be put in both the hex dump
;  portion and in the ASCII portion, at the position passed
;  in RDX, represented by a space where it is not a printable character.

           DUMPCHAR:
                    PUSH RBX            ;Save caller's RBX
                    PUSH RDI            ;Save caller's RDI

;First we insert the input char into the ASCII part of the dump line

                    MOV BL,[DOTXLAT+RAX]            ;Translate non printables to '.'
                    MOV [ASCLINE+RDX+1],BL          ;Write to the ASCII portion zuerst

;Next we insert the hex equivalent of the input char in the hex
;part of the hex dump line.

                    MOV RBX,RAX                     ;Save a 2nd copy of the input char
                    LEA RDI,[RDX*2+RDX]             ;Calculate the offset into line string (RDX*3)

;Look up low nybble character and insert it into the string:

                    AND RAX,000000000000000Fh        ;Mask out all but the low nybble
                    MOV AL,[HEXDIGITS+RAX]           ;Lookup the char equivalent of the nybble
                    MOV [DUMPLINE+RDI+2],AL          ;and write it to line string

                    AND RBX,00000000000000F0h        ;Mask out all but the 2nd lowest nybble
                    SHR RBX,4                        ;Shift the just previously filtered high nybble to lower nybble
                    MOV BL,[HEXDIGITS+RBX]           ;Lookup the char equivalent of the nybble
                    MOV [DUMPLINE+RDI+1],BL          ;and write it to line string

;Job's done. On to the caller with RET
                    POP RDI                           ;!!!Restore registers in LIFO structure
                    POP RBX                           ;Otherwise we will have a misaligned stack
                    RET                               ;Return to caller

;‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐
; PrintLine: Displays DumpLine to stdout
; INPUT: DUMPLINE, FULLLEN
; RETURNS: Nothing
; MODIFIES: Nothing
; CALLS: Kernel sys_write
; DESCRIPTION: The hex dump line string DumpLine is displayed to
;stdout using syscall function sys_write. Registers
;used are preserved.

            PRINTLINE:
                    PUSH RAX                      ;Back in x86-32 there existed the PUSHAD
                    PUSH RBX                      ; instruction that pushed multiple registers
                    PUSH RCX                      ;to the stack at once. Sadly, this instruction has
                    PUSH RDX                      ; been depreciated for x64!
                    PUSH RSI
                    PUSH RDI

                    MOV RAX,SYS_WRITE_CALL_VAL     ;Specify sys_write call
                    MOV RDI,STDOUT_FD              ;Specify standard output
                    MOV RSI,DUMPLINE               ;Pass addy of line string

;Line below ensures that we print ASCLINE as well.
;We can substitute DUMPLINE AND ASCLINE AND FULLLEN AND ASCLEN
;to select for the parts we may selectively want to print

                    MOV RDX,FULLLEN                ;Pass size of the line string
                    SYSCALL                        ;Ask the Linux kernel to display our string

                    POP RDI                         ;POPAD just like with PUSHAD handled multiple
                    POP RSI                         ;registers at once. POPAD would pop multiple
                    POP RDX                         ;registers out of the stack. But, just like PUSHAD
                    POP RCX                         ;,POPAD is not supported by x64! Schade!
                    POP RBX
                    POP RAX

                    RET                             ; Return to calling location


;‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐
; LoadBuff:Fills a buffer with data from stdin via syscall sys_read
; INPUT: Nothing
; RETURNS: # of bytes read in R15
; MODIFIES: RCX, R15, Buff
; CALLS: syscall sys_read
; DESCRIPTION: Loads a buffer full of data (BUFFLEN bytes) from stdin
; using syscall sys_read and places it in Buff. Buffer
; offset counter RCX is zeroed, because we're starting in
;on a new buffer full of data. Caller must test value in
;R15: If R15 contains 0 on return, we've hit EOF on stdin.
;< 0 in R15 on return indicates some kind of error.

             LOADBUFF:
                    PUSH RAX                    ;Save callers registers RAX,RDX,RSI and RDI
                    PUSH RDX                    ;onto the stack.
                    PUSH RSI
                    PUSH RDI

                    MOV RAX,SYS_READ_CALL_VAL    ;Specify sys_read call
                    MOV RDI,STDIN_FD             ;Specify stdin
                    MOV RSI,BUFF                 ;Pass offset of the buffer to read *to*
                    MOV RDX,BUFFLEN              ;Pass tthe number of bytes to read at one pass
                    SYSCALL                      ;Ask the kernel to sys_read to fill the buffer

;sys_read maintains a position on the input file/buffer of where it last was?!So it doesnt
;begin @ the beginning each time!?!

                    MOV R15,RAX                   ;Save the number of bytes read
                    XOR RCX,RCX                   ;Clear out the buffer pointer

                    POP RDI                       ;Restore callers registers RAX,RDX,RSI and RDI
                    POP RSI                       ;from the stack.
                    POP RDX
                    POP RAX

                    RET                           ;Return to calling location


; The main program lies here below
;


global _start

_start:
        MOV RBP,RSP                     ;for debugging

;Whatever initialisation needs doing before loop scan starts here

        XOR R15,R15                     ;zero out R15,RSI,& RCX
        XOR RSI,RSI
        XOR RCX,RCX
        CALL LOADBUFF                   ;Read first buffer of data from stdin
        CMP R15,0                       ;If R15 = 0, sys_read reached EOF in stdin
        JBE EXIT

;Go through the buffer and convert binary byte values to hex digits

        SCAN:
             XOR RAX,RAX                ;Clear RAX to 0
             MOV AL,[BUFF+RCX]          ;Get a byte from the buffer into AL
             MOV RDX,RSI                ;Copy total counter into RDX
             AND RDX,000000000000000Fh  ;Mask out lowest 4 bits of char counter
             CALL DUMPCHAR              ;Call the char poke procedure

;Bump the buffer pointer to the next char and see if the buffer's done

             INC RSI                    ;Increment total chars processed counter
             INC RCX                    ;Increment buffer pointer
             CMP RCX,R15                ;Compare with number of chars in buffer
             JB .MODTEST                ;If we've processed all chars in buffer...
             CALL LOADBUFF              ; ...go fill the buffer again.
             CMP R15,0                  ; R15 equ 0 when EOF is reached by sys_read
             JBE DONE                   ;If we get EOF, then we're done

;.MODTEST controls the loop, ensuring that we don't exceed 16 bytes

        .MODTEST:
             TEST RSI,0000000000000000Fh   ;Test 4 lowest bits in counter for 0
             JNZ SCAN                     ;If the counter is *not* mod 16, loop back
             CALL PRINTLINE               ;...otherwise print the line
             CALL CLEARLINE               ;Clear hex dump line to 0's
             NOP
             JMP SCAN                     ;Continue scanning the buffer

         DONE:
             CALL PRINTLINE               ;Print the final leftovers line

         EXIT:
             MOV RSP,RBP
             POP RBP

             MOV RAX,EXIT_SYSCALL	;EXIT THE PROGRAM
             MOV RDI,OK_RET_VAL	;RETURN VALUE
             SYSCALL		;SERVUS UND BIS DANN


;INVICTUS!!!!!!
;This programm now runs correctly!
;The error in the previous version was
;due to a stack misalignment: In DUMPCHAR we were errenously
;popping  RBX's value into RDX. Thereby causing the programm
;to print only the first line of the stdin
;and get caught in an infinite loop!
