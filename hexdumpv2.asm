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

; The HEXDIGITS table is used to convert numeric values to their hex
; equivalents. Index by nybble without a scale: [HexDigits+eax]

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
; IN:Nothing
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

                    RET                     ;This procedure is done. returns to caller

;‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐­‐
; DUMPCHAR:"Poke" a value into the hex dump line string.
;
; IN:Pass the 8‐­bit value to be poked in RAX.
;  Pass the value's position in the line (0‐­15) in RDX
; RETURNS: Nothing
; MODIFIES: RAX, ASCLine, DumpLine
; CALLS: Nothing
; DESCRIPTION: The value passed in RAX will be put in both the hex dump
;  portion and in the ASCII portion, at the position passed
;  in RDX, represented by a space where it is not a printable character.

           DUMPCHAR:
                    PUSH RBX            ;Save caller's RBX
                    PUSH RDI            ;Save caller's RDI

                    MOV BL,[DOTXLAT+RAX]
                    MOV [ASCLINE+RDX+1],BL

                    MOV RBX,RAX
                    LEA RDI,[RDX*2+RDX]

                    AND RAX,000000000000000Fh
                    MOV AL,[HEXDIGITS+RAX]
                    MOV [DUMPLINE+RDI+2],AL

                    AND RBX,00000000000000F0h
                    SHR RBX,4
                    MOV BL,[HEXDIGITS+RBX]
                    MOV [DUMPLINE+RDI+1],BL

                    POP RDI
                    POP RDX
                    RET
                    
