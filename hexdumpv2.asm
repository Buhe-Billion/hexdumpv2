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
